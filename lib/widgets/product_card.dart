import 'package:flutter/material.dart';

import '../models/offer.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';
import 'price_text.dart';
import 'product_image.dart';
import 'savings_widgets.dart';
import 'store_mark.dart';

/// Standard surface card.
/// Spec: design/02 §2.4 — a soft shadow before a hard border, pressed wash
/// on tap.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.sm),
    this.color = AppColors.surface,
    this.borderColor = AppColors.borderSubtle,
    this.borderRadius = AppSpacing.radiusMd,
    this.onTap,
    this.semanticLabel,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Whether the card floats on a shadow. Off for surfaces that are already
  /// stacked on something and would double up their depth.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final content = Padding(padding: padding, child: child);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          border: Border.all(color: borderColor),
          boxShadow: elevated
              ? const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    spreadRadius: -6,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
            child: onTap == null
                ? content
                : InkWell(
                    onTap: onTap,
                    splashColor: AppColors.primaryPressed.withValues(
                      alpha: 0.10,
                    ),
                    highlightColor: AppColors.surfaceHover.withValues(
                      alpha: 0.6,
                    ),
                    child: content,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Product card — grid (Home / Search / Favorites). Spec: design/02 §2.4.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.showFavorite = true,
  });

  final Product product;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final lowest = product.lowestOffer;
    final savings = product.savings;

    return AppCard(
      onTap: onTap,
      semanticLabel:
          '${product.name}, starts at '
          '${lowest?.price.toStringAsFixed(0) ?? 'no price'}',
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image flexes to the remaining height so the card can never overflow.
          // The 4:3 ratio is letterboxed inside that flexible area.
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      child: AppProductImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (showFavorite && onFavoriteTap != null)
                      Positioned(
                        top: AppSpacing.xxs,
                        right: AppSpacing.xxs,
                        child: FavoriteButton(
                          isFavorite: isFavorite,
                          onPressed: onFavoriteTap,
                          compact: true,
                          overlay: true,
                          iconSize: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          StoreIndicator(offers: product.offers),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleText,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(product.category, style: AppTypography.captionMuted),
          const SizedBox(height: AppSpacing.xs),
          _PriceRow(lowest: lowest, savings: savings),
        ],
      ),
    );
  }
}

/// Price + savings row — wraps safely at large text scales and narrow widths.
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.lowest, required this.savings});

  final Offer? lowest;
  final double? savings;

  @override
  Widget build(BuildContext context) {
    // Two separate constraints, solved separately.
    //
    // 1. The price cannot always fit. "₱9,013.65" measures 145dp at the card's
    //    16dp price style, but a 320dp two-column card has 114dp of inner
    //    width — no amount of flexing changes that. FittedBox(scaleDown) keeps
    //    every digit visible and shrinks only when it must, which truncation
    //    never did.
    // 2. Price plus badge often does not fit on one line, so the badge wraps.
    //    The image is the Expanded child, so an extra line is absorbed and the
    //    fixed mainAxisExtent still holds.
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: PriceText(
            amount: lowest?.price ?? 0,
            style: AppTypography.price,
          ),
        ),
        if (savings != null) SavingsBadge(amount: savings!),
      ],
    );
  }
}

/// Featured card for the Home "Top picks" carousel. Spec: design/03a §1.2.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lowest = product.lowestOffer;
    final savings = product.savings;
    return SizedBox(
      width: 180,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.sm),
        semanticLabel: '${product.name}, ${lowest?.price.toStringAsFixed(0)}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: AppProductImage(
                    imageUrl: product.imageUrl,
                    borderRadius: AppSpacing.radiusXs,
                  ),
                ),
                Positioned(
                  top: AppSpacing.xxs + 2,
                  left: AppSpacing.xxs + 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs - 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Text(
                      'Top pick',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondaryTint,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            StoreIndicator(offers: product.offers),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleText,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Flexible(
                  child: PriceText(
                    amount: lowest?.price ?? 0,
                    style: AppTypography.price,
                  ),
                ),
                if (savings != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(child: SavingsBadge(amount: savings)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
