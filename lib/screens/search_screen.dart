import 'dart:async';

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
import '../widgets/product_card.dart';
import '../widgets/skeletons.dart';
import 'product_details_screen.dart';

enum _SortMode { featured, priceAsc, priceDesc, name }

/// Search Results — serves query mode and category mode (design/03b §1).
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    this.initialCategory,
    this.initialQuery,
  });

  final String? initialCategory;
  final String? initialQuery;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _query = '';
  String? _category;
  _SortMode _sort = _SortMode.featured;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _query = widget.initialQuery ?? '';
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  List<Product> _filter(List<Product> all) {
    final query = _query.trim();
    var result = all;
    if (query.isNotEmpty) {
      result = result.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query);
      }).toList();
    }
    if (_category != null && _category != 'All') {
      result = result.where((p) => p.category == _category).toList();
    }
    switch (_sort) {
      case _SortMode.featured:
        break;
      case _SortMode.priceAsc:
        result = [...result]
          ..sort((a, b) => (a.lowestPrice ?? 0).compareTo(b.lowestPrice ?? 0));
      case _SortMode.priceDesc:
        result = [...result]
          ..sort((a, b) => (b.lowestPrice ?? 0).compareTo(a.lowestPrice ?? 0));
      case _SortMode.name:
        result = [...result]..sort((a, b) => a.name.compareTo(b.name));
    }
    return result;
  }

  void _openProduct(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsProvider>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _SearchField(
          controller: _controller,
          autofocus: widget.initialCategory == null,
          onChanged: _onQueryChanged,
          onClear: () {
            _controller.clear();
            setState(() => _query = '');
          },
        ),
      ),
      body: switch (provider.status) {
        ProductsStatus.loading => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: GridSkeleton(),
        ),
        ProductsStatus.error => ErrorState(
          message: provider.errorMessage,
          onRetry: () => context.read<ProductsProvider>().refresh(),
        ),
        ProductsStatus.success => _buildResults(context, provider.products),
      },
    );
  }

  Widget _buildResults(BuildContext context, List<Product> all) {
    final results = _filter(all);
    final categoryLabel = (_category != null && _category != 'All')
        ? ' · $_category'
        : '';
    final countLabel = _query.isNotEmpty
        ? '${results.length} of ${all.length} products$categoryLabel'
        : '${results.length} products$categoryLabel';

    final chips = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: CategoryChips(
        categories: kCategories,
        selected: _category ?? 'All',
        onSelected: (label) =>
            setState(() => _category = label == 'All' ? null : label),
      ),
    );

    final caption = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              countLabel,
              style: AppTypography.captionMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: () => _showSortMenu(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            icon: const Icon(Icons.swap_vert_rounded, size: 16),
            label: const Text('Sort'),
          ),
        ],
      ),
    );

    if (results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          chips,
          caption,
          const SizedBox(height: AppSpacing.xl),
          EmptyState(
            icon: Icons.search_off_rounded,
            title: _query.isNotEmpty
                ? 'No results for “$_query”'
                : 'Nothing here yet',
            body: 'Check the spelling or try a broader category.',
            secondaryAction: TextButton(
              onPressed: () {
                _controller.clear();
                setState(() {
                  _query = '';
                  _category = null;
                });
              },
              child: const Text('Clear filters'),
            ),
          ),
        ],
      );
    }

    final extent =
        290.0 + 90.0 * (MediaQuery.textScalerOf(context).scale(1.0) - 1.0);
    return AppLayout.centerContent(
      CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: chips),
          SliverToBoxAdapter(child: caption),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
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
                  product: results[index],
                  onTap: () => _openProduct(context, results[index]),
                ),
                childCount: results.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusMd),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text('Sort by', style: AppTypography.headline2),
            for (final (mode, label) in const [
              (_SortMode.featured, 'Featured'),
              (_SortMode.priceAsc, 'Price: low to high'),
              (_SortMode.priceDesc, 'Price: high to low'),
              (_SortMode.name, 'Name A–Z'),
            ])
              ListTile(
                leading: Icon(
                  _sort == mode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _sort == mode
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: _sort == mode
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _sort = mode);
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        style: AppTypography.body,
        decoration: InputDecoration(
          hintText: 'Search products…',
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.textSecondary,
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(Icons.cancel_rounded, size: 18),
                ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.zero,
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            borderSide: BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}
