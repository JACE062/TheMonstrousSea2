import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/ink_theme.dart';

/// Renders a classic 16-point nautical chart compass rose with fleur-de-lis north indicator.
class CompassRosePainter extends CustomPainter {
  const CompassRosePainter({
    this.primaryColor = InkTheme.inkPrimary,
    this.accentColor = InkTheme.goldAccent,
  });

  final Color primaryColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    if (radius <= 0) return;

    final ringPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Concentric chart rings
    canvas.drawCircle(center, radius * 0.95, ringPaint);
    canvas.drawCircle(center, radius * 0.75, ringPaint);
    canvas.drawCircle(center, radius * 0.25, ringPaint);

    // 16 points: 4 Cardinal, 4 Ordinal, 8 Half-winds
    _drawStarPoints(canvas, center, radius * 0.92, 4, primaryColor, accentColor, 0);
    _drawStarPoints(canvas, center, radius * 0.65, 4, accentColor, primaryColor, pi / 4);
    _drawStarPoints(canvas, center, radius * 0.45, 8, primaryColor.withValues(alpha: 0.5), primaryColor.withValues(alpha: 0.3), pi / 8);

    // North Fleur-de-lis marker
    _drawNorthFleurDeLis(canvas, center, radius * 0.95);

    // Center pivot brass stud
    final brassPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.08, brassPaint);
    canvas.drawCircle(center, radius * 0.08, ringPaint);
  }

  void _drawStarPoints(
    Canvas canvas,
    Offset center,
    double length,
    int count,
    Color leftColor,
    Color rightColor,
    double startAngle,
  ) {
    final step = (2 * pi) / count;
    final leftPaint = Paint()..color = leftColor..style = PaintingStyle.fill;
    final rightPaint = Paint()..color = rightColor..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final baseRadius = length * 0.25;

    for (var i = 0; i < count; i++) {
      final angle = startAngle + i * step;
      final tip = center + Offset(cos(angle - pi / 2) * length, sin(angle - pi / 2) * length);
      final leftBase = center + Offset(cos(angle - pi / 2 - pi / (count * 2)) * baseRadius, sin(angle - pi / 2 - pi / (count * 2)) * baseRadius);
      final rightBase = center + Offset(cos(angle - pi / 2 + pi / (count * 2)) * baseRadius, sin(angle - pi / 2 + pi / (count * 2)) * baseRadius);

      // Left half-point
      final leftPath = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(leftBase.dx, leftBase.dy)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      canvas.drawPath(leftPath, leftPaint);
      canvas.drawPath(leftPath, strokePaint);

      // Right half-point
      final rightPath = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(rightBase.dx, rightBase.dy)
        ..close();
      canvas.drawPath(rightPath, rightPaint);
      canvas.drawPath(rightPath, strokePaint);
    }
  }

  void _drawNorthFleurDeLis(Canvas canvas, Offset center, double length) {
    final paint = Paint()
      ..color = InkTheme.crimsonAccent
      ..style = PaintingStyle.fill;

    final tip = center + Offset(0, -length);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 6, tip.dy + 14)
      ..lineTo(tip.dx, tip.dy + 10)
      ..lineTo(tip.dx + 6, tip.dy + 14)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CompassRosePainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.accentColor != accentColor;
}
