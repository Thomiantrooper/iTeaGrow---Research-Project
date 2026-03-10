import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/leaf_maturity_result.dart';
import 'leaf_maturity_color_validator.dart';

class LeafMaturityPyTorchService {
  ClassificationModel? _model;
  bool _isInitialized = false;

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

      // ── 3. ML inference ────────────────────────────────────────────────
      // Returns List<double>: [logits(4) + features(1024*7*7)]
      final List<double> combined = await _model!.getImagePredictionList(
        imageBytes,
        mean: _mean,
        std: _std,
      );

      if (combined.length < 4) throw Exception('Incomplete model output');

      final List<double> logits = combined.sublist(0, 4);

      // Guard against NaN / Inf
      if (logits.any((v) => v.isNaN || v.isInfinite)) {
        throw Exception('Model produced invalid values (NaN/Inf)');
      }

      final probabilities = _softmax(logits);
      final baseResult = _extractResult(probabilities);

      // ── 4. Colour cross-validation ─────────────────────────────────────
      final colorResult = await _colorValidator.analyze(imageBytes);
      debugPrint(
          'LeafMaturity color: tender=${colorResult.tenderScore.toStringAsFixed(3)}, '
          'mature=${colorResult.matureScore.toStringAsFixed(3)}, '
          'brown=${colorResult.brownScore.toStringAsFixed(3)}, '
          'suggested=${colorResult.suggestedMaturity}'
          '(${colorResult.suggestedConfidence.toStringAsFixed(2)})');

      final corrected = MaturityColorValidator.crossValidate(
        modelMaturity: baseResult.maturity,
        modelConfidence: baseResult.maturityConfidence,
        colorResult: colorResult,
      );
      debugPrint('LeafMaturity corrected: ${corrected.maturity} '
          '(${corrected.confidence.toStringAsFixed(2)}) [${corrected.source}]');

      // ── 5. Ambiguity detection ──────────────────────────────────────────
      final tenderProb = baseResult.maturityProbabilities['Tender'] ?? 0.0;
      final matureProb = baseResult.maturityProbabilities['Mature'] ?? 0.0;
      final isAmbiguous = (tenderProb - matureProb).abs() < _ambiguityThreshold;

      // ── 6. Confidence banding ───────────────────────────────────────────
      final conf = corrected.confidence;
      final confidenceLabel = conf >= 0.85
          ? 'High'
          : conf >= 0.70
              ? 'Moderate'
              : conf >= 0.55
                  ? 'Low'
                  : 'Uncertain';

      // If color cross-val flipped the maturity, rebuild the probability map
      // so the UI still shows sensible probability bars.
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
    } catch (e) {
      debugPrint('LeafMaturity: Inference/CAM error: $e');
      rethrow;
    }
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
}
