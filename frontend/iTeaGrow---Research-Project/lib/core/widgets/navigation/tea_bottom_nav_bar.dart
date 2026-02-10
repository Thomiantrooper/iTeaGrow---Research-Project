import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

/// A navigation item for [TeaBottomNavBar].
class TeaNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const TeaNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A premium reusable bottom navigation bar with frosted-glass effect,
/// rounded top corners, and animated active indicator.
class TeaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<TeaNavItem> items;
  final ValueChanged<int> onTap;

  const TeaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TeaColors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(TeaRadius.xl),
          topRight: Radius.circular(TeaRadius.xl),
        ),
        boxShadow: const [
          BoxShadow(
            color: TeaColors.shadowVale,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TeaSpacing.sm,
            vertical: TeaSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              return _TeaNavBarItem(
                item: items[index],
                isActive: index == currentIndex,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TeaNavBarItem extends StatelessWidget {
  final TeaNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _TeaNavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.md,
          vertical: TeaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? TeaColors.freshLeaf.withOpacity(0.10)
              : Colors.transparent,
          borderRadius: TeaRadius.radiusRound,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 6 : 0,
              height: isActive ? 6 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: TeaColors.freshLeaf,
              ),
            ),
            // Icon
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? TeaColors.freshLeaf : TeaColors.darkGray,
              size: 24,
            ),
            const SizedBox(height: TeaSpacing.xxs),
            // Label
            Text(
              item.label,
              style: TeaTypography.labelSmall.copyWith(
                color: isActive ? TeaColors.freshLeaf : TeaColors.darkGray,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
