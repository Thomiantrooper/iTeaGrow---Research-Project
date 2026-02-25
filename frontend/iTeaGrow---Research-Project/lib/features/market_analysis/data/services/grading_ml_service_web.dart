// Web stub — tflite_flutter uses dart:ffi which is not available on web.
// All ML inference is skipped; callers should use the cloud API.
import '../models/market_models.dart';

class GradingMlService {
  Future<void> initModel() async {
    // no-op on web
  }

  Future<ClassificationResult?> classifyImage(
    dynamic imageFile, {
    bool generateHeatmap = true,
  }) async {
    throw UnsupportedError(
      'On-device TFLite grading is not supported on web. '
      'Use the cloud API instead.',
    );
  }

  void dispose() {
    // no-op on web
  }
}
