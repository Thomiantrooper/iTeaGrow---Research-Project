import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
import '../models/market_models.dart';

class GradingMlService {
  Interpreter? _interpreter;
  final List<String> _labels = [
    'BOP',
    'BOPF',
    'Dust',
    'Dust1',
    'Fanning1',
    'Pekoe',
  ];

  // ── Validation constants ────────────────────────────────────────────────
  static const int _maxImageSizeBytes = 20 * 1024 * 1024; // 20 MB
  static const int _minImageSizeBytes = 5 * 1024; // 5 KB
  static const Set<String> _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.bmp',
    '.tiff',
  };

  /// Ambiguity threshold: if top-1 − top-2 probability gap is less than
  /// this, flag the result as ambiguous (6-class problem — use tighter gap).
  static const double _ambiguityThreshold = 0.12;

  Future<void> initModel() async {
    try {
      // Load explainable model with multi-outputs
      _interpreter = await Interpreter.fromAsset(
          'assets/models/grading_model_explain.tflite');
      _interpreter!.allocateTensors();
    } catch (e) {
      debugPrint('GradingML: failed to load model/weights: $e');
      throw Exception('Model initialization failed');
    }
  }

  /// Returns a validation-failure result (non-null so the screen shows an
  /// error card rather than falling through to the online API).
  ClassificationResult _validationError(String message) => ClassificationResult(
        grade: 'Unknown',
        confidence: 0,
        source: 'offline',
        isValidationFailure: true,
        validationMessage: message,
        confidenceLabel: 'Uncertain',
      );

  Future<ClassificationResult?> classifyImage(File imageFile,
      {bool generateHeatmap = true}) async {
    // ── Layer 1: file extension ──────────────────────────────────────────
    final ext = '.${imageFile.path.split('.').last.toLowerCase()}';
    if (!_allowedExtensions.contains(ext)) {
      return _validationError(
          'Unsupported file format. Please use JPG, PNG, or WebP.');
    }

    // ── Layer 2: file size ───────────────────────────────────────────────
    final fileSize = await imageFile.length();
    if (fileSize < _minImageSizeBytes) {
      return _validationError(
          'Image file is too small. Please capture a clear powder photo.');
    }
    if (fileSize > _maxImageSizeBytes) {
      return _validationError(
          'Image file is too large (max 20 MB). Please use a compressed photo.');
    }

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

    // ── Layer 3: NaN / Inf guard ─────────────────────────────────────────
    final List<double> probabilities =
        List<double>.from((outputs[1] as List)[0]);
    if (probabilities.any((p) => p.isNaN || p.isInfinite)) {
      debugPrint('GradingML: NaN/Inf in probabilities — skipping result');
      return null;
    }

    // ── Layer 4: find top-1 and top-2 ────────────────────────────────────
    int maxIndex = -1;
    int secondIndex = -1;
    double maxConfidence = 0.0;
    double secondConfidence = 0.0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        secondIndex = maxIndex;
        secondConfidence = maxConfidence;
        maxConfidence = probabilities[i];
        maxIndex = i;
      } else if (probabilities[i] > secondConfidence) {
        secondIndex = i;
        secondConfidence = probabilities[i];
      }
    }

    if (maxIndex == -1) return null;

    // ── Layer 5: ambiguity detection ─────────────────────────────────────
    final isAmbiguous = secondIndex != -1 &&
        (maxConfidence - secondConfidence) < _ambiguityThreshold;

    // ── Layer 6: confidence banding ──────────────────────────────────────
    final String confidenceLabel;
    if (maxConfidence >= 0.85) {
      confidenceLabel = 'High';
    } else if (maxConfidence >= 0.70) {
      confidenceLabel = 'Moderate';
    } else if (maxConfidence >= 0.55) {
      confidenceLabel = 'Low';
    } else {
      confidenceLabel = 'Uncertain';
    }

    final result = ClassificationResult(
      grade: _labels[maxIndex],
      confidence: maxConfidence * 100,
      source: 'offline',
      imageFile: imageFile,
      confidenceLabel: confidenceLabel,
      isAmbiguous: isAmbiguous,
    );

    // Save to DB Microservice (awaited to ensure data integrity)
    await _saveToDb(result, imageFile.path);

    return result;
  }

  Future<void> _saveToDb(ClassificationResult result, String imagePath) async {
    try {
      String? imageBase64;
      final file = File(imagePath);
      if (await file.exists()) {
        imageBase64 = base64Encode(await file.readAsBytes());
      }

      final body = {
        'user_id': null,
        'image_path': imagePath,
        'image_data': imageBase64,
        'grade': result.grade,
        'confidence': result.confidence,
        'confidence_label': result.confidenceLabel,
        'source': 'offline',
        'is_ambiguous': result.isAmbiguous,
        'extra': null,
      };
      final response = await http
          .post(
            Uri.parse(ApiConfig.dbPowder),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Offline powder grading saved to DB');
      } else {
        debugPrint('⚠️ DB error saving powder grade: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error saving offline powder grading: $e');
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
