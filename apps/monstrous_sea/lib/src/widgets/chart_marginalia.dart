import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';
import 'pilot_art.dart';
import 'svg_asset_view.dart';

/// Faded illustrations and uncertain coast sketches, without waypoint semantics.
/// Anchors depend only on recorded points; neither offers nor gameplay RNG enter.
class ChartMarginalia extends StatelessWidget {
  const ChartMarginalia({
    super.key,
    required this.points,
    this.regionVisits = const [],
  });
  final List<Offset> points;
  final List<({int regionIndex, Offset point})> regionVisits;

  bool _hasRegionalArt(Offset point) => regionVisits.any(
    (visit) => visit.regionIndex > 0 && visit.point.dx <= point.dx,
  );

  // Regional illustrations use committed visits, never the active region or
  // offered courses. They remain anchored when another visit is appended.
  List<Widget> _regionalIllustrations() {
    final occupied = [
      for (var i = 0; i < points.length; i += 10) ...[
        Rect.fromLTWH(points[i].dx + 145, points[i].dy - 280, 300, 190),
        if (!_hasRegionalArt(points[i]))
          Rect.fromLTWH(points[i].dx + 70, points[i].dy + 120, 250, 165),
      ],
    ];
    final illustrations = <Widget>[];
    void add(
      String key,
      String asset,
      Rect target,
      double opacity, {
      bool above = false,
    }) {
      final direction = above ? -1.0 : 1.0;
      for (final shift in [0.0, direction * 190, direction * 380]) {
        final rect = target.shift(Offset(0, shift));
        if (occupied.any((other) => other.inflate(16).overlaps(rect)) ||
            points.any(
              (point) => Rect.fromCenter(
                center: point,
                width: 100,
                height: 100,
              ).overlaps(rect),
            )) {
          continue;
        }
        occupied.add(rect);
        illustrations.add(
          Positioned.fromRect(
            rect: rect,
            child: Opacity(
              opacity: opacity,
              child: SvgAssetView(
                key: ValueKey(key),
                assetPath: asset,
                width: rect.width,
                height: rect.height,
              ),
            ),
          ),
        );
        break;
      }
    }

    for (final region in [1, 2]) {
      final visits = regionVisits
          .where((visit) => visit.regionIndex == region)
          .toList();
      for (var i = 0; i < visits.length; i += 6) {
        final anchor = visits[i].point;
        if (region == 1) {
          add(
            'chart-kelp-$i',
            PilotArt.sargassoKelp,
            Rect.fromLTWH(anchor.dx - 110, anchor.dy + 115, 220, 170),
            .26,
          );
          add(
            'chart-fog-$i',
            PilotArt.fog,
            Rect.fromLTWH(anchor.dx - 120, anchor.dy - 260, 240, 150),
            .22,
            above: true,
          );
        } else {
          add(
            'chart-caldera-$i',
            PilotArt.reachCaldera,
            Rect.fromLTWH(anchor.dx - 130, anchor.dy + 115, 260, 190),
            .27,
          );
        }
      }
    }
    return illustrations;
  }

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
            if (!_hasRegionalArt(points[i]))
              Positioned(
                left: points[i].dx + 70,
                top: points[i].dy + 120,
                width: 250,
                height: 165,
                child: Opacity(
                  opacity: .24,
                  child: CustomPaint(
                    painter: _UncertainCoast(InkTheme.caption),
                  ),
                ),
              ),
          ],
          ..._regionalIllustrations(),
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
