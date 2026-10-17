import 'package:flutter/foundation.dart';

import 'offer.dart';

/// A curated product record with its recorded marketplace offers.
/// Catalog: 50 products at Milestone 5; the seed ships 10.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.offers,
    this.description,
    this.featured = false,
    this.comparable = true,
  });

  final String id;
  final String name;
  final String category;

  /// Asset path (e.g. `assets/products/<id>.jpg`) or permitted image URL.
  final String imageUrl;

  /// Offers for this exact product. Absent stores simply have no offer and
  /// the UI renders the designed "no recorded offer" row.
  final List<Offer> offers;

  /// Short honest description. Empty/`null` hides the About section.
  final String? description;

  /// Featured for the Home "Top picks" carousel.
  final bool featured;

  /// `false` when this record mixes variants that must not produce a savings
  /// figure (design: never compare incomparable listings).
  final bool comparable;

  // --- Comparison math (defensive by design) --------------------------------

  List<Offer> get _pricedOffers => offers.where((o) => o.isValidPrice).toList();

  /// Recorded offers with a valid price, cheapest first.
  List<Offer> get sortedOffers {
    final copy = List<Offer>.of(_pricedOffers)
      ..sort((a, b) => a.price.compareTo(b.price));
    return copy;
  }

  /// Lowest recorded price among valid offers, or null.
  Offer? get lowestOffer {
    final priced = _pricedOffers;
    if (priced.isEmpty) return null;
    return priced.reduce((a, b) => a.price <= b.price ? a : b);
  }

  double? get lowestPrice => lowestOffer?.price;

  double? get highestPrice {
    final priced = _pricedOffers;
    if (priced.isEmpty) return null;
    return priced.reduce((a, b) => a.price >= b.price ? a : b).price;
  }

  bool get hasMultipleOffers => _pricedOffers.length > 1;

  /// Potential savings in pesos, computed ONLY when offers are comparable.
  /// Returns null when there is 0/1 offer, prices are equal, or the record is
  /// explicitly marked non-comparable (variant mixing).
  double? get savings {
    if (!comparable || !hasMultipleOffers) return null;
    final min = lowestPrice;
    final max = highestPrice;
    if (min == null || max == null || min <= 0 || max <= min) return null;
    return max - min;
  }
}
