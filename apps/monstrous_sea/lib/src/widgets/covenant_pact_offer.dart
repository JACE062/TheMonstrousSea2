import 'package:flutter/material.dart';

import '../theme/ink_theme.dart';
import 'covenant_pact_preview.dart';
import 'upgrade_comparison.dart';

class CovenantPactOffer extends StatelessWidget {
  const CovenantPactOffer({
    super.key,
    required this.preview,
    required this.onToggle,
  });
  final CovenantPactPreview preview;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: preview.isActive
          ? InkTheme.crimsonAccent.withValues(alpha: 0.08)
          : InkTheme.parchmentSurface,
      border: Border.all(
        color: preview.isActive ? InkTheme.crimsonAccent : InkTheme.inkMuted,
        width: preview.isActive ? 1.6 : 1,
      ),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: preview.canToggle ? onToggle : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.definition.name.toUpperCase(),
                      style: InkTheme.titleMedium.copyWith(
                        color: preview.isActive
                            ? InkTheme.crimsonAccent
                            : InkTheme.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(preview.definition.flavor, style: InkTheme.caption),
                  ],
                ),
              ),
            ),
            Checkbox(
              key: ValueKey('pact-toggle-${preview.pact.name}'),
              semanticLabel:
                  '${preview.isActive ? 'Rescind' : 'Ratify'} ${preview.definition.name}',
              activeColor: InkTheme.crimsonAccent,
              value: preview.isActive,
              onChanged: preview.canToggle ? (_) => onToggle() : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final stat in preview.stats)
          UpgradeStatComparison(
            valueKey: ValueKey('pact-${preview.pact.name}-${stat.id}'),
            label: stat.label,
            current: stat.current,
            next: stat.next,
            linkKeywords: true,
          ),
      ],
    ),
  );
}
