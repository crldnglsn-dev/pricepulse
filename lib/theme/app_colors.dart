import 'package:flutter/material.dart';

import '../models/offer.dart';

/// Central color tokens — single source of truth for the visual identity.
/// Spec: design/02_design_system.md §1.1.
abstract final class AppColors {
  // --- Neutrals -----------------------------------------------------------
  static const Color bg = Color(0xFF121318);
  static const Color surface = Color(0xFF1C1E26);
  static const Color surfaceElevated = Color(0xFF262934);
  static const Color surfaceHover = Color(0xFF2C2F3B);
  static const Color border = Color(0xFF343743);
  static const Color borderSubtle = Color(0xFF262934);

  // --- Brand --------------------------------------------------------------
  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryHover = Color(0xFF925CFF);
  static const Color primaryPressed = Color(0xFF6B3BE0);
  static const Color primaryContainer = Color(0xFF2B2145);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFDECEFF);
  static const Color secondary = Color(0xFFE84393);
  static const Color secondaryContainer = Color(0xFF3A2233);
  static const Color secondaryTint = Color(0xFFFFC2DD);

  // --- Semantic -----------------------------------------------------------
  static const Color success = Color(0xFF65D98B);
  static const Color successContainer = Color(0xFF1B3526);
  // The design token `onSuccess` (#0B2E18) was specified for a bright green
  // fill; on the dark `successContainer` it fails 4.5:1 contrast, so it is
  // lifted to a light mint here (design QA §3.4: tune tokens to pass).
  static const Color onSuccess = Color(0xFFB8EECB);
  static const Color warning = Color(0xFFF2A73B);
  static const Color error = Color(0xFFFF6B7A);
  static const Color errorContainer = Color(0xFF3A1F24);
  static const Color link = Color(0xFFA98BFF);

  // --- Text ---------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA5A8B5);
  static const Color textMuted = Color(0xFF70747F);
  static const Color textDisabled = Color(0xFF4A4E5C);

  /// Marketplace accents — always shown next to the store *name* so color is
  /// never the only signal (design: color-independence requirement).
  static Color forStore(Store store) => switch (store) {
    Store.shopee => const Color(0xFFFF6B52),
    Store.lazada => const Color(0xFF7E9CFF),
    Store.tiktok => const Color(0xFF3FD8CE),
  };
}
