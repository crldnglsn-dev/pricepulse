import 'package:flutter/foundation.dart';

import '../utils/link_utils.dart';

/// A marketplace store that can carry a recorded offer.
enum Store {
  shopee('Shopee', 'S'),
  lazada('Lazada', 'L'),
  tiktok('TikTok Shop', 'TT');

  const Store(this.displayName, this.monogram);

  /// Human-readable store name — always displayed next to any store color.
  final String displayName;

  /// Short glyph used in the monogram circle.
  final String monogram;
}

/// One recorded price for a product at a marketplace.
///
/// `productUrl` is **not live data**: it starts as a clearly-marked
/// placeholder (see `seed_products.dart`) and must be verified before the
/// demo (design/04 §2). `linkAvailability` drives every "Open" interaction.
@immutable
class Offer {
  const Offer({
    required this.store,
    required this.price,
    required this.productUrl,
    required this.lastCheckedAt,
  });

  final Store store;

  /// Recorded price in Philippine pesos (₱). A value <= 0 is invalid and is
  /// excluded from comparison math.
  final double price;

  /// Marketplace listing URL. May be empty or a placeholder.
  final String productUrl;

  /// When this record was last checked. Shown for freshness; never implied
  /// to be a live price.
  final DateTime lastCheckedAt;

  bool get isValidPrice => price > 0;

  LinkAvailability get linkAvailability => computeLinkAvailability(productUrl);

  /// True only when the link is real (http/https and not a placeholder).
  bool get hasUsableLink => linkAvailability == LinkAvailability.available;
}
