import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/presentation/providers/dashboard_kpi_provider.dart';
import '../../features/dashboard/presentation/providers/activity_feed_provider.dart';
import '../../features/dashboard/presentation/providers/alerts_provider.dart';
import 'iot_live_provider.dart';

/// Coordinates refresh of all dashboard data providers.
/// Call `refreshAll()` for a manual full refresh (e.g., pull-to-refresh).
///
/// Polling intervals are managed individually by each provider:
///   - IoT sensors: 5 seconds (iot_live_provider.dart)
///   - Dashboard KPIs: 60 seconds (dashboard_kpi_provider.dart)
///   - Activity feed: 120 seconds (activity_feed_provider.dart)
///   - Alerts: 30 seconds (alerts_provider.dart)
class RefreshCoordinator {
  final Ref _ref;

  RefreshCoordinator(this._ref);

  /// Manually refresh all dashboard data at once
  Future<void> refreshAll() async {
    debugPrint('[RefreshCoordinator] Triggering full refresh...');
    await Future.wait([
      _ref.read(dashboardKpiProvider.notifier).refresh(),
      _ref.read(activityFeedProvider.notifier).refresh(),
      _ref.read(alertsProvider.notifier).refresh(),
      Future(() => _ref.read(iotLiveProvider.notifier).refresh()),
    ]);
    debugPrint('[RefreshCoordinator] Full refresh complete');
  }

  /// Refresh only dashboard KPIs and alerts (lightweight)
  Future<void> refreshDashboard() async {
    await Future.wait([
      _ref.read(dashboardKpiProvider.notifier).refresh(),
      _ref.read(alertsProvider.notifier).refresh(),
    ]);
  }
}

/// Provider for the refresh coordinator
final refreshCoordinatorProvider = Provider<RefreshCoordinator>((ref) {
  return RefreshCoordinator(ref);
});
