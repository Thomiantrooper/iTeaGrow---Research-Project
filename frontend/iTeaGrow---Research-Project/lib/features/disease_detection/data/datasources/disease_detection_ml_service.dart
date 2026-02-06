import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
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
    _isBackendAvailable = await checkBackendConnection();

    if (_isBackendAvailable) {
      print('Backend API connected at ${ApiConfig.effectiveBaseUrl}');
    } else {
      print('Backend not available at ${ApiConfig.effectiveBaseUrl} - using offline mode');
    }

    _isInitialized = true;
  }

  /// Check if the backend server is reachable
  Future<bool> checkBackendConnection() async {
    try {
      final healthUrl = ApiConfig.health;
      print('Checking backend at: $healthUrl');

      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 5));

      _isBackendAvailable = response.statusCode == 200;
      print('Backend health check: ${response.statusCode} - Available: $_isBackendAvailable');
      return _isBackendAvailable;
    } catch (e) {
      print('Backend connection check failed: $e');
      _isBackendAvailable = false;
      return false;
    }
  }

  /// Predict disease from image using backend API (Single Leaf)
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

    print('>>> PREDICT CALLED <<<');
    print('Backend available: $_isBackendAvailable');
    print('Image path: $imagePath');
    print('Is Web: $kIsWeb');

    // Try backend API first
    if (_isBackendAvailable) {
      try {
        print('>>> CALLING BACKEND API <<<');
        final result = await _predictWithBackend(
          imagePath,
          liveTemperature: liveTemperature,
          liveHumidity: liveHumidity,
          liveAirQuality: liveAirQuality,
          plantationId: plantationId,
          locationLat: locationLat,
          locationLng: locationLng,
          requestExplainability: requestExplainability,
        );
        print('>>> BACKEND SUCCESS: ${result.diseaseType} <<<');
        print('>>> Confidence: ${result.confidence} <<<');
        print('>>> Returning result from predict() <<<');
        print('');
        print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        print('!!! RESULT OBJECT CREATED SUCCESSFULLY !!!');
        print('!!! About to return to caller !!!');
        print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        print('');
        return result;
      } on ApiException catch (e) {
        print('!!! Backend API error: $e - falling back to offline mode');
      } catch (e, stackTrace) {
        print('!!! Unexpected error: $e - falling back to offline mode');
        print('!!! Stack trace: $stackTrace');
      }
    } else {
      print('!!! Backend NOT available - using offline mode');
    }

    // Offline fallback with dummy data
    print('>>> USING OFFLINE MODE ( DATA) <<<');
    return _predictOffline(
      imagePath,
      liveTemperature: liveTemperature,
      liveHumidity: liveHumidity,
      liveAirQuality: liveAirQuality,
    );
  }

  /// Batch detection for multiple leaves (Cumulative Score)
  Future<BatchDetectionResult> predictBatch(
    List<String> imagePaths, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
    String? blockId,
    String? fieldId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isBackendAvailable) {
      try {
        return await _predictBatchWithBackend(
          imagePaths,
          liveTemperature: liveTemperature,
          liveHumidity: liveHumidity,
          liveAirQuality: liveAirQuality,
          blockId: blockId,
          fieldId: fieldId,
        );
      } catch (e) {
        print('Batch backend error: $e - using offline mode');
      }
    }

    // Offline batch prediction
    return _predictBatchOffline(
      imagePaths,
      liveTemperature: liveTemperature,
      liveHumidity: liveHumidity,
      liveAirQuality: liveAirQuality,
    );
  }

  /// Field/Area analysis from a single image containing multiple leaves
  Future<FieldAnalysisResult> analyzeField(
    String imagePath, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
    String? blockId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isBackendAvailable) {
      try {
        return await _analyzeFieldWithBackend(
          imagePath,
          liveTemperature: liveTemperature,
          liveHumidity: liveHumidity,
          liveAirQuality: liveAirQuality,
          blockId: blockId,
        );
      } catch (e) {
        print('Field analysis backend error: $e - using offline mode');
      }
    }

    return _analyzeFieldOffline(
      imagePath,
      liveTemperature: liveTemperature,
      liveHumidity: liveHumidity,
      liveAirQuality: liveAirQuality,
    );
  }

  /// Call the backend API for disease detection (single image)
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
    // Prepare form fields
    final fields = <String, String>{};
    if (plantationId != null) fields['plantation_id'] = plantationId;
    if (locationLat != null) fields['location_lat'] = locationLat.toString();
    if (locationLng != null) fields['location_lng'] = locationLng.toString();
    if (liveTemperature != null) fields['temperature'] = liveTemperature.toString();
    if (liveHumidity != null) fields['humidity'] = liveHumidity.toString();
    if (liveAirQuality != null) fields['air_quality'] = liveAirQuality.toString();
    fields['request_explainability'] = requestExplainability.toString();
    fields['skip_quality_check'] = 'false';

    Map<String, dynamic> response;

    if (kIsWeb) {
      // For web, use multipart request with bytes
      response = await _postMultipartWeb(
        ApiConfig.inferenceDetect,
        imagePath: imagePath,
        fields: fields,
      );
    } else {
      // For mobile, use file path
      response = await _apiClient.postMultipartFromPath(
        ApiConfig.inferenceDetect,
        imagePath: imagePath,
        fields: fields,
      );
    }

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

  /// Batch prediction with backend
  Future<BatchDetectionResult> _predictBatchWithBackend(
    List<String> imagePaths, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
    String? blockId,
    String? fieldId,
  }) async {
    // Call batch endpoint
    final fields = <String, String>{};
    if (blockId != null) fields['block_id'] = blockId;
    if (fieldId != null) fields['field_id'] = fieldId;
    if (liveTemperature != null) fields['temperature'] = liveTemperature.toString();
    if (liveHumidity != null) fields['humidity'] = liveHumidity.toString();

    final response = await _apiClient.postMultipleFilesFromPaths(
      ApiConfig.batchDetect,
      imagePaths: imagePaths,
      fields: fields,
    );

    return BatchDetectionResult.fromApiResponse(response);
  }

  /// Field analysis with backend
  Future<FieldAnalysisResult> _analyzeFieldWithBackend(
    String imagePath, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
    String? blockId,
  }) async {
    final fields = <String, String>{};
    if (blockId != null) fields['block_id'] = blockId;
    if (liveTemperature != null) fields['temperature'] = liveTemperature.toString();
    if (liveHumidity != null) fields['humidity'] = liveHumidity.toString();
    fields['detect_multiple'] = 'true';

    Map<String, dynamic> response;

    if (kIsWeb) {
      // For web, use multipart request with bytes
      response = await _postMultipartWeb(
        ApiConfig.fieldAnalysis,
        imagePath: imagePath,
        fields: fields,
      );
    } else {
      // For mobile, use file path
      response = await _apiClient.postMultipartFromPath(
        ApiConfig.fieldAnalysis,
        imagePath: imagePath,
        fields: fields,
      );
    }

    return FieldAnalysisResult.fromApiResponse(response);
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
    final diseases = ['Healthy', 'Red Rust', 'Blister Blight', 'Gray Blight', 'Anthracnose'];
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

  /// Offline batch prediction (simulated)
  Future<BatchDetectionResult> _predictBatchOffline(
    List<String> imagePaths, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
  }) async {
    await Future.delayed(Duration(seconds: imagePaths.length));

    final random = Random();
    final diseases = ['Healthy', 'Red Rust', 'Blister Blight', 'Gray Blight'];
    final results = <SingleLeafResult>[];

    int healthyCount = 0;
    int infectedCount = 0;
    final diseaseCounts = <String, int>{};

    for (int i = 0; i < imagePaths.length; i++) {
      final disease = diseases[random.nextInt(diseases.length)];
      final confidence = 0.7 + random.nextDouble() * 0.25;

      if (disease == 'Healthy') {
        healthyCount++;
      } else {
        infectedCount++;
        diseaseCounts[disease] = (diseaseCounts[disease] ?? 0) + 1;
      }

      results.add(SingleLeafResult(
        imageIndex: i,
        diseaseType: disease,
        confidence: confidence,
        severity: confidence > 0.85 ? 'High' : (confidence > 0.7 ? 'Medium' : 'Low'),
      ));
    }

    final totalCount = imagePaths.length;
    final healthPercentage = (healthyCount / totalCount) * 100;
    final overallStatus = healthPercentage >= 70
        ? 'Healthy Block'
        : (healthPercentage >= 40 ? 'Moderate Risk' : 'High Risk Block');

    return BatchDetectionResult(
      totalImages: totalCount,
      healthyCount: healthyCount,
      infectedCount: infectedCount,
      healthPercentage: healthPercentage,
      overallStatus: overallStatus,
      diseaseCounts: diseaseCounts,
      individualResults: results,
      timestamp: DateTime.now(),
      temperature: liveTemperature,
      humidity: liveHumidity,
      recommendations: _generateBatchRecommendations(healthPercentage, diseaseCounts),
    );
  }

  /// Offline field analysis (simulated)
  Future<FieldAnalysisResult> _analyzeFieldOffline(
    String imagePath, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
  }) async {
    await Future.delayed(const Duration(seconds: 3));

    final random = Random();
    final detectedLeaves = 5 + random.nextInt(20); // 5-25 leaves detected
    final healthyCount = (detectedLeaves * (0.5 + random.nextDouble() * 0.4)).round();
    final infectedCount = detectedLeaves - healthyCount;
    final healthPercentage = (healthyCount / detectedLeaves) * 100;

    final diseases = ['Red Rust', 'Blister Blight', 'Gray Blight'];
    final diseaseCounts = <String, int>{};
    var remaining = infectedCount;
    for (final disease in diseases) {
      if (remaining <= 0) break;
      final count = random.nextInt(remaining + 1);
      if (count > 0) {
        diseaseCounts[disease] = count;
        remaining -= count;
      }
    }
    if (remaining > 0) {
      diseaseCounts[diseases[0]] = (diseaseCounts[diseases[0]] ?? 0) + remaining;
    }

    final overallStatus = healthPercentage >= 70
        ? 'Healthy Area'
        : (healthPercentage >= 40 ? 'Moderate Risk' : 'Critical Area');

    return FieldAnalysisResult(
      detectedLeafCount: detectedLeaves,
      healthyCount: healthyCount,
      infectedCount: infectedCount,
      healthPercentage: healthPercentage,
      overallStatus: overallStatus,
      diseaseCounts: diseaseCounts,
      timestamp: DateTime.now(),
      temperature: liveTemperature,
      humidity: liveHumidity,
      recommendations: _generateBatchRecommendations(healthPercentage, diseaseCounts),
      boundingBoxes: [], // Would contain detected leaf regions from backend
    );
  }

  List<String> _generateBatchRecommendations(
    double healthPercentage,
    Map<String, int> diseaseCounts,
  ) {
    final recommendations = <String>[];

    if (healthPercentage >= 80) {
      recommendations.add('Maintain current management practices');
      recommendations.add('Continue regular monitoring schedule');
    } else if (healthPercentage >= 50) {
      recommendations.add('Increase monitoring frequency');
      recommendations.add('Apply preventive fungicide treatment');
      if (diseaseCounts.isNotEmpty) {
        final mostCommon = diseaseCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
        recommendations.add('Focus treatment on ${mostCommon.key} (${mostCommon.value} cases)');
      }
    } else {
      recommendations.add('Immediate intervention required');
      recommendations.add('Apply targeted fungicide treatment');
      recommendations.add('Isolate severely affected areas');
      recommendations.add('Review environmental conditions');
    }

    return recommendations;
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

  /// Web-specific multipart upload using XFile bytes
  Future<Map<String, dynamic>> _postMultipartWeb(
    String url, {
    required String imagePath,
    Map<String, String>? fields,
  }) async {
    try {
      print('>>> _postMultipartWeb CALLED <<<');
      print('URL: $url');
      print('Image path: $imagePath');

      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers.addAll(ApiConfig.defaultHeaders);

      // For web, we need to fetch the blob and send as bytes
      // The imagePath on web is typically a blob URL from image_picker
      print('Fetching image from blob URL...');
      final imageResponse = await http.get(Uri.parse(imagePath));
      print('Image fetch status: ${imageResponse.statusCode}');

      if (imageResponse.statusCode == 200) {
        final bytes = imageResponse.bodyBytes;
        print('Image bytes loaded: ${bytes.length} bytes');
        final filename = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
        ));
      } else {
        throw ApiException('Failed to load image from path: ${imageResponse.statusCode}');
      }

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      print('Sending request to backend...');
      final streamedResponse = await request.send().timeout(
        Duration(seconds: ApiConfig.receiveTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException('HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('!!! _postMultipartWeb ERROR: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Web upload error: $e');
    }
  }
}

/// Result for batch detection (multiple images)
class BatchDetectionResult {
  final int totalImages;
  final int healthyCount;
  final int infectedCount;
  final double healthPercentage;
  final String overallStatus;
  final Map<String, int> diseaseCounts;
  final List<SingleLeafResult> individualResults;
  final DateTime timestamp;
  final double? temperature;
  final double? humidity;
  final List<String> recommendations;

  BatchDetectionResult({
    required this.totalImages,
    required this.healthyCount,
    required this.infectedCount,
    required this.healthPercentage,
    required this.overallStatus,
    required this.diseaseCounts,
    required this.individualResults,
    required this.timestamp,
    this.temperature,
    this.humidity,
    required this.recommendations,
  });

  factory BatchDetectionResult.fromApiResponse(Map<String, dynamic> json) {
    final results = (json['results'] as List?)
            ?.map((r) => SingleLeafResult.fromJson(r))
            .toList() ??
        [];

    return BatchDetectionResult(
      totalImages: json['total_images'] ?? 0,
      healthyCount: json['healthy_count'] ?? 0,
      infectedCount: json['infected_count'] ?? 0,
      healthPercentage: (json['health_percentage'] ?? 0).toDouble(),
      overallStatus: json['overall_status'] ?? 'Unknown',
      diseaseCounts: Map<String, int>.from(json['disease_counts'] ?? {}),
      individualResults: results,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

/// Single leaf result within a batch
class SingleLeafResult {
  final int imageIndex;
  final String diseaseType;
  final double confidence;
  final String severity;

  SingleLeafResult({
    required this.imageIndex,
    required this.diseaseType,
    required this.confidence,
    required this.severity,
  });

  factory SingleLeafResult.fromJson(Map<String, dynamic> json) {
    return SingleLeafResult(
      imageIndex: json['image_index'] ?? 0,
      diseaseType: json['disease_type'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      severity: json['severity'] ?? 'Unknown',
    );
  }
}

/// Result for field/area analysis (multiple leaves in one image)
class FieldAnalysisResult {
  final int detectedLeafCount;
  final int healthyCount;
  final int infectedCount;
  final double healthPercentage;
  final String overallStatus;
  final Map<String, int> diseaseCounts;
  final DateTime timestamp;
  final double? temperature;
  final double? humidity;
  final List<String> recommendations;
  final List<BoundingBox> boundingBoxes;

  FieldAnalysisResult({
    required this.detectedLeafCount,
    required this.healthyCount,
    required this.infectedCount,
    required this.healthPercentage,
    required this.overallStatus,
    required this.diseaseCounts,
    required this.timestamp,
    this.temperature,
    this.humidity,
    required this.recommendations,
    required this.boundingBoxes,
  });

  factory FieldAnalysisResult.fromApiResponse(Map<String, dynamic> json) {
    final boxes = (json['bounding_boxes'] as List?)
            ?.map((b) => BoundingBox.fromJson(b))
            .toList() ??
        [];

    return FieldAnalysisResult(
      detectedLeafCount: json['detected_leaf_count'] ?? 0,
      healthyCount: json['healthy_count'] ?? 0,
      infectedCount: json['infected_count'] ?? 0,
      healthPercentage: (json['health_percentage'] ?? 0).toDouble(),
      overallStatus: json['overall_status'] ?? 'Unknown',
      diseaseCounts: Map<String, int>.from(json['disease_counts'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      boundingBoxes: boxes,
    );
  }
}

/// Bounding box for detected leaf regions
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final String diseaseType;
  final double confidence;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.diseaseType,
    required this.confidence,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      diseaseType: json['disease_type'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}
