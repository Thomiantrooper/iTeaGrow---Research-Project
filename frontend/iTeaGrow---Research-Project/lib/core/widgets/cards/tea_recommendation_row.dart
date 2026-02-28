import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/design_system.dart';

/// Horizontal scrolling recommendation cards section
class TeaRecommendationRow extends StatelessWidget {
  final String sectionTitle;
  final List<TeaRecommendationItem> items;
  final VoidCallback? onSeeAll;

  const TeaRecommendationRow({
    super.key,
    required this.sectionTitle,
    required this.items,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TeaSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: TeaTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'See all',
                    style: TeaTypography.labelMedium.copyWith(
                      color: TeaColors.freshLeaf,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: TeaSpacing.sm),

        // Horizontal scrolling cards
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: TeaSpacing.smd),
            itemBuilder: (context, index) {
              return _RecommendationCard(
                item: items[index],
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final TeaRecommendationItem item;
  final int index;

  const _RecommendationCard({
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = item.gradientColors ??
        [TeaColors.freshLeaf, TeaColors.matureLeaf];

    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(TeaRadius.lg),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(TeaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(TeaSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(TeaRadius.sm),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    item.title,
                    style: TeaTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Subtitle
                  Text(
                    item.subtitle,
                    style: TeaTypography.labelSmall.copyWith(
                      color: Colors.white.withOpacity(0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.badge != null) ...[
                    const SizedBox(height: TeaSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TeaSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius:
                            BorderRadius.circular(TeaRadius.round),
                      ),
                      child: Text(
                        item.badge!,
                        style: TeaTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 80))
        .slideX(begin: 0.2, end: 0, duration: 350.ms);
  }
}

/// Data model for a recommendation item
class TeaRecommendationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color>? gradientColors;
  final String? badge;
  final VoidCallback? onTap;

  const TeaRecommendationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradientColors,
    this.badge,
    this.onTap,
  });
}
