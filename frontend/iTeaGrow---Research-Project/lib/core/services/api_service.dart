import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_config.dart';
import 'local_auth_service.dart' show sharedPreferencesProvider;

/// API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });
}

/// API Service for making HTTP requests to the backend
class ApiService {
  final SharedPreferences _prefs;
  static const String _tokenKey = 'api_access_token';

  /// Persistent HTTP client — reuses TCP connections & TLS sessions across
  /// all requests, eliminating per-call handshake overhead (~300-500 ms).
  static final http.Client _client = http.Client();

  ApiService(this._prefs);

  /// Fire-and-forget warm-up ping so Railway is awake before the user
  /// taps Login (called once on app start from AuthNotifier._initializeAuth).
  static void warmUp() {
    _client
        .get(
          Uri.parse('${ApiConfig.authMicroserviceBaseUrl}/health'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15))
        .then((_) => debugPrint('[ApiService] Railway warm-up done'))
        .catchError((e) => debugPrint('[ApiService] Railway warm-up: $e'));
  }

  /// Awaitable warm-up ping — use this when you need to ENSURE Railway is
  /// awake before making a critical request (e.g. Google login).
  static Future<void> warmUpAsync() async {
    try {
      await _client
          .get(
            Uri.parse('${ApiConfig.authMicroserviceBaseUrl}/health'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));
      debugPrint('[ApiService] Railway warm-up (async) done');
    } catch (e) {
      debugPrint('[ApiService] Railway warm-up (async): $e');
    }
  }

  /// Get stored access token
  String? get accessToken => _prefs.getString(_tokenKey);

  /// Save access token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  /// Clear access token
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  /// Check if user has valid token
  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  /// Get headers with authorization if token exists
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (hasToken) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  /// Make GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final String url = endpoint.startsWith('http')
          ? endpoint
          : '${ApiConfig.effectiveBaseUrl}$endpoint';

      final response = await _client.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Make POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final String url = endpoint.startsWith('http')
          ? endpoint
          : '${ApiConfig.effectiveBaseUrl}$endpoint';

      final response = await _client.post(
        Uri.parse(url),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Make PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final String url = endpoint.startsWith('http')
          ? endpoint
          : '${ApiConfig.effectiveBaseUrl}$endpoint';

      final response = await _client.put(
        Uri.parse(url),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Make DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final String url = endpoint.startsWith('http')
          ? endpoint
          : '${ApiConfig.effectiveBaseUrl}$endpoint';

      final response = await _client.delete(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    final statusCode = response.statusCode;
    final isSuccess = statusCode >= 200 && statusCode < 300;

    if (isSuccess) {
      try {
        final dynamic data =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;

        return ApiResponse(
          success: true,
          data: fromJson != null && data != null ? fromJson(data) : data as T?,
          statusCode: statusCode,
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Failed to parse response: ${e.toString()}',
          statusCode: statusCode,
        );
      }
    } else {
      String errorMessage = 'Request failed';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage =
            errorData['detail'] ?? errorData['message'] ?? errorMessage;
      } catch (_) {}

      return ApiResponse(
        success: false,
        error: errorMessage,
        statusCode: statusCode,
      );
    }
  }
}

/// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiService(prefs);
});
