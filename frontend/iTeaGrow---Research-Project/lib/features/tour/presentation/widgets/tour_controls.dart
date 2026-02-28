import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';

/// Navigation controls for the tour: Back / Step dots / Next + Skip
class TourControls extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const TourControls({
    super.key,
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
      padding: const EdgeInsets.symmetric(
        horizontal: TeaSpacing.md,
        vertical: TeaSpacing.smd,
      ),
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: BorderRadius.circular(TeaRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main controls row
          Row(
            children: [
              // Back button
              if (!isFirstStep)
                _buildControlButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back',
                  onTap: onBack,
                  isPrimary: false,
                )
              else
                const SizedBox(width: 72),

              const Spacer(),

              // Step dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalSteps, (index) {
                  final isActive = index == currentStep;
                  final isPast = index < currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? TeaColors.freshLeaf
                          : isPast
                              ? TeaColors.freshLeaf.withOpacity(0.4)
                              : TeaColors.lightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const Spacer(),

              // Next / Finish button
              _buildControlButton(
                icon: isLastStep
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                label: isLastStep ? 'Done' : 'Next',
                onTap: onNext,
                isPrimary: true,
              ),
            ],
          ),

          const SizedBox(height: TeaSpacing.xs),

          // Skip tour link
          if (!isLastStep)
            GestureDetector(
              onTap: onSkip,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: TeaSpacing.xs),
                child: Text(
                  'Skip tour',
                  style: TeaTypography.labelSmall.copyWith(
                    color: TeaColors.mediumGray,
                    decoration: TextDecoration.underline,
                    decorationColor: TeaColors.mediumGray,
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.smd,
          vertical: TeaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? TeaColors.freshLeaf : Colors.transparent,
          borderRadius: BorderRadius.circular(TeaRadius.md),
          border: isPrimary
              ? null
              : Border.all(color: TeaColors.mediumGray.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPrimary) ...[
              Icon(icon, size: 16, color: TeaColors.darkGray),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TeaTypography.labelMedium.copyWith(
                color: isPrimary ? TeaColors.white : TeaColors.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: TeaColors.white),
            ],
          ],
        ),
      ),
    );
  }
}
