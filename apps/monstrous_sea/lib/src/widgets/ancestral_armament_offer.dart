import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';
import 'ancestral_armament_preview.dart';
import 'ink_button.dart';
import 'upgrade_comparison.dart';

class AncestralArmamentOffer extends StatelessWidget {
  const AncestralArmamentOffer({
    super.key,
    required this.preview,
    required this.canUpgrade,
    required this.costDescription,
    required this.onUpgrade,
  });
  final AncestralArmamentPreview preview;
  final bool canUpgrade;
  final String? costDescription;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        label:
            'Ancestral armament tier ${preview.currentTier}${preview.isMaximum ? ', maximum' : ' to ${preview.nextTier}'}',
        excludeSemantics: true,
        child: Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('ANCESTRAL ARMAMENT', style: InkTheme.statLabel),
            UpgradeValueComparison(
              current: 'Tier ${preview.currentTier}',
              next: preview.nextTier == null
                  ? null
                  : 'Tier ${preview.nextTier}',
              style: InkTheme.statLabel,
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(preview.name, style: InkTheme.bodyBold),
      const SizedBox(height: 6),
      UpgradeStatComparison(
        valueKey: ValueKey('ancestral-multiplier-${preview.blueprint.name}'),
        label: 'Signature damage multiplier',
        current: preview.currentMultiplierText,
        next: preview.nextMultiplierText,
      ),
      for (final (i, damage) in preview.mountedDamage.indexed)
        UpgradeStatComparison(
          valueKey: ValueKey('ancestral-damage-${preview.blueprint.name}-$i'),
          label: preview.mountedDamage.length == 1
              ? 'Mounted base damage'
              : '${damage.name} base damage',
          current: '${damage.current}',
          next: damage.next?.toString(),
        ),
      if (!preview.isMaximum) ...[
        Text('Permanent refit: $costDescription', style: InkTheme.body),
        const SizedBox(height: 8),
        InkButton(
          key: ValueKey('ancestral-upgrade-${preview.blueprint.name}'),
          label: canUpgrade
              ? 'UPGRADE TIER ${preview.nextTier}'
              : 'LACKS MATERIALS',
          semanticLabel:
              'Upgrade ${preview.blueprint.displayName} signature armament to Tier ${preview.nextTier}',
          onPressed: canUpgrade ? onUpgrade : null,
        ),
      ] else
        Text('MAX TIER', style: InkTheme.statLabel),
    ],
  );
}
