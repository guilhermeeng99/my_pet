import 'package:flutter/widgets.dart';

/// Soft shadow elevations. See specs/design.md.
///
/// Tuned for the soft sky background — navy ink at low alpha keeps depth
/// readable without harsh black drop shadows.
abstract final class AppShadows {
  static const Color _ink = Color(0xFF0B1B3A);

  static const List<BoxShadow> elevation1 = [
    BoxShadow(color: Color(0x0F0B1B3A), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> elevation2 = [
    BoxShadow(color: Color(0x140B1B3A), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> elevation3 = [
    BoxShadow(color: Color(0x1A0B1B3A), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // Used internally by token tests / golden audits.
  static List<Color> get inkColors => const [_ink];
}
