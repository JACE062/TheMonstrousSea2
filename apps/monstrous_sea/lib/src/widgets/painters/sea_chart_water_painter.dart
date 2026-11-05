import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/ink_theme.dart';

/// Engraved markings share the route's world transform. Paint visible waters,
/// including negative/far coordinates, instead of a finite route-sized tile.
class SeaChartWaterPainter extends CustomPainter {
  SeaChartWaterPainter({required this.camera, required this.worldOffset})
    : super(repaint: camera);
  final TransformationController camera;
  final Offset worldOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = camera.value;
    final scale = matrix.getMaxScaleOnAxis();
    final origin =
        Offset(matrix.storage[12], matrix.storage[13]) + worldOffset * scale;
    final visible = Rect.fromLTRB(
      -origin.dx / scale,
      -origin.dy / scale,
      (size.width - origin.dx) / scale,
      (size.height - origin.dy) / scale,
    ).inflate(100);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    final grid = Paint()
      ..color = InkTheme.chartEdge.withValues(alpha: .14)
      ..strokeWidth = .7;
    for (
      var x = (visible.left / 94).floor();
      x <= (visible.right / 94).ceil();
      x++
    ) {
      canvas.drawLine(
        Offset(x * 94.0, visible.top),
        Offset(x * 94.0, visible.bottom),
        grid,
      );
    }
    for (
      var y = (visible.top / 94).floor();
      y <= (visible.bottom / 94).ceil();
      y++
    ) {
      canvas.drawLine(
        Offset(visible.left, y * 94.0),
        Offset(visible.right, y * 94.0),
        grid,
      );
    }
    final reach =
        [
          visible.topLeft,
          visible.topRight,
          visible.bottomLeft,
          visible.bottomRight,
        ].map((p) => p.distance).reduce(math.max) +
        100;
    for (var ray = 0; ray < 16; ray++) {
      final angle = ray * math.pi / 8;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle), math.sin(angle)) * reach,
        Paint()
          ..color = InkTheme.chartEdge.withValues(alpha: .09)
          ..strokeWidth = .8,
      );
    }
    final fold = Paint()
      ..color = InkTheme.chartEdge.withValues(alpha: .07)
      ..strokeWidth = 2;
    for (
      var x = (visible.left / 920).floor();
      x <= (visible.right / 920).ceil();
      x++
    ) {
      canvas.drawLine(
        Offset(x * 920.0 + 460, visible.top),
        Offset(x * 920.0 + 460, visible.bottom),
        fold,
      );
    }
    final waves = Paint()
      ..color = InkTheme.inkMuted.withValues(alpha: .2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (
      var x = (visible.left / 110).floor();
      x <= (visible.right / 110).ceil();
      x++
    ) {
      for (
        var y = (visible.top / 90).floor();
        y <= (visible.bottom / 90).ceil();
        y++
      ) {
        if ((x * 17 + y * 31).abs() % 7 > 3) continue;
        final p = Offset(x * 110.0 + 25, y * 90.0 + 22);
        for (var row = 0; row < 2; row++) {
          final dy = p.dy + row * 6;
          canvas.drawPath(
            Path()
              ..moveTo(p.dx, dy)
              ..quadraticBezierTo(p.dx + 5, dy - 4, p.dx + 10, dy)
              ..quadraticBezierTo(p.dx + 15, dy + 4, p.dx + 20, dy),
            waves,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SeaChartWaterPainter oldDelegate) =>
      oldDelegate.camera != camera || oldDelegate.worldOffset != worldOffset;
}
