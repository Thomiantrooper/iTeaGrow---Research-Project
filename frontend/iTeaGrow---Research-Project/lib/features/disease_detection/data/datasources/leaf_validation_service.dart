import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, compute;
import 'package:image/image.dart' as img;

/// Result of pre-scan leaf validation.
class LeafValidationResult {
  final bool isValid;
  final String message;
  final double greenScore;
  final double sharpnessScore;
  final double leafLikelihood;

  const LeafValidationResult({
    required this.isValid,
    required this.message,
    this.greenScore = 0.0,
    this.sharpnessScore = 0.0,
    this.leafLikelihood = 0.0,
  });
}

/// Pre-scan validation service that checks whether an uploaded image
/// clearly contains a natural leaf before sending it through disease detection.
///
/// Checks performed:
/// 1. Image decodability and minimum resolution
/// 2. Green-dominance analysis (natural leaf colour presence)
/// 3. Sharpness / blur detection via Laplacian variance
/// 4. Colour variance (rejects uniform solid-colour images)
class LeafValidationService {
  static final LeafValidationService _instance =
      LeafValidationService._internal();
  factory LeafValidationService() => _instance;
  LeafValidationService._internal();

  // Thresholds (tuned for tea-leaf photos taken on mobile)
  // Lowered back towards 0.06: 0.12 was too strict for dark green leaves
  // (mature/older tea leaves) photographed on white/light backgrounds.
  static const double _minGreenRatio = 0.06;
  static const double _minSharpness = 5.0;
  static const double _minColourVariance = 180.0;
  static const int _minDimension = 64;
  // Max fraction of inorganic pixels (very dark + metallic grey).
  // Catches electronic devices, cables, metal objects that have enough
  // green background to pass the green-ratio check.
  // Raised 35 % → 50 %: leaves photographed on white/cream paper surfaces
  // produce large low-saturation backgrounds that were previously over-counted.
  static const double _maxInorganicRatio = 0.50;

  /// Validate image bytes. Runs heavy pixel work on an isolate.
  Future<LeafValidationResult> validate(Uint8List imageBytes) async {
    try {
      return await compute(_analyzeImage, imageBytes);
    } catch (e) {
      debugPrint('LeafValidation error: $e');
      // If analysis fails, let the image through to avoid blocking the user
      return const LeafValidationResult(
        isValid: true,
        message: '',
      );
    }
  }

