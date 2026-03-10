import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pytorch_lite/pytorch_lite.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../domain/entities/disease_detection_result.dart';
import 'disease_color_analyzer.dart';

/// Image validation constants
const int _maxImageSizeBytes = 20 * 1024 * 1024; // 20 MB
const int _minImageSizeBytes = 5 * 1024; // 5 KB
const Set<String> _allowedExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.bmp',
  '.tiff'
};

class DiseaseDetectionMLService {
  static final DiseaseDetectionMLService _instance =
      DiseaseDetectionMLService._internal();
  factory DiseaseDetectionMLService() => _instance;
  DiseaseDetectionMLService._internal();

  final ApiClient _apiClient = ApiClient();

  final DiseaseColorAnalyzer _colorAnalyzer = DiseaseColorAnalyzer();
  bool _isInitialized = false;
  bool _isBackendAvailable = false;

  // Offline Model properties
  ClassificationModel? _offlineModel;
  bool _isOfflineModelLoaded = false;
  static const String _modelPath = 'assets/models/disease_model.ptl';
  static const int _inputSize = 224;
  // Classes from the classification model
  final List<String> _classNames = ['blister_blight', 'healthy', 'red_rust'];

  /// Initialize the service and check backend connectivity
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if backend is available
    _isBackendAvailable = await checkBackendConnection();

    if (_isBackendAvailable) {
      debugPrint(
          'Disease inference API connected at ${ApiConfig.diseaseInferenceBaseUrl}');
    } else {
      debugPrint(
          'Disease inference API not available at ${ApiConfig.diseaseInferenceBaseUrl} - using offline mode');
    }

    // Always try to load offline model as fallback
    if (!kIsWeb) {
      await _loadOfflineModel();
    }

