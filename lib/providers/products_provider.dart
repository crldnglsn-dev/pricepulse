import 'package:flutter/foundation.dart';

import '../data/product_repository.dart';
import '../models/product.dart';

enum ProductsStatus { loading, success, error }

/// Holds the product catalog state. Milestone 2 loads the approved seed data
/// through [ProductRepository]; Milestone 4 swaps the repository for the
/// Firestore stream without changing UI code.
class ProductsProvider extends ChangeNotifier {
  ProductsProvider({ProductRepository? repository})
    : _repository = repository ?? const SeedProductsRepository();

  final ProductRepository _repository;

  ProductsStatus _status = ProductsStatus.loading;
  List<Product> _products = const [];
  String? _errorMessage;

  bool _initialLoadDone = false;

  ProductsStatus get status => _status;
  List<Product> get products => _products;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = ProductsStatus.loading;
    notifyListeners();
    try {
      _products = await _repository.fetchProducts();
      _status = ProductsStatus.success;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }
    _initialLoadDone = true;
    notifyListeners();
  }

  /// Retry after an error, or pull-to-refresh re-fetch.
  Future<void> refresh() async {
    if (!_initialLoadDone) {
      await load();
      return;
    }
    try {
      _products = await _repository.fetchProducts();
      _status = ProductsStatus.success;
      _errorMessage = null;
    } catch (e) {
      // Keep the cached list visible; surface the error only if nothing
      // is shown yet (design: never blank a screen that already has data).
      _status = _products.isEmpty
          ? ProductsStatus.error
          : ProductsStatus.success;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
