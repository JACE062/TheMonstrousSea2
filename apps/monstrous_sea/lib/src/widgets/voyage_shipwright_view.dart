import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'parchment_card.dart';
import 'fitting_temper_preview.dart';

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
            Text('Refits last for this voyage.', style: InkTheme.body),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final columns = constraints.maxWidth >= 1050 * scale ? 3 : 1;
                final width =
                    (constraints.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final slot in blessingHardpoints)
                      SizedBox(
                        width: width,
                        child: _FittingOffer(
                          preview: FittingTemperPreview(ship, slot),
                          gold: ship.gold,
                          onTemper: () =>
                              controller.dispatch(TemperHardpoint(slot)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _FittingOffer extends StatelessWidget {
  const _FittingOffer({
    required this.preview,
    required this.gold,
    required this.onTemper,
  });
  final FittingTemperPreview preview;
  final int gold;
  final VoidCallback onTemper;

  @override
  Widget build(BuildContext context) => ParchmentCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label:
              '${preview.slot.displayName}, ${preview.currentMark}${preview.isMaximum ? '' : ' to ${preview.nextMark}'}',
          excludeSemantics: true,
          child: Wrap(
            spacing: 8,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(preview.slot.displayName, style: InkTheme.statLabel),
              _ValueComparison(
                current: preview.currentMark,
                next: preview.nextMark,
                style: InkTheme.statLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(preview.name, style: InkTheme.titleMedium),
        const SizedBox(height: 8),
        for (final (i, stat) in preview.stats.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Semantics(
              label:
                  '${stat.label}: ${stat.currentText}${stat.nextText == null ? '' : ' to ${stat.nextText}'}',
              excludeSemantics: true,
              child: Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${stat.label}:', style: InkTheme.body),
                  _ValueComparison(
                    key: ValueKey(
                      'fitting-temper-${preview.slot.name}-stat-$i',
                    ),
                    current: stat.currentText,
                    next: stat.nextText,
                    style: InkTheme.bodyBold,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        InkButton(
          key: ValueKey('temper-${preview.slot.name}'),
          label: preview.isMaximum
              ? 'MAXIMUM TEMPERING'
              : 'TEMPER · ${preview.cost}g',
          semanticLabel: preview.isMaximum
              ? '${preview.name}, maximum tempering'
              : 'Temper ${preview.name} from ${preview.currentMark} to ${preview.nextMark} for ${preview.cost} gold',
          onPressed: !preview.isMaximum && gold >= preview.cost
              ? onTemper
              : null,
        ),
      ],
    ),
  );
}

/// Draw arrows as icons: the atmospheric fonts do not contain that glyph.
class _ValueComparison extends StatelessWidget {
  const _ValueComparison({
    super.key,
    required this.current,
    required this.next,
    required this.style,
  });
  final String current;
  final String? next;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(current, style: style),
      if (next != null) ...[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_right_alt,
            size: 20,
            color: InkTheme.inkMuted,
          ),
        ),
        Text(next!, style: style.copyWith(color: InkTheme.goldAccent)),
      ],
    ],
  );
}
