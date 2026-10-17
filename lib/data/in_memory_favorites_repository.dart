import 'dart:async';

import 'favorites_repository.dart';

/// Favorites held in memory for this session only.
///
/// **Deliberately not persisted.** Persistence is a separate concern from the
/// contract, and keeping them apart means the storage choice can change without
/// touching the wiring. Until persistence lands, `scope` reports
/// [FavoriteScope.local] and the UI says so — a favorite that vanishes on
/// restart must never be presented as saved-to-an-account.
class InMemoryFavoritesRepository implements FavoritesRepository {
  final _items = <String, Favorite>{};
  final _controller = StreamController<List<Favorite>>.broadcast();

  /// Fixed so ordering is deterministic in tests and demos.
  static final DateTime _clock = DateTime.utc(2026, 10, 17);

  @override
  FavoriteScope get scope => FavoriteScope.local;

  @override
  SyncState get syncState => SyncState.localOnly;

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
    // The contract takes a desired end state rather than a flip, so a repeated
    // `save: true` is a no-op rather than a second save.
    final existing = _items[productId];
    if (save) {
      if (existing != null) {
        // Refresh the cached details but keep the original save time, so
        // re-saving does not jump the item to the top of the list.
        _items[productId] = existing.copyWith(
          lastKnownPrice: lastKnownPrice,
          lastKnownStore: lastKnownStore,
        );
        return;
      }
      _items[productId] = Favorite(
        productId: productId,
        savedAt: _clock,
        name: name,
        imageUrl: imageUrl,
        lastKnownPrice: lastKnownPrice,
        lastKnownStore: lastKnownStore,
      );
    } else if (existing != null) {
      _items.remove(productId);
    }
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_sorted());
  }

  List<Favorite> _sorted() =>
      _items.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  Future<void> dispose() => _controller.close();
}
