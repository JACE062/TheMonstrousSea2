import 'package:flutter/material.dart';
import '../../theme/ink_theme.dart';

/// Renders aged paper fiber markings and subtle chart vignetting.
class ParchmentTexturePainter extends CustomPainter {
  const ParchmentTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Subtle edge aging / burnished vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.transparent,
          InkTheme.parchmentDark.withValues(alpha: 0.35),
        ],
        stops: const [0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);

    // Subtle paper fibers (deterministic diagonal strokes)
    final fiberPaint = Paint()
      ..color = InkTheme.inkMuted.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final step = 28.0;
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.7, size.height),
        fiberPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParchmentTexturePainter oldDelegate) => false;
}
