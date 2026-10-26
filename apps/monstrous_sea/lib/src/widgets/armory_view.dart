import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'parchment_card.dart';
import 'weapon_stats_view.dart';

/// Inspection of the flagship's fixed hardpoints and single-use tactical belt.
/// Voyage marks, primordial dedications and ancestral refits remain distinct.
class ArmoryView extends StatelessWidget {
  const ArmoryView({super.key, required this.controller});
  final GameController controller;

  String _utilityDescription(ShipState ship) {
    final mult = ship.multiplierForHardpointMark(HardpointType.utility);
    return switch (ship.resolvedBlueprintId) {
      BlueprintId.ironclad =>
        '2-turn cooldown. Adds +${(ship.dmgReductionMod * mult).round()} damage reduction for this battle and anchors the hull against forced movement this round.',
      BlueprintId.clipper => '2-turn cooldown. Doubles evasion until the next dodge and moves one range band away from the monster.',
      BlueprintId.corsair =>
        '2-turn cooldown. Launches a drifting tether-trap one band ahead. It drifts closer each round, then detonates for ${((16 + 5 * (ship.level - 1)) * mult).round()} Slicing damage and pins the beast for one turn.',
      BlueprintId.bombardier => '2-turn cooldown. Illuminates the beast for two turns: clears obscurity, suppresses evasion, grants +15% accuracy and increases Blast damage taken by 25%.',
      BlueprintId.standard =>
        '2-turn cooldown. Reduces incoming damage by ${(20 * mult).round()}% this round and grants the next volley +15% accuracy and +${(20 * mult).round()}% damage.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    if (ship == null) return const SizedBox.shrink();
    final profile = controller.profile;
    final belt = ship.cargo.indexed
        .where((entry) => entry.$2 is Consumable)
        .toList();
    return ParchmentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.activeBoon != null || controller.activeQuirk != null) ...[
            Text('CAPTAIN TRAITS', style: InkTheme.statLabel),
            const SizedBox(height: 6),
            for (final trait in [controller.activeBoon, controller.activeQuirk])
              if (trait != null) ...[
                Text(trait.name, style: InkTheme.statValue.copyWith(fontSize: 15)),
                Text(trait.description, style: InkTheme.body.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
              ],
            const Divider(),
            const SizedBox(height: 8),
          ],
          Text(
            'HARDPOINTS & TACTICAL BELT',
            style: InkTheme.titleMedium.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'Three fixed hardpoints. Inspect their voyage marks, blessings and ancestral refits here.',
            style: InkTheme.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 14),
          for (final slot in ship.hardpoints) ...[
            Builder(
              builder: (context) {
                final canonical = slot.type.canonical;
                final weaponType = switch (canonical) {
                  HardpointType.broadside =>
                    ship.resolvedBlueprintId.broadsideWeaponType,
                  HardpointType.signature =>
                    ship.resolvedBlueprintId.signatureWeaponType,
                  _ => null,
                };
                final weapon = ship.equippedWeapons
                    .where((w) => w.weaponType == weaponType)
                    .firstOrNull;
                final blessing = ship.blessings[canonical];
                final relics = EldritchRelicDef.catalog.values.where(
                  (relic) =>
                      relic.weaponType == weaponType &&
                      profile.isEldritchRelicActive(relic.id),
                );
                return ParchmentCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${canonical.displayName.toUpperCase()} · ${ship.markLabelForHardpoint(canonical)}',
                        style: InkTheme.statLabel.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        weapon?.name ?? slot.name,
                        style: InkTheme.titleMedium.copyWith(
                          fontSize: 20,
                          color: InkTheme.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (weapon != null)
                        WeaponStatsView(item: weapon, compact: true)
                      else
                        Text(
                          _utilityDescription(ship),
                          style: InkTheme.body.copyWith(fontSize: 14),
                        ),
                      const SizedBox(height: 10),
                      if (blessing != null) ...[
                        Text(
                          '${blessing.title} · ${blessing.subtitle}',
                          style: InkTheme.statValue.copyWith(fontSize: 15),
                        ),
                        Text(
                          blessing.power.displayName,
                          style: InkTheme.caption.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          blessing.description,
                          style: InkTheme.body.copyWith(fontSize: 14),
                        ),
                      ] else
                        Text(
                          'No primordial blessing',
                          style: InkTheme.caption.copyWith(fontSize: 13),
                        ),
                      if (canonical == HardpointType.signature) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ancestral armament: Tier ${profile.armamentTierFor(ship.resolvedBlueprintId)}',
                          style: InkTheme.statLabel.copyWith(fontSize: 13),
                        ),
                      ],
                      for (final relic in relics) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Active relic: ${relic.name}',
                          style: InkTheme.statValue.copyWith(fontSize: 15),
                        ),
                        Text(
                          relic.effectSummary,
                          style: InkTheme.body.copyWith(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          const Divider(height: 20),
          Text(
            'TACTICAL BELT · ${belt.length}/${ship.maxCargo} SLOTS',
            style: InkTheme.statLabel.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Single-use provisions. Trigger one as a quick action in battle, or jettison it to free a slot.',
            style: InkTheme.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (belt.isEmpty)
            Text(
              'The belt is empty. Find provisions at merchants or at sea.',
              style: InkTheme.caption.copyWith(fontSize: 14),
            ),
          for (final (index, item) in belt)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ParchmentCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.name,
                      style: InkTheme.titleMedium.copyWith(
                        fontSize: 20,
                        color: InkTheme.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: InkTheme.body.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    WeaponStatsView(item: item, compact: true),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkButton(
                        label: 'JETTISON',
                        semanticLabel:
                            'Jettison ${item.name} from tactical belt',
                        onPressed: () =>
                            controller.dispatch(DropCargoItem(index)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
