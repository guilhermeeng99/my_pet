import 'package:flutter/material.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';

/// Lightweight inline weight trend rendered with CustomPaint — keeps the
/// dependency surface small until fl_chart lands. Plots the last 24
/// entries chronologically; pads scale to give labels breathing room.
class WeightSparkline extends StatelessWidget {
  const WeightSparkline({
    required this.entries,
    this.height = 140,
    super.key,
  });

  final List<WeightEntry> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final recent = _recentChronological();
    if (recent.length < 2) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: AppRadii.brLg,
        ),
        child: Text(
          'Add a second weigh-in to see the trend.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.onSurfaceMuted,
          ),
        ),
      );
    }
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadii.brLg,
      ),
      child: CustomPaint(
        painter: _SparklinePainter(
          values: recent.map((e) => e.weightKg).toList(growable: false),
          line: theme.colorScheme.primary,
          fill: theme.colorScheme.primary.withValues(alpha: 0.15),
          axis: palette.onSurfaceFaint,
        ),
        size: Size.infinite,
      ),
    );
  }

  /// Last 24 entries in ascending date order.
  List<WeightEntry> _recentChronological() {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length <= 24) return sorted;
    return sorted.sublist(sorted.length - 24);
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.axis,
  });

  final List<double> values;
  final Color line;
  final Color fill;
  final Color axis;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final pad = max - min == 0 ? 1.0 : (max - min) * 0.1;
    final scaleMin = min - pad;
    final scaleMax = max + pad;
    final range = scaleMax - scaleMin;

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final dx = i * stepX;
      final normalized = (values[i] - scaleMin) / range;
      final dy = size.height - (normalized * size.height);
      points.add(Offset(dx, dy));
    }

    // Axis (top + bottom hairlines for context).
    final axisPaint = Paint()
      ..color = axis.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, 0), axisPaint)
      ..drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        axisPaint,
      );

    // Filled area.
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fill);

    // Line.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas
      ..drawPath(
        linePath,
        Paint()
          ..color = line
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      // Endpoint dots.
      ..drawCircle(points.first, 3, Paint()..color = line)
      ..drawCircle(points.last, 4, Paint()..color = line);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.line != line;
}
