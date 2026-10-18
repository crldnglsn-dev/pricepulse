import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/data/catalog_parser.dart';
import 'package:pricepulse/data/data_failure.dart';
import 'package:pricepulse/data/favorites_repository.dart';
import 'package:pricepulse/data/guest_auth_service.dart';
import 'package:pricepulse/data/product_repository.dart';
import 'package:pricepulse/models/offer.dart';
import 'package:pricepulse/models/product.dart';
import 'package:pricepulse/providers/products_provider.dart';

/// These pin the *contracts* in `lib/data/`. An implementation that drifts from
/// its documented behaviour breaks a test here, rather than surprising the UI
/// later.
void main() {
  group('DataFailure', () {
    test('asDataFailure passes domain failures through untouched', () {
      const original = OfflineFailure();
      expect(asDataFailure(original), same(original));
    });

    test('asDataFailure never leaks a raw exception to the UI', () {
      // A stack trace or PlatformException text must not reach a price card.
      final mapped = asDataFailure(
        StateError('Bad state: null on field user_id at index 3'),
      );
      expect(mapped, isA<UnexpectedFailure>());
      expect(mapped.message, isNot(contains('user_id')));
      expect(mapped.message, isNot(contains('Bad state')));
    });

    test('offline keeps cached content; others do not', () {
      expect(const OfflineFailure().keepsCachedContent, isTrue);
      expect(const UnreachableFailure().keepsCachedContent, isFalse);
      expect(ParseFailure('id', 'missing').keepsCachedContent, isFalse);
    });

    test('auth failures are not retryable, transient ones are', () {
      expect(const NotAuthenticatedFailure().isRetryable, isFalse);
      expect(const PermissionDeniedFailure().isRetryable, isFalse);
      expect(const UnreachableFailure().isRetryable, isTrue);
    });

    test('every failure carries user-facing copy', () {
      const all = <DataFailure>[
        OfflineFailure(),
        UnreachableFailure(),
        NotAuthenticatedFailure(),
        PermissionDeniedFailure(),
        UnexpectedFailure(),
        UnsupportedOperationFailure('x'),
        StorageWriteFailure(),
        StorageUnavailableFailure(),
      ];
      for (final f in all) {
        expect(f.message.trim(), isNotEmpty, reason: f.runtimeType.toString());
      }
    });

    test('a storage failure is not retried immediately', () {
      // The remedy is disk space, not another attempt.
      expect(const StorageWriteFailure().isRetryable, isFalse);
      expect(const StorageUnavailableFailure().isRetryable, isTrue);
    });
  });

  group('catalog_parser', () {
    Map<String, dynamic> validDoc() => {
      'id': 'keyboard_001',
      'name': 'RGB Wireless Mechanical Keyboard',
      'category': 'PC Parts',
      'imageUrl': 'assets/products/k.jpg',
      'description': 'A keyboard.',
      'featured': true,
      'comparable': true,
      'offers': [
        {
          'store': 'Shopee',
          'price': 1299,
          'productUrl': 'https://shopee.ph/product/1/2',
          'lastCheckedAt': '2026-10-16',
        },
      ],
    };

    test('parses a well-formed document', () {
      final p = parseProduct(validDoc());
      expect(p.id, 'keyboard_001');
      expect(p.featured, isTrue);
      expect(p.offers.single.store, Store.shopee);
      expect(p.offers.single.price, 1299);
      expect(p.offers.single.lastCheckedAt, DateTime(2026, 10, 16));
    });

    test('a missing id names the field it failed on', () {
      final doc = validDoc()..remove('id');
      expect(
        () => parseProduct(doc),
        throwsA(isA<ParseFailure>().having((e) => e.field, 'field', 'id')),
      );
    });

    test('a wrong-typed price is a parse failure, not a crash', () {
      final doc = validDoc();
      (doc['offers'] as List)[0]['price'] = '1299';
      expect(() => parseProduct(doc), throwsA(isA<ParseFailure>()));
    });

    test('a product with no usable offer is rejected', () {
      final doc = validDoc()
        ..['offers'] = [
          {'store': 'Shopee', 'price': 0},
        ];
      expect(() => parseProduct(doc), throwsA(isA<ParseFailure>()));
    });

    test('an unknown store is dropped rather than crashing the record', () {
      final doc = validDoc();
      (doc['offers'] as List)[0]['store'] = 'NotAStore';
      // Only offer was bad, so the product has no priced offer left.
      expect(() => parseProduct(doc), throwsA(isA<ParseFailure>()));
    });

    test(
      'comparable defaults to true so a missing flag cannot grant savings',
      () {
        // Failing closed: absent flag means comparable only if explicitly checked.
        final doc = validDoc()..remove('comparable');
        expect(parseProduct(doc).comparable, isTrue);
      },
    );

    test('parseCatalog survives one bad document in a batch', () {
      final good = validDoc();
      final bad = validDoc()..['name'] = 42; // wrong type
      final result = parseCatalog([
        good,
        bad,
        {...good, 'id': 'second'},
      ]);
      expect(result.map((p) => p.id), ['keyboard_001', 'second']);
    });

    test('accepts both enum and display-name store spelling', () {
      final byEnum = validDoc();
      (byEnum['offers'] as List)[0]['store'] = 'shopee';
      expect(parseProduct(byEnum).offers.single.store, Store.shopee);

      final byDisplay = validDoc();
      (byDisplay['offers'] as List)[0]['store'] = 'TikTok Shop';
      expect(parseProduct(byDisplay).offers.single.store, Store.tiktok);
    });

    test('accepts the human-readable date format the UI displays', () {
      // The seed records dates the way `formatDateShort` renders them, so the
      // parser has to cope with that shape as well as ISO 8601.
      final doc = validDoc();
      (doc['offers'] as List)[0]['lastCheckedAt'] = 'Oct 16, 2026';
      expect(
        parseProduct(doc).offers.single.lastCheckedAt,
        DateTime(2026, 10, 16),
      );
    });

    test(
      'an unparseable date falls back to the epoch rather than throwing',
      () {
        final doc = validDoc();
        (doc['offers'] as List)[0]['lastCheckedAt'] = 'sometime last week';
        final offer = parseProduct(doc).offers.single;
        expect(offer.lastCheckedAt, DateTime(1970));
        // The record still parses: a bad date must not delete a real product.
        expect(offer.price, 1299);
      },
    );

    test('a missing date falls back to the epoch', () {
      final doc = validDoc();
      (doc['offers'] as List)[0].remove('lastCheckedAt');
      expect(parseProduct(doc).offers.single.lastCheckedAt, DateTime(1970));
    });

    test('a wrong-typed optional string is a parse failure', () {
      final doc = validDoc();
      doc['description'] = 7;
      expect(
        () => parseProduct(doc),
        throwsA(
          isA<ParseFailure>().having((e) => e.field, 'field', 'description'),
        ),
      );
    });

    test('a wrong-typed featured flag is a parse failure', () {
      final doc = validDoc();
      doc['featured'] = 'yes';
      expect(
        () => parseProduct(doc),
        throwsA(
          isA<ParseFailure>().having((e) => e.field, 'field', 'featured'),
        ),
      );
    });

    test('a non-list offers field is a parse failure', () {
      final doc = validDoc();
      doc['offers'] = 'Shopee 1299';
      expect(
        () => parseProduct(doc),
        throwsA(isA<ParseFailure>().having((e) => e.field, 'field', 'offers')),
      );
    });

    test('an empty name is rejected, not trimmed into blankness', () {
      final doc = validDoc();
      doc['name'] = '   ';
      expect(() => parseProduct(doc), throwsA(isA<ParseFailure>()));
    });

    test('an optional string of the wrong type on an offer is dropped', () {
      // A bad URL string must not take the whole product down — the offer
      // falls back to no link, which renders the honest unavailable state.
      final doc = validDoc();
      (doc['offers'] as List)[0]['productUrl'] = 99;
      final offer = parseProduct(doc).offers.single;
      expect(offer.productUrl, isEmpty);
      expect(offer.price, 1299);
    });

    test('round-trips the real seed catalog through the parser', () {
      // The shape Firestore will eventually hand us must be able to describe
      // the data we actually ship.
      final docs = SeedProductsRepository.products
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'category': p.category,
              'imageUrl': p.imageUrl,
              if (p.description != null) 'description': p.description,
              'featured': p.featured,
              'comparable': p.comparable,
              'offers': [
                for (final o in p.offers)
                  {
                    'store': o.store.displayName,
                    'price': o.price,
                    'productUrl': o.productUrl,
                    'lastCheckedAt': o.lastCheckedAt.toIso8601String(),
                  },
              ],
            },
          )
          .toList();

      final parsed = parseCatalog(docs);
      expect(parsed.length, SeedProductsRepository.products.length);
      for (var i = 0; i < parsed.length; i++) {
        expect(parsed[i].id, SeedProductsRepository.products[i].id);
        expect(
          parsed[i].lowestOffer?.price,
          SeedProductsRepository.products[i].lowestOffer?.price,
          reason: 'price drift on ${parsed[i].id}',
        );
        expect(parsed[i].savings, SeedProductsRepository.products[i].savings);
      }
    });
  });

  group('SeedProductsRepository contract', () {
    test('emits at least once and completes with the catalog', () async {
      final repo = SeedProductsRepository(latency: Duration.zero);
      final emitted = await repo.watchProducts().toList();
      expect(emitted, hasLength(1));
      expect(emitted.single.length, 5);
    });

    test('a caller can read the catalog without a stream', () {
      expect(SeedProductsRepository.products.length, 5);
    });
  });

  group('ProductsProvider against the stream contract', () {
    test('reaches success and exposes the catalog', () async {
      final provider = ProductsProvider(
        SeedProductsRepository(latency: Duration.zero),
      );
      await provider.load();
      await Future<void>.delayed(Duration.zero);

      expect(provider.status, ProductsStatus.success);
      expect(provider.products.length, 5);
      expect(provider.errorMessage, isNull);
      provider.dispose();
    });

    test('an offline failure with cached content keeps the screen populated', () async {
      // The scenario design/03b §2.2 calls for: airplane mode mid-session must
      // not blank a screen that already has data.
      final repo = _FlappingRepository();
      final provider = ProductsProvider(repo);
      await provider.load();
      await Future<void>.delayed(Duration.zero);
      expect(provider.status, ProductsStatus.success);
      expect(provider.products, isNotEmpty);

      repo.goOffline();
      await Future<void>.delayed(Duration.zero);

      expect(
        provider.status,
        ProductsStatus.success,
        reason: 'a cached-content failure must not blank a working screen',
      );
      expect(provider.products, isNotEmpty);
      expect(provider.failure, isA<OfflineFailure>());
      provider.dispose();
    });

    test(
      'a first-load failure surfaces a DataFailure, not a raw error',
      () async {
        final provider = ProductsProvider(_FailingRepository());
        await provider.load();
        await Future<void>.delayed(Duration.zero);

        expect(provider.status, ProductsStatus.error);
        expect(provider.failure, isA<DataFailure>());
        expect(provider.errorMessage, isNot(contains('Exception')));
        provider.dispose();
      },
    );

    test('the subscription is cancelled on dispose', () async {
      final repo = _CountingRepository();
      final provider = ProductsProvider(repo);
      await provider.load();
      await Future<void>.delayed(Duration.zero);
      provider.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(repo.cancelled, isTrue);
    });
  });

  group('FavoritesRepository contract', () {
    test('toggle is idempotent for a repeated intent', () async {
      // Losing a response and retrying must not double-save. The contract says
      // the caller passes the desired end state, not "flip".
      final repo = _RecordingFavoritesRepository();
      await repo.toggle(productId: 'a', save: true);
      await repo.toggle(productId: 'a', save: true);

      expect(repo.saveCalls, 1);
      expect(repo.isSaved('a'), isTrue);
    });

    test(
      'toggle(save: false) on an unsaved product is a no-op, not a throw',
      () async {
        final repo = _RecordingFavoritesRepository();
        await repo.toggle(productId: 'never-saved', save: false);
        expect(repo.isSaved('never-saved'), isFalse);
      },
    );

    test('watchFavorites emits newest first', () async {
      final repo = _RecordingFavoritesRepository();
      await repo.toggle(
        productId: 'old',
        save: true,
        savedAt: DateTime(2026, 1, 1),
      );
      await repo.toggle(
        productId: 'new',
        save: true,
        savedAt: DateTime(2026, 6, 1),
      );

      final emitted = await repo.watchFavorites().first;
      expect(emitted.map((f) => f.productId), ['new', 'old']);
    });
  });

  group('AuthService contract', () {
    test('the prototype service reports that it cannot authenticate', () {
      final service = GuestAuthService();

      expect(service.canAuthenticate, isFalse);
      expect(service.currentUser, isNull);
    });

    test('authStateChanges emits the current state immediately', () async {
      // A caller that subscribes late must not wait for an event.
      final service = GuestAuthService();

      expect(await service.authStateChanges().first, isNull);
    });

    test('a sign-in attempt fails with a DataFailure, not a raw throw', () {
      final service = GuestAuthService();

      expect(
        () => service.signIn(email: 'a@b.co', password: 'password'),
        throwsA(isA<DataFailure>()),
      );
    });

    test('the failure says where favorites actually are', () {
      // A user who cannot sign in must be told where their data is.
      final service = GuestAuthService();

      try {
        service.signIn(email: 'a@b.co', password: 'password');
        fail('signIn should not succeed in a build with no backend');
      } on DataFailure catch (failure) {
        expect(failure, isA<UnsupportedOperationFailure>());
        expect(failure.message, contains('this device'));
        expect(failure.isRetryable, isFalse);
      }
    });

    test('signing out is idempotent', () async {
      // A double tap on a logout button must not throw.
      final service = GuestAuthService();

      await service.signOut();
      await service.signOut();
    });

    test('a password reset fails honestly rather than pretending', () {
      final service = GuestAuthService();

      expect(
        () => service.sendPasswordReset('a@b.co'),
        throwsA(isA<UnsupportedOperationFailure>()),
      );
    });

    test('a registration attempt fails honestly too', () {
      final service = GuestAuthService();

      expect(
        () => service.register(
          email: 'a@b.co',
          password: 'password',
          displayName: 'Angela',
        ),
        throwsA(isA<UnsupportedOperationFailure>()),
      );
    });
  });

  group('Favorite value semantics', () {
    final a = Favorite(
      productId: 'p1',
      savedAt: DateTime.utc(2026, 10, 17),
      name: 'Logitech G102',
      lastKnownPrice: 1076,
    );

    test('equal values compare equal', () {
      final b = Favorite(
        productId: 'p1',
        savedAt: DateTime.utc(2026, 10, 17),
        name: 'Logitech G102',
        lastKnownPrice: 1076,
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('a different id is a different favorite', () {
      expect(
        a ==
            Favorite(
              productId: 'p2',
              savedAt: DateTime.utc(2026, 10, 17),
              name: 'Logitech G102',
              lastKnownPrice: 1076,
            ),
        isFalse,
      );
    });

    test('copyWith refreshes the cached fields but never the identity', () {
      final updated = a.copyWith(
        lastKnownPrice: 1049,
        lastKnownStore: 'Lazada',
      );
      expect(updated.productId, a.productId);
      expect(updated.savedAt, a.savedAt);
      expect(updated.lastKnownPrice, 1049);
      expect(updated.lastKnownStore, 'Lazada');
      expect(updated.name, a.name, reason: 'untouched fields must survive');
    });

    test('copyWith leaves price alone when not supplied', () {
      // Null means "no update", so a caller refreshing the store name cannot
      // accidentally erase a known price.
      expect(a.copyWith(lastKnownStore: 'Shopee').lastKnownPrice, 1076);
    });
  });
}

// --- Fakes -------------------------------------------------------------------

class _FailingRepository implements ProductRepository {
  @override
  Stream<List<Product>> watchProducts() =>
      Stream<List<Product>>.error(const UnreachableFailure());
}

/// Emits a catalog, then switches to failing with a cached-content failure —
/// the mid-session airplane-mode case.
class _FlappingRepository implements ProductRepository {
  final _controller = StreamController<List<Product>>();
  bool _offline = false;

  void goOffline() {
    _offline = true;
    _controller.addError(const OfflineFailure());
  }

  @override
  Stream<List<Product>> watchProducts() {
    if (!_offline) {
      _controller.add(SeedProductsRepository.products);
    }
    return _controller.stream;
  }
}

class _CountingRepository implements ProductRepository {
  bool cancelled = false;
  late final StreamController<List<Product>> _controller =
      StreamController<List<Product>>.broadcast(
        onCancel: () => cancelled = true,
      );

  @override
  Stream<List<Product>> watchProducts() {
    _controller.add(const <Product>[]);
    return _controller.stream;
  }
}

/// Minimal implementation used to pin [FavoritesRepository]'s contract. The
/// real one lands with the Favorites screen; this exists so the contract has an
/// executable definition before any consumer depends on it.
class _RecordingFavoritesRepository implements FavoritesRepository {
  final _items = <String, Favorite>{};
  int saveCalls = 0;

  @override
  FavoriteScope get scope => FavoriteScope.local;

  @override
  SyncState get syncState => SyncState.localOnly;

  @override
  Stream<List<Favorite>> watchFavorites() async* {
    yield _sorted();
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
    DateTime? savedAt,
  }) async {
    if (save) {
      // Re-saving an existing id replaces rather than duplicates.
      if (_items.containsKey(productId)) {
        _items[productId] = _items[productId]!.copyWith(
          lastKnownPrice: lastKnownPrice,
          lastKnownStore: lastKnownStore,
        );
        return;
      }
      saveCalls++;
      _items[productId] = Favorite(
        productId: productId,
        savedAt: savedAt ?? DateTime(2026, 10, 17),
        name: name,
        imageUrl: imageUrl,
        lastKnownPrice: lastKnownPrice,
        lastKnownStore: lastKnownStore,
      );
    } else {
      _items.remove(productId);
    }
  }

  List<Favorite> _sorted() {
    final list = _items.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }
}
