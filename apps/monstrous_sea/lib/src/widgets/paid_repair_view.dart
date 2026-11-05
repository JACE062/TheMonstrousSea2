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
            : 'NO HULL WORK AVAILABLE',
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
            Text(
              pool.totalWork == null
                  ? 'Stronghold repair work is uncapped; pay for the restoration you need.'
                  : 'REPAIR WORK: ${pool.remainingWork} / ${pool.totalWork} normal HP remaining',
              key: const ValueKey('paid-repair-remaining'),
              style: InkTheme.statLabel,
            ),
            if (pool.totalWork != null) ...[
              const SizedBox(height: 6),
              Text(
                session.paidRepairWork.isLatched
                    ? 'Allowance fixed from ${pool.maximumHullBasis} maximum hull. Refits do not add or replenish paid work.'
                    : '${(session.paidRepairAllowanceFraction! * 100).round()}% of maximum hull when you first buy repairs. Refitting before that purchase increases the allowance.',
                style: InkTheme.body,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Captain healing: ${(ship.captainHealingMultiplier * 100).round()}% of normal work. Buttons show actual hull restoration and total cost.',
              style: InkTheme.caption,
            ),
            if (remaining.restoredHp == 0) ...[
              const SizedBox(height: 6),
              Text(
                ship.currentHp >= ship.maxHp ? 'Hull already full.' : 'No effective restoration remains from this visit’s work.',
                style: InkTheme.body,
              ),
            ],
            const SizedBox(height: 10),
            if (affordable.restoredHp > 0 &&
                affordable.normalWork < remaining.normalWork) ...[
              InkButton(
                key: const ValueKey('paid-repair-affordable'),
                label:
                    'BUY WITHIN PURSE: +${affordable.restoredHp} HP · ${affordable.goldCost}g',
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
