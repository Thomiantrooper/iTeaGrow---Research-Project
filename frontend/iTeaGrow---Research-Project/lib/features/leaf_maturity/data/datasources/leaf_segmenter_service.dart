import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image/image.dart' as img;

/// A pure-Dart leaf segmenter that finds individual leaves on a
/// controlled light (white/cream) background.
///
/// Works best when leaves are placed on a white A4 sheet.
/// Slightly overlapping leaves are handled by Non-Maximum Suppression (NMS).
class LeafSegmenterService {
  /// Padding added around each bounding box before cropping.
  static const int _cropPadding = 12;

  /// Brightness threshold (0–255). Pixels darker than this value are
  /// considered "leaf" (foreground); brighter pixels are "background".
  /// 200 works well for white paper.
  static const int _brightnessThreshold = 200;

  /// IoU threshold for NMS. Boxes overlapping by more than this fraction
  /// are considered duplicates — only the larger one is kept.
  static const double _nmsIouThreshold = 0.40;

  /// Segments [imageBytes] into cropped leaf images.
  ///
  /// Returns a list of [LeafRegion] records, each containing:
  /// - [bounds]: bounding box in original image pixel coordinates.
  /// - [croppedBytes]: JPEG bytes of the cropped region, ready for ML.
  ///
  /// Returns an **empty list** when no valid leaf regions are found —
  /// the caller should fall back to full-image inference.
  Future<List<LeafRegion>> segment(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      debugPrint('LeafSegmenter: failed to decode image');
      return [];
    }

    final int w = image.width;
    final int h = image.height;

    // ── 1. Build a binary mask: true = foreground (dark leaf) ──────────
    final List<bool> mask = List<bool>.filled(w * h, false);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = image.getPixel(x, y);
        if (_pixelBrightness(pixel) < _brightnessThreshold) {
          mask[y * w + x] = true;
        }
      }
    }

    // ── 2. Connected-component labelling (row-scan + union-find) ───────
    final List<int> labels = List<int>.filled(w * h, 0);
    final Map<int, int> parent = {};
    int nextLabel = 1;

    int find(int x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]!]!;
        x = parent[x]!;
      }
      return x;
    }

    void unite(int a, int b) {
      a = find(a);
      b = find(b);
      if (a != b) parent[a] = b;
    }

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = y * w + x;
        if (!mask[idx]) continue;

        final int left = (x > 0 && mask[idx - 1]) ? labels[idx - 1] : 0;
        final int above = (y > 0 && mask[idx - w]) ? labels[idx - w] : 0;

        if (left == 0 && above == 0) {
          labels[idx] = nextLabel;
          parent[nextLabel] = nextLabel;
          nextLabel++;
        } else if (left != 0 && above == 0) {
          labels[idx] = left;
        } else if (above != 0 && left == 0) {
          labels[idx] = above;
        } else {
          labels[idx] = above;
          unite(left, above);
        }
      }
    }

    // ── 3. Resolve labels → bounding boxes ─────────────────────────────
    final Map<int, _BBox> bboxMap = {};
    for (int idx = 0; idx < w * h; idx++) {
      if (labels[idx] == 0) continue;
      final root = find(labels[idx]);
      final x = idx % w;
      final y = idx ~/ w;
      final bbox = bboxMap.putIfAbsent(root, () => _BBox(x, y, x, y));
      bbox.extend(x, y);
    }

    // ── 4. Filter by minimum size ────────────────────────────────────────
    // Use 0.3% of total image area as the minimum. For a 1024×1024 image
    // that is ~3,145 px² — small enough to catch large leaves but large
    // enough to reject shadow/noise specks between overlapping leaves.
    // Clamped between 4,000 and 80,000 px² to handle all image sizes.
    final int minArea = ((w * h) * 0.003).round().clamp(4000, 80000);
    final List<_BBox> validBoxes =
        bboxMap.values.where((b) => b.area >= minArea).toList();

    // ── 5. Non-Maximum Suppression (NMS) ────────────────────────────────
    // Sort largest-area first. Reject any candidate that overlaps an
    // already-kept box by more than _nmsIouThreshold.
    // This collapses phantom detections produced by overlapping leaves.
    validBoxes.sort((a, b) => b.area.compareTo(a.area));
    final List<_BBox> kept = [];
    for (final candidate in validBoxes) {
      bool suppressed = false;
      for (final keeper in kept) {
        if (_iou(candidate, keeper) > _nmsIouThreshold) {
          suppressed = true;
          break;
        }
      }
      if (!suppressed) kept.add(candidate);
    }

    // ── 6. Pad and crop each surviving box ──────────────────────────────
    final List<LeafRegion> regions = [];
    for (final bbox in kept) {
      final x1 = (bbox.minX - _cropPadding).clamp(0, w - 1);
      final y1 = (bbox.minY - _cropPadding).clamp(0, h - 1);
      final x2 = (bbox.maxX + _cropPadding).clamp(0, w - 1);
      final y2 = (bbox.maxY + _cropPadding).clamp(0, h - 1);

      final cropped = img.copyCrop(
        image,
        x: x1,
        y: y1,
        width: x2 - x1,
        height: y2 - y1,
      );

      regions.add(LeafRegion(
        bounds: Rect.fromLTRB(
          x1.toDouble(),
          y1.toDouble(),
          x2.toDouble(),
          y2.toDouble(),
        ),
        croppedBytes: Uint8List.fromList(img.encodeJpg(cropped, quality: 90)),
      ));
    }

    debugPrint('LeafSegmenter: raw=${bboxMap.length}, '
        'after size filter=${validBoxes.length}, '
        'after NMS=${regions.length}');
    return regions;
  }

  /// Intersection-over-Union of two bounding boxes.
  double _iou(_BBox a, _BBox b) {
    final interX1 = a.minX > b.minX ? a.minX : b.minX;
    final interY1 = a.minY > b.minY ? a.minY : b.minY;
    final interX2 = a.maxX < b.maxX ? a.maxX : b.maxX;
    final interY2 = a.maxY < b.maxY ? a.maxY : b.maxY;
    if (interX2 <= interX1 || interY2 <= interY1) return 0.0;
    final intersection = (interX2 - interX1) * (interY2 - interY1);
    final union = a.area + b.area - intersection;
    return union == 0 ? 0.0 : intersection / union;
  }

  /// Convert a pixel to 0-255 luminance (ITU-R BT.709).
  int _pixelBrightness(img.Pixel pixel) {
    return ((0.2126 * pixel.r.toInt()) +
            (0.7152 * pixel.g.toInt()) +
            (0.0722 * pixel.b.toInt()))
        .round();
  }
}

/// A detected leaf region.
class LeafRegion {
  /// Bounding box in the original image's pixel space.
  final Rect bounds;

  /// JPEG bytes of the cropped leaf — ready to pass directly to the ML model.
  final Uint8List croppedBytes;

  const LeafRegion({required this.bounds, required this.croppedBytes});
}

/// Internal mutable bounding-box accumulator.
class _BBox {
  int minX, minY, maxX, maxY;
  _BBox(this.minX, this.minY, this.maxX, this.maxY);

  void extend(int x, int y) {
    if (x < minX) minX = x;
    if (y < minY) minY = y;
    if (x > maxX) maxX = x;
    if (y > maxY) maxY = y;
  }

  int get area => (maxX - minX) * (maxY - minY);
}
