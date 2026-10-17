import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/models/offer.dart';
import 'package:pricepulse/models/product.dart';

final _checked = DateTime(2026, 10, 16);

Offer _offer(
  Store store,
  double price, {
  String url = 'https://example.invalid/x',
}) {
  return Offer(
    store: store,
    price: price,
    productUrl: url,
    lastCheckedAt: _checked,
  );
}

void main() {
  group('Product comparison math (defensive)', () {
    test('lowestOffer picks the min valid price', () {
      final product = Product(
        id: 'p1',
        name: 'Test',
        category: 'Test',
        imageUrl: 'assets/products/p1.jpg',
        offers: [
          _offer(Store.shopee, 1299),
          _offer(Store.lazada, 1250),
          _offer(Store.tiktok, 1150),
        ],
      );
      expect(product.lowestOffer?.price, 1150);
      expect(product.lowestOffer?.store, Store.tiktok);
      expect(product.lowestPrice, 1150);
      expect(product.highestPrice, 1299);
      expect(product.savings, 149);
    });

    test('invalid (<=0) prices are excluded from math', () {
      final product = Product(
        id: 'p2',
        name: 'Test',
        category: 'Test',
        imageUrl: 'assets/products/p2.jpg',
        offers: [
          _offer(Store.shopee, 0), // invalid record
          _offer(Store.lazada, 1200),
          _offer(Store.tiktok, 1150),
        ],
      );
      expect(product.hasMultipleOffers, true);
      expect(product.lowestPrice, 1150);
      expect(product.offers.length, 3);
    });

    test('single offer never produces savings', () {
      final product = Product(
        id: 'p3',
        name: 'Test',
        category: 'Test',
        imageUrl: 'assets/products/p3.jpg',
        offers: [_offer(Store.shopee, 899)],
      );
      expect(product.hasMultipleOffers, false);
      expect(product.savings, isNull);
      expect(product.lowestPrice, 899);
    });

    test('comparable:false never produces savings', () {
      final product = Product(
        id: 'p4',
        name: 'Test',
        category: 'Test',
        imageUrl: 'assets/products/p4.jpg',
        comparable: false,
        offers: [
          _offer(Store.shopee, 9985),
          _offer(Store.lazada, 9790),
          _offer(Store.tiktok, 10150),
        ],
      );
      expect(product.hasMultipleOffers, true);
      expect(product.savings, isNull, reason: 'variant mixing must not save');
    });

    test('equal offers produce no savings', () {
      final product = Product(
        id: 'p5',
        name: 'Test',
        category: 'Test',
        imageUrl: 'assets/products/p5.jpg',
        offers: [_offer(Store.shopee, 1200), _offer(Store.lazada, 1200)],
      );
      expect(product.savings, isNull);
    });

    test('sortedOffers orders cheapest first', () {
      final product = Product(
        id: 'p6',
        name: 'Test',
        category: 'Test',
        imageUrl: 'assets/products/p6.jpg',
        offers: [
          _offer(Store.shopee, 1299),
          _offer(Store.lazada, 1150),
          _offer(Store.tiktok, 1250),
        ],
      );
      expect(product.sortedOffers.map((o) => o.store).toList(), [
        Store.lazada,
        Store.tiktok,
        Store.shopee,
      ]);
    });
  });
}
