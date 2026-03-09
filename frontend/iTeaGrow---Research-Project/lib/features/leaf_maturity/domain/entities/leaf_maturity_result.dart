class LeafMaturityResult {
  final String species; // 'Assamica' or 'DT1'
  final String maturity; // 'Tender' or 'Mature'
  final double speciesConfidence;
  final double maturityConfidence;
  final Map<String, double> speciesProbabilities;
  final Map<String, double> maturityProbabilities;
  final DateTime timestamp;
  final double rawConfidence;

  // ── Validation & quality fields ─────────────────────────────────────────
  /// True when pre-flight or pre-scan validation rejected this image.
  final bool isNotALeaf;

  /// Human-readable reason for validation failure (non-null when [isNotALeaf]).
  final String? validationMessage;

  /// Textual confidence band: 'High' ≥0.85, 'Moderate' ≥0.70,
  /// 'Low' ≥0.55, 'Uncertain' <0.55.
  final String confidenceLabel;

  /// True when the tender vs mature margin is too small to be reliable
  /// (|tender − mature| < 0.15).  Suggest re-scan.
  final bool isAmbiguous;

  /// True when the result was cross-validated against HSV colour analysis.
  final bool colorValidated;

  LeafMaturityResult({
    required this.species,
    required this.maturity,
    required this.speciesConfidence,
    required this.maturityConfidence,
    required this.speciesProbabilities,
    required this.maturityProbabilities,
    required this.timestamp,
    required this.rawConfidence,
    this.isNotALeaf = false,
    this.validationMessage,
    this.confidenceLabel = 'High',
    this.isAmbiguous = false,
    this.colorValidated = false,
  });
}
