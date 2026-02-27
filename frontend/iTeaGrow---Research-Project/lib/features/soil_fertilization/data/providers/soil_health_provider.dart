import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
import '../../domain/entities/soil_health_record.dart';

class SoilHealthState {
  final List<SoilHealthRecord> records;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefreshed;
  final int? selectedHectareId;

  SoilHealthState({
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.lastRefreshed,
    this.selectedHectareId,
  });

  /// Returns the record for the selected hectare, or the first one if none selected
  SoilHealthRecord? get latest {
    if (records.isEmpty) return null;
    if (selectedHectareId == null) return records.first;
    try {
      return records.firstWhere((r) => r.hectareId == selectedHectareId);
    } catch (_) {
      return records.first;
    }
  }

  SoilHealthState copyWith({
    List<SoilHealthRecord>? records,
    bool? isLoading,
    String? error,
    DateTime? lastRefreshed,
    int? selectedHectareId,
  }) {
    return SoilHealthState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      selectedHectareId: selectedHectareId ?? this.selectedHectareId,
    );
  }
}

class SoilHealthNotifier extends StateNotifier<SoilHealthState> {
  SoilHealthNotifier() : super(SoilHealthState()) {
    _startPolling();
  }

  static const _pollInterval = Duration(seconds: 10);
  Timer? _timer;

  void _startPolling() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.soilLatestPredictions),
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final records =
            data.map((json) => SoilHealthRecord.fromJson(json)).toList();

        state = state.copyWith(
          records: records,
          isLoading: false,
          lastRefreshed: DateTime.now(),
          // Default to first hectare if not set
          selectedHectareId: state.selectedHectareId ??
              (records.isNotEmpty ? records.first.hectareId : null),
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

  void selectHectare(int hectareId) {
    state = state.copyWith(selectedHectareId: hectareId);
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
