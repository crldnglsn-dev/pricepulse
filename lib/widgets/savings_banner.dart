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
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 18, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The figure counts up when the screen opens. It lands on the
                // recorded saving, which is the same number it would show
                // without the animation — the count-up is decoration, not a
                // different claim.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: savings),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Text(
                    '${formatPeso(value)} cheaper than the highest offer',
                    style: AppTypography.body.copyWith(
                      color: AppColors.onSuccess,
                      fontWeight: FontWeight.w600,
                    ),
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
