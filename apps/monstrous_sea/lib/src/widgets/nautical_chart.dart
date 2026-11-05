import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import 'pilot_art.dart';
import 'painters/sea_chart_paper_painter.dart';
import 'svg_asset_view.dart';

String voyageOutcomeLabel(VoyageLegRecord entry) => [
  if (entry.combatWon) 'VICTORY',
  if (entry.wreckPassed) 'PASSED WRECK',
  if (entry.wreckRecovered) 'CARGO RECOVERED',
  if (!entry.combatWon && !entry.wreckPassed && !entry.wreckRecovered)
    'ARRIVED',
].join(' · ');

String voyageDestinationLabel(VoyageLegRecord entry) => entry.isNemesis
    ? 'Nemesis'
    : switch (entry.destination) {
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

/// At most twice the route's padded vertical span can be visible. Flat wakes
/// retain a legible minimum paper height; their horizontal extent needs panning.
double chartMinimumScale(NauticalRouteGeometry route, double viewportHeight) =>
    (viewportHeight /
            (2 *
                math.max(
                  viewportHeight,
                  math.max(320, route.bounds.height + 200),
                )))
        .clamp(.06, 1.0);

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
    this.expandViewport = false,
    this.coursePanel,
  });
  final SeaChart chart;
  final ShipState? ship;
  final bool isInPort;
  final bool Function()? takeMotion;
  final double? viewportHeight;
  final bool expandViewport;
  final Widget? coursePanel;
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
        .min(1.0, scene.viewport.height / bounds.height)
        .clamp(chartMinimumScale(scene.route, scene.viewport.height), 1.0);
    final wide = bounds.width * scale > scene.viewport.width;
    final center = scene.at(wide ? scene.route.points.last : bounds.center);
    final target = wide
        ? Offset(scene.viewport.width * .68, scene.viewport.height / 2)
        : scene.viewport.center(Offset.zero);
    _camera.value = _view(scale, target - center * scale);
    _userMoved = false;
  }

  void _locate() {
    final scene = _scene;
    if (scene == null) return;
    _camera.value = _view(
      1,
      Offset(scene.viewport.width * .68, scene.viewport.height / 2) -
          scene.at(scene.route.points.last),
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
      _zoomTo(_camera.value.getMaxScaleOnAxis());
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

  void _zoomTo(double scale) {
    final scene = _scene;
    if (scene == null) return;
    final focal = scene.viewport.center(Offset.zero);
    final world = _camera.toScene(focal);
    final bounded = scale.clamp(
      chartMinimumScale(scene.route, scene.viewport.height),
      3.0,
    );
    _camera.value = _view(bounded, focal - world * bounded);
  }

  Widget _sceneContents(_ChartScene scene) {
    final route = scene.route;
    final points = route.points.map(scene.at).toList();
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
        : (points.last - points[points.length - 2]).direction;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _SeaPaperPainter(scene.offset)),
        ),
        Positioned.fill(child: CustomPaint(painter: _WakePainter(points))),
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
            style: InkTheme.statLabel.copyWith(fontSize: 10),
          ),
        ),
        for (var i = 0; i < route.history.length; i++)
          Positioned(
            left: points[i + 1].dx - 23,
            top: points[i + 1].dy - 23,
            child: Tooltip(
              key: ValueKey('voyage-marker-$i'),
              message:
                  'Region ${route.history[i].regionIndex + 1} · Leg ${route.history[i].leg}: ${voyageDestinationLabel(route.history[i])} · ${voyageOutcomeLabel(route.history[i])}',
              child: Semantics(
                label:
                    'Leg ${route.history[i].leg}, ${voyageOutcomeLabel(route.history[i])}',
                child: _WaypointArt(entry: route.history[i]),
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
                    : PilotArt.forShip(widget.ship!),
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
            style: InkTheme.statLabel.copyWith(fontSize: 11),
          ),
        ),
        if (widget.isInPort && route.history.isNotEmpty)
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
  }

  Widget _viewport(NauticalRouteGeometry route) => LayoutBuilder(
    builder: (context, bounds) {
      final panelWidth = widget.coursePanel == null
          ? 0.0
          : math.min(380.0, bounds.maxWidth * .35);
      return CustomPaint(
        painter: const SeaChartPaperPainter(),
        child: ClipPath(
          clipper: const SeaChartPaperClipper(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, inner) {
                    final scene = _ChartScene(
                      route,
                      Size(
                        math.max(
                          140,
                          inner.maxWidth -
                              (panelWidth > 0 ? panelWidth + 24 : 0),
                        ),
                        inner.maxHeight,
                      ),
                    );
                    _configure(scene);
                    return Focus(
                      focusNode: _mapFocus,
                      onKeyEvent: _key,
                      child: Semantics(
                        label: 'Travelled sea chart. Drag to pan, scroll to zoom. Arrow keys pan; Home frames the route; End locates the vessel.',
                        // InteractiveViewer handles wheel scaling eagerly. Claim the
                        // signal before a parent Scrollable can also scroll the page.
                        child: Listener(
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent) {
                              GestureBinding.instance.pointerSignalResolver
                                  .register(event, (_) {});
                            }
                          },
                          child: InteractiveViewer(
                            key: const ValueKey('nautical-map-viewport'),
                            transformationController: _camera,
                            constrained: false,
                            minScale: chartMinimumScale(
                              route,
                              scene.viewport.height,
                            ),
                            maxScale: 3,
                            boundaryMargin: const EdgeInsets.all(
                              double.infinity,
                            ),
                            onInteractionStart: (_) {
                              _userMoved = true;
                              _mapFocus.requestFocus();
                            },
                            child: SizedBox(
                              width: scene.size.width,
                              height: scene.size.height,
                              child: AnimatedBuilder(
                                animation: _motion,
                                builder: (context, _) => _sceneContents(scene),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 32,
                bottom: 32,
                child: IgnorePointer(
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: _CompassRosePainter(InkTheme.statLabel),
                    ),
                  ),
                ),
              ),
              if (widget.coursePanel != null)
                Positioned(
                  top: 32,
                  bottom: 32,
                  right: 32,
                  width: panelWidth,
                  child: widget.coursePanel!,
                ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final route = NauticalRouteGeometry(widget.chart.voyageLog);
    return LayoutBuilder(
      builder: (context, bounds) {
        final expands =
            widget.expandViewport ||
            (widget.viewportHeight == null && bounds.hasBoundedHeight);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, bounds) {
                final title = Text(
                  'TRAVELLED WATERS',
                  style: InkTheme.titleMedium.copyWith(fontSize: 23),
                );
                final controls = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const ValueKey('zoom-out-chart'),
                      tooltip: 'Zoom out',
                      onPressed: () {
                        _zoomTo(_camera.value.getMaxScaleOnAxis() / 1.25);
                        _userMoved = true;
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      key: const ValueKey('zoom-in-chart'),
                      tooltip: 'Zoom in',
                      onPressed: () {
                        _zoomTo(_camera.value.getMaxScaleOnAxis() * 1.25);
                        _userMoved = true;
                      },
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      key: const ValueKey('fit-nautical-route'),
                      tooltip: 'Frame route height (Home)',
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
                );
                return bounds.maxWidth < 560
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          title,
                          Align(
                            alignment: Alignment.centerRight,
                            child: controls,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: title),
                          controls,
                        ],
                      );
              },
            ),
            Text(
              'Drag to explore · Scroll or pinch to zoom',
              style: InkTheme.caption,
            ),
            const SizedBox(height: 8),
            if (expands)
              Expanded(child: _viewport(route))
            else
              SizedBox(
                height:
                    widget.viewportHeight ??
                    (MediaQuery.sizeOf(context).width < 600 ? 300 : 420),
                child: _viewport(route),
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
      },
    );
  }
}

class _WaypointArt extends StatelessWidget {
  const _WaypointArt({required this.entry});
  final VoyageLegRecord entry;

  String? get _asset {
    if (entry.combatWon) return PilotArt.defeatedMonster;
    if (entry.wreckRecovered) return PilotArt.treasure;
    return switch (entry.destination) {
      CourseDestination.midpointHaven => PilotArt.portHaven,
      CourseDestination.repairRefit => PilotArt.anchor,
      CourseDestination.specialistMerchant => PilotArt.freighter,
      _ => switch (entry.nodeType) {
        EncounterNodeType.respiteIsland => PilotArt.portHaven,
        EncounterNodeType.shipwreckSalvage => PilotArt.treasure,
        EncounterNodeType.smugglerTrader => PilotArt.freighter,
        EncounterNodeType.ancientShrine => null,
        _ =>
          entry.monsterSpecies == null
              ? PilotArt.cannons
              : PilotArt.forSpecies(entry.monsterSpecies!),
      },
    };
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 46,
    height: 46,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: InkTheme.chartPaperLight.withValues(alpha: .8),
            shape: BoxShape.circle,
            border: Border.all(
              color: entry.isNemesis
                  ? InkTheme.crimsonAccent
                  : InkTheme.inkMuted.withValues(alpha: .65),
            ),
          ),
          child: Opacity(
            opacity: entry.wreckPassed ? .45 : 1,
            child: _asset != null
                ? SvgAssetView(assetPath: _asset!, width: 46, height: 46)
                : const SizedBox(
                    width: 46,
                    height: 46,
                    child: CustomPaint(painter: _ShrineMarkPainter()),
                  ),
          ),
        ),
        if (entry.combatWon && entry.wreckRecovered)
          const Positioned(
            right: -8,
            bottom: -5,
            child: SvgAssetView(
              assetPath: PilotArt.treasure,
              width: 23,
              height: 23,
            ),
          ),
        if (entry.wreckPassed)
          const Positioned.fill(
            child: CustomPaint(painter: _PassedMarkPainter()),
          ),
      ],
    ),
  );
}

