import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../theme/ink_theme.dart';

/// Renders compact antique badges displaying damage, charge time, hit bonus,
/// weapon battery type, and status effects for weapons and equipment.
class WeaponStatsView extends StatelessWidget {
  const WeaponStatsView({
    super.key,
    required this.item,
    this.compact = false,
  });

  final Item item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (item is ShipWeapon) {
      final weapon = item as ShipWeapon;
      final shortPct = (weaponRangeDamageMultiplier(weapon.weaponType, CombatRange.short) * 100).round();
      final medPct = (weaponRangeDamageMultiplier(weapon.weaponType, CombatRange.medium) * 100).round();
      final longPct = isWeaponTypeUsableAtRange(weapon.weaponType, CombatRange.long)
          ? '${(weaponRangeDamageMultiplier(weapon.weaponType, CombatRange.long) * 100).round()}%'
          : '—';
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _statBadge(
            '${weapon.damage} ${weapon.damageType.displayName}',
            icon: Icons.flash_on,
            color: InkTheme.crimsonAccent,
          ),
          _statBadge(
            weapon.chargeTime == 0 ? '0T Reload' : '${weapon.chargeTime}T CD',
            icon: Icons.timer,
            color: InkTheme.inkPrimary,
          ),
          _statBadge(
            'S:$shortPct% / M:$medPct% / L:$longPct',
            icon: Icons.straighten,
            color: InkTheme.inkSecondary,
          ),
          _statBadge(
            '+${weapon.hitModifier} Hit',
            icon: Icons.adjust,
            color: InkTheme.verdigrisGreen,
          ),
          if (weapon.statusEffect != null)
            _statBadge(
              weapon.statusEffect!.displayName,
              icon: Icons.coronavirus,
              color: InkTheme.goldAccent,
            ),
        ],
      );
    }

    if (item is Consumable) {
      final consumable = item as Consumable;
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _statBadge(
            '${consumable.usesLeft}/${consumable.maxUses} Uses',
            icon: Icons.science,
            color: InkTheme.goldAccent,
          ),
          _statBadge(
            '0T Quick Action',
            icon: Icons.bolt,
            color: InkTheme.verdigrisGreen,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _statBadge(String label, {IconData? icon, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: InkTheme.parchmentHighlight,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 10 : 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: InkTheme.statLabel.copyWith(
              fontSize: compact ? 10 : 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
