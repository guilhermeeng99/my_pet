import 'package:flutter/material.dart';

/// Color tokens. See specs/design.md for rationale and usage rules.
///
/// Widgets must consume these via the [BuildContext] extensions in
/// `palette_ext.dart`, never as raw imports — the extension routes the
/// correct light/dark variant automatically.
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryPressed = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFE6EFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF0B2A6B);

  static const Color primaryDark = Color(0xFF5B8DEF);
  static const Color primaryPressedDark = Color(0xFF2563EB);
  static const Color primaryContainerDark = Color(0xFF13234A);
  static const Color onPrimaryContainerDark = Color(0xFFCFE0FF);

  // ── Neutral surfaces (light) ─────────────────────────────────────────
  static const Color background = Color(0xFFF2F7FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEAF2FF);
  static const Color outline = Color(0xFFDDE6F4);
  static const Color onBackground = Color(0xFF0E1830);
  static const Color onSurface = Color(0xFF0E1830);
  static const Color onSurfaceMuted = Color(0xFF5C6985);
  static const Color onSurfaceFaint = Color(0xFF8E99B3);

  // ── Neutral surfaces (dark) ──────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color surfaceDark = Color(0xFF131C30);
  static const Color surfaceMutedDark = Color(0xFF1B2540);
  static const Color outlineDark = Color(0xFF2D3957);
  static const Color onBackgroundDark = Color(0xFFEDF2FF);
  static const Color onSurfaceDark = Color(0xFFEDF2FF);
  static const Color onSurfaceMutedDark = Color(0xFFA5B0C9);
  static const Color onSurfaceFaintDark = Color(0xFF7480A0);

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF3FBF7F);
  static const Color warning = Color(0xFFF5B544);
  static const Color danger = Color(0xFFF25A4F);
  static const Color info = Color(0xFF3FA9F5);

  static const Color successDark = Color(0xFF5FD89A);
  static const Color warningDark = Color(0xFFFFC966);
  static const Color dangerDark = Color(0xFFFF7A6E);
  static const Color infoDark = Color(0xFF5FBEFF);

  // ── Pet category accents (used decoratively, same in both modes) ─────
  static const Color accentCat = Color(0xFFFF8C73);
  static const Color accentDog = Color(0xFFFFB84D);
  static const Color accentBird = Color(0xFF5FBEFF);
  static const Color accentRabbit = Color(0xFF7C8CFF);
  static const Color accentOther = Color(0xFF7AC4A8);

  // ── ColorScheme builders ─────────────────────────────────────────────
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: primary,
    onSecondary: onPrimary,
    secondaryContainer: primaryContainer,
    onSecondaryContainer: onPrimaryContainer,
    error: danger,
    onError: Color(0xFFFFFFFF),
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceMuted,
    outline: outline,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: onPrimary,
    primaryContainer: primaryContainerDark,
    onPrimaryContainer: onPrimaryContainerDark,
    secondary: primaryDark,
    onSecondary: onPrimary,
    secondaryContainer: primaryContainerDark,
    onSecondaryContainer: onPrimaryContainerDark,
    error: dangerDark,
    onError: Color(0xFF0E1830),
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    surfaceContainerHighest: surfaceMutedDark,
    outline: outlineDark,
  );
}
