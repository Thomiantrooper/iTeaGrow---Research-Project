import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, compute;
import 'package:image/image.dart' as img;

/// Result of HSV colour analysis for maturity cross-validation.
class MaturityColorResult {
  /// Fraction of leaf pixels that look like tender/young shoots (0–1).
  final double tenderScore;

  /// Fraction of leaf pixels that look like mature/dark leaves (0–1).
  final double matureScore;

  /// Fraction of leaf pixels that are brownish / over-mature / stressed (0–1).
  final double brownScore;

  /// Maturity suggested by colour alone: 'Tender', 'Mature', or 'Uncertain'.
  final String suggestedMaturity;

  /// Confidence of the colour-based suggestion (0–1).
  final double suggestedConfidence;

  const MaturityColorResult({
    required this.tenderScore,
    required this.matureScore,
    required this.brownScore,
    required this.suggestedMaturity,
    required this.suggestedConfidence,
  });
}

/// Result of combining the ML model output with colour analysis.
class CorrectedMaturityPrediction {
  final String maturity;
  final double confidence;

  /// Describes which signal won: 'model+color', 'color-override',
  /// 'model (color-conflict)', 'model-only'.
  final String source;

  const CorrectedMaturityPrediction({
    required this.maturity,
    required this.confidence,
    required this.source,
  });
}

/// Pixel-level HSV colour cross-validator for tea leaf maturity.
///
/// Runs **after** the ML model and either boosts or reduces the model's
/// confidence in its Tender/Mature prediction based on leaf colour.
///
/// Colour signatures used:
///  * **Tender shoots** — vivid yellow-green to bright green.
///    HSV: H 52–98°, S >70, V >120.
///  * **Mature leaves** — deep forest green to blue-green.
///    HSV: H 82–148°, S >35, V 20–145.
///  * **Brown/over-mature** — brownish, yellowish-brown, russet tones.
///    HSV: H 10–52°, S >30, V 40–200 with R > G > B.
class MaturityColorValidator {
  static final MaturityColorValidator _instance = MaturityColorValidator._();
  factory MaturityColorValidator() => _instance;
  MaturityColorValidator._();

  // ── Minimum signal thresholds ──────────────────────────────────────────
  static const double _tenderThreshold = 0.12;
  static const double _matureThreshold = 0.12;

  // ── Cross-validation parameters ───────────────────────────────────────
  /// Colour signal must exceed this to be eligible to override the model.
  static const double _overrideMinColorConf = 0.70;

  /// Model confidence must be below this for colour to override it.
  static const double _overrideMaxModelConf = 0.75;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Run colour analysis on raw image bytes.  Heavy work runs in an isolate.
  Future<MaturityColorResult> analyze(Uint8List imageBytes) async {
    try {
      return await compute(_analyzeColors, imageBytes);
    } catch (e) {
      debugPrint('MaturityColorValidator error: $e');
      return const MaturityColorResult(
        tenderScore: 0,
        matureScore: 0,
        brownScore: 0,
        suggestedMaturity: 'Uncertain',
        suggestedConfidence: 0,
      );
    }
  }

  /// Combine the ML model's maturity prediction with colour analysis.
  ///
  /// Rules:
  ///  1. Weak colour signal → trust model unchanged.
  ///  2. Model and colour **agree** → boost confidence.
  ///  3. Colour strongly disagrees and model is uncertain → colour wins.
  ///  4. Mild disagreement → reduce model confidence moderately.
  static CorrectedMaturityPrediction crossValidate({
    required String modelMaturity,
    required double modelConfidence,
    required MaturityColorResult colorResult,
  }) {
    final colorMaturity = colorResult.suggestedMaturity;
    final colorConf = colorResult.suggestedConfidence;

    // ── Case 1: Colour signal too weak ──────────────────────────────────
    if (colorMaturity == 'Uncertain' || colorConf < 0.30) {
      return CorrectedMaturityPrediction(
        maturity: modelMaturity,
        confidence: modelConfidence,
        source: 'model-only',
      );
    }

    // ── Case 2: Model and colour agree ──────────────────────────────────
    if (modelMaturity == colorMaturity) {
      final boosted =
          (modelConfidence * 0.60 + colorConf * 0.35 + 0.05).clamp(0.0, 0.97);
      // Ensure we don't accidentally lower confidence below original if they agreed
      final finalConf = max(boosted, modelConfidence);
      return CorrectedMaturityPrediction(
        maturity: modelMaturity,
        confidence: finalConf,
        source: 'model+color',
      );
    }

    // ── Case 3: Colour strongly disagrees, model is uncertain ───────────
    if (colorConf >= _overrideMinColorConf &&
        modelConfidence < _overrideMaxModelConf) {
      final overrideConf =
          (colorConf * 0.65 + modelConfidence * 0.10).clamp(0.45, 0.78);
      debugPrint(
          'MATURITY COLOR OVERRIDE: model=$modelMaturity($modelConfidence) '
          '→ $colorMaturity($overrideConf) [color=$colorConf]');
      return CorrectedMaturityPrediction(
        maturity: colorMaturity,
        confidence: overrideConf,
        source: 'color-override',
      );
    }

    // ── Case 4: Mild disagreement — reduce model confidence ─────────────
    final adjusted = (modelConfidence * 0.75).clamp(0.30, 0.85);
    return CorrectedMaturityPrediction(
      maturity: modelMaturity,
      confidence: adjusted,
      source: 'model (color-conflict)',
    );
  }

