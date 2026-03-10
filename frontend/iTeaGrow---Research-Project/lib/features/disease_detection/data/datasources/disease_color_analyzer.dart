import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, compute;
import 'package:image/image.dart' as img;

/// Result of colour-based disease analysis.
class ColorAnalysisResult {
  /// Fraction of pixels that look like blister-blight lesions (0–1).
  final double blisterScore;

  /// Fraction of pixels that look like red-rust patches (0–1).
  final double rustScore;

  /// Fraction of pixels that are natural healthy green (0–1).
  final double greenScore;

  /// The disease suggested purely by colour analysis, or 'Healthy'.
  final String suggestedDisease;

  /// Confidence of the colour-based suggestion (0–1).
  final double suggestedConfidence;

  const ColorAnalysisResult({
    required this.blisterScore,
    required this.rustScore,
    required this.greenScore,
    required this.suggestedDisease,
    required this.suggestedConfidence,
  });
}

/// Analyses leaf images at the pixel level to detect disease-specific colour
/// patterns.  This runs **after** the ML model and acts as a cross-validation
/// layer that can boost or override the model's prediction.
///
/// Patterns detected:
///  * **Blister Blight** — white / pale-yellow circular blister-like spots on
///    a green background.  HSV: high value (>170), low saturation (<80), or
///    yellowish (H 20-60) with high value.
///  * **Red Rust** — red, maroon, dark-orange, or brown rust-like patches.
///    HSV: hue 0-30 or 340-360, moderate-to-high saturation, value 40-200.
///  * **Healthy** — mostly uniform green with no abnormal pigments.
class DiseaseColorAnalyzer {
  static final DiseaseColorAnalyzer _instance = DiseaseColorAnalyzer._();
  factory DiseaseColorAnalyzer() => _instance;
  DiseaseColorAnalyzer._();

  // ── Thresholds ──────────────────────────────────────────────────────────

  /// Minimum fraction of disease-coloured pixels to consider a detection.
  static const double _blisterThreshold = 0.05; // 5 %
  static const double _rustThreshold = 0.02; // 2 %

  /// If the disease pixel fraction is above this, treat the colour signal as
  /// very strong (high confidence override).
  static const double _strongBlisterThreshold = 0.15; // 15 %
  static const double _strongRustThreshold = 0.08; // 8 %

  // ── Public API ──────────────────────────────────────────────────────────

  /// Run colour analysis on raw image bytes.  Heavy work is done in an
  /// isolate via [compute].
  Future<ColorAnalysisResult> analyze(Uint8List imageBytes) async {
    try {
      return await compute(_analyzeColors, imageBytes);
    } catch (e) {
      debugPrint('ColorAnalyzer error: $e');
      return const ColorAnalysisResult(
        blisterScore: 0,
        rustScore: 0,
        greenScore: 0,
        suggestedDisease: 'Healthy',
        suggestedConfidence: 0,
      );
    }
  }

