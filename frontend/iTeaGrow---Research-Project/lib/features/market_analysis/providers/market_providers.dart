import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../core/services/local_auth_service.dart';
import '../data/models/market_models.dart';
import '../data/services/market_api_service.dart';
import '../data/services/grading_ml_service.dart';

// Services
final marketApiServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MarketApiService(prefs);
});
final gradingMlServiceProvider = Provider<GradingMlService>((ref) {
  final service = GradingMlService();
  service.initModel(); // Ideally initialize early or on demand
  return service;
});

// API Health State
class MarketApiHealthNotifier extends StateNotifier<bool> {
  final MarketApiService _apiService;

  MarketApiHealthNotifier(this._apiService) : super(false) {
    checkHealth();
  }

  Future<void> checkHealth() async {
    try {
      final isHealthy = await _apiService.checkHealth();
      if (mounted) state = isHealthy;
    } catch (_) {
      if (mounted) state = false;
    }
  }
}

final marketApiHealthProvider =
    StateNotifierProvider<MarketApiHealthNotifier, bool>((ref) {
  return MarketApiHealthNotifier(ref.watch(marketApiServiceProvider));
});

// Classification State Holder
final classificationProvider = StateNotifierProvider.autoDispose<
    ClassificationNotifier, AsyncValue<ClassificationResult?>>((ref) {
  return ClassificationNotifier(
      ref.watch(gradingMlServiceProvider), ref.watch(marketApiServiceProvider));
});

class ClassificationNotifier
    extends StateNotifier<AsyncValue<ClassificationResult?>> {
  final GradingMlService _mlService;
  final MarketApiService _apiService;

  ClassificationNotifier(this._mlService, this._apiService)
      : super(const AsyncValue.data(null));

  Future<void> classify(File image,
      {bool forceOnline = false, bool generateHeatmap = true}) async {
    state = const AsyncValue.loading();
    try {
      ClassificationResult? result;

      if (!forceOnline) {
        // Try Offline first
        result = await _mlService.classifyImage(image,
            generateHeatmap: generateHeatmap);
      }

      if (result == null || forceOnline) {
        // Fallback or forced Online API
        result = await _apiService.classifyImageOnline(image);
      }

      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

// Live Market Grid State
final marketPricesProvider = FutureProvider<MarketPriceResponse>((ref) async {
  final api = ref.watch(marketApiServiceProvider);
  return await api.getMarketPrices();
});

// Market History Provider
final marketHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(marketApiServiceProvider);
  return await api.getMarketHistory();
});

// Market Report Data Provider (fetch details for a specific record)
final marketReportDataProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(marketApiServiceProvider);
  return await api.getMarketReportData(id);
});

// Price Calculation Async State
final priceCalculationProvider = StateNotifierProvider.autoDispose<
    PriceCalculationNotifier, AsyncValue<PricingResponse?>>((ref) {
  return PriceCalculationNotifier(ref.watch(marketApiServiceProvider));
});

class PriceCalculationNotifier
    extends StateNotifier<AsyncValue<PricingResponse?>> {
  final MarketApiService _apiService;

  PriceCalculationNotifier(this._apiService)
      : super(const AsyncValue.data(null));

  Future<void> calculatePrice(PricingRequest request,
      {String? imagePath}) async {
    state = const AsyncValue.loading();
    try {
      final response =
          await _apiService.calculatePrice(request, imagePath: imagePath);
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

// Market Summary Provider (for analytics)
final marketSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, days) async {
  final api = ref.watch(marketApiServiceProvider);
  return await api.getMarketSummary(days: days);
});
