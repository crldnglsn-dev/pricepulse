import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Designed missing-image placeholder.
/// Spec: design/02 §2.9 `MissingImage`.
class MissingImage extends StatelessWidget {
  const MissingImage({super.key, this.label = 'No image', this.iconSize = 48});

  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: iconSize,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.captionMuted),
        ],
      ),
    );
  }
}

/// Product image that resolves assets or URLs and always falls back to the
/// designed placeholder. Missing images are an expected, honest state while
/// the product catalog is being assembled (Milestone 5).
class AppProductImage extends StatelessWidget {
  const AppProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  final String imageUrl;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (imageUrl.startsWith('assets/')) {
      image = Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (_, _, _) => const MissingImage(),
      );
    } else {
      image = Image.network(
        imageUrl,
        fit: fit,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const MissingImage(label: 'Loading…'),
        errorBuilder: (_, _, _) => const MissingImage(),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}
