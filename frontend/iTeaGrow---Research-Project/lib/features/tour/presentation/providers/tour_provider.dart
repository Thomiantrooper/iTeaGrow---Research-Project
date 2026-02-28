import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/local_auth_service.dart';
import '../../domain/tour_step.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class TourState {
  final bool isActive;
  final bool isCompleted;
  final int currentStepIndex;
  final List<TourStep> steps;
  final bool isDimmed;

  const TourState({
    this.isActive = false,
    this.isCompleted = false,
    this.currentStepIndex = 0,
    this.steps = const [],
    this.isDimmed = false,
  });

  TourStep? get currentStep =>
      steps.isNotEmpty && currentStepIndex < steps.length
          ? steps[currentStepIndex]
          : null;

  int get totalSteps => steps.length;
  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex >= steps.length - 1;
  double get progress =>
      steps.isEmpty ? 0 : (currentStepIndex + 1) / steps.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class TourNotifier extends StateNotifier<TourState> {
  final SharedPreferences _prefs;
  static const _completedKey = 'tour_completed';

  TourNotifier(this._prefs) : super(const TourState()) {
    _loadCompletionState();
  }

  void _loadCompletionState() {
    final completed = _prefs.getBool(_completedKey) ?? false;
    state = TourState(isCompleted: completed);
  }

  /// Start the tour with the given steps
  void startTour({
    GlobalKey? heroCardKey,
    GlobalKey? metricsKey,
    GlobalKey? quickActionsKey,
    GlobalKey? alertsKey,
  }) {
    final steps = TourSteps.buildSteps(
      heroCardKey: heroCardKey,
      metricsKey: metricsKey,
      quickActionsKey: quickActionsKey,
      alertsKey: alertsKey,
    );

    state = TourState(
      isActive: true,
      isCompleted: false,
      currentStepIndex: 0,
      steps: steps,
      isDimmed: true,
    );
  }

  /// Move to the next step
  void nextStep() {
    if (state.isLastStep) {
      completeTour();
      return;
    }
    state = TourState(
      isActive: true,
      currentStepIndex: state.currentStepIndex + 1,
      steps: state.steps,
      isDimmed: true,
    );
  }

  /// Move to the previous step
  void previousStep() {
    if (state.isFirstStep) return;
    state = TourState(
      isActive: true,
      currentStepIndex: state.currentStepIndex - 1,
      steps: state.steps,
      isDimmed: true,
    );
  }

  /// Skip the tour entirely
  void skipTour() {
    _prefs.setBool(_completedKey, true);
    state = const TourState(isCompleted: true);
  }

  /// Complete the tour (last step done)
  void completeTour() {
    _prefs.setBool(_completedKey, true);
    state = const TourState(isCompleted: true);
  }

  /// Reset the tour (for re-taking it from settings)
  void resetTour() {
    _prefs.setBool(_completedKey, false);
    state = const TourState(isCompleted: false);
  }

  /// Check if tour should auto-start (first time user)
  bool get shouldAutoStart => !state.isCompleted && !state.isActive;
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final tourProvider = StateNotifierProvider<TourNotifier, TourState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TourNotifier(prefs);
});
