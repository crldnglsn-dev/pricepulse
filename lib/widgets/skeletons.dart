import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import '../theme/app_spacing.dart';
import 'skeleton.dart';

/// Home skeleton — mirrors the real layout footprint.
/// Spec: design/03a §1.3 (loading state).
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SkeletonBox(height: 52, radius: 999),
          const SizedBox(height: AppSpacing.md),
          _chipRow(),
          const SizedBox(height: AppSpacing.xl),
          GridSkeleton(featured: true),
        ],
      ),
    );
  }

  /// Flexible chip placeholders — a fixed count × fixed width overflows at
  /// 320dp, so the widths share the row.
  Widget _chipRow() {
    return Row(
      children: List.generate(
        4,
        (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: SkeletonBox(height: 44, radius: 999),
          ),
        ),
      ),
    );
  }
}

/// Product grid skeleton used by Home / Search / Favorites.
class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key, this.featured = false});

  final bool featured;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: AppLayout.gridColumns(context),
      mainAxisSpacing: AppSpacing.gridGap,
      crossAxisSpacing: AppSpacing.gridGap,
      childAspectRatio: 0.68,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(6, (_) => const _CardSkeleton()),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image area flexes like the real ProductCard → never overflows.
        const Expanded(child: SkeletonBox(radius: 0)),
        const SizedBox(height: AppSpacing.xs + 4),
        const SkeletonBox(height: 12, width: 64),
        const SizedBox(height: AppSpacing.xs),
        const SkeletonBox(height: 14),
        const SizedBox(height: AppSpacing.xxs),
        const SkeletonBox(height: 12, width: 92),
        const SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 16, width: double.infinity),
      ],
    );
  }
}

/// Product Details skeleton. Spec: design/03a §2.3 (loading state).
class ProductDetailsSkeleton extends StatelessWidget {
  const ProductDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(aspectRatio: 1, child: SkeletonBox(radius: 0)),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 12, width: 140),
                const SizedBox(height: AppSpacing.sm),
                const SkeletonBox(height: 22),
                const SizedBox(height: AppSpacing.xs),
                const SkeletonBox(height: 22, width: 240),
                const SizedBox(height: AppSpacing.xl),
                const SkeletonBox(height: 96, radius: AppSpacing.radiusMd),
                const SizedBox(height: AppSpacing.xl),
                SkeletonBox(height: 18, width: 160),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < 3; i++) ...[
                  const SkeletonBox(height: 64, radius: AppSpacing.radiusMd),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
