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
  static const double _blisterThreshold = 0.10;  // 10 % (high — avoids false positives)
  static const double _rustThreshold = 0.05;     // 5 %

  /// If the disease pixel fraction is above this, treat the colour signal as
  /// very strong (high confidence override).
  static const double _strongBlisterThreshold = 0.20;  // 20 %
  static const double _strongRustThreshold = 0.12;     // 12 %

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

    // ── Case 2: Model says Healthy, but colour sees disease ─────────────
    // VERY conservative: only override with overwhelming colour evidence
    // AND only when the model's own confidence in "Healthy" is low.
    if (_isHealthy(modelDisease) && !_isHealthy(colorDisease)) {
      // Only override if colour confidence is very high AND model is uncertain
      if (colorConf >= 0.80 && modelConfidence < 0.70) {
        final overrideConf = (colorConf * 0.6 + modelConfidence * 0.1)
            .clamp(0.50, 0.80);
        debugPrint(
            'COLOR OVERRIDE: model=$modelDisease($modelConfidence) → '
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
      // If colour analysis shows strong green with high confidence,
      // the leaf is likely healthy and the model was fooled by background
      if (colorConf >= 0.55 && colorResult.greenScore >= 0.40) {
        debugPrint(
            'COLOR→HEALTHY OVERRIDE: model=$modelDisease($modelConfidence) '
            'but green=${colorResult.greenScore.toStringAsFixed(2)}, '
            'colorConf=$colorConf → Healthy');
        return CorrectedPrediction(
          diseaseType: 'Healthy',
          confidence: colorConf.clamp(0.60, 0.92),
          source: 'color-healthy-override',
        );
      }
      // Moderate green — reduce model confidence significantly
      if (colorResult.greenScore >= 0.30) {
        final adjusted = (modelConfidence * 0.60).clamp(0.30, 0.70);
        return CorrectedPrediction(
          diseaseType: modelDisease,
          confidence: adjusted,
          source: 'model (color-reduced)',
        );
      }
      // Low green — keep model output but slightly reduce confidence
      final adjusted = (modelConfidence * 0.85).clamp(0.30, 0.95);
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

    // Down-sample for speed
    final src = (image.width > 400 || image.height > 400)
        ? img.copyResize(image, width: 400)
        : image;

    int blisterPixels = 0;
    int rustPixels = 0;
    int greenPixels = 0;
    int leafPixels = 0; // non-background pixels
    final total = src.width * src.height;

    // ── First pass: identify leaf vs background pixels ──────────────────
    // Build a simple mask: true = likely leaf, false = likely background
    final isLeafPixel = List<bool>.filled(total, false);

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final brightness = (r + g + b) / 3.0;
        final hsv = _rgbToHsv(r, g, b);
        final s = hsv[1];
        final v = hsv[2];

        // Background: very bright + very low saturation (white/grey bg)
        // or very dark (black bg) or overexposed
        if (brightness > 230 && s < 35) {
          continue;
        }
        if (brightness < 25 || brightness > 248) {
          continue;
        }
        // Near-white / near-grey with no colour → background
        if (s < 20 && v > 200) {
          continue;
        }

        isLeafPixel[y * src.width + x] = true;
      }
    }

    // ── Second pass: classify leaf pixels ──────────────────────────────
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        if (!isLeafPixel[y * src.width + x]) continue;

        final pixel = src.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final hsv = _rgbToHsv(r, g, b);
        final h = hsv[0]; // 0-360
        final s = hsv[1]; // 0-255
        final v = hsv[2]; // 0-255

        leafPixels++;

        // ── Red Rust detection (checked FIRST — more distinctive) ────
        // Red, maroon, dark orange, brown rust patches:
        //   - Hue in red/orange range (0-35 or 340-360)
        //   - Moderate saturation (not grey, not neon)
        //   - Moderate value (not too dark, not too bright)
        if (((h >= 0 && h <= 35) || (h >= 340 && h <= 360)) &&
            s > 50 && s < 230 &&
            v > 40 && v < 210) {
          // R channel should dominate for true rust
          if (r > g && r > b && (r - g) > 15) {
            rustPixels++;
            continue; // don't double-count
          }
        }

        // ── Blister Blight detection ─────────────────────────────────
        // White / pale / cream blister spots ON a leaf surface:
        //   - Must have some saturation (not pure white background)
        //   - Or pale yellow-green typical of blister lesions
        //   - Require nearby green context (handled by leaf mask above)
        if ((s >= 15 && s < 55 && v > 170 && v < 240) ||  // pale spots (not pure white)
            (s >= 20 && s < 70 && v > 155 && h >= 25 && h <= 65)) { // pale yellowish lesion
          // Additional spatial check: at least some green neighbours nearby
          // means this pale spot is actually on a leaf, not floating in space
          if (_hasGreenNeighbour(src, x, y, isLeafPixel)) {
            blisterPixels++;
            continue;
          }
        }

        // ── Healthy green ────────────────────────────────────────────
        // Green leaf tissue: hue 60-170, decent saturation
        if (h >= 60 && h <= 170 && s > 40 && v > 40) {
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
      suggestedConfidence = (greenScore * 1.2).clamp(0.0, 0.90);
    }

    return ColorAnalysisResult(
      blisterScore: blisterScore,
      rustScore: rustScore,
      greenScore: greenScore,
      suggestedDisease: suggestedDisease,
      suggestedConfidence: suggestedConfidence,
    );
  }

  /// Check if a pixel has at least one green-ish leaf neighbour in a 5×5 area.
  /// This prevents isolated bright pixels (background, text) from being counted
  /// as blister spots.
  static bool _hasGreenNeighbour(img.Image image, int cx, int cy, List<bool> leafMask) {
    int greenCount = 0;
    const radius = 3;
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) continue;
        if (!leafMask[ny * image.width + nx]) continue;
        final p = image.getPixel(nx, ny);
        final pr = p.r.toInt();
        final pg = p.g.toInt();
        final pb = p.b.toInt();
        // Check if neighbour is greenish
        if (pg > pr && pg > pb && pg > 50) {
          greenCount++;
          if (greenCount >= 5) return true; // need at least 5 green neighbours
        }
      }
    }
    return false;
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
