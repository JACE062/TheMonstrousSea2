import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pilot_art.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/loot_supplies_view.dart';

/// Screen displaying salvaged battle spoils following monster defeat,
/// allowing captain to stow loot or jettison held cargo to free space.
class LootScreen extends StatelessWidget {
  const LootScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;

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
                if (controller.session.currentWreck?.stage ==
                    WreckStage.recovery) ...[
                  ParchmentCard(
                    child: Text(
                      'These are the defeated creature’s full spoils. The cleared wreck’s separate cargo awaits recovery after these supplies are resolved.',
                      style: InkTheme.body,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Direct Gold Salvaged Notification Banner
                if (controller.lastGoldSalvaged > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: InkTheme.goldAccent.withValues(alpha: 0.15),
                      border: Border.all(
                        color: InkTheme.goldAccent,
                        width: 1.5,
                      ),
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

                LootSuppliesView(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
