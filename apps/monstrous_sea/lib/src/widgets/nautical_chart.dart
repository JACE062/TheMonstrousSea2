import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import 'pilot_art.dart';
import 'svg_asset_view.dart';

String voyageOutcomeLabel(VoyageLegRecord entry) => [
  if (entry.combatWon) 'VICTORY',
  if (entry.wreckPassed) 'PASSED WRECK',
  if (entry.wreckRecovered) 'CARGO RECOVERED',
  if (!entry.combatWon && !entry.wreckPassed && !entry.wreckRecovered)
    'ARRIVED',
].join(' · ');

String voyageDestinationLabel(VoyageLegRecord entry) =>
    switch (entry.destination) {
      CourseDestination.midpointHaven => 'Midpoint Haven',
      CourseDestination.repairRefit => 'Repair / refit',
      CourseDestination.specialistMerchant => 'Specialist merchant',
      CourseDestination.titan => 'Regional Titan',
      CourseDestination.ordinary => entry.nodeType.displayName,
    };

/// World positions accumulate from the previous ship position. East is forward,
/// port is north, and starboard south, matching the existing lookout bearings.
class NauticalRouteGeometry {
  NauticalRouteGeometry(Iterable<VoyageLegRecord> entries)
    : history = List.unmodifiable(entries) {
    var point = Offset.zero;
    points.add(point);
    for (final entry in history) {
      final lateral = switch (entry.bearing) {
        NavigationalBearing.larboardTack => -64.0,
        NavigationalBearing.deadAhead => 0.0,
        NavigationalBearing.starboardTack => 64.0,
      };
      point += Offset(92, lateral);
      points.add(point);
    }
    var minX = 0.0, minY = 0.0, maxX = 0.0, maxY = 0.0;
    for (final p in points) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }
    bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  final List<VoyageLegRecord> history;
  final List<Offset> points = [];
  late final Rect bounds;
}

Path routeSegment(Offset from, Offset to) => Path()
  ..moveTo(from.dx, from.dy)
  ..lineTo(to.dx, to.dy);

class NauticalChart extends StatefulWidget {
  const NauticalChart({
    super.key,
    required this.chart,
    this.ship,
    this.isInPort = false,
    this.takeMotion,
    this.viewportHeight,
  });
  final SeaChart chart;
  final ShipState? ship;
  final bool isInPort;
  final bool Function()? takeMotion;
  final double? viewportHeight;
  @override
  State<NauticalChart> createState() => _NauticalChartState();
}

class _ChartScene {
  _ChartScene(this.route, this.viewport) {
    final paper = route.bounds.inflate(100);
    size = Size(
      math.max(viewport.width, paper.width),
      math.max(viewport.height, paper.height),
    );
    offset = Offset(
      -paper.left + (size.width - paper.width) / 2,
      -paper.top + (size.height - paper.height) / 2,
    );
  }
  final NauticalRouteGeometry route;
  final Size viewport;
  late final Size size;
  late final Offset offset;
  Offset at(Offset world) => world + offset;
}

