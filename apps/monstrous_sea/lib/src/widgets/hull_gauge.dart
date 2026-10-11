import 'package:flutter/material.dart';
import '../theme/ink_theme.dart';

/// Renders a cross-hatched health meter displaying current vs max hull/vitality.
class HullGauge extends StatelessWidget {
  const HullGauge({
    super.key,
    required this.currentHp,
    required this.maxHp,
    this.label = 'HULL INTEGRITY',
    this.height = 18,
  });

  final int currentHp;
  final int maxHp;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pct = maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0.0;
    final isCritical = pct < 0.25;
    final isWounded = pct < 0.50;

    final barColor = isCritical
        ? InkTheme.crimsonAccent
        : isWounded
            ? InkTheme.goldAccent
            : InkTheme.verdigrisGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: InkTheme.statLabel,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$currentHp / $maxHp HP',
              style: InkTheme.statValue.copyWith(
                color: isCritical ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: InkTheme.parchmentDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: InkTheme.inkPrimary, width: 1.2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
