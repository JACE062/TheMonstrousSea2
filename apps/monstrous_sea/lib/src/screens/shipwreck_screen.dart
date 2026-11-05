import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/hull_patch_kit_button.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pilot_art.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/wreck_supplies_view.dart';

/// Presents the core's condition, recovery commitment and one cargo receipt.
class ShipwreckScreen extends StatelessWidget {
  const ShipwreckScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });
  final GameController controller;
  final VoidCallback onOpenChart;

  @override
  Widget build(BuildContext context) {
    final wreck = controller.session.currentWreck;
    final ship = controller.ship;
    if (wreck == null || ship == null) {
      return const ParchmentScaffold(
        body: Center(child: Text('Wreck state unavailable.')),
      );
    }
    final id = wreck.id;
    void choose(WreckRecoveryChoice choice) =>
        controller.dispatch(ChooseWreckRecovery(id, choice));
    final condition = switch (wreck.condition) {
      WreckCondition.pickedClean => 'PICKED-CLEAN WRECK',
      WreckCondition.uncertain => 'UNCERTAIN WRECK',
      WreckCondition.fresh => 'FRESH WRECK',
    };
    final assessment = switch (wreck.condition) {
      WreckCondition.pickedClean =>
        'The open holds have been stripped. Only a small, quick haul remains.',
      WreckCondition.uncertain => 'Take the modest accessible salvage and leave, or forego it and linger for the deeper cargo.',
      WreckCondition.fresh => 'The fresh cargo lies below. Recovering it takes a deliberate commitment; you can still sail past empty.',
    };
    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    InkButton(label: 'SEA CHART', onPressed: onOpenChart),
                    Text('PURSE: ${ship.gold}g', style: InkTheme.statLabel),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(
                  child: SvgAssetView(
                    assetPath: PilotArt.treasure,
                    width: 56,
                    height: 56,
                  ),
                ),
                Text(
                  controller.currentShipwreckName.toUpperCase(),
                  style: InkTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  condition,
                  style: InkTheme.statValue,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                HullGauge(
                  currentHp: ship.currentHp,
                  maxHp: ship.maxHp,
                  label: 'VESSEL HULL VITALITY',
                ),
                CarriedPatchKits(controller: controller),
                const SizedBox(height: 20),
                if (wreck.stage == WreckStage.assessment) ...[
                  ParchmentCard(child: Text(assessment, style: InkTheme.body)),
                  const SizedBox(height: 12),
                  if (wreck.condition != WreckCondition.fresh) ...[
                    InkButton(
                      label: 'QUICK SALVAGE & LEAVE',
                      isPrimary: true,
                      onPressed: () => choose(WreckRecoveryChoice.quickSalvage),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (wreck.condition != WreckCondition.pickedClean) ...[
                    ParchmentCard(
                      child: Text(
                        'COMMITTED RECOVERY: High chance of a creature fight. An Apex predator may appear. Species and tier remain unknown until it appears.${wreck.condition == WreckCondition.uncertain ? ' You cannot take the quick haul as well.' : ''}',
                        style: InkTheme.body.copyWith(
                          color: InkTheme.crimsonAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkButton(
                      label: wreck.condition == WreckCondition.fresh
                          ? 'COMMIT TO RECOVERY'
                          : 'LINGER FOR DEEPER CARGO',
                      onPressed: () =>
                          choose(WreckRecoveryChoice.deeperRecovery),
                    ),
                    const SizedBox(height: 12),
                  ],
                  InkButton(
                    label: 'SAIL PAST EMPTY',
                    onPressed: () => choose(WreckRecoveryChoice.passBy),
                  ),
                ] else if (wreck.stage == WreckStage.recovery) ...[
                  ParchmentCard(
                    child: Text(
                      wreck.condition == WreckCondition.pickedClean
                          ? 'THREAT CLEARED. The remaining small haul is ready to recover. There is no further fight here.'
                          : 'THREAT CLEARED. The full wreck cargo is ready to recover. No further risk choice or fight remains.',
                      style: InkTheme.body,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkButton(
                    label: 'RECOVER CARGO',
                    isPrimary: true,
                    onPressed: () =>
                        choose(WreckRecoveryChoice.recoverClearedCargo),
                  ),
                ] else if (wreck.stage == WreckStage.receipt) ...[
                  ParchmentCard(
                    child: Column(
                      children: [
                        Text('SALVAGE COMPLETE', style: InkTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          controller.session.wreckSalvageReceipt.join('\n'),
                          style: InkTheme.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.pendingLoot.isNotEmpty) ...[
                    WreckSuppliesView(controller: controller),
                    const SizedBox(height: 16),
                  ],
                  InkButton(
                    label: 'LEAVE WRECK & TAKE THE HELM',
                    isPrimary: true,
                    onPressed: controller.pendingLoot.isNotEmpty
                        ? null
                        : () => choose(WreckRecoveryChoice.depart),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
