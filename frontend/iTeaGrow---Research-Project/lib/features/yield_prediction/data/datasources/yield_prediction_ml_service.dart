import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_config.dart';
import '../models/prediction_request_model.dart';
import '../models/prediction_response_model.dart';

/// Service for Tea Yield Prediction API communication
class YieldPredictionApiService {
  static final YieldPredictionApiService _instance =
      YieldPredictionApiService._internal();
  factory YieldPredictionApiService() => _instance;
  YieldPredictionApiService._internal();

  final http.Client _client = http.Client();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check API health
    try {
      final isHealthy = await checkHealth();
      if (isHealthy) {
        print('✅ Yield Prediction API connected successfully');
        _isInitialized = true;
      } else {
        print('⚠️ Yield Prediction API health check failed');
      }
    } catch (e) {
      print('⚠️ Yield Prediction API initialization error: $e');
    }
  }

  /// Check API health status
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.yieldPredictionHealth))
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Get yield prediction from API
  Future<PredictionResponseModel> getPrediction(
      PredictionRequestModel request,) async {
    try {
      // Validate request
      if (!request.isValid()) {
        return PredictionResponseModel.error(
          request.getValidationError() ?? 'Invalid request data',
        );
      }

      // Make API call
      final response = await _client
          .post(
            Uri.parse(ApiConfig.yieldPredictionPredict),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: ApiConfig.receiveTimeout));

      // Parse response
      if (response.statusCode == 200) {
        print('🔍 DEBUG - API Response: ${response.body}');
        final data = jsonDecode(response.body);
        return PredictionResponseModel.fromJson(data);
      } else {
        // Handle error response
        try {
          final errorData = jsonDecode(response.body);
          return PredictionResponseModel.error(
            errorData['detail'] ??
                'Request failed with status ${response.statusCode}',
          );
        } catch (e) {
          return PredictionResponseModel.error(
            'Request failed with status ${response.statusCode}',
          );
        }
      }
    } on SocketException {
      return PredictionResponseModel.error(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return PredictionResponseModel.error(
        'Request timeout. Please try again.',
      );
    } on FormatException {
      return PredictionResponseModel.error(
        'Invalid response format from server.',
      );
    } catch (e) {
      return PredictionResponseModel.error(
        'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Save prediction to local backend (MongoDB)
  Future<void> savePrediction(
      PredictionRequestModel request, PredictionResponseModel response,) async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_access_token');

      if (token == null) {
        print('⚠️ Cannot save prediction: No auth token found');
        return;
      }

      final payload = {
        'request': request.toJson(),
        'response': response.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final apiResponse = await _client.post(
        Uri.parse(ApiConfig.yieldPredictionStore),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (apiResponse.statusCode == 200) {
        print('✅ Prediction saved to MongoDB successfully');
      } else {
        print(
            '⚠️ Failed to save prediction: ${apiResponse.statusCode} - ${apiResponse.body}',);
      }
    } catch (e) {
      print('⚠️ Error saving prediction to DB: $e');
    }
  }

  /// Get weather forecast
  Future<Map<String, dynamic>?> getWeatherForecast({int days = 7}) async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.yieldPredictionWeather}?days=$days'))
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Weather fetch failed: $e');
      return null;
    }
  }

  /// Get recent predictions from database
  Future<List<Map<String, dynamic>>> getRecentPredictions({
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.yieldPredictionRecent}?limit=$limit'))
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['predictions'] ?? []);
      }
      return [];
    } catch (e) {
      print('Failed to get recent predictions: $e');
      return [];
    }
  }

  /// Get analytics summary
  Future<Map<String, dynamic>?> getAnalytics() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.yieldPredictionAnalytics))
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Failed to get analytics: $e');
      return null;
    }
  }

  /// Check database status
  Future<Map<String, dynamic>?> getDatabaseStatus() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.yieldPredictionDatabaseStatus))
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Failed to get database status: $e');
      return null;
    }
  }

  /// Cleanup
  void dispose() {
    _client.close();
  }
}
