import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'buttons.dart';

/// Sticky bottom comparison CTA. Spec: design/02 §2.5 + design/03a §2.2.
///
/// Opens the lowest recorded offer. When the cheapest store's link is a
/// placeholder/unavailable it renders disabled with an honest caption — the
/// current milestone's seed data has no verified links, so the disabled state
/// is intentionally visible until Milestone 5.
class StickyCompareBar extends StatelessWidget {
  const StickyCompareBar({super.key, required this.product, this.onOpenLowest});

  final Product product;
  final VoidCallback? onOpenLowest;

  @override
  Widget build(BuildContext context) {
    final lowest = product.lowestOffer;
    final price = lowest?.price ?? 0;
    final canOpen = lowest != null && lowest.hasUsableLink;

    final String label;
    if (lowest == null) {
      label = 'No recorded offers';
    } else if (product.hasMultipleOffers) {
      label =
          'Open lowest · ${lowest.store.displayName} · ${formatPeso(price)}';
    } else {
      label = 'Open · ${lowest.store.displayName} · ${formatPeso(price)}';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: label,
              icon: lowest != null ? Icons.open_in_new_rounded : null,
              onPressed: canOpen ? onOpenLowest : null,
            ),
            if (!canOpen && lowest != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Listing link unavailable — check back soon',
                  textAlign: TextAlign.center,
                  style: AppTypography.captionMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