  /// Combine the ML model's prediction with colour analysis to produce a
  /// corrected disease type and confidence.
  ///
  /// Rules:
  ///  1. If the model and colour analysis **agree**, boost confidence.
  ///  2. If the model says Healthy but colour analysis detects strong disease
  ///     signal → **override** to the colour-detected disease.
  ///  3. If the model says a disease but colour analysis shows mostly green
  ///     with no disease signal → lower confidence but keep model output
  ///     (the model may see patterns colour analysis misses).
  static CorrectedPrediction crossValidate({
    required String modelDisease,
    required double modelConfidence,
    required ColorAnalysisResult colorResult,
  }) {
    final colorDisease = colorResult.suggestedDisease;
    final colorConf = colorResult.suggestedConfidence;

    // ── Case 1: Model and colour agree ──────────────────────────────────
    if (_sameDisease(modelDisease, colorDisease)) {
      // Boost confidence significantly when both signals agree
      final boosted = (modelConfidence * 0.55 + colorConf * 0.35 + 0.10)
          .clamp(modelConfidence, 0.98);
      return CorrectedPrediction(
        diseaseType: modelDisease,
        confidence: boosted,
        source: 'model+color',
      );
    }

    // ── Case 1.5: Model says Not A Leaf, but colour sees strong disease ───
    // The backend sometimes falsely rejects heavily rusted leaves as "Not A Leaf"
    // ── Case 1.5: Model says Not A Leaf, but colour sees strong disease ───
    // The backend sometimes falsely rejects heavily rusted leaves as "Not A Leaf"
    // due to lack of green. We ONLY override this specifically for Red Rust,
    // because background tables/glare can falsely trigger Blister Blight on small leaves.
    if (modelDisease.toLowerCase() == 'not a leaf' ||
        modelDisease.toLowerCase() == 'not_a_leaf') {
      if (colorDisease == 'Red Rust' && colorConf >= 0.35) {
        debugPrint('COLOR OVERRIDE: Backend said Not A Leaf, but color found '
            '$colorDisease($colorConf)');
        return CorrectedPrediction(
          diseaseType: colorDisease,
          confidence: colorConf.clamp(0.45, 0.85),
          source: 'color-override-notaleaf',
        );
      }

      // Also allow overriding "Not A Leaf" to Healthy if the leaf is small but clearly green
      if (colorDisease == 'Healthy' && colorConf >= 0.40) {
        debugPrint(
            'COLOR OVERRIDE: Backend said Not A Leaf, but color found Healthy($colorConf)');
        return CorrectedPrediction(
          diseaseType: 'Healthy',
          // Boost confidence artificially so it doesn't look like a completely uncertain guess
          confidence: (colorConf + 0.20).clamp(0.60, 0.85),
          source: 'color-override-healthy',
        );
      }
      // Otherwise, trust the Not A Leaf prediction
      return CorrectedPrediction(
        diseaseType: modelDisease,
        confidence: modelConfidence,
        source: 'model-trusted',
      );
    }

    // ── Case 2: Model says Healthy, but colour sees disease ─────────────
    // VERY conservative: only override with overwhelming colour evidence
    // AND only when the model's own confidence in "Healthy" is low.
    if (_isHealthy(modelDisease) && !_isHealthy(colorDisease)) {
      // Only override if colour confidence is very high AND model is uncertain
      if (colorConf >= 0.80 && modelConfidence < 0.65) {
        final overrideConf =
            (colorConf * 0.7 + modelConfidence * 0.1).clamp(0.50, 0.75);
        debugPrint('COLOR OVERRIDE: model=$modelDisease($modelConfidence) → '
            '$colorDisease($overrideConf) [color=$colorConf]');
        return CorrectedPrediction(
          diseaseType: colorDisease,
          confidence: overrideConf,
          source: 'color-override',
        );
      }
      // Model says Healthy and color evidence isn't overwhelming → trust model
      return CorrectedPrediction(
        diseaseType: modelDisease,
        confidence: modelConfidence,
        source: 'model-trusted',
      );
    }

    // ── Case 3: Model says disease, colour says Healthy ─────────────────
    if (!_isHealthy(modelDisease) && _isHealthy(colorDisease)) {
      // Very strict override: ONLY override if scanner finds virtually zero disease pixels.
      final pureGreen =
          colorResult.rustScore < 0.005 && colorResult.blisterScore < 0.005;

      if (pureGreen &&
          colorResult.greenScore >= 0.28 &&
          modelConfidence < 0.97) {
        debugPrint(
            'COLOR→HEALTHY OVERRIDE: model=$modelDisease($modelConfidence), '
            'green=${colorResult.greenScore.toStringAsFixed(2)}');
        return CorrectedPrediction(
          diseaseType: 'Healthy',
          confidence: colorConf.clamp(0.60, 0.90),
          source: 'color-healthy-override',
        );
      }
      // Moderate green — reduce model confidence slightly
      if (colorResult.greenScore >= 0.30) {
        final adjusted = (modelConfidence * 0.80).clamp(0.30, 0.85);
        return CorrectedPrediction(
          diseaseType: modelDisease,
          confidence: adjusted,
          source: 'model (color-reduced)',
        );
      }
      // Low green — keep model output but barely reduce confidence
      final adjusted = (modelConfidence * 0.95).clamp(0.30, 0.95);
      return CorrectedPrediction(
        diseaseType: modelDisease,
        confidence: adjusted,
        source: 'model (color-reduced)',
      );
    }

    // ── Case 4: Both say disease but disagree on which one ──────────────
    // Trust whichever has higher confidence
    if (colorConf > modelConfidence && colorConf >= 0.50) {
      return CorrectedPrediction(
        diseaseType: colorDisease,
        confidence: colorConf,
        source: 'color-preferred',
      );
    }
    return CorrectedPrediction(
      diseaseType: modelDisease,
      confidence: modelConfidence,
      source: 'model-preferred',
    );
  }

  static bool _isHealthy(String d) =>
      d == 'Healthy' || d.toLowerCase() == 'healthy';
  static bool _sameDisease(String a, String b) =>
      a.toLowerCase().replaceAll(' ', '_') ==
      b.toLowerCase().replaceAll(' ', '_');

  // ── Isolate worker ────────────────────────────────────────────────────

  static ColorAnalysisResult _analyzeColors(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return const ColorAnalysisResult(
        blisterScore: 0,
        rustScore: 0,
        greenScore: 0,
        suggestedDisease: 'Healthy',
        suggestedConfidence: 0,
      );
    }

    // Down-sample for speed – 200 px wide is plenty for colour stats
    final src = (image.width > 200 || image.height > 200)
        ? img.copyResize(image, width: 200)
        : image;

    int blisterPixels = 0;
    int rustPixels = 0;
    int greenPixels = 0;
    int leafPixels = 0; // non-background pixels
    final total = src.width * src.height;

    // ── Single-pass: background filter + classify ──────────────────────

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final brightness = (r + g + b) / 3.0;
        final hsv = _rgbToHsv(r, g, b);
        final h = hsv[0];
        final s = hsv[1];
        final v = hsv[2];

