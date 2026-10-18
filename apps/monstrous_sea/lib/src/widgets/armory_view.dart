import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'parchment_card.dart';
import 'svg_asset_view.dart';
import 'weapon_stats_view.dart';

/// Interactive armory card for mounting, stowing, and swapping ship weapons.
///
/// Usable seamlessly at Port and in Rest Areas.
class ArmoryView extends StatelessWidget {
  const ArmoryView({
    super.key,
    required this.controller,
  });

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    if (ship == null) return const SizedBox.shrink();

    return ParchmentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'ARMORY & BATTERIES',
                  style: InkTheme.titleMedium.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: InkTheme.parchmentHighlight,
                  border: Border.all(color: InkTheme.goldAccent, width: 1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Hardpoints: ${ship.equippedWeapons.length}/${ship.hardpoints.length} Mounted',
                  style: InkTheme.statLabel.copyWith(
                    color: ship.equippedWeapons.length >= ship.hardpoints.length
                        ? InkTheme.crimsonAccent
                        : InkTheme.inkPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mounted Guns
          Text(
            'ACTIVE BATTERY (${ship.equippedWeapons.length} MOUNTED)',
            style: InkTheme.statLabel.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (ship.equippedWeapons.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No naval guns mounted on active deck!', style: InkTheme.caption),
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

          // Stowed Weapons in Cargo Hold
          Text('STOWED WEAPONS IN CARGO HOLD', style: InkTheme.statLabel.copyWith(fontSize: 12)),
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
                  child: Text('No spare naval guns in cargo hold.', style: InkTheme.caption),
                );
              }

              return Column(
                children: cargoWeapons.map((entry) {
                  final cargoIdx = entry.key;
                  final weapon = entry.value;
                  final canEquip = ship.canEquipWeapon(weapon);

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
                          label: canEquip ? 'Mount' : 'Deck Full',
                          semanticLabel: 'Mount ${weapon.name} to active gun deck',
                          semanticHint: canEquip
                              ? 'Mount weapon to open hardpoint slot'
                              : 'All deck hardpoint mounts are occupied',
                          isPrimary: canEquip,
                          onPressed: canEquip
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
    );
  }
}
