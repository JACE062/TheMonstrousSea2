import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/armory_view.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pause_menu.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/pilot_art.dart';

/// Screen allowing captain to rest upon the open swell, inspect vessel,
/// inspect fixed fittings and tactical belt supplies, and choose their next move.
class RestScreen extends StatelessWidget {
  const RestScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });

  final GameController controller;
  final VoidCallback onOpenChart;

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    final seaChart = controller.seaChart;

    return ParchmentScaffold(
      showPauseButton: false,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'RESPITE ON THE OPEN SEA',
                            style: InkTheme.titleLarge.copyWith(fontSize: 32),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'The waves lap gently against the timbers as the crew catches breath.',
                            style: InkTheme.subtitle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const PauseMenuButton(),
                  ],
                ),
                const SizedBox(height: 24),

                if (ship != null) ...[
                  // 1. Vessel Status Card
                  ParchmentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgAssetView(
                              assetPath: PilotArt.forShip(ship),
                              width: 80,
                              height: 80,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ship.name, style: InkTheme.titleMedium),
                                  Text(
                                    'Leg ${seaChart.currentLeg} of ${seaChart.totalLegs} • ${seaChart.currentRegionName}',
                                    style: InkTheme.caption,
                                  ),
                                  const SizedBox(height: 8),
                                  HullGauge(
                                    currentHp: ship.currentHp,
                                    maxHp: ship.maxHp,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statColumn('GOLD CARRIED', '${ship.gold}g'),
                            _statColumn(
                              'TACTICAL BELT',
                              '${ship.cargo.length} / ${ship.maxCargo}',
                            ),
                            _statColumn(
                              'BATTERIES',
                              '${ship.equippedWeapons.length} / ${ship.maxHardpointSlots} Mounts',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. Fixed hardpoint and tactical belt inspection
                  ArmoryView(controller: controller),
                  const SizedBox(height: 18),

                  // 3. Carpenter's Emergency Triage (Open Ocean)
                  ParchmentCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "CARPENTER'S WORKBENCH",
                              style: InkTheme.statLabel.copyWith(
                                color: controller.canEmergencyRepairAtSea
                                    ? InkTheme.crimsonAccent
                                    : InkTheme.inkPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (controller.canEmergencyRepairAtSea)
                              Text(
                                'CRITICAL HULL (< 25%)',
                                style: InkTheme.caption.copyWith(
                                  color: InkTheme.crimsonAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.canEmergencyRepairAtSea
                              ? 'Hull integrity is critical! The carpenter can hammer emergency cross-beams and canvas tar to patch the hull to the 25% seaworthy floor.'
                              : 'Open ocean swells are too turbulent for hull careening. Seek a Respite Island for hull careening and a voyage shipwright for refits.',
                          style: InkTheme.caption,
                        ),
                        if (controller.canEmergencyRepairAtSea) ...[
                          const SizedBox(height: 10),
                          InkButton(
                            label:
                                'EMERGENCY TRIAGE (${controller.emergencyRepairCost}g)',
                            semanticLabel: 'Perform emergency carpenter triage to restore hull to 25% floor',
                            isPrimary: true,
                            onPressed:
                                (ship.gold >= controller.emergencyRepairCost)
                                ? () => controller.dispatch(
                                    const RepairShip(0.25),
                                  )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Chart button
                InkButton(
                  label: 'CONSULT SEA CHART',
                  icon: const SvgAssetView(
                    assetPath: PilotArt.cannons,
                    width: 22,
                    height: 22,
                  ),
                  onPressed: onOpenChart,
                ),
                const SizedBox(height: 16),

                // Primary Next Move Choice (No retreat; the wind drives relentlessly outward)
                InkButton(
                  label:
                      (seaChart.currentRow == SeaChart.bossRow &&
                          seaChart.currentCol == SeaChart.bossCol &&
                          controller.isCurrentEncounterDefeated)
                      ? (seaChart.currentRegionIndex < SeaChart.totalRegions - 1
                            ? 'ENTER ${SeaChart.strongholdName(seaChart.currentRegionIndex + 1).toUpperCase()} (STRONGHOLD)'
                            : 'CLAIM EXPEDITION VICTORY!')
                      : 'TAKE THE HELM & SET COURSE',
                  isPrimary: true,
                  onPressed: () => controller.dispatch(
                    (seaChart.currentRow == SeaChart.bossRow &&
                            seaChart.currentCol == SeaChart.bossCol &&
                            controller.isCurrentEncounterDefeated)
                        ? const AdvanceToNextBattle()
                        : const TakeHelm(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: InkTheme.statLabel.copyWith(fontSize: 12.5)),
        const SizedBox(height: 2),
        Text(value, style: InkTheme.statValue.copyWith(fontSize: 16)),
      ],
    );
  }
}
