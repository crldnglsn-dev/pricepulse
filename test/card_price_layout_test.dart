import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/data/product_repository.dart';
import 'package:pricepulse/models/product.dart';
import 'package:pricepulse/theme/app_theme.dart';
import 'package:pricepulse/utils/formatters.dart';
import 'package:pricepulse/widgets/product_card.dart';

/// Regression guard for a bug found by running on a real device, not by a
/// test: a five-digit peso amount rendered as "9,01..." on the product card.
///
/// Making both the price and the savings badge `Flexible` stopped the overflow
/// but let the price be the thing that shrank. The price is the headline
/// number; the badge is the one that should give way.
///
/// The assertion compares the laid-out width of the price text against the
/// width it needs. A narrower layout means Flutter ellipsized it.
void main() {
  /// The widest price in the shipped catalog — the one that broke.
  Product widestProduct() => SeedProductsRepository.products.reduce(
    (a, b) => (a.lowestPrice ?? 0) >= (b.lowestPrice ?? 0) ? a : b,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    Product product,
    double width,
  ) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Center(
            // The real grid width for a 2-column layout at this viewport.
            child: SizedBox(
              width: (width - 32 - 12) / 2,
              child: ProductCard(product: product, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool wasEllipsized(WidgetTester tester, String text) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
    final needed = paragraph.computeMaxIntrinsicWidth(paragraph.size.width);
    return paragraph.size.width < needed - 0.5;
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('the price is not ellipsized at ${width}dp', (tester) async {
      final product = widestProduct();
      await pumpCard(tester, product, width);

      final price = formatPeso(product.lowestPrice ?? 0);
      expect(find.text(price), findsOneWidget);
      expect(
        wasEllipsized(tester, price),
        isFalse,
        reason: '"$price" is the headline number and must never be cut off',
      );
    });
  }

  testWidgets('every catalog price renders in full on a card', (tester) async {
    for (final product in SeedProductsRepository.products) {
      await pumpCard(tester, product, 320);
      final price = formatPeso(product.lowestPrice ?? 0);
      expect(
        wasEllipsized(tester, price),
        isFalse,
        reason: '${product.id} truncated "$price"',
      );
    }
  });

  testWidgets('the card still does not overflow when the badge is long', (
    tester,
  ) async {
    await pumpCard(tester, widestProduct(), 320);
    // The badge absorbs the squeeze, so the row must not overflow.
    expect(tester.takeException(), isNull);
  });

  testWidgets('the savings badge is the thing that gives way', (tester) async {
    // Documents the intended trade-off: the price wins, the badge truncates.
    final product = SeedProductsRepository.products.firstWhere(
      (p) => p.savings != null && (p.lowestPrice ?? 0) >= 9000,
    );
    await pumpCard(tester, product, 320);
    final price = formatPeso(product.lowestPrice ?? 0);
    expect(wasEllipsized(tester, price), isFalse);
  });
}
