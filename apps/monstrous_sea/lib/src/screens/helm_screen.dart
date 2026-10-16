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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final onOpenChart = widget.onOpenChart;
        final ship = controller.ship;
        final options = controller.currentCourseOptions;
        final currentLeg = controller.currentLeg;
        final totalLegs = controller.totalLegs;
        final regionTitle = controller.seaChart.currentRegionName;

        return ParchmentScaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  style: InkTheme.titleLarge.copyWith(fontSize: 22),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.air,
                            color: InkTheme.inkMuted,
                            size: 24,
                          ),
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
                                  style: InkTheme.caption.copyWith(fontSize: 11.5),
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

                    // Armory Toggle
                    ParchmentCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ARMORY & MUNITIONS', style: InkTheme.statLabel),
                                Text(
                                  'Inspect deck batteries and swap mounted weapons.',
                                  style: InkTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkButton(
                            label: _showingArmory ? 'HIDE ARMORY' : 'MANAGE ARMORY',
                            onPressed: () => setState(() => _showingArmory = !_showingArmory),
                          ),
                        ],
                      ),
                    ),
                    if (_showingArmory) ...[
                      const SizedBox(height: 14),
                      ArmoryView(controller: controller),
                    ],
                    const SizedBox(height: 20),

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
                            onSteer: () => controller.dispatch(
                              SteerCourse(option.bearing),
                            ),
                          ),
                        );
                      }),
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
  });

  final CourseOption option;
  final VoidCallback onSteer;

  @override
  Widget build(BuildContext context) {
    final bearingTitle = switch (option.bearing) {
      NavigationalBearing.larboardTack => 'BEARING EAST-NORTHEAST • LARBOARD TACK',
      NavigationalBearing.deadAhead => 'BEARING DUE EAST • DEAD AHEAD',
      NavigationalBearing.starboardTack => 'BEARING EAST-SOUTHEAST • STARBOARD TACK',
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
              Icon(
                directionIcon,
                color: InkTheme.goldAccent,
                size: 20,
              ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          InkButton(
            label: 'STEER THIS HEADING',
            isPrimary: option.bearing == NavigationalBearing.deadAhead,
            semanticLabel: 'Steer ship heading ${option.bearing.displayName}',
            onPressed: onSteer,
          ),
        ],
      ),
    );
  }
}
