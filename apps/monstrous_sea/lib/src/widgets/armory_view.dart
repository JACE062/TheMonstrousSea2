import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'parchment_card.dart';
import 'pilot_art.dart';
import 'svg_asset_view.dart';
import 'weapon_stats_view.dart';

/// Interactive flagship hardpoint and tactical consumable belt overview card.
///
/// Displays the ship's 3 intrinsic hardpoints (Broadside, Signature, Utility),
/// allows tempering hardpoints (`Mk I -> Mk II -> Mk III`) at Port or Grand Haven,
/// and manages the Tactical Consumable Belt (`3–4` slots).
class ArmoryView extends StatelessWidget {
  const ArmoryView({
    super.key,
    required this.controller,
  });

  final GameController controller;

  String _utilityDescription(ShipState ship, HardpointSlot slot) {
    final bpId = BlueprintId.values
        .where((b) => b.name == ship.blueprintId)
        .firstOrNull;
    final mult = ship.multiplierForHardpointMark(HardpointType.utility);
    return switch (bpId) {
      BlueprintId.ironclad =>
        '2T CD • Permanently adds +${(ship.dmgReductionMod * mult).round()} Damage Reduction for the battle and anchors hull against forced push/pull this round.',
      BlueprintId.clipper =>
        '2T CD • Doubles current Evasion until next dodge and shifts 1 range band away from the monster.',
      BlueprintId.corsair =>
        '2T CD • Launches a Drifting Tether-Trap 1 band ahead. Drifts 1 band closer each round; detonates on contact for ${(16 + 5 * (ship.level - 1) * mult).round()} Slicing damage and Pins the beast (1T).',
      BlueprintId.bombardier =>
        '2T CD • Illuminates the beast for 2 turns: clears Obscured, suppresses monster Evasion to 0%, grants +15% Accuracy, and boosts Blast damage taken by +25%.',
      _ =>
        '2T CD • Reduces incoming damage by ${(20 * mult).round()}% this round and empowers your next offensive volley with +15% Accuracy and +${(20 * mult).round()}% Damage.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    if (ship == null) return const SizedBox.shrink();

    final canTemperHere = controller.phase == SessionPhase.port ||
        (controller.phase == SessionPhase.respiteIsland &&
            controller.isCurrentIslandHaven);

    final broadsideWeapon =
        ship.equippedWeapons.where((w) => !w.isSignature).firstOrNull;
    final signatureWeapon =
        ship.equippedWeapons.where((w) => w.isSignature).firstOrNull;

    return ParchmentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'HARDPOINTS & TACTICAL BELT',
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
                  '3 Hardpoints • Belt: ${ship.cargo.length}/${ship.maxCargo}',
                  style: InkTheme.statLabel.copyWith(
                    color: ship.cargo.length >= ship.maxCargo
                        ? InkTheme.crimsonAccent
                        : InkTheme.inkPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Intrinsic 3-Hardpoint Deck Topology
          Text(
            'INTRINSIC FLAGSHIP HARDPOINTS (3 MOUNTS)',
            style: InkTheme.statLabel.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          ...ship.hardpoints.map((slot) {
            final canonical = slot.type.canonical;
            final mark = ship.markForHardpoint(canonical);
            final markLabel = ship.markLabelForHardpoint(canonical);
            final temperCost = calculateHardpointTemperCost(mark);
            final canTemper = canTemperHere && mark < 3;
            final canAffordTemper = canTemper && ship.gold >= temperCost;

            final ShipWeapon? mountedWeapon = switch (canonical) {
              HardpointType.broadside => broadsideWeapon,
              HardpointType.signature => signatureWeapon,
              _ => null,
            };

            final title = mountedWeapon?.name ?? '${slot.name} ($markLabel)';
            final roleBadge = switch (canonical) {
              HardpointType.broadside => '1. BROADSIDE (0T)',
              HardpointType.signature => '2. SIGNATURE (1T)',
              _ => '3. UTILITY (2T)',
            };

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: InkTheme.parchmentHighlight.withValues(alpha: 0.5),
                border: Border.all(
                  color: canonical == HardpointType.signature
                      ? InkTheme.crimsonAccent.withValues(alpha: 0.7)
                      : InkTheme.inkMuted,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgAssetView(
                    assetPath: mountedWeapon != null
                        ? SvgAssetView.pathForItem(mountedWeapon)
                        : PilotArt.helm,
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: InkTheme.inkPrimary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                roleBadge,
                                style: InkTheme.caption.copyWith(
                                  color: InkTheme.parchmentHighlight,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: mark > 1
                                    ? InkTheme.goldAccent
                                    : InkTheme.parchmentSurface,
                                border: Border.all(color: InkTheme.goldAccent),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                markLabel,
                                style: InkTheme.caption.copyWith(
                                  color: mark > 1
                                      ? Colors.white
                                      : InkTheme.inkPrimary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              title,
                              style: InkTheme.statValue.copyWith(
                                color: mountedWeapon != null
                                    ? InkTheme.rarityColor(mountedWeapon.rarity)
                                    : InkTheme.inkPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (mountedWeapon != null)
                          WeaponStatsView(item: mountedWeapon, compact: true)
                        else
                          Text(
                            _utilityDescription(ship, slot),
                            style: InkTheme.caption.copyWith(fontSize: 11.5),
                          ),
                      ],
                    ),
                  ),
                  if (canTemperHere) ...[
                    const SizedBox(width: 8),
                    if (mark < 3)
                      InkButton(
                        label: 'Temper (${temperCost}g)',
                        semanticLabel:
                            'Temper ${canonical.displayName} hardpoint to Mk ${mark + 1} for $temperCost gold',
                        isPrimary: canAffordTemper,
                        onPressed: canAffordTemper
                            ? () => controller.dispatch(
                                  TemperHardpoint(canonical),
                                )
                            : null,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: InkTheme.goldAccent.withValues(alpha: 0.15),
                          border: Border.all(color: InkTheme.goldAccent),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'MAX MK III',
                          style: InkTheme.caption.copyWith(
                            color: InkTheme.goldAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          }),

          const Divider(height: 18),

          // 2. Tactical Consumable Belt
          Text(
            'TACTICAL CONSUMABLE BELT (${ship.cargo.length}/${ship.maxCargo} SLOTS • 0T QUICK ACTION IN BATTLE)',
            style: InkTheme.statLabel.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (ship.cargo.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Tactical belt is empty. Stock consumables at the Merchant or salvage wrecks at sea.',
                style: InkTheme.caption,
              ),
            )
          else
            ...List.generate(ship.cargo.length, (cargoIdx) {
              final item = ship.cargo[cargoIdx];
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
                      assetPath: SvgAssetView.pathForItem(item),
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: InkTheme.statValue.copyWith(
                              color: InkTheme.rarityColor(item.rarity),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (item is Consumable)
                            WeaponStatsView(item: item, compact: true)
                          else
                            Text(
                              'Salvaged Treasure • Value: ${item.value}g',
                              style: InkTheme.caption,
                            ),
                        ],
                      ),
                    ),
                    InkButton(
                      label: 'Jettison',
                      semanticLabel: 'Jettison ${item.name} from tactical belt',
                      onPressed: () =>
                          controller.dispatch(DropCargoItem(cargoIdx)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

