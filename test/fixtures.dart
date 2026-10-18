import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pricepulse/data/auth_service.dart';
import 'package:pricepulse/data/favorites_repository.dart';
import 'package:pricepulse/data/guest_auth_service.dart';
import 'package:pricepulse/data/in_memory_favorites_repository.dart';
import 'package:pricepulse/data/product_repository.dart';
import 'package:pricepulse/providers/auth_provider.dart';
import 'package:pricepulse/providers/favorites_provider.dart';
import 'package:pricepulse/models/product.dart';
import 'package:pricepulse/providers/products_provider.dart';

/// Shared fixtures and test harnesses.
///
/// Screens read their state through providers, so any test that pumps a screen
/// directly has to supply them. Centralising that here means a new provider is
/// added in one place rather than in every test file that pumps a screen.
Product testProduct() => SeedProductsRepository.products.first;

/// Wraps [child] in the providers a real screen expects, at the app root.
///
/// Pass [catalog] to also supply the product catalog, which Home and Search
/// require and Product Details does not. Pass [auth] to drive the Account
/// screen; it defaults to the prototype's guest service.
Widget harnessProviders(
  Widget child, {
  bool catalog = false,
  FavoritesRepository? favorites,
  AuthService? auth,
  ProductRepository? products,
}) {
  return MultiProvider(
    providers: [
      if (catalog)
        ChangeNotifierProvider<ProductsProvider>(
          create: (_) => ProductsProvider(
            products ?? SeedProductsRepository(latency: Duration.zero),
          )..load(),
        ),
      ChangeNotifierProvider<FavoritesProvider>(
        create: (_) => FavoritesProvider(favorites ?? _throwaway())..load(),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(auth ?? GuestAuthService())..load(),
      ),
    ],
    child: child,
  );
}

FavoritesRepository _throwaway() => InMemoryFavoritesRepository();
