import 'package:flutter/material.dart';

import '../models/offer.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Small colored dot — always accompanied by the store *name* elsewhere
/// (color-independence requirement).
class StoreDot extends StatelessWidget {
  const StoreDot({
    super.key,
    required this.store,
    this.size = 8,
    this.present = true,
  });

  final Store store;
  final double size;
  final bool present;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: present ? AppColors.forStore(store) : AppColors.border,
      ),
    );
  }
}

/// Monogram circle used in offer rows (design/02 §2.5).
class StoreMonogram extends StatelessWidget {
  const StoreMonogram({super.key, required this.store, this.size = 36});

  final Store store;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        store.monogram,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.forStore(store),
          fontSize: store == Store.tiktok ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Row of up to 3 dots (present → colored, absent → gray) + "N stores".
/// Spec: design/02 §2.4 (store dots).
class StoreIndicator extends StatelessWidget {
  const StoreIndicator({super.key, required this.offers});

  final List<Offer> offers;

  @override
  Widget build(BuildContext context) {
    final count = offers.where((o) => o.isValidPrice).length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final store in Store.values)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xxs),
            child: StoreDot(
              store: store,
              present: offers.any((o) => o.store == store && o.isValidPrice),
            ),
          ),
        if (count > 0)
          Flexible(
            child: Text(
              count == 1 ? '1 store' : '$count stores',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionMuted,
            ),
          ),
      ],
    );
  }
}
