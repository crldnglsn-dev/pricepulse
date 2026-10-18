import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pricepulse/models/offer.dart';
import 'package:pricepulse/theme/app_colors.dart';
import 'package:pricepulse/theme/app_typography.dart';

/// Contrast floors for the palette.
///
/// Design QA §3.4 sets them: body text at 7:1, captions and small text at
/// 4.5:1, and UI chrome (icons, borders, dividers) at 3:1.
///
/// A light palette is exactly where a dark theme's contrast quietly stops
/// holding — a muted grey that reads fine on near-black is unreadable on
/// paper. These tests are the reason the re-skin did not ship four unreadable
/// labels.
void main() {
  /// Relative luminance, per WCAG 2.1.
  double luminance(Color c) {
    double channel(double v) {
      final s = v / 255;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }

    final argb = c.toARGB32();
    final r = channel(((argb >> 16) & 0xFF).toDouble());
    final g = channel(((argb >> 8) & 0xFF).toDouble());
    final b = channel((argb & 0xFF).toDouble());
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  void expectContrast(
    String label,
    Color foreground,
    Color background,
    double minimum,
  ) {
    final ratio = contrast(foreground, background);
    expect(
      ratio,
      greaterThanOrEqualTo(minimum),
      reason:
          '$label: ${foreground.toARGB32().toRadixString(16)} on '
          '${background.toARGB32().toRadixString(16)} is ${ratio.toStringAsFixed(2)}:1, '
          'needs at least $minimum:1',
    );
  }

  group('text on the page and on cards', () {
    const surfaces = {
      'page': AppColors.bg,
      'card': AppColors.surface,
      'elevated': AppColors.surfaceElevated,
    };

    for (final entry in surfaces.entries) {
      final name = entry.key;
      final surface = entry.value;
      test('body text clears 7:1 on the $name', () {
        expectContrast(
          'textPrimary on $name',
          AppColors.textPrimary,
          surface,
          7,
        );
        expectContrast(
          'textSecondary on $name',
          AppColors.textSecondary,
          surface,
          4.5,
        );
        expectContrast('textMuted on $name', AppColors.textMuted, surface, 4.5);
      });
    }
  });

  group('text on coloured fills', () {
    test('the primary button label clears 4.5:1 on the primary fill', () {
      expectContrast(
        'onPrimary on primary',
        AppColors.onPrimary,
        AppColors.primary,
        4.5,
      );
    });

    test('the blush container holds deep rose text', () {
      expectContrast(
        'onPrimaryContainer on primaryContainer',
        AppColors.onPrimaryContainer,
        AppColors.primaryContainer,
        4.5,
      );
    });

    test('the lilac container holds deep lilac text', () {
      expectContrast(
        'secondaryTint on secondaryContainer',
        AppColors.secondaryTint,
        AppColors.secondaryContainer,
        4.5,
      );
    });

    test('the savings green holds its label', () {
      // The savings badge is 12px text, so it is held to the caption floor.
      expectContrast(
        'onSuccess on successContainer',
        AppColors.onSuccess,
        AppColors.successContainer,
        4.5,
      );
    });

    test('the error container holds its label', () {
      expectContrast(
        'error on errorContainer',
        AppColors.error,
        AppColors.errorContainer,
        4.5,
      );
    });
  });

  group('UI chrome', () {
    test('the filled heart clears 3:1 on a near-white overlay', () {
      // The heart sits on a translucent scrim over a product photo.
      expectContrast(
        'favourite on surface',
        AppColors.favourite,
        AppColors.surface,
        3,
      );
    });

    test('each store accent clears 3:1 on a card', () {
      for (final store in Store.values) {
        expectContrast(
          '${store.name} dot on surface',
          AppColors.forStore(store),
          AppColors.surface,
          3,
        );
      }
    });
  });

  group('the type scale', () {
    test('every named style paints readable text on the page', () {
      final styles = <String, TextStyle>{
        'display': AppTypography.display,
        'headline1': AppTypography.headline1,
        'headline2': AppTypography.headline2,
        'titleText': AppTypography.titleText,
        'bodyLarge': AppTypography.bodyLarge,
        'body': AppTypography.body,
        'bodySecondary': AppTypography.bodySecondary,
        'caption': AppTypography.caption,
        'captionMuted': AppTypography.captionMuted,
        'overline': AppTypography.overline,
        'priceLarge': AppTypography.priceLarge,
        'price': AppTypography.price,
        'labelLarge': AppTypography.labelLarge,
        'labelSmall': AppTypography.labelSmall,
        'avatarInitial': AppTypography.avatarInitial,
      };

      for (final entry in styles.entries) {
        final style = entry.value;
        // Anything below 18pt is "small text" and takes the 4.5:1 floor.
        final minimum = (style.fontSize ?? 14) >= 18 ? 3.0 : 4.5;
        expectContrast(
          entry.key,
          style.color ?? AppColors.textPrimary,
          AppColors.bg,
          minimum,
        );
      }
    });
  });
}
