import 'package:flutter/material.dart';

import '../models/offer.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'price_text.dart';
import 'savings_widgets.dart';
import 'store_mark.dart';

/// Comparison row for one marketplace offer.
/// Spec: design/02 §2.5 `OfferRow` (+ `lowest` / `disabled` slots).
class OfferRow extends StatelessWidget {
  const OfferRow({
    super.key,
    required this.store,
    required this.price,
    required this.subtitle,
    this.isLowest = false,
    this.isDisabled = false,
    this.note,
    this.onTap,
  });

  final Store store;

  /// Recorded price (ignored when [isDisabled]).
  final double price;
  final String subtitle;

  /// Green rail + green price + "Lowest" pill.
  final bool isLowest;

  /// Missing-offer state — dashed border, no CTA.
  final bool isDisabled;

  /// Optional extra caption slot (e.g. variant disclosure).
  final String? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDisabled
        ? AppColors.border
        : (isLowest
              ? AppColors.onSuccess.withValues(alpha: 0.45)
              : AppColors.borderSubtle);

    final Widget row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (isDisabled) ...[
            _DashedFrame(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StoreMonogram(store: store),
                  const SizedBox(width: AppSpacing.sm),
                  _RowText(store: store, subtitle: subtitle, disabled: true),
                ],
              ),
            ),
          ] else ...[
            Stack(
              children: [
                StoreMonogram(store: store),
                Positioned(
                  top: 0,
                  right: 0,
                  child: StoreDot(store: store, size: 8),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            // The text+trailing group shares the flexible width, and the
            // trailing price/pill pair wraps rather than clipping once the
            // font scale outgrows the row (design QA §3.4).
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _RowText(store: store, subtitle: subtitle),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        PriceText(
                          amount: price,
                          style: isLowest
                              ? AppTypography.price.copyWith(
                                  color: AppColors.onSuccess,
                                )
                              : AppTypography.price,
                        ),
                        if (isLowest)
                          const LowestPill()
                        else
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final interactive = _wrapInteractive(row);
    if (note == null) return interactive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        interactive,
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(note!, style: AppTypography.captionMuted),
        ),
      ],
    );
  }

  Widget _wrapInteractive(Widget child) {
    if (isDisabled || onTap == null) return child;
    return Semantics(
      button: true,
      label: 'Open ${store.displayName} listing',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          splashColor: AppColors.primaryPressed.withValues(alpha: 0.10),
          highlightColor: AppColors.surfaceHover.withValues(alpha: 0.6),
          child: child,
        ),
      ),
    );
  }
}

class _RowText extends StatelessWidget {
  const _RowText({
    required this.store,
    required this.subtitle,
    this.disabled = false,
  });

  final Store store;
  final String subtitle;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final fg = disabled ? AppColors.textMuted : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          store.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.captionMuted,
        ),
      ],
    );
  }
}

/// Dashed border wrapper for the disabled-offer state.
class _DashedFrame extends StatelessWidget {
  const _DashedFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: AppColors.border),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppSpacing.radiusSm),
    );
    final path = Path()..addRRect(rrect);
    for (final metricPath in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metricPath.length) {
        final end = (distance + dash).clamp(0.0, metricPath.length);
        canvas.drawPath(metricPath.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
