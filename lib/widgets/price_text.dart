import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../utils/formatters.dart';

/// Tabular-figure price text (₱) so comparison columns align.
/// Spec: design/02 §1.2 (numbers) + `price`/`priceLarge` styles.
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.amount,
    this.style,
    this.maxLines = 1,
  });

  final double amount;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final base = style ?? AppTypography.price;
    return Text(
      formatPeso(amount),
      maxLines: maxLines,
      overflow: maxLines > 1 ? null : TextOverflow.ellipsis,
      style: base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}
