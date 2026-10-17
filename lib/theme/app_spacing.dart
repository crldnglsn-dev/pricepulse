/// Spacing + radius tokens on a 4px grid.
/// Spec: design/02_design_system.md §1.3–§1.4.
abstract final class AppSpacing {
  // Spacing scale.
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  // Layout conventions.
  static const double screen = md; // 16 horizontal screen padding
  static const double section = xl; // 24 vertical rhythm
  static const double gridGap = sm; // 12 between grid cards

  // Corner radius scale.
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
}
