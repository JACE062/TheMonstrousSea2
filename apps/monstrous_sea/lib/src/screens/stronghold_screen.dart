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
import '../widgets/voyage_shipwright_view.dart';

/// A mid-voyage berth. Permanent ancestral progression stays at the home port.
class StrongholdScreen extends StatelessWidget {
  const StrongholdScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });

  final GameController controller;
  final VoidCallback onOpenChart;


  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ParchmentScaffold(
      showPauseButton: false,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: PauseMenuButton(),
                ),
                Text(
                  controller.seaChart.currentPortName.toUpperCase(),
                  style: InkTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Voyage stronghold · ${controller.seaChart.currentRegionName}',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                if (controller.ship case final ship?) ...[
                  ParchmentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(ship.name, style: InkTheme.titleMedium),
                        Text(
                          'Captain ${controller.captainName} · Purse: ${ship.gold}g',
                          style: InkTheme.body,
                        ),
                        HullGauge(currentHp: ship.currentHp, maxHp: ship.maxHp),
                        const SizedBox(height: 12),
                        Text(
                          'Your voyage continues. Refit the vessel, replenish supplies, and prepare for the next region.',
                          style: InkTheme.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InkButton(
                        label: 'MERCHANT',
                        onPressed: () =>
                            controller.dispatch(const VisitMerchant()),
                      ),
                      InkButton(
                        label: 'REPAIR +${controller.repairHpFor(1.0)} HP · ${controller.repairCostFor(1.0)}g',
                        onPressed:
                            ship.currentHp < ship.maxHp &&
                                ship.gold >= controller.repairCostFor(1.0)
                            ? () => controller.dispatch(const RepairShip(1.0))
                            : null,
                      ),
                      InkButton(label: 'SEA CHART', onPressed: onOpenChart),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkButton(
                    label:
                        'SET SAIL FOR ${controller.seaChart.currentRegionName.toUpperCase()}',
                    isPrimary: true,
                    onPressed: () => controller.dispatch(const TakeHelm()),
                  ),
                  const SizedBox(height: 18),
                  VoyageShipwrightView(controller: controller),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(
                      'SHIP FITTINGS & BELT INSPECTION',
                      style: InkTheme.statLabel,
                    ),
                    children: [ArmoryView(controller: controller)],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
