class YieldPredictionResult {
  final double predictedYield; // kg per hectare
  final double confidence;
  final String qualityGrade;
  final DateTime timestamp;

  YieldPredictionResult({
    required this.predictedYield,
    required this.confidence,
    required this.qualityGrade,
    required this.timestamp,
  });
}
