import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Scale-down press feedback (micro-interaction convention: buttons shrink
/// to .97 while pressed).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.enabled;
    return AnimatedScale(
      scale: _pressed && interactive ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: interactive
            ? () => setState(() => _pressed = false)
            : null,
        onTap: interactive ? widget.onTap : null,
        child: widget.child,
      ),
    );
  }
}

/// Filled primary button (purple). Spec: design/02 §2.1 `PrimaryButton`.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.destructive = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  /// Error-tinted variant for irreversible confirms (spec design/03b §4.2).
  /// Uses `errorContainer`/`error` rather than a solid `error` fill, which
  /// would only reach 2.8:1 against white label text.
  final bool destructive;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final Color fg;
    final Color bg;
    final Color border;
    if (!enabled) {
      fg = AppColors.textMuted;
      bg = AppColors.surfaceElevated;
      border = AppColors.border;
    } else if (destructive) {
      fg = AppColors.error;
      bg = AppColors.errorContainer;
      border = AppColors.error;
    } else {
      fg = AppColors.onPrimary;
      bg = AppColors.primary;
      border = Colors.transparent;
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: PressableScale(
        enabled: enabled,
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: 48,
          width: expand ? double.infinity : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ] else if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill toggle used for filter/sort chips. Spec: design/02 §2.1 `GhostButton`.
class GhostPill extends StatelessWidget {
  const GhostPill({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = isSelected
        ? AppColors.onPrimaryContainer
        : AppColors.textSecondary;
    final bg = isSelected
        ? AppColors.primaryContainer
        : AppColors.surfaceElevated;
    final border = isSelected ? AppColors.primary : AppColors.border;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: AppSpacing.xxs),
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

/// Heart toggle. Spec: design/02 §2.1 `FavoriteButton`.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    this.onPressed,
    this.iconSize = 22,
    this.compact = false,
    this.overlay = false,
  });

  final bool isFavorite;
  final VoidCallback? onPressed;
  final double iconSize;

  /// Smaller visual for card overlays; tap target stays 40dp+.
  final bool compact;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final color = isFavorite ? AppColors.secondary : AppColors.textPrimary;
    final icon = isFavorite ? Icons.favorite : Icons.favorite_border;
    return Semantics(
      button: true,
      label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      child: SizedBox(
        // Card overlays use the 44dp floor; standalone controls get 48dp.
        width: compact ? 44 : 48,
        height: compact ? 44 : 48,
        child: Material(
          color: overlay
              ? Colors.black.withValues(alpha: 0.45)
              : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                icon,
                key: ValueKey<bool>(isFavorite),
                size: iconSize,
                color: overlay && !isFavorite ? AppColors.textPrimary : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
