import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class AlertData {
  final String id;
  final String severity;
  final String title;
  final String message;
  final String? routePath;
  final DateTime createdAt;

  const AlertData({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    this.routePath,
    required this.createdAt,
  });

  bool get isWarning => severity == 'warning' || severity == 'high';
  bool get isError => severity == 'error' || severity == 'critical';
  bool get isInfo => severity == 'info' || severity == 'low';

  factory AlertData.fromJson(Map<String, dynamic> json) {
    final severity = json['severity']?.toString().toLowerCase() ??
        json['level']?.toString().toLowerCase() ??
        'info';
    final type = json['type']?.toString() ?? '';

    String routePath = '/notifications';
    if (type.contains('disease') || type.contains('blight')) {
      routePath = '/disease-detection';
    } else if (type.contains('harvest') || type.contains('plant')) {
      routePath = '/plants';
    } else if (type.contains('iot') || type.contains('sensor')) {
      routePath = '/iot-devices';
    } else if (type.contains('soil')) {
      routePath = '/soil-fertilization';
    }

    return AlertData(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      severity: severity,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Alert',
      message: json['message']?.toString() ??
          json['description']?.toString() ??
          '',
      routePath: routePath,
      createdAt: _parseTimestamp(
          json['created_at'] ?? json['timestamp'] ?? json['date']),
    );
  }

  static DateTime _parseTimestamp(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    final s = v.toString();
    return DateTime.tryParse(s.endsWith('Z') ? s : '${s}Z')?.toLocal() ??
        DateTime.now();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class AlertsState {
  final bool isLoading;
  final String? error;
  final List<AlertData> alerts;
  final DateTime? lastUpdated;

  const AlertsState({
    this.isLoading = true,
    this.error,
    this.alerts = const [],
    this.lastUpdated,
  });

  bool get hasData => lastUpdated != null;
  int get alertCount => alerts.length;
  int get warningCount => alerts.where((a) => a.isWarning).length;
  int get errorCount => alerts.where((a) => a.isError).length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AlertsNotifier extends StateNotifier<AlertsState> {
  AlertsNotifier() : super(const AlertsState()) {
    debugPrint('[Alerts] Notifier created, starting polling...');
    _startPolling();
  }

  static const _pollInterval = Duration(seconds: 30);
  Timer? _timer;

  void _startPolling() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    state = AlertsState(
      isLoading: !state.hasData,
      alerts: state.alerts,
      lastUpdated: state.lastUpdated,
    );

    try {
      final List<AlertData> allAlerts = [];

      // Fetch from IoT anomalies (sensor-based alerts)
      try {
        final anomalyUrl =
            '${ApiConfig.iotAnomalies}?_t=${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('[Alerts] Fetching anomalies: $anomalyUrl');

        final response = await http.get(
          Uri.parse(anomalyUrl),
          headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List items =
              body is List ? body : (body['anomalies'] ?? body['data'] ?? []);
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              allAlerts.add(AlertData.fromJson({
                ...item,
                'type': 'sensor',
              }));
            }
          }
        }
      } catch (e) {
        debugPrint('[Alerts] Anomalies error: $e');
      }

      // Fetch from disease risk factors
      try {
        final riskUrl =
            '${ApiConfig.iotRiskFactors}?_t=${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('[Alerts] Fetching risk factors: $riskUrl');

        final response = await http.get(
          Uri.parse(riskUrl),
          headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List items =
              body is List ? body : (body['risks'] ?? body['data'] ?? []);
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              allAlerts.add(AlertData.fromJson({
                ...item,
                'type': 'disease',
                'severity': 'warning',
              }));
            }
          }
        }
      } catch (e) {
        debugPrint('[Alerts] Risk factors error: $e');
      }

      // Sort by createdAt descending, limit to 5
      allAlerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final limited = allAlerts.take(5).toList();

      state = AlertsState(
        isLoading: false,
        alerts: limited,
        lastUpdated: DateTime.now(),
      );

      debugPrint('[Alerts] Loaded ${limited.length} alerts');
    } catch (e) {
      debugPrint('[Alerts] Error: $e');
      state = AlertsState(
        isLoading: false,
        error: 'Connection failed',
        alerts: state.alerts,
        lastUpdated: state.lastUpdated,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  ref.keepAlive();
  return AlertsNotifier();
});
