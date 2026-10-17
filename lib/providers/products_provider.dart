import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/data_failure.dart';
import '../data/product_repository.dart';
import '../models/product.dart';

enum ProductsStatus { loading, success, error }

/// Holds the catalog state.
///
/// Owns the [ProductRepository] stream: subscribes on load, and closes it on
/// dispose. The repository contract says a stream must not close on error —
/// completing is indistinguishable from an empty catalog to the UI — so this
/// class decides when the lifetime ends, and nothing else does.
class ProductsProvider extends ChangeNotifier {
  /// Positional because the field is private, which rules out a named
  /// initializing formal without silencing the lint.
  ProductsProvider(this._repository);

  final ProductRepository _repository;
  StreamSubscription<List<Product>>? _subscription;

  ProductsStatus _status = ProductsStatus.loading;
  List<Product> _products = const [];
  DataFailure? _failure;
  bool _hasLoadedOnce = false;

  ProductsStatus get status => _status;
  List<Product> get products => _products;

  /// The failure, if any. Never null when [status] is
  /// [ProductsStatus.error], and never an unhandled exception.
  DataFailure? get failure => _failure;

  /// User-facing error copy, or null. Screens read this instead of formatting
  /// an exception, so a stack trace cannot reach a product card.
  String? get errorMessage => _failure?.message;

  /// True once the catalog has arrived at least once, so a refresh failure can
  /// keep showing content instead of blanking the screen.
  bool get hasLoadedOnce => _hasLoadedOnce;

  Future<void> load() async {
    _status = ProductsStatus.loading;
    _failure = null;
    notifyListeners();

    await _subscription?.cancel();
    _subscription = _repository.watchProducts().listen(
      _onProducts,
      onError: _onError,
    );
  }

  /// Re-reads the catalog. A failure while content is already on screen keeps
  /// that content and surfaces the failure alongside it, rather than replacing
  /// a working screen with an error.
  Future<void> refresh() async {
    await load();
  }

  void _onProducts(List<Product> products) {
    _products = products;
    _status = ProductsStatus.success;
    _failure = null;
    _hasLoadedOnce = true;
    notifyListeners();
  }

  void _onError(Object error, StackTrace stackTrace) {
    // A failure that permits cached content is a warning on an already-working
    // screen, not a reason to blank it.
    final failure = asDataFailure(error);
    if (failure.keepsCachedContent && _hasLoadedOnce) {
      _failure = failure;
      notifyListeners();
      return;
    }
    _failure = failure;
    _status = _products.isEmpty ? ProductsStatus.error : ProductsStatus.success;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
