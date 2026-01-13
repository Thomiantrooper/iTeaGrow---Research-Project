class PowderGradingResult {
  final String grade; // 'Premium', 'Grade A', 'Grade B', etc.
  final double qualityScore; // 0-100
  final double marketPrice; // Rs/kg
  final double priceChange; // % change from last week
  final String marketTrend; // 'Rising', 'Stable', 'Falling'
  final Map<String, double> regionalPrices; // Different market prices
  final DateTime timestamp;

  PowderGradingResult({
    required this.grade,
    required this.qualityScore,
    required this.marketPrice,
    required this.priceChange,
    required this.marketTrend,
    required this.regionalPrices,
    required this.timestamp,
  });
}
