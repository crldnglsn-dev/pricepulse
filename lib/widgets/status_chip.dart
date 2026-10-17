import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum StatusVariant { neutral, success, warning, error }

/// Small status pill (dot + label). Spec: design/02 §2.6 `StatusChip`.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.variant = StatusVariant.neutral,
  });

  final String label;
  final StatusVariant variant;

  @override
  Widget build(BuildContext context) {
    final Color dot = switch (variant) {
      StatusVariant.neutral => AppColors.textMuted,
      StatusVariant.success => AppColors.success,
      StatusVariant.warning => AppColors.warning,
      StatusVariant.error => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
