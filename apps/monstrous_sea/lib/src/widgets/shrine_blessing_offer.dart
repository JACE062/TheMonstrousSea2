import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'mechanic_text.dart';
import 'parchment_card.dart';
import 'shrine_blessing_preview.dart';
import 'upgrade_comparison.dart';

class ShrineBlessingOffer extends StatelessWidget {
  const ShrineBlessingOffer({
    super.key,
    required this.preview,
    required this.onAccept,
  });
  final ShrineBlessingPreview preview;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) => MechanicScope(
    data: MechanicContext(
      ship: preview.prospectiveShip,
      blessing: preview.displayed,
      regionIndex: preview.regionIndex,
    ),
    child: ParchmentCard(
      borderColor: preview.isLocked ? InkTheme.inkFaint : InkTheme.goldAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            preview.slot.displayName.toUpperCase(),
            style: InkTheme.statLabel,
          ),
          const SizedBox(height: 8),
          Text(preview.displayed.title, style: InkTheme.titleMedium),
          UpgradeStatComparison(
            valueKey: ValueKey('shrine-tier-${preview.slot.name}'),
            label: 'Blessing',
            current: preview.current?.tierLabel ?? 'Undedicated',
            next: preview.next?.tierLabel,
          ),
          const SizedBox(height: 8),
          MechanicText(preview.summary, style: InkTheme.body),
          const SizedBox(height: 8),
          for (final stat in preview.stats)
            UpgradeStatComparison(
              valueKey: ValueKey('shrine-${preview.slot.name}-${stat.id}'),
              label: stat.label,
              current: stat.current,
              next: stat.next,
              linkKeywords: true,
            ),
          if (preview.restriction != null) ...[
            Text(preview.restriction!, style: InkTheme.statLabel),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          InkButton(
            key: ValueKey('bless-${preview.slot.name}'),
            label: preview.isLocked
                ? 'LOCKED'
                : preview.current == null
                ? 'DEDICATE'
                : 'UPGRADE',
            semanticLabel: preview.isLocked
                ? '${preview.slot.displayName}: ${preview.restriction}'
                : '${preview.current == null ? 'Dedicate' : 'Upgrade'} ${preview.slot.displayName}: ${preview.displayed.title}, ${preview.displayed.tierLabel}',
            isPrimary: !preview.isLocked,
            onPressed: preview.isLocked ? null : onAccept,
          ),
        ],
      ),
    ),
  );
}
