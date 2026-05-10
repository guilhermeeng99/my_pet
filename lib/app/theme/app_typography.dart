import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens. See specs/design.md.
///
/// Inter is loaded via google_fonts during MVP. When the app ships, the
/// font is bundled via `pubspec.yaml` for offline reliability.
abstract final class AppTypography {
  static TextStyle _base(double size, FontWeight weight, double lineHeight,
      double spacing, Color color) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: lineHeight,
      letterSpacing: spacing,
      color: color,
    );
  }

  static TextTheme textTheme({required Brightness brightness}) {
    final ink = brightness == Brightness.light
        ? const Color(0xFF0E1830)
        : const Color(0xFFEDF2FF);
    final muted = brightness == Brightness.light
        ? const Color(0xFF5C6985)
        : const Color(0xFFA5B0C9);

    return TextTheme(
      displayLarge: _base(36, FontWeight.w700, 1.1, -0.5, ink),
      headlineLarge: _base(28, FontWeight.w700, 1.15, -0.4, ink),
      headlineMedium: _base(24, FontWeight.w700, 1.2, -0.3, ink),
      headlineSmall: _base(20, FontWeight.w600, 1.25, -0.2, ink),
      titleLarge: _base(18, FontWeight.w600, 1.3, 0, ink),
      titleMedium: _base(16, FontWeight.w600, 1.35, 0, ink),
      titleSmall: _base(14, FontWeight.w600, 1.35, 0.1, ink),
      bodyLarge: _base(16, FontWeight.w400, 1.5, 0, ink),
      bodyMedium: _base(14, FontWeight.w400, 1.5, 0.1, muted),
      bodySmall: _base(12, FontWeight.w500, 1.3, 0.5, muted),
      labelLarge: _base(13, FontWeight.w600, 1.3, 0.4, ink),
      labelMedium: _base(12, FontWeight.w600, 1.3, 0.5, muted),
      labelSmall: _base(11, FontWeight.w700, 1.2, 1.2, muted),
    );
  }
}
