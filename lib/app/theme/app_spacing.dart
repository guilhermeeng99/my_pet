/// Strict 4-pt spacing grid. See specs/design.md.
///
/// Use these constants instead of inline doubles in widgets so spacing stays
/// uniform across the app. Adding a new value requires updating the spec.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double huge = 64;
}
