import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/app.dart';
import 'package:pricepulse/screens/product_details_screen.dart';
import 'package:pricepulse/widgets/product_card.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(const PricePulseApp());
    // Advance past the seed repository's simulated 700ms load.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  Future<void> revealGrid(WidgetTester tester) async {
    // Lazy slivers only build items entering the viewport.
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -420),
    );
    await tester.pump();
  }

  testWidgets('app boots into the Home tab after the seed load', (
    tester,
  ) async {
    await pumpHome(tester);

    // Top-of-page components (checked before scrolling).
    expect(find.text('PricePulse'), findsOneWidget);
    expect(find.text('Search products…'), findsOneWidget);
    expect(find.text('Top picks'), findsOneWidget);

    await revealGrid(tester);
    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('tapping a product opens the comparison screen', (tester) async {
    await pumpHome(tester);
    await revealGrid(tester);

    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();

    // Navigated to the comparison screen.
    expect(find.byType(ProductDetailsScreen), findsOneWidget);

    // The hero is 1:1 full-width, so offers live below the fold. Scroll the
    // details screen's own scrollable until the offer section is visible.
    final detailsScrollable = find
        .descendant(
          of: find.byType(ProductDetailsScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Available offers'),
      300,
      scrollable: detailsScrollable,
    );
    await tester.pump();

    expect(find.text('Shopee'), findsWidgets);
    expect(find.text('Lazada'), findsWidgets);
    expect(find.text('TikTok Shop'), findsWidgets);
  });

  testWidgets('bottom navigation switches to the Favorites tab', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('No favorites yet'), findsOneWidget);
  });
}
