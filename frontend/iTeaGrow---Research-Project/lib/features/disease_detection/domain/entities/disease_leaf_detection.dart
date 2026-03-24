import 'dart:ui' show Rect;
import '../../../disease_detection/domain/entities/disease_detection_result.dart';

/// Pairs a detected leaf's bounding box with its disease classification result.
class DiseaseLeafDetection {
  /// Position of this leaf in the original image (pixel coordinates).
  final Rect bounds;

  /// The disease classification result for this individual leaf crop.
  final DiseaseDetectionResult result;

  /// Zero-based index of this leaf in the detection list.
  final int index;

  const DiseaseLeafDetection({
    required this.bounds,
    required this.result,
    required this.index,
  });
}
