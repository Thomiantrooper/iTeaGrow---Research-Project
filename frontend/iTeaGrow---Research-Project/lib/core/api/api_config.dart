import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'dart:io' show Platform;

/// API Configuration for Tea Leaf Disease Detection Backend
class ApiConfig {
  // =========================================================================
  // PRODUCTION URL - Railway Disease Detection API
  // Update after deploying railway-disease-api folder
  // =========================================================================
  static const String productionBaseUrl = 'https://tea-leaf-disease-api-prod.up.railway.app';

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
        // Use localhost for both emulator and physical device (bridged via ADB reverse)
        return 'http://localhost:8000';
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
  static String get batchDetect => '$apiBaseUrl/inference/batch';
  static String get fieldAnalysis => '$apiBaseUrl/inference/field-analysis';
  static String get cumulativeScore => '$apiBaseUrl/inference/cumulative-score';
  static String get inferenceExportOnnx => '$apiBaseUrl/inference/export-onnx';

  // IoT Endpoints
  static String get iotConditions => '$apiBaseUrl/iot/conditions';
  static String get iotIngest => '$apiBaseUrl/iot/ingest';
  static String get iotBatchIngest => '$apiBaseUrl/iot/batch-ingest';
  static String get iotData => '$apiBaseUrl/iot/ingest';
  static String get iotDataLatest => '$apiBaseUrl/iot/conditions';
  static String get iotDevices => '$apiBaseUrl/bluetooth/devices';
  static String get iotStatistics => '$apiBaseUrl/iot/statistics';
  static String get iotFleetHealth => '$apiBaseUrl/iot/fleet-health';
  static String get iotRiskFactors => '$apiBaseUrl/iot/risk-factors';
  static String get iotAnomalies => '$apiBaseUrl/iot/anomalies';

  // Bluetooth IoT Endpoints
  static String get bluetoothConfig => '$apiBaseUrl/bluetooth/config';
  static String get bluetoothRegister => '$apiBaseUrl/bluetooth/devices/register';
  static String get bluetoothDevices => '$apiBaseUrl/bluetooth/devices';
  static String get bluetoothData => '$apiBaseUrl/bluetooth/data';
  static String get bluetoothSync => '$apiBaseUrl/bluetooth/sync';
  static String get bluetoothHealth => '$apiBaseUrl/bluetooth/health';

  // Disease Detection Storage Endpoints
  static String get diseaseDetections =>
      '$effectiveBaseUrl/api/disease/detections';
  static String get diseaseDetectionsWithImage =>
      '$effectiveBaseUrl/api/disease/detections/with-image';
  static String get diseaseStatistics =>
      '$effectiveBaseUrl/api/disease/statistics';
  static String get diseaseStatisticsDetailed =>
      '$effectiveBaseUrl/api/disease/statistics/detailed';
  static String get diseaseRecent => '$effectiveBaseUrl/api/disease/recent';

  // Chatbot / AI Assistant Endpoints
  static String get chatbotChat => '$apiBaseUrl/chatbot/chat';
  static String get chatbotChatStream => '$apiBaseUrl/chatbot/chat/stream';
  static String get chatbotFact => '$apiBaseUrl/chatbot/fact';
  static String get chatbotHealth => '$apiBaseUrl/chatbot/health';
  static String get chatbotSuggestions => '$apiBaseUrl/chatbot/suggestions';

  // Auth Endpoints
  static String get authLogin => '$effectiveBaseUrl/api/users/login';
  static String get authRegister => '$effectiveBaseUrl/api/users/register';
  static String get authVerifyToken => '$effectiveBaseUrl/api/users/verify-token';
  static String get authProfile => '$effectiveBaseUrl/api/users/me';
  static String get authLogout => '$effectiveBaseUrl/api/users/logout';

  // Feedback & Retraining Endpoints
  static String get feedbackSubmit => '$apiBaseUrl/feedback/submit';
  static String get feedbackStatistics => '$apiBaseUrl/feedback/statistics';

  // Sync Endpoints
  static String get syncStatus => '$apiBaseUrl/sync/status';
  static String get syncTrigger => '$apiBaseUrl/sync/trigger';

  // Additional Recommendation Endpoints
  static String get treatmentProtocol => '$apiBaseUrl/recommendations/treatment';
  static String get fungicideCatalog => '$apiBaseUrl/recommendations/fungicides';
  static String get costEstimate => '$apiBaseUrl/recommendations/cost-estimate';

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