        // Background filter
        if (brightness > 230 && s < 35) continue;
        if (brightness < 25 || brightness > 248) continue;
        if (s < 18) continue;

        leafPixels++;

        // ── Red Rust detection (checked FIRST — more distinctive) ────
        // Red, maroon, dark orange, brown rust patches:
        //   - Hue in red/orange range (0-35 or 340-360)
        //   - Moderate saturation (not grey, not neon)
        //   - Moderate value (not too dark, not too bright)
        if (((h >= 0 && h <= 35) || (h >= 340 && h <= 360)) &&
            s > 40 &&
            s < 230 &&
            v > 30 &&
            v < 210) {
          // R channel should dominate for true rust
          if (r > g && r > (b * 0.9) && (r - g) > 10) {
            rustPixels++;
            continue;
          }
        }

        // ── Generic brown/grey necrotic spot detection ─────────────────
        // Catch dead spots that aren't specific to Red Rust or Blister
        if (h >= 10 && h <= 50 && s > 15 && v > 20 && v < 180) {
          if (r >= g && (r - g) > 5) {
            rustPixels++; // count as rust for the purposes of avoiding healthy override
            continue;
          }
        }

        // ── Blister Blight detection ─────────────────────────────────
        // Blister blight spots are typically pale yellow or pale green ON the leaf surface.
        // We strictly require a Hue between 20 (yellow/orange) and 75 (yellow/green)
        // to completely ignore white light reflections (glare) and white table backgrounds.
        if (s >= 15 && s < 70 && v > 140 && h >= 20 && h <= 75) {
          // Quick inline green-neighbour check (no mask needed)
          bool hasGreenNear = false;
          for (int dy = -2; dy <= 2 && !hasGreenNear; dy++) {
            for (int dx = -2; dx <= 2 && !hasGreenNear; dx++) {
              if (dx == 0 && dy == 0) continue;
              final nx = x + dx;
              final ny = y + dy;
              if (nx < 0 || nx >= src.width || ny < 0 || ny >= src.height)
                continue;
              final np = src.getPixel(nx, ny);
              final nr = np.r.toInt();
              final ng = np.g.toInt();
              final nb = np.b.toInt();
              if (ng > nr && ng > nb && ng > 50) hasGreenNear = true;
            }
          }
          if (hasGreenNear) {
            blisterPixels++;
            continue;
          }
        }

        // ── Healthy green ────────────────────────────────────────────
        // Green leaf tissue: hue 40-180 (yellow-green to cyan-green), decent saturation
        // Allow darker values (v > 20) since tea leaves can be very dark green
        if (h >= 40 && h <= 180 && s > 25 && v > 20) {
          greenPixels++;
        }
      }
    }

    // ── Compute scores ──────────────────────────────────────────────────
    // Normalize against leaf pixels (not total, to ignore background)
    final effectiveTotal = leafPixels > 100 ? leafPixels : total;
    final blisterScore = blisterPixels / effectiveTotal;
    final rustScore = rustPixels / effectiveTotal;
    final greenScore = greenPixels / effectiveTotal;

    // ── Determine suggestion ────────────────────────────────────────────
    String suggestedDisease = 'Healthy';
    double suggestedConfidence = 0.0;

    // Blister Blight check
    if (blisterScore >= _blisterThreshold) {
      final strength = blisterScore >= _strongBlisterThreshold
          ? 0.85
          : 0.40 + (blisterScore / _strongBlisterThreshold) * 0.45;
      if (strength > suggestedConfidence) {
        suggestedDisease = 'Blister Blight';
        suggestedConfidence = strength.clamp(0.0, 0.95);
      }
    }

    // Red Rust check
    if (rustScore >= _rustThreshold) {
      final strength = rustScore >= _strongRustThreshold
          ? 0.85
          : 0.40 + (rustScore / _strongRustThreshold) * 0.45;
      if (strength > suggestedConfidence) {
        suggestedDisease = 'Red Rust';
        suggestedConfidence = strength.clamp(0.0, 0.95);
      }
    }

    // If neither disease detected, confidence in "Healthy" based on green ratio
    if (suggestedDisease == 'Healthy') {
      double baseConf = (greenScore * 1.1).clamp(0.0, 0.90);
      // If we saw ANY disease pixels (even below threshold), penalize Healthy score
      if (blisterScore > 0.01 || rustScore > 0.01) {
        baseConf *= 0.6; // 40% reduction
      }
      suggestedConfidence = baseConf;
    }

    return ColorAnalysisResult(
      blisterScore: blisterScore,
      rustScore: rustScore,
      greenScore: greenScore,
      suggestedDisease: suggestedDisease,
      suggestedConfidence: suggestedConfidence,
    );
  }

  /// Convert RGB (0–255) to HSV.  Returns [H (0–360), S (0–255), V (0–255)].
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

/// The corrected prediction after cross-validating model output with colour
/// analysis.
class CorrectedPrediction {
  final String diseaseType;
  final double confidence;
  final String source; // For debugging: which signal dominated

  const CorrectedPrediction({
    required this.diseaseType,
    required this.confidence,
    required this.source,
  });
}
