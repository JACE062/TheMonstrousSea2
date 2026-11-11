import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';
import 'harbor_monument_preview.dart';
import 'ink_button.dart';
import 'upgrade_comparison.dart';

class HarborMonumentOffer extends StatelessWidget {
  const HarborMonumentOffer({
    super.key,
    required this.preview,
    required this.canUpgrade,
    required this.costDescription,
    required this.onUpgrade,
  });

  final HarborMonumentPreview preview;
  final bool canUpgrade;
  final String costDescription;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: preview.currentRank > 0
          ? InkTheme.parchmentHighlight
          : InkTheme.parchmentSurface,
      border: Border.all(
        color: preview.currentRank > 0
            ? InkTheme.goldAccent
            : InkTheme.inkMuted,
        width: preview.currentRank > 0 ? 1.8 : 1.0,
      ),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          preview.definition.name.toUpperCase(),
          style: InkTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(preview.definition.subtitle, style: InkTheme.caption),
        const SizedBox(height: 8),
        UpgradeStatComparison(
          valueKey: ValueKey('monument-rank-${preview.monument.name}'),
          label: 'Rank',
          current: '${preview.currentRank}',
          next: '${preview.nextRank}',
        ),
        UpgradeStatComparison(
          valueKey: ValueKey('monument-bonus-${preview.monument.name}'),
          label: preview.label,
          current: preview.currentText,
          next: preview.nextText,
        ),
        Text('Cost: $costDescription', style: InkTheme.body),
        const SizedBox(height: 8),
        InkButton(
          key: ValueKey('monument-upgrade-${preview.monument.name}'),
          label: canUpgrade
              ? 'UPGRADE (Rank ${preview.nextRank})'
              : 'LACKS MATERIALS',
          semanticLabel:
              'Upgrade ${preview.definition.name} to Rank ${preview.nextRank}',
          semanticHint: costDescription,
          onPressed: canUpgrade ? onUpgrade : null,
        ),
      ],
    ),
  );
}
