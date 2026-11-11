import 'package:monstrous_core/monstrous_core.dart';

/// Read-only intrinsic changes for one purchase; no combat, RNG or live mutation.
class FittingTemperPreview {
  FittingTemperPreview(ShipState ship, HardpointType requestedSlot)
    : slot = requestedSlot.canonical,
      currentMark = ship.markLabelForHardpoint(requestedSlot),
      cost = calculateHardpointTemperCost(
        ship.markForHardpoint(requestedSlot),
      ) {
    final upgraded = ship.markForHardpoint(slot) < 3
        ? ShipState.fromJson(ship.toJson())
        : null;
    if (upgraded != null) temperShipHardpoint(upgraded, slot);
    nextMark = upgraded?.markLabelForHardpoint(slot);
    final blueprint = ship.resolvedBlueprintId;
    name = switch (slot) {
      HardpointType.broadside => blueprint.broadsideWeaponType.displayName,
      HardpointType.signature => blueprint.signatureWeaponType.displayName,
      _ => blueprint.utilityHardpoint.displayName,
    };
    if (slot != HardpointType.utility) {
      final weapons = ship.equippedWeapons
          .where((w) => w.isSignature == (slot == HardpointType.signature))
          .toList();
      final nextWeapons = upgraded?.equippedWeapons
          .where((w) => w.isSignature == (slot == HardpointType.signature))
          .toList();
      stats = [
        for (var i = 0; i < weapons.length; i++)
          FittingTemperStat(
            label:
                '${weapons.length > 1 ? '${weapons[i].weaponType.displayName} · ' : ''}Base ${weapons[i].damageType.displayName} damage',
            current: weapons[i].damage,
            next: nextWeapons?[i].damage,
          ),
      ];
    } else {
      FittingTemperStat stat(
        String label,
        int Function(ShipState) value, {
        bool percent = false,
        bool bonus = false,
      }) => FittingTemperStat(
        label: label,
        current: value(ship),
        next: upgraded == null ? null : value(upgraded),
        percent: percent,
        bonus: bonus,
      );
      stats = switch (blueprint) {
        BlueprintId.standard => [
          stat(
            'Next-volley damage',
            (s) => (s.bracedVolleyDamageBonus * 100).round(),
            percent: true,
            bonus: true,
          ),
        ],
        BlueprintId.ironclad => [
          stat(
            'Damage reduction per use',
            (s) => s.fortifyDamageReductionGain,
            bonus: true,
          ),
        ],
        BlueprintId.clipper => [
          stat(
            'Evasion bonus',
            (s) => s.evasiveRiggingBonus,
            percent: true,
            bonus: true,
          ),
        ],
        BlueprintId.corsair => [
          stat('Trap Slicing damage', (s) => s.tetherTrapDamage),
        ],
        BlueprintId.bombardier => [
          stat(
            'Shot accuracy bonus',
            (s) => s.spotterFlareAccuracyBonus,
            percent: true,
            bonus: true,
          ),
          stat(
            'Blast damage bonus',
            (s) => (s.spotterFlareBlastBonus * 100).round(),
            percent: true,
            bonus: true,
          ),
        ],
      };
    }
  }

  final HardpointType slot;
  final String currentMark;
  final int cost;
  late final String name;
  late final String? nextMark;
  late final List<FittingTemperStat> stats;
  bool get isMaximum => nextMark == null;
}

class FittingTemperStat {
  const FittingTemperStat({
    required this.label,
    required this.current,
    required this.next,
    this.percent = false,
    this.bonus = false,
  });
  final String label;
  final int current;
  final int? next;
  final bool percent;
  final bool bonus;
  String _format(int value) => '${bonus ? '+' : ''}$value${percent ? '%' : ''}';
  String get currentText => _format(current);
  String? get nextText => next == null ? null : _format(next!);
}
