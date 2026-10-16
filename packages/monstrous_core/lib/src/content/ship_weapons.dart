import '../lore/weapon_lore.dart';
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
/// Formulas match balanced tactical overhaul:
/// - Cannon: weight 1, charge 0, piercing [8..12]*L, hitMod 85, value 20*L
/// - TorpedoLauncher: weight 2, charge 2, blast [18..24]*L, hitMod 75, value 30*L
/// - BladeLauncher: weight 2, charge 2, slicing [16..22]*L, hitMod 80, value 30*L
/// - LightningRailgun: weight 3, charge 2, shock [16..22]*L, hitMod 80, value 50*L, stuns
/// - Flamethrower: weight 3, charge 2, fire [16..22]*L, hitMod 85, value 50*L, burns
ShipWeapon generateShipWeapon(
  ShipWeaponType type,
  int level,
  RarityLevel rarity,
  GameRng rng, {
  String? id,
}) {
  final weaponId = id ?? '${type.name}_${++_shipWeaponIdCounter}';

  final desc = WeaponLore.ship[type]?.description ?? type.displayName;

  switch (type) {
    case ShipWeaponType.cannon:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        value: 20 * level,
        rarity: rarity,
        damage: rng.nextIntRange(8, 12) * level,
        hitModifier: 85,
        chargeTime: type.chargeTime,
        damageType: DamageType.piercing,
        equipWeight: type.equipWeight,
        weaponType: type,
      );
    case ShipWeaponType.prowRam:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        value: 40 * level,
        rarity: rarity,
        damage: rng.nextIntRange(22, 28) * level,
        hitModifier: 90,
        chargeTime: type.chargeTime,
        damageType: DamageType.blast,
        equipWeight: type.equipWeight,
        weaponType: type,
      );
    case ShipWeaponType.precisionCulverin:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        value: 35 * level,
        rarity: rarity,
        damage: rng.nextIntRange(10, 14) * level,
        hitModifier: 95,
        chargeTime: type.chargeTime,
        damageType: DamageType.piercing,
        equipWeight: type.equipWeight,
        weaponType: type,
      );
    case ShipWeaponType.heavyMortar:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        value: 45 * level,
        rarity: rarity,
        damage: rng.nextIntRange(24, 32) * level,
        hitModifier: 80,
        chargeTime: type.chargeTime,
        damageType: DamageType.blast,
        equipWeight: type.equipWeight,
        weaponType: type,
      );
    case ShipWeaponType.harpoonWinch:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        value: 35 * level,
        rarity: rarity,
        damage: rng.nextIntRange(14, 20) * level,
        hitModifier: 85,
        chargeTime: type.chargeTime,
        damageType: DamageType.piercing,
        equipWeight: type.equipWeight,
        weaponType: type,
      );
    case ShipWeaponType.torpedoLauncher:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        value: 30 * level,
        rarity: rarity,
        damage: rng.nextIntRange(18, 24) * level,
        hitModifier: 75,
        chargeTime: type.chargeTime,
        damageType: DamageType.blast,
        equipWeight: type.equipWeight,
        weaponType: type,
      );
    case ShipWeaponType.bladeLauncher:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        value: 30 * level,
        rarity: rarity,
        damage: rng.nextIntRange(16, 22) * level,
        hitModifier: 80,
        chargeTime: type.chargeTime,
        damageType: DamageType.slicing,
        equipWeight: type.equipWeight,
        weaponType: type,
      );
    case ShipWeaponType.lightningRailgun:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        value: 50 * level,
        rarity: rarity,
        damage: rng.nextIntRange(16, 22) * level,
        hitModifier: 80,
        chargeTime: type.chargeTime,
        damageType: DamageType.shock,
        statusEffect: StatusEffect.stun,
        equipWeight: type.equipWeight,
        weaponType: type,
      );
    case ShipWeaponType.flamethrower:
      return ShipWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        value: 50 * level,
        rarity: rarity,
        damage: rng.nextIntRange(16, 22) * level,
        hitModifier: 85,
        chargeTime: type.chargeTime,
        damageType: DamageType.fire,
        statusEffect: StatusEffect.burn,
        equipWeight: type.equipWeight,
        weaponType: type,
      );
  }
}

/// Generates a random [ShipWeapon] of a randomly chosen type, scaled to [level].
///
/// By default excludes signature weapons (Prow Ram, Heavy Mortar, etc.) so that
/// general loot pools drop universal weapons.
ShipWeapon randomShipWeapon(
  int level,
  GameRng rng, {
  RarityLevel? rarity,
  String? id,
  bool includeSignature = false,
}) {
  final weaponRarity = rarity ?? rarityForLevel(level);
  final pool = includeSignature
      ? ShipWeaponType.values
      : ShipWeaponType.values.where((t) => !t.isSignature).toList();
  final type = pool[rng.nextInt(pool.length)];
  return generateShipWeapon(type, level, weaponRarity, rng, id: id);
}
