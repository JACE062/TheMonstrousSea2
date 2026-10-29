import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/armory_view.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pilot_art.dart';
import '../widgets/svg_asset_view.dart';

/// The quarterdeck helm navigation screen where the captain evaluates
/// the lookout's observations from the crow's nest and steers the ship's heading.
class HelmScreen extends StatefulWidget {
  const HelmScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });

  final GameController controller;
  final VoidCallback onOpenChart;

  @override
  State<HelmScreen> createState() => _HelmScreenState();
}

class _HelmScreenState extends State<HelmScreen> {
  bool _showingArmory = false;
  bool _departing = false;
  Widget? _lastHelmView;

  void _redrawCourses() {
    final controller = widget.controller;
    if (_departing ||
        controller.phase != SessionPhase.helm ||
        !controller.canRedrawStormSeerCourses) {
      return;
    }
    controller.dispatch(const RedrawStormSeerCourses());
  }

  void _steer(NavigationalBearing bearing) {
    if (_departing || widget.controller.phase != SessionPhase.helm) return;
    setState(() => _departing = true);
    try {
      widget.controller.dispatch(SteerCourse(bearing));
    } catch (_) {
      if (mounted) setState(() => _departing = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        // AnimatedSwitcher keeps the outgoing screen alive during its fade.
        // Preserve that rendered view instead of reading the next encounter's
        // mutable chart state, and prevent a second click during departure.
        if (_departing || controller.phase != SessionPhase.helm) {
          return IgnorePointer(
            child: ExcludeFocus(
              child: _lastHelmView ?? const SizedBox.shrink(),
            ),
          );
        }
        final onOpenChart = widget.onOpenChart;
        final ship = controller.ship;
        final options = controller.currentCourseOptions;
        final currentLeg = controller.currentLeg;
        final totalLegs = controller.totalLegs;
        final regionTitle = controller.seaChart.currentRegionName;

        return _lastHelmView = ParchmentScaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        InkButton(
                          label: 'CONSULT SEA CHART',
                          semanticLabel: 'Open dead-reckoning sea chart',
                          onPressed: onOpenChart,
                        ),
                        if (ship != null)
                          Text(
                            'PURSE: ${ship.gold}g',
                            style: InkTheme.statValue.copyWith(
                              color: InkTheme.goldAccent,
                              fontSize: 15,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Header Banner
                    ParchmentCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgAssetView(
                                assetPath: PilotArt.helm,
                                width: 28,
                                height: 28,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  "THE QUARTERDECK • SETTING COURSE",
                                  style: InkTheme.titleLarge.copyWith(
                                    fontSize: 22,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ship?.name ?? 'Vessel'} • $regionTitle (Leg ${currentLeg + 1} of $totalLegs)',
                            style: InkTheme.subtitle.copyWith(
                              color: InkTheme.inkMuted,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Prevailing Gale Notice
                    ParchmentCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.air, color: InkTheme.inkMuted, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PREVAILING OFFSHORE GALE: FRESH WESTERLIES',
                                  style: InkTheme.statValue.copyWith(
                                    fontSize: 13,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'The wind drives your square riggers relentlessly seaward. A lee shore forbids retreat; survival lies in pressing outward.',
                                  style: InkTheme.caption.copyWith(
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hull status
                    if (ship != null) ...[
                      HullGauge(
                        currentHp: ship.currentHp,
                        maxHp: ship.maxHp,
                        label: 'VESSEL HULL VITALITY',
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (controller.canEmergencyRepairAtSea) ...[
                      ParchmentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'EMERGENCY HULL TRIAGE',
                              style: InkTheme.statValue,
                            ),
                            Text(
                              'Patch the hull to 25% integrity before choosing a heading.',
                              style: InkTheme.body,
                            ),
                            InkButton(
                              label:
                                  'PATCH TO 25% · ${controller.emergencyRepairCost}g',
                              onPressed:
                                  ship != null &&
                                      ship.gold >=
                                          controller.emergencyRepairCost
                                  ? () => controller.dispatch(
                                      const RepairShip(0.25),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (controller.activeBoon?.id ==
                        BloodlineTraitId.stormSeer) ...[
                      ParchmentCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('STORM-SEER', style: InkTheme.statLabel),
                            const SizedBox(height: 4),
                            Text(
                              'Read the winds once per region to redraw ordinary headings. Haven, Titan and Nemesis courses hold fast.',
                              style: InkTheme.caption,
                            ),
                            const SizedBox(height: 8),
                            InkButton(
                              key: const ValueKey('storm-seer-redraw'),
                              label: 'READ THE WINDS',
                              compact: true,
                              semanticHint:
                                  controller.stormSeerRedrawRestriction,
                              onPressed: controller.canRedrawStormSeerCourses
                                  ? _redrawCourses
                                  : null,
                            ),
                            if (controller.stormSeerRedrawRestriction
                                case final restriction?) ...[
                              const SizedBox(height: 6),
                              Text(restriction, style: InkTheme.caption),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      options.length == 1
                          ? 'LOOKOUT OBSERVATION • CONVERGENT APPROACH'
                          : 'LOOKOUT OBSERVATIONS & COURSES',
                      style: InkTheme.statValue.copyWith(
                        color: InkTheme.goldAccent,
                        letterSpacing: 1.2,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Course Option Cards
                    if (options.isEmpty)
                      ParchmentCard(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Awaiting the navigator to verify current soundings...',
                            style: InkTheme.body,
                          ),
                        ),
                      )
                    else
                      ...options.map((option) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CourseOptionCard(
                            option: option,
                            restriction: controller.session.courseRestriction(
                              option.bearing,
                            ),
                            onSteer: _departing
                                ? null
                                : () => _steer(option.bearing),
                          ),
                        );
                      }),
                    // Armory Toggle
                    ParchmentCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 500;
                          final description = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SHIP FITTINGS & BELT INSPECTION',
                                style: InkTheme.statLabel,
                              ),
                              Text(
                                'Inspect fitting marks, blessings, refits, and belt supplies.',
                                style: InkTheme.caption,
                              ),
                            ],
                          );
                          return Flex(
                            direction: compact
                                ? Axis.vertical
                                : Axis.horizontal,
                            crossAxisAlignment: compact
                                ? CrossAxisAlignment.stretch
                                : CrossAxisAlignment.center,
                            children: [
                              if (compact)
                                description
                              else
                                Expanded(child: description),
                              SizedBox(
                                width: compact ? 0 : 8,
                                height: compact ? 8 : 0,
                              ),
                              InkButton(
                                label: _showingArmory
                                    ? 'CLOSE INSPECTION'
                                    : 'INSPECT VESSEL',
                                onPressed: () => setState(
                                  () => _showingArmory = !_showingArmory,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (_showingArmory) ...[
                      const SizedBox(height: 14),
                      ArmoryView(controller: controller),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CourseOptionCard extends StatelessWidget {
  const _CourseOptionCard({
    required this.option,
    required this.onSteer,
    this.restriction,
  });

  final CourseOption option;
  final VoidCallback? onSteer;
  final String? restriction;

  @override
  Widget build(BuildContext context) {
    final bearingTitle = switch (option.bearing) {
      NavigationalBearing.larboardTack =>
        'BEARING EAST-NORTHEAST • LARBOARD TACK',
      NavigationalBearing.deadAhead => 'BEARING DUE EAST • DEAD AHEAD',
      NavigationalBearing.starboardTack =>
        'BEARING EAST-SOUTHEAST • STARBOARD TACK',
    };

    final directionIcon = switch (option.bearing) {
      NavigationalBearing.larboardTack => Icons.north_east,
      NavigationalBearing.deadAhead => Icons.east,
      NavigationalBearing.starboardTack => Icons.south_east,
    };

    return ParchmentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with bearing and tag
          Row(
            children: [
              Icon(directionIcon, color: InkTheme.goldAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bearingTitle,
                  style: InkTheme.statValue.copyWith(
                    fontSize: 14,
                    color: InkTheme.inkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (option.isIdentified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: InkTheme.goldAccent.withAlpha(40),
                    border: Border.all(color: InkTheme.goldAccent),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    option.nodeType.displayName.toUpperCase(),
                    style: InkTheme.caption.copyWith(
                      color: InkTheme.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Lookout's Quote
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: InkTheme.parchmentDark.withAlpha(60),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: InkTheme.inkFaint),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“ ',
                  style: TextStyle(
                    fontFamily: 'PirataOne',
                    fontSize: 22,
                    color: InkTheme.goldAccent,
                    height: 0.8,
                  ),
                ),
                Expanded(
                  child: Text(
                    option.lookoutCall,
                    style: InkTheme.body.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Steer Button
          if (restriction != null) ...[
            Text(
              restriction!,
              style: InkTheme.body.copyWith(color: InkTheme.crimsonAccent),
            ),
            const SizedBox(height: 8),
          ],
          Tooltip(
            message: restriction ?? 'Steer ${option.bearing.displayName}',
            child: InkButton(
              label: restriction != null
                  ? 'HEADING UNAVAILABLE'
                  : 'STEER THIS HEADING',
              isPrimary: option.bearing == NavigationalBearing.deadAhead,
              semanticLabel: 'Steer ship heading ${option.bearing.displayName}',
              semanticHint: restriction,
              onPressed: restriction != null ? null : onSteer,
            ),
          ),
        ],
      ),
    );
  }
}
