/// API Configuration for Tea Leaf Disease Detection Backend
class ApiConfig {
  // Base URL - Change this to your backend server address
  // For local development: http://localhost:8000 or http://10.0.2.2:8000 (Android emulator)
  // For physical device: Use your computer's IP address (e.g., http://192.168.1.100:8000)
  static const String baseUrl = 'http://10.0.2.2:8000';

  // API Version
  static const String apiVersion = 'v1';

  // Full API base path
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';

  // Endpoints
  static String get inferenceDetect => '$apiBaseUrl/inference/detect';
  static String get inferenceExplain => '$apiBaseUrl/inference/explain';
  static String get modelInfo => '$apiBaseUrl/inference/model-info';
  static String get health => '$baseUrl/health';
  static String get recommendations => '$apiBaseUrl/recommendations/generate';
  static String get quickRecommendations => '$apiBaseUrl/recommendations/quick';

  // IoT Endpoints
  static String get iotConditions => '$apiBaseUrl/iot/conditions';
  static String get iotIngest => '$apiBaseUrl/iot/ingest';

  // Timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 60;

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Accept': 'application/json',
  };
}
