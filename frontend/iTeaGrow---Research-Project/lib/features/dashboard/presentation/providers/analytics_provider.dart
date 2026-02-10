import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';

/// Analytics data state.
class AnalyticsState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? overview;
  final List<Map<String, dynamic>>? diseaseTrends;
  final List<Map<String, dynamic>>? diseaseDistribution;
  final Map<String, dynamic>? recoveryTracking;
  final Map<String, dynamic>? userStats;
  final Map<String, dynamic>? yearlyAnalysis;

  const AnalyticsState({
    this.isLoading = false,
    this.error,
    this.overview,
    this.diseaseTrends,
    this.diseaseDistribution,
    this.recoveryTracking,
    this.userStats,
    this.yearlyAnalysis,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? overview,
    List<Map<String, dynamic>>? diseaseTrends,
    List<Map<String, dynamic>>? diseaseDistribution,
    Map<String, dynamic>? recoveryTracking,
    Map<String, dynamic>? userStats,
    Map<String, dynamic>? yearlyAnalysis,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      overview: overview ?? this.overview,
      diseaseTrends: diseaseTrends ?? this.diseaseTrends,
      diseaseDistribution: diseaseDistribution ?? this.diseaseDistribution,
      recoveryTracking: recoveryTracking ?? this.recoveryTracking,
      userStats: userStats ?? this.userStats,
      yearlyAnalysis: yearlyAnalysis ?? this.yearlyAnalysis,
    );
  }
}

/// Analytics StateNotifier.
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final ApiService _apiService;

  AnalyticsNotifier(this._apiService) : super(const AnalyticsState());

  Future<void> loadOverview() async {
    state = state.copyWith(isLoading: true);

    final response = await _apiService.get<Map<String, dynamic>>(
      '/api/analytics/overview',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      state = state.copyWith(isLoading: false, overview: response.data);
    } else {
      state = state.copyWith(isLoading: false, error: response.error);
    }
  }

  Future<void> loadDiseaseTrends({int days = 90, String interval = 'daily'}) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/api/analytics/disease-trends?days=$days&interval=$interval',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final trends = (response.data!['trends'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      state = state.copyWith(diseaseTrends: trends);
    }
  }

  Future<void> loadDiseaseDistribution({int days = 30}) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/api/analytics/disease-distribution?days=$days',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final distribution = (response.data!['distribution'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      state = state.copyWith(diseaseDistribution: distribution);
    }
  }

  Future<void> loadRecoveryTracking({int days = 90}) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/api/analytics/recovery-tracking?days=$days',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      state = state.copyWith(recoveryTracking: response.data);
    }
  }

  Future<void> loadUserStats() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/api/analytics/user-stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      state = state.copyWith(userStats: response.data);
    }
  }

  Future<void> loadYearlyAnalysis({int? year}) async {
    final yearParam = year != null ? '?year=$year' : '';
    final response = await _apiService.get<Map<String, dynamic>>(
      '/api/analytics/yearly-analysis$yearParam',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      state = state.copyWith(yearlyAnalysis: response.data);
    }
  }

  /// Load all analytics data at once.
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    await Future.wait([
      loadOverview(),
      loadDiseaseTrends(),
      loadDiseaseDistribution(),
      loadRecoveryTracking(),
      loadUserStats(),
      loadYearlyAnalysis(),
    ]);
    state = state.copyWith(isLoading: false);
  }
}

/// Provider for analytics state.
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AnalyticsNotifier(apiService);
});
