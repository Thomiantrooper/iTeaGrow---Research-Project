import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
import '../../domain/entities/disease_detection_result.dart';
import '../datasources/disease_detection_ml_service.dart'
    show FieldAnalysisResult;

/// Service for storing and retrieving disease detection results.
/// All saves go to the DB Microservice (Railway) instead of localhost.
class DiseaseStorageService {
  static final DiseaseStorageService _instance =
      DiseaseStorageService._internal();
  factory DiseaseStorageService() => _instance;
  DiseaseStorageService._internal();

  final http.Client _client = http.Client();

  // ── Private helper ──────────────────────────────────────────────────────────
  Future<String?> _imageToBase64(String imagePath) async {
    if (kIsWeb) return null;
    final file = File(imagePath);
    if (await file.exists()) {
      return base64Encode(await file.readAsBytes());
    }
    return null;
  }

  Future<Map<String, dynamic>?> _postToDb(
      String url, Map<String, dynamic> body, {String? authToken}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Saved to DB microservice: $url');
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('⚠️ DB microservice ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('⚠️ Error posting to DB microservice: $e');
      return null;
    }
  }

  // ── Disease Detection ───────────────────────────────────────────────────────

  /// Save a single-leaf detection result to MongoDB via Railway DB microservice.
  Future<Map<String, dynamic>?> saveDetection({
    required DiseaseDetectionResult result,
    required String imagePath,
    String? authToken,
  }) async {
    final imageBase64 = await _imageToBase64(imagePath);
    final body = {
      'user_id': result.userId,
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
      'image_quality_score': result.imageQualityScore,
      'validation_message': result.validationMessage,
      'extra': null,
    };
    return _postToDb(ApiConfig.dbDisease, body, authToken: authToken);
  }

  /// Alias – previously used multipart, now delegates to saveDetection.
  Future<Map<String, dynamic>?> saveDetectionWithImage({
    required DiseaseDetectionResult result,
    required String imagePath,
    String? authToken,
  }) =>
      saveDetection(result: result, imagePath: imagePath, authToken: authToken);

  /// Save a field analysis (multi-leaf) result to MongoDB via Railway DB microservice.
  Future<Map<String, dynamic>?> saveFieldAnalysisWithImage({
    required FieldAnalysisResult result,
    required String imagePath,
    String? authToken,
  }) async {
    String primaryDisease = 'Field Analysis';
    double primaryConfidence = result.healthPercentage / 100;
    if (result.diseaseCounts.isNotEmpty) {
      final sorted = result.diseaseCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      primaryDisease = sorted.first.key;
      primaryConfidence = sorted.first.value / result.detectedLeafCount;
    }

    final imageBase64 = await _imageToBase64(imagePath);
    final body = {
      'user_id': result.userId,
      'image_path': imagePath,
      'image_data': imageBase64,
      'disease_name': primaryDisease,
      'confidence': primaryConfidence,
      'severity': result.overallStatus,
      'recommendations': result.recommendations,
      'is_field_analysis': true,
      'detected_leaf_count': result.detectedLeafCount,
      'healthy_count': result.healthyCount,
      'infected_count': result.infectedCount,
      'health_percentage': result.healthPercentage,
      'disease_counts': result.diseaseCounts,
      'temperature': result.temperature,
      'humidity': result.humidity,
      'air_quality': result.airQuality,
      'summary': result.summary?.toJson(),
      'extra': null,
    };
    return _postToDb(ApiConfig.dbDisease, body, authToken: authToken);
  }

  // ── Read / History ──────────────────────────────────────────────────────────

  /// Get disease detection history from DB microservice.
  Future<List<DiseaseDetectionResult>> getDetections({
    int skip = 0,
    int limit = 50,
    String? diseaseName,
    bool includeImage = false,
    String? authToken,
  }) async {
    try {
      String url = '${ApiConfig.dbDisease}?skip=$skip&limit=$limit';
      if (diseaseName != null) url += '&disease_name=$diseaseName';

      final headers = {
        'Accept': 'application/json'
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((json) => DiseaseDetectionResult.fromStoredJson(
                  json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting detections: $e');
      return [];
    }
  }

  /// Get disease detection statistics (proxies to DB microservice list).
  Future<Map<String, dynamic>?> getStatistics({String? authToken}) async {
    try {
      final headers = {
        'Accept': 'application/json'
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.get(Uri.parse(ApiConfig.dbDisease),
          headers: headers).timeout(const Duration(seconds: 30));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) return {'total': data.length, 'records': data};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return null;
    }
  }

  /// Get detailed statistics - computes analytics from the raw detections list.
  Future<Map<String, dynamic>?> getDetailedStatistics({
    int days = 30,
    String? authToken,
  }) async {
    try {
      final headers = {'Accept': 'application/json'};
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client
          .get(
            Uri.parse('${ApiConfig.dbDisease}?skip=0&limit=200'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final data = jsonDecode(response.body);
      final List<dynamic> list = data is List ? data : [];

      final cutoff = DateTime.now().subtract(Duration(days: days));
      final filtered = list.where((doc) {
        final createdAt = doc['created_at'];
        if (createdAt == null) return true;
        try {
          return DateTime.parse(createdAt.toString()).isAfter(cutoff);
        } catch (_) {
          return true;
        }
      }).toList();

      final totalScans = filtered.length;
      int healthyCount = 0;
      int infectedCount = 0;
      final Map<String, int> diseaseMap = {};
      final Map<String, int> severityMap = {};

      for (final doc in filtered) {
        final disease = (doc['disease_name'] ?? 'Unknown') as String;
        final isHealthy = disease.toLowerCase() == 'healthy';
        if (isHealthy) {
          healthyCount++;
        } else {
          infectedCount++;
        }
        diseaseMap[disease] = (diseaseMap[disease] ?? 0) + 1;

        final severity = (doc['severity'] ?? 'Unknown') as String;
        severityMap[severity] = (severityMap[severity] ?? 0) + 1;
      }

      final healthRate =
          totalScans > 0 ? (healthyCount / totalScans) * 100 : 0.0;

      final diseaseDistribution = diseaseMap.entries
          .map((e) => {'disease_name': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return {
        'total_scans': totalScans,
        'healthy_count': healthyCount,
        'infected_count': infectedCount,
        'health_rate': healthRate,
        'disease_distribution': diseaseDistribution,
        'severity_distribution': severityMap,
      };
    } catch (e) {
      debugPrint('Error getting detailed statistics: $e');
      return null;
    }
  }

  /// Get recent detections.
  Future<Map<String, dynamic>?> getRecentDetections({
    int limit = 10,
    String? authToken,
  }) async {
    try {
      final headers = {
        'Accept': 'application/json'
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.get(
        Uri.parse('${ApiConfig.dbDisease}?limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'records': jsonDecode(response.body)};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting recent detections: $e');
      return null;
    }
  }

  /// Delete a detection (not supported by DB microservice — no-op).
  Future<bool> deleteDetection(String detectionId, {String? authToken}) async {
    debugPrint('deleteDetection: not implemented in DB microservice');
    return false;
  }

  void dispose() {
    _client.close();
  }
}

/// Model for stored detection with additional fields.
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
