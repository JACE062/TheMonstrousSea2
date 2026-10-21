import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pilot_art.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/wreck_supplies_view.dart';

/// Screen rendered upon discovering a floating shipwreck derelict,
/// offering tactical choices between salvaging munitions, cracking the gold
/// strongbox, or stripping copper and timbers to reinforce hull vitality.
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
    final ship = controller.ship;
    final wreckName = controller.currentShipwreckName.isNotEmpty
        ? controller.currentShipwreckName
        : 'The Shattered Caravel';
    final hasSalvaged = controller.hasSalvagedCurrentWreck;

    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Navigation Bar
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkButton(
                      label: 'SEA CHART',
                      semanticLabel: 'Open navigation sea chart',
                      onPressed: onOpenChart,
                    ),
                    if (ship != null)
                      Text(
                        'PURSE: ${ship.gold}g',
                        style: InkTheme.statLabel.copyWith(
                          color: InkTheme.goldAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Header
                Center(
                  child: SvgAssetView(
                    assetPath: PilotArt.defeatedMonster,
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  wreckName.toUpperCase(),
                  style: InkTheme.titleLarge.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'A waterlogged derelict floats in the morning mist, rigging trailing in the brine. Hull groans against the swell.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Vessel Vitality
                if (ship != null) ...[
                  ParchmentCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${ship.name} (Tier ${ship.level} ${ship.shipClass.displayName})',
                          style: InkTheme.statValue.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        HullGauge(
                          currentHp: ship.currentHp,
                          maxHp: ship.maxHp,
                          label: 'VESSEL HULL VITALITY',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (!hasSalvaged) ...[
                  Text('CHOOSE SALVAGE OPERATION', style: InkTheme.statLabel),
                  const SizedBox(height: 10),

                  // Choice 1: Munitions
                  ParchmentCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SvgAssetView(
                          assetPath: PilotArt.cannons,
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Search Hold for Materials & Supplies',
                                style: InkTheme.statValue.copyWith(fontSize: 16),
                              ),
                              Text(
                                'Search sealed lockers for salvage materials and usable tactical supplies.',
                                style: InkTheme.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '2–4 Sea Glass • 25% chance: 1 Depth-Wrought Iron • 50% chance: 1 consumable',
                                style: InkTheme.statLabel.copyWith(color: InkTheme.goldAccent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkButton(
                          label: 'SEARCH HOLD',
                          isPrimary: true,
                          onPressed: () => controller.dispatch(
                            const SalvageShipwreck(ShipwreckChoice.munitions),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Choice 2: Strongbox
                  ParchmentCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SvgAssetView(
                          assetPath: PilotArt.treasure,
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Crack the Captain's Strongbox",
                                style: InkTheme.statValue.copyWith(fontSize: 16),
                              ),
                              Text(
                                'Search the waterlogged captain\'s cabin and pick the lock on the reinforced iron chest.',
                                style: InkTheme.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '60–120 gold doubloons + 2–4 Sea Glass',
                                style: InkTheme.statLabel.copyWith(color: InkTheme.goldAccent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkButton(
                          label: 'CRACK CHEST',
                          isPrimary: true,
                          onPressed: () => controller.dispatch(
                            const SalvageShipwreck(ShipwreckChoice.strongbox),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Choice 3: Timbers
                  ParchmentCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SvgAssetView(
                          assetPath: PilotArt.anchor,
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Strip Copper & Stout Oak Timbers',
                                style: InkTheme.statValue.copyWith(fontSize: 16),
                              ),
                              Text(
                                'Pry intact hull planks, iron brackets, and copper sheathing to patch your own battle scars.',
                                style: InkTheme.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Restore up to 25% max hull (healing penalties apply) + 1–2 Sea Glass',
                                style: InkTheme.statLabel.copyWith(color: InkTheme.greenAccent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkButton(
                          label: 'STRIP TIMBERS',
                          isPrimary: true,
                          onPressed: () => controller.dispatch(
                            const SalvageShipwreck(ShipwreckChoice.timbers),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Salvaged Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: InkTheme.goldAccent.withValues(alpha: 0.12),
                      border: Border.all(color: InkTheme.goldAccent, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'SALVAGE COMPLETE',
                          style: InkTheme.titleLarge.copyWith(
                            color: InkTheme.goldAccent,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.session.wreckSalvageReceipt.join('\n'),
                          style: InkTheme.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (controller.pendingLoot.isNotEmpty) ...[
                    WreckSuppliesView(controller: controller),
                    const SizedBox(height: 16),
                  ],
                  // Depart only after explicitly resolving any overflow.
                  InkButton(
                    label: 'LEAVE WRECK & TAKE THE HELM',
                    semanticLabel: 'Leave the salvaged derelict and take the helm to set course',
                    isPrimary: true,
                    onPressed: controller.pendingLoot.isNotEmpty
                        ? null
                        : () => controller.dispatch(const TakeHelm()),
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
