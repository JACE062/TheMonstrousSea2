import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';

/// Compact, wrapping readouts keep the underlying weapon and status legible.
class BlessingBadge extends StatelessWidget {
  const BlessingBadge({super.key, required this.blessing});
  final HardpointBlessing blessing;

  @override
  Widget build(BuildContext context) => _PowerBadge(
    label: '${blessing.tierLabel} · ${blessing.title}',
    explanation:
        '${blessing.power.displayName}: ${blessing.subtitle}. ${blessing.description}',
  );
}

class ShipPowerStatusBadges extends StatelessWidget {
  const ShipPowerStatusBadges({super.key, required this.ship});
  final ShipState ship;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      if (ship.basaltBarrierHp > 0)
        _PowerBadge(
          label: 'Basalt Barrier: ${ship.basaltBarrierHp} HP',
          explanation:
              'Basalt Aegis (${ship.basaltAegisTurns}T): absorbs incoming damage and returns a Tidal Shockwave when struck.',
        ),
      if (ship.stormRiggingTurns > 0)
        _PowerBadge(
          label: 'Storm Rigging (${ship.stormRiggingTurns}T)',
          explanation: 'Monster attacks trigger retaliatory Shock damage and Static Charge.',
        ),
      if (ship.boilingWakeTurns > 0)
        _PowerBadge(
          label: 'Boiling Wake (${ship.boilingWakeTurns}T)',
          explanation: 'Monster movement through the wake takes Fire damage.',
        ),
    ],
  );
}

class MonsterPowerStatusBadges extends StatelessWidget {
  const MonsterPowerStatusBadges({super.key, required this.monster});
  final MonsterState monster;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      if (monster.staticStacks > 0)
        _PowerBadge(
          label: 'Static Charge (${monster.staticStacks}/3)',
          explanation: 'At 3 stacks, Arc Discharge purges Frenzy and shatters a lethal windup or applies Electro-Jolt.',
        ),
      if (monster.corrodedStacks > 0)
        _PowerBadge(
          label:
              'Corroded (${monster.corrodedStacks}/3) · ${monster.corrodedTurns}T',
          explanation:
              'Amplifies all incoming damage and reduces monster attack damage by ${monster.corrodedStacks * 5}%.',
        ),
      if (monster.isElectroJolted)
        const _PowerBadge(
          label: 'Electro-Jolt (1T)',
          explanation:
              'Monster accuracy -30%; attack damage -25% for its next action.',
        ),
      if (monster.tremorAccPenalty > 0)
        _PowerBadge(
          label: 'Tremor -${monster.tremorAccPenalty}%',
          explanation: 'Monster accuracy reduced for its next action.',
        ),
      if (monster.burnTurns > 0)
        _PowerBadge(
          label: 'Ignited (${monster.burnTurns}T)',
          explanation: 'Burning: takes Fire damage at the start of its turn. Enables Thermal Detonation.',
        ),
    ],
  );
}

class _PowerBadge extends StatelessWidget {
  const _PowerBadge({required this.label, required this.explanation});
  final String label;
  final String explanation;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: explanation,
    child: Semantics(
      label: '$label. $explanation',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: InkTheme.goldAccent.withValues(alpha: 0.10),
          border: Border.all(color: InkTheme.goldAccent.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: InkTheme.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
