import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/offer.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import '../utils/link_utils.dart';
import '../widgets/buttons.dart';
import '../widgets/feedback.dart';
import '../widgets/offer_row.dart';
import '../widgets/price_range_bar.dart';
import '../widgets/price_text.dart';
import '../widgets/product_image.dart';
import '../widgets/savings_banner.dart';
import '../widgets/savings_widgets.dart';
import '../widgets/status_chip.dart';
import '../widgets/sticky_compare_bar.dart';

/// Product Details / Price Comparison — the hero screen.
/// Spec: design/03a §2.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _favorite = false;

  Product get product => widget.product;

  void _toggleFavorite() {
    // Local-only preview toggle while auth/favorites (Milestone 8) is pending.
    setState(() => _favorite = !_favorite);
    showAppSnackbar(
      context,
      _favorite
          ? 'Added to favorites — cloud sync arrives with accounts.'
          : 'Removed from favorites.',
      kind: _favorite ? SnackbarKind.info : SnackbarKind.info,
    );
  }

  Future<void> _openLink(Offer offer) async {
    final availability = offer.linkAvailability;
    if (availability != LinkAvailability.available) {
      final hasUrl = offer.productUrl.trim().isNotEmpty;
      await showLinkUnavailableDialog(
        context,
        url: hasUrl ? offer.productUrl : null,
      );
      return;
    }

    // Handing off leaves the app, so confirm first. The dialog also restates
    // the *recorded* price and its date — by the time the user taps, the live
    // store price may have moved, and that gap is the whole honesty contract.
    final confirmed = await showAppDialog(
      context,
      title: 'Open ${offer.store.displayName}?',
      message:
          'This leaves PricePulse and opens the listing in the '
          '${offer.store.displayName} app or your browser.\n\n'
          'Recorded price ${formatPeso(offer.price)} on '
          '${formatDateShort(offer.lastCheckedAt)} — the live price may differ.',
      confirmLabel: 'Open listing',
    );
    if (confirmed != true || !mounted) return;

    try {
      final uri = Uri.parse(offer.productUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!opened) {
        await showLinkUnavailableDialog(context, url: offer.productUrl);
        return;
      }
      showAppSnackbar(
        context,
        'Opening ${offer.store.displayName}…',
        kind: SnackbarKind.info,
      );
    } catch (_) {
      if (!mounted) return;
      await showLinkUnavailableDialog(context, url: offer.productUrl);
    }
  }

  void _openLowest() {
    final lowest = product.lowestOffer;
    if (lowest != null) _openLink(lowest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          FavoriteButton(isFavorite: _favorite, onPressed: _toggleFavorite),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      bottomNavigationBar: (product.offers.where((o) => o.isValidPrice).isEmpty)
          ? null
          : StickyCompareBar(product: product, onOpenLowest: _openLowest),
      body: _DetailsBody(product: product, onOpenLink: _openLink),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final count = product.offers.where((o) => o.isValidPrice).length;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: AppColors.surfaceElevated,
            child: AppProductImage(
              imageUrl: product.imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.md,
            child: StatusChip(
              label: count == 1 ? '1 price recorded' : '$count prices recorded',
            ),
          ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.category.toUpperCase(), style: AppTypography.overline),
        const SizedBox(height: AppSpacing.xxs),
        Text(product.name, style: AppTypography.headline1),
      ],
    );
  }
}

class _PriceSummaryCard extends StatelessWidget {
  const _PriceSummaryCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final lowest = product.lowestOffer;
    final highest = product.highestPrice;
    final multi = product.hasMultipleOffers;

    // No valid offer: never render a fabricated ₱0 as if it were a price.
    if (lowest == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.remove_shopping_cart_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'No price has been recorded for this product yet.',
                style: AppTypography.bodySecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap (not Row+Spacer) so the caption pair reflows instead of
          // overflowing at large text scales (design QA §3.4).
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'from ${formatPeso(lowest.price)}',
                style: AppTypography.bodySecondary,
              ),
              if (highest != null)
                Text(
                  'Range ${formatPeso(lowest.price)} – '
                  '${formatPeso(highest)}',
                  style: AppTypography.captionMuted,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (multi)
            PriceRangeBar(offers: product.offers)
          else
            Text('1 recorded offer', style: AppTypography.captionMuted),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PriceText(
                amount: lowest.price,
                style: AppTypography.priceLarge.copyWith(
                  color: multi ? AppColors.success : AppColors.textPrimary,
                ),
              ),
              if (multi)
                const LowestPill(label: 'Lowest recorded price')
              else
                Text('Only recorded offer', style: AppTypography.captionMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _FreshnessFooter extends StatelessWidget {
  const _FreshnessFooter({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final latest = product.offers
        .map((o) => o.lastCheckedAt)
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    final freshness = latest == null
        ? 'No price has been recorded for this product yet.'
        : 'Prices are recorded manually for this prototype. '
              'Last checked ${formatDateShort(latest)} — live store prices '
              'may differ.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(freshness, style: AppTypography.captionMuted)),
      ],
    );
  }
}

class _AboutSection extends StatefulWidget {
  const _AboutSection({required this.description});

  final String description;

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this product', style: AppTypography.headline2),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.description,
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: AppTypography.bodySecondary,
        ),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.link,
          ),
          child: Text(
            _expanded ? 'Less' : 'More',
            style: AppTypography.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.product, required this.onOpenLink});

  final Product product;
  final ValueChanged<Offer> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return AppLayout.centerContent(
      CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Hero(product: product)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _TitleBlock(product: product),
                if (product.savings != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  SavingsBanner(
                    savings: product.savings!,
                    bestStore: product.lowestOffer!.store.displayName,
                    bestPrice: product.lowestOffer!.price,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _PriceSummaryCard(product: product),
                const SizedBox(height: AppSpacing.xl),
                Text('Available offers', style: AppTypography.headline2),
                if (!product.comparable) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Different variant — shown for reference only',
                    style: AppTypography.captionMuted,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                for (final row in _offerRows()) ...[
                  row,
                  const SizedBox(height: AppSpacing.xs),
                ],
                const SizedBox(height: AppSpacing.xl),
                _FreshnessFooter(product: product),
                if (product.description != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _AboutSection(description: product.description!),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Offers cheapest-first (fixed rule, design/03a §2.2), followed by the
  /// stores that have no recorded offer in their canonical order.
  List<Widget> _offerRows() {
    final rows = <Widget>[];
    final lowest = product.lowestOffer;
    for (final offer in product.sortedOffers) {
      rows.add(
        OfferRow(
          store: offer.store,
          price: offer.price,
          subtitle: 'Recorded ${formatDateShort(offer.lastCheckedAt)}',
          isLowest: identical(offer, lowest),
          onTap: () => onOpenLink(offer),
        ),
      );
    }
    for (final store in Store.values) {
      if (product.offers.any((o) => o.store == store)) continue;
      rows.add(
        OfferRow(
          store: store,
          price: 0,
          subtitle: 'No recorded offer yet',
          isDisabled: true,
        ),
      );
    }
    return rows;
  }
}
