// Core enumerations for combat, items, ships, and monsters.

enum DamageType {
  slicing('Slicing'),
  piercing('Piercing'),
  blast('Blast'),
  fire('Fire'),
  venom('Venom'),
  shock('Shock');

  const DamageType(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

enum StatusEffect {
  burn('Burn', 'Burning'),
  poison('Poison', 'Poisoned'),
  stun('Stun', 'Stunned');

  const StatusEffect(this.displayName, this.verbRepresentation);
  final String displayName;
  final String verbRepresentation;

  @override
  String toString() => displayName;
}

enum RarityLevel {
  common('Common', 1),
  rare('Rare', 2),
  epic('Epic', 3),
  legendary('Legendary', 4);

  const RarityLevel(this.displayName, this.level);
  final String displayName;
  final int level;

  @override
  String toString() => displayName;
}

enum ShipWeaponType {
  cannon('Cannon', chargeTime: 0, equipWeight: 2),
  torpedoLauncher('Torpedo Launcher', chargeTime: 2, equipWeight: 4),
  bladeLauncher('Blade Launcher', chargeTime: 1, equipWeight: 3),
  lightningRailgun('Lightning Railgun', chargeTime: 3, equipWeight: 3),
  flamethrower('Flamethrower', chargeTime: 3, equipWeight: 3);

  const ShipWeaponType(
    this.displayName, {
    required this.chargeTime,
    required this.equipWeight,
  });

  final String displayName;
  final int chargeTime;
  final int equipWeight;

  @override
  String toString() => displayName;
}

enum MonsterWeaponType {
  ram('Ram', chargeTime: 0),
  tail('Tail', chargeTime: 1),
  jaws('Jaws', chargeTime: 1),
  claw('Claw', chargeTime: 0),
  tentacle('Tentacle', chargeTime: 0),
  stingingTendrils('Stinging Tendrils', chargeTime: 2);

  const MonsterWeaponType(this.displayName, {required this.chargeTime});
  final String displayName;
  final int chargeTime;

  @override
  String toString() => displayName;
}

enum ConsumableType {
  unstableTincture(
    'Unstable Tincture',
    'An iridescent vial of stormy liquid with a noticeable warmth.',
    DamageType.venom,
  ),
  blastPack(
    'Blast Pack',
    'A small bundle of explosives designed for breaching armored doors.',
    DamageType.blast,
  ),
  chakram(
    'Chakram',
    "Very sharp, circular throwing-blade. Won't hurt much, but could sever limbs if thrown right.",
    DamageType.slicing,
  );

  const ConsumableType(this.displayName, this.description, this.damageType);
  final String displayName;
  final String description;
  final DamageType damageType;

  @override
  String toString() => displayName;
}

enum ShipClass {
  standard('Standard Ship'),
  freighter('Freighter'),
  ironclad('Ironclad'),
  corvette('Corvette');

  const ShipClass(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

enum MonsterSpecies {
  shark('Shark'),
  serpent('Serpent'),
  jellyfish('Jellyfish'),
  squid('Squid'),
  crustacean('Crustacean'),
  kraken('The Kraken');

  const MonsterSpecies(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}
