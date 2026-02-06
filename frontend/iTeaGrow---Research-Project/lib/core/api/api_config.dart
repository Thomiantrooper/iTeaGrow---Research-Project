import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'dart:io' show Platform;

/// API Configuration for Tea Leaf Disease Detection Backend
class ApiConfig {
  // =========================================================================
  // PRODUCTION URL - Your Railway deployed backend
  // Update this URL after deploying to Railway
  // =========================================================================
  static const String productionBaseUrl = 'https://iteagrow-disease-detection.up.railway.app';

  // Set to true to always use production backend (recommended for mobile app)
  static const bool useProductionBackend = true;

  // Base URL - Automatically detects platform and mode
  static String get baseUrl {
    // In release mode or if production backend is enabled, use production URL
    if (kReleaseMode || useProductionBackend) {
      return productionBaseUrl;
    }

    // Development mode - use local backend
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // For mobile platforms in debug mode
    try {
      if (Platform.isAndroid) {
        // Android emulator uses 10.0.2.2 to reach host machine
        return 'http://10.0.2.2:8000';
      } else if (Platform.isIOS) {
        // iOS simulator uses localhost
        return 'http://localhost:8000';
      }
    } catch (e) {
      // Platform not available (web)
    }
    return 'http://localhost:8000';
  }

  // Override URL for custom server (e.g., when using a real device)
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static String get effectiveBaseUrl => _customBaseUrl ?? baseUrl;

  // API Version
  static const String apiVersion = 'v1';

  // Full API base path
  static String get apiBaseUrl => '$effectiveBaseUrl/api/$apiVersion';

  // Endpoints
  static String get inferenceDetect => '$apiBaseUrl/inference/detect';
  static String get inferenceExplain => '$apiBaseUrl/inference/explain';
  static String get modelInfo => '$apiBaseUrl/inference/model-info';
  static String get health => '$effectiveBaseUrl/health';
  static String get recommendations => '$apiBaseUrl/recommendations/generate';
  static String get quickRecommendations => '$apiBaseUrl/recommendations/quick';

  // Batch/Cumulative Detection Endpoints
  static String get batchDetect => '$apiBaseUrl/inference/batch-detect';
  static String get fieldAnalysis => '$apiBaseUrl/inference/field-analysis';
  static String get cumulativeScore => '$apiBaseUrl/inference/cumulative-score';

  // IoT Endpoints
  static String get iotConditions => '$apiBaseUrl/iot/conditions';
  static String get iotIngest => '$apiBaseUrl/iot/ingest';
  static String get iotData => '$effectiveBaseUrl/api/iot/data';
  static String get iotDataLatest => '$effectiveBaseUrl/api/iot/data/latest';
  static String get iotDevices => '$effectiveBaseUrl/api/iot/devices';
  static String get iotStatistics => '$effectiveBaseUrl/api/iot/statistics';

  // Disease Detection Storage Endpoints
  static String get diseaseDetections => '$effectiveBaseUrl/api/disease/detections';
  static String get diseaseDetectionsWithImage => '$effectiveBaseUrl/api/disease/detections/with-image';
  static String get diseaseStatistics => '$effectiveBaseUrl/api/disease/statistics';
  static String get diseaseStatisticsDetailed => '$effectiveBaseUrl/api/disease/statistics/detailed';
  static String get diseaseRecent => '$effectiveBaseUrl/api/disease/recent';

  // Yield Prediction API (Railway Production)
  static const String yieldPredictionBaseUrl =
      'https://iteagrow-tea-yield-prod.up.railway.app';
  static String get yieldPredictionHealth => '$yieldPredictionBaseUrl/health';
  static String get yieldPredictionPredict =>
      '$yieldPredictionBaseUrl/api/v1/predict';
  static String get yieldPredictionWeather =>
      '$yieldPredictionBaseUrl/api/v1/weather';
  static String get yieldPredictionDatabaseStatus =>
      '$yieldPredictionBaseUrl/database/status';
  static String get yieldPredictionRecent =>
      '$yieldPredictionBaseUrl/database/predictions/recent';
  static String get yieldPredictionAnalytics =>
      '$yieldPredictionBaseUrl/database/analytics/summary';
  static String get yieldPredictionStore => '$apiBaseUrl/yield/records';

  // Timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 60;
  static const int batchTimeout = 120; // Longer timeout for batch processing

  // Headers
  static Map<String, String> get defaultHeaders => {
        'Accept': 'application/json',
      };
}
