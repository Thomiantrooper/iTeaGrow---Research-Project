import 'dart:ui' show Rect;
import 'leaf_maturity_result.dart';

/// Represents a single detected tea leaf within a multi-leaf image.
///
/// [bounds] is the bounding box in the original image's pixel coordinates.
/// [result] is the ShuffleNetV2 classification result for that cropped leaf.
class LeafDetection {
  final int index;
  final Rect bounds;
  final LeafMaturityResult result;

  const LeafDetection({
    required this.index,
    required this.bounds,
    required this.result,
  });
}
