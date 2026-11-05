import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';

class HullPatchKitButton extends StatelessWidget {
  const HullPatchKitButton({
    super.key,
    required this.controller,
    required this.itemId,
    this.fromPendingLoot = false,
  });
  final GameController controller;
  final String itemId;
  final bool fromPendingLoot;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final session = controller.session;
      if (!session.canUseHullPatchOutsideBattle ||
          (fromPendingLoot &&
              controller.phase != SessionPhase.loot &&
              controller.phase != SessionPhase.shipwreck)) {
        return const SizedBox.shrink();
      }
      final items = fromPendingLoot
          ? controller.pendingLoot
          : controller.ship!.cargo;
      final item = items.where((item) => item.id == itemId).firstOrNull;
      if (item is! Consumable || item.type != ConsumableType.hullPatchKit) {
        return const SizedBox.shrink();
      }
      final hp = session.hullPatchHealingHp;
      return Tooltip(
        message: hp > 0
            ? 'Use this Hull Patch Kit now to restore $hp hull HP.'
            : 'Hull already full; this kit remains available to keep or stow.',
        child: InkButton(
          key: ValueKey(
            'hull-patch-${fromPendingLoot ? 'pending' : 'carried'}-$itemId',
          ),
          label: hp > 0 ? 'PATCH +$hp HP' : 'HULL FULL · KEEP KIT',
          semanticLabel: fromPendingLoot
              ? 'Use found Hull Patch Kit without stowing it, restoring $hp HP'
              : 'Use carried Hull Patch Kit, restoring $hp HP',
          onPressed: hp > 0 && !controller.isPlayingEvents
              ? () => controller.dispatch(
                  UseHullPatchKit(itemId, fromPendingLoot: fromPendingLoot),
                )
              : null,
        ),
      );
    },
  );
}

/// A small management control reused where no full belt inspection is visible.
class CarriedPatchKits extends StatelessWidget {
  const CarriedPatchKits({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (!controller.session.canUseHullPatchOutsideBattle) {
        return const SizedBox.shrink();
      }
      final kits = controller.ship!.cargo
          .whereType<Consumable>()
          .where((item) => item.type == ConsumableType.hullPatchKit)
          .toList();
      if (kits.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CARRIED PATCH KITS', style: InkTheme.statLabel),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kit in kits)
                  HullPatchKitButton(controller: controller, itemId: kit.id),
              ],
            ),
          ],
        ),
      );
    },
  );
}
