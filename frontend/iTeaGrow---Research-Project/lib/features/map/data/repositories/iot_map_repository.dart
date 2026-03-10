import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
import '../../domain/models/iot_zone_models.dart';

/// Repository for fetching IoT map data from Railway API
class IoTMapRepository {
  static const String baseUrl =
      'https://iteagrow-soil-monitoring-iot-api.up.railway.app';

  /// Get latest soil data — one record per unique absolute hectare_id.
  /// Uses /farm/by-hectare (MongoDB aggregation) so we always get exactly one
  /// record per physical sector, regardless of how many scan rounds have run.
  Future<List<SoilData>> getLatestData({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/farm/by-hectare'),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data
            .map((e) => SoilData.fromJson(e as Map<String, dynamic>))
            .toList();

        // Mirror data to DB Microservice
        for (var record in results) {
          _mirrorToDb(record);
        }

        return results;
      } else {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load latest data: $e');
    }
  }

  /// Get historical data for specific hectare
  Future<List<SoilData>> getHectareHistory(int hectareId,
      {int limit = 100}) async {
    try {
      // API has max limit of 100, enforce it here too
      final actualLimit = limit > 100 ? 100 : limit;

      final response = await http.get(
        Uri.parse('$baseUrl/hectare/$hectareId?limit=$actualLimit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data
            .map((e) => SoilData.fromJson(e as Map<String, dynamic>))
            .toList();

        // Mirror data to DB Microservice
        for (var record in results) {
          _mirrorToDb(record);
        }

        return results;
      } else {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load hectare history: $e');
    }
  }

  /// Get all soil data for a range of hectare IDs (one block = 25 hectares)
  Future<List<SoilData>> getRangeData(int startHectare, int endHectare,
      {int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/farm/range?start_hectare=$startHectare&end_hectare=$endHectare&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data
            .map((e) => SoilData.fromJson(e as Map<String, dynamic>))
            .toList();

        // Mirror data to DB Microservice
        for (var record in results) {
          _mirrorToDb(record);
        }

        return results;
      } else {
        throw Exception(
            'Server returned \${response.statusCode}: \${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load range data: $e');
    }
  }

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Mirror IoT data to our persistent DB microservice
  Future<void> _mirrorToDb(SoilData data) async {
    try {
      final body = {
        'hectare_id': data.hectareId,
        'soil_health': data.soilHealth,
        'nitrogen_level': data.nitrogen,
        'phosphorus_level': data.phosphorus,
        'potassium_level': data.potassium,
        'soil_ph': data.pH,
        'temperature': data.temperature,
        'humidity': data.humidity,
        'ec': data.ec,
        'fertilizer': data.fertilizer,
        'device_id': data.deviceId,
        'block_id': data.blockId,
        'extra': {
          'source': 'IoT Map Sync',
          'original_timestamp': data.timestamp.toIso8601String(),
          'reading_count': data.readingCount,
        },
      };

      // Fire and forget to avoid slowing down the UI
      http
          .post(
            Uri.parse(ApiConfig.dbSoil),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5))
          .catchError((_) => http.Response('', 500));
    } catch (e) {
      // Silently fail mirroring to not break the UI
    }
  }
}