class _PassedMarkPainter extends CustomPainter {
  const _PassedMarkPainter();
  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
    Offset(4, size.height - 4),
    Offset(size.width - 4, 4),
    Paint()
      ..color = InkTheme.inkMuted
      ..strokeWidth = 1.5,
  );
  @override
  bool shouldRepaint(_PassedMarkPainter oldDelegate) => false;
}

/// Structural shrine engraving, pending the separate curated entity-art pass.
class _ShrineMarkPainter extends CustomPainter {
  const _ShrineMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = InkTheme.inkPrimary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(9, 18)
        ..lineTo(23, 8)
        ..lineTo(37, 18)
        ..close(),
      ink,
    );
    canvas.drawRect(const Rect.fromLTWH(12, 20, 22, 15), ink);
    for (final x in [16.0, 23.0, 30.0]) {
      canvas.drawLine(Offset(x, 21), Offset(x, 34), ink);
    }
    canvas.drawLine(const Offset(9, 38), const Offset(37, 38), ink);
    canvas.drawCircle(const Offset(23, 14), 2, ink);
  }

  @override
  bool shouldRepaint(_ShrineMarkPainter oldDelegate) => false;
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
    canvas.save();
    canvas.scale(size.width / 76, size.height / 76);
    const center = Offset(38, 38);
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompassRosePainter old) => old.style != style;
}
