/// Response models for Tea Yield Prediction API

/// Main prediction response wrapper
class PredictionResponseModel {
  final bool success;
  final List<DailyPredictionModel> predictions;
  final PredictionSummaryModel summary;
  final String? error;

  PredictionResponseModel({
    required this.success,
    required this.predictions,
    required this.summary,
    this.error,
  });

  factory PredictionResponseModel.fromJson(Map<String, dynamic> json) {
    // Extract days from root if available
    final int days = json['prediction_days'] ?? 0;

    // Parse summary and inject days if needed
    final summaryJson = json['summary'] ?? {};
    if (days > 0) {
      // Create a mutable copy or just handle in PredictionSummaryModel
      // Simplest is to pass it via a modified fromJson or just rely on the map
      Map<String, dynamic> summaryMap = Map<String, dynamic>.from(summaryJson);
      summaryMap['days_predicted'] = days;
      // Note: We'll update PredictionSummaryModel to look for 'days_predicted' which we just added,
      // or we can just explicitly map it there if the keys match.
      // Actually, let's just make PredictionSummaryModel handle the API keys (total_yield_kg, etc)
      // and we can manually overwrite the days if we want, or just let it separate.
    }

    return PredictionResponseModel(
      success: json['success'] ?? false,
      predictions: (json['predictions'] as List?)
              ?.map((p) => DailyPredictionModel.fromJson(p))
              .toList() ??
          [],
      summary: PredictionSummaryModel.fromJson(summaryJson, rootDays: days),
      error: json['error'] as String?,
    );
  }

  factory PredictionResponseModel.error(String message) {
    return PredictionResponseModel(
      success: false,
      predictions: [],
      summary: PredictionSummaryModel.empty(),
      error: message,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'predictions': predictions.map((p) => p.toJson()).toList(),
      'summary': summary.toJson(),
      'error': error,
    };
  }
}

/// Individual daily prediction
class DailyPredictionModel {
  final String date;
  final double predictedYieldKg;
  final double logEfficiency;
  final WeatherDataModel weather;

  DailyPredictionModel({
    required this.date,
    required this.predictedYieldKg,
    required this.logEfficiency,
    required this.weather,
  });

  factory DailyPredictionModel.fromJson(Map<String, dynamic> json) {
    return DailyPredictionModel(
      date: json['date'] ?? '',
      predictedYieldKg: (json['predicted_yield_kg'] ?? 0).toDouble(),
      // Handle potential nulls or mismatches safely
      logEfficiency: (json['log_efficiency'] != null)
          ? (json['log_efficiency'] as num).toDouble()
          : 2.0,
      // API returns flat structure for weather, not nested
      weather: WeatherDataModel.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'predicted_yield_kg': predictedYieldKg,
      'log_efficiency': logEfficiency,
      ...weather.toJson(),
    };
  }

  DateTime get dateTime => DateTime.parse(date);
}

/// Weather forecast data
class WeatherDataModel {
  final double tempMax;
  final double tempMin;
  final double rainfall;
  final double humidity;

  WeatherDataModel({
    required this.tempMax,
    required this.tempMin,
    required this.rainfall,
    required this.humidity,
  });

  factory WeatherDataModel.fromJson(Map<String, dynamic> json) {
    // API returns 'temperature_c', mapping to both min/max for now as API provides single value
    final temp = (json['temperature_c'] ?? 0).toDouble();

    return WeatherDataModel(
      tempMax: (json['temp_max'] ?? temp).toDouble(),
      tempMin: (json['temp_min'] ?? temp).toDouble(),
      rainfall: (json['rainfall'] ?? json['rainfall_mm'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? json['humidity_pct'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temp_max': tempMax,
      'temp_min': tempMin,
      'rainfall': rainfall,
      'humidity': humidity,
      'temperature_c':
          (tempMax + tempMin) / 2, // approximation for reverse mapping
    };
  }

  double get avgTemp => (tempMax + tempMin) / 2;
}

/// Prediction summary statistics
class PredictionSummaryModel {
  final double totalPredictedYield;
  final double averageDailyYield;
  final int daysPredicted;
  final String? weatherSource;

  PredictionSummaryModel({
    required this.totalPredictedYield,
    required this.averageDailyYield,
    required this.daysPredicted,
    this.weatherSource,
  });

  factory PredictionSummaryModel.fromJson(Map<String, dynamic> json,
      {int rootDays = 0}) {
    return PredictionSummaryModel(
      totalPredictedYield:
          (json['total_predicted_yield'] ?? json['total_yield_kg'] ?? 0)
              .toDouble(),
      averageDailyYield:
          (json['average_daily_yield'] ?? json['average_yield_kg'] ?? 0)
              .toDouble(),
      daysPredicted: json['days_predicted'] ?? rootDays,
      weatherSource: json['weather_source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_predicted_yield': totalPredictedYield,
      'average_daily_yield': averageDailyYield,
      'days_predicted': daysPredicted,
      'weather_source': weatherSource,
    };
  }

  factory PredictionSummaryModel.empty() {
    return PredictionSummaryModel(
      totalPredictedYield: 0,
      averageDailyYield: 0,
      daysPredicted: 0,
    );
  }
}
