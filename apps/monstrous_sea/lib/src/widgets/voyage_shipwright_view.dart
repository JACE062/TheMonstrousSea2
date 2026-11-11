import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'parchment_card.dart';
import 'fitting_temper_preview.dart';
import 'hull_upgrade_preview.dart';
import 'upgrade_comparison.dart';

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
      final hullPreview = HullUpgradePreview(ship);
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
            _HullOffer(
              preview: hullPreview,
              gold: ship.gold,
              onUpgrade: () => controller.dispatch(const UpgradeShip()),
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

class _HullOffer extends StatelessWidget {
  const _HullOffer({
    required this.preview,
    required this.gold,
    required this.onUpgrade,
  });
  final HullUpgradePreview preview;
  final int gold;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) => ParchmentCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label:
              'Hull tier ${preview.currentTier}${preview.isMaximum ? ', maximum' : ' to ${preview.nextTier}'}',
          excludeSemantics: true,
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('HULL TIER', style: InkTheme.statLabel),
              UpgradeValueComparison(
                current: '${preview.currentTier}',
                next: preview.nextTier?.toString(),
                style: InkTheme.statLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final columns = constraints.maxWidth >= 760 * scale ? 2 : 1;
            final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 2,
              children: [
                for (final stat in preview.stats)
                  SizedBox(
                    width: width,
                    child: UpgradeStatComparison(
                      valueKey: ValueKey('hull-upgrade-${stat.id}'),
                      label: stat.label,
                      current: stat.current,
                      next: stat.next,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        InkButton(
          key: const ValueKey('hull-upgrade'),
          label: preview.isMaximum
              ? 'MAXIMUM HULL TIER'
              : 'UPGRADE TIER · ${preview.cost}g',
          semanticLabel: preview.isMaximum
              ? 'Maximum hull tier'
              : 'Refit to hull tier ${preview.nextTier} for ${preview.cost} gold',
          onPressed: !preview.isMaximum && gold >= preview.cost
              ? onUpgrade
              : null,
        ),
      ],
    ),
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
              UpgradeValueComparison(
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
          UpgradeStatComparison(
            valueKey: ValueKey('fitting-temper-${preview.slot.name}-stat-$i'),
            label: stat.label,
            current: stat.currentText,
            next: stat.nextText,
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
