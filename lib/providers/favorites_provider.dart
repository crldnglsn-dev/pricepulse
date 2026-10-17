import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/data_failure.dart';
import '../data/favorites_repository.dart';

enum FavoritesStatus { loading, success, error }

/// Holds saved products.
///
/// Sits between the UI and [FavoritesRepository]. Its job is to make a failed
/// write impossible to render as a success: [toggle] returns whether it
/// worked, and a failure is recorded in [lastFailure] for the caller to show.
/// The UI must never paint a filled heart for a favorite that was not saved.
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider(this._repository);

  final FavoritesRepository _repository;
  StreamSubscription<List<Favorite>>? _subscription;

  FavoritesStatus _status = FavoritesStatus.loading;
  List<Favorite> _favorites = const [];
  DataFailure? _lastFailure;

  FavoritesStatus get status => _status;
  List<Favorite> get favorites => _favorites;

  /// Where these favorites live. The UI surfaces this so the user is never
  /// misled about sync.
  FavoriteScope get scope => _repository.scope;

  /// Whether the backing store is settled, queued or offline.
  SyncState get syncState => _repository.syncState;

  /// The most recent write failure, or null.
  DataFailure? get lastFailure => _lastFailure;

  bool get isEmpty => _favorites.isEmpty;

  Future<void> load() async {
    _status = FavoritesStatus.loading;
    notifyListeners();
    await _subscription?.cancel();
    _subscription = _repository.watchFavorites().listen(
      _onFavorites,
      onError: _onError,
    );
  }

  /// Moves [productId] to the requested end state.
  ///
  /// Returns true when the write succeeded. On failure nothing is cached and
  /// [lastFailure] is set, so a caller can revert its optimistic UI.
  Future<bool> toggle(
    String productId, {
    bool save = true,
    String? name,
    String? imageUrl,
    double? lastKnownPrice,
    String? lastKnownStore,
  }) async {
    _lastFailure = null;
    try {
      await _repository.toggle(
        productId: productId,
        save: save,
        name: name,
        imageUrl: imageUrl,
        lastKnownPrice: lastKnownPrice,
        lastKnownStore: lastKnownStore,
      );
      notifyListeners();
      return true;
    } on Object catch (error) {
      // A failed write must not leave the UI showing the optimistic state.
      _lastFailure = asDataFailure(error);
      notifyListeners();
      return false;
    }
  }

  /// Whether [productId] is currently saved.
  bool isSaved(String productId) =>
      _favorites.any((f) => f.productId == productId);

  void _onFavorites(List<Favorite> favorites) {
    _favorites = favorites;
    _status = FavoritesStatus.success;
    notifyListeners();
  }

  void _onError(Object error, StackTrace stackTrace) {
    _lastFailure = asDataFailure(error);
    _status = FavoritesStatus.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
