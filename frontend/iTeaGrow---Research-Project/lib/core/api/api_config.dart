import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'dart:io' show Platform;

/// API Configuration for Tea Leaf Disease Detection Backend
class ApiConfig {
  // =========================================================================
  // FUTURE PRODUCTION URL - Main Backend Railway (Not Yet Deployed)
  // This will be for auth, users, storage, IoT when deployed to production
  // =========================================================================
  static const String productionBaseUrl =
      'https://iteagrow-main-prod.up.railway.app'; // TODO: Update when deployed

  // =========================================================================
  // DISEASE ML INFERENCE - Railway Production (ACTIVE)
  // Only for disease detection inference endpoints
  // =========================================================================
  static const String diseaseInferenceBaseUrl =
      'https://tea-leaf-disease-api-prod.up.railway.app';

  // Set to true to always use production backend (recommended for mobile app)
  // NOTE: This only affects main backend (auth, storage, IoT)
  // Disease ML and Yield Prediction use their own separate URLs
  static const bool useProductionBackend = false;

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

  // Disease inference uses Railway (always has model loaded)
  static String get diseaseInferenceApiUrl =>
      '$diseaseInferenceBaseUrl/api/$apiVersion';

  // Inference Endpoints - Use Railway Disease API
  static String get inferenceDetect =>
      '$diseaseInferenceApiUrl/inference/detect';
  static String get inferenceExplain =>
      '$diseaseInferenceApiUrl/inference/explain';
  static String get modelInfo => '$diseaseInferenceApiUrl/inference/model-info';
  static String get health => '$effectiveBaseUrl/health';
  static String get diseaseInferenceHealth => '$diseaseInferenceBaseUrl/health';
  static String get recommendations =>
      '$diseaseInferenceApiUrl/recommendations/generate';
  static String get quickRecommendations =>
      '$diseaseInferenceApiUrl/recommendations/quick';

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

  // Environmental IoT Microservice (Standalone Railway Backend)
  static const String environmentalIotMicroserviceBaseUrl =
      'https://iteagrow-environment-monitoring-iot-api.up.railway.app';

  // Environmental MQTT Live Streaming Endpoints (data stored by mqtt_bridge.py)
  // Returns latest reading per device pushed by MQTT bridge
  static String get environmentalIotLiveLatest =>
      '$environmentalIotMicroserviceBaseUrl/api/iot/live/latest';
  static String environmentalIotLiveDevice(String deviceId) =>
      '$environmentalIotMicroserviceBaseUrl/api/iot/live/latest?device_id=$deviceId';

  // Soil Monitoring & Health API (Railway Standard)
  static const String soilMonitoringBaseUrl =
      'https://iteagrow-soil-monitoring-iot-api.up.railway.app';
  static String get soilLatestPredictions =>
      '$soilMonitoringBaseUrl/farm/by-hectare';
  static String soilHectareData(int id) => '$soilMonitoringBaseUrl/hectare/$id';
  static String get soilHealthCheck => '$soilMonitoringBaseUrl/health';

  // Bluetooth IoT Endpoints
  static String get bluetoothConfig => '$apiBaseUrl/bluetooth/config';
  static String get bluetoothRegister =>
      '$apiBaseUrl/bluetooth/devices/register';
  static String get bluetoothDevices => '$apiBaseUrl/bluetooth/devices';
  static String get bluetoothData => '$apiBaseUrl/bluetooth/data';
  static String get bluetoothSync => '$apiBaseUrl/bluetooth/sync';
  static String get bluetoothHealth => '$apiBaseUrl/bluetooth/health';

  // WiFi IoT Endpoints
  static String get wifiDiscover => '$apiBaseUrl/wifi/discover';
  static String get wifiRegister => '$apiBaseUrl/wifi/devices/register';
  static String get wifiDevices => '$apiBaseUrl/wifi/devices';
  static String get wifiData => '$apiBaseUrl/wifi/data';
  static String get wifiBatch => '$apiBaseUrl/wifi/batch';
  static String get wifiHealth => '$apiBaseUrl/wifi/health';

  // Analytics Endpoints
  static String get analyticsOverview =>
      '$effectiveBaseUrl/api/analytics/overview';
  static String get analyticsDiseaseTrends =>
      '$effectiveBaseUrl/api/analytics/disease-trends';
  static String get analyticsDiseaseDistribution =>
      '$effectiveBaseUrl/api/analytics/disease-distribution';
  static String get analyticsRecovery =>
      '$effectiveBaseUrl/api/analytics/recovery-tracking';
  static String get analyticsUserStats =>
      '$effectiveBaseUrl/api/analytics/user-stats';
  static String get analyticsYearlyAnalysis =>
      '$effectiveBaseUrl/api/analytics/yearly-analysis';

  // Report Endpoints
  static String reportData(String detectionId) =>
      '$effectiveBaseUrl/api/reports/$detectionId';
  static String get reportHistory =>
      '$effectiveBaseUrl/api/reports/user/history';
  static String get reportSummary =>
      '$effectiveBaseUrl/api/reports/summary/range';

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

  // Auth Endpoints (Using Standalone Authentication Microservice)
  static const String authMicroserviceBaseUrl =
      'https://authentication-iteagrow-api.up.railway.app';

  static String get authLogin => '$authMicroserviceBaseUrl/api/users/login';
  static String get authGoogleLogin =>
      '$authMicroserviceBaseUrl/api/users/google-login';
  static String get authRegister =>
      '$authMicroserviceBaseUrl/api/users/register';
  static String get authVerifyToken =>
      '$authMicroserviceBaseUrl/api/users/verify-token';
  static String get authProfile => '$authMicroserviceBaseUrl/api/users/me';
  static String get authChangePassword =>
      '$authMicroserviceBaseUrl/api/users/change-password';
  static String get authLogout =>
      '$authMicroserviceBaseUrl/api/users/logout'; // Not currently implemented in backend but keeping for future

  // Feedback & Retraining Endpoints
  static String get feedbackSubmit => '$apiBaseUrl/feedback/submit';
  static String get feedbackStatistics => '$apiBaseUrl/feedback/statistics';

  // Sync Endpoints
  static String get syncStatus => '$apiBaseUrl/sync/status';
  static String get syncTrigger => '$apiBaseUrl/sync/trigger';

  // Additional Recommendation Endpoints
  static String get treatmentProtocol =>
      '$apiBaseUrl/recommendations/treatment';
  static String get fungicideCatalog =>
      '$apiBaseUrl/recommendations/fungicides';
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
