import 'package:flutter/material.dart';

/// Friendly cat-face mascot rendered programmatically — circles for the head
/// + ears, dot eyes, a small smile and whiskers. Tinted by `colorScheme.primary`
/// over a soft container fill.
///
/// Placeholder until a commissioned illustration ships at
/// `assets/illustrations/mascot.svg`. Kept asset-free so empty / loading
/// screens render without a network or bundle dependency.
class PetMascot extends StatelessWidget {
  const PetMascot({this.size = 160, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MascotPainter(
          fill: scheme.primaryContainer,
          ink: scheme.primary,
          accent: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({required this.fill, required this.ink, required this.accent});

  final Color fill;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2 + s * 0.04);
    final headRadius = s * 0.36;

    final fillPaint = Paint()..color = fill;
    final inkPaint = Paint()..color = ink;

    // Ears (filled triangles).
    final earOffset = s * 0.30;
    final earPath = Path()
      ..moveTo(center.dx - earOffset, center.dy - headRadius * 0.55)
      ..lineTo(center.dx - earOffset * 0.50, center.dy - headRadius * 1.45)
      ..lineTo(center.dx - earOffset * 0.10, center.dy - headRadius * 0.85)
      ..close()
      ..moveTo(center.dx + earOffset, center.dy - headRadius * 0.55)
      ..lineTo(center.dx + earOffset * 0.50, center.dy - headRadius * 1.45)
      ..lineTo(center.dx + earOffset * 0.10, center.dy - headRadius * 0.85)
      ..close();
    canvas
      ..drawPath(earPath, fillPaint)
      ..drawCircle(center, headRadius, fillPaint);

    // Eyes.
    final eyeRadius = s * 0.04;
    final eyeDx = headRadius * 0.42;
    final eyeDy = headRadius * 0.10;
    canvas
      ..drawCircle(center.translate(-eyeDx, -eyeDy), eyeRadius, inkPaint)
      ..drawCircle(center.translate(eyeDx, -eyeDy), eyeRadius, inkPaint);

    // Eye highlights.
    final highlight = Paint()..color = Colors.white;
    final hr = eyeRadius * 0.35;
    canvas
      ..drawCircle(
        center.translate(-eyeDx + hr, -eyeDy - hr),
        hr,
        highlight,
      )
      ..drawCircle(
        center.translate(eyeDx + hr, -eyeDy - hr),
        hr,
        highlight,
      );

    // Nose (tiny rounded triangle).
    final nosePath = Path()
      ..moveTo(center.dx - s * 0.025, center.dy + s * 0.04)
      ..lineTo(center.dx + s * 0.025, center.dy + s * 0.04)
      ..lineTo(center.dx, center.dy + s * 0.075)
      ..close();
    canvas.drawPath(nosePath, inkPaint);

    // Smile (open arc below the nose).
    final smileRect = Rect.fromCenter(
      center: center.translate(0, s * 0.10),
      width: s * 0.16,
      height: s * 0.10,
    );
    final smilePaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(smileRect, 0.1, 3.05 - 0.2, false, smilePaint);

    // Cheek blush.
    final blush = Paint()..color = accent.withValues(alpha: 0.18);
    canvas
      ..drawCircle(
        center.translate(-headRadius * 0.62, headRadius * 0.18),
        s * 0.05,
        blush,
      )
      ..drawCircle(
        center.translate(headRadius * 0.62, headRadius * 0.18),
        s * 0.05,
        blush,
      );

    // Whiskers.
    final whiskerPaint = Paint()
      ..color = ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.010
      ..strokeCap = StrokeCap.round;
    final yOffsets = [-s * 0.02, s * 0.0, s * 0.02];
    for (final yo in yOffsets) {
      canvas
        ..drawLine(
          center.translate(-headRadius * 0.40, s * 0.06 + yo),
          center.translate(-headRadius * 0.95, s * 0.04 + yo),
          whiskerPaint,
        )
        ..drawLine(
          center.translate(headRadius * 0.40, s * 0.06 + yo),
          center.translate(headRadius * 0.95, s * 0.04 + yo),
          whiskerPaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) =>
      old.fill != fill || old.ink != ink || old.accent != accent;
}
