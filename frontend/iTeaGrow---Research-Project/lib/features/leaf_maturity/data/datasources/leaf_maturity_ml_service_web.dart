// Web stub — tflite_flutter uses dart:ffi which is not available on web.
// All ML inference is skipped; callers should fall back to the cloud API.
import '../../domain/entities/leaf_maturity_result.dart';

class LeafMaturityMLService {
  static final LeafMaturityMLService _instance =
      LeafMaturityMLService._internal();
  factory LeafMaturityMLService() => _instance;
  LeafMaturityMLService._internal();

  bool get isInitialized => false;

  Future<void> initialize() async {
    // no-op on web
  }

  Future<LeafMaturityResult> predict(String imagePath) async {
    throw UnsupportedError(
      'On-device TFLite inference is not supported on web. '
      'Use the cloud API instead.',
    );
  }

  void dispose() {
    // no-op on web
  }
}
