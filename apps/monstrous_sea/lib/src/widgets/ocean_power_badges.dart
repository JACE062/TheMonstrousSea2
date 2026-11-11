import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import 'mechanic_text.dart';

/// Ordinary effects share the same row as power effects, without duplicate Burn.
List<Widget> _combatStatusBadges(Combatant combatant) => [
  for (final effect in combatant.statusEffects)
    if (!(effect == StatusEffect.burn &&
        combatant is MonsterState &&
        combatant.burnTurns > 0))
      _PowerBadge(
        label: effect.displayName,
        explanation: switch (effect) {
          StatusEffect.burn =>
            'Takes Fire damage each turn. 25% chance to go out afterward.',
          StatusEffect.poison =>
            'Takes venom damage each turn. 25% chance to clear afterward.',
          StatusEffect.stun => 'Loses its next action, then clears.',
        },
      ),
];

/// Keep one wrapping row beneath health, with no empty gap when effects clear.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => children.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 4, runSpacing: 4, children: children),
        );
}

/// Compact, wrapping readouts keep the underlying weapon and status legible.
class BlessingBadge extends StatelessWidget {
  const BlessingBadge({super.key, required this.blessing});
  final HardpointBlessing blessing;

  @override
  Widget build(BuildContext context) => MechanicScope(
    data: MechanicScope.of(context).withBlessing(blessing),
    child: _PowerBadge(
      label: '${blessing.tierLabel} · ${blessing.title}',
      explanation: '${blessing.power.displayName}. ${blessing.description}',
    ),
  );
}

class ShipPowerStatusBadges extends StatelessWidget {
  const ShipPowerStatusBadges({super.key, required this.ship});
  final ShipState ship;

  @override
  Widget build(BuildContext context) => _StatusRow(
    children: [
      if (ship.isGrappled)
        const _PowerBadge(
          label: 'Grappled',
          explanation: 'Prevents all ship movement this turn.',
        ),
      if (ship.tempAccuracyPenalty > 0)
        _PowerBadge(
          label: 'Accuracy −${ship.tempAccuracyPenalty}%',
          explanation: 'Shot accuracy penalty for this round.',
        ),
      if (ship.isBracedByDrill)
        const _PowerBadge(
          label: 'Braced · −20% incoming',
          explanation: 'Reduces incoming attack damage this round.',
        ),
      if (ship.basaltBarrierHp > 0)
        _PowerBadge(
          label: 'Basalt Barrier: ${ship.basaltBarrierHp} HP',
          explanation:
              'Absorbs damage. Retaliates with Tidal Shockwave when hit. ${ship.basaltAegisTurns} turn${ship.basaltAegisTurns == 1 ? '' : 's'} remaining.',
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
      ..._combatStatusBadges(ship),
    ],
  );
}

class MonsterPowerStatusBadges extends StatelessWidget {
  const MonsterPowerStatusBadges({super.key, required this.monster});
  final MonsterState monster;

  @override
  Widget build(BuildContext context) => MechanicScope(
    data: MechanicScope.of(context).withMonster(monster),
    child: _StatusRow(
      children: [
        if (monster.staticStacks > 0)
          _PowerBadge(
            label: 'Static Charge (${monster.staticStacks}/3)',
            explanation:
                'At 3 stacks, triggers Arc Discharge and consumes the stacks.',
          ),
        if (monster.corrodedStacks > 0)
          _PowerBadge(
            label:
                'Corroded (${monster.corrodedStacks}/3) · ${monster.corrodedTurns}T',
            condition: 'Corroded',
            explanation:
                'Amplifies all incoming damage and reduces monster attack damage by ${monster.corrodedStacks * 5}%.',
          ),
        if (monster.isElectroJolted)
          const _PowerBadge(
            label: 'Electro-Jolt (1T)',
            explanation:
                'Next enemy action: −30% accuracy, −25% attack damage.',
          ),
        if (monster.tremorAccPenalty > 0)
          _PowerBadge(
            label: 'Shaken -${monster.tremorAccPenalty}%',
            condition: 'Shaken',
            explanation: 'Monster accuracy reduced for its next action.',
          ),
        if (monster.burnTurns > 0)
          _PowerBadge(
            label: 'Burning (${monster.burnTurns}T)',
            condition: 'Burning',
            explanation: 'Takes Fire damage at the start of its turn.',
          ),
        ..._combatStatusBadges(monster),
      ],
    ),
  );
}

class _PowerBadge extends StatelessWidget {
  const _PowerBadge({
    required this.label,
    required this.explanation,
    this.condition,
  });
  final String? condition;
  final String label;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final message = condition == null
        ? explanation
        : MechanicScope.of(context).explanation(condition!);
    return MechanicTooltip(
      message: message,
      child: Semantics(
        label: '$label. $message',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: InkTheme.goldAccent.withValues(alpha: 0.10),
            border: Border.all(
              color: InkTheme.goldAccent.withValues(alpha: 0.7),
            ),
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
}
