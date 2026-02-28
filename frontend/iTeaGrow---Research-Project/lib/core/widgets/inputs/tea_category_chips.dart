import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

/// Horizontal scrolling category chips row
class TeaCategoryChips extends StatelessWidget {
  final List<TeaCategoryItem> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const TeaCategoryChips({
    super.key,
    required this.categories,
    this.selectedIndex = 0,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: TeaSpacing.sm),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final item = categories[index];

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: TeaSpacing.md,
                vertical: TeaSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? TeaColors.freshLeaf : TeaColors.white,
                borderRadius: BorderRadius.circular(TeaRadius.round),
                border: Border.all(
                  color: isSelected
                      ? TeaColors.freshLeaf
                      : TeaColors.lightGray,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: TeaColors.freshLeaf.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: 16,
                      color: isSelected ? TeaColors.white : item.iconColor ?? TeaColors.freshLeaf,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    item.label,
                    style: TeaTypography.labelMedium.copyWith(
                      color: isSelected ? TeaColors.white : TeaColors.darkGray,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Data model for a category chip
class TeaCategoryItem {
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const TeaCategoryItem({
    required this.label,
    this.icon,
    this.iconColor,
  });
}
