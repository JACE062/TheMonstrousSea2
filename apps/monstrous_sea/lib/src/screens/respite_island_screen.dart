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

/// Screen rendered when anchoring at a calm Respite Island haven,
/// offering free hull careening, gunnery drills, island shipwright refits,
/// and tactical armory management before venturing back into open ocean.
class RespiteIslandScreen extends StatefulWidget {
  const RespiteIslandScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });

  final GameController controller;
  final VoidCallback onOpenChart;

  @override
  State<RespiteIslandScreen> createState() => _RespiteIslandScreenState();
}

class _RespiteIslandScreenState extends State<RespiteIslandScreen> {
  bool _showingArmory = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final ship = controller.ship;
    final islandName = controller.currentIslandName.isNotEmpty
        ? controller.currentIslandName
        : 'Cormorant Key';
    final hasChosenDuty = controller.session.hasChosenIslandDuty;
    final hasCareened = controller.hasCareenedAtCurrentIsland;
    final hasDrilled = controller.hasDrilledAtCurrentIsland;
    final hasForaged = controller.session.hasForagedAtCurrentIsland;
    final hasBoon = controller.gunneryAccuracyBoon > 0;
    final canCareen = !hasChosenDuty && ship != null && ship.currentHp < ship.maxHp;
    final canDrill = !hasChosenDuty;
    final canForage = !hasChosenDuty;

