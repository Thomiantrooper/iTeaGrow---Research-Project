import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/design_system.dart';

/// Base shimmer placeholder rectangle
class TeaSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const TeaSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: TeaColors.lightGray.withOpacity(0.4),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 1200.ms,
          color: TeaColors.white.withOpacity(0.5),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.6, end: 1.0, duration: 1200.ms);
  }
}

/// Full card skeleton matching TeaCard.elevated dimensions
class TeaSkeletonCard extends StatelessWidget {
  final double height;

  const TeaSkeletonCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: TeaSpacing.cardPaddingMd,
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: TeaRadius.radiusLg,
        boxShadow: TeaShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              TeaSkeleton(width: 40, height: 40, borderRadius: TeaRadius.sm),
              const SizedBox(width: TeaSpacing.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    TeaSkeleton(width: 120, height: 14),
                    SizedBox(height: 6),
                    TeaSkeleton(width: 80, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const TeaSkeleton(height: 12),
        ],
      ),
    );
  }
}

/// Three side-by-side skeleton cards matching metrics row layout
class TeaSkeletonMetricRow extends StatelessWidget {
  const TeaSkeletonMetricRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildMetricSkeleton()),
        const SizedBox(width: TeaSpacing.smd),
        Expanded(child: _buildMetricSkeleton()),
        const SizedBox(width: TeaSpacing.smd),
        Expanded(child: _buildMetricSkeleton()),
      ],
    );
  }

  Widget _buildMetricSkeleton() {
    return Container(
      padding: const EdgeInsets.all(TeaSpacing.smd),
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: TeaRadius.radiusMd,
        boxShadow: TeaShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TeaSkeleton(width: 32, height: 32, borderRadius: 8),
          const SizedBox(height: TeaSpacing.sm),
          const TeaSkeleton(width: 50, height: 22),
          const SizedBox(height: 4),
          TeaSkeleton(height: 10),
        ],
      ),
    );
  }
}

/// Hero card skeleton matching the premium dashboard hero layout
class TeaSkeletonHeroCard extends StatelessWidget {
  const TeaSkeletonHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: TeaRadius.radiusLg,
        boxShadow: TeaShadows.cardShadow,
      ),
      child: Column(
        children: [
          // Top visualization area
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: TeaColors.leafPale.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(TeaRadius.lg),
              ),
            ),
            padding: const EdgeInsets.all(TeaSpacing.md),
            child: Row(
              children: [
                // Left plant circle placeholder
                Expanded(
                  flex: 2,
                  child: Center(
                    child: TeaSkeleton(
                      width: 100,
                      height: 100,
                      borderRadius: 50,
                    ),
                  ),
                ),
                // Right stats panel
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(TeaSpacing.smd),
                    decoration: BoxDecoration(
                      color: TeaColors.white.withOpacity(0.5),
                      borderRadius: TeaRadius.radiusMd,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TeaSkeleton(width: 110, height: 14),
                        const SizedBox(height: TeaSpacing.smd),
                        ...List.generate(
                          4,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TeaSkeleton(width: 70, height: 10),
                                TeaSkeleton(width: 40, height: 18, borderRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom stats section
          Padding(
            padding: TeaSpacing.cardPaddingMd,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        TeaSkeleton(width: 140, height: 16),
                        SizedBox(height: 4),
                        TeaSkeleton(width: 100, height: 12),
                      ],
                    ),
                    const TeaSkeleton(width: 90, height: 32, borderRadius: 16),
                  ],
                ),
                const SizedBox(height: TeaSpacing.md),
                const TeaSkeleton(height: 8, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity list skeleton with 3 list items
class TeaSkeletonActivityList extends StatelessWidget {
  final int itemCount;

  const TeaSkeletonActivityList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: TeaRadius.radiusLg,
        boxShadow: TeaShadows.cardShadow,
      ),
      child: Column(
        children: List.generate(itemCount, (index) {
          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              Padding(
                padding: TeaSpacing.cardPaddingMd,
                child: Row(
                  children: [
                    TeaSkeleton(width: 36, height: 36, borderRadius: TeaRadius.sm),
                    const SizedBox(width: TeaSpacing.smd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          TeaSkeleton(width: 140, height: 14),
                          SizedBox(height: 4),
                          TeaSkeleton(width: 100, height: 10),
                        ],
                      ),
                    ),
                    const TeaSkeleton(width: 50, height: 10),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Alert list skeleton
class TeaSkeletonAlertList extends StatelessWidget {
  final int itemCount;

  const TeaSkeletonAlertList({super.key, this.itemCount = 2});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < itemCount - 1 ? TeaSpacing.sm : 0),
          child: Container(
            padding: TeaSpacing.cardPaddingMd,
            decoration: BoxDecoration(
              color: TeaColors.white,
              borderRadius: TeaRadius.radiusMd,
              border: Border.all(color: TeaColors.lightGray.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                TeaSkeleton(width: 36, height: 36, borderRadius: TeaRadius.sm),
                const SizedBox(width: TeaSpacing.smd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      TeaSkeleton(width: 180, height: 14),
                      SizedBox(height: 6),
                      TeaSkeleton(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
