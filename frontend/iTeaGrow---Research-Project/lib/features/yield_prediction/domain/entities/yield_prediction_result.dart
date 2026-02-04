import '../../data/models/prediction_response_model.dart';

/// Domain entity for yield prediction result
class YieldPredictionResult {
  final bool success;
  final List<DailyPrediction> dailyPredictions;
  final PredictionSummary summary;
  final String? error;
  final DateTime timestamp;

  YieldPredictionResult({
    required this.success,
    required this.dailyPredictions,
    required this.summary,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from API response model
  factory YieldPredictionResult.fromResponseModel(
    PredictionResponseModel model,
  ) {
    return YieldPredictionResult(
      success: model.success,
      dailyPredictions:
          model.predictions.map((p) => DailyPrediction.fromModel(p)).toList(),
      summary: PredictionSummary.fromModel(model.summary),
      error: model.error,
    );
  }

  factory YieldPredictionResult.error(String message) {
    return YieldPredictionResult(
      success: false,
      dailyPredictions: [],
      summary: PredictionSummary.empty(),
      error: message,
    );
  }
}

/// Daily prediction entity
class DailyPrediction {
  final DateTime date;
  final double predictedYieldKg;
  final double logEfficiency;
  final WeatherData weather;

  DailyPrediction({
    required this.date,
    required this.predictedYieldKg,
    required this.logEfficiency,
    required this.weather,
  });

  factory DailyPrediction.fromModel(DailyPredictionModel model) {
    return DailyPrediction(
      date: model.dateTime,
      predictedYieldKg: model.predictedYieldKg,
      logEfficiency: model.logEfficiency,
      weather: WeatherData.fromModel(model.weather),
    );
  }
}

/// Weather data entity
class WeatherData {
  final double tempMax;
  final double tempMin;
  final double rainfall;
  final double humidity;

  WeatherData({
    required this.tempMax,
    required this.tempMin,
    required this.rainfall,
    required this.humidity,
  });

  factory WeatherData.fromModel(WeatherDataModel model) {
    return WeatherData(
      tempMax: model.tempMax,
      tempMin: model.tempMin,
      rainfall: model.rainfall,
      humidity: model.humidity,
    );
  }

  double get avgTemp => (tempMax + tempMin) / 2;
}

/// Prediction summary entity
class PredictionSummary {
  final double totalPredictedYield;
  final double averageDailyYield;
  final int daysPredicted;
  final String? weatherSource;

  PredictionSummary({
    required this.totalPredictedYield,
    required this.averageDailyYield,
    required this.daysPredicted,
    this.weatherSource,
  });

  factory PredictionSummary.fromModel(PredictionSummaryModel model) {
    return PredictionSummary(
      totalPredictedYield: model.totalPredictedYield,
      averageDailyYield: model.averageDailyYield,
      daysPredicted: model.daysPredicted,
      weatherSource: model.weatherSource,
    );
  }

  factory PredictionSummary.empty() {
    return PredictionSummary(
      totalPredictedYield: 0,
      averageDailyYield: 0,
      daysPredicted: 0,
    );
  }
}
