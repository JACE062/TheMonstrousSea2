import '../model/enums.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';

int _shipWeaponIdCounter = 0;

/// Maps a level number to an appropriate [RarityLevel].
RarityLevel rarityForLevel(int level) {
  if (level <= 1) return RarityLevel.common;
  if (level == 2) return RarityLevel.rare;
  if (level == 3) return RarityLevel.epic;
  return RarityLevel.legendary;
}

/// Generates a specific [ShipWeapon] scaled by [level] and configured by [type].
///
/// Formulas match GDD and Java specifications:
/// - Cannon: weight 2, charge 0, piercing [8..12]*L, hitMod 2*L, value 20*L
/// - TorpedoLauncher: weight 4, charge 2, blast [13..17]*L, hitMod 2*L, value 30*L
/// - BladeLauncher: weight 3, charge 1, slicing [13..17]*L, hitMod 2*L, value 30*L
/// - LightningRailgun: weight 3, charge 3, shock [20..30]*L, hitMod 2*L, value 50*L, stuns
/// - Flamethrower: weight 3, charge 3, fire [20..30]*L, hitMod 2*L, value 50*L, burns
ShipWeapon generateShipWeapon(
  ShipWeaponType type,
  int level,
  RarityLevel rarity,
  GameRng rng, {
  String? id,
}) {
  final weaponId = id ?? '${type.name}_${++_shipWeaponIdCounter}';
  final hitModifier = 2 * level;

  switch (type) {
    case ShipWeaponType.cannon:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: 'A simple, lead-firing cannon',
        value: 20 * level,
        rarity: rarity,
        damage: rng.nextIntRange(8, 12) * level,
        hitModifier: hitModifier,
        chargeTime: 0,
        damageType: DamageType.piercing,
        equipWeight: 2,
        weaponType: type,
      );
    case ShipWeaponType.torpedoLauncher:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description:
            'Fires underwater explosives capable of blasting through armor',
        value: 30 * level,
        rarity: rarity,
        damage: rng.nextIntRange(13, 17) * level,
        hitModifier: hitModifier,
        chargeTime: 2,
        damageType: DamageType.blast,
        equipWeight: 4,
        weaponType: type,
      );
    case ShipWeaponType.bladeLauncher:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description:
            'Launches spinning blades with a penchant for removing limbs',
        value: 30 * level,
        rarity: rarity,
        damage: rng.nextIntRange(13, 17) * level,
        hitModifier: hitModifier,
        chargeTime: 1,
        damageType: DamageType.slicing,
        equipWeight: 3,
        weaponType: type,
      );
    case ShipWeaponType.lightningRailgun:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description:
            "Arcs a powerful lightning bolt, zapping a target's nervous system",
        value: 50 * level,
        rarity: rarity,
        damage: rng.nextIntRange(20, 30) * level,
        hitModifier: hitModifier,
        chargeTime: 3,
        damageType: DamageType.shock,
        statusEffect: StatusEffect.stun,
        equipWeight: 3,
        weaponType: type,
      );
    case ShipWeaponType.flamethrower:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description:
            'Fuel. Ignition. A memory of hell wreaks flame upon your enemies',
        value: 50 * level,
        rarity: rarity,
        damage: rng.nextIntRange(20, 30) * level,
        hitModifier: hitModifier,
        chargeTime: 3,
        damageType: DamageType.fire,
        statusEffect: StatusEffect.burn,
        equipWeight: 3,
        weaponType: type,
      );
  }
}

/// Generates a random [ShipWeapon] of a randomly chosen type, scaled to [level].
ShipWeapon randomShipWeapon(
  int level,
  GameRng rng, {
  RarityLevel? rarity,
  String? id,
}) {
  final weaponRarity = rarity ?? rarityForLevel(level);
  final type = ShipWeaponType.values[rng.nextInt(ShipWeaponType.values.length)];
  return generateShipWeapon(type, level, weaponRarity, rng, id: id);
}
