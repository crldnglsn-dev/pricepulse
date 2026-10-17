import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/app.dart';
import 'package:pricepulse/models/offer.dart';
import 'package:pricepulse/models/product.dart';
import 'package:pricepulse/screens/home_screen.dart';
import 'package:pricepulse/screens/product_details_screen.dart';
import 'package:pricepulse/screens/search_screen.dart';
import 'package:pricepulse/theme/app_layout.dart';
import 'package:pricepulse/theme/app_theme.dart';
import 'package:pricepulse/widgets/empty_state.dart';
import 'package:pricepulse/widgets/offer_row.dart';
import 'package:pricepulse/widgets/skeletons.dart';

/// Regression tests for the UI review pass. Each test pins a defect that was
/// actually fixed, so the same breakage cannot quietly return.
void main() {
  Product productWith(List<Offer> offers, {bool comparable = true}) => Product(
    id: 'p1',
    name: 'RGB Wireless Mechanical Keyboard',
    category: 'PC Parts',
    imageUrl: 'assets/products/p1.jpg',
    offers: offers,
    comparable: comparable,
  );

  Offer offer(Store store, double price) => Offer(
    store: store,
    price: price,
    productUrl: 'https://shopee.example/1',
    lastCheckedAt: DateTime(2026, 10, 16),
  );

  Future<void> pumpDetails(
    WidgetTester tester,
    Product product, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: ProductDetailsScreen(product: product),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ProductDetailsScreen resilience', () {
    testWidgets('a product with zero offers does not crash', (tester) async {
      await pumpDetails(tester, productWith(const []));

      expect(find.byType(ProductDetailsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a product with no valid prices does not crash', (
      tester,
    ) async {
      await pumpDetails(
        tester,
        productWith([offer(Store.shopee, 0), offer(Store.lazada, -5)]),
      );

      expect(find.byType(ProductDetailsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a product with no recorded price never shows a fabricated '
        '₱0', (tester) async {
      await pumpDetails(tester, productWith(const []));

      expect(find.textContaining('No price has been recorded'), findsWidgets);
      expect(find.textContaining('₱0'), findsNothing);
    });

    testWidgets('offers are listed cheapest first', (tester) async {
      await pumpDetails(
        tester,
        productWith([
          offer(Store.shopee, 1299),
          offer(Store.lazada, 1250),
          offer(Store.tiktok, 1150),
        ]),
      );

      await tester.scrollUntilVisible(
        find.text('Available offers'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ProductDetailsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      // Cheapest first: 1150 (TikTok) → 1250 (Lazada) → 1299 (Shopee).
      final order = tester
          .widgetList<OfferRow>(find.byType(OfferRow))
          .map((r) => r.store)
          .toList();
      expect(order, [Store.tiktok, Store.lazada, Store.shopee]);
    });

    testWidgets('missing stores render disabled rows after priced ones', (
      tester,
    ) async {
      await pumpDetails(
        tester,
        productWith([offer(Store.lazada, 1250), offer(Store.tiktok, 1150)]),
      );

      await tester.scrollUntilVisible(
        find.text('Available offers'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ProductDetailsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      final rows = tester.widgetList<OfferRow>(find.byType(OfferRow)).toList();
      expect(rows.map((r) => r.isDisabled), [false, false, true]);
      expect(rows.last.store, Store.shopee);
    });

    for (final (label, size) in [
      ('320dp', Size(320, 640)),
      ('768dp', Size(768, 1024)),
      ('1440dp', Size(1440, 900)),
    ]) {
      testWidgets('lays out without overflow at $label', (tester) async {
        await pumpDetails(
          tester,
          productWith([
            offer(Store.shopee, 1299),
            offer(Store.lazada, 1250),
            offer(Store.tiktok, 1150),
          ]),
          size: size,
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives a 200% text scale without overflow', (tester) async {
      await pumpDetails(
        tester,
        productWith([
          offer(Store.shopee, 1299),
          offer(Store.lazada, 1250),
          offer(Store.tiktok, 1150),
        ]),
        size: const Size(320, 640),
        textScale: 2.0,
      );

      await tester.scrollUntilVisible(
        find.text('Available offers'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ProductDetailsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('EmptyState', () {
    testWidgets('does not truncate a long error message', (tester) async {
      const long =
          'Timed out after 5 attempts while reaching the catalog '
          'service. Check your connection and try again.';
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: ErrorState(message: long)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Timed out'), findsOneWidget);
    });
  });

  group('Home and Search', () {
    Future<void> pumpApp(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const PricePulseApp());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    for (final size in [Size(320, 640), Size(768, 1024), Size(1440, 900)]) {
      testWidgets('Home lays out without overflow at ${size.width}dp', (
        tester,
      ) async {
        await pumpApp(tester, size);
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -420),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Home skeleton lays out without overflow at 320dp', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const PricePulseApp()),
      );
      // Hold on the loading frame (before the seed load resolves).
      await tester.pump();

      expect(find.byType(HomeSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Let the repository's simulated load timer drain before teardown.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    Future<int> gridCrossAxisCount(WidgetTester tester) async {
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -420),
      );
      await tester.pumpAndSettle();
      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      return delegate.crossAxisCount;
    }

    testWidgets('Home grid steps to three columns at 600dp+', (tester) async {
      await pumpApp(tester, const Size(1024, 900));

      expect(await gridCrossAxisCount(tester), 3);
    });

    testWidgets('Home grid stays two columns on a phone', (tester) async {
      await pumpApp(tester, const Size(390, 844));

      expect(await gridCrossAxisCount(tester), 2);
    });

    testWidgets('Home content column is capped on a desktop-width window', (
      tester,
    ) async {
      await pumpApp(tester, const Size(1440, 900));

      final width = tester
          .getSize(
            find.descendant(
              of: find.byType(HomeScreen),
              matching: find.byType(CustomScrollView),
            ),
          )
          .width;
      expect(width, lessThanOrEqualTo(AppLayout.maxContentWidth));
    });

    testWidgets('Search results lay out without overflow at 320dp', (
      tester,
    ) async {
      await pumpApp(tester, const Size(320, 640));

      await tester.tap(find.text('Search products…'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchResultsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
