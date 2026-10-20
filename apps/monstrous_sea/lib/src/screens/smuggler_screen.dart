import 'dart:math';
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
import '../widgets/weapon_stats_view.dart';

/// Screen rendered upon discovering a wandering Smuggler's Ketch,
/// allowing the captain to purchase black-market munitions, patch hull breaches
/// with seasoned oak planks, and liquidate cargo mid-voyage.
class SmugglerScreen extends StatefulWidget {
  const SmugglerScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });

  final GameController controller;
  final VoidCallback onOpenChart;

  @override
  State<SmugglerScreen> createState() => _SmugglerScreenState();
}

class _SmugglerScreenState extends State<SmugglerScreen> {
  int _activeTab = 0; // 0: Contraband Wares, 1: Liquidate Cargo
  bool _showingArmory = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final ship = controller.ship;
        final smugglerName = controller.currentSmugglerName.isNotEmpty
            ? controller.currentSmugglerName
            : "The Shadowed Ketch";
        final stock = controller.smugglerStock;

        final missingHp = ship != null ? ship.maxHp - ship.currentHp : 0;
        final repairHp = ship != null ? min((ship.maxHp * 0.25).round(), missingHp) : 0;
        final repairCost = (repairHp * 1.5).ceil();
        final canAffordRepair = ship != null && repairHp > 0 && ship.gold >= repairCost;

        final hasTreasure = ship?.cargo.any((item) => item is Treasure) ?? false;

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
                        'PURSE: ${ship.gold}g | TACTICAL BELT: ${ship.cargo.length}/${ship.maxCargo}',
                        style: InkTheme.statLabel.copyWith(
                          color: InkTheme.goldAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Smuggler Header
                Center(
                  child: SvgAssetView(
                    assetPath: PilotArt.helm,
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  smugglerName.toUpperCase(),
                  style: InkTheme.titleLarge.copyWith(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'A clandestine merchant vessel rides the ocean swell under muffled lanterns, peddling contraband munitions.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Vessel Vitality Gauge
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
                  const SizedBox(height: 16),
                ],

                // Seasoned Oak Planks (Emergency Hull Repair)
                ParchmentCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SEASONED OAK PLANKS (+$repairHp HP)',
                              style: InkTheme.statValue.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              repairHp > 0
                                  ? 'Smugglers hammer seasoned oak and caulking over shot holes for ${repairCost}g (1.5x black market rate).'
                                  : 'Hull timbers are currently sound and seaworthy.',
                              style: InkTheme.caption.copyWith(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkButton(
                        label: 'REPAIR (${repairCost}g)',
                        semanticLabel: 'Repair hull with oak planks for $repairCost gold',
                        onPressed: canAffordRepair
                            ? () => controller.dispatch(const RepairShip(0.25))
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Mode Tabs
                Row(
                  children: [
                    Expanded(
                      child: InkButton(
                        label: 'CONTRABAND WARES (${stock.length})',
                        isPrimary: _activeTab == 0,
                        onPressed: () => setState(() => _activeTab = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkButton(
                        label: 'SELL FROM BELT (${ship?.cargo.length ?? 0})',
                        isPrimary: _activeTab == 1,
                        onPressed: () => setState(() => _activeTab = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab 0: Contraband Stock
                if (_activeTab == 0) ...[
                  if (stock.isEmpty)
                    ParchmentCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'The smuggler has sold out of contraband wares for this voyage.',
                          style: InkTheme.body,
                        ),
                      ),
                    )
                  else
                    ...stock.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final canAfford = ship != null &&
                          ship.gold >= item.value &&
                          ship.cargo.length < ship.maxCargo;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ParchmentCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.name,
                                          style: InkTheme.statValue.copyWith(
                                            color: InkTheme.inkPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (item is ShipWeapon)
                                      WeaponStatsView(item: item, compact: true)
                                    else if (item is Consumable)
                                      Text(
                                        'Single use · Value: ${item.value}g',
                                        style: InkTheme.caption.copyWith(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkButton(
                                label: 'BUY (${item.value}g)',
                                isPrimary: true,
                                semanticLabel: 'Purchase ${item.name} for ${item.value} gold',
                                onPressed: canAfford
                                    ? () => controller.dispatch(BuyMerchantItem(index))
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],

                // Tab 1: Liquidate Cargo
                if (_activeTab == 1) ...[
                  if (hasTreasure) ...[
                    ParchmentCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'SELL ALL TREASURE SPOILS',
                              style: InkTheme.statValue.copyWith(
                                color: InkTheme.goldAccent,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          InkButton(
                            label: 'EXCHANGE ALL',
                            isPrimary: true,
                            semanticLabel: 'Sell all treasure spoils for gold',
                            onPressed: () => controller.dispatch(const SellAllTreasure()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (ship == null || ship.cargo.isEmpty)
                    ParchmentCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Your Tactical Belt is currently empty.',
                          style: InkTheme.body,
                        ),
                      ),
                    )
                  else
                    ...ship.cargo.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ParchmentCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: InkTheme.statValue.copyWith(fontSize: 16)),
                                    if (item is Consumable)
                                      Text('Single use · Value: ${item.value}g',
                                          style: InkTheme.caption),
                                  ],
                                ),
                              ),
                              InkButton(
                                label: 'SELL (${item.value}g)',
                                semanticLabel: 'Sell ${item.name} for ${item.value} gold',
                                onPressed: () => controller.dispatch(SellCargoItem(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],

                const SizedBox(height: 18),

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
                              'Mount fresh black-market weapons and configure deck batteries.',
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

                const SizedBox(height: 24),

                // Departure Button
                InkButton(
                  label: 'DEPART SMUGGLER & CONTINUE EXPEDITION',
                  isPrimary: true,
                  semanticLabel: 'Depart the smuggler ketch and continue naval voyage',
                  onPressed: () => controller.dispatch(const DepartSmuggler()),
                ),
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
