import 'dart:io';
import 'dart:math';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../domain/entities/disease_detection_result.dart';

class DiseaseDetectionMLService {
  static final DiseaseDetectionMLService _instance =
      DiseaseDetectionMLService._internal();
  factory DiseaseDetectionMLService() => _instance;
  DiseaseDetectionMLService._internal();

  final ApiClient _apiClient = ApiClient();
  bool _isInitialized = false;
  bool _isBackendAvailable = false;

  /// Initialize the service and check backend connectivity
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if backend is available
    _isBackendAvailable = await _apiClient.isServerReachable();

    if (_isBackendAvailable) {
      print('Backend API connected at ${ApiConfig.baseUrl}');
    } else {
      print('Backend not available - using offline mode with dummy results');
    }

    _isInitialized = true;
  }

  /// Check if the backend server is reachable
  Future<bool> checkBackendConnection() async {
    _isBackendAvailable = await _apiClient.isServerReachable();
    return _isBackendAvailable;
  }

  /// Predict disease from image using backend API
  Future<DiseaseDetectionResult> predict(
    String imagePath, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
    String? plantationId,
    double? locationLat,
    double? locationLng,
    bool requestExplainability = false,
  }) async {
    // Ensure initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Try backend API first
    if (_isBackendAvailable) {
      try {
        return await _predictWithBackend(
          imagePath,
          liveTemperature: liveTemperature,
          liveHumidity: liveHumidity,
          liveAirQuality: liveAirQuality,
          plantationId: plantationId,
          locationLat: locationLat,
          locationLng: locationLng,
          requestExplainability: requestExplainability,
        );
      } on ApiException catch (e) {
        print('Backend API error: $e - falling back to offline mode');
        // Fall back to offline mode
      } catch (e) {
        print('Unexpected error: $e - falling back to offline mode');
      }
    }

    // Offline fallback with dummy data
    return _predictOffline(
      imagePath,
      liveTemperature: liveTemperature,
      liveHumidity: liveHumidity,
      liveAirQuality: liveAirQuality,
    );
  }

  /// Call the backend API for disease detection
  Future<DiseaseDetectionResult> _predictWithBackend(
    String imagePath, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
    String? plantationId,
    double? locationLat,
    double? locationLng,
    bool requestExplainability = false,
  }) async {
    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      throw ApiException('Image file not found: $imagePath');
    }

    // Prepare form fields
    final fields = <String, String>{};
    if (plantationId != null) fields['plantation_id'] = plantationId;
    if (locationLat != null) fields['location_lat'] = locationLat.toString();
    if (locationLng != null) fields['location_lng'] = locationLng.toString();
    fields['request_explainability'] = requestExplainability.toString();
    fields['skip_quality_check'] = 'false';

    // Make API call
    final response = await _apiClient.postMultipart(
      ApiConfig.inferenceDetect,
      imageFile: imageFile,
      fields: fields,
    );

    // Parse response and add IoT data
    final result = DiseaseDetectionResult.fromApiResponse(response);

    // Return result with IoT context
    return DiseaseDetectionResult(
      diseaseType: result.diseaseType,
      confidence: result.confidence,
      severity: result.severity,
      recommendations: result.recommendations,
      timestamp: result.timestamp,
      temperature: liveTemperature,
      humidity: liveHumidity,
      airQuality: liveAirQuality,
      requestId: result.requestId,
      imageId: result.imageId,
      processingTimeMs: result.processingTimeMs,
      detections: result.detections,
      summary: result.summary,
    );
  }

  /// Offline prediction with simulated results (fallback)
  Future<DiseaseDetectionResult> _predictOffline(
    String imagePath, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
  }) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate dummy results
    final diseases = ['Healthy', 'Red Rust', 'Blister Blight'];
    final random = Random();
    final diseaseType = diseases[random.nextInt(diseases.length)];
    final confidence = 0.7 + random.nextDouble() * 0.25;

    final recommendations = diseaseType == 'Healthy'
        ? ['Continue regular monitoring', 'Maintain current practices']
        : [
            'Apply recommended fungicide',
            'Improve drainage',
            'Monitor closely for 2 weeks',
            'Check environmental conditions',
          ];

    return DiseaseDetectionResult(
      diseaseType: diseaseType,
      confidence: confidence,
      severity:
          confidence > 0.85 ? 'High' : (confidence > 0.7 ? 'Medium' : 'Low'),
      recommendations: recommendations,
      timestamp: DateTime.now(),
      temperature: liveTemperature ?? (25.0 + random.nextDouble() * 5),
      humidity: liveHumidity ?? (60.0 + random.nextDouble() * 20),
      airQuality: liveAirQuality ?? (50.0 + random.nextDouble() * 100),
    );
  }

  /// Get model information from backend
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (!_isBackendAvailable) return null;

    try {
      return await _apiClient.get(ApiConfig.modelInfo);
    } catch (e) {
      print('Failed to get model info: $e');
      return null;
    }
  }

  /// Check backend health status
  Future<Map<String, dynamic>?> getHealthStatus() async {
    try {
      return await _apiClient.get(ApiConfig.health);
    } catch (e) {
      print('Failed to get health status: $e');
      return null;
    }
  }

  bool get isBackendAvailable => _isBackendAvailable;
}
