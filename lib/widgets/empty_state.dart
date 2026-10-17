import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';

/// Composable empty state.
/// Spec: design/02 §2.9 `EmptyState`.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.secondaryAction,
    this.bodyMaxLines = 2,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final Widget? secondaryAction;

  /// The design spec caps the body at 2 lines (design/02 §2.9). States whose
  /// body is dynamic diagnostic copy — errors, in practice — raise this so a
  /// message is never silently truncated into uselessness.
  final int bodyMaxLines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headline2,
              ),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body!,
                  maxLines: bodyMaxLines,
                  overflow: bodyMaxLines > 1 ? TextOverflow.ellipsis : null,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.xl),
                action!,
              ],
              if (secondaryAction != null) ...[
                const SizedBox(height: AppSpacing.xs),
                secondaryAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state with retry.
/// Spec: design/02 §2.9 `ErrorState`.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = "We couldn't load products",
    this.message,
    this.onRetry,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      body: message,
      bodyMaxLines: 5,
      action: PrimaryButton(
        label: 'Try again',
        onPressed: onRetry,
        expand: false,
        icon: Icons.refresh_rounded,
      ),
    );
  }
}
