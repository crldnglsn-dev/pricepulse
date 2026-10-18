import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/data/data_failure.dart';
import 'package:pricepulse/data/product_repository.dart';
import 'package:pricepulse/models/product.dart';
import 'package:pricepulse/screens/product_details_screen.dart';
import 'package:pricepulse/screens/search_screen.dart';
import 'package:pricepulse/theme/app_theme.dart';
import 'package:pricepulse/widgets/category_chips.dart';
import 'package:pricepulse/widgets/empty_state.dart';
import 'package:pricepulse/widgets/product_card.dart';
import 'package:pricepulse/widgets/skeletons.dart';

import 'fixtures.dart';

/// Tests for the search and results screen.
///
/// The screen is a single surface for two entry modes — a typed query and a
/// tapped category — so most of these tests drive one and check that the other
/// keeps working alongside it.
void main() {
  Future<void> pumpSearch(
    WidgetTester tester, {
    String? query,
    String? category,
    ProductRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      // The providers sit above MaterialApp, as they do in the real app, so a
      // pushed route can still reach them.
      harnessProviders(
        MaterialApp(
          theme: buildAppTheme(),
          home: SearchResultsScreen(
            initialQuery: query,
            initialCategory: category,
          ),
        ),
        catalog: true,
        products: repository,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Types into the field and waits out the 300ms debounce.
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }

  group('query mode', () {
    testWidgets('filters the catalog as the user types', (tester) async {
      await pumpSearch(tester);

      expect(find.byType(ProductCard), findsWidgets);

      await type(tester, 'redmi');

      expect(find.textContaining('Redmi Watch'), findsWidgets);
      expect(find.textContaining('Xiaomi TV'), findsNothing);
    });

    testWidgets('reports the honest count', (tester) async {
      await pumpSearch(tester);

      await type(tester, 'redmi');

      expect(find.textContaining('of 5 products'), findsOneWidget);
    });

    testWidgets('the clear button empties the query', (tester) async {
      await pumpSearch(tester);
      await type(tester, 'watch');

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.textContaining('of 5 products'), findsNothing);
      expect(find.text('5 products'), findsOneWidget);
    });

    testWidgets('a query with no matches shows the empty state', (
      tester,
    ) async {
      await pumpSearch(tester);

      await type(tester, 'zzzznothing');

      expect(find.textContaining('No results for'), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
    });

    testWidgets('Clear filters resets the query and the category', (
      tester,
    ) async {
      await pumpSearch(tester, category: 'Audio');

      await type(tester, 'zzzznothing');

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductCard), findsWidgets);
    });

    testWidgets('tapping a result opens the product', (tester) async {
      await pumpSearch(tester);

      await tester.tap(find.byType(ProductCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailsScreen), findsOneWidget);
    });
  });

  group('category mode', () {
    testWidgets('starts filtered to the category it was opened with', (
      tester,
    ) async {
      await pumpSearch(tester, category: 'Audio');

      expect(find.textContaining('· Audio'), findsOneWidget);
      expect(find.textContaining('Orashare'), findsWidgets);
      expect(find.textContaining('Xiaomi TV'), findsNothing);
    });

    testWidgets('a chip switches the category', (tester) async {
      await pumpSearch(tester);

      // The chip row scrolls horizontally. Drag it until the target chip is
      // on screen, then tap it.
      final chipRow = find
          .descendant(
            of: find.byType(CategoryChips),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(chipRow, const Offset(-520, 0));
      await tester.pumpAndSettle();
      // Scoped to the chip row: a product card's category label also reads
      // "Wearables", and the finder would be ambiguous.
      await tester.tap(
        find.descendant(
          of: find.byType(CategoryChips),
          matching: find.text('Wearables'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('· Wearables'), findsOneWidget);
      expect(find.textContaining('Redmi Watch'), findsWidgets);
    });

    testWidgets('a category and a query narrow together', (tester) async {
      await pumpSearch(tester, category: 'Audio');

      await type(tester, 'zzz');

      expect(find.textContaining('No results for'), findsOneWidget);
    });
  });

  group('sorting', () {
    List<String> cardTitles(WidgetTester tester) => tester
        .widgetList<ProductCard>(find.byType(ProductCard))
        .map((c) => c.product.name)
        .toList();

    testWidgets('the sort sheet offers every order', (tester) async {
      await pumpSearch(tester);

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();

      expect(find.text('Featured'), findsOneWidget);
      expect(find.text('Price: low to high'), findsOneWidget);
      expect(find.text('Price: high to low'), findsOneWidget);
      expect(find.text('Name A–Z'), findsOneWidget);
    });

    testWidgets('price low to high puts the cheapest first', (tester) async {
      await pumpSearch(tester);

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: low to high'));
      await tester.pumpAndSettle();

      final titles = cardTitles(tester);
      expect(titles.first, contains('Bench'));
    });

    testWidgets('price high to low puts the dearest first', (tester) async {
      await pumpSearch(tester);

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: high to low'));
      await tester.pumpAndSettle();

      final titles = cardTitles(tester);
      expect(titles.first, contains('Xiaomi TV'));
    });

    testWidgets('name A–Z sorts alphabetically', (tester) async {
      await pumpSearch(tester);

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name A–Z'));
      await tester.pumpAndSettle();

      final titles = cardTitles(tester);
      final sorted = [...titles]..sort();
      expect(titles, sorted);
    });

    testWidgets('the sheet closes when an order is chosen', (tester) async {
      await pumpSearch(tester);

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Featured'));
      await tester.pumpAndSettle();

      expect(find.text('Price: low to high'), findsNothing);
    });
  });

  group('states', () {
    testWidgets('shows a skeleton while the catalog loads', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        harnessProviders(
          MaterialApp(
            theme: buildAppTheme(),
            home: const SearchResultsScreen(),
          ),
          catalog: true,
          products: const SeedProductsRepository(latency: Duration(seconds: 1)),
        ),
      );
      // Hold on the loading frame.
      await tester.pump();

      expect(find.byType(GridSkeleton), findsOneWidget);

      // Let the repository's simulated latency drain before teardown.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('shows an error state with a retry when the read fails', (
      tester,
    ) async {
      await pumpSearch(tester, repository: _FailingRepository());

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.textContaining('Could not read the catalog'), findsOneWidget);
    });
  });
}

/// A repository whose read always fails.
class _FailingRepository implements ProductRepository {
  @override
  Stream<List<Product>> watchProducts() async* {
    yield* Stream<List<Product>>.error(
      const UnreachableFailure('Could not read the catalog.'),
    );
  }
}
