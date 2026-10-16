import '../lore/weapon_lore.dart';
import '../model/attack_result.dart';
import '../model/enums.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';
import 'ship_weapons.dart';

int _consumableIdCounter = 0;

/// Generates a [Consumable] instance of the specified [type] and [rarity].
///
/// Formulas match GDD and Java specifications:
/// - Max uses: [rarity.level] (1 for Common, 2 for Rare, 3 for Epic, 4 for Legendary)
/// - Value: 25 * [rarity.level]
Consumable generateConsumable(
  ConsumableType type,
  RarityLevel rarity, {
  String? id,
}) {
  final consumableId = id ?? '${type.name}_${++_consumableIdCounter}';
  final maxUses = rarity.level;
  final value = 25 * rarity.level;
  final desc = WeaponLore.consumables[type]?.description ?? type.description;

  return Consumable(
    id: consumableId,
    name: type.displayName,
    description: desc,
    value: value,
    rarity: rarity,
    type: type,
    maxUses: maxUses,
  );
}

/// Generates a random [Consumable] scaled to [level].
Consumable randomConsumable(
  int level,
  GameRng rng, {
  String? id,
}) {
  final rarity = rarityForLevel(level);
  final type = ConsumableType.values[rng.nextInt(ConsumableType.values.length)];
  return generateConsumable(type, rarity, id: id);
}

/// Resolves the effect of using a [consumable] in combat against a target.
///
/// Rules:
/// - Unstable Tincture: 100% success rate, inflicts a random status effect
///   (Burn, Poison, or Stun), dealing 0 initial direct damage.
/// - Blast Pack & Chakram: 75% hit rate (`d100() <= 75`), dealing
///   `5 * rarity.level` damage with their respective damage types.
AttackResult resolveConsumableEffect(Consumable consumable, GameRng rng) {
  if (consumable.type == ConsumableType.unstableTincture) {
    const effects = [
      StatusEffect.burn,
      StatusEffect.poison,
      StatusEffect.stun,
    ];
    final selectedEffect = effects[rng.nextInt(effects.length)];
    return AttackResult(
      didHit: true,
      damage: 0,
      damageType: consumable.type.damageType,
      statusEffect: selectedEffect,
      description: '${consumable.name} inflicts ${selectedEffect.displayName}!',
    );
  } else {
    final hits = rng.d100() <= 75;
    if (hits) {
      final damage = 5 * consumable.rarity.level;
      return AttackResult(
        didHit: true,
        damage: damage,
        damageType: consumable.type.damageType,
        description:
            '${consumable.name} hits for $damage ${consumable.type.damageType.displayName} damage!',
      );
    } else {
      return AttackResult(
        didHit: false,
        damage: 0,
        damageType: consumable.type.damageType,
        description: 'The ${consumable.name} misses!',
      );
    }
  }
}
