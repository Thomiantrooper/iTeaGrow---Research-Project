import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class DashboardKpiState {
  final bool isLoading;
  final String? error;
  final int activeBlocks;
  final double healthPercent;
  final int harvestReadyBlocks;
  final int alertCount;
  final String estateName;
  final DateTime? lastUpdated;

  const DashboardKpiState({
    this.isLoading = true,
    this.error,
    this.activeBlocks = 0,
    this.healthPercent = 0,
    this.harvestReadyBlocks = 0,
    this.alertCount = 0,
    this.estateName = '',
    this.lastUpdated,
  });

  bool get hasData => lastUpdated != null;

  String get healthStatusLabel {
    if (healthPercent >= 80) return 'Good Health';
    if (healthPercent >= 60) return 'Moderate';
    if (healthPercent >= 40) return 'At Risk';
    return 'Critical';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class DashboardKpiNotifier extends StateNotifier<DashboardKpiState> {
  DashboardKpiNotifier() : super(const DashboardKpiState()) {
    debugPrint('[DashboardKPI] Notifier created, starting polling...');
    _startPolling();
  }

  static const _pollInterval = Duration(seconds: 60);
  Timer? _timer;

  void _startPolling() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    state = DashboardKpiState(
      isLoading: !state.hasData,
      error: null,
      activeBlocks: state.activeBlocks,
      healthPercent: state.healthPercent,
      harvestReadyBlocks: state.harvestReadyBlocks,
      alertCount: state.alertCount,
      estateName: state.estateName,
      lastUpdated: state.lastUpdated,
    );

    try {
      final url =
          '${ApiConfig.analyticsOverview}?_t=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('[DashboardKPI] Fetching: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('[DashboardKPI] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        state = DashboardKpiState(
          isLoading: false,
          activeBlocks: _toInt(body['active_blocks'] ?? body['total_blocks']),
          healthPercent:
              _toDouble(body['health_percent'] ?? body['overall_health']),
          harvestReadyBlocks: _toInt(body['harvest_ready'] ??
              body['harvest_ready_blocks']),
          alertCount:
              _toInt(body['alert_count'] ?? body['active_alerts']),
          estateName: body['estate_name']?.toString() ??
              body['plantation_name']?.toString() ??
              'My Estate',
          lastUpdated: DateTime.now(),
        );
      } else {
        state = DashboardKpiState(
          isLoading: false,
          error: 'Server error (${response.statusCode})',
          activeBlocks: state.activeBlocks,
          healthPercent: state.healthPercent,
          harvestReadyBlocks: state.harvestReadyBlocks,
          alertCount: state.alertCount,
          estateName: state.estateName,
          lastUpdated: state.lastUpdated,
        );
      }
    } catch (e) {
      debugPrint('[DashboardKPI] Error: $e');
      state = DashboardKpiState(
        isLoading: false,
        error: 'Connection failed',
        activeBlocks: state.activeBlocks,
        healthPercent: state.healthPercent,
        harvestReadyBlocks: state.harvestReadyBlocks,
        alertCount: state.alertCount,
        estateName: state.estateName,
        lastUpdated: state.lastUpdated,
      );
    }
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
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

final dashboardKpiProvider =
    StateNotifierProvider<DashboardKpiNotifier, DashboardKpiState>((ref) {
  ref.keepAlive();
  return DashboardKpiNotifier();
});
