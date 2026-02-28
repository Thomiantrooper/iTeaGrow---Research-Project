import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class ActivityItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  IconType get iconType {
    switch (type) {
      case 'scan':
      case 'detection':
        return IconType.scan;
      case 'harvest':
        return IconType.harvest;
      case 'soil':
      case 'fertilizer':
        return IconType.soil;
      case 'alert':
        return IconType.alert;
      case 'report':
        return IconType.report;
      default:
        return IconType.scan;
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type']?.toString() ??
          json['activity_type']?.toString() ??
          'scan',
      title: json['title']?.toString() ??
          json['action']?.toString() ??
          json['disease_name']?.toString() ??
          'Activity',
      subtitle: json['subtitle']?.toString() ??
          json['description']?.toString() ??
          json['message']?.toString() ??
          '',
      timestamp: _parseTimestamp(json['timestamp'] ??
          json['created_at'] ??
          json['detected_at']),
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

enum IconType { scan, harvest, soil, alert, report }

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class ActivityFeedState {
  final bool isLoading;
  final String? error;
  final List<ActivityItem> activities;
  final DateTime? lastUpdated;

  const ActivityFeedState({
    this.isLoading = true,
    this.error,
    this.activities = const [],
    this.lastUpdated,
  });

  bool get hasData => lastUpdated != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ActivityFeedNotifier extends StateNotifier<ActivityFeedState> {
  ActivityFeedNotifier() : super(const ActivityFeedState()) {
    debugPrint('[ActivityFeed] Notifier created, starting polling...');
    _startPolling();
  }

  static const _pollInterval = Duration(seconds: 120);
  Timer? _timer;

  void _startPolling() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    state = ActivityFeedState(
      isLoading: !state.hasData,
      activities: state.activities,
      lastUpdated: state.lastUpdated,
    );

    try {
      final List<ActivityItem> allActivities = [];

      // Fetch recent disease detections
      try {
        final recentUrl =
            '${ApiConfig.diseaseRecent}?limit=10&_t=${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('[ActivityFeed] Fetching recent: $recentUrl');

        final recentResponse = await http.get(
          Uri.parse(recentUrl),
          headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
        ).timeout(const Duration(seconds: 10));

        if (recentResponse.statusCode == 200) {
          final body = jsonDecode(recentResponse.body);
          final List items =
              body is List ? body : (body['detections'] ?? body['data'] ?? []);
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              allActivities.add(ActivityItem.fromJson({
                ...item,
                'type': 'scan',
                'title': item['disease_name'] ?? 'Leaf scan completed',
                'subtitle': item['confidence'] != null
                    ? '${(double.tryParse(item['confidence'].toString()) ?? 0 * 100).toStringAsFixed(0)}% confidence'
                    : item['result'] ?? '',
              }));
            }
          }
        }
      } catch (e) {
        debugPrint('[ActivityFeed] Recent detections error: $e');
      }

      // Fetch report history
      try {
        final reportUrl =
            '${ApiConfig.reportHistory}?limit=5&_t=${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('[ActivityFeed] Fetching reports: $reportUrl');

        final reportResponse = await http.get(
          Uri.parse(reportUrl),
          headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
        ).timeout(const Duration(seconds: 10));

        if (reportResponse.statusCode == 200) {
          final body = jsonDecode(reportResponse.body);
          final List items =
              body is List ? body : (body['reports'] ?? body['data'] ?? []);
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              allActivities.add(ActivityItem.fromJson({
                ...item,
                'type': 'report',
                'title': 'Report generated',
                'subtitle': item['disease_name'] ?? 'Detection report',
              }));
            }
          }
        }
      } catch (e) {
        debugPrint('[ActivityFeed] Reports error: $e');
      }

      // Sort by timestamp descending, limit to 10
      allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final limited = allActivities.take(10).toList();

      state = ActivityFeedState(
        isLoading: false,
        activities: limited,
        lastUpdated: DateTime.now(),
      );

      debugPrint('[ActivityFeed] Loaded ${limited.length} activities');
    } catch (e) {
      debugPrint('[ActivityFeed] Error: $e');
      state = ActivityFeedState(
        isLoading: false,
        error: 'Connection failed',
        activities: state.activities,
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

final activityFeedProvider =
    StateNotifierProvider<ActivityFeedNotifier, ActivityFeedState>((ref) {
  ref.keepAlive();
  return ActivityFeedNotifier();
});