    final upgradeCost = ship != null && ship.level < 4
        ? calculateShipUpgradeCost(ship.level)
        : null;
    final canAffordUpgrade = upgradeCost != null && (ship?.gold ?? 0) >= upgradeCost;

    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkButton(
                      label: 'SEA CHART',
                      semanticLabel: 'Open navigation sea chart',
                      onPressed: widget.onOpenChart,
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

                // Island Header
                Center(
                  child: SvgAssetView(
                    assetPath: PilotArt.portHaven,
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.isCurrentIslandHaven
                      ? 'GRAND HAVEN: ${islandName.toUpperCase()}'
                      : 'SECLUDED COVE: ${islandName.toUpperCase()}',
                  style: InkTheme.titleLarge.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                Text(
                  controller.isCurrentIslandHaven
                      ? 'Calm sheltered deep-water soundings and verdant sanctuary cliffs. A grand haven of safety.'
                      : 'A small uncharted atoll and tranquil sandy spit offering emergency respite from the storm.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Vessel Vitality & Status
                if (ship != null) ...[
                  ParchmentCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${ship.name} (Tier ${ship.level} ${ship.shipClass.displayName})',
                              style: InkTheme.statValue.copyWith(fontSize: 16),
                            ),
                            if (hasBoon)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: InkTheme.goldAccent.withValues(alpha: 0.15),
                                  border: Border.all(color: InkTheme.goldAccent),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${controller.gunneryAccuracyBoon}% GUNNERY BOON ACTIVE',
                                  style: InkTheme.caption.copyWith(
                                    color: InkTheme.goldAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
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
                  const SizedBox(height: 20),
                ],

                // Island Action Cards Grid
                Text(
                  hasChosenDuty
                      ? 'CREW SHORE DUTY COMPLETED (PREPARING TO DEPART)'
                      : 'CREW SHORE DUTY (CHOOSE ONE BEFORE TIDE TURNS)',
                  style: InkTheme.statValue.copyWith(
                    color: hasChosenDuty ? InkTheme.inkMuted : InkTheme.goldAccent,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),

                // 1. Careen Hull Card
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
                              'Careen & Patch Hull Timbers',
                              style: InkTheme.statValue.copyWith(fontSize: 16),
                            ),
                            Text(
                              'Haul the ship into the tidal shallows, scrape brine barnacles, and caulk seams with oakum and pitch.',
                              style: InkTheme.caption,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.isCurrentIslandHaven
                                  ? 'Restores 30% Max Hull • Shore Duty Option'
                                  : 'Restores 20% Max Hull • Shore Duty Option',
                              style: InkTheme.statLabel.copyWith(color: InkTheme.greenAccent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkButton(
                        label: hasCareened
                            ? 'CAREENED'
                            : (hasChosenDuty
                                ? 'DUTY SPENT'
                                : (ship != null && ship.currentHp == ship.maxHp
                                    ? 'HULL FULL'
                                    : (controller.isCurrentIslandHaven ? 'CAREEN (+30%)' : 'CAREEN (+20%)'))),
                        isPrimary: canCareen,
                        onPressed: canCareen
                            ? () => controller.dispatch(const CareenHullAtIsland())
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Drill Gunners Card
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
                              'Gunnery & Battery Drills',
                              style: InkTheme.statValue.copyWith(fontSize: 16),
                            ),
                            Text(
                              'Sight battery broadsides against offshore rocks and coordinate synchronized cannon volleys.',
                              style: InkTheme.caption,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+15% Accuracy Boon on Next Battle • Shore Duty Option',
                              style: InkTheme.statLabel.copyWith(color: InkTheme.goldAccent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkButton(
                        label: hasDrilled
                            ? 'DRILLED'
                            : (hasChosenDuty ? 'DUTY SPENT' : 'DRILL GUNS'),
                        isPrimary: canDrill,
                        onPressed: canDrill
                            ? () => controller.dispatch(const DrillGunnersAtIsland())
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Forage Shoals Card
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
                              'Forage & Beachcomb Shoals',
                              style: InkTheme.statValue.copyWith(fontSize: 16),
                            ),
                            Text(
                              'Send shore parties along sandy spits and coral pools to scavenge wreckage drift and pearls.',
                              style: InkTheme.caption,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.isCurrentIslandHaven
                                  ? 'Recovers 40–60 Gold Doubloons • Shore Duty Option'
                                  : 'Recovers 25–35 Gold Doubloons • Shore Duty Option',
                              style: InkTheme.statLabel.copyWith(color: InkTheme.goldAccent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkButton(
                        label: hasForaged
                            ? 'FORAGED'
                            : (hasChosenDuty ? 'DUTY SPENT' : 'FORAGE SHOALS'),
                        isPrimary: canForage,
                        onPressed: canForage
                            ? () => controller.dispatch(const ForageShoalsAtIsland())
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Island Shipwright Refit Card (Only at Grand Haven)
                if (controller.isCurrentIslandHaven && ship != null && ship.level < 4)
                  ParchmentCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SvgAssetView(
                          assetPath: PilotArt.helm,
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hermit Shipwright Refit (Tier ${ship.level + 1})',
                                style: InkTheme.statValue.copyWith(fontSize: 16),
                              ),
                              Text(
                                'An old recluse shipwright reinforces ship framing, expanding max HP, cargo space, and gun deck weight.',
                                style: InkTheme.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Refit Fee: ${upgradeCost}g (Purse: ${ship.gold}g)',
                                style: InkTheme.statLabel.copyWith(
                                  color: canAffordUpgrade
                                      ? InkTheme.goldAccent
                                      : InkTheme.crimsonAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkButton(
                          label: 'UPGRADE TIER',
                          isPrimary: canAffordUpgrade,
                          onPressed: canAffordUpgrade
                              ? () => controller.dispatch(const UpgradeShip())
                              : null,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Armory Toggle
                ParchmentCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ARMORY & MUNITIONS', style: InkTheme.statLabel),
                          Text(
                            'Equip deck weapons, swap ordnance, and manage cargo.',
                            style: InkTheme.caption,
                          ),
                        ],
                      ),
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

                const SizedBox(height: 28),

                // Primary Depart Expedition Button
                InkButton(
                  label: 'DEPART ISLAND & TAKE THE HELM',
                  semanticLabel: 'Depart the island haven and take the helm to steer next course',
                  isPrimary: true,
                  onPressed: () => controller.dispatch(const DepartIsland()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
