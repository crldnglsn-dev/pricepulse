import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data_failure.dart';
import 'favorites_repository.dart';

/// Favorites persisted to device storage.
///
/// Still [FavoriteScope.local] — this survives an app restart, not a reinstall,
/// and is not tied to an account. The UI must keep saying "on this device" until
/// the Firestore implementation exists.
///
/// Reads are tolerant by design: a corrupted or partly-written blob yields an
/// empty list rather than a crash on launch. Losing a favorite is recoverable;
/// an app that will not start is not.
class StoredFavoritesRepository implements FavoritesRepository {
  /// Mutable because it is resolved lazily on first use: [SharedPreferences]
  /// needs an async initialise, which a constructor cannot await. Tests inject
  /// a ready instance.
  StoredFavoritesRepository({SharedPreferences? preferences}) {
    _preferences = preferences;
  }

  static const String _key = 'pricepulse.favorites.v1';

  SharedPreferences? _preferences;
  final _items = <String, Favorite>{};
  final _controller = StreamController<List<Favorite>>.broadcast();
  bool _ready = false;

  @override
  FavoriteScope get scope => FavoriteScope.local;

  @override
  SyncState get syncState => SyncState.localOnly;

  /// Loads persisted favorites. Safe to call more than once.
  Future<void> load() async {
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final entry in decoded) {
            final favorite = _parse(entry);
            if (favorite != null) _items[favorite.productId] = favorite;
          }
        }
      } on FormatException {
        // Unreadable blob: start clean rather than blocking launch.
        await prefs.remove(_key);
      }
    }
    _ready = true;
  }

  @override
  Stream<List<Favorite>> watchFavorites() async* {
    yield _sorted();
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
    final prefs = _awaitPreferences();
    final existing = _items[productId];

    if (save) {
      _items[productId] = existing == null
          ? Favorite(
              productId: productId,
              savedAt: DateTime.now(),
              name: name,
              imageUrl: imageUrl,
              lastKnownPrice: lastKnownPrice,
              lastKnownStore: lastKnownStore,
            )
          : existing.copyWith(
              lastKnownPrice: lastKnownPrice,
              lastKnownStore: lastKnownStore,
            );
    } else if (existing != null) {
      _items.remove(productId);
    }

    final wrote = await prefs.setString(_key, jsonEncode(_encodeAll()));
    if (!wrote) {
      // The in-memory copy is already changed; roll it back so the UI cannot
      // show a favorite the device failed to store.
      if (save && existing == null) {
        _items.remove(productId);
      } else if (!save && existing != null) {
        _items[productId] = existing;
      }
      throw const StorageWriteFailure();
    }
    _emit();
  }

  SharedPreferences _awaitPreferences() {
    final prefs = _preferences;
    if (prefs != null) return prefs;
    throw const StorageUnavailableFailure();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_sorted());
  }

  List<Favorite> _sorted() =>
      _items.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  List<Map<String, Object?>> _encodeAll() => _items.values
      .map(
        (f) => {
          'productId': f.productId,
          'savedAt': f.savedAt.toIso8601String(),
          if (f.name != null) 'name': f.name,
          if (f.imageUrl != null) 'imageUrl': f.imageUrl,
          if (f.lastKnownPrice != null) 'lastKnownPrice': f.lastKnownPrice,
          if (f.lastKnownStore != null) 'lastKnownStore': f.lastKnownStore,
        },
      )
      .toList();

  /// Parses one stored record, returning null for anything unusable. A single
  /// bad entry costs one favorite, not the whole list.
  static Favorite? _parse(Object? entry) {
    if (entry is! Map) return null;
    final id = entry['productId'];
    if (id is! String || id.isEmpty) return null;
    final savedAt = DateTime.tryParse('${entry['savedAt']}');
    if (savedAt == null) return null;
    final price = entry['lastKnownPrice'];
    return Favorite(
      productId: id,
      savedAt: savedAt,
      name: entry['name'] as String?,
      imageUrl: entry['imageUrl'] as String?,
      lastKnownPrice: price is num ? price.toDouble() : null,
      lastKnownStore: entry['lastKnownStore'] as String?,
    );
  }

  Future<void> dispose() => _controller.close();

  bool get isReady => _ready;
}
