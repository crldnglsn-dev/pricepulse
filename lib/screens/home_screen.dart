import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/category_chips.dart';
import '../widgets/empty_state.dart';
import '../widgets/feedback.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/skeletons.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';

/// Home / Discover — the first hero screen.
/// Spec: design/03a §1.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onAccountTap});

  final VoidCallback onAccountTap;

  void _openProduct(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(product: product),
      ),
    );
  }

  void _openSearch(BuildContext context, {String? category}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchResultsScreen(initialCategory: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsProvider>();
    return Scaffold(
      appBar: _HomeAppBar(onAccountTap: onAccountTap),
      body: switch (provider.status) {
        ProductsStatus.loading => const HomeSkeleton(),
        ProductsStatus.error => ErrorState(
          message: provider.errorMessage,
          onRetry: provider.refresh,
        ),
        ProductsStatus.success =>
          provider.products.isEmpty
              ? const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'No products yet',
                  body: 'The catalog is being set up.',
                )
              : _HomeContent(
                  products: provider.products,
                  onProductTap: (p) => _openProduct(context, p),
                  onSearchTap: () => _openSearch(context),
                  onCategoryTap: (c) => _openSearch(context, category: c),
                  onRefresh: provider.refresh,
                ),
      },
    );
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({required this.onAccountTap});

  final VoidCallback onAccountTap;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(
            Icons.trending_down_rounded,
            size: 22,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'PricePulse',
              style: AppTypography.headline1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Tooltip(
            message: 'Account',
            child: Material(
              color: AppColors.primaryContainer,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onAccountTap,
                child: const SizedBox(
                  // 48dp — design QA §3.4 touch-target floor.
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Text('P', style: AppTypography.avatarInitial),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.products,
    required this.onProductTap,
    required this.onSearchTap,
    required this.onCategoryTap,
    required this.onRefresh,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onCategoryTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final featured = products.where((p) => p.featured).toList();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final gridExtent = 290.0 + 90.0 * (textScale - 1.0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: AppLayout.centerContent(
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: SearchBarHome(
                  productCount: products.length,
                  onTap: onSearchTap,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                // Trailing padding lives on the chips themselves so the scroll
                // row is inset at both ends without boxing in the grid below.
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: CategoryChips(
                  categories: kCategories,
                  selected: 'All',
                  onSelected: (label) {
                    if (label != 'All') onCategoryTap(label);
                  },
                ),
              ),
            ),
            if (featured.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: const SectionHeader(title: 'Top picks'),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < featured.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.sm),
                        FeaturedCard(
                          product: featured[i],
                          onTap: () => onProductTap(featured[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SectionHeader(
                  title: 'All products',
                  count: products.length,
                  trailingLabel: 'See all',
                  onTrailingTap: onSearchTap,
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
                  mainAxisExtent: gridExtent,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(
                    product: products[index],
                    onTap: () => onProductTap(products[index]),
                    onFavoriteTap: () => showAppSnackbar(
                      context,
                      'Cloud-synced favorites arrive with accounts in a later '
                      'milestone.',
                      kind: SnackbarKind.info,
                    ),
                  ),
                  childCount: products.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
