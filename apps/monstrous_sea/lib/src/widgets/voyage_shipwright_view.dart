import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'parchment_card.dart';

/// The same paid voyage upgrades are offered at midpoint Havens and strongholds.
class VoyageShipwrightView extends StatelessWidget {
  const VoyageShipwrightView({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final ship = controller.ship;
      if (ship == null || !controller.session.canUseVoyageShipwright) {
        return const SizedBox.shrink();
      }
      final cost = calculateShipUpgradeCost(ship.level);
      return ParchmentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('VOYAGE SHIPWRIGHT', style: InkTheme.titleMedium),
            Text(
              'Spend gold on hull refits and fitting tempering. These upgrades last for this voyage.',
              style: InkTheme.body,
            ),
            const SizedBox(height: 8),
            Text(
              'PURSE: ${ship.gold}g',
              key: const ValueKey('voyage-shipwright-purse'),
              style: InkTheme.statLabel.copyWith(color: InkTheme.goldAccent),
            ),
            const SizedBox(height: 12),
            Text('HULL TIER ${ship.level} / 4', style: InkTheme.statLabel),
            const SizedBox(height: 8),
            InkButton(
              label: ship.level < 4
                  ? 'UPGRADE TIER · ${cost}g'
                  : 'MAXIMUM HULL TIER',
              onPressed: ship.level < 4 && ship.gold >= cost
                  ? () => controller.dispatch(const UpgradeShip())
                  : null,
            ),
            const Divider(height: 28),
            Text('FITTING TEMPERING', style: InkTheme.statLabel),
            const SizedBox(height: 8),
            for (final slot in blessingHardpoints) ...[
              InkButton(
                label:
                    '${slot.displayName} · ${ship.markLabelForHardpoint(slot)}${ship.markForHardpoint(slot) < 3 ? ' · Temper ${calculateHardpointTemperCost(ship.markForHardpoint(slot))}g' : ' · Maximum'}',
                onPressed:
                    ship.markForHardpoint(slot) < 3 &&
                        ship.gold >=
                            calculateHardpointTemperCost(
                              ship.markForHardpoint(slot),
                            )
                    ? () => controller.dispatch(TemperHardpoint(slot))
                    : null,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    },
  );
}
