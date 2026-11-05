import 'dart:math' as math;

import 'package:flutter/material.dart';
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

IconData _discoveryIcon(VoyageLegRecord entry) => switch (entry.nodeType) {
  EncounterNodeType.respiteIsland => Icons.anchor,
  EncounterNodeType.smugglerTrader => Icons.storefront_outlined,
  EncounterNodeType.ancientShrine => Icons.auto_awesome_outlined,
  EncounterNodeType.shipwreckSalvage => Icons.directions_boat_outlined,
  _ => Icons.circle_outlined,
};

/// Stable chart geometry uses only committed history, never offers or RNG.
Offset routePoint(
  VoyageLegRecord entry,
  Size size,
  int titanLeg, {
  int firstLeg = 0,
}) {
  final side = switch (entry.bearing) {
    NavigationalBearing.larboardTack => -1,
    NavigationalBearing.deadAhead => 0,
    NavigationalBearing.starboardTack => 1,
  };
  return Offset(
    size.width * (.5 + .27 * side),
    size.height -
        35 -
        (entry.leg - firstLeg) / (titanLeg - firstLeg) * (size.height - 75),
  );
}

Path routeSegment(Offset from, Offset to, double center) => Path()
  ..moveTo(from.dx, from.dy)
  ..cubicTo(
    center,
    from.dy - (from.dy - to.dy) * .45,
    center,
    to.dy + (from.dy - to.dy) * .45,
    to.dx,
    to.dy,
  );

class NauticalChart extends StatefulWidget {
  const NauticalChart({
    super.key,
    required this.chart,
    this.ship,
    this.isInPort = false,
    this.takeMotion,
  });
  final SeaChart chart;
  final ShipState? ship;
  final bool isInPort;
  final bool Function()? takeMotion;
  @override
  State<NauticalChart> createState() => _NauticalChartState();
}

