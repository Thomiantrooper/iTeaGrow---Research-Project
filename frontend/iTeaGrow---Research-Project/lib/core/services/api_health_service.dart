import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/api_config.dart';

/// API Health Check Service
/// Monitors backend health and provides auto-retry functionality
class ApiHealthService {
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 5);
  static const int _maxRetries = 3;

  Timer? _healthCheckTimer;
  bool _isHealthy = false;
  String _lastStatus = 'unknown';
  DateTime? _lastCheck;

  /// Singleton instance
  static final ApiHealthService instance = ApiHealthService._();
  ApiHealthService._();

  /// Check if API is healthy
  bool get isHealthy => _isHealthy;

  /// Get last known status
  String get lastStatus => _lastStatus;

  /// Get last check time
  DateTime? get lastCheck => _lastCheck;

  /// Start periodic health checks
  void startHealthChecks() {
    debugPrint('Starting API health checks...');
    _checkHealth(); // Initial check
    _healthCheckTimer?.cancel();
    _healthCheckTimer =
        Timer.periodic(_healthCheckInterval, (_) => _checkHealth());
  }

  /// Stop periodic health checks
  void stopHealthChecks() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Perform a single health check
  Future<bool> _checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.effectiveBaseUrl}/health'),
          )
          .timeout(const Duration(seconds: 10));

      _lastCheck = DateTime.now();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _lastStatus = data['status'] ?? 'unknown';
        _isHealthy = _lastStatus == 'operational' || _lastStatus == 'degraded';

        debugPrint('API Health: $_lastStatus (${_isHealthy ? "✓" : "✗"})');
        return _isHealthy;
      } else {
        _lastStatus = 'error';
        _isHealthy = false;
        debugPrint('API Health Check Failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _lastStatus = 'unavailable';
      _isHealthy = false;
      debugPrint('API Health Check Error: $e');
      return false;
    }
  }

  /// Wait for API to become healthy with auto-retry
  Future<bool> waitForHealthy({
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = _maxRetries,
  }) async {
    debugPrint('Waiting for API to become healthy...');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint('Health check attempt $attempt/$maxRetries');

      final isHealthy = await _checkHealth();
      if (isHealthy) {
        debugPrint('✓ API is healthy');
        return true;
      }

      if (attempt < maxRetries) {
        debugPrint('Retrying in ${_retryDelay.inSeconds}s...');
        await Future.delayed(_retryDelay);
      }
    }

    debugPrint('✗ API health check failed after $maxRetries attempts');
    return false;
  }

  /// Make a request with automatic health check and retry
  Future<http.Response?> makeRequestWithRetry(
    Future<http.Response> Function() request, {
    int maxRetries = _maxRetries,
  }) async {
    // First, check if API is healthy
    if (!_isHealthy) {
      debugPrint('API not healthy, checking before request...');
      final healthy = await waitForHealthy(maxRetries: 2);
      if (!healthy) {
        debugPrint('API unavailable, request aborted');
        return null;
      }
    }

    // Try the request with retries
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Request attempt $attempt/$maxRetries');
        final response = await request();

        if (response.statusCode >= 500) {
          // Server error, mark as unhealthy and retry
          _isHealthy = false;
          if (attempt < maxRetries) {
            debugPrint(
                'Server error, retrying in ${_retryDelay.inSeconds}s...');
            await Future.delayed(_retryDelay);
            continue;
          }
        }

        return response;
      } catch (e) {
        debugPrint('Request failed: $e');
        _isHealthy = false;

        if (attempt < maxRetries) {
          debugPrint('Retrying in ${_retryDelay.inSeconds}s...');
          await Future.delayed(_retryDelay);
        } else {
          rethrow;
        }
      }
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    stopHealthChecks();
  }
}
