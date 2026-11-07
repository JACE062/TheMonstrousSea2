import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import 'pilot_art.dart';
import 'chart_camera.dart';
import 'chart_marginalia.dart';
import 'painters/sea_chart_paper_painter.dart';
import 'painters/sea_chart_water_painter.dart';
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
  NauticalRouteGeometry(
    Iterable<VoyageLegRecord> entries, {
    int regionIndex = 0,
  }) : history = List.unmodifiable(entries) {
    var point = Offset.zero;
    points.add(point);
    wakePoints.add(point);
    void berth(int region) {
      point += const Offset(92, 0);
      ports.add((regionIndex: region, position: point));
      wakePoints.add(point);
    }

    int? previousRegion;
    for (final entry in history) {
      if (previousRegion != null && entry.regionIndex > previousRegion) {
        berth(entry.regionIndex);
      }
      final lateral = switch (entry.bearing) {
        NavigationalBearing.larboardTack => -64.0,
        NavigationalBearing.deadAhead => 0.0,
        NavigationalBearing.starboardTack => 64.0,
      };
      point += Offset(92, lateral);
      points.add(point);
      wakePoints.add(point);
      previousRegion = entry.regionIndex;
    }
    // Region advancement confirms an arrived stronghold, including before the
    // next encounter. This adds no serialized visit or numbered leg.
    if (regionIndex > (previousRegion ?? 0)) berth(regionIndex);
    var minX = 0.0, minY = 0.0, maxX = 0.0, maxY = 0.0;
    for (final p in wakePoints) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }
    bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  final List<VoyageLegRecord> history;
  final List<Offset> points = [];
  final List<Offset> wakePoints = [];
  final List<({int regionIndex, Offset position})> ports = [];
  Offset get currentPosition => wakePoints.last;
  late final Rect bounds;
}

/// Keep 46-unit markers at least 41 logical pixels wide at every route length.
const nauticalChartMinimumScale = .9;
const nauticalChartMaximumScale = 3.0;
// The vessel illustration sits above its arrival node.
const _vesselCenterOffset = Offset(0, -23);

