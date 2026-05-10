import 'package:flutter/widgets.dart';

/// Soft shadow elevations. See specs/design.md.
///
/// Light-mode values are tuned for the soft sky background; dark variants get
/// triple alpha to keep depth visible against deep navy surfaces.
abstract final class AppShadows {
  static const Color _lightInk = Color(0xFF0B1B3A);
  static const Color _darkInk = Color(0xFF000000);

  static const List<BoxShadow> elevation1Light = [
    BoxShadow(color: Color(0x0F0B1B3A), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> elevation2Light = [
    BoxShadow(color: Color(0x140B1B3A), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> elevation3Light = [
    BoxShadow(color: Color(0x1A0B1B3A), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> elevation1Dark = [
    BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> elevation2Dark = [
    BoxShadow(color: Color(0x55000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> elevation3Dark = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> elevation1(Brightness b) =>
      b == Brightness.light ? elevation1Light : elevation1Dark;
  static List<BoxShadow> elevation2(Brightness b) =>
      b == Brightness.light ? elevation2Light : elevation2Dark;
  static List<BoxShadow> elevation3(Brightness b) =>
      b == Brightness.light ? elevation3Light : elevation3Dark;

  // Used internally by token tests / golden audits.
  static List<Color> get inkColors => const [_lightInk, _darkInk];
}
