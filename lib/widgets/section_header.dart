import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Section header with optional trailing action and count.
/// Spec: design/02 §2.4 (carousel/grid headers).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final String title;
  final int? count;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTypography.headline2,
              children: [
                TextSpan(text: title),
                if (count != null)
                  TextSpan(
                    text: ' · $count',
                    style: AppTypography.headline2.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingLabel != null)
          TextButton(
            onPressed: onTrailingTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.link,
            ),
            child: Text(trailingLabel!, style: AppTypography.labelSmall),
          ),
      ],
    );
  }
}
