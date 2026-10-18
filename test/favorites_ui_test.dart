import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pricepulse/data/in_memory_favorites_repository.dart';
import 'package:pricepulse/data/product_repository.dart';
import 'package:pricepulse/providers/favorites_provider.dart';
import 'package:pricepulse/providers/products_provider.dart' as p;
import 'package:pricepulse/screens/home_screen.dart';
import 'package:pricepulse/screens/product_details_screen.dart';
import 'package:pricepulse/theme/app_theme.dart';
import 'package:pricepulse/widgets/buttons.dart';
import 'package:pricepulse/widgets/product_card.dart';

import 'fixtures.dart';

/// Slice 2: the heart is wired to the real provider.
///
/// The bar this slice has to clear is not "a heart exists" — it already did.
/// It is that a tap survives the round trip and that the user is never told a
/// favorite is synced when it is only on this device.
void main() {
  late InMemoryFavoritesRepository repo;

  setUp(() => repo = InMemoryFavoritesRepository());
  tearDown(() => repo.dispose());

  Future<void> pumpWithFavorites(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FavoritesProvider>(
            create: (_) => FavoritesProvider(repo)..load(),
          ),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Home needs the catalog as well as favorites.
  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<p.ProductsProvider>(
            create: (_) => p.ProductsProvider(
              SeedProductsRepository(latency: Duration.zero),
            )..load(),
          ),
          ChangeNotifierProvider<FavoritesProvider>(
            create: (_) => FavoritesProvider(repo)..load(),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const HomeScreen(onAccountTap: _noop),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Product Details heart', () {
    Future<void> pumpDetails(WidgetTester tester) async {
      await pumpWithFavorites(tester, const _DetailsHarness());
      await tester.pumpAndSettle();
    }

    testWidgets('tapping the heart saves the product', (tester) async {
      await pumpDetails(tester);

      expect(find.byIcon(Icons.favorite), findsNothing);
      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();

      expect(repo.isSaved('logitech_g102'), isTrue);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('tapping again removes it', (tester) async {
      await pumpDetails(tester);

      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();

      expect(repo.isSaved('logitech_g102'), isFalse);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('the saved favorite records what the tab will need to render', (
      tester,
    ) async {
      await pumpDetails(tester);
      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();

      final saved = (await repo.watchFavorites().first).single;
      expect(saved.name, 'Logitech G102 LIGHTSYNC Gaming Mouse');
      expect(saved.imageUrl, 'assets/products/logitech_g102.png');
      expect(saved.lastKnownPrice, 1019);
      expect(saved.lastKnownStore, 'Lazada');
    });

    testWidgets('the confirmation never claims the favorite is synced', (
      tester,
    ) async {
      await pumpDetails(tester);
      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();

      final copy = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(copy, contains('on this device'));
      expect(copy.toLowerCase(), isNot(contains('synced')));
      expect(copy.toLowerCase(), isNot(contains('cloud')));
    });
  });

  group('Home card hearts', () {
    testWidgets('a saved product shows a filled heart in the grid', (
      tester,
    ) async {
      await repo.toggle(productId: 'logitech_g102', save: true);
      await pumpHome(tester);

      expect(find.byType(ProductCard), findsWidgets);
      expect(find.byIcon(Icons.favorite), findsWidgets);
    });

    testWidgets('tapping a card heart saves that product only', (tester) async {
      await pumpHome(tester);
      // The grid is lazy; bring a card fully into view before hitting its heart.
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -420),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(ProductCard).first,
          matching: find.byType(FavoriteButton),
        ),
      );
      await tester.pumpAndSettle();

      final saved = (await repo.watchFavorites().first).single;
      expect(saved.productId, 'logitech_g102');
      expect(
        (await repo.watchFavorites().first).length,
        1,
        reason: 'one tap must not save several products',
      );
    });
  });
}

void _noop() {}

/// A one-product details screen, so the test does not depend on the catalog.
class _DetailsHarness extends StatelessWidget {
  const _DetailsHarness();

  @override
  Widget build(BuildContext context) {
    return ProductDetailsScreen(product: testProduct());
  }
}
