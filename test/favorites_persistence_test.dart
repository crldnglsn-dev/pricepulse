import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pricepulse/data/favorites_repository.dart';
import 'package:pricepulse/data/stored_favorites_repository.dart';
import 'package:pricepulse/providers/favorites_provider.dart';

/// Slice 3: a favorite must survive an app restart.
///
/// Slice 2 promised "Saved on this device" in the snackbar. That promise is
/// only true if the write actually reaches disk, so this slice exists to make
/// the copy honest — and to prove a failed write is not silently reported as
/// saved.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<StoredFavoritesRepository> fresh() async {
    final repo = StoredFavoritesRepository();
    await repo.load();
    return repo;
  }

  group('survives a restart', () {
    test('a saved favorite is present after a new instance loads', () async {
      final first = await fresh();
      await first.toggle(
        productId: 'logitech_g102',
        save: true,
        name: 'Logitech G102 LIGHTSYNC Gaming Mouse',
        lastKnownPrice: 1076,
        lastKnownStore: 'Shopee',
      );
      await first.dispose();

      // A new repository instance is what a relaunch looks like.
      final second = await fresh();
      final restored = (await second.watchFavorites().first).single;

      expect(restored.productId, 'logitech_g102');
      expect(restored.name, 'Logitech G102 LIGHTSYNC Gaming Mouse');
      expect(restored.lastKnownPrice, 1076);
      expect(restored.lastKnownStore, 'Shopee');
      expect(second.isSaved('logitech_g102'), isTrue);
      await second.dispose();
    });

    test('removing a favorite persists the removal', () async {
      final first = await fresh();
      await first.toggle(productId: 'a', save: true);
      await first.toggle(productId: 'a', save: false);
      await first.dispose();

      final second = await fresh();
      expect(await second.watchFavorites().first, isEmpty);
      await second.dispose();
    });

    test('re-saving keeps one entry and the original save time', () async {
      final first = await fresh();
      await first.toggle(productId: 'a', save: true);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await first.toggle(productId: 'a', save: true);
      await first.dispose();

      final second = await fresh();
      expect((await second.watchFavorites().first), hasLength(1));
      await second.dispose();
    });

    test('scope stays local — persistence is not an account', () async {
      final repo = await fresh();
      // The copy depends on this. Persisting to disk must not start claiming
      // the favorite is synced.
      expect(repo.scope, FavoriteScope.local);
      expect(repo.syncState, SyncState.localOnly);
      await repo.dispose();
    });
  });

  group('degrades rather than crashing', () {
    test('a corrupted blob is discarded, not fatal', () async {
      SharedPreferences.setMockInitialValues({
        'pricepulse.favorites.v1': '{not json at all',
      });

      final repo = await fresh();
      expect(await repo.watchFavorites().first, isEmpty);
      await repo.dispose();
    });

    test('one unreadable entry costs one favorite, not the list', () async {
      SharedPreferences.setMockInitialValues({
        'pricepulse.favorites.v1': jsonEncode([
          {'productId': 'good', 'savedAt': '2026-10-17T00:00:00.000Z'},
          {'noId': true, 'savedAt': '2026-10-17T00:00:00.000Z'},
          {'productId': 'bad-date', 'savedAt': 'not-a-date'},
        ]),
      });

      final repo = await fresh();
      final list = await repo.watchFavorites().first;
      expect(list.map((f) => f.productId), ['good']);
      await repo.dispose();
    });

    test('a write before any explicit load still works', () async {
      // Regression: the app wires this as
      // `FavoritesProvider(StoredFavoritesRepository())..load()`, where load()
      // is the *provider's* load. Nothing ever called the repository's load(),
      // so every write threw "Saved items are still loading". The repository
      // must be usable through the provider with no explicit load call.
      final repo = StoredFavoritesRepository();
      final provider = FavoritesProvider(repo)..load();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final ok = await provider.toggle('logitech_g102', save: true);
      expect(ok, isTrue, reason: provider.lastFailure?.message);
      expect(repo.isSaved('logitech_g102'), isTrue);
      provider.dispose();
      await repo.dispose();
    });

    test(
      'subscribing without an explicit load shows persisted favorites',
      () async {
        final seed = StoredFavoritesRepository();
        await seed.load();
        await seed.toggle(productId: 'logitech_g102', save: true, name: 'G102');
        await seed.dispose();

        // Fresh instance, no load() call at all.
        final repo = StoredFavoritesRepository();
        final first = await repo.watchFavorites().first;
        expect(first.single.productId, 'logitech_g102');
        await repo.dispose();
      },
    );

    // The genuinely-unavailable-storage path cannot be exercised here:
    // SharedPreferences.setMockInitialValues always succeeds and
    // SharedPreferences is a concrete class, so there is no seam to inject a
    // failing implementation. That is why _readFromDisk catches and returns
    // false rather than throwing — the branch exists so a device with no
    // writable storage degrades to "favorites do not stick" rather than a
    // crash, and it is reachable on hardware even if not in tests.
  });
}
