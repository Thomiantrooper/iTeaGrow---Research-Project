import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/design_system.dart';

/// Large gradient hero card inspired by modern travel-app UI
class TeaGradientHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? description;
  final String? badgeText;
  final List<Color>? gradientColors;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double height;

  const TeaGradientHeroCard({
    super.key,
    required this.title,
    this.subtitle = '',
    this.description,
    this.badgeText,
    this.gradientColors,
    this.icon,
    this.trailing,
    this.onTap,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [TeaColors.matureLeaf, TeaColors.freshLeaf, TeaColors.leafLight];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(TeaRadius.huge),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 40,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(TeaSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TeaSpacing.smd,
                        vertical: TeaSpacing.xs,
                      ),
                      margin: const EdgeInsets.only(bottom: TeaSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(TeaRadius.round),
                      ),
                      child: Text(
                        badgeText!,
                        style: TeaTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: TeaTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: TeaSpacing.xs),
                    Text(
                      subtitle,
                      style: TeaTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: TeaSpacing.sm),
                    Text(
                      description!,
                      style: TeaTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Icon watermark
            if (icon != null)
              Positioned(
                right: TeaSpacing.lg,
                top: TeaSpacing.lg,
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),

            // Trailing widget
            if (trailing != null)
              Positioned(
                right: TeaSpacing.md,
                bottom: TeaSpacing.md,
                child: trailing!,
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms);
  }
}
