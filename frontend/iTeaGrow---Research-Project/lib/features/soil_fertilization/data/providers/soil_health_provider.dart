import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/soil_health_record.dart';

// Sentinel to distinguish "not passed" from explicit null in copyWith.
// Standard Dart workaround for clearing nullable fields.
const _absent = Object();

class SoilHealthState {
  final List<SoilHealthRecord> records;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefreshed;
  final int? selectedZoneId;
  final int? selectedHectareId;
  final int? selectedBlockId;

  SoilHealthState({
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.lastRefreshed,
    this.selectedZoneId,
    this.selectedHectareId,
    this.selectedBlockId,
  });

  /// Returns the record for the current navigation level.
  /// — Sector selected (selectedBlockId = 1–25): returns record at blockBase + blockId - 1
  /// — Block selected (no sector): returns most recent across the 25-sector block range
  /// — No selection: returns the most recent overall record
  SoilHealthRecord? get latest {
    if (records.isEmpty) return null;

    // Sector selected: sectorHectareId = blockBase + sectorIndex - 1
    if (selectedHectareId != null && selectedBlockId != null) {
      final sectorHId = selectedHectareId! + selectedBlockId! - 1;
      final matches = records.where((r) => r.hectareId == sectorHId).toList();
      if (matches.isEmpty) return null;
      matches.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return matches.first;
    }

    // Block selected: return most recent record within the 25-sector block range
    if (selectedHectareId != null) {
      final blockEnd = selectedHectareId! + 24;
      final matches = records
          .where((r) =>
              r.hectareId >= selectedHectareId! && r.hectareId <= blockEnd)
          .toList();
      if (matches.isEmpty) return null;
      matches.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return matches.first;
    }

    // No selection: most recent overall
    final sorted = [...records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.first;
  }

  /// copyWith that correctly clears nullable int fields when null is passed.
  /// Use the default (_absent) to keep existing value; pass null to clear.
  SoilHealthState copyWith({
    List<SoilHealthRecord>? records,
    bool? isLoading,
    String? error,
    DateTime? lastRefreshed,
    Object? selectedZoneId = _absent,
    Object? selectedHectareId = _absent,
    Object? selectedBlockId = _absent,
  }) {
    return SoilHealthState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      selectedZoneId: identical(selectedZoneId, _absent)
          ? this.selectedZoneId
          : selectedZoneId as int?,
      selectedHectareId: identical(selectedHectareId, _absent)
          ? this.selectedHectareId
          : selectedHectareId as int?,
      selectedBlockId: identical(selectedBlockId, _absent)
          ? this.selectedBlockId
          : selectedBlockId as int?,
    );
  }
}

class SoilHealthNotifier extends StateNotifier<SoilHealthState> {
  SoilHealthNotifier() : super(SoilHealthState()) {
    _startPolling();
  }

  static const _pollInterval = Duration(seconds: 30);
  static const String _baseUrl =
      'https://iteagrow-soil-monitoring-iot-api.up.railway.app';
  Timer? _timer;

