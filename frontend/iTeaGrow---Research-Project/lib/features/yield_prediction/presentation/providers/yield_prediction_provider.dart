import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/yield_prediction_ml_service.dart';
import '../../data/models/prediction_request_model.dart';
import '../../domain/entities/yield_prediction_result.dart';

/// State for yield prediction
class YieldPredictionState {
  final bool isLoading;
  final YieldPredictionResult? result;
  final String? error;
  final bool isApiHealthy;

  YieldPredictionState({
    this.isLoading = false,
    this.result,
    this.error,
    this.isApiHealthy = false,
  });

  YieldPredictionState copyWith({
    bool? isLoading,
    YieldPredictionResult? result,
    String? error,
    bool? isApiHealthy,
  }) {
    return YieldPredictionState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
      isApiHealthy: isApiHealthy ?? this.isApiHealthy,
    );
  }
}

/// Yield prediction notifier
class YieldPredictionNotifier extends StateNotifier<YieldPredictionState> {
  YieldPredictionNotifier() : super(YieldPredictionState()) {
    _initialize();
  }

  final _apiService = YieldPredictionApiService();

  Future<void> _initialize() async {
    await _apiService.initialize();
    final isHealthy = await _apiService.checkHealth();
    state = state.copyWith(isApiHealthy: isHealthy);
  }

  /// Check API health
  Future<void> checkHealth() async {
    final isHealthy = await _apiService.checkHealth();
    state = state.copyWith(isApiHealthy: isHealthy);
  }

  /// Get yield prediction
  Future<void> getPrediction(PredictionRequestModel request) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getPrediction(request);
      final result = YieldPredictionResult.fromResponseModel(response);

      if (result.success) {
        // Save to local backend for tracking
        await _apiService.savePrediction(request, response);

        state = state.copyWith(
          isLoading: false,
          result: result,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Prediction failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Clear current result
  void clearResult() {
    state = state.copyWith(result: null, error: null);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for yield prediction state
final yieldPredictionProvider =
    StateNotifierProvider<YieldPredictionNotifier, YieldPredictionState>((ref) {
  return YieldPredictionNotifier();
});

/// Provider for API service (for direct access if needed)
final yieldPredictionApiServiceProvider =
    Provider<YieldPredictionApiService>((ref) {
  return YieldPredictionApiService();
});
