import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale.
/// Spec: design/02_design_system.md §1.2.
///
/// Colors are baked into the styles so every Text created from them resolves
/// a concrete (accessible) color instead of inheriting a possibly-wrong value.
///
/// Nunito is bundled as a single variable font, so every style states its
/// weight twice: once as `fontWeight`, for the engine's font matching, and
/// once as an explicit `wght` axis variation, for the case where the family
/// is loaded as a variable font. Both point at the same value, so a bold
/// heading is bold rather than a slightly-heavier 400.
abstract final class AppTypography {
  /// Nunito — rounded terminals, open apertures, and numerals that stay
  /// legible at price sizes.
  static const String fontFamily = 'Nunito';

  // Display.
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.4,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // Headings.
  static const TextStyle headline1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: -0.1,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Titles / body.
  static const TextStyle titleText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: 0.1,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: 0.1,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: 0.1,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // Captions / meta.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: 0.2,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static const TextStyle captionMuted = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: 0.2,
    height: 1.35,
    color: AppColors.textMuted,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 1.0,
    height: 1.3,
    color: AppColors.textMuted,
  );

  // Prices — tabular figures so columns align during comparison.
  static const TextStyle priceLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.2,
    height: 1.2,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.3,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Buttons / labels.
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0.3,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0.15,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Monogram initial inside a round avatar (Home app bar).
  static const TextStyle avatarInitial = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    color: AppColors.onPrimaryContainer,
  );

  /// Maps the scale onto Material [TextTheme] roles used by framework
  /// components (AppBar titles, buttons, list tiles, etc.).
  static TextTheme materialTextTheme() => const TextTheme(
    displaySmall: display,
    headlineMedium: headline1,
    titleLarge: headline2,
    titleMedium: titleText,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: labelLarge,
    labelMedium: labelSmall,
    labelSmall: overline,
  );
}
