import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/leaf_maturity_result.dart';

class LeafMaturityPyTorchService {
  ClassificationModel? _model;
  bool _isInitialized = false;

  static const String _modelPath = 'assets/models/tea_maturity_explain.ptl';
  static const String _weightsPath = 'assets/models/fc_weights.json';
  static const int _inputSize = 224;

  // FC Weights for CAM calculation
  List<List<double>>? _fcWeights;

  // ImageNet mean and std
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🧠 Loading PyTorch Mobile model (Explainable - Single Output)...');

      // Standard loadClassificationModel is the most stable path in pytorch_lite
      _model = await PytorchLite.loadClassificationModel(
          _modelPath, _inputSize, _inputSize, 4);

      print('📊 Loading FC weights for CAM...');
      final weightData = await rootBundle.loadString(_weightsPath);
      final decodedWeights = json.decode(weightData);

      // Handle the nested structure from our python export script
      if (decodedWeights is Map && decodedWeights.containsKey('fc_weights')) {
        _fcWeights = (decodedWeights['fc_weights'] as List)
            .map((row) =>
                (row as List).map((e) => (e as num).toDouble()).toList())
            .toList();
      } else {
        // Fallback if structure varies
        _fcWeights = (decodedWeights as List)
            .map((row) =>
                (row as List).map((e) => (e as num).toDouble()).toList())
            .toList();
      }

