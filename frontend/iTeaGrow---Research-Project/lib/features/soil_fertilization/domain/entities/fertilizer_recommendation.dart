class FertilizerRecommendation {
  final double nitrogenAmount; // kg/hectare
  final double phosphorusAmount;
  final double potassiumAmount;
  final String reasoning;
  final DateTime timestamp;

  FertilizerRecommendation({
    required this.nitrogenAmount,
    required this.phosphorusAmount,
    required this.potassiumAmount,
    required this.reasoning,
    required this.timestamp,
  });
}
