import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/data/categories.dart';
import 'package:pricepulse/data/seed_products.dart';
import 'package:pricepulse/models/offer.dart';

/// Guards the hand-curated catalog against silent drift. Every record here was
/// typed by hand off live marketplace listings, so these are exactly the
/// invariants that break when someone edits carelessly.
void main() {
  final products = seedProducts;

  test('the catalog holds the five curated products', () {
    expect(products.length, 5);
    expect(products.map((p) => p.id).toSet(), {
      'logitech_g102',
      'orashare_hs05',
      'xiaomi_tv_a32',
      'redmi_watch_5',
      'bench_pomade_20g',
    });
  });

  test('product ids are unique', () {
    expect(products.map((p) => p.id).toSet().length, products.length);
  });

  test('every product has at least one valid offer', () {
    for (final p in products) {
      expect(
        p.offers.where((o) => o.isValidPrice),
        isNotEmpty,
        reason: '${p.id} has no offer with a usable price',
      );
    }
  });

  test('every category is reachable from the chip row', () {
    // A category missing from kCategories makes its products unfindable via the
    // category filter — only reachable by typing the name in search.
    for (final p in products) {
      expect(
        kCategories,
        contains(p.category),
        reason: '${p.id} uses "${p.category}", absent from kCategories',
      );
    }
  });

  test('no product lists the same store twice', () {
    for (final p in products) {
      final stores = p.offers.map((o) => o.store).toSet();
      expect(stores.length, p.offers.length, reason: '${p.id} duplicate store');
    }
  });

  test('every offer points at that store and is not a placeholder', () {
    for (final p in products) {
      for (final o in p.offers) {
        final url = o.productUrl;
        expect(url, startsWith('https://'), reason: '${p.id}/${o.store}');
        expect(
          url,
          isNot(contains('example.invalid')),
          reason: '${p.id}/${o.store} is a placeholder, not a real listing',
        );
        // Cheap guard against pasting the wrong store's link.
        expect(
          url,
          anyOf(
            contains('shopee.ph'),
            contains('lazada.com.ph'),
            contains('tiktok.com'),
          ),
          reason: '${p.id}/${o.store} URL is not a known marketplace host',
        );
      }
    }
  });

  test('offers carry the verified freshness stamp', () {
    for (final p in products) {
      for (final o in p.offers) {
        expect(
          o.lastCheckedAt,
          anyOf(verifiedCheckedAt, previouslyCheckedAt),
          reason: p.id,
        );
        expect(
          o.lastCheckedAt.isAfter(verifiedCheckedAt),
          isFalse,
          reason: '${p.id} is stamped in the future',
        );
      }
    }
  });

  test('offers that could not be re-confirmed keep their older stamp', () {
    // These four prices sat inside a flash sale on 2026-10-18, so they were
    // not re-recorded. Bumping them to the newer stamp would claim a check
    // that never happened.
    const unconfirmed = {
      ('orashare_hs05', Store.tiktok),
      ('xiaomi_tv_a32', Store.tiktok),
      ('redmi_watch_5', Store.shopee),
      ('redmi_watch_5', Store.tiktok),
    };

    for (final p in products) {
      for (final o in p.offers) {
        final key = (p.id, o.store);
        if (unconfirmed.contains(key)) {
          expect(
            o.lastCheckedAt,
            previouslyCheckedAt,
            reason: '$key should keep its older stamp',
          );
        } else {
          expect(
            o.lastCheckedAt,
            verifiedCheckedAt,
            reason: '$key was re-read and should carry the newer stamp',
          );
        }
      }
    }
  });

  test('savings are never computed for non-comparable records', () {
    for (final p in products.where((p) => !p.comparable)) {
      expect(
        p.savings,
        isNull,
        reason: '${p.id} is non-comparable but still reports savings',
      );
    }
  });

  test('at least one product is deliberately missing a store', () {
    // Keeps the OfferRow "no recorded offer yet" state exercised in a demo.
    final partial = products.where(
      (p) => p.offers.map((o) => o.store).toSet().length < Store.values.length,
    );
    expect(partial, isNotEmpty);
  });

  test('at least one product is marked non-comparable', () {
    // Keeps the "different variant" honesty state exercised in a demo.
    expect(products.where((p) => !p.comparable), isNotEmpty);
  });

  test('every product uses a bundled asset image', () {
    for (final p in products) {
      expect(
        p.imageUrl,
        startsWith('assets/products/'),
        reason: '${p.id} should use a bundled asset, not a network image',
      );
    }
  });

  test('every referenced image file exists on disk and is a real image', () {
    // AppProductImage silently falls back to MissingImage via errorBuilder, so
    // a missing or corrupt file would never surface as an error. Check the
    // bytes directly instead.
    for (final p in products) {
      final file = File(p.imageUrl);
      expect(
        file.existsSync(),
        isTrue,
        reason: '${p.id} points at ${p.imageUrl}, which is not on disk',
      );
      final bytes = file.readAsBytesSync();
      expect(
        bytes.length,
        greaterThan(1000),
        reason: '${p.imageUrl} too small',
      );
      final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
      final isPng =
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47;
      expect(
        isJpeg || isPng,
        isTrue,
        reason:
            '${p.imageUrl} is neither JPEG nor PNG — extension/content '
            'mismatch will make Image.asset fail',
      );
    }
  });
}
