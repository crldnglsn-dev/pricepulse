import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/data/in_memory_favorites_repository.dart';
import 'package:pricepulse/data/product_repository.dart';
import 'package:pricepulse/screens/favorites_screen.dart';
import 'package:pricepulse/widgets/product_card.dart';

import 'fixtures.dart';

/// Slice 4: the Favorites tab.
///
/// The bar is not "the tab renders". It is that the tab no longer claims
/// favorites are unimplemented, and never claims a local favorite is synced.
void _noop() {}

void main() {
  late InMemoryFavoritesRepository repo;

  setUp(() => repo = InMemoryFavoritesRepository());
  tearDown(() => repo.dispose());

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.pumpWidget(
      harnessProviders(
        MaterialApp(home: FavoritesScreen(onDiscover: _noop)),
        catalog: true,
        favorites: repo,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty state invites the user to discover products', (
    tester,
  ) async {
    await pumpTab(tester);

    expect(find.text('No favorites yet'), findsOneWidget);
    expect(find.text('Discover products'), findsOneWidget);
  });

  testWidgets('the empty state no longer claims favorites are unimplemented', (
    tester,
  ) async {
    await pumpTab(tester);

    // Slice 4 replaced this copy. If it ever comes back, a slice was reverted.
    final copy = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(copy.toLowerCase(), isNot(contains('later milestone')));
    expect(copy.toLowerCase(), isNot(contains('cloud-synced')));
  });

  testWidgets('the chip says where favorites live, and never "Synced"', (
    tester,
  ) async {
    await pumpTab(tester);

    expect(find.text('On this device'), findsOneWidget);
    final copy = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(copy, isNot(contains('Synced')));
  });

  testWidgets('a saved product appears as a card', (tester) async {
    await repo.toggle(productId: 'logitech_g102', save: true);
    await pumpTab(tester);

    expect(find.byType(ProductCard), findsOneWidget);
    expect(find.text('No favorites yet'), findsNothing);
  });

  testWidgets('saved cards show a filled heart', (tester) async {
    await repo.toggle(productId: 'logitech_g102', save: true);
    await pumpTab(tester);

    expect(find.byIcon(Icons.favorite), findsWidgets);
  });

  testWidgets('unsaving from the tab removes the card', (tester) async {
    await repo.toggle(productId: 'logitech_g102', save: true);
    await pumpTab(tester);
    expect(find.byType(ProductCard), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(ProductCard).first,
        matching: find.byIcon(Icons.favorite),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.isSaved('logitech_g102'), isFalse);
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('a saved product missing from the catalog is reported, not '
      'silently dropped', (tester) async {
    await repo.toggle(productId: 'deleted_product', save: true);
    await pumpTab(tester);

    expect(find.byType(ProductCard), findsNothing);
    expect(
      find.textContaining('no longer in the catalog'),
      findsOneWidget,
      reason: 'absence is information, not something to hide',
    );
  });

  testWidgets('a saved product resolves against the real catalog', (
    tester,
  ) async {
    await repo.toggle(productId: 'redmi_watch_5', save: true);
    await pumpTab(tester);

    expect(
      tester
          .widgetList<ProductCard>(find.byType(ProductCard))
          .single
          .product
          .id,
      'redmi_watch_5',
    );
    // The id resolved to a real product rather than a cached stub.
    expect(
      SeedProductsRepository.products
          .map((p) => p.id)
          .contains('redmi_watch_5'),
      isTrue,
    );
  });
}
