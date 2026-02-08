class LeafMaturityResult {
  final String species; // 'Assamica' or 'DT1'
  final String maturity; // 'Tender' or 'Mature'
  final double speciesConfidence;
  final double maturityConfidence;
  final Map<String, double> speciesProbabilities;
  final Map<String, double> maturityProbabilities;
  final DateTime timestamp;

  LeafMaturityResult({
    required this.species,
    required this.maturity,
    required this.speciesConfidence,
    required this.maturityConfidence,
    required this.speciesProbabilities,
    required this.maturityProbabilities,
    required this.timestamp,
  });
}
