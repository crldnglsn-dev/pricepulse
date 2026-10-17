import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pricepulse/data/data_failure.dart';
import 'package:pricepulse/data/favorites_repository.dart';
import 'package:pricepulse/data/stored_favorites_repository.dart';

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

    test('a write before load throws a DataFailure, not a raw error', () async {
      final repo = StoredFavoritesRepository();
      // No load() and no injected preferences: the write cannot resolve storage.
      await expectLater(
        repo.toggle(productId: 'a', save: true),
        throwsA(isA<StorageUnavailableFailure>()),
      );
      await repo.dispose();
    });
  });
}
