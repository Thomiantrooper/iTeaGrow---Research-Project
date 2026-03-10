import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../../domain/entities/leaf_maturity_result.dart';

/// TFLite-based Tea Leaf Maturity Classification Service
///
/// Model: ShuffleNetV2 x1.0
/// Input: [1, 224, 224, 3] NHWC Float32
/// Output: [1, 4] Float32 logits
/// Classes: [Assamica/tender, Assamica/matured, DT1/tender, DT1/matured]
class LeafMaturityMLService {
  static final LeafMaturityMLService _instance =
      LeafMaturityMLService._internal();
  factory LeafMaturityMLService() => _instance;
  LeafMaturityMLService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;
  List<int> _inputShape = [];
  List<int> _outputShape = [];

  // Model configuration
  static const String _modelPath = 'assets/models/tea_maturity.tflite';
  static const int _inputSize = 224;
  static const int _numClasses = 4;

  // ImageNet normalization constants
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];

  /// Initialize the TFLite interpreter
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('LeafMaturityTFLite: Initializing model with Flex ops support...');

      final options = InterpreterOptions();

      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: options,
      );

      final inputTensor = _interpreter!.getInputTensor(0);
      debugPrint('LeafMaturityTFLite: Input shape (pre-alloc): ${inputTensor.shape}');

      _interpreter!.allocateTensors();

      _inputShape = List<int>.from(_interpreter!.getInputTensor(0).shape);
      _outputShape = List<int>.from(_interpreter!.getOutputTensor(0).shape);

      debugPrint('LeafMaturityTFLite: Initialized — input: $_inputShape, output: $_outputShape');

      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('LeafMaturityTFLite: Initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e.toString().contains('Flex') ||
          e.toString().contains('Select TF') ||
          e.toString().contains('failed to prepare')) {
        debugPrint('CRITICAL: Flex Ops missing — '
            'add tensorflow-lite-select-tf-ops to build.gradle');
      }
      rethrow;
    }
  }

  Future<LeafMaturityResult> predict(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 1. Load and preprocess image
      debugPrint('LeafMaturityTFLite: Preprocessing $imagePath');
      final input = await _preprocessImage(imagePath);

      // Validate input size against expected shape
      final expectedInputSize = _inputShape.reduce((a, b) => a * b);
      if (input.length != expectedInputSize) {
        throw Exception(
            'Input size mismatch: expected $expectedInputSize, got ${input.length}.');
      }

      // 2. Prepare output buffer
      final expectedOutputSize = _outputShape.reduce((a, b) => a * b);
      final output = Float32List(expectedOutputSize);

      // 3. Run inference
      final inferenceStopwatch = Stopwatch()..start();
      _interpreter!.run(input, output);
      inferenceStopwatch.stop();
      debugPrint('LeafMaturityTFLite: Inference in ${inferenceStopwatch.elapsedMilliseconds}ms');

      // Validate output
      if (output.any((v) => v.isNaN || v.isInfinite)) {
        throw Exception('Model produced invalid values (NaN/Inf)');
      }

      // 4. Post-process
      final logits = output.toList();
      final probabilities = _softmax(logits);

      stopwatch.stop();
      debugPrint('LeafMaturityTFLite: Done in ${stopwatch.elapsedMilliseconds}ms');

      return _extractResult(probabilities);
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('LeafMaturityTFLite: Prediction failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Preprocess image following training pipeline
  /// Adaptive detection for NHWC vs NCHW layouts
  Future<Float32List> _preprocessImage(String imagePath) async {
    // Load image
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Step 1: Resize to 256 (shorter edge)
    image = _resizeShorterEdge(image, 256);

    // Step 2: Center crop to 224x224
    image = _centerCrop(image, _inputSize);

    // Detect actual tensor shape to decide layout
    final inputTensor = _interpreter!.getInputTensor(0);
    final inputShape = inputTensor.shape;

    // NHWC: [batch, height, width, channels] -> shape[3] == 3
    // NCHW: [batch, channels, height, width] -> shape[1] == 3
    final bool isNCHW = inputShape[1] == 3;
    final int totalSize = 1 * 3 * _inputSize * _inputSize;
    final input = Float32List(totalSize);
    var bufferIndex = 0;

    if (!isNCHW) {
      // NHWC Layout (Standard TFLite)
      for (var y = 0; y < _inputSize; y++) {
        for (var x = 0; x < _inputSize; x++) {
          final pixel = image.getPixel(x, y);

          // Correct Pixel API for image 4.x
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();

          input[bufferIndex++] = ((r / 255.0) - _mean[0]) / _std[0];
          input[bufferIndex++] = ((g / 255.0) - _mean[1]) / _std[1];
          input[bufferIndex++] = ((b / 255.0) - _mean[2]) / _std[2];
        }
      }
    } else {
      // NCHW Layout (Standard PyTorch)
      // Fill all reds, then all greens, then all blues
      for (var c = 0; c < 3; c++) {
        for (var y = 0; y < _inputSize; y++) {
          for (var x = 0; x < _inputSize; x++) {
            final pixel = image.getPixel(x, y);

            double value;
            if (c == 0)
              value = pixel.r.toDouble();
            else if (c == 1)
              value = pixel.g.toDouble();
            else
              value = pixel.b.toDouble();

            input[bufferIndex++] = ((value / 255.0) - _mean[c]) / _std[c];
          }
        }
      }
    }

    debugPrint(
        'LeafMaturityTFLite: Input layout: ${isNCHW ? "NCHW" : "NHWC"}, shape: $_inputShape');
    return input;
  }

  /// Resize image keeping aspect ratio (shorter edge = targetSize)
  /// Matches PyTorch's transforms.Resize(256)
  img.Image _resizeShorterEdge(img.Image image, int targetSize) {
    final width = image.width;
    final height = image.height;

    int newWidth, newHeight;

    if (width < height) {
      newWidth = targetSize;
      newHeight = (height * targetSize / width).round();
    } else {
      newHeight = targetSize;
      newWidth = (width * targetSize / height).round();
    }

    return img.copyResize(image, width: newWidth, height: newHeight);
  }

  /// Center crop to target size
  /// Matches PyTorch's transforms.CenterCrop(224)
  img.Image _centerCrop(img.Image image, int cropSize) {
    if (image.width < cropSize || image.height < cropSize) {
      // If image is smaller than crop size, resize it first
      return img.copyResize(image, width: cropSize, height: cropSize);
    }

    final x = (image.width - cropSize) ~/ 2;
    final y = (image.height - cropSize) ~/ 2;

    return img.copyCrop(image, x: x, y: y, width: cropSize, height: cropSize);
  }

  /// Softmax function to convert logits to probabilities
  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final expValues = logits.map((x) => math.exp(x - maxLogit)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }

  /// Extract result from probabilities
  LeafMaturityResult _extractResult(List<double> probabilities) {
    // Classes: [Assamica/tender, Assamica/matured, DT1/tender, DT1/matured]
    final speciesProbs = {
      'Assamica': probabilities[0] + probabilities[1],
      'DT1': probabilities[2] + probabilities[3],
    };

    final maturityProbs = {
      'Tender': probabilities[0] + probabilities[2],
      'Mature': probabilities[1] + probabilities[3],
    };

    // Find winners
    final species =
        speciesProbs.entries.reduce((a, b) => a.value > b.value ? a : b);
    final maturity =
        maturityProbs.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Calculate raw confidence (highest probability in the 4 classes)
    final rawConfidence = probabilities.reduce(math.max);

    return LeafMaturityResult(
      species: species.key,
      maturity: maturity.key,
      speciesConfidence: species.value,
      maturityConfidence: maturity.value,
      speciesProbabilities: speciesProbs,
      maturityProbabilities: maturityProbs,
      timestamp: DateTime.now(),
      rawConfidence: rawConfidence,
    );
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
