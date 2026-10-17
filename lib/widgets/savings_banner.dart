import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

/// Green savings banner for the comparison screen.
/// Spec: design/03a §2.2 `SavingsBanner`.
class SavingsBanner extends StatelessWidget {
  const SavingsBanner({
    super.key,
    required this.savings,
    required this.bestStore,
    required this.bestPrice,
  });

  final double savings;
  final String bestStore;
  final double bestPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 18,
              color: AppColors.onSuccess,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatPeso(savings)} cheaper than the highest offer',
                  style: AppTypography.body.copyWith(
                    color: AppColors.onSuccess,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Buy on $bestStore for ${formatPeso(bestPrice)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.onSuccess.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
