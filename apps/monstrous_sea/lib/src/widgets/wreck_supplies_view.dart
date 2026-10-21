import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'parchment_card.dart';

/// Explicit claim/jettison decisions for supplies that did not fit on the belt.
class WreckSuppliesView extends StatelessWidget {
  const WreckSuppliesView({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship!;
    final full = ship.cargo.length >= ship.maxCargo;
    return ParchmentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'RECOVERED SUPPLIES · BELT ${ship.cargo.length}/${ship.maxCargo}',
            style: InkTheme.statValue,
          ),
          Text(
            full
                ? 'Belt full. Jettison an item to stow the recovered supply, or leave it behind.'
                : 'Stow the recovered supply, or leave it behind.',
            style: InkTheme.body,
          ),
          for (var i = 0; i < controller.pendingLoot.length; i++) ...[
            const SizedBox(height: 10),
            Text(controller.pendingLoot[i].name, style: InkTheme.statValue),
            InkButton(
              label: 'STOW SUPPLY',
              onPressed: full
                  ? null
                  : () => controller.dispatch(TakeLootItem(i)),
            ),
          ],
          if (full)
            for (var i = 0; i < ship.cargo.length; i++) ...[
              const SizedBox(height: 10),
              Text(ship.cargo[i].name, style: InkTheme.body),
              InkButton(
                label: 'JETTISON ${ship.cargo[i].name}',
                isDanger: true,
                onPressed: () => controller.dispatch(DropCargoItem(i)),
              ),
            ],
          const SizedBox(height: 10),
          InkButton(
            label: 'LEAVE UNCLAIMED SUPPLIES',
            onPressed: () => controller.dispatch(const LeaveRemainingLoot()),
          ),
        ],
      ),
    );
  }
}
