import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
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

  /// Returns the record for the selected block/hectare.
  /// Returns null when the selected block has no data — never shows fake fallback data.
  SoilHealthRecord? get latest {
    if (records.isEmpty) return null;

    // If a specific block is selected, only return its record — null if no data
    if (selectedHectareId != null && selectedBlockId != null) {
      final matches = records
          .where((r) =>
              r.hectareId == selectedHectareId && r.blockId == selectedBlockId)
          .toList();
      if (matches.isEmpty) return null; // No data for this block — show nothing
      matches.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return matches.first;
    }

    // Hectare selected but no specific block — return most recent for that hectare
    if (selectedHectareId != null) {
      final matches =
          records.where((r) => r.hectareId == selectedHectareId).toList();
      if (matches.isEmpty) return null;
      matches.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return matches.first;
    }

    // No selection at all — return the most recent overall record
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

  /// Merges incoming records into existing without overwriting per-hectare
  /// loaded records. Key = "hectareId_blockId" ensures one entry per block.
  List<SoilHealthRecord> _mergeRecords(
      List<SoilHealthRecord> existing, List<SoilHealthRecord> incoming) {
    final map = <String, SoilHealthRecord>{
      for (var r in existing) '${r.hectareId}_${r.blockId}': r,
    };
    for (var r in incoming) {
      final key = '${r.hectareId}_${r.blockId}';
      if (!map.containsKey(key)) map[key] = r;
    }
    return map.values.toList();
  }

  /// Full refresh triggered by user — shows loading indicator.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      // /farm/latest?limit=100 returns ALL per-block records, not aggregated
      final response = await http.get(
        Uri.parse('$_baseUrl/farm/latest?limit=100'),
        headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final fresh = data.map((j) => SoilHealthRecord.fromJson(j)).toList();
        final merged = _mergeRecords(state.records, fresh);
        state = state.copyWith(
          records: merged,
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
  Future<void> _backgroundRefresh() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farm/latest?limit=100'),
        headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final fresh = data.map((j) => SoilHealthRecord.fromJson(j)).toList();
        state = state.copyWith(
          records: _mergeRecords(state.records, fresh),
          lastRefreshed: DateTime.now(),
        );
      }
    } catch (_) {
      // Silent fail
    }
  }

  /// Loads ALL block records for a given hectare from /hectare/{id}.
  /// Mirrors map screen's _loadHectareData. Called automatically on selectHectare.
  Future<void> loadHectareData(int hectareId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.soilHectareData(hectareId)}?limit=100'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final hectareRecords =
            data.map((j) => SoilHealthRecord.fromJson(j)).toList();
        // Replace ALL records for this hectare with the freshly loaded set
        final updated = [
          ...state.records.where((r) => r.hectareId != hectareId),
          ...hectareRecords,
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

    // Only navigate to blocks that actually have data for the current hectare
    final blocksWithData = state.records
        .where(
            (r) => r.hectareId == state.selectedHectareId && r.blockId != null)
        .map((r) => r.blockId!)
        .toSet()
        .toList()
      ..sort();

    if (blocksWithData.isEmpty) return;

    if (state.selectedBlockId == null) {
      selectBlock(blocksWithData.first);
      return;
    }

    final idx = blocksWithData.indexOf(state.selectedBlockId!);
    final nextIdx = idx >= blocksWithData.length - 1 ? 0 : idx + 1;
    selectBlock(blocksWithData[nextIdx]);
  }

  void selectPrevious() {
    if (state.selectedHectareId == null) return;

    // Only navigate to blocks that actually have data for the current hectare
    final blocksWithData = state.records
        .where(
            (r) => r.hectareId == state.selectedHectareId && r.blockId != null)
        .map((r) => r.blockId!)
        .toSet()
        .toList()
      ..sort();

    if (blocksWithData.isEmpty) return;

    if (state.selectedBlockId == null) {
      selectBlock(blocksWithData.last);
      return;
    }

    final idx = blocksWithData.indexOf(state.selectedBlockId!);
    final prevIdx = idx <= 0 ? blocksWithData.length - 1 : idx - 1;
    selectBlock(blocksWithData[prevIdx]);
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
