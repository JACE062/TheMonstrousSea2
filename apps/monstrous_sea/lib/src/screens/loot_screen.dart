import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pilot_art.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/weapon_stats_view.dart';

/// Screen displaying salvaged battle spoils following monster defeat,
/// allowing captain to stow loot or jettison held cargo to free space.
class LootScreen extends StatelessWidget {
  const LootScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final pendingLoot = controller.pendingLoot;
    final ship = controller.ship;
    final isFull = (ship?.cargo.length ?? 0) >= (ship?.maxCargo ?? 0);

    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'VICTORY SPOILS SALVAGED',
                  style: InkTheme.titleLarge.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'The beast sinks into the deep, leaving flotsam and munitions in the brine.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Direct Gold Salvaged Notification Banner
                if (controller.lastGoldSalvaged > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: InkTheme.goldAccent.withValues(alpha: 0.15),
                      border: Border.all(color: InkTheme.goldAccent, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SvgAssetView(
                          assetPath: PilotArt.treasure,
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '+${controller.lastGoldSalvaged} GOLD SALVAGED DIRECTLY TO PURSE (Purse: ${ship?.gold ?? 0}g)',
                            style: InkTheme.statLabel.copyWith(
                              color: InkTheme.goldAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Cargo Hold Indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFull
                        ? InkTheme.crimsonAccent.withValues(alpha: 0.12)
                        : InkTheme.parchmentSurface,
                    border: Border.all(
                      color: isFull ? InkTheme.crimsonAccent : InkTheme.inkMuted,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TACTICAL BELT: ${ship?.cargo.length ?? 0} / ${ship?.maxCargo ?? 0}',
                        style: InkTheme.statLabel.copyWith(
                          color: isFull ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
                        ),
                      ),
                      if (isFull)
                        Text(
                          'BELT FULL — Toss an item below to stow spoils',
                          style: InkTheme.statLabel.copyWith(
                            color: InkTheme.crimsonAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pending Loot Items
                Text('SPOILS FLOATING IN THE WATER', style: InkTheme.statLabel),
                const SizedBox(height: 8),
                if (pendingLoot.isEmpty)
                  ParchmentCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'All spoils have been stowed.',
                        style: InkTheme.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...List.generate(pendingLoot.length, (index) {
                    final item = pendingLoot[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ParchmentCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SvgAssetView(
                              assetPath: SvgAssetView.pathForItem(item),
                              width: 38,
                              height: 38,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: InkTheme.statValue.copyWith(
                                      color: InkTheme.inkPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    item.description,
                                    style: InkTheme.caption.copyWith(fontSize: 13),
                                  ),
                                  const SizedBox(height: 3),
                                  WeaponStatsView(item: item),
                                  const SizedBox(height: 2),
                                  Text(
                                    item is Consumable
                                        ? 'Single use · Value: ${item.value}g'
                                        : 'Value: ${item.value}g',
                                    style: InkTheme.statLabel.copyWith(
                                      color: InkTheme.goldAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkButton(
                              label: isFull ? 'Belt Full' : 'Stow',
                              semanticLabel: isFull ? 'Tactical Belt is full' : 'Stow ${item.name} on the Tactical Belt',
                              isPrimary: !isFull,
                              onPressed: isFull
                                  ? null
                                  : () => controller.dispatch(TakeLootItem(index)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // Primary Action Buttons (placed directly below spoils)
                Row(
                  children: [
                    if (pendingLoot.isNotEmpty && !isFull)
                      Expanded(
                        child: InkButton(
                          label: 'TAKE ALL SPOILS',
                          isPrimary: true,
                          onPressed: () => controller.dispatch(const TakeAllLoot()),
                        ),
                      ),
                    if (pendingLoot.isNotEmpty && !isFull) const SizedBox(width: 12),
                    Expanded(
                      child: InkButton(
                        label: pendingLoot.isEmpty ? 'CONTINUE VOYAGE' : 'LEAVE LEFTOVER & CONTINUE',
                        onPressed: () => controller.dispatch(const LeaveRemainingLoot()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Cargo Hold Management (Jettison options to free space)
                if (ship != null && ship.cargo.isNotEmpty) ...[
                  Text('ITEMS ON YOUR TACTICAL BELT (${ship.cargo.length}/${ship.maxCargo})', style: InkTheme.statLabel),
                  const SizedBox(height: 8),
                  ParchmentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isFull)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Select an item to jettison into the sea to free up belt space:',
                              style: InkTheme.caption.copyWith(color: InkTheme.crimsonAccent),
                            ),
                          ),
                        ...List.generate(ship.cargo.length, (cargoIdx) {
                          final cargoItem = ship.cargo[cargoIdx];

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
                                  assetPath: SvgAssetView.pathForItem(cargoItem),
                                  width: 32,
                                  height: 32,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cargoItem.name,
                                        style: InkTheme.statValue.copyWith(
                                          color: InkTheme.inkPrimary,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      WeaponStatsView(item: cargoItem, compact: true),
                                    ],
                                  ),
                                ),
                                InkButton(
                                  label: 'Jettison',
                                  semanticLabel: 'Jettison ${cargoItem.name} into the sea',
                                  isDanger: true,
                                  onPressed: () => controller.dispatch(DropCargoItem(cargoIdx)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
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
