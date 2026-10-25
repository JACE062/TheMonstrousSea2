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

/// Tactical helm maneuvers issued to reposition the flagship relative to the quarry.
enum HelmOrder {
  advance('Advance'),
  holdLine('Hold Line'),
  fallBack('Fall Back');

  const HelmOrder(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

/// Discrete operational engagement ranges during naval ship-to-beast combat.
enum CombatRange {
  long('Long Range'),
  medium('Medium Range'),
  short('Short Range');

  const CombatRange(this.displayName);
  final String displayName;

  /// Returns the next closer range band, or [short] if already at point-blank.
  CombatRange get closer => switch (this) {
        CombatRange.long => CombatRange.medium,
        CombatRange.medium => CombatRange.short,
        CombatRange.short => CombatRange.short,
      };

  /// Returns the next farther range band, or [long] if already at distance.
  CombatRange get farther => switch (this) {
        CombatRange.short => CombatRange.medium,
        CombatRange.medium => CombatRange.long,
        CombatRange.long => CombatRange.long,
      };

  /// Returns the bounded list of valid [HelmOrder]s available at this distance.
  List<HelmOrder> get availableHelmOrders => switch (this) {
        CombatRange.long => const [HelmOrder.holdLine, HelmOrder.advance],
        CombatRange.medium => const [
            HelmOrder.advance,
            HelmOrder.holdLine,
            HelmOrder.fallBack,
          ],
        CombatRange.short => const [HelmOrder.holdLine, HelmOrder.fallBack],
      };

  /// Calculates the destination range band after executing [order].
  CombatRange rangeAfterHelmOrder(HelmOrder order) => switch (order) {
        HelmOrder.advance => closer,
        HelmOrder.holdLine => this,
        HelmOrder.fallBack => farther,
      };

  @override
  String toString() => displayName;
}

enum ShipWeaponType {
  // Broadsides (0T Cooldown)
  cannon('Naval Cannon Battery', chargeTime: 0, equipWeight: 1),
  heavyCarronade(
    'Heavy Carronades',
    chargeTime: 0,
    equipWeight: 1,
    isBlueprintIntrinsic: true,
  ),
  swivelGun(
    'Long-Barrel Swivel Guns',
    chargeTime: 0,
    equipWeight: 1,
    isBlueprintIntrinsic: true,
  ),
  chainShotBroadside(
    'Chain-Shot Broadside',
    chargeTime: 0,
    equipWeight: 1,
    isBlueprintIntrinsic: true,
  ),
  shrapnelHowitzer(
    'Shrapnel Howitzers',
    chargeTime: 0,
    equipWeight: 1,
    isBlueprintIntrinsic: true,
  ),

  // Signature Armaments (1T Cooldown across all blueprints)
  twinChasers(
    'Twin Chaser Cannons',
    chargeTime: 1,
    equipWeight: 2,
    isSignature: true,
    isBlueprintIntrinsic: true,
  ),
  prowRam(
    'Prow Ram',
    chargeTime: 1,
    equipWeight: 2,
    isSignature: true,
    isBlueprintIntrinsic: true,
  ),
  precisionCulverin(
    'Precision Culverin',
    chargeTime: 1,
    equipWeight: 1,
    isSignature: true,
    isBlueprintIntrinsic: true,
  ),
  heavyMortar(
    'Heavy Mortar',
    chargeTime: 1,
    equipWeight: 3,
    isSignature: true,
    isBlueprintIntrinsic: true,
  ),
  harpoonWinch(
    'Harpoon Winch',
    chargeTime: 1,
    equipWeight: 2,
    isSignature: true,
    isBlueprintIntrinsic: true,
  ),

  // Legacy Java / Refit Weapons
  torpedoLauncher('Torpedo Launcher', chargeTime: 2, equipWeight: 2),
  bladeLauncher('Blade Launcher', chargeTime: 2, equipWeight: 2),
  lightningRailgun('Lightning Railgun', chargeTime: 2, equipWeight: 3),
  flamethrower('Flamethrower', chargeTime: 2, equipWeight: 3);

  const ShipWeaponType(
    this.displayName, {
    required this.chargeTime,
    required this.equipWeight,
    this.isSignature = false,
    this.isBlueprintIntrinsic = false,
  });

  final String displayName;
  final int chargeTime;
  final int equipWeight;
  final bool isSignature;
  final bool isBlueprintIntrinsic;

  @override
  String toString() => displayName;
}

/// Blueprint-specific Utility Hardpoint mechanisms (2-turn cooldown).
enum UtilityHardpointId {
  gunneryDrill(
    'Gunnery Drill',
    'Brace for -20% incoming damage this round and grant +15% Accuracy & +20% Damage to your next volley.',
    cooldownTurns: 2,
  ),
  fortifyPlates(
    'Fortify Iron Plates',
    'Bolster hull Damage Reduction for the battle and Anchor the ship for 1 round (immune to monster push/pull).',
    cooldownTurns: 2,
  ),
  evasiveRigging(
    'Evasive Rigging',
    'Double ship Evasion until next dodge and immediately shift 1 range band away from the monster.',
    cooldownTurns: 2,
  ),
  driftingTetherTrap(
    'Drifting Tether-Trap',
    'Launch a floating razor-net 1 band ahead. Drifts 1 band toward the beast each round and detonates on contact for Slicing damage + Pin (1T).',
    cooldownTurns: 2,
  ),
  spotterFlare(
    'Phosphor Spotter Flare',
    'Illuminate the beast for 2 turns: clears Ink/Obscurity, suppresses Evasion, grants +15% Accuracy, and increases Blast damage taken by +25%.',
    cooldownTurns: 2,
  );

  const UtilityHardpointId(
    this.displayName,
    this.description, {
    this.cooldownTurns = 2,
  });

  final String displayName;
  final String description;
  final int cooldownTurns;

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
    'A small bundle of explosives designed for breaching armored shells.',
    DamageType.blast,
  ),
  chakram(
    'Chakram',
    "Very sharp, circular throwing-blade. Won't hurt much, but could sever limbs if thrown right.",
    DamageType.slicing,
  ),
  hullPatchKit(
    'Hull Patch Kit',
    'Seasoned oak planks and hot pitch that restore 30% of max hull HP as a Quick Action.',
    DamageType.piercing,
  ),
  krakenInkBomb(
    'Bottled Kraken Ink',
    'Alchemical smoke bomb that shrouds the ship, granting +25% Evasion for 1 round.',
    DamageType.venom,
  ),
  alchemicalPitch(
    'Alchemical Pitch Flask',
    'Coats the next hardpoint volley in volatile naptha (+25% Fire damage and inflicts Burn).',
    DamageType.fire,
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
  corvette('Corvette'),
  clipper('Clipper'),
  corsair('Corsair'),
  bombardier('Bombardier');

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
  kraken('The Kraken'),
  worldSerpent('The World Serpent'),
  ancientLeviathan('The Ancient Leviathan');

  const MonsterSpecies(this.displayName);
  final String displayName;

  /// Unique regional bosses are never eligible for the Nemesis system.
  bool get isRegionTitan => switch (this) {
    kraken || worldSerpent || ancientLeviathan => true,
    _ => false,
  };

  @override
  String toString() => displayName;
}

/// The nature of an encounter node positioned on the naval sea chart.
enum EncounterNodeType {
  beastCombat('Beast Encounter'),
  respiteIsland('Respite Island'),
  shipwreckSalvage('Shipwreck Salvage'),
  smugglerTrader('Smuggler Trader'),
  ancientShrine('Ancient Sea Shrine'),
  regionTitan('Region Titan');

  const EncounterNodeType(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

/// Strategic salvaging choices available when encountering a floating shipwreck derelict.
enum ShipwreckChoice {
  munitions('Search Hold for Materials & Supplies'),
  strongbox("Crack the Captain's Strongbox"),
  timbers('Strip Plating & Repair Hull');

  const ShipwreckChoice(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

/// Choices available when communing at an Ancient Sea Shrine.
enum ShrineChoice {
  tribute('Offer Tribute (Gold for Sea Favor)'),
  abyssalPact('Abyssal Pact (Sacrifice Hull for Relic)'),
  ancientRunes('Consult Ancient Runes (Lore & Reveal Chart)'),
  leave('Sail Past in Reverence');

  const ShrineChoice(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

/// The directional compass headings available at the ship's helm when setting course.
enum NavigationalBearing {
  larboardTack('East-Northeast (Larboard Tack)', 'E-NE', 'Larboard Tack'),
  deadAhead('Due East (Dead Ahead)', 'E', 'Dead Ahead'),
  starboardTack('East-Southeast (Starboard Tack)', 'E-SE', 'Starboard Tack');

  const NavigationalBearing(this.displayName, this.abbreviation, this.shortName);
  final String displayName;
  final String abbreviation;
  final String shortName;

  @override
  String toString() => displayName;
}
