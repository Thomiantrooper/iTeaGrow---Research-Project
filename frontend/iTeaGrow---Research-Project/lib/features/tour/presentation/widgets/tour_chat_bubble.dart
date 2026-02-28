import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';

/// Chat-style speech bubble for the tour guide robot
class TourChatBubble extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final bool isVisible;

  const TourChatBubble({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(TeaRadius.lg),
          topRight: Radius.circular(TeaRadius.lg),
          bottomLeft: Radius.circular(TeaRadius.lg),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: TeaColors.freshLeaf.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: TeaColors.freshLeaf.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar with gradient accent
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TeaSpacing.md,
              vertical: TeaSpacing.smd,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TeaColors.freshLeaf.withOpacity(0.08),
                  TeaColors.goldenSunlight.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(TeaRadius.lg - 1),
                topRight: Radius.circular(TeaRadius.lg - 1),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: TeaColors.freshLeaf.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: TeaColors.freshLeaf,
                    ),
                  ),
                  const SizedBox(width: TeaSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TeaTypography.titleSmall.copyWith(
                      color: TeaColors.matureLeaf,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Message body
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TeaSpacing.md,
              TeaSpacing.sm,
              TeaSpacing.md,
              TeaSpacing.md,
            ),
            child: Text(
              message,
              style: TeaTypography.bodySmall.copyWith(
                color: TeaColors.darkGray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 100.ms)
        .slideY(begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 300.ms);
  }
}
