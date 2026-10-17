import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/data/data_failure.dart';
import 'package:pricepulse/data/favorites_repository.dart';
import 'package:pricepulse/data/in_memory_favorites_repository.dart';
import 'package:pricepulse/providers/favorites_provider.dart';

/// Slice 1: repository + provider, no UI. The contract is pinned by
/// `data_contract_test.dart`; this checks the in-memory implementation actually
/// honours it, and that the provider cannot render a failed write as success.
void main() {
  late InMemoryFavoritesRepository repo;

  setUp(() => repo = InMemoryFavoritesRepository());
  tearDown(() => repo.dispose());

  group('InMemoryFavoritesRepository', () {
    test('starts empty', () async {
      final emitted = await repo.watchFavorites().first;
      expect(emitted, isEmpty);
      expect(repo.isSaved('anything'), isFalse);
    });

    test('a write is reflected in the stream', () async {
      final emissions = <List<Favorite>>[];
      final sub = repo.watchFavorites().listen(emissions.add);

      await repo.toggle(productId: 'logitech_g102', save: true, name: 'G102');
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.single.productId, 'logitech_g102');
      expect(repo.isSaved('logitech_g102'), isTrue);
      await sub.cancel();
    });

    test('scope and sync are reported honestly', () {
      // A prototype favorite must never claim to be synced to an account.
      expect(repo.scope, FavoriteScope.local);
      expect(repo.syncState, SyncState.localOnly);
    });

    test(
      'saving twice keeps one entry and keeps the original save time',
      () async {
        await repo.toggle(productId: 'a', save: true, name: 'First');
        await repo.toggle(
          productId: 'a',
          save: true,
          lastKnownPrice: 999,
          lastKnownStore: 'Lazada',
        );
        final list = await repo.watchFavorites().first;
        expect(list, hasLength(1));
        expect(list.single.lastKnownPrice, 999);
        expect(list.single.lastKnownStore, 'Lazada');
      },
    );

    test('unsaving an absent product does not throw', () async {
      await repo.toggle(productId: 'never', save: false);
      expect(await repo.watchFavorites().first, isEmpty);
    });

    test('a favorite stores enough to render without the catalog', () async {
      // Favorites outlive a catalog edit, so the cached fields are what the
      // Favorites tab can draw when no catalog read is available.
      await repo.toggle(
        productId: 'logitech_g102',
        save: true,
        name: 'Logitech G102 LIGHTSYNC Gaming Mouse',
        imageUrl: 'assets/products/logitech_g102.png',
        lastKnownPrice: 1076,
        lastKnownStore: 'Shopee',
      );
      final saved = (await repo.watchFavorites().first).single;
      expect(saved.name, 'Logitech G102 LIGHTSYNC Gaming Mouse');
      expect(saved.imageUrl, 'assets/products/logitech_g102.png');
      expect(saved.lastKnownPrice, 1076);
      expect(saved.lastKnownStore, 'Shopee');
    });
  });

  group('FavoritesProvider', () {
    Future<FavoritesProvider> loaded() async {
      final p = FavoritesProvider(repo)..load();
      await Future<void>.delayed(Duration.zero);
      return p;
    }

    test('reaches success and reports empty', () async {
      final p = await loaded();
      expect(p.status, FavoritesStatus.success);
      expect(p.isEmpty, isTrue);
      expect(p.lastFailure, isNull);
      p.dispose();
    });

    test('a successful toggle is reflected and reported as success', () async {
      final p = await loaded();
      final ok = await p.toggle(
        'logitech_g102',
        save: true,
        name: 'Logitech G102 LIGHTSYNC Gaming Mouse',
        lastKnownPrice: 1076,
        lastKnownStore: 'Shopee',
      );
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(p.isSaved('logitech_g102'), isTrue);
      expect(p.favorites.single.lastKnownPrice, 1076);
      p.dispose();
    });

    test('a failed write returns false and leaves nothing cached', () async {
      final p = FavoritesProvider(_ThrowingFavoritesRepository());
      await p.load();
      await Future<void>.delayed(Duration.zero);

      final ok = await p.toggle('logitech_g102', save: true);

      expect(ok, isFalse, reason: 'a failed write must not read as success');
      expect(p.isSaved('logitech_g102'), isFalse);
      expect(p.lastFailure, isA<DataFailure>());
      expect(p.lastFailure!.message, isNotEmpty);
      p.dispose();
    });

    test('the next successful write clears the previous failure', () async {
      final flaky = _ThrowingFavoritesRepository();
      final p = FavoritesProvider(flaky);
      await p.load();
      await Future<void>.delayed(Duration.zero);

      await p.toggle('a', save: true);
      expect(p.lastFailure, isNotNull);

      flaky.shouldFail = false;
      final ok = await p.toggle('a', save: true);
      expect(ok, isTrue);
      expect(p.lastFailure, isNull);
      p.dispose();
    });

    test(
      'exposes the scope so the UI can label the storage honestly',
      () async {
        final p = await loaded();
        expect(p.scope, FavoriteScope.local);
        expect(p.syncState, SyncState.localOnly);
        p.dispose();
      },
    );
  });
}

/// A repository whose writes fail on demand, to prove the provider's error path.
class _ThrowingFavoritesRepository implements FavoritesRepository {
  final _controller = StreamController<List<Favorite>>.broadcast();
  final _items = <String, Favorite>{};
  bool shouldFail = true;

  @override
  FavoriteScope get scope => FavoriteScope.local;

  @override
  SyncState get syncState => SyncState.localOnly;

  @override
  Stream<List<Favorite>> watchFavorites() async* {
    yield _items.values.toList();
    yield* _controller.stream;
  }

  @override
  bool isSaved(String productId) => _items.containsKey(productId);

  @override
  Future<void> toggle({
    required String productId,
    required bool save,
    String? name,
    String? imageUrl,
    double? lastKnownPrice,
    String? lastKnownStore,
  }) async {
    if (shouldFail) throw const UnreachableFailure();
    if (save) {
      _items[productId] = Favorite(
        productId: productId,
        savedAt: DateTime.utc(2026, 10, 17),
        name: name,
        lastKnownPrice: lastKnownPrice,
        lastKnownStore: lastKnownStore,
      );
    } else {
      _items.remove(productId);
    }
    _controller.add(_items.values.toList());
  }
}
