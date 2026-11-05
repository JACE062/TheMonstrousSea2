import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'hull_patch_kit_button.dart';
import 'parchment_card.dart';
import 'svg_asset_view.dart';
import 'weapon_stats_view.dart';

/// The same supply/belt decisions for creature spoils and recovered wreck cargo.
class LootSuppliesView extends StatelessWidget {
  const LootSuppliesView({
    super.key,
    required this.controller,
    this.onContinue,
  });
  final GameController controller;
  final VoidCallback? onContinue;
  Widget _itemDetails(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 500) return Row(children: children);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children)
            if (child is Expanded)
              child.child
            else if (child is SizedBox)
              const SizedBox(height: 8)
            else if (child is SvgAssetView)
              Align(alignment: Alignment.centerLeft, child: child)
            else
              child,
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final pendingLoot = controller.pendingLoot;
      final ship = controller.ship;
      final isFull = (ship?.cargo.length ?? 0) >= (ship?.maxCargo ?? 0);
      final hasKit = [...pendingLoot, ...?ship?.cargo]
          .whereType<Consumable>()
          .any((item) => item.type == ConsumableType.hullPatchKit);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  'TACTICAL BELT: ${ship?.cargo.length ?? 0} / ${ship?.maxCargo ?? 0}',
                  style: InkTheme.statLabel.copyWith(
                    color: isFull
                        ? InkTheme.crimsonAccent
                        : InkTheme.inkPrimary,
                  ),
                ),
                if (isFull)
                  Text(
                    hasKit
                        ? 'BELT FULL — Patch Kits can be used now if the hull needs repairs. Keeping supplies still requires a slot.'
                        : 'BELT FULL — Toss an item below to stow spoils',
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
                  child: _itemDetails([
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
                          if (item is Consumable &&
                              item.type == ConsumableType.hullPatchKit)
                            HullPatchKitButton(
                              controller: controller,
                              itemId: item.id,
                              fromPendingLoot: true,
                            ),
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
                      semanticLabel: isFull
                          ? 'Tactical Belt is full'
                          : 'Stow ${item.name} on the Tactical Belt',
                      isPrimary: !isFull,
                      onPressed: isFull
                          ? null
                          : () => controller.dispatch(TakeLootItem(index)),
                    ),
                  ]),
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
                  label: pendingLoot.isEmpty
                      ? 'CONTINUE VOYAGE'
                      : 'LEAVE LEFTOVER & CONTINUE',
                  onPressed: () {
                    controller.dispatch(const LeaveRemainingLoot());
                    onContinue?.call();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cargo Hold Management (Jettison options to free space)
          if (ship != null && ship.cargo.isNotEmpty) ...[
            Text(
              'ITEMS ON YOUR TACTICAL BELT (${ship.cargo.length}/${ship.maxCargo})',
              style: InkTheme.statLabel,
            ),
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
                        style: InkTheme.caption.copyWith(
                          color: InkTheme.crimsonAccent,
                        ),
                      ),
                    ),
                  ...List.generate(ship.cargo.length, (cargoIdx) {
                    final cargoItem = ship.cargo[cargoIdx];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: InkTheme.parchmentHighlight.withValues(
                          alpha: 0.5,
                        ),
                        border: Border.all(color: InkTheme.inkMuted, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _itemDetails([
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
                              if (cargoItem is Consumable &&
                                  cargoItem.type == ConsumableType.hullPatchKit)
                                HullPatchKitButton(
                                  controller: controller,
                                  itemId: cargoItem.id,
                                ),
                            ],
                          ),
                        ),
                        InkButton(
                          label: 'Jettison',
                          semanticLabel:
                              'Jettison ${cargoItem.name} into the sea',
                          isDanger: true,
                          onPressed: () =>
                              controller.dispatch(DropCargoItem(cargoIdx)),
                        ),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
