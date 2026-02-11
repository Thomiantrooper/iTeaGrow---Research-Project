import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

/// A premium card with a background image (or gradient fallback),
/// dark overlay, and positioned text content.
class TeaImageCard extends StatelessWidget {
  /// Asset path for the background image (e.g. 'assets/images/scan.png').
  final String? imagePath;

  /// Fallback icon shown when [imagePath] is null.
  final IconData? fallbackIcon;

  /// Gradient colors used as fallback when no image, or as overlay tint.
  final List<Color> gradientColors;

  final String title;
  final String? subtitle;
  final String? tag;
  final VoidCallback? onTap;
  final double height;
  final BorderRadius? borderRadius;

  const TeaImageCard({
    super.key,
    this.imagePath,
    this.fallbackIcon,
    this.gradientColors = const [TeaColors.freshLeaf, TeaColors.matureLeaf],
    required this.title,
    this.subtitle,
    this.tag,
    this.onTap,
    this.height = 140,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? TeaRadius.radiusLg;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: image or gradient
              if (imagePath != null)
                Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                  ),
                ),

              // Gradient overlay (darker at bottom for text readability)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(imagePath != null ? 0.15 : 0.0),
                      Colors.black.withOpacity(imagePath != null ? 0.55 : 0.15),
                    ],
                  ),
                ),
              ),

              // Large watermark icon (behind text, bottom-right)
              if (fallbackIcon != null)
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Icon(
                    fallbackIcon,
                    size: 72,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),

              // Text content
              Padding(
                padding: const EdgeInsets.all(TeaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (tag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tag!,
                          style: TeaTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      title,
                      style: TeaTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TeaTypography.labelSmall.copyWith(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
