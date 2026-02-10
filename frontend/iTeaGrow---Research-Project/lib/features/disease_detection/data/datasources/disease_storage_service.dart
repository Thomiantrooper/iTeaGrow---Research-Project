import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
import '../../domain/entities/disease_detection_result.dart';
import '../datasources/disease_detection_ml_service.dart' show FieldAnalysisResult;

/// Service for storing and retrieving disease detection results from MongoDB
class DiseaseStorageService {
  static final DiseaseStorageService _instance = DiseaseStorageService._internal();
  factory DiseaseStorageService() => _instance;
  DiseaseStorageService._internal();

  final http.Client _client = http.Client();

  /// Save detection result to MongoDB with image
  Future<Map<String, dynamic>?> saveDetection({
    required DiseaseDetectionResult result,
    required String imagePath,
    String? authToken,
  }) async {
    try {
      // Read image and convert to base64
      String? imageBase64;
      if (!kIsWeb) {
        final file = File(imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          imageBase64 = base64Encode(bytes);
        }
      }

      final body = {
        'image_path': imagePath,
        'image_data': imageBase64,
        'disease_name': result.diseaseType,
        'confidence': result.confidence,
        'severity': result.severity,
        'recommendations': result.recommendations,
        'detections': result.detections?.map((d) => d.toJson()).toList(),
        'summary': result.summary?.toJson(),
        'temperature': result.temperature,
        'humidity': result.humidity,
        'air_quality': result.airQuality,
        'processing_time_ms': result.processingTimeMs,
        'request_id': result.requestId,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.post(
        Uri.parse(ApiConfig.diseaseDetections),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('Error saving detection: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error saving detection: $e');
      return null;
    }
  }

  /// Save detection with image upload (multipart)
  Future<Map<String, dynamic>?> saveDetectionWithImage({
    required DiseaseDetectionResult result,
    required String imagePath,
    String? authToken,
  }) async {
    try {
      debugPrint('Saving detection to: ${ApiConfig.diseaseDetectionsWithImage}');
      debugPrint('Auth token present: ${authToken != null}');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.diseaseDetectionsWithImage),
      );

      // Add headers
      request.headers['Accept'] = 'application/json';
      if (authToken != null && authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
        debugPrint('Authorization header added');
      } else {
        debugPrint('WARNING: No auth token - request may fail with 401');
      }

      // Add image file - handle web vs mobile differently
      if (kIsWeb) {
        // On web, imagePath is a blob URL - fetch it and send as bytes
        debugPrint('Web platform detected - fetching blob URL');
        final imageResponse = await http.get(Uri.parse(imagePath));
        if (imageResponse.statusCode == 200) {
          final bytes = imageResponse.bodyBytes;
          final filename = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: filename,
          ),);
          debugPrint('Image bytes loaded: ${bytes.length} bytes');
        } else {
          debugPrint('Failed to load image from blob URL: ${imageResponse.statusCode}');
          return null;
        }
      } else {
        // On mobile, use file path directly
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      // Add form fields
      request.fields['disease_name'] = result.diseaseType;
      request.fields['confidence'] = result.confidence.toString();
      if (result.severity.isNotEmpty) {
        request.fields['severity'] = result.severity;
      }
      if (result.recommendations.isNotEmpty) {
        request.fields['recommendations'] = jsonEncode(result.recommendations);
      }
      if (result.detections != null) {
        request.fields['detections'] = jsonEncode(result.detections!.map((d) => d.toJson()).toList());
      }
      if (result.summary != null) {
        request.fields['summary'] = jsonEncode(result.summary!.toJson());
      }
      if (result.temperature != null) {
        request.fields['temperature'] = result.temperature.toString();
      }
      if (result.humidity != null) {
        request.fields['humidity'] = result.humidity.toString();
      }
      if (result.airQuality != null) {
        request.fields['air_quality'] = result.airQuality.toString();
      }
      if (result.processingTimeMs != null) {
        request.fields['processing_time_ms'] = result.processingTimeMs.toString();
      }
      if (result.requestId != null) {
        request.fields['request_id'] = result.requestId!;
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Storage response status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Detection saved successfully!');
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('Error saving detection with image: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 401) {
        debugPrint('Authentication failed - user may need to log in');
      }
      return null;
    } catch (e) {
      debugPrint('Error saving detection with image: $e');
      return null;
    }
  }

