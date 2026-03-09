import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, compute;
import 'package:image/image.dart' as img;

/// Result of pre-scan powder validation.
class PowderValidationResult {
  final bool isValid;
  final String message;
  final double powderScore;
  final double sharpnessScore;

  const PowderValidationResult({
    required this.isValid,
    required this.message,
    this.powderScore = 0.0,
    this.sharpnessScore = 0.0,
  });
}

/// Pre-scan validation service that checks whether an uploaded image
/// contains tea powder before sending it through grading ML.
///
/// Checks performed:
/// 1. Image decodability and minimum resolution (64×64)
/// 2. Sharpness via Laplacian variance
/// 3. Colour variance (rejects blank / solid-colour surfaces)
/// 4. Green-dominant rejection (image is a leaf, not powder)
/// 5. Brown/dark pixel ratio (hallmark of dry tea powder)
class PowderValidationService {
  static final PowderValidationService _instance =
      PowderValidationService._internal();
  factory PowderValidationService() => _instance;
  PowderValidationService._internal();

  // ── Thresholds (tuned for CTC dry tea powder photos on mobile) ───────
  // Powder is less sharp than a crisp leaf, so sharpness bar is lower.
  static const double _minSharpness = 6.0;
  // Powder is relatively uniform; set a lower variance bar than leaves.
  static const double _minColourVariance = 120.0;
  // Raised from 0.12 → 0.22: 12 % was too lenient (dark floors/wood passed).
  static const double _minPowderRatio = 0.22;
  // Reject if > 25 % of pixels are clearly green (it's a leaf, not powder).
  static const double _maxGreenRatio = 0.25;
  // Reject if > 40 % of pixels are inorganic surfaces (cables, electronics).
  static const double _maxInorganicRatio = 0.40;
  static const int _minDimension = 64;

  /// Validate image bytes. Heavy pixel work runs in an isolate.
  Future<PowderValidationResult> validate(Uint8List imageBytes) async {
    try {
      return await compute(_analyzeImage, imageBytes);
    } catch (e) {
      debugPrint('PowderValidation error: $e');
      // On analysis failure, let the image through so the user isn't blocked.
      return const PowderValidationResult(isValid: true, message: '');
    }
  }

