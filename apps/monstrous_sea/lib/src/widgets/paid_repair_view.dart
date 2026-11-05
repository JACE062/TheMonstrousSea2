import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'parchment_card.dart';

/// Service quotes come from the engine; building this view never spends or
/// fixes a repair allowance. Both repairs and refits remain independently usable.
class PaidRepairView extends StatelessWidget {
  const PaidRepairView({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final session = controller.session;
      final ship = controller.ship;
      final pool = session.paidRepairQuote(0);
      if (ship == null || pool == null) return const SizedBox.shrink();
      final quarter = session.paidRepairQuote(.25)!;
      final remaining = session.paidRepairQuote(1)!;
      final affordable = session.affordablePaidRepairQuote!;
      Widget purchase(double percentage, PaidRepairQuote quote) => InkButton(
        key: ValueKey('paid-repair-$percentage'),
        label: quote.restoredHp > 0
            ? 'REPAIR +${quote.restoredHp} HP · ${quote.goldCost}g'
            : ship.currentHp >= ship.maxHp
            ? 'HULL FULL'
            : 'NO REPAIRS REMAINING',
        onPressed:
            quote.restoredHp > 0 &&
                ship.gold >= quote.goldCost &&
                !controller.isPlayingEvents
            ? () => controller.dispatch(RepairShip(percentage))
            : null,
      );
      return ParchmentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PAID HULL REPAIRS', style: InkTheme.titleMedium),
            const SizedBox(height: 6),
            if (pool.totalWork != null)
              Text(
                'REPAIRS REMAINING: ${((pool.remainingWork ?? 0) * 100 / ship.maxHp).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}% HULL',
                key: const ValueKey('paid-repair-remaining'),
                style: InkTheme.statLabel,
              ),
            const SizedBox(height: 10),
            if (affordable.restoredHp > 0 &&
                affordable.normalWork < remaining.normalWork) ...[
              InkButton(
                key: const ValueKey('paid-repair-affordable'),
                label:
                    'REPAIR +${affordable.restoredHp} HP · ${affordable.goldCost}g',
                onPressed: !controller.isPlayingEvents
                    ? () =>
                          controller.dispatch(const BuyAffordablePaidRepairs())
                    : null,
              ),
              const SizedBox(height: 8),
            ],
            if (quarter.normalWork > 0 &&
                quarter.normalWork != remaining.normalWork) ...[
              purchase(.25, quarter),
              const SizedBox(height: 8),
            ],
            purchase(1, remaining),
          ],
        ),
      );
    },
  );
}
