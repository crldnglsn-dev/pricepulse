import '../models/product.dart';
import 'seed_products.dart';

/// Data access boundary. The UI depends on this interface, not on Firebase,
/// so Milestone 4 can swap the seed implementation for a Firestore stream
/// without touching any screen or widget.
abstract interface class ProductRepository {
  Future<List<Product>> fetchProducts();
}

/// Bundled seed dataset (design/04 §2). Prices and products are [SEED] sample
/// data; every `productUrl` is a placeholder on `example.invalid` and MUST be
/// replaced with verified store links before the demo (Milestone 5).
class SeedProductsRepository implements ProductRepository {
  const SeedProductsRepository();

  @override
  Future<List<Product>> fetchProducts() async {
    // Simulated initial load so the approved loading skeletons are
    // demonstrable. Removed when the Firestore stream replaces this in
    // Milestone 4 — the UI consumes ProductRepository, so nothing else moves.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return seedProducts;
  }
}