  /// Static top-level function so it can run in an isolate via [compute].
  static LeafValidationResult _analyzeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return const LeafValidationResult(
        isValid: false,
        message: 'Unable to process this image. Please upload a clear photo of a leaf.',
      );
    }

    if (image.width < _minDimension || image.height < _minDimension) {
      return const LeafValidationResult(
        isValid: false,
        message:
            'The image resolution is too low. Please capture a clearer, closer photo of the leaf.',
      );
    }

    // Down-sample large images for fast analysis
    final analysisImg = (image.width > 512 || image.height > 512)
        ? img.copyResize(image, width: 512)
        : image;

    final greenScore = _computeGreenRatio(analysisImg);
    final sharpness = _computeSharpness(analysisImg);
    final colourVariance = _computeColourVariance(analysisImg);
    final inorganicRatio = _computeInorganicRatio(analysisImg);

    // --- Decision logic ---
    if (sharpness < _minSharpness) {
      return LeafValidationResult(
        isValid: false,
        message:
            'The image appears blurry. Please hold the camera steady and capture a clearer image of the leaf.',
        greenScore: greenScore,
        sharpnessScore: sharpness,
        leafLikelihood: 0.0,
      );
    }

    if (colourVariance < _minColourVariance) {
      return LeafValidationResult(
        isValid: false,
        message:
            'The image does not appear to contain a leaf. Please scan a real tea leaf.',
        greenScore: greenScore,
        sharpnessScore: sharpness,
        leafLikelihood: 0.0,
      );
    }

    // If there is sufficient green content the image contains a leaf —
    // skip the inorganic check so leaves on white / light-gray backgrounds
    // (paper, foam board, lab surfaces) are not incorrectly rejected.
    if (greenScore < _minGreenRatio) {
      // Low green: now also check inorganic ratio to catch electronic devices
      // that happen to pass due to colourful fabric in the background.
      if (inorganicRatio > _maxInorganicRatio) {
        return LeafValidationResult(
          isValid: false,
          message:
              'No leaf detected. Please point the camera directly at a tea leaf in good lighting.',
          greenScore: greenScore,
          sharpnessScore: sharpness,
          leafLikelihood: 0.0,
        );
      }
      return LeafValidationResult(
        isValid: false,
        message:
            'No leaf detected in the image. Please ensure the leaf is clearly visible and well-lit.',
        greenScore: greenScore,
        sharpnessScore: sharpness,
        leafLikelihood: greenScore / _minGreenRatio,
      );
    }

    // Compute an overall leaf-likelihood score (0..1)
    final likelihood = _clamp01(
      (greenScore / 0.30).clamp(0.0, 1.0) * 0.4 +
      (sharpness / 100.0).clamp(0.0, 1.0) * 0.3 +
      (colourVariance / 2000.0).clamp(0.0, 1.0) * 0.3,
    );

    return LeafValidationResult(
      isValid: true,
      message: '',
      greenScore: greenScore,
      sharpnessScore: sharpness,
      leafLikelihood: likelihood,
    );
  }

  /// Fraction of pixels that match natural leaf colour using HSV hue ranges.
  ///
  /// Uses HSV instead of raw channel dominance so that UI/app teal/cyan
  /// colours (H ~160–200°) are NOT counted as leaf green (H 60–155°).
  ///
  ///  * Leaf green:        H 60–155°, S > 0.15, V > 0.12
  ///  * Diseased/brownish: H 20–80°,  S > 0.20, V > 0.15  (warm-leaf tones)
  static double _computeGreenRatio(img.Image image) {
    int greenPixels = 0;
    int naturalPixels = 0;
    final totalPixels = image.width * image.height;

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

        // Leaf-like green: hue 60–155°, not too desaturated, not too dark.
        // Excludes teal/cyan (H > 155°) and blue (H > 200°) used in UI.
        if (hue >= 60 && hue <= 155 && s > 0.10 && v > 0.05) {
          greenPixels++;
        }
        // Diseased / yellowish-green leaf tones.
        // Range deliberately starts at 45° (yellow-green) NOT 20°, so that
        // brown soil / powder / rust-coloured objects (H 15–40°) are NOT counted
        // as leaf tissue and fail the greenScore gate.
        if (hue >= 45 && hue <= 80 && s > 0.15 && v > 0.08 && g > 40) {
          naturalPixels++;
        }
        // Red-rust / heavily infected leaf tissue (H 5–45°, reddish-brown).
        // A tea leaf covered in red rust is still a leaf — it just has almost
        // no green left.  Count these pixels so badly infected leaves pass the
        // greenScore gate and reach the model for proper classification.
        // Guard: require moderate saturation AND red channel dominant so that
        // random brown backgrounds (low S) aren't counted.
        if (hue >= 5 && hue <= 45 && s > 0.25 && v > 0.10 &&
            r > g && r > b && (r - g) > 20) {
          naturalPixels++;
        }
      }
    }

    // Combined score: green dominance + natural leaf tones
    final greenRatio = greenPixels / totalPixels;
    final naturalRatio = naturalPixels / totalPixels;
    return (greenRatio * 0.6 + naturalRatio * 0.4);
  }

  /// Laplacian-variance sharpness metric.
  /// Higher = sharper image. Very low values indicate heavy blur.
  static double _computeSharpness(img.Image image) {
    // Convert to grayscale for Laplacian
    final gray = img.grayscale(img.copyResize(image, width: 256));
    double sum = 0;
    int count = 0;

    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        // 3x3 Laplacian kernel: center=4, neighbours=-1
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

  /// Colour variance across RGB channels.
  /// Very low variance means a solid colour (unlikely to be a leaf).
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
  ///  * Very dark  (V < 0.10)          — black cables, dark plastic
  ///  * Metallic grey (S < 0.16, V 0.12–0.72) — electronic devices, metal
  ///
  /// High values indicate electronic equipment, not a natural leaf.
  static double _computeInorganicRatio(img.Image image) {
    int inorganicPixels = 0;
    final totalPixels = image.width * image.height;

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

        // Very dark: cables, pitch-black plastic
        if (v < 0.10) {
          inorganicPixels++;
        }
        // Metallic / grey: circuit boards, metal casings, plastic housings.
        // Upper bound lowered 0.72 → 0.60 so near-white paper backgrounds
        // (V > 0.60, S ≈ 0) are not mis-counted as inorganic.
        else if (s < 0.16 && v >= 0.12 && v <= 0.60) {
          inorganicPixels++;
        }
      }
    }

    return inorganicPixels / totalPixels;
  }

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
}
