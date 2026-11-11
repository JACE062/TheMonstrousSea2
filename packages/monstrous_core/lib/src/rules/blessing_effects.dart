import '../model/enums.dart';
import '../model/flagship_blueprint.dart';
import '../model/ocean_power.dart';

/// Preserve intrinsic shell interactions when a fitting receives a dedication.
double blessingCarapaceMultiplier(
  ShipWeaponType? type,
  DamageType damage,
  HardpointBlessing? blessing,
) {
  if (blessing?.power == OceanPower.brinemother) {
    if (blessing!.slot == HardpointType.broadside) return 2;
    if (blessing.slot == HardpointType.signature) {
      return type == ShipWeaponType.heavyMortar ? 2 : 1;
    }
  }
  if (blessing?.power == OceanPower.earthshakerTitan &&
      damage != DamageType.fire) {
    return type == ShipWeaponType.heavyMortar ? 2 : 1.5;
  }
  return damage == DamageType.blast
      ? type == ShipWeaponType.heavyMortar
            ? 2
            : 1.5
      : 1;
}

double blessingCarapaceBypass(
  ShipWeaponType? type,
  DamageType damage,
  HardpointBlessing? blessing,
) {
  if (blessing?.power == OceanPower.brinemother &&
      (blessing?.slot == HardpointType.signature ||
          damage == DamageType.fire)) {
    return 1;
  }
  if (type == ShipWeaponType.precisionCulverin) return 0.5;
  return damage == DamageType.fire ? 1 : 0;
}
