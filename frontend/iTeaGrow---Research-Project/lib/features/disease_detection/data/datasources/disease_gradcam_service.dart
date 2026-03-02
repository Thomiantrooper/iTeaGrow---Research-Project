import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// On-device Grad-CAM explainability service for Tea Leaf Disease Detection.
///
/// Uses a MobileNetV2-backed explainable model (disease_explain.ptl) that outputs
/// a concatenated tensor:  [class_logits(3), feature_map_flat(1280*7*7)]
///
/// The CAM is computed as a weighted sum of the feature maps using the
/// class-specific FC weights from disease_fc_weights.json.
class DiseaseGradCAMService {
  static final DiseaseGradCAMService _instance =
      DiseaseGradCAMService._internal();
  factory DiseaseGradCAMService() => _instance;
  DiseaseGradCAMService._internal();

  ClassificationModel? _model;
  bool _isInitialized = false;

  static const String _modelPath    = 'assets/models/disease_explain.ptl';
  static const String _weightsPath  = 'assets/models/disease_fc_weights.json';
  static const int    _inputSize    = 224;

  // FC weights for CAM: [numClasses][numChannels]
  List<List<double>>? _fcWeights;
  int _numChannels = 512;   // YOLOv8n backbone (layers 0-9); overridden from JSON
  int _featureH    = 7;
  int _featureW    = 7;

  // Disease class names — must match the order of the model output
  static const List<String> _classNames = [
    'blister_blight',
    'healthy',
    'red_rust',
  ];

  // YOLOv8 normalization: pixel / 255, no mean/std subtraction
  static const List<double> _mean = [0.0, 0.0, 0.0];
  static const List<double> _std  = [1.0, 1.0, 1.0];

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      print('🧠 [DiseaseGradCAM] Loading explainable model...');
      _model = await PytorchLite.loadClassificationModel(
        _modelPath, _inputSize, _inputSize, _classNames.length,
      );

      print('📊 [DiseaseGradCAM] Loading FC weights...');
      final weightJson = await rootBundle.loadString(_weightsPath);
      final decoded    = json.decode(weightJson) as Map<String, dynamic>;

      // Support both top-level array and {fc_weights: [...]} formats
      final rawWeights =
          decoded.containsKey('fc_weights') ? decoded['fc_weights'] : decoded;

      _fcWeights = (rawWeights as List)
          .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
          .toList();

      // Override channel count from JSON metadata if present
      if (decoded.containsKey('num_channels')) {
        _numChannels = (decoded['num_channels'] as num).toInt();
      }
      if (decoded.containsKey('feature_h')) {
        _featureH = (decoded['feature_h'] as num).toInt();
      }
      if (decoded.containsKey('feature_w')) {
        _featureW = (decoded['feature_w'] as num).toInt();
      }

