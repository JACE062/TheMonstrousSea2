import '../lore/weapon_lore.dart';
import '../model/enums.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';
import 'ship_weapons.dart';

int _monsterWeaponIdCounter = 0;

/// Generates a specific [MonsterWeapon] scaled by [level] and configured by [type].
///
/// Formulas match balanced tactical overhaul:
/// - Ram: charge 0, blast [8..12]*L, hitMod 80
/// - Tail: charge 1, blast [14..18]*L, hitMod 75
/// - Jaws: charge 1, piercing [18..22]*L, hitMod 75
/// - Claw: charge 0, slicing [8..12]*L, hitMod 80
/// - Tentacle: charge 0, blast [2..3]*L, hitMod 70
/// - StingingTendrils: charge 2, shock [6..10]*L, hitMod 70, stuns
MonsterWeapon generateMonsterWeapon(
  MonsterWeaponType type,
  int level,
  GameRng rng, {
  RarityLevel? rarity,
  String? id,
}) {
  final weaponId = id ?? '${type.name}_${++_monsterWeaponIdCounter}';
  final weaponRarity = rarity ?? rarityForLevel(level);

  final desc = WeaponLore.monster[type]?.description ?? type.displayName;

  switch (type) {
    case MonsterWeaponType.ram:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        rarity: weaponRarity,
        damage: rng.nextIntRange(8, 12) + 4 * (level - 1),
        hitModifier: 80,
        chargeTime: 0,
        damageType: DamageType.blast,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.tail:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        rarity: weaponRarity,
        damage: rng.nextIntRange(14, 18) + 5 * (level - 1),
        hitModifier: 75,
        chargeTime: 1,
        damageType: DamageType.blast,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.jaws:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        rarity: weaponRarity,
        damage: rng.nextIntRange(18, 22) + 6 * (level - 1),
        hitModifier: 75,
        chargeTime: 1,
        damageType: DamageType.piercing,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.claw:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        rarity: weaponRarity,
        damage: rng.nextIntRange(8, 12) + 4 * (level - 1),
        hitModifier: 80,
        chargeTime: 0,
        damageType: DamageType.slicing,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.tentacle:
      final tentacleDmg =
          level <= 2 ? rng.nextIntRange(2, 3) : (level <= 4 ? 3 : 4);
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        rarity: weaponRarity,
        damage: tentacleDmg,
        hitModifier: 70,
        chargeTime: 0,
        damageType: DamageType.blast,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.stingingTendrils:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: desc,
        rarity: weaponRarity,
        damage: rng.nextIntRange(6, 10) + 3 * (level - 1),
        hitModifier: 70,
        chargeTime: 2,
        damageType: DamageType.shock,
        statusEffect: StatusEffect.stun,
        monsterWeaponType: type,
      );
  }
}