double nauticalCoursePanelWidth(double width) => width * .3;

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
    this.coursePanelWidth,
  });
  final SeaChart chart;
  final ShipState? ship;
  final bool isInPort;
  final bool Function()? takeMotion;
  final double? viewportHeight;
  final bool expandViewport;
  final Widget? coursePanel;
  final double? coursePanelWidth;
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
  final _camera = NauticalCameraController();
  final _mapFocus = FocusNode(debugLabel: 'Nautical map');
  _ChartScene? _scene;
  Object? _sceneKey;
  bool _userMoved = false;

  Matrix4 _view(double scale, Offset translation) => Matrix4.identity()
    ..setEntry(0, 0, scale)
    ..setEntry(1, 1, scale)
    ..setEntry(2, 2, scale)
    ..setTranslationRaw(translation.dx, translation.dy, 0);
  void _centerJourney() {
    final scene = _scene;
    if (scene == null) return;
    final scale = _camera.value.getMaxScaleOnAxis().clamp(
      nauticalChartMinimumScale,
      nauticalChartMaximumScale,
    );
    _camera.value = _view(
      scale,
      scene.viewport.center(Offset.zero) -
          scene.at(scene.route.bounds.center) * scale,
    );
    _userMoved = true;
  }

  void _locate() {
    final scene = _scene;
    if (scene == null) return;
    final scale = _camera.value.getMaxScaleOnAxis().clamp(
      nauticalChartMinimumScale,
      nauticalChartMaximumScale,
    );
    _camera.value = _view(
      scale,
      scene.viewport.center(Offset.zero) -
          (scene.at(scene.route.currentPosition) + _vesselCenterOffset) * scale,
    );
    _userMoved = true;
  }

  void _configure(_ChartScene scene) {
    _camera.bounds = NauticalCameraBounds(
      travelled: scene.route.bounds,
      viewport: scene.viewport,
      sceneOffset: scene.offset,
      minimumScale: nauticalChartMinimumScale,
      maximumScale: nauticalChartMaximumScale,
    );
    final key = (Object.hashAll(scene.route.wakePoints), scene.viewport);
    if (key == _sceneKey) {
      _scene = scene;
      return;
    }
    final previous = _scene;
    _sceneKey = key;
    _scene = scene;
    if (previous == null) {
      _locate();
      _userMoved = false;
      final pending = widget.takeMotion?.call() ?? false;
      if (pending && !MediaQuery.disableAnimationsOf(context)) {
        _motion.forward(from: 0);
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sceneKey != key) return;
      if (!_userMoved) {
        _locate();
        _userMoved = false;
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
      _centerJourney();
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
      nauticalChartMinimumScale,
      nauticalChartMaximumScale,
    );
    _camera.value = _view(bounded, focal - world * bounded);
  }

  Widget _sceneContents(_ChartScene scene) {
    final route = scene.route;
    final points = route.points.map(scene.at).toList();
    final wake = route.wakePoints.map(scene.at).toList();
    var vessel = wake.last;
    if (wake.length > 1 && _motion.value < 1) {
      vessel = Offset.lerp(
        wake[wake.length - 2],
        wake.last,
        Curves.easeInOut.transform(_motion.value),
      )!;
    }
    final heading = wake.length < 2
        ? 0.0
        : (wake.last - wake[wake.length - 2]).direction;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ChartMarginalia(
            points: wake,
            regionVisits: [
              for (var i = 0; i < route.history.length; i++)
                (
                  regionIndex: route.history[i].regionIndex,
                  point: points[i + 1],
                ),
            ],
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _WakePainter(wake))),
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
          left: points.first.dx - 24,
          width: 180,
          top: points.first.dy + 28,
          child: Text(
            SeaChart.strongholdName(0),
            key: const ValueKey('chart-home-port-label'),
            textAlign: TextAlign.start,
            style: InkTheme.statLabel.copyWith(fontSize: 11),
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
          top: vessel.dy + _vesselCenterOffset.dy - 20,
          child: Semantics(
            key: const ValueKey('chart-current-vessel'),
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
        for (final port in route.ports)
          Positioned(
            left: scene.at(port.position).dx - 23,
            top: scene.at(port.position).dy - 23,
            child: Tooltip(
              key: ValueKey('chart-port-${port.regionIndex}'),
              message: SeaChart.strongholdName(port.regionIndex),
              child: const SvgAssetView(
                assetPath: PilotArt.portHaven,
                width: 46,
                height: 46,
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
          : widget.coursePanelWidth ??
                nauticalCoursePanelWidth(bounds.maxWidth);
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
                        label: 'Sea chart of travelled waters.',
                        // InteractiveViewer handles wheel scaling eagerly. Claim the
                        // signal before a parent Scrollable can also scroll the page.
                        child: Listener(
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent) {
                              GestureBinding.instance.pointerSignalResolver
                                  .register(event, (_) {});
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                key: const ValueKey('chart-moving-waters'),
                                painter: SeaChartWaterPainter(
                                  camera: _camera,
                                  worldOffset: scene.offset,
                                ),
                              ),
                              InteractiveViewer(
                                key: const ValueKey('nautical-map-viewport'),
                                transformationController: _camera,
                                constrained: false,
                                minScale: nauticalChartMinimumScale,
                                maxScale: nauticalChartMaximumScale,
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
                                    builder: (context, _) =>
                                        _sceneContents(scene),
                                  ),
                                ),
                              ),
                            ],
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
              Positioned(
                left: 32,
                top: bounds.maxHeight < 400 ? 32 : null,
                bottom: bounds.maxHeight < 400 ? null : 132,
                child: _controls(),
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

  Widget _controls() => DecoratedBox(
    decoration: BoxDecoration(
      color: InkTheme.parchmentSurface.withValues(alpha: .96),
      border: Border.all(color: InkTheme.inkMuted),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('zoom-out-chart'),
          tooltip: 'Zoom out',
          onPressed: () {
            _zoomTo(_camera.value.getMaxScaleOnAxis() / 1.25);
            _userMoved = true;
          },
          icon: const CustomPaint(
            size: Size(24, 24),
            painter: _ChartToolPainter(zoom: -1),
          ),
        ),
        IconButton(
          key: const ValueKey('zoom-in-chart'),
          tooltip: 'Zoom in',
          onPressed: () {
            _zoomTo(_camera.value.getMaxScaleOnAxis() * 1.25);
            _userMoved = true;
          },
          icon: const CustomPaint(
            size: Size(24, 24),
            painter: _ChartToolPainter(zoom: 1),
          ),
        ),
        IconButton(
          key: const ValueKey('fit-nautical-route'),
          tooltip: 'Center journey',
          onPressed: _centerJourney,
          icon: const SvgAssetView(
            assetPath: PilotArt.centerJourney,
            width: 28,
            height: 28,
          ),
        ),
        IconButton(
          key: const ValueKey('locate-chart-vessel'),
          tooltip: 'Find vessel',
          onPressed: _locate,
          icon: const SvgAssetView(
            assetPath: PilotArt.standard,
            width: 28,
            height: 28,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final route = NauticalRouteGeometry(
      widget.chart.voyageLog,
      regionIndex: widget.chart.currentRegionIndex,
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        final expands =
            widget.expandViewport ||
            (widget.viewportHeight == null && bounds.hasBoundedHeight);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (expands)
              Expanded(child: _viewport(route))
            else
              SizedBox(
                height:
                    widget.viewportHeight ??
                    (MediaQuery.sizeOf(context).width < 600 ? 300 : 420),
                child: _viewport(route),
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

class _ChartToolPainter extends CustomPainter {
  const _ChartToolPainter({required this.zoom});
  final int zoom;
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = InkTheme.inkPrimary
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (zoom == 0) {
      final c = size.center(Offset.zero);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, 2)
          ..lineTo(size.width - 2, c.dy)
          ..lineTo(c.dx, size.height - 2)
          ..lineTo(2, c.dy)
          ..close(),
        ink,
      );
      canvas.drawCircle(c, 3, ink);
      canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, 6), ink);
      canvas.drawLine(Offset(0, c.dy), Offset(6, c.dy), ink);
    } else {
      const c = Offset(9, 9);
      canvas.drawCircle(c, 7, ink);
      canvas.drawLine(const Offset(14, 14), const Offset(22, 22), ink);
      canvas.drawLine(const Offset(5, 9), const Offset(13, 9), ink);
      if (zoom > 0) {
        canvas.drawLine(const Offset(9, 5), const Offset(9, 13), ink);
      }
    }
  }

  @override
  bool shouldRepaint(_ChartToolPainter oldDelegate) => oldDelegate.zoom != zoom;
}