  // ── Isolate worker ─────────────────────────────────────────────────────

  static MaturityColorResult _analyzeColors(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return const MaturityColorResult(
        tenderScore: 0,
        matureScore: 0,
        brownScore: 0,
        suggestedMaturity: 'Uncertain',
        suggestedConfidence: 0,
      );
    }

    // Down-sample for speed
    final src = (image.width > 400 || image.height > 400)
        ? img.copyResize(image, width: 400)
        : image;

    int tenderPixels = 0;
    int maturePixels = 0;
    int brownPixels = 0;
    int leafPixels = 0;
    final total = src.width * src.height;

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final brightness = (r + g + b) / 3.0;

        // Skip near-white / near-black backgrounds
        if (brightness > 230 && _saturation(r, g, b) < 35) continue;
        if (brightness < 25 || brightness > 248) continue;
        if (_saturation(r, g, b) < 20 && brightness > 200) continue;

        final hsv = _rgbToHsv(r, g, b);
        final h = hsv[0]; // 0–360
        final s = hsv[1]; // 0–255
        final v = hsv[2]; // 0–255

        if (s < 20) continue; // achromatic — skip

        leafPixels++;

        // ── Tender: vivid yellow-green to bright green ──────────────
        // Young bud tissue is lighter and more yellowish than mature leaves.
        if (h >= 52 && h <= 98 && s > 70 && v > 120) {
          tenderPixels++;
          continue;
        }

        // ── Mature: deep forest green to blue-green ──────────────────
        // Mature leaves are darker and less saturated than tender ones.
        if (h >= 82 && h <= 148 && s > 35 && v >= 20 && v <= 145) {
          maturePixels++;
          continue;
        }

        // ── Brown / over-mature / stressed ───────────────────────────
        if (h >= 10 && h <= 52 && s > 30 && v > 40 && v < 200) {
          if (r > g && r > b) brownPixels++;
        }
      }
    }

    final effective =
        leafPixels > 100 ? leafPixels.toDouble() : total.toDouble();
    final tenderScore = tenderPixels / effective;
    final matureScore = maturePixels / effective;
    final brownScore = brownPixels / effective;

    // ── Determine colour suggestion ─────────────────────────────────────
    String suggestedMaturity = 'Uncertain';
    double suggestedConfidence = 0.0;

    if (tenderScore > matureScore && tenderScore >= _tenderThreshold) {
      final ratio = tenderScore / (tenderScore + matureScore + 0.01);
      suggestedMaturity = 'Tender';
      suggestedConfidence = ratio.clamp(0.30, 0.90);
    } else if (matureScore > tenderScore && matureScore >= _matureThreshold) {
      final ratio = matureScore / (matureScore + tenderScore + 0.01);
      suggestedMaturity = 'Mature';
      suggestedConfidence = ratio.clamp(0.30, 0.90);
    }

    // Heavy brown presence → reduce confidence (unreliable image quality)
    if (brownScore > 0.30) {
      suggestedMaturity = 'Uncertain';
      suggestedConfidence = suggestedConfidence * 0.4;
    }

    return MaturityColorResult(
      tenderScore: tenderScore,
      matureScore: matureScore,
      brownScore: brownScore,
      suggestedMaturity: suggestedMaturity,
      suggestedConfidence: suggestedConfidence,
    );
  }

  static double _saturation(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;
    final cmax = rf > gf ? (rf > bf ? rf : bf) : (gf > bf ? gf : bf);
    final cmin = rf < gf ? (rf < bf ? rf : bf) : (gf < bf ? gf : bf);
    return cmax == 0 ? 0 : ((cmax - cmin) / cmax) * 255;
  }

  static List<double> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;
    final cmax = rf > gf ? (rf > bf ? rf : bf) : (gf > bf ? gf : bf);
    final cmin = rf < gf ? (rf < bf ? rf : bf) : (gf < bf ? gf : bf);
    final delta = cmax - cmin;

    double h = 0;
    if (delta != 0) {
      if (cmax == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (cmax == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
    }
    if (h < 0) h += 360;

    final s = cmax == 0 ? 0.0 : (delta / cmax) * 255;
    final v = cmax * 255;

    return [h, s, v];
  }
}