      _isInitialized = true;
      print('✅ Model and weight assets loaded');
    } catch (e) {
      print("Error loading model assets: $e");
      rethrow;
    }
  }

  Future<LeafMaturityResult> predict(XFile imageFile) async {
    if (!_isInitialized) await initialize();

    try {
      print("Running explainable inference on ${imageFile.path}...");
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 1. Unified inference call
      // Returns List<double>: [logits(4) + features(1024*7*7)]
      final List<double> combined = await _model!.getImagePredictionList(
        imageBytes,
        mean: _mean,
        std: _std,
      );

      if (combined.length < 4) throw Exception("Incomplete model output");

      // 2. Extract results
      final List<double> logits = combined.sublist(0, 4);
      final List<double> featuresFlattened = combined.sublist(4);

      final probabilities = _softmax(logits);
      final resultData = _extractResult(probabilities);

      // 3. CAM generation
      int classIdx = _getMaxIdx(probabilities);

      final img.Image? baseImage = img.decodeImage(imageBytes);
      if (baseImage == null) throw Exception("Could not decode image");

      final heatmapPath = await _generateHeatmap(
          baseImage, featuresFlattened, _fcWeights![classIdx]);

      return LeafMaturityResult(
        species: resultData.species,
        maturity: resultData.maturity,
        speciesConfidence: resultData.speciesConfidence,
        maturityConfidence: resultData.maturityConfidence,
        speciesProbabilities: resultData.speciesProbabilities,
        maturityProbabilities: resultData.maturityProbabilities,
        timestamp: resultData.timestamp,
        rawConfidence: resultData.rawConfidence,
        heatmapPath: heatmapPath,
      );
    } catch (e) {
      print("Inference/CAM error: $e");
      rethrow;
    }
  }

  int _getMaxIdx(List<double> list) {
    int idx = 0;
    double maxVal = -double.infinity;
    for (int i = 0; i < list.length; i++) {
      if (list[i] > maxVal) {
        maxVal = list[i];
        idx = i;
      }
    }
    return idx;
  }

  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce(max);
    final exps = logits.map((l) => exp(l - maxLogit)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  Future<String?> _generateHeatmap(img.Image baseImage,
      List<double> featuresFlattened, List<double> weights) async {
    try {
      final int h = 7;
      final int w = 7;
      final int channels = 1024;

      if (featuresFlattened.length < channels * h * w) return null;

      // 1. Weighted sum
      List<List<double>> heatmap = List.generate(h, (_) => List.filled(w, 0.0));
      for (int k = 0; k < channels; k++) {
        final double weight = weights[k];
        final int channelOffset = k * h * w;
        for (int i = 0; i < h; i++) {
          final int rowOffset = channelOffset + (i * w);
          for (int j = 0; j < w; j++) {
            heatmap[i][j] += weight * featuresFlattened[rowOffset + j];
          }
        }
      }

      // 2. ReLU & Normalize
      double maxVal = -double.infinity;
      for (int i = 0; i < h; i++) {
        for (int j = 0; j < w; j++) {
          if (heatmap[i][j] < 0) heatmap[i][j] = 0;
          if (heatmap[i][j] > maxVal) maxVal = heatmap[i][j];
        }
      }

      if (maxVal > 0) {
        for (int i = 0; i < h; i++) {
          for (int j = 0; j < w; j++) {
            heatmap[i][j] /= maxVal;
          }
        }
      }

      // 3. Create image and overlay
      img.Image processedBase = _preprocessForOverlay(baseImage);

      img.Image heatmapImage = img.Image(width: w, height: h);
      for (int i = 0; i < h; i++) {
        for (int j = 0; j < w; j++) {
          int val = (heatmap[i][j] * 255).toInt();
          heatmapImage.setPixelRgb(j, i, val, val, val);
        }
      }

      img.Image resizedHeatmap = img.copyResize(heatmapImage,
          width: _inputSize,
          height: _inputSize,
          interpolation: img.Interpolation.linear);

      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final hPixel = resizedHeatmap.getPixel(x, y);
          final double hVal = hPixel.r / 255.0;

          // Color map (JET-like)
          int r = (max(0.0, min(1.0, 1.5 - (4.0 * (hVal - 0.75).abs())))) *
              255 ~/
              1;
          int g = (max(0.0, min(1.0, 1.5 - (4.0 * (hVal - 0.50).abs())))) *
              255 ~/
              1;
          int b = (max(0.0, min(1.0, 1.5 - (4.0 * (hVal - 0.25).abs())))) *
              255 ~/
              1;

          final basePixel = processedBase.getPixel(x, y);
          final finalR = (basePixel.r * 0.4 + r * 0.6).toInt();
          final finalG = (basePixel.g * 0.4 + g * 0.6).toInt();
          final finalB = (basePixel.b * 0.4 + b * 0.6).toInt();

          processedBase.setPixelRgb(x, y, finalR, finalG, finalB);
        }
      }

      final tempDir = await getTemporaryDirectory();
      final String fullPath =
          '${tempDir.path}/cam_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(fullPath).writeAsBytes(img.encodeJpg(processedBase));

      return fullPath;
    } catch (e) {
      print("Heatmap failure: $e");
      return null;
    }
  }

  img.Image _preprocessForOverlay(img.Image image) {
    int width = image.width;
    int height = image.height;
    double ratio = 256 / min(width, height);
    int newWidth = (width * ratio).round();
    int newHeight = (height * ratio).round();
    img.Image resized =
        img.copyResize(image, width: newWidth, height: newHeight);
    return img.copyCrop(resized,
        x: (newWidth - 224) ~/ 2,
        y: (newHeight - 224) ~/ 2,
        width: 224,
        height: 224);
  }

  LeafMaturityResult _extractResult(List<double> probabilities) {
    final speciesProbs = {
      'Assamica': probabilities[0] + probabilities[1],
      'DT1': probabilities[2] + probabilities[3],
    };
    final maturityProbs = {
      'Tender': probabilities[0] + probabilities[2],
      'Mature': probabilities[1] + probabilities[3],
    };
    final species =
        speciesProbs.entries.reduce((a, b) => a.value > b.value ? a : b);
    final maturity =
        maturityProbs.entries.reduce((a, b) => a.value > b.value ? a : b);

    return LeafMaturityResult(
      species: species.key,
      maturity: maturity.key,
      speciesConfidence: species.value,
      maturityConfidence: maturity.value,
      speciesProbabilities: speciesProbs,
      maturityProbabilities: maturityProbs,
      timestamp: DateTime.now(),
      rawConfidence: probabilities.reduce(max),
    );
  }
}
