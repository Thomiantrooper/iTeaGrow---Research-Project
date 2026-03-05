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
  static const double _minGreenRatio = 0.06;
  static const double _minSharpness = 12.0;
  static const double _minColourVariance = 180.0;
  static const int _minDimension = 64;

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

    if (greenScore < _minGreenRatio) {
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

  /// Fraction of pixels where the green channel dominates (G > R and G > B)
  /// with a tolerance for brownish/yellowish diseased leaves.
  static double _computeGreenRatio(img.Image image) {
    int greenPixels = 0;
    int naturalPixels = 0; // includes brownish/reddish leaf tones
    final totalPixels = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Pure green dominance
        if (g > r && g > b && g > 40) {
          greenPixels++;
        }
        // Brownish / reddish-green tones typical of diseased leaves
        if (g > 30 && (g + r) > (b * 2 + 40) && r < 220 && b < 180) {
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

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
}