class _NauticalChartState extends State<NauticalChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );
  final _camera = TransformationController();
  final _mapFocus = FocusNode(debugLabel: 'Nautical map');
  _ChartScene? _scene;
  Object? _sceneKey;
  bool _userMoved = false;

  Matrix4 _view(double scale, Offset translation) => Matrix4.identity()
    ..setEntry(0, 0, scale)
    ..setEntry(1, 1, scale)
    ..setTranslationRaw(translation.dx, translation.dy, 0);
  void _fit(_ChartScene scene) {
    final bounds = scene.route.bounds.inflate(100);
    final scale = math
        .min(
          scene.viewport.width / bounds.width,
          scene.viewport.height / bounds.height,
        )
        .clamp(.06, 1.0);
    final center = scene.at(bounds.center);
    _camera.value = _view(
      scale,
      scene.viewport.center(Offset.zero) - center * scale,
    );
    _userMoved = false;
  }

  void _locate() {
    final scene = _scene;
    if (scene == null) return;
    _camera.value = _view(
      1,
      scene.viewport.center(Offset.zero) - scene.at(scene.route.points.last),
    );
    _userMoved = true;
  }

  void _configure(_ChartScene scene) {
    final key = (Object.hashAll(scene.route.points), scene.viewport);
    if (key == _sceneKey) {
      _scene = scene;
      return;
    }
    final previous = _scene;
    _sceneKey = key;
    _scene = scene;
    if (previous == null) {
      _fit(scene);
      final pending = widget.takeMotion?.call() ?? false;
      if (pending && !MediaQuery.disableAnimationsOf(context)) {
        _motion.forward(from: 0);
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sceneKey != key) return;
      if (!_userMoved) {
        _fit(scene);
        return;
      }
      // Rebase growing paper without moving the world under a panned viewport.
      final scale = _camera.value.getMaxScaleOnAxis();
      final delta = (previous.offset - scene.offset) * scale;
      final matrix = _camera.value.clone();
      matrix.storage[12] += delta.dx;
      matrix.storage[13] += delta.dy;
      _camera.value = matrix;
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      if (_scene != null) _fit(_scene!);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      _locate();
      return KeyEventResult.handled;
    }
    final shift = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => const Offset(50, 0),
      LogicalKeyboardKey.arrowRight => const Offset(-50, 0),
      LogicalKeyboardKey.arrowUp => const Offset(0, 50),
      LogicalKeyboardKey.arrowDown => const Offset(0, -50),
      _ => null,
    };
    if (shift == null) return KeyEventResult.ignored;
    final matrix = _camera.value.clone();
    matrix.storage[12] += shift.dx;
    matrix.storage[13] += shift.dy;
    _camera.value = matrix;
    _userMoved = true;
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _motion.dispose();
    _camera.dispose();
    _mapFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = NauticalRouteGeometry(widget.chart.voyageLog);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'TRAVELLED WATERS',
                style: InkTheme.titleMedium.copyWith(fontSize: 23),
              ),
            ),
            IconButton(
              key: const ValueKey('fit-nautical-route'),
              tooltip: 'Fit travelled route (Home)',
              onPressed: () {
                if (_scene != null) _fit(_scene!);
              },
              icon: const Icon(Icons.fit_screen),
            ),
            IconButton(
              key: const ValueKey('locate-chart-vessel'),
              tooltip: 'Locate vessel (End)',
              onPressed: _locate,
              icon: const Icon(Icons.my_location),
            ),
          ],
        ),
        Text(
          'Drag to explore · Scroll or pinch to zoom',
          style: InkTheme.caption,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height:
              widget.viewportHeight ??
              (MediaQuery.sizeOf(context).width < 600 ? 270 : 350),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final scene = _ChartScene(
                route,
                Size(bounds.maxWidth, bounds.maxHeight),
              );
              _configure(scene);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: InkTheme.parchmentHighlight,
                  border: Border.all(color: InkTheme.inkMuted),
                ),
                child: Stack(
                  children: [
                    Focus(
                      focusNode: _mapFocus,
                      onKeyEvent: _key,
                      child: Semantics(
                        label: 'Travelled sea chart. Drag to pan, scroll to zoom. Arrow keys pan; Home fits the route; End locates the vessel.',
                        child: InteractiveViewer(
                          key: const ValueKey('nautical-map-viewport'),
                          transformationController: _camera,
                          constrained: false,
                          minScale: .06,
                          maxScale: 3,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          onInteractionStart: (_) {
                            _userMoved = true;
                            _mapFocus.requestFocus();
                          },
                          child: SizedBox(
                            width: scene.size.width,
                            height: scene.size.height,
                            child: AnimatedBuilder(
                              animation: _motion,
                              builder: (context, _) {
                                final points = route.points
                                    .map(scene.at)
                                    .toList();
                                var vessel = points.last;
                                if (points.length > 1 && _motion.value < 1) {
                                  vessel = Offset.lerp(
                                    points[points.length - 2],
                                    points.last,
                                    Curves.easeInOut.transform(_motion.value),
                                  )!;
                                }
                                final heading = points.length < 2
                                    ? 0.0
                                    : (points.last - points[points.length - 2])
                                          .direction;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _SeaPaperPainter(scene.offset),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _WakePainter(points),
                                      ),
                                    ),
                                    Positioned(
                                      left: points.first.dx - 23,
                                      top: points.first.dy - 23,
                                      child: const SvgAssetView(
                                        assetPath: PilotArt.portHaven,
                                        width: 46,
                                        height: 46,
                                      ),
                                    ),
                                    Positioned(
                                      left: points.first.dx - 36,
                                      top: points.first.dy + 28,
                                      child: Text(
                                        'DEPARTURE',
                                        style: InkTheme.statLabel.copyWith(
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    for (
                                      var i = 0;
                                      i < route.history.length;
                                      i++
                                    )
                                      Positioned(
                                        left: points[i + 1].dx - 18,
                                        top: points[i + 1].dy - 18,
                                        child: Tooltip(
                                          message:
                                              'Region ${route.history[i].regionIndex + 1} · Leg ${route.history[i].leg}: ${voyageDestinationLabel(route.history[i])} · ${voyageOutcomeLabel(route.history[i])}',
                                          child: Semantics(
                                            label:
                                                'Leg ${route.history[i].leg}, ${voyageOutcomeLabel(route.history[i])}',
                                            child: _WaypointArt(
                                              entry: route.history[i],
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      left: vessel.dx - 26,
                                      top: vessel.dy - 43,
                                      child: Semantics(
                                        label: 'Current vessel',
                                        child: Transform.rotate(
                                          angle: heading,
                                          child: SvgAssetView(
                                            assetPath: widget.ship == null
                                                ? PilotArt.standard
                                                : PilotArt.forShip(
                                                    widget.ship!,
                                                  ),
                                            width: 52,
                                            height: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: vessel.dx + 19,
                                      top: vessel.dy + 15,
                                      child: Text(
                                        'VESSEL',
                                        style: InkTheme.statLabel.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    if (widget.isInPort &&
                                        route.history.isNotEmpty)
                                      Positioned(
                                        left: points.last.dx + 35,
                                        top: points.last.dy + 30,
                                        child: Tooltip(
                                          message: widget.chart.currentPortName,
                                          child: const SvgAssetView(
                                            assetPath: PilotArt.portHaven,
                                            width: 40,
                                            height: 40,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: IgnorePointer(
                        child: SizedBox(
                          width: 76,
                          height: 76,
                          child: CustomPaint(
                            painter: _CompassRosePainter(InkTheme.statLabel),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text('Arrival', style: InkTheme.caption),
            Text('Passed wreck', style: InkTheme.caption),
            Text('Cargo recovered', style: InkTheme.caption),
            Text('Skull: victory', style: InkTheme.caption),
          ],
        ),
      ],
    );
  }
}

class _WaypointArt extends StatelessWidget {
  const _WaypointArt({required this.entry});
  final VoyageLegRecord entry;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 36,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: CustomPaint(painter: _WaypointPainter(entry))),
        if (entry.combatWon)
          const Center(
            child: SvgAssetView(
              assetPath: PilotArt.defeatedMonster,
              width: 28,
              height: 28,
            ),
          ),
        if (entry.combatWon && entry.wreckRecovered)
          Positioned(
            right: -7,
            bottom: -5,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(
                painter: _WaypointPainter(entry, cargoOnly: true),
              ),
            ),
          ),
      ],
    ),
  );
}

class _WaypointPainter extends CustomPainter {
  _WaypointPainter(this.entry, {this.cargoOnly = false});
  final VoyageLegRecord entry;
  final bool cargoOnly;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 36, size.height / 36);
    final ink = Paint()
      ..color = entry.wreckPassed ? InkTheme.inkMuted : InkTheme.inkPrimary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(
      const Offset(18, 18),
      17,
      Paint()..color = InkTheme.parchmentSurface,
    );
    canvas.drawCircle(const Offset(18, 18), 17, ink);
    void line(double x, double y, double x2, double y2) =>
        canvas.drawLine(Offset(x, y), Offset(x2, y2), ink);
    if (cargoOnly || entry.wreckRecovered && !entry.combatWon) {
      canvas.drawRect(const Rect.fromLTWH(9, 10, 18, 17), ink);
      line(9, 10, 27, 27);
      line(9, 27, 27, 10);
      line(9, 15, 27, 15);
    } else if (!entry.combatWon) {
      switch (entry.nodeType) {
        case EncounterNodeType.respiteIsland:
          canvas.drawArc(
            const Rect.fromLTWH(5, 23, 26, 12),
            math.pi,
            math.pi,
            false,
            ink,
          );
          line(18, 25, 20, 9);
          line(20, 9, 10, 13);
          line(20, 9, 29, 14);
          line(20, 9, 13, 7);
          line(20, 9, 26, 6);
        case EncounterNodeType.smugglerTrader:
          canvas.drawPath(
            Path()
              ..moveTo(6, 23)
              ..lineTo(12, 29)
              ..lineTo(25, 29)
              ..lineTo(30, 23)
              ..close(),
            ink,
          );
          line(18, 23, 18, 7);
          canvas.drawPath(
            Path()
              ..moveTo(19, 8)
              ..lineTo(28, 20)
              ..lineTo(19, 20)
              ..close(),
            ink,
          );
        case EncounterNodeType.ancientShrine:
          canvas.drawPath(
            Path()
              ..moveTo(6, 14)
              ..lineTo(18, 6)
              ..lineTo(30, 14)
              ..close(),
            ink,
          );
          for (final x in [11.0, 18.0, 25.0]) {
            line(x, 16, x, 27);
          }
          line(7, 29, 29, 29);
        case EncounterNodeType.shipwreckSalvage:
          canvas.drawPath(
            Path()
              ..moveTo(5, 22)
              ..lineTo(11, 29)
              ..lineTo(25, 29)
              ..lineTo(31, 22),
            ink,
          );
          line(18, 22, 15, 15);
          line(15, 15, 20, 12);
          line(20, 12, 17, 6);
          line(8, 22, 13, 20);
          line(23, 20, 28, 22);
        default:
          line(10, 28, 26, 8);
          line(10, 8, 26, 28);
          line(21, 8, 26, 8);
          line(26, 8, 27, 13);
      }
      if (entry.wreckPassed) line(5, 31, 31, 5);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaypointPainter old) =>
      old.entry != entry || old.cargoOnly != cargoOnly;
}

class _WakePainter extends CustomPainter {
  _WakePainter(this.points);
  final List<Offset> points;
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = InkTheme.inkPrimary.withValues(alpha: .65)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < points.length; i++) {
      for (final metric in routeSegment(
        points[i - 1],
        points[i],
      ).computeMetrics()) {
        for (var distance = 0.0; distance < metric.length; distance += 9) {
          canvas.drawPath(
            metric.extractPath(distance, math.min(distance + 3, metric.length)),
            ink,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_WakePainter old) => old.points != points;
}

class _SeaPaperPainter extends CustomPainter {
  _SeaPaperPainter(this.offset);
  final Offset offset;
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = InkTheme.inkMuted.withValues(alpha: .18)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (
      var x = ((-offset.dx) / 110).floor();
      x < (size.width - offset.dx) / 110;
      x++
    ) {
      for (
        var y = ((-offset.dy) / 90).floor();
        y < (size.height - offset.dy) / 90;
        y++
      ) {
        if ((x * 17 + y * 31).abs() % 7 > 3) continue;
        final p = Offset(x * 110 + offset.dx + 25, y * 90 + offset.dy + 22);
        for (var row = 0; row < 2; row++) {
          canvas.drawPath(
            Path()
              ..moveTo(p.dx, p.dy + row * 6)
              ..quadraticBezierTo(
                p.dx + 5,
                p.dy - 4 + row * 6,
                p.dx + 10,
                p.dy + row * 6,
              )
              ..quadraticBezierTo(
                p.dx + 15,
                p.dy + 4 + row * 6,
                p.dx + 20,
                p.dy + row * 6,
              ),
            ink,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SeaPaperPainter old) => old.offset != offset;
}

class _CompassRosePainter extends CustomPainter {
  _CompassRosePainter(this.style);
  final TextStyle style;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ink = Paint()
      ..color = InkTheme.inkPrimary
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 17, ink);
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final tip =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (i.isEven ? 26 : 18);
      final left =
          center + Offset(math.cos(angle - .4), math.sin(angle - .4)) * 5;
      final right =
          center + Offset(math.cos(angle + .4), math.sin(angle + .4)) * 5;
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(center.dx, center.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(path, ink);
    }
    for (final (label, position) in [
      ('N', const Offset(38, 3)),
      ('E', const Offset(70, 38)),
      ('S', const Offset(38, 71)),
      ('W', const Offset(5, 38)),
    ]) {
      final text = TextPainter(
        text: TextSpan(text: label, style: style.copyWith(fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, position - Offset(text.width / 2, text.height / 2));
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(_CompassRosePainter old) => old.style != style;
}
