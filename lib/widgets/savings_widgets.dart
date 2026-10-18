import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

/// Green "Save ₱X" badge.
/// Spec: design/02 §2.5 `SavingsBadge`.
class SavingsBadge extends StatelessWidget {
  const SavingsBadge({super.key, required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.savings_outlined,
            size: 14,
            color: AppColors.onSuccess,
          ),
          const SizedBox(width: 4),
          // Scaled down rather than truncated. A badge that reads "Save ..."
          // says nothing, and a savings figure that loses its last digits is
          // worse than a smaller one.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Save ${formatPeso(amount)}',
                maxLines: 1,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSuccess,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green "Lowest" pill (check icon + text — never color alone).
/// Spec: design/02 §2.5 `LowestPill`.
class LowestPill extends StatelessWidget {
  const LowestPill({super.key, this.label = 'Lowest'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 14,
            color: AppColors.onSuccess,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSuccess,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
