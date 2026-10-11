import '../model/enums.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';
import 'ship_weapons.dart';

int _monsterWeaponIdCounter = 0;

/// Generates a specific [MonsterWeapon] scaled by [level] and configured by [type].
///
/// Formulas match GDD and Java specifications:
/// - Ram: charge 0, blast [10..14]*L, hitMod 1*L
/// - Tail: charge 1, blast [18..22]*L, hitMod 1*L
/// - Jaws: charge 1, piercing [22..26]*L, hitMod 1*L
/// - Claw: charge 0, slicing [10..14]*L, hitMod 1*L
/// - Tentacle: charge 0, blast [2..4]*L, hitMod 1*L
/// - StingingTendrils: charge 2, shock [8..12]*L, hitMod 1*L, stuns
MonsterWeapon generateMonsterWeapon(
  MonsterWeaponType type,
  int level,
  GameRng rng, {
  RarityLevel? rarity,
  String? id,
}) {
  final weaponId = id ?? '${type.name}_${++_monsterWeaponIdCounter}';
  final weaponRarity = rarity ?? rarityForLevel(level);
  final hitModifier = level;

  switch (type) {
    case MonsterWeaponType.ram:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: 'The huge body of the creature is weapon enough',
        rarity: weaponRarity,
        damage: rng.nextIntRange(10, 14) * level,
        hitModifier: hitModifier,
        chargeTime: 0,
        damageType: DamageType.blast,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.tail:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: 'A huge and powerful tail',
        rarity: weaponRarity,
        damage: rng.nextIntRange(18, 22) * level,
        hitModifier: hitModifier,
        chargeTime: 1,
        damageType: DamageType.blast,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.jaws:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: 'A set of Jaws lined with razor-sharp teeth',
        rarity: weaponRarity,
        damage: rng.nextIntRange(22, 26) * level,
        hitModifier: hitModifier,
        chargeTime: 1,
        damageType: DamageType.piercing,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.claw:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description: 'A mighty claw',
        rarity: weaponRarity,
        damage: rng.nextIntRange(10, 14) * level,
        hitModifier: hitModifier,
        chargeTime: 0,
        damageType: DamageType.slicing,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.tentacle:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description:
            'One tentacle of many, capable of grabbing and slamming alike',
        rarity: weaponRarity,
        damage: rng.nextIntRange(2, 4) * level,
        hitModifier: hitModifier,
        chargeTime: 0,
        damageType: DamageType.blast,
        monsterWeaponType: type,
      );
    case MonsterWeaponType.stingingTendrils:
      return MonsterWeapon(
        id: weaponId,
        name: type.displayName,
        description:
            'Tendrils filled with venom strong enough to eat away at ships',
        rarity: weaponRarity,
        damage: rng.nextIntRange(8, 12) * level,
        hitModifier: hitModifier,
        chargeTime: 2,
        damageType: DamageType.shock,
        statusEffect: StatusEffect.stun,
        monsterWeaponType: type,
      );
  }
}
