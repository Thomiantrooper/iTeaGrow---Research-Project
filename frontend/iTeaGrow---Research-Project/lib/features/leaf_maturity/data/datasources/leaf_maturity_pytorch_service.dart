import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
import '../../domain/entities/leaf_maturity_result.dart';
import '../../domain/entities/leaf_detection.dart';
import 'leaf_maturity_color_validator.dart';
import 'leaf_segmenter_service.dart';

class LeafMaturityPyTorchService {
  ClassificationModel? _model;
  bool _isInitialized = false;

  final LeafSegmenterService _segmenter = LeafSegmenterService();

  static const String _modelPath = 'assets/models/tea_maturity_explain.ptl';
  static const int _inputSize = 224;

  // ImageNet mean and std
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];

  // ── Validation constants ───────────────────────────────────────────────
  static const int _maxImageSizeBytes = 20 * 1024 * 1024; // 20 MB
  static const int _minImageSizeBytes = 5 * 1024; // 5 KB
  static const Set<String> _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.bmp',
    '.tiff'
  };

  /// Tender vs Mature probability margin below which the result is ambiguous.
  static const double _ambiguityThreshold = 0.15;

  final MaturityColorValidator _colorValidator = MaturityColorValidator();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('LeafMaturity: Loading PyTorch explainability model...');

      _model = await PytorchLite.loadClassificationModel(
          _modelPath, _inputSize, _inputSize, 4);

      _isInitialized = true;
      debugPrint('LeafMaturity: Model and weights loaded successfully');
    } catch (e) {
      debugPrint('LeafMaturity: Error loading model assets: $e');
      rethrow;
    }
  }

  /// Helper: returns an error [LeafMaturityResult] for validation failures.
  LeafMaturityResult _validationError(String message) {
    return LeafMaturityResult(
      species: 'Unknown',
      maturity: 'Unknown',
      speciesConfidence: 0,
      maturityConfidence: 0,
      speciesProbabilities: {},
      maturityProbabilities: {},
      timestamp: DateTime.now(),
      rawConfidence: 0,
      isNotALeaf: true,
      validationMessage: message,
      confidenceLabel: 'Uncertain',
    );
  }

  Future<LeafMaturityResult> predict(XFile imageFile) async {
    if (!_isInitialized) await initialize();

    try {
      // ── 1. Pre-flight extension check ──────────────────────────────────
      final extension = imageFile.path.contains('.')
          ? '.${imageFile.path.split('.').last.toLowerCase()}'
          : '';
      if (extension.isNotEmpty && !_allowedExtensions.contains(extension)) {
        return _validationError(
            'Unsupported image format: $extension. Please use JPEG, PNG, or WebP.');
      }

      debugPrint('LeafMaturity: Running inference on ${imageFile.path}');
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // ── 2. File size check ─────────────────────────────────────────────
      if (imageBytes.length < _minImageSizeBytes) {
        return _validationError('Image file is too small '
            '(${(imageBytes.length / 1024).toStringAsFixed(1)} KB). '
            'Minimum is ${_minImageSizeBytes ~/ 1024} KB — the file may be corrupt.');
      }
      if (imageBytes.length > _maxImageSizeBytes) {
        return _validationError('Image file is too large '
            '(${(imageBytes.length / 1024 / 1024).toStringAsFixed(1)} MB). '
            'Maximum is ${_maxImageSizeBytes ~/ 1024 ~/ 1024} MB.');
      }

      final result = await _runInference(imageBytes);
      _saveToDb(result, imageFile.path);
      return result;
    } catch (e) {
      debugPrint('LeafMaturity: Inference error: $e');
      rethrow;
    }
  }

  /// Detects and classifies every leaf found in [imageFile].
  ///
  /// - If the image contains a plain background (white paper), the segmenter
  ///   finds each leaf automatically and classifies them individually.
  /// - If no regions are found (dark / coloured background), falls back to
  ///   classifying the full image as a single leaf.
  Future<List<LeafDetection>> predictMultiple(XFile imageFile) async {
    if (!_isInitialized) await initialize();

    final Uint8List imageBytes = await imageFile.readAsBytes();

    // ── file-size guard ────────────────────────────────────────────────
    if (imageBytes.length < _minImageSizeBytes ||
        imageBytes.length > _maxImageSizeBytes) {
      // Delegate the exact error message to predict() for consistency.
      final err = await predict(imageFile);
      return [LeafDetection(index: 0, bounds: const Rect.fromLTWH(0, 0, 0, 0), result: err)];
    }

    // ── Stage 1: segment ──────────────────────────────────────────────
    final regions = await _segmenter.segment(imageBytes);

    if (regions.isEmpty) {
      debugPrint('LeafSegmenter: no regions found — running full-image fallback');
      final result = await _runInference(imageBytes);
      return [LeafDetection(index: 0, bounds: const Rect.fromLTWH(0, 0, 0, 0), result: result)];
    }

    // ── Stage 2: classify each crop ───────────────────────────────────
    final List<LeafDetection> detections = [];
    for (int i = 0; i < regions.length; i++) {
      final region = regions[i];
      debugPrint('LeafMaturity: classifying leaf ${i + 1}/${regions.length}');
      final result = await _runInference(region.croppedBytes);
      _saveToDb(result, imageFile.path);
      detections.add(LeafDetection(
        index: i,
        bounds: region.bounds,
        result: result,
      ));
    }
    return detections;
  }

  /// Core ML inference + colour cross-validation for a single image buffer.
  Future<LeafMaturityResult> _runInference(Uint8List imageBytes) async {
    // ── ML inference ────────────────────────────────────────────────────
    final List<double> combined = await _model!.getImagePredictionList(
      imageBytes,
      mean: _mean,
      std: _std,
    );

    if (combined.length < 4) throw Exception('Incomplete model output');
    final List<double> logits = combined.sublist(0, 4);
    if (logits.any((v) => v.isNaN || v.isInfinite)) {
      throw Exception('Model produced invalid values (NaN/Inf)');
    }

    final probabilities = _softmax(logits);
    final baseResult = _extractResult(probabilities);

    // ── Colour cross-validation ──────────────────────────────────────────
    final colorResult = await _colorValidator.analyze(imageBytes);
    debugPrint(
        'LeafMaturity color: tender=${colorResult.tenderScore.toStringAsFixed(3)}, '
        'mature=${colorResult.matureScore.toStringAsFixed(3)}, '
        'suggested=${colorResult.suggestedMaturity}');

    final corrected = MaturityColorValidator.crossValidate(
      modelMaturity: baseResult.maturity,
      modelConfidence: baseResult.maturityConfidence,
      colorResult: colorResult,
    );

    // ── Ambiguity detection ──────────────────────────────────────────────
    final tenderProb = baseResult.maturityProbabilities['Tender'] ?? 0.0;
    final matureProb = baseResult.maturityProbabilities['Mature'] ?? 0.0;
    final isAmbiguous = (tenderProb - matureProb).abs() < _ambiguityThreshold;

    // ── Confidence banding ───────────────────────────────────────────────
    final conf = corrected.confidence;
    final confidenceLabel = conf >= 0.85
        ? 'High'
        : conf >= 0.70
            ? 'Moderate'
            : conf >= 0.55
                ? 'Low'
                : 'Uncertain';

    Map<String, double> finalMaturityProbs = baseResult.maturityProbabilities;
    if (corrected.maturity != baseResult.maturity) {
      final other = corrected.maturity == 'Tender' ? 'Mature' : 'Tender';
      finalMaturityProbs = {
        corrected.maturity: corrected.confidence,
        other: (1.0 - corrected.confidence).clamp(0.0, 1.0),
      };
    }

    return LeafMaturityResult(
      species: baseResult.species,
      maturity: corrected.maturity,
      speciesConfidence: baseResult.speciesConfidence,
      maturityConfidence: corrected.confidence,
      speciesProbabilities: baseResult.speciesProbabilities,
      maturityProbabilities: finalMaturityProbs,
      timestamp: baseResult.timestamp,
      rawConfidence: baseResult.rawConfidence,
      isAmbiguous: isAmbiguous,
      confidenceLabel: confidenceLabel,
      colorValidated: true,
    );
  }

  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce(max);
    final exps = logits.map((l) => exp(l - maxLogit)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
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

  Future<void> _saveToDb(LeafMaturityResult result, String imagePath) async {
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
        'species': result.species,
        'maturity': result.maturity,
        'species_confidence': result.speciesConfidence,
        'maturity_confidence': result.maturityConfidence,
        'raw_confidence': result.rawConfidence,
        'extra': null,
      };

      final response = await http
          .post(
            Uri.parse(ApiConfig.dbMaturity),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Leaf maturity saved to DB');
      } else {
        debugPrint('⚠️ DB error saving maturity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error saving leaf maturity to DB: $e');
    }
  }
}
