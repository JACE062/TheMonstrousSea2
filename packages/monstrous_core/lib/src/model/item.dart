import 'enums.dart';

/// Base class for all items in the game (treasures, consumables, weapons).
abstract class Item implements Comparable<Item> {
  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.value,
    required this.rarity,
  });

  final String id;
  String name;
  String description;
  int value;
  RarityLevel rarity;

  @override
  int compareTo(Item other) {
    if (rarity != other.rarity) {
      return rarity.level.compareTo(other.rarity.level);
    }
    final self = this;
    if (self is ShipWeapon && other is ShipWeapon) {
      if (self.weaponType != other.weaponType) {
        return self.weaponType.index.compareTo(other.weaponType.index);
      }
    }
    return value.compareTo(other.value);
  }

  @override
  String toString() => '$name (${value}g)';
}

/// Pure treasure item that can be sold for gold at port.
class Treasure extends Item {
  Treasure({
    required super.id,
    required super.name,
    required super.description,
    required super.value,
    required super.rarity,
  });
}

/// Consumable item usable during combat or exploration.
class Consumable extends Item {
  Consumable({
    required super.id,
    required super.name,
    required super.description,
    required super.value,
    required super.rarity,
    required this.type,
    required this.maxUses,
    int? usesLeft,
  }) : usesLeft = usesLeft ?? maxUses;

  final ConsumableType type;
  final int maxUses;
  int usesLeft;

  bool get isDepleted => usesLeft <= 0;

  @override
  String toString() => '$name $usesLeft/$maxUses Uses (${value}g)';
}

/// Base weapon class for ships and sea monsters.
abstract class Weapon extends Item {
  Weapon({
    required super.id,
    required super.name,
    required super.description,
    required super.value,
    required super.rarity,
    required this.damage,
    required this.hitModifier,
    required this.chargeTime,
    int? chargeCountdown,
    required this.damageType,
    this.statusEffect,
  }) : chargeCountdown = chargeCountdown ?? 0;

  int damage;
  int hitModifier;
  int chargeTime;
  int chargeCountdown;
  DamageType damageType;
  StatusEffect? statusEffect;

  bool get isReady => chargeCountdown <= 0;

  void decrementChargeCountdown() {
    if (chargeCountdown > 0) {
      chargeCountdown--;
    }
  }

  void resetCharge() {
    chargeCountdown = chargeTime;
  }
}

/// Weapons equipable onto ships.
class ShipWeapon extends Weapon {
  ShipWeapon({
    required super.id,
    required super.name,
    required super.description,
    required super.value,
    required super.rarity,
    required super.damage,
    required super.hitModifier,
    required super.chargeTime,
    super.chargeCountdown,
    required super.damageType,
    super.statusEffect,
    required this.equipWeight,
    required this.weaponType,
  });

  final int equipWeight;
  final ShipWeaponType weaponType;
}

/// Weapons wielded by sea monsters.
class MonsterWeapon extends Weapon {
  MonsterWeapon({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.damage,
    required super.hitModifier,
    required super.chargeTime,
    super.chargeCountdown,
    required super.damageType,
    super.statusEffect,
    required this.monsterWeaponType,
  }) : super(value: 0);

  final MonsterWeaponType monsterWeaponType;
}
