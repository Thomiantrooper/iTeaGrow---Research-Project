import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/iot_zone_models.dart';

/// Repository for fetching IoT map data from Railway API
class IoTMapRepository {
  static const String baseUrl =
      'https://iteagrow-soil-monitoring-iot-api.up.railway.app';

  /// Get latest soil data from all hectares (API max limit is 100)
  Future<List<SoilData>> getLatestData({int limit = 100}) async {
    try {
      final actualLimit = limit > 100 ? 100 : limit;
      final response = await http.get(
        Uri.parse('$baseUrl/farm/latest?limit=$actualLimit'),
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
