import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'mechanic_text.dart';
import 'ink_button.dart';
import 'hull_patch_kit_button.dart';
import 'parchment_card.dart';
import 'weapon_stats_view.dart';
import 'utility_description.dart';

/// Inspection of the flagship's fixed fittings and single-use tactical belt.
/// Voyage marks, primordial dedications and ancestral refits remain distinct.
class ArmoryView extends StatelessWidget {
  const ArmoryView({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    if (ship == null) return const SizedBox.shrink();
    final profile = controller.profile;
    final belt = ship.cargo.indexed
        .where((entry) => entry.$2 is Consumable)
        .toList();
    return MechanicScope(
      data: MechanicContext(
        ship: ship,
        regionIndex: controller.seaChart.currentRegionIndex,
      ),
      child: ParchmentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.activeBoon != null ||
                controller.activeQuirk != null) ...[
              Text('CAPTAIN TRAITS', style: InkTheme.statLabel),
              const SizedBox(height: 6),
              for (final trait in [
                controller.activeBoon,
                controller.activeQuirk,
              ])
                if (trait != null) ...[
                  Text(
                    trait.name,
                    style: InkTheme.statValue.copyWith(fontSize: 15),
                  ),
                  MechanicText(
                    trait.description,
                    style: InkTheme.body.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],
              const Divider(),
              const SizedBox(height: 8),
            ],
            Text(
              'SHIP FITTINGS & TACTICAL BELT',
              style: InkTheme.titleMedium.copyWith(fontSize: 22),
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
                          weapon?.name ?? slot.displayName,
                          style: InkTheme.titleMedium.copyWith(
                            fontSize: 20,
                            color: InkTheme.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (weapon != null)
                          WeaponStatsView(item: weapon, compact: true)
                        else
                          MechanicText(
                            utilityDescription(ship),
                            style: InkTheme.body.copyWith(fontSize: 14),
                          ),
                        if (blessing != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '${blessing.title} · ${blessing.subtitle}',
                            style: InkTheme.statValue.copyWith(fontSize: 15),
                          ),
                          Text(
                            blessing.power.displayName,
                            style: InkTheme.caption.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          MechanicText(
                            blessing.description,
                            mechanics: MechanicContext(
                              ship: ship,
                              blessing: blessing,
                              regionIndex:
                                  controller.seaChart.currentRegionIndex,
                            ),
                            style: InkTheme.body.copyWith(fontSize: 14),
                          ),
                        ],
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
                          MechanicText(
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
              'Patch Kits can be used between battles.',
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
                      MechanicText(
                        currentItemDescription(item),
                        style: InkTheme.body.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      WeaponStatsView(item: item, compact: true),
                      const SizedBox(height: 10),
                      if (item is Consumable &&
                          item.type == ConsumableType.hullPatchKit) ...[
                        HullPatchKitButton(
                          controller: controller,
                          itemId: item.id,
                        ),
                        const SizedBox(height: 8),
                      ],
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
      ),
    );
  }
}
