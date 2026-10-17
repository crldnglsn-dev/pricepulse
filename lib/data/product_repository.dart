import 'dart:async';

import 'data_failure.dart';
import '../models/product.dart';
import 'seed_products.dart';

/// Data access boundary for the catalog. UI depends on this interface, never on
/// a backend, so the seed implementation can be replaced by a Firestore stream
/// without touching a screen or a widget.
///
/// ## Why this is a `Stream`, not a `Future`
///
/// Firestore hands you a `Stream`, not a `Future`. Declaring `Future` here would
/// force the Firestore implementation to flatten that stream into a one-shot
/// read, which costs the two behaviours `design/03b` §2.2 specifies: live
/// updates when an admin edits a product, and an offline cache that keeps
/// serving while disconnected.
///
/// The cost is honest and small: a `Stream` has to be closed, and it can emit
/// more than once. [ProductsProvider] owns that lifetime.
///
/// ## Contract for implementers
///
/// - Emit the full catalog on every change. No partial pages — the catalog is
///   small and bounded.
/// - Emit at least once. An empty catalog is a valid first value; silence is
///   not, because the UI would sit on its skeleton forever.
/// - Emit [OfflineFailure] on the stream when a read fails but cached content
///   is still servable. Do **not** close the stream on error — a stream that
///   completes is indistinguishable from an empty catalog to the UI.
/// - Never throw a raw exception. Use [DataFailure]; [asDataFailure] is a
///   safety net, not the intended path.
abstract interface class ProductRepository {
  /// The catalog, updating as it changes. Errors arrive via [DataFailure].
  Stream<List<Product>> watchProducts();
}

/// Bundled seed dataset (`design/04` §2).
///
/// Prices and links are real recorded values read off listings on
/// [SeedProductsRepository.checkedAt]; they go stale, which is exactly what the
/// freshness labels in the UI exist to communicate.
class SeedProductsRepository implements ProductRepository {
  const SeedProductsRepository({this.latency = _defaultLatency});

  /// Simulated read latency so the loading skeletons are demonstrable. Set to
  /// [Duration.zero] in tests. Dropped when Firestore replaces this.
  final Duration latency;

  static const Duration _defaultLatency = Duration(milliseconds: 700);

  /// The date the recorded prices and links were read.
  static final DateTime checkedAt = DateTime(2026, 10, 17);

  @override
  Stream<List<Product>> watchProducts() async* {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    yield products;
  }

  /// The catalog itself, so tests and the parser can assert against it without
  /// going through a stream.
  static List<Product> get products => seedProducts;
}
