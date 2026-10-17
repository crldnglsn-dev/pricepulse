import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Category filter chips — single-select horizontal row.
/// Spec: design/02 §2.3.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 44dp — the design QA floor for touch targets (§3.4).
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Owned here so the scroller is inset at both ends while the chips
        // still run full-bleed to the viewport edge.
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final label = categories[index];
          final isSelected = label == selected;
          return _CategoryPill(
            label: label,
            isSelected: isSelected,
            // Only the aggregate "All" chip carries a glyph; concrete
            // categories are text-only so the row stays scannable.
            icon: index == 0 ? Icons.grid_view_rounded : null,
            onTap: () => onSelected(label),
          );
        },
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = isSelected
        ? AppColors.onPrimaryContainer
        : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: isSelected ? AppColors.primaryContainer : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: AppSpacing.xxs + 2),
                ],
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
