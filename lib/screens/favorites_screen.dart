import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/favorites_repository.dart';
import '../models/product.dart';
import '../providers/favorites_provider.dart';
import '../providers/products_provider.dart';
import 'product_details_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/buttons.dart';
import '../widgets/empty_state.dart';
import '../widgets/feedback.dart';
import '../widgets/skeletons.dart';
import '../widgets/product_card.dart';
import '../widgets/status_chip.dart';

/// Saved products.
///
/// Spec: design/03b §2.1–§2.3, with one deliberate deviation. The spec's
/// `StatusChip` reads "Synced"; this build has no account, so it reads "On this
/// device" instead. Claiming sync before sync exists is the one thing this app
/// must never do.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, this.onDiscover});

  /// Takes the user to browsing when the list is empty.
  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final catalog = context.watch<ProductsProvider>().products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: StatusChip(label: _chipLabel(favorites.scope)),
            ),
          ),
        ],
      ),
      body: switch (favorites.status) {
        FavoritesStatus.loading => const _FavoritesSkeleton(),
        FavoritesStatus.error => ErrorState(
          message:
              favorites.lastFailure?.message ??
              'Could not read your saved products.',
          onRetry: () => context.read<FavoritesProvider>().load(),
        ),
        FavoritesStatus.success => _FavoritesBody(
          favorites: favorites.favorites,
          catalog: catalog,
          onDiscover: onDiscover,
        ),
      },
    );
  }

  static String _chipLabel(FavoriteScope scope) => switch (scope) {
    FavoriteScope.local => 'On this device',
    FavoriteScope.cloud => 'Synced',
  };
}

class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody({
    required this.favorites,
    required this.catalog,
    this.onDiscover,
  });

  final List<Favorite> favorites;
  final List<Product> catalog;
  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No favorites yet',
        body: 'Tap the heart on any product to keep it here.',
        action: onDiscover == null
            ? null
            : PrimaryButton(
                label: 'Discover products',
                onPressed: onDiscover,
                expand: false,
              ),
      );
    }

    // Resolve against the catalog so a saved item shows its real recorded
    // offers. Anything the catalog no longer carries is reported rather than
    // silently dropped.
    final byId = {for (final p in catalog) p.id: p};
    final resolved = <Product>[
      for (final f in favorites)
        if (byId[f.productId] != null) byId[f.productId]!,
    ];
    final missing = favorites.length - resolved.length;

    final extent =
        290.0 + 90.0 * (MediaQuery.textScalerOf(context).scale(1.0) - 1.0);

    return AppLayout.centerContent(
      CustomScrollView(
        slivers: [
          if (missing > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        missing == 1
                            ? '1 saved product is no longer in the catalog.'
                            : '$missing saved products are no longer in the '
                                  'catalog.',
                        style: AppTypography.captionMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppLayout.gridColumns(context),
                crossAxisSpacing: AppSpacing.gridGap,
                mainAxisSpacing: AppSpacing.gridGap,
                mainAxisExtent: extent,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductCard(
                  product: resolved[index],
                  isFavorite: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ProductDetailsScreen(product: resolved[index]),
                    ),
                  ),
                  onFavoriteTap: () => _unsave(context, resolved[index]),
                ),
                childCount: resolved.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unsave(BuildContext context, Product product) async {
    final favorites = context.read<FavoritesProvider>();
    final ok = await favorites.toggle(product.id, save: false);
    if (!context.mounted) return;
    showFavoriteResult(
      context,
      succeeded: ok,
      saved: false,
      scope: favorites.scope,
      failure: favorites.lastFailure,
    );
  }
}

class _FavoritesSkeleton extends StatelessWidget {
  const _FavoritesSkeleton();

  @override
  Widget build(BuildContext context) => const GridSkeleton();
}
