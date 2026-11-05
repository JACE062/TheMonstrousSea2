import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/ink_theme.dart';

/// Structural parchment and engraving; no generated geography or gameplay RNG.
class SeaChartPaperClipper extends CustomClipper<Path> {
  const SeaChartPaperClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final corners = [
      const Offset(4, 4),
      Offset(size.width - 4, 4),
      Offset(size.width - 4, size.height - 4),
      Offset(4, size.height - 4),
    ];
    for (var side = 0; side < 4; side++) {
      final from = corners[side], to = corners[(side + 1) % 4];
      final delta = to - from;
      final steps = (delta.distance / 9).ceil().clamp(1, 1000);
      final normal = Offset(-delta.dy, delta.dx) / delta.distance;
      for (var step = 0; step <= steps; step++) {
        final wear =
            math.sin(step * 1.7 + side * 3) * 1.4 +
            math.sin(step * .63 + side) * .9;
        final p = from + delta * (step / steps) + normal * wear;
        if (side == 0 && step == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
    }
    return path..close();
  }

  @override
  bool shouldReclip(SeaChartPaperClipper oldClipper) => false;
}

class SeaChartPaperPainter extends CustomPainter {
  const SeaChartPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final edge = const SeaChartPaperClipper().getClip(size);
    canvas.drawShadow(
      edge,
      InkTheme.inkPrimary.withValues(alpha: .3),
      3,
      false,
    );
    canvas.save();
    canvas.clipPath(edge);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.2, -.25),
          radius: 1,
          colors: [
            InkTheme.chartPaperLight,
            InkTheme.chartPaper,
            InkTheme.parchmentDark,
          ],
          stops: [0, .7, 1],
        ).createShader(rect),
    );
    // Soft tide stains and fold lines are restrained enough to read the wake.
    for (final (center, radius) in [
      (Offset(size.width * .16, size.height * .83), size.height * .32),
      (Offset(size.width * .81, size.height * .1), size.height * .24),
    ]) {
      final stain = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              InkTheme.chartEdge.withValues(alpha: .09),
              InkTheme.chartEdge.withValues(alpha: 0),
            ],
          ).createShader(stain),
      );
    }
    final border = Paint()
      ..color = InkTheme.chartEdge.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect.deflate(14), border);
    canvas.drawRect(
      rect.deflate(19),
      border..color = InkTheme.chartEdge.withValues(alpha: .3),
    );
    final ticks = Paint()
      ..color = InkTheme.chartEdge.withValues(alpha: .5)
      ..strokeWidth = 3;
    for (var x = 22.0; x < size.width - 22; x += 28) {
      canvas.drawLine(
        Offset(x, 16.5),
        Offset(math.min(x + 14, size.width - 22), 16.5),
        ticks,
      );
      canvas.drawLine(
        Offset(x, size.height - 16.5),
        Offset(math.min(x + 14, size.width - 22), size.height - 16.5),
        ticks,
      );
    }
    for (var y = 22.0; y < size.height - 22; y += 28) {
      canvas.drawLine(
        Offset(16.5, y),
        Offset(16.5, math.min(y + 14, size.height - 22)),
        ticks,
      );
      canvas.drawLine(
        Offset(size.width - 16.5, y),
        Offset(size.width - 16.5, math.min(y + 14, size.height - 22)),
        ticks,
      );
    }
    canvas.restore();
    canvas.drawPath(
      edge,
      Paint()
        ..color = InkTheme.chartEdge.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(SeaChartPaperPainter oldDelegate) => false;
}
