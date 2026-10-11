import 'package:flutter/material.dart';
import '../../theme/ink_theme.dart';

/// Renders authentic double-ruled nautical cartouche borders with corner flourishes.
class CartoucheBorderPainter extends CustomPainter {
  const CartoucheBorderPainter({
    this.borderColor = InkTheme.inkPrimary,
    this.margin = 8.0,
    this.strokeWidth = 1.5,
  });

  final Color borderColor;
  final double margin;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= margin * 2 || size.height <= margin * 2) return;

    final outerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final innerPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.7;

    // Outer Rect
    final outerRect = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );
    canvas.drawRect(outerRect, outerPaint);

    // Inner Rect
    const inset = 4.0;
    if (outerRect.width > inset * 2 && outerRect.height > inset * 2) {
      final innerRect = outerRect.deflate(inset);
      canvas.drawRect(innerRect, innerPaint);
    }

    // Corner Ornaments / Rosettes
    const cornerSize = 10.0;
    _drawCornerFlourish(canvas, outerRect.left, outerRect.top, cornerSize, 1, 1);
    _drawCornerFlourish(canvas, outerRect.right, outerRect.top, cornerSize, -1, 1);
    _drawCornerFlourish(canvas, outerRect.left, outerRect.bottom, cornerSize, 1, -1);
    _drawCornerFlourish(canvas, outerRect.right, outerRect.bottom, cornerSize, -1, -1);
  }

  void _drawCornerFlourish(
    Canvas canvas,
    double x,
    double y,
    double s,
    double dx,
    double dy,
  ) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    // Small corner square
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: 4, height: 4),
      paint,
    );

    // Diagonal bracket line
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(x + dx * s, y)
      ..lineTo(x + dx * (s * 0.4), y + dy * (s * 0.4))
      ..lineTo(x, y + dy * s);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CartoucheBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.margin != margin ||
      oldDelegate.strokeWidth != strokeWidth;
}
