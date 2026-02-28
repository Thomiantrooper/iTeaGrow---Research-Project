import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../providers/tour_provider.dart';
import 'tour_robot.dart';
import 'tour_chat_bubble.dart';
import 'tour_controls.dart';

/// Full-screen tour overlay with dimming, highlight cutout, robot, bubble, and controls
class TourOverlay extends ConsumerWidget {
  const TourOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourState = ref.watch(tourProvider);

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
          // Dimming layer with optional highlight cutout
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // Absorb taps on dimmed area
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: tourState.isDimmed ? 1.0 : 0.0,
                child: CustomPaint(
                  painter: _HighlightPainter(
                    targetRect: targetRect,
                    dimColor: TeaColors.nearBlack.withOpacity(0.55),
                  ),
                ),
              ),
            ),
          ),

          // Chat bubble - positioned above the robot in bottom-right
          Positioned(
            right: TeaSpacing.md,
            bottom: 160,
            child: TourChatBubble(
              key: ValueKey('bubble_${tourState.currentStepIndex}'),
              title: step.title,
              message: step.message,
              icon: step.icon,
            ),
          ),

          // Robot character - bottom right
          Positioned(
            right: TeaSpacing.lg,
            bottom: 90,
            child: TourRobot(
              isVisible: true,
              isTalking: true,
              onTap: () => ref.read(tourProvider.notifier).nextStep(),
            ),
          ),

          // Controls bar - bottom center
          Positioned(
            left: TeaSpacing.md,
            right: TeaSpacing.md,
            bottom: TeaSpacing.lg,
            child: SafeArea(
              child: TourControls(
                currentStep: tourState.currentStepIndex,
                totalSteps: tourState.totalSteps,
                isFirstStep: tourState.isFirstStep,
                isLastStep: tourState.isLastStep,
                onNext: () => ref.read(tourProvider.notifier).nextStep(),
                onBack: () => ref.read(tourProvider.notifier).previousStep(),
                onSkip: () => ref.read(tourProvider.notifier).skipTour(),
              ),
            ),
          ),

          // Step counter label
          Positioned(
            top: MediaQuery.of(context).padding.top + TeaSpacing.md,
            right: TeaSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TeaSpacing.smd,
                vertical: TeaSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: TeaColors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(TeaRadius.round),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '${tourState.currentStepIndex + 1} / ${tourState.totalSteps}',
                style: TeaTypography.labelSmall.copyWith(
                  color: TeaColors.freshLeaf,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
        ],
      ),
    );
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

    // Full-screen dim
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect != null) {
      // Punch a hole for the target
      final holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            targetRect!,
            const Radius.circular(TeaRadius.md),
          ),
        );

      // Combine paths with evenOdd to create the cutout
      final combinedPath = Path.combine(
        PathOperation.difference,
        fullPath,
        holePath,
      );

      canvas.drawPath(combinedPath, paint);

      // Draw a subtle glow border around the cutout
      final borderPaint = Paint()
        ..color = TeaColors.goldenSunlight.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          targetRect!,
          const Radius.circular(TeaRadius.md),
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
