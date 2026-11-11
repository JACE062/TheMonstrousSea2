import 'package:monstrous_core/monstrous_core.dart';

/// Supported hull-refit effects, resolved without altering the player's vessel.
class HullUpgradePreview {
  HullUpgradePreview(ShipState ship)
    : currentTier = ship.level,
      cost = calculateShipUpgradeCost(ship.level) {
    final upgraded = ship.level < 4 ? ShipState.fromJson(ship.toJson()) : null;
    if (upgraded != null) upgradeShipState(upgraded);
    nextTier = upgraded?.level;
    final changes = <HullUpgradeStat>[
      HullUpgradeStat(
        id: 'hull',
        label: 'Hull integrity (HP)',
        current: '${ship.currentHp}/${ship.maxHp}',
        next: upgraded == null
            ? null
            : '${upgraded.currentHp}/${upgraded.maxHp}',
      ),
    ];
    void stat(
      String id,
      String label,
      int current,
      int? next, {
      bool percent = false,
      bool bonus = false,
    }) {
      if (next == current) return;
      String format(int value) =>
          '${bonus ? '+' : ''}$value${percent ? '%' : ''}';
      changes.add(
        HullUpgradeStat(
          id: id,
          label: label,
          current: format(current),
          next: next == null ? null : format(next),
        ),
      );
    }

    for (final (i, weapon) in ship.equippedWeapons.indexed) {
      stat(
        'weapon-$i',
        '${weapon.weaponType.displayName} base damage',
        weapon.damage,
        upgraded?.equippedWeapons[i].damage,
      );
    }
    if (upgraded != null || ship.baseEvasion > 0) {
      stat(
        'evasion',
        'Base evasion',
        ship.baseEvasion,
        upgraded?.baseEvasion,
        percent: true,
      );
    }
    if (upgraded != null || ship.baseDmgReduction > 0) {
      stat(
        'reduction',
        'Base damage reduction',
        ship.baseDmgReduction,
        upgraded?.baseDmgReduction,
      );
    }
    switch (ship.resolvedBlueprintId) {
      case BlueprintId.ironclad:
        stat(
          'fortify',
          'Iron Plates reduction per use',
          ship.fortifyDamageReductionGain,
          upgraded?.fortifyDamageReductionGain,
          bonus: true,
        );
      case BlueprintId.corsair:
        stat(
          'trap',
          'Tether-Trap Slicing damage',
          ship.tetherTrapDamage,
          upgraded?.tetherTrapDamage,
        );
      default:
        break;
    }
    // AC and weapon weight are retired mechanics, not refit benefits to expose.
    stats = List.unmodifiable(changes);
  }

  final int currentTier;
  final int cost;
  late final int? nextTier;
  late final List<HullUpgradeStat> stats;
  bool get isMaximum => nextTier == null;
}

class HullUpgradeStat {
  const HullUpgradeStat({
    required this.id,
    required this.label,
    required this.current,
    required this.next,
  });
  final String id;
  final String label;
  final String current;
  final String? next;
}
