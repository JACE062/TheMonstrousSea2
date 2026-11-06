import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';
import 'pilot_art.dart';
import 'svg_asset_view.dart';

/// Faded illustrations and uncertain coast sketches, without waypoint semantics.
/// Anchors depend only on recorded points; neither offers nor gameplay RNG enter.
class ChartMarginalia extends StatelessWidget {
  const ChartMarginalia({super.key, required this.points});
  final List<Offset> points;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < points.length; i += 10) ...[
            Positioned(
              left: points[i].dx + 145,
              top: points[i].dy - 280,
              width: 300,
              height: 190,
              child: Opacity(
                opacity: .27,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MonstersInscription(
                          InkTheme.subtitle,
                          i == 0
                              ? 'HERE BE MONSTERS'
                              : i % 20 == 0
                              ? 'KEEP A WEATHER EYE'
                              : 'UNSOUNDED WATERS',
                        ),
                      ),
                    ),
                    Positioned(
                      left: 72,
                      top: 66,
                      width: 155,
                      height: 110,
                      child: SvgAssetView(
                        assetPath: i % 30 == 0
                            ? PilotArt.shark
                            : i % 30 == 10
                            ? PilotArt.squid
                            : PilotArt.serpent,
                        width: 155,
                        height: 110,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: points[i].dx + 70,
              top: points[i].dy + 120,
              width: 250,
              height: 165,
              child: Opacity(
                opacity: .24,
                child: CustomPaint(painter: _UncertainCoast(InkTheme.caption)),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _MonstersInscription extends CustomPainter {
  _MonstersInscription(this.style, this.phrase);
  final TextStyle style;
  final String phrase;
  @override
  void paint(Canvas canvas, Size size) {
    final glyphs = [
      for (final letter in phrase.split(''))
        TextPainter(
          text: TextSpan(
            text: letter,
            style: style.copyWith(
              fontSize: 19,
              fontStyle: FontStyle.italic,
              color: InkTheme.inkPrimary,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    const radius = 135.0;
    final total = glyphs.fold(0.0, (width, glyph) => width + glyph.width + 1.8);
    var angle = -math.pi / 2 - total / radius / 2;
    final center = Offset(size.width / 2, 166);
    for (final glyph in glyphs) {
      final advance = (glyph.width + 1.8) / radius;
      final at = angle + advance / 2;
      canvas.save();
      canvas.translate(
        center.dx + math.cos(at) * radius,
        center.dy + math.sin(at) * radius,
      );
      canvas.rotate(at + math.pi / 2);
      glyph.paint(canvas, Offset(-glyph.width / 2, -glyph.height));
      canvas.restore();
      angle += advance;
      glyph.dispose();
    }
  }

  @override
  bool shouldRepaint(_MonstersInscription oldDelegate) =>
      oldDelegate.style != style || oldDelegate.phrase != phrase;
}

class _UncertainCoast extends CustomPainter {
  _UncertainCoast(this.style);
  final TextStyle style;
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = InkTheme.inkPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final shore = Path()
      ..moveTo(14, 69)
      ..cubicTo(18, 33, 46, 61, 51, 37)
      ..cubicTo(60, 5, 80, 45, 98, 20)
      ..cubicTo(114, 3, 129, 47, 144, 32)
      ..cubicTo(174, 9, 163, 66, 197, 56)
      ..cubicTo(234, 45, 207, 84, 224, 99)
      ..cubicTo(238, 126, 192, 112, 179, 129)
      ..cubicTo(164, 148, 139, 115, 119, 133)
      ..cubicTo(93, 150, 94, 110, 66, 124)
      ..cubicTo(36, 136, 50, 99, 25, 99)
      ..cubicTo(6, 99, 30, 83, 14, 69)
      ..close();
    canvas.drawPath(shore, ink);
    canvas.save();
    canvas.clipPath(shore);
    for (var x = 5.0; x < 240; x += 9) {
      canvas.drawLine(
        Offset(x, 15),
        Offset(x - 45, 145),
        ink
          ..color = InkTheme.inkMuted.withValues(alpha: .5)
          ..strokeWidth = .5,
      );
    }
    canvas.restore();
    ink
      ..color = InkTheme.inkPrimary
      ..strokeWidth = 1.2;
    for (final (x, y) in [(83.0, 64.0), (108.0, 57.0), (137.0, 72.0)]) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 12, y + 14)
          ..lineTo(x, y - 9)
          ..lineTo(x + 13, y + 14),
        ink,
      );
      canvas.drawLine(Offset(x, y - 9), Offset(x - 3, y + 6), ink);
    }
    final label = TextPainter(
      text: TextSpan(
        text: 'coast unproved ?',
        style: style.copyWith(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: InkTheme.inkPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset((size.width - label.width) / 2, 143));
    label.dispose();
  }

  @override
  bool shouldRepaint(_UncertainCoast oldDelegate) => oldDelegate.style != style;
}
