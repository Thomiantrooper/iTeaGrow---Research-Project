import 'dart:convert';
import 'package:http/http.dart' as http;
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
        headers: {'Content-Type': 'application/json', 'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => SoilData.fromJson(e as Map<String, dynamic>))
            .toList();
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
        return data
            .map((e) => SoilData.fromJson(e as Map<String, dynamic>))
            .toList();
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
        return data
            .map((e) => SoilData.fromJson(e as Map<String, dynamic>))
            .toList();
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
}
