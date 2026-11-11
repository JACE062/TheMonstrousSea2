import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';
import 'eldritch_relic_preview.dart';
import 'ink_button.dart';
import 'upgrade_comparison.dart';

class EldritchRelicOffer extends StatelessWidget {
  const EldritchRelicOffer({
    super.key,
    required this.preview,
    required this.costDescription,
    required this.onForge,
  });
  final EldritchRelicPreview preview;
  final String costDescription;
  final VoidCallback onForge;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: preview.isForged
          ? InkTheme.parchmentHighlight
          : InkTheme.parchmentSurface,
      border: Border.all(
        color: preview.isForged ? InkTheme.goldAccent : InkTheme.inkMuted,
        width: preview.isForged ? 1.8 : 1.0,
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
        Text(
          '${preview.blueprintName} · ${preview.definition.weaponType.displayName}',
          style: InkTheme.statLabel,
        ),
        const SizedBox(height: 8),
        Text(preview.definition.description, style: InkTheme.caption),
        const SizedBox(height: 8),
        Text('ADDED SIGNATURE EFFECTS', style: InkTheme.statLabel),
        const SizedBox(height: 6),
        for (final stat in preview.stats)
          UpgradeStatComparison(
            valueKey: ValueKey('relic-${preview.relic.name}-${stat.id}'),
            label: stat.label,
            current: stat.current,
            next: stat.next,
            linkKeywords: true,
          ),
        if (preview.isForged) ...[
          Text(
            'FORGED',
            style: InkTheme.statLabel.copyWith(color: InkTheme.goldAccent),
          ),
          Text(
            preview.isActive
                ? 'Active for ${preview.blueprintName}'
                : 'Inactive',
            style: InkTheme.caption,
          ),
        ] else ...[
          Text('Forge cost: $costDescription', style: InkTheme.body),
          const SizedBox(height: 8),
          if (!preview.blueprintUnlocked)
            Text(
              'REQUIRES ${preview.blueprintName.toUpperCase()}',
              style: InkTheme.statLabel.copyWith(color: InkTheme.crimsonAccent),
            )
          else
            InkButton(
              key: ValueKey('relic-forge-${preview.relic.name}'),
              label: preview.canForge ? 'FORGE RELIC' : 'LACKS MATERIALS',
              semanticLabel: 'Forge ${preview.definition.name}',
              semanticHint: costDescription,
              onPressed: preview.canForge ? onForge : null,
            ),
        ],
      ],
    ),
  );
}