class _NauticalChartState extends State<NauticalChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );
  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final pending = widget.takeMotion?.call() ?? false;
      if (pending && !MediaQuery.disableAnimationsOf(context)) {
        _motion.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chart = widget.chart;
    final regionalHistory = widget.isInPort
        ? <VoyageLegRecord>[]
        : chart.voyageLog
              .where((entry) => entry.regionIndex == chart.currentRegionIndex)
              .toList();
    final history = regionalHistory.length > 7
        ? regionalHistory.sublist(regionalHistory.length - 7)
        : regionalHistory;
    final firstLeg = history.isEmpty ? 0 : math.max(0, history.first.leg - 1);
    final endLeg = math.max(
      firstLeg + 1,
      history.isEmpty ? 0 : history.last.leg,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('TRAVELLED WATERS', style: InkTheme.titleMedium),
        Text(
          'Onward with the prevailing wind. Side tacks rejoin the outward course; route length adds no encounters.',
          style: InkTheme.caption,
        ),
        if (regionalHistory.length > history.length)
          Text(
            'Recent wake · earlier soundings in the voyage log',
            style: InkTheme.caption,
          ),
        SizedBox(
          height: MediaQuery.sizeOf(context).width < 600
              ? 210
              : MediaQuery.sizeOf(context).height < 750
              ? 240
              : 330,
          child: LayoutBuilder(
            builder: (context, bounds) {
              final size = Size(bounds.maxWidth, bounds.maxHeight);
              final markerSize = MediaQuery.sizeOf(context).width < 600
                  ? 16.0
                  : 24.0;
              final origin = Offset(size.width / 2, size.height - 12);
              final points = history
                  .map((e) => routePoint(e, size, endLeg, firstLeg: firstLeg))
                  .toList();
              final last = points.isEmpty ? origin : points.last;
              final previous = points.length < 2
                  ? origin
                  : points[points.length - 2];
              final lastSegment = routeSegment(previous, last, size.width / 2);
              return AnimatedBuilder(
                animation: _motion,
                builder: (context, _) {
                  var vessel = last;
                  if (points.isNotEmpty && _motion.value < 1) {
                    final metric = lastSegment.computeMetrics().first;
                    vessel =
                        metric
                            .getTangentForOffset(
                              metric.length *
                                  Curves.easeInOut.transform(_motion.value),
                            )
                            ?.position ??
                        last;
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WakePainter(origin, points),
                        ),
                      ),
                      Positioned(
                        left: origin.dx - 18,
                        top: origin.dy - 26,
                        child: const SvgAssetView(
                          assetPath: PilotArt.portHaven,
                          width: 36,
                          height: 36,
                        ),
                      ),
                      for (var i = 0; i < history.length; i++)
                        Positioned(
                          left: points[i].dx - markerSize / 2,
                          top: points[i].dy - markerSize / 2,
                          child: Tooltip(
                            message:
                                'Region ${history[i].regionIndex + 1} · Leg ${history[i].leg}: ${voyageDestinationLabel(history[i])} · ${voyageOutcomeLabel(history[i])}',
                            child: Semantics(
                              label:
                                  'Leg ${history[i].leg}, ${voyageOutcomeLabel(history[i])}',
                              child: Container(
                                width: markerSize,
                                height: markerSize,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: InkTheme.parchmentSurface,
                                  shape: history[i].combatWon
                                      ? BoxShape.rectangle
                                      : BoxShape.circle,
                                  border: Border.all(
                                    color: history[i].wreckPassed
                                        ? InkTheme.inkMuted
                                        : InkTheme.goldAccent,
                                    width: 1.5,
                                  ),
                                ),
                                child: history[i].combatWon
                                    ? SvgAssetView(
                                        assetPath: PilotArt.defeatedMonster,
                                        width: markerSize - 2,
                                        height: markerSize - 2,
                                      )
                                    : Icon(
                                        history[i].wreckRecovered
                                            ? Icons.inventory_2_outlined
                                            : history[i].wreckPassed
                                            ? Icons.close
                                            : _discoveryIcon(history[i]),
                                        size: 16,
                                        color: InkTheme.inkPrimary,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      for (var i = 0; i < history.length; i++)
                        if (history[i].combatWon && history[i].wreckRecovered)
                          Positioned(
                            left: points[i].dx + markerSize / 2 - 3,
                            top: points[i].dy,
                            child: Tooltip(
                              message: 'Cargo recovered after victory',
                              child: Container(
                                color: InkTheme.parchmentSurface,
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                      Positioned(
                        left: vessel.dx + 13,
                        top: vessel.dy - 20,
                        child: Semantics(
                          label: 'Current vessel',
                          child: Column(
                            children: [
                              SvgAssetView(
                                assetPath: widget.ship == null
                                    ? PilotArt.standard
                                    : PilotArt.forShip(widget.ship!),
                                width: 42,
                                height: 34,
                              ),
                              Text(
                                'VESSEL',
                                style: InkTheme.statLabel.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final (icon, label) in [
              (Icons.circle_outlined, 'Arrival'),
              (Icons.close, 'Passed'),
              (Icons.inventory_2_outlined, 'Cargo'),
              (Icons.flag_outlined, 'Victory'),
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: InkTheme.inkMuted),
                  const SizedBox(width: 3),
                  Text(label, style: InkTheme.caption),
                ],
              ),
          ],
        ),
        if (chart.voyageLog.any(
          (e) => e.regionIndex < chart.currentRegionIndex,
        ))
          Text(
            'Earlier regions remain in the voyage log.',
            style: InkTheme.caption,
          ),
      ],
    );
  }
}

class _WakePainter extends CustomPainter {
  _WakePainter(this.origin, this.points);
  final Offset origin;
  final List<Offset> points;
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = InkTheme.inkMuted
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    var from = origin;
    for (final point in points) {
      for (final metric in routeSegment(
        from,
        point,
        size.width / 2,
      ).computeMetrics()) {
        for (var distance = 0.0; distance < metric.length; distance += 8) {
          canvas.drawPath(
            metric.extractPath(distance, math.min(distance + 3, metric.length)),
            ink,
          );
        }
      }
      from = point;
    }
  }

  @override
  bool shouldRepaint(_WakePainter old) =>
      old.origin != origin || old.points != points;
}
