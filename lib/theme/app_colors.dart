import 'package:flutter/material.dart';

import '../models/offer.dart';

/// Central color tokens — single source of truth for the visual identity.
/// Spec: design/02_design_system.md §1.1.
///
/// **Milk & Blush** — a warm, light palette. The app is about soft things
/// (prices, favourites, small purchases), so the base is warm paper rather
/// than a dark slab, and the accents are rose, lilac and mint.
///
/// Every text token below was chosen to clear the contrast floor on the
/// surface it is used on: body text at 7:1, captions at 4.5:1. That is
/// checked by `test/theme_contrast_test.dart`, because a light palette is
/// exactly where a dark theme's contrast quietly stops holding.
abstract final class AppColors {
  // --- Neutrals -----------------------------------------------------------
  /// Warm paper. The page itself, and the app bar so it reads seamless.
  static const Color bg = Color(0xFFFFF9F6);

  /// Cards and sheets.
  static const Color surface = Color(0xFFFFFFFF);

  /// One step above a surface — chips, dialogs, snackbars.
  static const Color surfaceElevated = Color(0xFFFFFCFB);

  /// Pressed wash on a tappable surface.
  static const Color surfaceHover = Color(0xFFF7EFF4);

  /// Hairline separators and card outlines.
  static const Color border = Color(0xFFEFE3EA);

  /// The faintest separator.
  static const Color borderSubtle = Color(0xFFF7EFF3);

  // --- Brand --------------------------------------------------------------
  /// Rose. The primary action colour.
  static const Color primary = Color(0xFFFF6FA5);
  static const Color primaryHover = Color(0xFFFF87B4);
  static const Color primaryPressed = Color(0xFFE85A8E);

  /// Blush. Selected states, chips, the favourites heart.
  static const Color primaryContainer = Color(0xFFFFE4EE);

  /// Deep plum for text and icons sitting on [primary].
  ///
  /// White on the soft rose only reaches 2.6:1, so the label is plum rather
  /// than white — 5.4:1, and a pastel button with a deep label is the look
  /// this palette is going for anyway.
  static const Color onPrimary = Color(0xFF4A1F36);

  /// The brand colour as text, a glyph or a border on a light surface.
  ///
  /// [primary] is a fill and reads at 2.5:1 as text, which is not enough.
  /// This is the same hue taken deep enough to read: 4.8:1.
  static const Color accent = Color(0xFFC33D6E);

  /// Deep rose for text sitting on [primaryContainer].
  static const Color onPrimaryContainer = Color(0xFF8A2450);

  /// Lilac. Secondary emphasis — the "Top pick" badge, secondary actions.
  static const Color secondary = Color(0xFFA78BFA);
  static const Color secondaryContainer = Color(0xFFEEE8FF);

  /// Deep lilac for text sitting on [secondaryContainer].
  static const Color secondaryTint = Color(0xFF4A2E93);

  /// Mint. Tertiary emphasis.
  static const Color tertiary = Color(0xFF5ECFB6);

  // --- Semantic -----------------------------------------------------------
  /// "You saved money" green. For icons and accents on a light surface.
  static const Color success = Color(0xFF2FA37B);
  static const Color successContainer = Color(0xFFDFF5EB);

  /// Deep green for text and icons sitting on [successContainer]. 8.2:1.
  /// [success] itself only reaches 2.8:1 on that fill, which is fine for an
  /// accent but not for 12px text.
  static const Color onSuccess = Color(0xFF14503A);

  static const Color warning = Color(0xFFB8780E);
  static const Color error = Color(0xFFC2303F);
  static const Color errorContainer = Color(0xFFFFE3E7);

  /// The filled heart. Deeper than [primary] because a small filled glyph on
  /// a near-white scrim needs 3:1, and [primary] only reaches 2.6:1.
  static const Color favourite = Color(0xFFE8437E);

  // --- Text ---------------------------------------------------------------
  /// Warm charcoal. Body and headings. 14:1 on [surface].
  static const Color textPrimary = Color(0xFF2E2733);

  /// Secondary text. 7.2:1 on [surface].
  static const Color textSecondary = Color(0xFF5C5468);

  /// Muted text and captions. 5.4:1 on [surface] — muted, but still legible.
  static const Color textMuted = Color(0xFF6F6679);

  static const Color textDisabled = Color(0xFFB5ACBD);

  // --- Depth --------------------------------------------------------------
  /// The soft shadow under a card. Rose-tinted rather than grey, so the
  /// shadow belongs to the palette instead of sitting on top of it.
  static const Color shadow = Color(0x1FE86FA8);

  /// A heavier shadow, for the one surface that floats above everything.
  static const Color shadowStrong = Color(0x2EE86FA8);

  // --- Background wash ----------------------------------------------------
  /// The soft gradient blobs behind the Home content. Painted, not blurred —
  /// a live [BackdropFilter] here would re-blur on every frame.
  static const Color meshBlush = Color(0xFFFFD9E6);
  static const Color meshLilac = Color(0xFFE4DCFF);
  static const Color meshButter = Color(0xFFFFEFCB);
  static const Color meshMint = Color(0xFFD2F3E9);

  /// Marketplace accents — always shown next to the store *name* so color is
  /// never the only signal (design: color-independence requirement).
  /// Darkened from the dark theme's values, which were tuned for a dark
  /// surface and lose contrast on paper.
  static Color forStore(Store store) => switch (store) {
    Store.shopee => const Color(0xFFE2553A),
    Store.lazada => const Color(0xFF4A6FD4),
    Store.tiktok => const Color(0xFF149C93),
  };
}
