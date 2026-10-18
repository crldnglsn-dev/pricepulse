import 'package:flutter/material.dart';

import '../data/favorites_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The chip that says where favorites actually live.
///
/// Single-sourced because two screens show it and they must never disagree:
/// the one thing this app must not do is tell the user a favorite is synced
/// when it is only on this device.
StatusChip favoriteScopeChip(FavoriteScope scope) => StatusChip(
  label: switch (scope) {
    FavoriteScope.local => 'On this device',
    FavoriteScope.cloud => 'Synced',
  },
  variant: switch (scope) {
    FavoriteScope.local => StatusVariant.neutral,
    FavoriteScope.cloud => StatusVariant.success,
  },
);

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
          // Flexible so the label wraps instead of overflowing when the chip
          // is width-constrained — a 200% text scale on a narrow phone.
          Flexible(child: Text(label, style: AppTypography.caption)),
        ],
      ),
    );
  }
}
