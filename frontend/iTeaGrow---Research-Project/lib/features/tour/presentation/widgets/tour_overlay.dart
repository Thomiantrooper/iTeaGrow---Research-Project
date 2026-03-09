import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../providers/tour_provider.dart';

/// Floating onboarding tour overlay - positioned above main UI, never overlaps chatbot
class TourOverlay extends ConsumerWidget {
  /// Override to use a different provider (e.g. managerTourProvider).
  /// Defaults to [tourProvider].
  final StateNotifierProvider<TourNotifier, TourState>? tourProviderOverride;
  const TourOverlay({super.key, this.tourProviderOverride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tourProviderOverride ?? tourProvider;
    final tourState = ref.watch(provider);

    if (!tourState.isActive || tourState.currentStep == null) {
      return const SizedBox.shrink();
    }

    final step = tourState.currentStep!;

    // Try to get the target widget's position for the highlight
    Rect? targetRect;
    if (step.targetKey?.currentContext != null) {
      final renderBox =
          step.targetKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        targetRect = Rect.fromLTWH(
          position.dx - 8,
          position.dy - 8,
          renderBox.size.width + 16,
          renderBox.size.height + 16,
        );
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Dimming layer with highlight cutout
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: tourState.isDimmed ? 1.0 : 0.0,
                child: CustomPaint(
                  painter: _HighlightPainter(
                    targetRect: targetRect,
                    dimColor: const Color(0xFF1A1A2E).withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),

          // Centered floating card - the main onboarding content
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: _TourCard(
              key: ValueKey('tour_step_${tourState.currentStepIndex}'),
              icon: step.icon,
              title: step.title,
              message: step.message,
              currentStep: tourState.currentStepIndex,
              totalSteps: tourState.totalSteps,
              isFirstStep: tourState.isFirstStep,
              isLastStep: tourState.isLastStep,
              onNext: () => ref.read(provider.notifier).nextStep(),
              onBack: () => ref.read(provider.notifier).previousStep(),
              onSkip: () => ref.read(provider.notifier).skipTour(),
            ),
          ),

          // Dismiss X button - top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => ref.read(provider.notifier).skipTour(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
        ],
      ),
    );
  }
}

/// The floating tour card widget
class _TourCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final int currentStep;
  final int totalSteps;
  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const _TourCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.currentStep,
    required this.totalSteps,
    required this.isFirstStep,
    required this.isLastStep,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TeaColors.freshLeaf.withOpacity(0.15),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [TeaColors.freshLeaf, TeaColors.matureLeaf],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: TeaColors.freshLeaf.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TeaTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: TeaColors.nearBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Step ${currentStep + 1} of $totalSteps',
                        style: TeaTypography.labelSmall.copyWith(
                          color: TeaColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Message body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: TeaTypography.bodyMedium.copyWith(
                color: TeaColors.darkGray,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final isActive = index == currentStep;
              final isPast = index < currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? TeaColors.freshLeaf
                      : isPast
                          ? TeaColors.freshLeaf.withOpacity(0.3)
                          : TeaColors.lightGray,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                // Skip / Back
                if (!isLastStep)
                  GestureDetector(
                    onTap: onSkip,
                    child: Text(
                      'Skip tour',
                      style: TeaTypography.labelMedium.copyWith(
                        color: TeaColors.mediumGray,
                      ),
                    ),
                  )
                else
                  const SizedBox(),

                const Spacer(),

                // Back button
                if (!isFirstStep)
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: TeaColors.mediumGray.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back_rounded,
                              size: 16, color: TeaColors.darkGray),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TeaTypography.labelMedium.copyWith(
                              color: TeaColors.darkGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!isFirstStep) const SizedBox(width: 8),

                // Next / Done button
                GestureDetector(
                  onTap: onNext,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TeaColors.freshLeaf, TeaColors.matureLeaf],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: TeaColors.freshLeaf.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastStep ? 'Get Started' : 'Next',
                          style: TeaTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isLastStep
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(
            begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
        .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 350.ms);
  }
}

/// Custom painter that dims the screen and punches a rounded-rect hole at the target
class _HighlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color dimColor;

  _HighlightPainter({
    this.targetRect,
    required this.dimColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dimColor;

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect != null) {
      final holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            targetRect!,
            const Radius.circular(16),
          ),
        );

      final combinedPath = Path.combine(
        PathOperation.difference,
        fullPath,
        holePath,
      );

      canvas.drawPath(combinedPath, paint);

      // Subtle glow border around cutout
      final borderPaint = Paint()
        ..color = TeaColors.freshLeaf.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          targetRect!,
          const Radius.circular(16),
        ),
        borderPaint,
      );
    } else {
      canvas.drawPath(fullPath, paint);
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) =>
      targetRect != oldDelegate.targetRect ||
      dimColor != oldDelegate.dimColor;
}
