import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/pilot_art.dart';
import '../widgets/weapon_stats_view.dart';

/// Screen allowing captain to rest upon the open swell, inspect vessel,
/// manage weapon mounts in the armory, and choose their next move.
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    'Sector [${seaChart.currentRow}, ${seaChart.currentCol}] • Loop ${seaChart.timesCompleted}',
                                    style: InkTheme.caption,
                                  ),
                                  const SizedBox(height: 8),
                                  HullGauge(currentHp: ship.currentHp, maxHp: ship.maxHp),
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
                            _statColumn('CARGO STOWED', '${ship.cargo.length} / ${ship.maxCargo}'),
                            _statColumn('GUN WEIGHT', '${ship.currentWeaponWeight} / ${ship.maxWeaponWeight} Wt'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. Armory & Gun Deck Card (Java Parity: swap equipped weapons)
                  ParchmentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ARMORY & WEAPON BATTERIES', style: InkTheme.titleMedium.copyWith(fontSize: 18)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: InkTheme.parchmentHighlight,
                                border: Border.all(color: InkTheme.goldAccent, width: 1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'Weight: ${ship.currentWeaponWeight}/${ship.maxWeaponWeight} Wt',
                                style: InkTheme.statLabel.copyWith(
                                  color: ship.currentWeaponWeight >= ship.maxWeaponWeight
                                      ? InkTheme.crimsonAccent
                                      : InkTheme.inkPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Mounted Weapons
                        Text('MOUNTED GUNS (${ship.equippedWeapons.length})', style: InkTheme.statLabel.copyWith(fontSize: 12)),
                        const SizedBox(height: 6),
                        if (ship.equippedWeapons.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No weapons mounted on gun deck!', style: InkTheme.caption),
                          )
                        else
                          ...List.generate(ship.equippedWeapons.length, (idx) {
                            final weapon = ship.equippedWeapons[idx];
                            final hasCargoRoom = ship.cargo.length < ship.maxCargo;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: InkTheme.parchmentHighlight.withValues(alpha: 0.5),
                                border: Border.all(color: InkTheme.inkMuted, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  SvgAssetView(
                                    assetPath: SvgAssetView.pathForItem(weapon),
                                    width: 32,
                                    height: 32,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          weapon.name,
                                          style: InkTheme.statValue.copyWith(
                                            color: InkTheme.rarityColor(weapon.rarity),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        WeaponStatsView(item: weapon, compact: true),
                                      ],
                                    ),
                                  ),
                                  InkButton(
                                    label: hasCargoRoom ? 'Stow' : 'Hold Full',
                                    semanticLabel: hasCargoRoom
                                        ? 'Stow ${weapon.name} into cargo hold'
                                        : 'Cannot stow ${weapon.name}, cargo hold is full',
                                    onPressed: hasCargoRoom
                                        ? () => controller.dispatch(UnequipShipWeapon(idx))
                                        : null,
                                  ),
                                ],
                              ),
                            );
                          }),

                        const Divider(height: 18),

                        // Stowed Weapons in Hold
                        Text('STOWED WEAPONS IN CARGO', style: InkTheme.statLabel.copyWith(fontSize: 12)),
                        const SizedBox(height: 6),
                        Builder(
                          builder: (context) {
                            final cargoWeapons = <MapEntry<int, ShipWeapon>>[];
                            for (var i = 0; i < ship.cargo.length; i++) {
                              final item = ship.cargo[i];
                              if (item is ShipWeapon) {
                                cargoWeapons.add(MapEntry(i, item));
                              }
                            }

                            if (cargoWeapons.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('No spare naval weapons stowed in the cargo hold.', style: InkTheme.caption),
                              );
                            }

                            return Column(
                              children: cargoWeapons.map((entry) {
                                final cargoIdx = entry.key;
                                final weapon = entry.value;
                                final canFitWeight = ship.currentWeaponWeight + weapon.equipWeight <= ship.maxWeaponWeight;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: InkTheme.parchmentHighlight.withValues(alpha: 0.5),
                                    border: Border.all(color: InkTheme.inkMuted, width: 1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      SvgAssetView(
                                        assetPath: SvgAssetView.pathForItem(weapon),
                                        width: 32,
                                        height: 32,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              weapon.name,
                                              style: InkTheme.statValue.copyWith(
                                                color: InkTheme.rarityColor(weapon.rarity),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            WeaponStatsView(item: weapon, compact: true),
                                          ],
                                        ),
                                      ),
                                      InkButton(
                                        label: canFitWeight ? 'Mount' : 'Heavy',
                                        semanticLabel: 'Mount ${weapon.name} to active gun deck',
                                        semanticHint: canFitWeight
                                            ? null
                                            : 'Exceeds battery weight limit by ${(ship.currentWeaponWeight + weapon.equipWeight) - ship.maxWeaponWeight} Wt',
                                        isPrimary: canFitWeight,
                                        onPressed: canFitWeight
                                            ? () => controller.dispatch(EquipCargoWeapon(cargoIdx))
                                            : null,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Chart button
                InkButton(
                  label: 'CONSULT SEA CHART',
                  icon: SvgAssetView(assetPath: PilotArt.cannons, width: 22, height: 22),
                  onPressed: onOpenChart,
                ),
                const SizedBox(height: 16),

                // Primary Next Move Choices
                Row(
                  children: [
                    Expanded(
                      child: InkButton(
                        label: 'ADVANCE TO NEXT WATERS',
                        isPrimary: true,
                        onPressed: () => controller.dispatch(const AdvanceToNextBattle()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkButton(
                        label: 'RETURN TO PORT',
                        onPressed: () => controller.dispatch(const ReturnToPort()),
                      ),
                    ),
                  ],
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
        Text(label, style: InkTheme.statLabel.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: InkTheme.statValue.copyWith(fontSize: 14)),
      ],
    );
  }
}
