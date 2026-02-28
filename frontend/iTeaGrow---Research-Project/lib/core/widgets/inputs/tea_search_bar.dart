import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

/// Pill-shaped search bar inspired by modern travel-app UI
class TeaSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTap;
  final bool showFilterIcon;
  final bool readOnly;

  const TeaSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onFilterTap,
    this.onTap,
    this.showFilterIcon = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: TeaColors.white,
          borderRadius: BorderRadius.circular(TeaRadius.round),
          boxShadow: [
            BoxShadow(
              color: TeaColors.freshLeaf.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: TeaSpacing.md),
            Icon(
              Icons.search_rounded,
              color: TeaColors.mediumGray,
              size: 22,
            ),
            const SizedBox(width: TeaSpacing.sm),
            Expanded(
              child: readOnly
                  ? Text(
                      hintText,
                      style: TeaTypography.bodyMedium.copyWith(
                        color: TeaColors.mediumGray,
                      ),
                    )
                  : TextField(
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TeaTypography.bodyMedium.copyWith(
                          color: TeaColors.mediumGray,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: TeaTypography.bodyMedium,
                    ),
            ),
            if (showFilterIcon) ...[
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: TeaSpacing.xs),
                decoration: BoxDecoration(
                  color: TeaColors.freshLeaf,
                  borderRadius: BorderRadius.circular(TeaRadius.round),
                ),
                child: IconButton(
                  onPressed: onFilterTap,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  color: TeaColors.white,
                  padding: EdgeInsets.zero,
                ),
              ),
            ] else
              const SizedBox(width: TeaSpacing.md),
          ],
        ),
      ),
    );
  }
}
