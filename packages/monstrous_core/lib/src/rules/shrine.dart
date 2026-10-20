import '../model/combatant.dart';
import '../model/flagship_blueprint.dart';
import '../model/ocean_power.dart';
import '../rng/game_rng.dart';

const blessingHardpoints = [
  HardpointType.broadside,
  HardpointType.signature,
  HardpointType.utility,
];

/// Allied powers respect another power's dedication and the sovereign cap.
bool canBlessHardpoint(ShipState ship, OceanPower power, HardpointType slot) {
  if (!blessingHardpoints.contains(slot)) return false;
  final current = ship.blessings[slot];
  return current == null || (current.power == power && current.tier < 3);
}

/// Returns the next tier without modifying the ship, or null for a locked slot.
HardpointBlessing? previewShrineBlessing(
  ShipState ship,
  OceanPower power,
  HardpointType slot,
) {
  if (!canBlessHardpoint(ship, power, slot)) return null;
  return HardpointBlessing(
    power: power,
    slot: slot,
    tier: (ship.blessings[slot]?.tier ?? 0) + 1,
  );
}

List<OceanPower> eligibleShrinePowers(ShipState ship) => OceanPower.values
    .where(
      (power) => blessingHardpoints.any(
        (slot) => canBlessHardpoint(ship, power, slot),
      ),
    )
    .toList();

double shrinePowerWeight(ShipState ship, OceanPower power) =>
    ship.blessings.values.any((blessing) => blessing.power == power)
    ? 2.5
    : 1.0;

/// Weighted sampling without replacement, consuming only the injected RNG.
/// Fully dedicated ships may have fewer than two eligible powers remaining.
List<OceanPower> selectShrinePowers(ShipState ship, GameRng rng) {
  final remaining = eligibleShrinePowers(ship);
  final selected = <OceanPower>[];
  while (remaining.isNotEmpty && selected.length < 2) {
    final total = remaining.fold<double>(
      0,
      (sum, power) => sum + shrinePowerWeight(ship, power),
    );
    var roll = rng.nextDouble() * total;
    var index = remaining.length - 1;
    for (var i = 0; i < remaining.length; i++) {
      roll -= shrinePowerWeight(ship, remaining[i]);
      if (roll < 0) {
        index = i;
        break;
      }
    }
    selected.add(remaining.removeAt(index));
  }
  return List.unmodifiable(selected);
}
