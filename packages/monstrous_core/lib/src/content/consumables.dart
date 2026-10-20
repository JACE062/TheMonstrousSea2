import '../lore/weapon_lore.dart';
import '../model/attack_result.dart';
import '../model/enums.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';

int _consumableIdCounter = 0;

/// Generates one single-use item. [rarity] is retained for legacy callers only;
/// consumables have fixed potency and value, independent of rarity.
Consumable generateConsumable(
  ConsumableType type,
  RarityLevel rarity, {
  String? id,
}) {
  final consumableId = id ?? '${type.name}_${++_consumableIdCounter}';
  final desc = WeaponLore.consumables[type]?.description ?? type.description;

  return Consumable(
    id: consumableId,
    name: type.displayName,
    description: desc,
    value: 25,
    rarity: RarityLevel.common,
    type: type,
    maxUses: 1,
  );
}

/// Generates a random single-use [Consumable]; [level] is a legacy argument.
Consumable randomConsumable(int level, GameRng rng, {String? id}) {
  final type = ConsumableType.values[rng.nextInt(ConsumableType.values.length)];
  return generateConsumable(type, RarityLevel.common, id: id);
}

/// Resolves the effect of using a [consumable] in combat against a target.
///
/// Rules:
/// - Unstable Tincture: 100% success rate, inflicts a random status effect
///   (Burn, Poison, or Stun), dealing 0 initial direct damage.
/// - Blast Pack & Chakram: 75% hit rate (`d100() <= 75`), dealing
///   5 damage with their respective damage types.
AttackResult resolveConsumableEffect(Consumable consumable, GameRng rng) {
  switch (consumable.type) {
    case ConsumableType.hullPatchKit:
      return AttackResult(
        didHit: true,
        damage: 0,
        damageType: consumable.type.damageType,
        description:
            '${consumable.name} patches the hull, restoring 30% max HP!',
      );
    case ConsumableType.krakenInkBomb:
      return AttackResult(
        didHit: true,
        damage: 0,
        damageType: consumable.type.damageType,
        description:
            '${consumable.name} billows a smoke screen (+25% Evasion)!',
      );
    case ConsumableType.alchemicalPitch:
      return AttackResult(
        didHit: true,
        damage: 0,
        damageType: consumable.type.damageType,
        statusEffect: StatusEffect.burn,
        description:
            '${consumable.name} coats the guns in incendiary pitch (+25% Fire damage & Burn on next volley)!',
      );
    case ConsumableType.unstableTincture:
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
        description:
            '${consumable.name} inflicts ${selectedEffect.displayName}!',
      );
    case ConsumableType.blastPack:
    case ConsumableType.chakram:
      final hits = rng.d100() <= 75;
      if (hits) {
        const damage = 5;
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
