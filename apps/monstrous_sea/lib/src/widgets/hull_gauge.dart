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
    final targetPct = maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0.0;
    final isCritical = targetPct < 0.25;

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
            // Dark crimson backing track clearly displaying lost hull/vitality
            color: InkTheme.crimsonAccent.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: InkTheme.inkPrimary, width: 1.4),
          ),
          clipBehavior: Clip.antiAlias,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: targetPct),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, animatedPct, child) {
              final isAnimatedCrit = animatedPct < 0.25;
              final isAnimatedWounded = animatedPct < 0.50;
              final barColor = isAnimatedCrit
                  ? InkTheme.crimsonAccent
                  : isAnimatedWounded
                      ? InkTheme.goldAccent
                      : InkTheme.verdigrisGreen;

              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animatedPct.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
