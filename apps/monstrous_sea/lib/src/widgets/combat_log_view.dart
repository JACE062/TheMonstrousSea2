import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';

/// Scrollable maritime combat log drawer displaying the chronicle of battle
/// with clear visual separation: ship actions on the left, beast actions on the right,
/// and ambient events centered.
class CombatLogView extends StatelessWidget {
  const CombatLogView({
    super.key,
    required this.entries,
    this.scrollController,
  });

  /// Accepts either [List<CombatLogEntry>] or [List<String>] for maximum versatility.
  final List<dynamic> entries;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: InkTheme.parchmentSurface,
        border: Border.all(color: InkTheme.inkMuted, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        children: [
          // Header legend differentiating the sides
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 640) {
                  return Text(
                    'CHRONICLE OF BATTLE',
                    style: InkTheme.caption.copyWith(
                      fontSize: 11.5,
                      color: InkTheme.inkMuted,
                    ),
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: InkTheme.verdigrisGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'VESSEL VOLLEYS',
                          style: InkTheme.statLabel.copyWith(
                            fontSize: 11.5,
                            color: InkTheme.verdigrisGreen,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'CHRONICLE OF BATTLE',
                      style: InkTheme.caption.copyWith(
                        fontSize: 11.5,
                        letterSpacing: 1.2,
                        color: InkTheme.inkMuted,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'BEAST STRIKES',
                          style: InkTheme.statLabel.copyWith(
                            fontSize: 11.5,
                            color: InkTheme.crimsonAccent,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: InkTheme.crimsonAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 4),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'The open swell is calm... for now.',
                      style: InkTheme.caption,
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final item = entries[index];
                      final CombatLogEntry entry = item is CombatLogEntry
                          ? item
                          : CombatLogEntry(
                              message: item.toString(),
                              actor:
                                  item.toString().contains('beast') ||
                                      item.toString().contains('Kraken') ||
                                      item.toString().contains('spewed')
                                  ? CombatLogActor.monster
                                  : CombatLogActor.ship,
                            );

                      return _buildEntryRow(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryRow(CombatLogEntry entry) {
    final isShip = entry.actor == CombatLogActor.ship;
    final isMonster = entry.actor == CombatLogActor.monster;
    final isAmbient = entry.actor == CombatLogActor.ambient;

    if (isAmbient) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: InkTheme.parchmentDark.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '~ ${entry.message} ~',
              style: InkTheme.caption.copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: entry.isCritical
                    ? InkTheme.crimsonAccent
                    : InkTheme.inkMuted,
                fontWeight: entry.isCritical
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final alignment = isShip ? Alignment.centerLeft : Alignment.centerRight;
    final borderColor = isShip
        ? InkTheme.verdigrisGreen
        : InkTheme.crimsonAccent;
    final badgeColor = isShip
        ? InkTheme.verdigrisGreen
        : InkTheme.crimsonAccent;
    final badgeLabel = isShip ? 'VESSEL' : 'BEAST';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isShip
                  ? InkTheme.parchmentHighlight.withValues(alpha: 0.7)
                  : InkTheme.crimsonAccent.withValues(alpha: 0.08),
              border: Border(
                left: isShip
                    ? BorderSide(color: borderColor, width: 3)
                    : BorderSide.none,
                right: isMonster
                    ? BorderSide(color: borderColor, width: 3)
                    : BorderSide.none,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isShip ? 0 : 4),
                bottomLeft: Radius.circular(isShip ? 0 : 4),
                topRight: Radius.circular(isMonster ? 0 : 4),
                bottomRight: Radius.circular(isMonster ? 0 : 4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isShip) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    margin: const EdgeInsets.only(right: 6, top: 1),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      badgeLabel,
                      style: InkTheme.statLabel.copyWith(
                        fontSize: 11,
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                Flexible(
                  child: Text(
                    entry.message,
                    style: InkTheme.caption.copyWith(
                      color: entry.isCritical
                          ? InkTheme.crimsonAccent
                          : InkTheme.inkPrimary,
                      fontSize: 14.5,
                      fontWeight: entry.isCritical
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isMonster) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    margin: const EdgeInsets.only(left: 6, top: 1),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      badgeLabel,
                      style: InkTheme.statLabel.copyWith(
                        fontSize: 11,
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