  void _startPolling() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(_pollInterval, (_) => _backgroundRefresh());
  }

  /// Merges incoming records into existing, keeping the most recent per hectare_id.
  /// One record per hectare_id — matches the map screen's _allSoilData behaviour.
  List<SoilHealthRecord> _mergeRecords(
      List<SoilHealthRecord> existing, List<SoilHealthRecord> incoming) {
    final map = <int, SoilHealthRecord>{
      for (var r in existing) r.hectareId: r,
    };
    for (var r in incoming) {
      final cur = map[r.hectareId];
      if (cur == null || r.timestamp.isAfter(cur.timestamp)) {
        map[r.hectareId] = r;
      }
    }
    return map.values.toList();
  }

  /// Full refresh triggered by user — shows loading indicator.
  /// Uses /farm/by-hectare which runs a MongoDB aggregation returning exactly
  /// ONE record per hectare (always the newest), so scan-round accumulation
  /// never causes the 100-record limit to drop older hectares.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farm/by-hectare'),
        headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final fresh = data.map((j) => SoilHealthRecord.fromJson(j)).toList();
        // Fresh already contains 1 record per hectare (newest). Full replace is safe.
        state = state.copyWith(
          records: fresh,
          isLoading: false,
          lastRefreshed: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Connection failed: $e',
      );
    }
  }

  /// Background refresh — silent, preserves selected state.
  /// Also uses /farm/by-hectare so scan-round accumulation never causes stale data.
  Future<void> _backgroundRefresh() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farm/by-hectare'),
        headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final fresh = data.map((j) => SoilHealthRecord.fromJson(j)).toList();
        // Merge with any block-range records already loaded for the selected block.
        state = state.copyWith(
          records: _mergeRecords(state.records, fresh),
          lastRefreshed: DateTime.now(),
        );
      }
    } catch (_) {
      // Silent fail
    }
  }

  /// Loads all 25 sector records for a block via /farm/range (mirrors map screen logic).
  /// [blockBase] = selectedHectareId (the block’s first hectare_id, e.g. 1 for North B1).
  Future<void> loadHectareData(int blockBase) async {
    try {
      final blockEnd = blockBase + 24;
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/farm/range?start_hectare=$blockBase&end_hectare=$blockEnd&limit=1000'),
        headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final blockRecords =
            data.map((j) => SoilHealthRecord.fromJson(j)).toList();
        // Replace existing records in this block range with fresh data
        final updated = [
          ...state.records
              .where((r) => r.hectareId < blockBase || r.hectareId > blockEnd),
          ...blockRecords,
        ];
        state = state.copyWith(records: updated);
      }
    } catch (_) {
      // Non-fatal: existing records still display
    }
  }

  void selectZone(int zoneId) {
    state = state.copyWith(
      selectedZoneId: zoneId,
      selectedHectareId: null,
      selectedBlockId: null,
    );
  }

  void selectHectare(int hectareId) {
    state = state.copyWith(
      selectedHectareId: hectareId,
      selectedBlockId: null,
    );
    // Load all S-block records for this hectare (mirrors map screen logic)
    loadHectareData(hectareId);
  }

  void selectBlock(int blockId) {
    state = state.copyWith(selectedBlockId: blockId);
  }

  void selectNext() {
    if (state.selectedHectareId == null) return;
    final blockBase = state.selectedHectareId!;
    final blockEnd = blockBase + 24;
    // Navigate only through sectors that actually have data in this block range
    final sectorsWithData = state.records
        .where((r) => r.hectareId >= blockBase && r.hectareId <= blockEnd)
        .map((r) => r.hectareId - blockBase + 1) // sector index 1-25
        .toSet()
        .toList()
      ..sort();

    if (sectorsWithData.isEmpty) return;

    if (state.selectedBlockId == null) {
      selectBlock(sectorsWithData.first);
      return;
    }

    final idx = sectorsWithData.indexOf(state.selectedBlockId!);
    final nextIdx = idx >= sectorsWithData.length - 1 ? 0 : idx + 1;
    selectBlock(sectorsWithData[nextIdx]);
  }

  void selectPrevious() {
    if (state.selectedHectareId == null) return;
    final blockBase = state.selectedHectareId!;
    final blockEnd = blockBase + 24;
    // Navigate only through sectors that actually have data in this block range
    final sectorsWithData = state.records
        .where((r) => r.hectareId >= blockBase && r.hectareId <= blockEnd)
        .map((r) => r.hectareId - blockBase + 1) // sector index 1-25
        .toSet()
        .toList()
      ..sort();

    if (sectorsWithData.isEmpty) return;

    if (state.selectedBlockId == null) {
      selectBlock(sectorsWithData.last);
      return;
    }

    final idx = sectorsWithData.indexOf(state.selectedBlockId!);
    final prevIdx = idx <= 0 ? sectorsWithData.length - 1 : idx - 1;
    selectBlock(sectorsWithData[prevIdx]);
  }

  void navigateUp() {
    if (state.selectedBlockId != null) {
      state = state.copyWith(selectedBlockId: null);
    } else if (state.selectedHectareId != null) {
      state = state.copyWith(selectedHectareId: null);
    } else if (state.selectedZoneId != null) {
      state = state.copyWith(selectedZoneId: null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final soilHealthProvider =
    StateNotifierProvider<SoilHealthNotifier, SoilHealthState>((ref) {
  return SoilHealthNotifier();
});
