import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/ink_theme.dart';

/// Renders rolling oceanic swells using antique woodcut-style undulating ink lines.
class AnimatedWavePainter extends CustomPainter {
  const AnimatedWavePainter({
    required this.progress,
    this.waveColor = InkTheme.inkMuted,
  });

  final double progress; // 0.0 to 1.0 animation cycle
  final Color waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final basePaint = Paint()
      ..color = waveColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final crestPaint = Paint()
      ..color = InkTheme.inkPrimary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Draw 4 tiers of animated waves across the height
    for (var tier = 0; tier < 4; tier++) {
      final yBase = size.height * (0.35 + tier * 0.2);
      final amplitude = 8.0 + tier * 3.0;
      final frequency = 0.02 - tier * 0.002;
      final phase = progress * 2 * pi + tier * (pi / 2);

      final path = Path();
      var first = true;

      for (var x = 0.0; x <= size.width; x += 4.0) {
        final y = yBase + sin(x * frequency + phase) * amplitude;
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, tier.isEven ? basePaint : crestPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.waveColor != waveColor;
}
