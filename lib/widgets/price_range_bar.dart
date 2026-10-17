import 'package:flutter/material.dart';

import '../models/offer.dart';
import '../theme/app_colors.dart';

/// Visual spread of recorded prices — marker per store on a min→max track.
/// Purely informational (recorded prices, not live). Spec: design/02 §2.5.
class PriceRangeBar extends StatelessWidget {
  const PriceRangeBar({super.key, required this.offers});

  final List<Offer> offers;

  @override
  Widget build(BuildContext context) {
    final priced = offers.where((o) => o.price > 0).toList();
    if (priced.isEmpty) return const SizedBox.shrink();

    final prices = priced.map((o) => o.price).toList();
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);

    Widget bar;
    if (max <= min) {
      // Equal prices: single centered marker.
      bar = Center(
        child: _Marker(
          store: priced.first.store,
          color: AppColors.success,
          isLowest: true,
        ),
      );
    } else {
      bar = LayoutBuilder(
        builder: (context, constraints) {
          final span = constraints.maxWidth - 8; // leave marker space at ends
          return SizedBox(
            height: 14,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                for (final offer in priced)
                  Positioned(
                    left: 4 + ((offer.price - min) / (max - min)) * span,
                    top: 3,
                    child: _Marker(
                      store: offer.store,
                      color: AppColors.forStore(offer.store),
                      isLowest: offer.price == min,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return Semantics(
      label:
          'Price range from '
          '${min.toStringAsFixed(0)} to ${max.toStringAsFixed(0)} pesos',
      child: bar,
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.store,
    required this.color,
    required this.isLowest,
  });

  final Store store;
  final Color color;
  final bool isLowest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isLowest
            ? Border.all(color: AppColors.success, width: 1.5)
            : null,
        // The lowest store additionally gets a green halo.
        boxShadow: isLowest
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.35),
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }
}