    _isInitialized = true;
  }

  Future<void> _loadOfflineModel() async {
    try {
      debugPrint(
          'Loading offline classification PTL model from $_modelPath...');
      _offlineModel = await PytorchLite.loadClassificationModel(
        _modelPath,
        _inputSize,
        _inputSize,
        _classNames.length,
      );
      _isOfflineModelLoaded = true;
      debugPrint('Offline classification model loaded successfully!');
    } catch (e) {
      debugPrint('Error loading offline model: $e');
      _isOfflineModelLoaded = false;
    }
  }

  /// Check if the backend server is reachable
  Future<bool> checkBackendConnection() async {
    try {
      final healthUrl = ApiConfig.diseaseInferenceHealth;
      debugPrint('Checking disease inference backend at: $healthUrl');

      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          // Check for root health or model-specific health
          final isHealthy =
              data['status'] == 'healthy' || data['message'] != null;
          final isInferenceHealthy =
              data['services']?['inference'] == 'healthy';

          _isBackendAvailable =
              isHealthy || isInferenceHealthy || data['status'] == 'degraded';
        } catch (e) {
          // Fallback to basic status code check if JSON parsing fails
          _isBackendAvailable = true;
        }
      } else {
        _isBackendAvailable = false;
      }

      debugPrint(
          'Disease inference health check: ${response.statusCode} - Available: $_isBackendAvailable');
      return _isBackendAvailable;
    } catch (e) {
      debugPrint('Backend connection check failed: $e');
      _isBackendAvailable = false;
      return false;
    }
  }

  /// Validate image file before sending to backend.
  /// Returns null if valid, or an error message if invalid.
  String? _validateImageFile(String imagePath) {
    if (kIsWeb) return null; // Skip file checks on web

    final file = File(imagePath);
    if (!file.existsSync()) {
      return 'Image file not found at: $imagePath';
    }

    final fileSize = file.lengthSync();
    if (fileSize < _minImageSizeBytes) {
      return 'Image file is too small (${(fileSize / 1024).toStringAsFixed(1)} KB). '
          'The file may be corrupt. Minimum size is ${_minImageSizeBytes ~/ 1024} KB.';
    }
    if (fileSize > _maxImageSizeBytes) {
      return 'Image file is too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB). '
          'Maximum size is ${_maxImageSizeBytes ~/ 1024 ~/ 1024} MB.';
    }

    final extension = imagePath.contains('.')
        ? '.${imagePath.split('.').last.toLowerCase()}'
        : '';
    if (extension.isNotEmpty && !_allowedExtensions.contains(extension)) {
      return 'Unsupported image format: $extension. '
          'Please use JPEG, PNG, or WebP.';
    }

    return null; // Valid
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

    // Pre-flight image validation
    final validationError = _validateImageFile(imagePath);
    if (validationError != null) {
      debugPrint('Image validation failed: $validationError');
      return DiseaseDetectionResult(
        diseaseType: 'Not A Leaf',
        confidence: 0.0,
        severity: 'None',
        recommendations: [
          validationError,
          'Please select a valid image file.',
        ],
        timestamp: DateTime.now(),
      );
    }

    // Re-check backend if previously unavailable — status may have changed
    if (!_isBackendAvailable) {
      _isBackendAvailable = await checkBackendConnection();
      debugPrint('Re-checked backend availability: $_isBackendAvailable');
    }

    debugPrint('>>> PREDICT CALLED <<<');
    debugPrint('Backend available: $_isBackendAvailable');
    debugPrint('Image path: $imagePath');
    debugPrint('Is Web: $kIsWeb');

    // Try backend API first, then offline fallback
    DiseaseDetectionResult? mlResult;

    if (_isBackendAvailable) {
      try {
        debugPrint('>>> CALLING BACKEND API <<<');
        mlResult = await _predictWithBackend(
          imagePath,
          liveTemperature: liveTemperature,
          liveHumidity: liveHumidity,
          liveAirQuality: liveAirQuality,
          plantationId: plantationId,
          locationLat: locationLat,
          locationLng: locationLng,
          requestExplainability: requestExplainability,
        );
        debugPrint(
            '>>> BACKEND SUCCESS: ${mlResult.diseaseType} (${mlResult.confidence}) <<<');
      } on ApiException catch (e) {
        debugPrint('!!! Backend API error: $e - falling back to offline mode');
      } catch (e, stackTrace) {
        debugPrint('!!! Unexpected error: $e - falling back to offline mode');
        debugPrint('!!! Stack trace: $stackTrace');
      }
    } else {
      debugPrint('!!! Backend NOT available - using offline mode');
    }

    // Offline fallback
    if (mlResult == null) {
      debugPrint('>>> USING OFFLINE MODE <<<');
      mlResult = await _predictOffline(
        imagePath,
        liveTemperature: liveTemperature,
        liveHumidity: liveHumidity,
        liveAirQuality: liveAirQuality,
      );
    }

    // ── Colour cross-validation layer ───────────────────────────────────
    // Run pixel-level colour analysis and cross-validate with model output
    // to catch misclassifications (e.g. model says "Healthy" on a clearly
    // diseased leaf).
    if (!mlResult.isNotALeaf && !kIsWeb) {
      try {
        final imageBytes = await File(imagePath).readAsBytes();
        final colorResult = await _colorAnalyzer.analyze(imageBytes);
        debugPrint(
            '>>> COLOR ANALYSIS: blister=${colorResult.blisterScore.toStringAsFixed(3)}, '
            'rust=${colorResult.rustScore.toStringAsFixed(3)}, '
            'green=${colorResult.greenScore.toStringAsFixed(3)}, '
            'suggested=${colorResult.suggestedDisease}(${colorResult.suggestedConfidence.toStringAsFixed(2)})');

        final corrected = DiseaseColorAnalyzer.crossValidate(
          modelDisease: mlResult.diseaseType,
          modelConfidence: mlResult.confidence,
          colorResult: colorResult,
        );

        debugPrint(
            '>>> CORRECTED: ${corrected.diseaseType} (${corrected.confidence.toStringAsFixed(2)}) [${corrected.source}]');

        // Apply correction if it changed something
        if (corrected.diseaseType != mlResult.diseaseType ||
            corrected.confidence != mlResult.confidence) {
          final newSeverity =
              _getSeverity(corrected.confidence, corrected.diseaseType);
          mlResult = DiseaseDetectionResult(
            diseaseType: corrected.diseaseType,
            confidence: corrected.confidence,
            severity: newSeverity,
            recommendations:
                _getRecommendations(corrected.diseaseType, newSeverity),
            timestamp: mlResult.timestamp,
            temperature: mlResult.temperature,
            humidity: mlResult.humidity,
            airQuality: mlResult.airQuality,
            requestId: mlResult.requestId,
            imageId: mlResult.imageId,
            processingTimeMs: mlResult.processingTimeMs,
            detections: mlResult.detections,
            summary: mlResult.summary,
            imageQualityScore: mlResult.imageQualityScore,
            validationMessage: mlResult.validationMessage,
            heatmapPath: mlResult.heatmapPath,
          );
        }
      } catch (e) {
        debugPrint('Color cross-validation failed (non-fatal): $e');
      }
    }

    return mlResult!;
  }

  /// Generate appropriate recommendations for a disease + severity.
  List<String> _getRecommendations(String diseaseType, String severity) {
    switch (diseaseType) {
      case 'Healthy':
        return [
          'No diseases detected. The leaf appears healthy.',
          'Continue regular monitoring and standard cultural practices.',
        ];
      case 'Blister Blight':
        return [
          'Blister Blight (Exobasidium vexans) detected.',
          'Apply systemic fungicide (e.g., triadimefon or copper oxychloride).',
          'Carry out skiffing to remove infected shoots promptly.',
          'Avoid overhead irrigation which promotes spore dispersal.',
          if (severity == 'High' || severity == 'Critical')
            'URGENT: Isolate affected plants and consult plantation agronomist.',
          'Increase monitoring frequency during cool, humid weather.',
        ];
      case 'Red Rust':
        return [
          'Red Rust (Cephaleuros parasiticus) detected.',
          'Apply copper-based fungicide as a preventive/curative measure.',
          'Improve canopy ventilation by selective pruning.',
          'Remove and destroy heavily infected leaves to reduce inoculum.',
          if (severity == 'High' || severity == 'Critical')
            'URGENT: Isolate affected plants and apply treatment immediately.',
          'Monitor neighboring plants for spread.',
        ];
      default:
        return [
          'Disease detected: $diseaseType.',
          'Consult your plantation agronomist for a detailed treatment plan.',
          'Isolate affected plants where possible.',
        ];
    }
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
        debugPrint('Batch backend error: $e - using offline mode');
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

    // Pre-flight image validation
    final validationError = _validateImageFile(imagePath);
    if (validationError != null) {
      debugPrint('Field analysis image validation failed: $validationError');
      return FieldAnalysisResult(
        detectedLeafCount: 0,
        healthyCount: 0,
        infectedCount: 0,
        healthPercentage: 0.0,
        overallStatus: 'Invalid Image',
        diseaseCounts: {},
        timestamp: DateTime.now(),
        recommendations: [
          validationError,
          'Please select a valid image file for field analysis.',
        ],
        boundingBoxes: [],
      );
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
        debugPrint('Field analysis backend error: $e - using offline mode');
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
    if (liveTemperature != null)
      fields['temperature'] = liveTemperature.toString();
    if (liveHumidity != null) fields['humidity'] = liveHumidity.toString();
    if (liveAirQuality != null)
      fields['air_quality'] = liveAirQuality.toString();
    fields['request_explainability'] = requestExplainability.toString();
    fields['skip_quality_check'] =
        'true'; // always attempt inference; quality gate is mobile-unfriendly

    Map<String, dynamic> response;

    if (kIsWeb) {
      // For web, use multipart request with bytes
      response = await _postMultipartWeb(
        ApiConfig.inferenceDetect,
        imagePath: imagePath,
        fields: fields,
      );
    } else {
      // For mobile, use file path - 30 second timeout for image upload
      response = await _apiClient
          .postMultipartFromPath(
        ApiConfig.inferenceDetect,
        imagePath: imagePath,
        fields: fields,
      )
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw ApiException('Request timed out. Please try again.');
      });
    }

    // Parse response and add IoT data
    final result = DiseaseDetectionResult.fromApiResponse(response);

    // Return result with IoT context + quality/validation data
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
      imageQualityScore: result.imageQualityScore,
      validationMessage: result.validationMessage,
      heatmapPath: null,
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
    if (liveTemperature != null)
      fields['temperature'] = liveTemperature.toString();
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
    if (liveTemperature != null)
      fields['temperature'] = liveTemperature.toString();
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

  /// Offline fallback — uses PyTorch Lite model running locally with Grad-CAM!
  Future<DiseaseDetectionResult> _predictOffline(
    String imagePath, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
  }) async {
    if (kIsWeb || !_isOfflineModelLoaded || _offlineModel == null) {
      return DiseaseDetectionResult(
        diseaseType: 'Unavailable',
        confidence: 0.0,
        severity: 'None',
        recommendations: [
          'The ML backend is currently offline and offline models could not be loaded.',
          'Please check your internet connection and try again.',
        ],
        timestamp: DateTime.now(),
      );
    }

    try {
      debugPrint('>>> RUNNING OFFLINE CLASSIFICATION INFERENCE <<<');
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();

      String displayType;
      double bestScore;
      String severity;

      // Classification model — getImagePredictionListProbabilities returns
      // softmax probabilities (0‑1) for each class
      final List<double> scores =
          await _offlineModel!.getImagePredictionListProbabilities(bytes);

      if (scores.isEmpty) {
        return DiseaseDetectionResult(
          diseaseType: 'Healthy',
          confidence: 0.5,
          severity: 'None',
          recommendations: [
            'No diseases detected. Continue regular monitoring.',
            '(Offline analysis mode)',
          ],
          timestamp: DateTime.now(),
        );
      }

      int bestIdx = 0;
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > scores[bestIdx]) bestIdx = i;
      }
      bestScore = scores[bestIdx].clamp(0.0, 1.0);
      final String className =
          bestIdx < _classNames.length ? _classNames[bestIdx] : 'healthy';
      displayType = className
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
      severity = _getSeverity(bestScore, displayType);

      return DiseaseDetectionResult(
        diseaseType: displayType,
        confidence: bestScore,
        severity: severity,
        recommendations: [
          'Detected $displayType via offline analysis.',
          if (severity == 'High' || severity == 'Critical')
            'URGENT: Isolate affected plants and apply appropriate treatment.',
          if (severity == 'Medium' || severity == 'Low')
            'Monitor the affected area closely.',
          '(Note: Offline prediction. Reconnect to server for detailed insights.)',
        ],
        timestamp: DateTime.now(),
        temperature: liveTemperature,
        humidity: liveHumidity,
        airQuality: liveAirQuality,
        heatmapPath: null,
      );
    } catch (e) {
      debugPrint('Offline inference error: $e');
      return DiseaseDetectionResult(
        diseaseType: 'Error',
        confidence: 0.0,
        severity: 'None',
        recommendations: ['Error during offline analysis: $e'],
        timestamp: DateTime.now(),
      );
    }
  }

  String _getSeverity(double confidence, String diseaseName) {
    if (diseaseName.toLowerCase() == "healthy") return "None";
    if (confidence >= 0.80) return confidence >= 0.90 ? "Critical" : "High";
    if (confidence >= 0.65) return "Medium";
    if (confidence >= 0.45) return "Low";
    return "Uncertain";
  }

  /// Offline batch fallback — returns unavailable result
  Future<BatchDetectionResult> _predictBatchOffline(
    List<String> imagePaths, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return BatchDetectionResult(
      totalImages: imagePaths.length,
      healthyCount: 0,
      infectedCount: 0,
      healthPercentage: 0.0,
      overallStatus: 'Unavailable — Backend Offline',
      diseaseCounts: {},
      individualResults: [],
      timestamp: DateTime.now(),
      temperature: liveTemperature,
      humidity: liveHumidity,
      recommendations: [
        'The ML backend is currently offline.',
        'Batch detection requires an active server connection.',
        'Please check your internet connection and try again.',
      ],
    );
  }

  /// Offline field analysis fallback — returns unavailable result
  Future<FieldAnalysisResult> _analyzeFieldOffline(
    String imagePath, {
    double? liveTemperature,
    double? liveHumidity,
    double? liveAirQuality,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return FieldAnalysisResult(
      detectedLeafCount: 0,
      healthyCount: 0,
      infectedCount: 0,
      healthPercentage: 0.0,
      overallStatus: 'Unavailable — Backend Offline',
      diseaseCounts: {},
      timestamp: DateTime.now(),
      temperature: liveTemperature,
      humidity: liveHumidity,
      recommendations: [
        'The ML backend is currently offline.',
        'Field analysis requires an active server connection.',
        'Please check your internet connection and try again.',
      ],
      boundingBoxes: [],
    );
  }

  /// Get model information from backend
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (!_isBackendAvailable) return null;

    try {
      return await _apiClient.get(ApiConfig.modelInfo);
    } catch (e) {
      debugPrint('Failed to get model info: $e');
      return null;
    }
  }

  /// Check backend health status
  Future<Map<String, dynamic>?> getHealthStatus() async {
    try {
      return await _apiClient.get(ApiConfig.diseaseInferenceHealth);
    } catch (e) {
      debugPrint('Failed to get health status: $e');
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
      debugPrint('>>> _postMultipartWeb CALLED <<<');
      debugPrint('URL: $url');
      debugPrint('Image path: $imagePath');

      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers.addAll(ApiConfig.defaultHeaders);

      // For web, we need to fetch the blob and send as bytes
      // The imagePath on web is typically a blob URL from image_picker
      debugPrint('Fetching image from blob URL...');
      final imageResponse = await http.get(Uri.parse(imagePath));
      debugPrint('Image fetch status: ${imageResponse.statusCode}');

      if (imageResponse.statusCode == 200) {
        final bytes = imageResponse.bodyBytes;
        debugPrint('Image bytes loaded: ${bytes.length} bytes');
        final filename = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: filename,
          ),
        );
      } else {
        throw ApiException(
            'Failed to load image from path: ${imageResponse.statusCode}');
      }

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      debugPrint('Sending request to backend...');
      final streamedResponse = await request.send().timeout(
            const Duration(seconds: ApiConfig.receiveTimeout),
          );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Backend response status: ${response.statusCode}');
      debugPrint(
          'Backend response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
            'HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('!!! _postMultipartWeb ERROR: $e');
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
  final double? airQuality;
  final List<String> recommendations;
  final List<BoundingBox> boundingBoxes;
  final DetectionSummary? summary;

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
    this.airQuality,
    required this.recommendations,
    required this.boundingBoxes,
    this.summary,
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
      airQuality: json['air_quality']?.toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      boundingBoxes: boxes,
      summary: json['summary'] != null
          ? DetectionSummary.fromJson(json['summary'])
          : null,
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
