import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import 'mechanic_text.dart';

/// Read only the detached actors supplied by combat presentation. Each effect
/// owns its hover/long-press target instead of inheriting the dodge explanation.
class ShipCombatStats extends StatelessWidget {
  const ShipCombatStats({super.key, required this.ship});
  final ShipState ship;

  @override
  Widget build(BuildContext context) {
    final volleyBonus =
        (20 * ship.hardpointMarkMultiplier(HardpointType.utility)).round();
    return Wrap(
      spacing: 4,
      children: [
        _Stat('Level ${ship.level} ${ship.shipClass.name.toUpperCase()}'),
        if (ship.currentDmgReduction > 0)
          _Stat(
            '• Fortified: -${ship.currentDmgReduction} Dmg',
            key: const ValueKey('ship-stat-fortified'),
            explanation:
                'Reduces each incoming hit by ${ship.currentDmgReduction} damage. '
                'Fortification lasts for the rest of this battle.',
          ),
        _Stat(
          '• Evade: ${ship.effectiveEvasion}%',
          key: const ValueKey('ship-stat-evasion'),
          explanation: 'Current dodge chance after captain, regional and active-effect modifiers, capped at 95%. Unavoidable attacks bypass dodge.',
        ),
        if (ship.isAnchoredThisTurn)
          const _Stat(
            '• Anchored',
            key: ValueKey('ship-stat-anchored'),
            explanation: 'Prevents forced movement this round.',
          ),
        if (ship.gunneryDrillBuffActive)
          _Stat(
            '• Braced Volley (+15% Accuracy/+$volleyBonus% Damage)',
            key: const ValueKey('ship-stat-braced-volley'),
            explanation:
                'The next volley gains +15% accuracy and +$volleyBonus% damage.',
          ),
        if (ship.pitchCoatingActive)
          const _Stat(
            '• Pitch Coated · +25% volley damage',
            key: ValueKey('ship-stat-pitch'),
            explanation: 'The next volley gains +25% damage; connecting hits apply Burning.',
          ),
      ],
    );
  }
}

class MonsterCombatStats extends StatelessWidget {
  const MonsterCombatStats({
    super.key,
    required this.monster,
    required this.ship,
  });
  final MonsterState monster;
  final ShipState ship;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    children: [
      _Stat('Danger Level ${monster.level}'),
      if (monster.numberOfTentacles > 0)
        _Stat('• ${monster.numberOfTentacles} Tentacles'),
      if (monster.frenzyStacks > 0)
        _Stat(
          '• Frenzy: +${monster.frenzyStacks * 25}%',
          key: const ValueKey('monster-stat-frenzy'),
          explanation:
              'Frenzy increases attack damage by ${monster.frenzyStacks * 25}%.',
        ),
      _Stat(
        '• Dodge: ${monster.effectiveEvasion}%',
        key: const ValueKey('monster-stat-dodge'),
        explanation: 'Current dodge chance after Pin and Spotter Flare. Attack accuracy is a separate roll.',
      ),
      if (monster.obscurityAccuracyPenalty > 0)
        _Stat(
          '• Obscurity: -${monster.obscurityAccuracyPenalty}% shot accuracy',
          key: const ValueKey('monster-stat-obscurity'),
          explanation:
              'Reduces shot accuracy by ${monster.obscurityAccuracyPenalty}%. Successful hits have a 25% chance to clear it, lasts until cleared.',
        ),
      if (monster.isPinnedThisTurn)
        const _Stat(
          '• Pinned',
          key: ValueKey('monster-stat-pinned'),
          explanation: 'Prevents movement and halves dodge this turn.',
        ),
      if (monster.spotterFlareTurns > 0)
        _Stat(
          '• ☀️ Illuminated (${monster.spotterFlareTurns}T)',
          key: const ValueKey('monster-stat-illuminated'),
          explanation:
              'Suppresses Obscurity and dodge. Shots gain +${monster.spotterFlareAccuracyBonus}% accuracy; '
              'Blast damage taken increases by ${(monster.spotterFlareBlastBonus * 100).round()}%.',
        ),
      if (ship.activeTetherTrapDistance != null)
        _Stat(
          '• 🪤 Trap: ${ship.activeTetherTrapDistance} Band${ship.activeTetherTrapDistance == 1 ? '' : 's'}',
          key: const ValueKey('monster-stat-trap'),
          explanation: 'The tether-trap drifts closer each round. Contact deals Slicing damage and Pins.',
        ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, {super.key, this.explanation});
  final String label;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, style: InkTheme.caption);
    return explanation == null
        ? text
        : MechanicTooltip(message: explanation!, child: text);
  }
}
