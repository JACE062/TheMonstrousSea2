import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';

/// Screen rendered upon encountering an Ancient Sea Shrine rising from the depths,
/// presenting the captain with atmospheric regional lore and interactive devotions.
class ShrineScreen extends StatefulWidget {
  const ShrineScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });
  final GameController controller;
  final VoidCallback onOpenChart;

  @override
  State<ShrineScreen> createState() => _ShrineScreenState();
}

class _ShrineScreenState extends State<ShrineScreen> {
  OceanPower? _selectedPower;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ship = controller.ship;
        final powers = controller.shrineManifestedPowers;
        final selected = powers.contains(_selectedPower) &&
                _selectedPower != controller.forbiddenShrinePower
            ? _selectedPower
            : null;
        return ParchmentScaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkButton(
                        label: 'SEA CHART',
                        onPressed: widget.onOpenChart,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (controller.currentShrineName.isEmpty
                              ? 'Ancient Sea Shrine'
                              : controller.currentShrineName)
                          .toUpperCase(),
                      style: InkTheme.titleLarge.copyWith(fontSize: 26),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ParchmentCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ANCIENT RUNIC INSCRIPTION',
                            style: InkTheme.statLabel,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.currentShrineLore.isEmpty
                                ? 'Four ancient wardens lend their wrath against the Abyssal Font. Each dedication endures for this voyage.'
                                : controller.currentShrineLore,
                            style: InkTheme.body.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ship != null) ...[
                      const SizedBox(height: 12),
                      HullGauge(
                        currentHp: ship.currentHp,
                        maxHp: ship.maxHp,
                        label: ship.name,
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (controller.hasCommunedAtCurrentShrine) ...[
                      ParchmentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMMUNION COMPLETE',
                              style: InkTheme.statValue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The phosphorescent glow dims as the wardens withdraw. The sea ahead awaits your passage.',
                              style: InkTheme.body,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkButton(
                        label: 'DEPART SHRINE & SET SAIL',
                        isPrimary: true,
                        onPressed: () =>
                            controller.dispatch(const DepartShrine()),
                      ),
                    ] else ...[
                      Text(
                        '1 · CHOOSE A PRIMORDIAL',
                        style: InkTheme.statValue,
                      ),
                      const SizedBox(height: 8),
                      if (powers.isEmpty)
                        Text(
                          'Your dedications are complete. Offer respects and seek guidance in the runes.',
                          style: InkTheme.body,
                        )
                      else
                        _responsiveCards([
                          for (final power in powers)
                            _powerCard(power, selected == power),
                        ], breakpoint: 600),
                      const SizedBox(height: 20),
                      if (selected != null && ship != null) ...[
                        Text(
                          '2 · DEDICATE A FITTING',
                          style: InkTheme.statValue,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A dedication lasts for this voyage. You may switch wardens above before committing.',
                          style: InkTheme.caption,
                        ),
                        const SizedBox(height: 10),
                        _responsiveCards([
                          for (final slot in [
                            HardpointType.broadside,
                            HardpointType.signature,
                            HardpointType.utility,
                          ])
                            _hardpointCard(ship, selected, slot),
                        ], breakpoint: 800),
                        const SizedBox(height: 20),
                      ],
                      ParchmentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('RUNIC GUIDANCE', style: InkTheme.statValue),
                            const SizedBox(height: 6),
                            Text(
                              'Offer respects without a dedication. Gain +10% accuracy in the next combat and reveal adjacent sea chart nodes.',
                              style: InkTheme.body,
                            ),
                            const SizedBox(height: 12),
                            InkButton(
                              key: const ValueKey('read-runes'),
                              label: 'READ THE ANCIENT RUNES',
                              semanticLabel: 'Read the ancient runes and offer respects for runic guidance',
                              onPressed: () => controller.dispatch(
                                const CommuneWithShrine(
                                  ShrineChoice.ancientRunes,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            controller.dispatch(const DepartShrine()),
                        child: const Text('SAIL PAST IN REVERENCE'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _responsiveCards(List<Widget> cards, {required double breakpoint}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _powerCard(OceanPower power, bool selected) {
    final forbidden = widget.controller.forbiddenShrinePower == power;
    return ParchmentCard(
      borderColor: selected ? InkTheme.goldAccent : InkTheme.inkMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(power.displayName, style: InkTheme.titleMedium),
          const SizedBox(height: 8),
          Text(power.domainLore, style: InkTheme.body),
          const SizedBox(height: 8),
          Text(power.synergySummary, style: InkTheme.caption),
          if (forbidden) ...[
            const SizedBox(height: 8),
            Text('ILL OMEN - Superstition forbids this power.',
                style: InkTheme.statLabel.copyWith(color: InkTheme.crimsonAccent)),
          ],
          const SizedBox(height: 12),
          Semantics(
            selected: selected,
            child: InkButton(
              key: ValueKey('select-${power.name}'),
              label: forbidden ? 'FORBIDDEN' : selected ? 'COMMUNING' : 'COMMUNE',
              semanticLabel: 'Commune with ${power.displayName}',
              isPrimary: selected,
              onPressed: forbidden ? null : () => setState(() => _selectedPower = power),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hardpointCard(ShipState ship, OceanPower power, HardpointType slot) {
    final current = ship.blessings[slot];
    final otherPower = current != null && current.power != power;
    final maxed = current != null && current.tier >= 3;
    final locked = otherPower || maxed;
    final preview = locked
        ? current
        : HardpointBlessing(
            power: power,
            slot: slot,
            tier: (current?.tier ?? 0) + 1,
          );
    final reason = otherPower
        ? 'Dedicated to ${current.power.displayName}'
        : 'Max Sovereign Tier Reached';
    return ParchmentCard(
      key: ValueKey('hardpoint-${slot.name}'),
      borderColor: locked ? InkTheme.inkFaint : InkTheme.goldAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(slot.displayName.toUpperCase(), style: InkTheme.statLabel),
          const SizedBox(height: 8),
          Text(preview.title, style: InkTheme.titleMedium),
          Text(
            preview.tierLabel,
            style: InkTheme.statValue.copyWith(color: InkTheme.goldAccent),
          ),
          const SizedBox(height: 8),
          Text(preview.description, style: InkTheme.body),
          if (!locked && current != null) ...[
            const SizedBox(height: 8),
            Text(
              '${current.tierLabel} → ${preview.tierLabel}',
              style: InkTheme.statValue.copyWith(
                color: InkTheme.verdigrisGreen,
              ),
            ),
            if (preview.damageBonus != current.damageBonus)
              Text(
                'Weapon damage +${(current.damageBonus * 100).round()}% → +${(preview.damageBonus * 100).round()}%',
                style: InkTheme.body.copyWith(color: InkTheme.verdigrisGreen),
              ),
            if (preview.critChanceBonus != current.critChanceBonus)
              Text(
                'Critical chance +${current.critChanceBonus}% → +${preview.critChanceBonus}%',
                style: InkTheme.body.copyWith(color: InkTheme.verdigrisGreen),
              ),
            Text('Current: ${current.description}', style: InkTheme.caption),
          ],
          const SizedBox(height: 12),
          if (locked) ...[
            Text(reason, style: InkTheme.statLabel),
            const SizedBox(height: 8),
          ],
          InkButton(
            key: ValueKey('bless-${slot.name}'),
            label: locked
                ? 'LOCKED'
                : current == null
                ? 'DEDICATE'
                : 'UPGRADE',
            semanticLabel: locked
                ? '${slot.displayName}: $reason'
                : '${current == null ? 'Dedicate' : 'Upgrade'} ${slot.displayName}: ${preview.title}, ${preview.tierLabel}',
            isPrimary: !locked,
            onPressed: locked
                ? null
                : () => widget.controller.dispatch(
                    AcceptShrineBlessing(power, slot),
                  ),
          ),
        ],
      ),
    );
  }
}