  /// Save field analysis result (multiple leaves) with image
  Future<Map<String, dynamic>?> saveFieldAnalysisWithImage({
    required FieldAnalysisResult result,
    required String imagePath,
    String? authToken,
  }) async {
    try {
      debugPrint('Saving field analysis to: ${ApiConfig.diseaseDetectionsWithImage}');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.diseaseDetectionsWithImage),
      );

      // Add headers
      request.headers['Accept'] = 'application/json';
      if (authToken != null && authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      // Add image file - handle web vs mobile
      if (kIsWeb) {
        final imageResponse = await http.get(Uri.parse(imagePath));
        if (imageResponse.statusCode == 200) {
          final bytes = imageResponse.bodyBytes;
          final filename = 'field_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: filename,
          ),);
        } else {
          debugPrint('Failed to load image from blob URL');
          return null;
        }
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      // Store as a summary detection with field analysis data
      // Use the most common disease as the primary disease type
      String primaryDisease = 'Field Analysis';
      double primaryConfidence = result.healthPercentage / 100;

      if (result.diseaseCounts.isNotEmpty) {
        final sortedDiseases = result.diseaseCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        primaryDisease = sortedDiseases.first.key;
        primaryConfidence = sortedDiseases.first.value / result.detectedLeafCount;
      }

      // Add form fields
      request.fields['disease_name'] = primaryDisease;
      request.fields['confidence'] = primaryConfidence.toString();
      request.fields['severity'] = result.overallStatus;
      request.fields['recommendations'] = jsonEncode(result.recommendations);
      request.fields['is_field_analysis'] = 'true';
      request.fields['detected_leaf_count'] = result.detectedLeafCount.toString();
      request.fields['healthy_count'] = result.healthyCount.toString();
      request.fields['infected_count'] = result.infectedCount.toString();
      request.fields['health_percentage'] = result.healthPercentage.toString();
      request.fields['disease_counts'] = jsonEncode(result.diseaseCounts);

      if (result.temperature != null) {
        request.fields['temperature'] = result.temperature.toString();
      }
      if (result.humidity != null) {
        request.fields['humidity'] = result.humidity.toString();
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Field analysis save response: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Field analysis saved successfully!');
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('Error saving field analysis: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error saving field analysis: $e');
      return null;
    }
  }

  /// Get detection history
  Future<List<DiseaseDetectionResult>> getDetections({
    int skip = 0,
    int limit = 50,
    String? diseaseName,
    bool includeImage = false,
    String? authToken,
  }) async {
    try {
      String url = '${ApiConfig.diseaseDetections}?skip=$skip&limit=$limit&include_image=$includeImage';
      if (diseaseName != null) {
        url += '&disease_name=$diseaseName';
      }

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => DiseaseDetectionResult.fromStoredJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting detections: $e');
      return [];
    }
  }

  /// Get detection statistics
  Future<Map<String, dynamic>?> getStatistics({String? authToken}) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.get(
        Uri.parse(ApiConfig.diseaseStatistics),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return null;
    }
  }

  /// Get detailed statistics for charts
  Future<Map<String, dynamic>?> getDetailedStatistics({
    int days = 30,
    String? authToken,
  }) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.get(
        Uri.parse('${ApiConfig.diseaseStatisticsDetailed}?days=$days'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting detailed statistics: $e');
      return null;
    }
  }

  /// Get recent detections
  Future<Map<String, dynamic>?> getRecentDetections({
    int limit = 10,
    String? authToken,
  }) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.get(
        Uri.parse('${ApiConfig.diseaseRecent}?limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting recent detections: $e');
      return null;
    }
  }

  /// Delete a detection
  Future<bool> deleteDetection(String detectionId, {String? authToken}) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.delete(
        Uri.parse('${ApiConfig.diseaseDetections}/$detectionId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error deleting detection: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Model for stored detection with additional fields
class StoredDetection {
  final String id;
  final String userId;
  final String? imagePath;
  final String? imageData;
  final DiseaseDetectionResult result;
  final DateTime createdAt;

  StoredDetection({
    required this.id,
    required this.userId,
    this.imagePath,
    this.imageData,
    required this.result,
    required this.createdAt,
  });

  factory StoredDetection.fromJson(Map<String, dynamic> json) {
    return StoredDetection(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user_id'] ?? '',
      imagePath: json['image_path'],
      imageData: json['image_data'],
      result: DiseaseDetectionResult.fromStoredJson(json),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
