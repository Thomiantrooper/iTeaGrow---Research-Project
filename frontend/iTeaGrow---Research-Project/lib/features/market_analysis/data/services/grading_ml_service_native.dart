import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/market_models.dart';

class GradingMlService {
  Interpreter? _interpreter;
  Map<String, dynamic>? _weightsData;
  final List<String> _labels = [
    "BOP",
    "BOPF",
    "Dust",
    "Dust1",
    "Fanning1",
    "Pekoe"
  ];

  Future<void> initModel() async {
    try {
      // Load explainable model with multi-outputs
      _interpreter = await Interpreter.fromAsset(
          'assets/models/grading_model_explain.tflite');
      _interpreter!.allocateTensors();

      // Load weights for CAM
      final weightsString =
          await rootBundle.loadString('assets/models/powder_weights.json');
      _weightsData = json.decode(weightsString);
    } catch (e) {
      print('Failed to load tflite model or weights: $e');
      throw Exception('Model initialization failed');
    }
  }

  Future<ClassificationResult?> classifyImage(File imageFile,
      {bool generateHeatmap = true}) async {
    if (_interpreter == null) {
      await initModel();
    }
    if (_interpreter == null) return null;

    final imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    img.Image resizedImage =
        img.copyResize(originalImage, width: 224, height: 224);

    var inputBuffer = _imageToFloat32Buffer(resizedImage);

    // Multi-output: [feature_output, prob_output]
    // Index 169: [1, 7, 7, 1280], Index 172: [1, 6]
    var outputs = {
      0: List.generate(
          1,
          (_) => List.generate(
              7, (_) => List.generate(7, (_) => List.filled(1280, 0.0)))),
      1: List.generate(1, (_) => List.filled(6, 0.0)),
    };

    _interpreter!.runForMultipleInputs([inputBuffer], outputs);

    List<double> probabilities = (outputs[1] as List)[0];
    int maxIndex = -1;
    double maxConfidence = 0.0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        maxIndex = i;
      }
    }

    if (maxIndex != -1) {
      String? heatmapPath;
      if (generateHeatmap && _weightsData != null) {
        final featureMap = (outputs[0] as List)[0];
        heatmapPath =
            await _generateCamHeatmap(originalImage, maxIndex, featureMap);
      }

      return ClassificationResult(
        grade: _labels[maxIndex],
        confidence: maxConfidence * 100,
        source: 'offline',
        imageFile: imageFile,
        heatmapPath: heatmapPath,
      );
    }
    return null;
  }

  Future<String?> _generateCamHeatmap(img.Image baseImage, int targetClassIndex,
      List<dynamic> featureMap) async {
    try {
      final List<dynamic> allWeights = _weightsData!['weights'];
      final List<double> classWeights =
          List<double>.from(allWeights[targetClassIndex]);

      // 1. Compute Weighted Sum [7x7]
      final cam = List.filled(49, 0.0);
      for (int y = 0; y < 7; y++) {
        for (int x = 0; x < 7; x++) {
          double sum = 0.0;
          final List<dynamic> channels = featureMap[y][x];
          for (int c = 0; c < 1280; c++) {
            sum += (channels[c] as double) * classWeights[c];
          }
          cam[y * 7 + x] = sum;
        }
      }

      // 2. ReLU and Normalization
      double maxVal = -double.infinity;
      double minVal = double.infinity;
      for (int i = 0; i < 49; i++) {
        if (cam[i] < 0) cam[i] = 0;
        if (cam[i] > maxVal) maxVal = cam[i];
        if (cam[i] < minVal) minVal = cam[i];
      }

      if (maxVal > minVal) {
        for (int i = 0; i < 49; i++) {
          cam[i] = (cam[i] - minVal) / (maxVal - minVal);
        }
      }

      // 3. Create Heatmap Image
      img.Image heatmap = img.Image(width: 7, height: 7);
      for (int i = 0; i < 49; i++) {
        final val = (cam[i] * 255).toInt();
        // Heatmap colors (Blue -> Red)
        int r = val;
        int g = (val > 128) ? 255 - val : val;
        int b = 255 - val;
        heatmap.setPixelRgb(i % 7, i ~/ 7, r, g, b);
      }

      img.Image resizedHeatmap = img.copyResize(heatmap,
          width: baseImage.width,
          height: baseImage.height,
          interpolation: img.Interpolation.linear);

      // 4. Blend
      final outImage = baseImage.clone();
      for (int y = 0; y < outImage.height; y++) {
        for (int x = 0; x < outImage.width; x++) {
          final pBase = outImage.getPixel(x, y);
          final pHeat = resizedHeatmap.getPixel(x, y);

          final r = (pBase.r * 0.7 + pHeat.r * 0.3).toInt();
          final g = (pBase.g * 0.7 + pHeat.g * 0.3).toInt();
          final b = (pBase.b * 0.7 + pHeat.b * 0.3).toInt();

          outImage.setPixelRgb(x, y, r, g, b);
        }
      }

      final tempDir = await getTemporaryDirectory();
      final String fullPath =
          '${tempDir.path}/cam_powder_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(fullPath).writeAsBytes(img.encodeJpg(outImage));
      return fullPath;
    } catch (e) {
      print('Error generating Grad-CAM: $e');
      return null;
    }
  }

  List<List<List<List<double>>>> _imageToFloat32Buffer(img.Image image) {
    var buffer = List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = image.getPixelSafe(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );
    return buffer;
  }

  void dispose() {
    _interpreter?.close();
  }
}
