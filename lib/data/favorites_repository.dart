import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data_failure.dart';

/// A saved product.
///
/// Deliberately not the `Product` itself: a favorite outlives a catalog edit,
/// and re-reading the catalog on every render would make the Favorites tab
/// depend on a network read it has no business making. Storing the id plus
/// whatever was known at save time keeps the list renderable offline and lets
/// the catalog reconcile later.
@immutable
class Favorite {
  const Favorite({
    required this.productId,
    required this.savedAt,
    this.name,
    this.imageUrl,
    this.lastKnownPrice,
    this.lastKnownStore,
  });

  final String productId;

  /// When it was saved. Newest first is the documented order (`design/03b`
  /// §2.2), so the repository is responsible for that ordering, not the UI.
  final DateTime savedAt;

  /// Cached for offline rendering. Null when unknown.
  final String? name;
  final String? imageUrl;
  final double? lastKnownPrice;
  final String? lastKnownStore;

  Favorite copyWith({
    String? name,
    double? lastKnownPrice,
    String? lastKnownStore,
  }) {
    return Favorite(
      productId: productId,
      savedAt: savedAt,
      name: name ?? this.name,
      imageUrl: imageUrl,
      lastKnownPrice: lastKnownPrice ?? this.lastKnownPrice,
      lastKnownStore: lastKnownStore ?? this.lastKnownStore,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Favorite &&
      other.productId == productId &&
      other.savedAt == savedAt &&
      other.name == name &&
      other.lastKnownPrice == lastKnownPrice;

  @override
  int get hashCode => Object.hash(productId, savedAt, name, lastKnownPrice);
}

/// Where a favorite lives. Surfaced in the UI so the user is never misled about
/// sync.
enum FavoriteScope {
  /// This device only. Not an account, not shared, lost on reinstall. This is
  /// the prototype's honest position and the UI says so.
  local,

  /// Tied to a signed-in account and synced across devices.
  cloud,
}

/// Whether writes are in flight or settled. Drives the `StatusChip` in
/// `design/03b` §2.2 — the whole point is that the user can see sync state
/// rather than assume it.
enum SyncState {
  /// Local only; no backend involved.
  localOnly,

  /// Everything written, nothing pending.
  synced,

  /// Writes are queued because there is no connection.
  pendingWrites,

  /// The backend is unreachable and stale data is being shown.
  offline,
}

/// Favorites data access. Implemented locally today, by Firestore later.
///
/// ## Contract for implementers
///
/// - [watchFavorites] emits newest-first, at least once, and must not close on
///   error (see [ProductRepository.watchProducts] for why).
/// - [toggle] is **idempotent per intent**: the caller passes the desired end
///   state, not "flip". A repeated `toggle(save: true)` saves once. A caller
///   that loses a response and retries therefore cannot double-save.
/// - [toggle] throws a [DataFailure] rather than silently failing. The UI shows
///   a snackbar; it must never render a heart as saved when the write failed.
/// - Writes are ordered per product id, not globally, so a slow save on one
///   item cannot reorder or drop another.
abstract interface class FavoritesRepository {
  /// The current scope, so the UI can label what the user is looking at.
  FavoriteScope get scope;

  /// The current sync state, for the status chip.
  SyncState get syncState;

  /// Favorites for the current user, newest first. Emits on every change.
  Stream<List<Favorite>> watchFavorites();

  /// Moves [productId] to the requested end state.
  ///
  /// Idempotent: calling it twice with the same [save] is the same as calling
  /// it once.
  Future<void> toggle({
    required String productId,
    required bool save,
    String? name,
    String? imageUrl,
    double? lastKnownPrice,
    String? lastKnownStore,
  });

  /// Whether [productId] is currently saved.
  ///
  /// Present so callers don't have to filter a list to answer a question the
  /// Favorites tab asks per card.
  bool isSaved(String productId);
}
