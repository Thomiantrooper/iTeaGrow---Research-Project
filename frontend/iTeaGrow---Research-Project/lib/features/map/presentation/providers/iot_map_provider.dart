import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/iot_map_repository.dart';
import '../../domain/models/iot_zone_models.dart';

/// Provider for IoT Map Repository
final iotMapRepositoryProvider = Provider<IoTMapRepository>((ref) {
  return IoTMapRepository();
});

/// Provider for latest soil data across all hectares (max 100 from API)
final latestSoilDataProvider = FutureProvider<List<SoilData>>((ref) async {
  final repository = ref.read(iotMapRepositoryProvider);
  return await repository.getLatestData(limit: 100);
});

/// Provider for specific hectare history
final hectareHistoryProvider =
    FutureProvider.family<List<SoilData>, int>((ref, hectareId) async {
  final repository = ref.read(iotMapRepositoryProvider);
  return await repository.getHectareHistory(hectareId, limit: 100);
});

/// Provider for a block's full range of sector data
/// blockBase = the starting hectare_id of the block (e.g. B1 of North = 1)
final blockRangeProvider =
    FutureProvider.family<List<SoilData>, ({int start, int end})>(
        (ref, range) async {
  final repository = ref.read(iotMapRepositoryProvider);
  return await repository.getRangeData(range.start, range.end);
});

/// Provider for API health check
final apiHealthProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(iotMapRepositoryProvider);
  return await repository.checkHealth();
});

/// Provider to force data refresh
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Auto-refresh provider (refreshes every 30 seconds)
final autoRefreshProvider = StreamProvider<int>((ref) async* {
  var counter = 0;
  while (true) {
    await Future.delayed(const Duration(seconds: 30));
    counter++;
    ref.read(refreshTriggerProvider.notifier).state = counter;
    ref.invalidate(latestSoilDataProvider);
    yield counter;
  }
});
