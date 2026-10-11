import 'package:flutter/material.dart';
import '../theme/ink_theme.dart';

/// Scrollable maritime combat log drawer displaying the chronicle of battle.
class CombatLogView extends StatelessWidget {
  const CombatLogView({
    super.key,
    required this.entries,
    this.scrollController,
  });

  final List<String> entries;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: InkTheme.parchmentSurface,
        border: Border.all(color: InkTheme.inkMuted, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: entries.isEmpty
          ? Center(
              child: Text(
                'The open water is calm... for now.',
                style: InkTheme.caption,
              ),
            )
          : ListView.builder(
              controller: scrollController,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isFatal = entry.contains('defeated') || entry.contains('sank');
                final isHit = entry.contains('hits') || entry.contains('damage');

                final color = isFatal
                    ? InkTheme.crimsonAccent
                    : isHit
                        ? InkTheme.inkPrimary
                        : InkTheme.inkMuted;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '• $entry',
                    style: InkTheme.caption.copyWith(
                      color: color,
                      fontSize: 14,
                      fontWeight: isFatal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