      _isInitialized = true;
      print('✅ [DiseaseGradCAM] Initialized — '
          '${_fcWeights!.length} classes × $_numChannels channels, '
          'feature map ${_featureH}×${_featureW}');
    } catch (e) {
      print('❌ [DiseaseGradCAM] Initialization failed: $e');
      rethrow;
    }
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Run inference AND generate a Grad-CAM heatmap overlay.
  ///
  /// Returns a record: (classIndex, confidence, probabilities, heatmapPath)
  Future<DiseaseCAMResult> predict(Uint8List imageBytes) async {
    if (!_isInitialized) await initialize();

    // 1. Run explainable model — returns [logits(3) + features(C*H*W)]
    final List<double> combined = await _model!.getImagePredictionList(
      imageBytes,
      mean: _mean,
      std: _std,
    );

    if (combined.length < _classNames.length) {
      throw Exception(
          '[DiseaseGradCAM] Model output too short: ${combined.length}');
    }

    // 2. Split logits vs feature maps
    final logits           = combined.sublist(0, _classNames.length);
    final featuresFlattened = combined.sublist(_classNames.length);

    // 3. Softmax probabilities
    final probs  = _softmax(logits);
    final classIdx = _argmax(probs);
    final confidence = probs[classIdx];

    print('[DiseaseGradCAM] Class: ${_classNames[classIdx]} '
        '(${(confidence * 100).toStringAsFixed(1)}%)');

    // 4. Generate CAM heatmap
    final baseImage = img.decodeImage(imageBytes);
    String? heatmapPath;
    if (baseImage != null && _fcWeights != null &&
        featuresFlattened.length >= _numChannels * _featureH * _featureW) {
      heatmapPath = await _generateHeatmap(
        baseImage,
        featuresFlattened,
        _fcWeights![classIdx],
      );
    }

    return DiseaseCAMResult(
      classIndex:   classIdx,
      className:    _classNames[classIdx],
      confidence:   confidence,
      probabilities: {
        for (int i = 0; i < _classNames.length; i++)
          _classNames[i]: probs[i]
      },
      heatmapPath: heatmapPath,
    );
  }

  // ─── CAM Generation ──────────────────────────────────────────────────────

  Future<String?> _generateHeatmap(
    img.Image baseImage,
    List<double> featuresFlattened,
    List<double> weights,
  ) async {
    try {
      final int h = _featureH;
      final int w = _featureW;
      final int c = _numChannels;

      // 1. Weighted sum of feature channels → raw CAM [h×w]
      // Layout: featuresFlattened = [c][h][w]  (channel-first / PyTorch convention)
      final cam = List.generate(h, (_) => List.filled(w, 0.0));
      for (int k = 0; k < c; k++) {
        final double weight = weights[k];
        final int channelOffset = k * h * w;
        for (int i = 0; i < h; i++) {
          final int rowOffset = channelOffset + i * w;
          for (int j = 0; j < w; j++) {
            cam[i][j] += weight * featuresFlattened[rowOffset + j];
          }
        }
      }

      // 2. ReLU + min-max normalize
      double maxVal = -double.infinity;
      for (int i = 0; i < h; i++) {
        for (int j = 0; j < w; j++) {
          if (cam[i][j] < 0) cam[i][j] = 0;
          if (cam[i][j] > maxVal) maxVal = cam[i][j];
        }
      }
      if (maxVal > 0) {
        for (int i = 0; i < h; i++) {
          for (int j = 0; j < w; j++) {
            cam[i][j] /= maxVal;
          }
        }
      }

      // 3. Prepare base image (resize & center-crop to 224×224)
      final img.Image processedBase = _preprocessForOverlay(baseImage);

      // 4. Build 7×7 grayscale heatmap image
      final img.Image camImage = img.Image(width: w, height: h);
      for (int i = 0; i < h; i++) {
        for (int j = 0; j < w; j++) {
          final int val = (cam[i][j] * 255).toInt();
          camImage.setPixelRgb(j, i, val, val, val);
        }
      }

      // 5. Upsample to 224×224 with bilinear interpolation
      final img.Image resizedCam = img.copyResize(
        camImage,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // 6. Apply JET-like colormap and blend with original image
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final hPixel = resizedCam.getPixel(x, y);
          final double hVal = hPixel.r / 255.0;

          // JET colormap
          final int r = (max(0.0, min(1.0, 1.5 - (4.0 * (hVal - 0.75).abs()))) * 255).toInt();
          final int g = (max(0.0, min(1.0, 1.5 - (4.0 * (hVal - 0.50).abs()))) * 255).toInt();
          final int b = (max(0.0, min(1.0, 1.5 - (4.0 * (hVal - 0.25).abs()))) * 255).toInt();

          final basePixel = processedBase.getPixel(x, y);
          // 40% original + 60% heatmap for clear visualization
          final finalR = (basePixel.r * 0.4 + r * 0.6).toInt();
          final finalG = (basePixel.g * 0.4 + g * 0.6).toInt();
          final finalB = (basePixel.b * 0.4 + b * 0.6).toInt();

          processedBase.setPixelRgb(x, y, finalR, finalG, finalB);
        }
      }

      // 7. Save to temp directory
      final tempDir  = await getTemporaryDirectory();
      final fullPath =
          '${tempDir.path}/disease_cam_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(fullPath).writeAsBytes(img.encodeJpg(processedBase));

      print('[DiseaseGradCAM] Heatmap saved: $fullPath');
      return fullPath;
    } catch (e) {
      print('[DiseaseGradCAM] Heatmap generation failed: $e');
      return null;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  img.Image _preprocessForOverlay(img.Image image) {
    final int width  = image.width;
    final int height = image.height;
    final double ratio  = 256.0 / min(width, height);
    final int newWidth  = (width * ratio).round();
    final int newHeight = (height * ratio).round();
    final img.Image resized =
        img.copyResize(image, width: newWidth, height: newHeight);
    return img.copyCrop(
      resized,
      x: (newWidth - _inputSize) ~/ 2,
      y: (newHeight - _inputSize) ~/ 2,
      width:  _inputSize,
      height: _inputSize,
    );
  }

  List<double> _softmax(List<double> logits) {
    final double maxLogit = logits.reduce(max);
    final exps = logits.map((l) => exp(l - maxLogit)).toList();
    final sum  = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  int _argmax(List<double> values) {
    int idx = 0;
    double maxVal = -double.infinity;
    for (int i = 0; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        idx    = i;
      }
    }
    return idx;
  }

  bool get isAvailable => _isInitialized && _model != null && _fcWeights != null;
}

// ─── Result Model ─────────────────────────────────────────────────────────────

class DiseaseCAMResult {
  final int    classIndex;
  final String className;
  final double confidence;
  final Map<String, double> probabilities;
  final String? heatmapPath;

  const DiseaseCAMResult({
    required this.classIndex,
    required this.className,
    required this.confidence,
    required this.probabilities,
    this.heatmapPath,
  });

  String get displayName {
    switch (className) {
      case 'healthy':        return 'Healthy';
      case 'red_rust':       return 'Red Rust';
      case 'blister_blight': return 'Blister Blight';
      default:
        return className
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
            .join(' ');
    }
  }
}
