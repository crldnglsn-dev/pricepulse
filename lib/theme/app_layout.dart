import 'package:flutter/widgets.dart';

import 'app_spacing.dart';

/// Layout rules that respond to the viewport rather than to a single screen.
///
/// Design QA §3.4 requires content to stay readable on landscape/tablet by
/// capping the reading column and centering it, and to step the product grid
/// up to three columns from 600dp.
abstract final class AppLayout {
  /// Widest the content column may grow before it is centered. Sized so the
  /// 3-column grid (which kicks in at 600dp) is reachable without letting
  /// cards sprawl across a desktop-width window.
  static const double maxContentWidth = 720;

  /// Viewport width at which the product grid steps to three columns.
  static const double threeColumnBreakpoint = 600;

  /// Columns for the product grid at the current viewport.
  static int gridColumns(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= threeColumnBreakpoint ? 3 : 2;

  /// Centres and width-caps [child] on wide viewports.
  ///
  /// A no-op below [maxContentWidth], so phone layouts are untouched.
  static Widget centerContent(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxContentWidth),
      child: child,
    ),
  );

  /// Horizontal page padding for a screen at the current viewport.
  static EdgeInsets get pagePadding =>
      const EdgeInsets.symmetric(horizontal: AppSpacing.screen);
}