  /// Static top-level function — must be top-level or static to run via [compute].
  static PowderValidationResult _analyzeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return const PowderValidationResult(
        isValid: false,
        message:
            'Unable to process this image. Please upload a clear photo of the tea powder.',
      );
    }

    if (image.width < _minDimension || image.height < _minDimension) {
      return const PowderValidationResult(
        isValid: false,
        message:
            'Image resolution is too low. Please capture a closer, clearer photo.',
      );
    }

    // Down-sample large images for fast analysis.
    final analysisImg = (image.width > 512 || image.height > 512)
        ? img.copyResize(image, width: 512)
        : image;

    final sharpness = _computeSharpness(analysisImg);
    final colourVariance = _computeColourVariance(analysisImg);
    final greenRatio = _computeGreenRatio(analysisImg);
    final powderRatio = _computePowderRatio(analysisImg);
    final inorganicRatio = _computeInorganicRatio(analysisImg);

    if (sharpness < _minSharpness) {
      return PowderValidationResult(
        isValid: false,
        message:
            'The image appears blurry. Please hold the camera steady and capture a clear photo of the powder.',
        sharpnessScore: sharpness,
      );
    }

    if (colourVariance < _minColourVariance) {
      return PowderValidationResult(
        isValid: false,
        message:
            'Image does not appear to contain tea powder. Please scan a powder sample on a plain surface.',
        sharpnessScore: sharpness,
      );
    }

    if (greenRatio > _maxGreenRatio) {
      return PowderValidationResult(
        isValid: false,
        message:
            'This does not appear to be a tea powder image. Please scan a dry tea powder sample.',
        powderScore: powderRatio,
        sharpnessScore: sharpness,
      );
    }

    // Reject images dominated by inorganic surfaces (electronic devices,
    // cables, metal). Such images can accidentally satisfy the powder-colour
    // check due to coloured backgrounds.
    if (inorganicRatio > _maxInorganicRatio) {
      return PowderValidationResult(
        isValid: false,
        message:
            'No tea powder detected. Please place the powder sample in the frame and ensure good lighting.',
        powderScore: powderRatio,
        sharpnessScore: sharpness,
      );
    }

    if (powderRatio < _minPowderRatio) {
      return PowderValidationResult(
        isValid: false,
        message:
            'No tea powder detected. Ensure the powder fills the frame and is well-lit.',
        powderScore: powderRatio,
        sharpnessScore: sharpness,
      );
    }

    return PowderValidationResult(
      isValid: true,
      message: '',
      powderScore: powderRatio,
      sharpnessScore: sharpness,
    );
  }

  // ── Pixel analysers ───────────────────────────────────────────────────

  /// Fraction of pixels with brownish/dark colour typical of dry tea powder.
  ///
  /// Two sub-cases:
  ///  * Very dark CTC black powder: V < 0.25 (value component in HSV)
  ///  * Brownish powder:           H 8–45°, S > 0.15, V 0.10–0.65
  static double _computePowderRatio(img.Image image) {
    int powderPixels = 0;
    final total = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        // HSV conversion
        final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
        final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
        final v = maxC / 255.0;
        final delta = maxC - minC;
        final s = maxC > 0 ? delta / maxC : 0.0;

        double hue = 0.0;
        if (delta > 0) {
          if (maxC == r) {
            hue = 60.0 * (((g - b) / delta) % 6);
          } else if (maxC == g) {
            hue = 60.0 * ((b - r) / delta + 2);
          } else {
            hue = 60.0 * ((r - g) / delta + 4);
          }
          if (hue < 0) hue += 360.0;
        }

        // Brownish-black powder: requires BOTH brownish hue AND saturation.
        // Removed the pure `v < 0.25` catch-all that matched any dark surface
        // (dark wood, dark clothes, dark floors, etc.).
        if (hue >= 5 && hue <= 50 && s > 0.20 && v > 0.08 && v < 0.62) {
          powderPixels++;
        }
      }
    }

    return powderPixels / total;
  }

  /// Fraction of pixels where green clearly dominates (leaf indicator).
  /// Fraction of pixels that match natural leaf green using HSV hue ranges.
  /// Uses HSV instead of raw channel dominance so that teal/cyan UI colours
  /// (H > 155°) are NOT counted as leaf green (H 60–155°).
  static double _computeGreenRatio(img.Image image) {
    int greenPixels = 0;
    final total = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
        final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
        final v = maxC / 255.0;
        final delta = maxC - minC;
        final s = maxC > 0 ? delta / maxC : 0.0;

        double hue = 0.0;
        if (delta > 0) {
          if (maxC == r) {
            hue = 60.0 * (((g - b) / delta) % 6);
          } else if (maxC == g) {
            hue = 60.0 * ((b - r) / delta + 2);
          } else {
            hue = 60.0 * ((r - g) / delta + 4);
          }
          if (hue < 0) hue += 360.0;
        }

        // Leaf-like green: hue 60–155°. Excludes teal/cyan (H > 155°).
        if (hue >= 60 && hue <= 155 && s > 0.15 && v > 0.12) {
          greenPixels++;
        }
      }
    }

    return greenPixels / total;
  }

  /// Laplacian-variance sharpness. Very low values = heavy blur.
  static double _computeSharpness(img.Image image) {
    final gray = img.grayscale(img.copyResize(image, width: 256));
    double sum = 0;
    int count = 0;

    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final center = gray.getPixel(x, y).r.toInt();
        final laplacian = (4 * center -
                gray.getPixel(x - 1, y).r.toInt() -
                gray.getPixel(x + 1, y).r.toInt() -
                gray.getPixel(x, y - 1).r.toInt() -
                gray.getPixel(x, y + 1).r.toInt())
            .toDouble();
        sum += laplacian * laplacian;
        count++;
      }
    }

    return count > 0 ? sum / count : 0;
  }

  /// Colour variance across RGB channels. Very low = blank/solid surface.
  static double _computeColourVariance(img.Image image) {
    double sumR = 0, sumG = 0, sumB = 0;
    double sumR2 = 0, sumG2 = 0, sumB2 = 0;
    final n = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        sumR += r;
        sumG += g;
        sumB += b;
        sumR2 += r * r;
        sumG2 += g * g;
        sumB2 += b * b;
      }
    }

    final varR = (sumR2 / n) - (sumR / n) * (sumR / n);
    final varG = (sumG2 / n) - (sumG / n) * (sumG / n);
    final varB = (sumB2 / n) - (sumB / n) * (sumB / n);

    return varR + varG + varB;
  }

  /// Fraction of pixels that are clearly inorganic:
  ///  * Very dark (V < 0.10)           — black cables, dark plastic
  ///  * Metallic grey (S < 0.16, V 0.12–0.72) — electronic casings, metal
  static double _computeInorganicRatio(img.Image image) {
    int inorganicPixels = 0;
    final total = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
        final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
        final v = maxC / 255.0;
        final s = maxC > 0 ? (maxC - minC) / maxC : 0.0;

        if (v < 0.10) {
          inorganicPixels++;
        } else if (s < 0.16 && v >= 0.12 && v <= 0.72) {
          inorganicPixels++;
        }
      }
    }

    return inorganicPixels / total;
  }
}
