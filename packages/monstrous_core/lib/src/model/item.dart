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

  Map<String, dynamic> toJson();

  static Item fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    switch (kind) {
      case 'consumable':
        return Consumable.fromJson(json);
      case 'shipWeapon':
        return ShipWeapon.fromJson(json);
      case 'treasure':
      default:
        return Treasure.fromJson(json);
    }
  }
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

  factory Treasure.fromJson(Map<String, dynamic> json) => Treasure(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        value: json['value'] as int,
        rarity: RarityLevel.values.firstWhere(
          (e) => e.name == json['rarity'],
          orElse: () => RarityLevel.common,
        ),
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': 'treasure',
        'id': id,
        'name': name,
        'description': description,
        'value': value,
        'rarity': rarity.name,
      };
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

  factory Consumable.fromJson(Map<String, dynamic> json) => Consumable(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        value: json['value'] as int,
        rarity: RarityLevel.values.firstWhere(
          (e) => e.name == json['rarity'],
          orElse: () => RarityLevel.common,
        ),
        type: ConsumableType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ConsumableType.unstableTincture,
        ),
        maxUses: json['maxUses'] as int,
        usesLeft: json['usesLeft'] as int?,
      );

  final ConsumableType type;
  final int maxUses;
  int usesLeft;

  bool get isDepleted => usesLeft <= 0;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': 'consumable',
        'id': id,
        'name': name,
        'description': description,
        'value': value,
        'rarity': rarity.name,
        'type': type.name,
        'maxUses': maxUses,
        'usesLeft': usesLeft,
      };

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

  /// Base hit accuracy percentage (e.g. 85 for 85% hit chance).
  int get baseAccuracy => hitModifier;

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

  factory ShipWeapon.fromJson(Map<String, dynamic> json) => ShipWeapon(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        value: json['value'] as int,
        rarity: RarityLevel.values.firstWhere(
          (e) => e.name == json['rarity'],
          orElse: () => RarityLevel.common,
        ),
        damage: json['damage'] as int,
        hitModifier: json['hitModifier'] as int,
        chargeTime: json['chargeTime'] as int,
        chargeCountdown: json['chargeCountdown'] as int?,
        damageType: DamageType.values.firstWhere(
          (e) => e.name == json['damageType'],
          orElse: () => DamageType.piercing,
        ),
        statusEffect: json['statusEffect'] != null
            ? StatusEffect.values.firstWhere((e) => e.name == json['statusEffect'])
            : null,
        equipWeight: json['equipWeight'] as int,
        weaponType: ShipWeaponType.values.firstWhere(
          (e) => e.name == json['weaponType'],
          orElse: () => ShipWeaponType.cannon,
        ),
      );

  final int equipWeight;
  final ShipWeaponType weaponType;

  bool get isSignature => weaponType.isSignature;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': 'shipWeapon',
        'id': id,
        'name': name,
        'description': description,
        'value': value,
        'rarity': rarity.name,
        'damage': damage,
        'hitModifier': hitModifier,
        'chargeTime': chargeTime,
        'chargeCountdown': chargeCountdown,
        'damageType': damageType.name,
        'statusEffect': statusEffect?.name,
        'equipWeight': equipWeight,
        'weaponType': weaponType.name,
      };
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

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': 'monsterWeapon',
        'id': id,
        'name': name,
        'description': description,
        'rarity': rarity.name,
        'damage': damage,
        'hitModifier': hitModifier,
        'chargeTime': chargeTime,
        'chargeCountdown': chargeCountdown,
        'damageType': damageType.name,
        'statusEffect': statusEffect?.name,
        'monsterWeaponType': monsterWeaponType.name,
      };
}
