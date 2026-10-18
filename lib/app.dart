import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/stored_favorites_repository.dart';
import 'data/guest_auth_service.dart';
import 'data/product_repository.dart';
import 'navigation/app_shell.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/products_provider.dart';
import 'theme/app_theme.dart';

/// PricePulse root widget.
class PricePulseApp extends StatelessWidget {
  const PricePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ProductsProvider(const SeedProductsRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(StoredFavoritesRepository())..load(),
        ),
        // The auth boundary. Swapping GuestAuthService for a Firebase-backed
        // one is the only change a signed-in build needs here.
        ChangeNotifierProvider(
          create: (_) => AuthProvider(GuestAuthService())..load(),
        ),
      ],
      child: MaterialApp(
        title: 'PricePulse',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AppShell(),
      ),
    );
  }
}
