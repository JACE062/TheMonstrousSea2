import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/svg_asset_view.dart';

/// Screen displaying salvaged battle spoils following monster defeat.
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
          constraints: const BoxConstraints(maxWidth: 720),
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
                  'The beast sinks into the deep, leaving flotsam and treasures in the brine.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Cargo Hold Indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: InkTheme.parchmentSurface,
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
                        'CARGO HOLD CAPACITY: ${ship?.cargo.length ?? 0} / ${ship?.maxCargo ?? 0}',
                        style: InkTheme.statLabel.copyWith(
                          color: isFull ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
                        ),
                      ),
                      if (isFull)
                        Text(
                          'HOLD IS FULL!',
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
                    final rarityColor = InkTheme.rarityColor(item.rarity);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ParchmentCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SvgAssetView(
                              assetPath: item is Treasure
                                  ? 'assets/art/icon_treasure.svg'
                                  : item is ShipWeapon
                                      ? 'assets/art/icon_cannons.svg'
                                      : 'assets/art/icon_helm.svg',
                              width: 36,
                              height: 36,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: InkTheme.statValue.copyWith(
                                      color: rarityColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    item.description,
                                    style: InkTheme.caption.copyWith(fontSize: 13),
                                  ),
                                  Text(
                                    '${item.rarity.displayName} • Value: ${item.value}g',
                                    style: InkTheme.statLabel.copyWith(
                                      color: InkTheme.goldAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkButton(
                              label: 'Stow',
                              onPressed: isFull
                                  ? null
                                  : () => controller.dispatch(TakeLootItem(index)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // Action Buttons
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
                        label: 'LEAVE LEFTOVER & PROCEED',
                        onPressed: () => controller.dispatch(const LeaveRemainingLoot()),
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
}
