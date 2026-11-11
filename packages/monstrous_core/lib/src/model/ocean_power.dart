import 'flagship_blueprint.dart';

/// Allied primordial wardens whose blessings last for the current voyage.
enum OceanPower {
  magmaVentLord,
  tempestSovereign,
  brinemother,
  earthshakerTitan,
}

extension OceanPowerLore on OceanPower {
  String get displayName => switch (this) {
    OceanPower.magmaVentLord => 'The Magma Vent-Lord',
    OceanPower.tempestSovereign => 'The Tempest Sovereign',
    OceanPower.brinemother => 'The Brinemother',
    OceanPower.earthshakerTitan => 'The Earthshaker Titan',
  };

  String get symbol => switch (this) {
    OceanPower.magmaVentLord => '🔥',
    OceanPower.tempestSovereign => '⚡',
    OceanPower.brinemother => '🧪',
    OceanPower.earthshakerTitan => '🪨',
  };

  String get domainLore => switch (this) {
    OceanPower.magmaVentLord => 'Ancient fury stirs in hydrothermal vents, lava tubes, and boiling sulfur.',
    OceanPower.tempestSovereign =>
      'Hurricane squalls and deep-sea lightning answer the oldest storm.',
    OceanPower.brinemother => 'Abyssal brine and caustic enzymes reclaim rusted wrecks and armored shells.',
    OceanPower.earthshakerTitan =>
      'Basalt monoliths rise where seafloor faults awaken tidal tremors.',
  };

  String get synergySummary => switch (this) {
    OceanPower.magmaVentLord =>
      'Ignite the beast, then detonate Burning targets with your Signature.',
    OceanPower.tempestSovereign =>
      'Build Static Charge to unleash lightning and disrupt the beast.',
    OceanPower.brinemother => 'Dissolve Carapace and apply Corroded.',
    OceanPower.earthshakerTitan =>
      'Crush Carapace, interrupt windups, and raise a retaliating barrier.',
  };
}

/// One immutable dedication in a canonical hardpoint's single blessing socket.
class HardpointBlessing {
  const HardpointBlessing({
    required this.power,
    required this.slot,
    required this.tier,
  }) : assert(tier >= 1 && tier <= 3),
       assert(
         slot == HardpointType.broadside ||
             slot == HardpointType.signature ||
             slot == HardpointType.utility,
       );

  final OceanPower power;
  final HardpointType slot;
  final int tier;

  String get tierLabel => switch (tier) {
    1 => 'Tier I',
    2 => 'Tier II',
    _ => 'Tier III',
  };
  String get subtitle =>
      '$tierLabel · ${switch (tier) {
        1 => 'Initiate',
        2 => 'Resonant',
        _ => 'Sovereign',
      }}';
  String get title => switch ((power, slot)) {
    (OceanPower.magmaVentLord, HardpointType.broadside) => 'Magma Volley',
    (OceanPower.magmaVentLord, HardpointType.signature) => 'Caldera Eruption',
    (OceanPower.magmaVentLord, _) => 'Boiling Wake',
    (OceanPower.tempestSovereign, HardpointType.broadside) =>
      'Galvanic Broadside',
    (OceanPower.tempestSovereign, HardpointType.signature) =>
      'Thunderclap Prow',
    (OceanPower.tempestSovereign, _) => 'Storm-Arc Rigging',
    (OceanPower.brinemother, HardpointType.broadside) => 'Caustic Volley',
    (OceanPower.brinemother, HardpointType.signature) => 'Acid-Bore Strike',
    (OceanPower.brinemother, _) => 'Verdigris Miasma',
    (OceanPower.earthshakerTitan, HardpointType.broadside) => 'Tremor Volley',
    (OceanPower.earthshakerTitan, HardpointType.signature) =>
      'Fault-Line Shatter',
    (OceanPower.earthshakerTitan, _) => 'Basalt Aegis',
  };

  double get damageBonus {
    if (slot == HardpointType.utility) return 0;
    final values = switch ((power, slot)) {
      (OceanPower.magmaVentLord, HardpointType.broadside) => [0.10, 0.20, 0.30],
      (OceanPower.magmaVentLord, _) => [0.15, 0.25, 0.40],
      (
        OceanPower.tempestSovereign || OceanPower.brinemother,
        HardpointType.broadside,
      ) =>
        [0.10, 0.18, 0.25],
      (OceanPower.tempestSovereign || OceanPower.brinemother, _) => [
        0.15,
        0.25,
        0.35,
      ],
      (OceanPower.earthshakerTitan, HardpointType.broadside) => [
        0.15,
        0.25,
        0.35,
      ],
      (OceanPower.earthshakerTitan, _) => [0.20, 0.35, 0.50],
    };
    return values[tier - 1];
  }

  int get critChanceBonus =>
      power == OceanPower.tempestSovereign && slot == HardpointType.signature
      ? (tier == 3 ? 20 : 15)
      : 0;

  // Effect parameters are shared by resolution, descriptions and shrine previews.
  bool get appliesBurning =>
      power == OceanPower.magmaVentLord &&
      (slot != HardpointType.signature || tier == 3);
  int get burningDuration => power == OceanPower.magmaVentLord ? 3 : 0;
  double get thermalDetonationFraction =>
      power == OceanPower.magmaVentLord && slot == HardpointType.signature
      ? [0.25, 0.40, 0.60][tier - 1]
      : 0;
  int get utilityDuration => slot != HardpointType.utility
      ? 0
      : switch (power) {
          OceanPower.magmaVentLord => tier == 3 ? 3 : 2,
          OceanPower.tempestSovereign || OceanPower.earthshakerTitan => 2,
          OceanPower.brinemother => 0,
        };
  // Reactive state flags already determine which utility effect is active.
  int get wakeMovementDamage => [12, 20, 30][tier - 1];
  double get wakeBurnMultiplier =>
      power == OceanPower.magmaVentLord &&
          slot == HardpointType.utility &&
          tier == 3
      ? 1.5
      : 1;
  int get staticChargeOnHit =>
      power != OceanPower.tempestSovereign || slot == HardpointType.utility
      ? 0
      : slot == HardpointType.signature
      ? (tier == 3 ? 3 : 2)
      : 1;
  int get doubleStaticChargeChance =>
      power == OceanPower.tempestSovereign &&
          slot == HardpointType.broadside &&
          tier == 3
      ? 35
      : 0;
  int get staticChargeOnActivation =>
      power == OceanPower.tempestSovereign && slot == HardpointType.utility
      ? (tier == 3 ? 2 : 1)
      : 0;
  int get stormRetaliationDamage => [10, 18, 26][tier - 1];
  int get staticChargeOnRetaliation => 1;
  int get extraCarapaceMelt => power != OceanPower.brinemother
      ? 0
      : switch (slot) {
          HardpointType.broadside => [4, 8, 12][tier - 1],
          HardpointType.utility => [8, 14, 22][tier - 1],
          _ => 0,
        };
  int get corrodedStacksApplied => power != OceanPower.brinemother
      ? 0
      : switch (slot) {
          HardpointType.broadside => tier == 3 ? 2 : 1,
          HardpointType.signature => tier == 3 ? 3 : 2,
          _ => tier,
        };
  int get corrodedDuration => power == OceanPower.brinemother ? 3 : 0;
  double get unarmoredDamageBonus =>
      power == OceanPower.brinemother &&
          slot == HardpointType.signature &&
          tier == 3
      ? 0.15
      : 0;
  int get shakenAccuracyPenalty =>
      power == OceanPower.earthshakerTitan && slot == HardpointType.broadside
      ? [10, 15, 20][tier - 1]
      : 0;
  double get windupDamageBonus =>
      power == OceanPower.earthshakerTitan && slot == HardpointType.signature
      ? (tier == 3 ? 0.35 : 0.25)
      : 0;
  bool get breaksWindup =>
      power == OceanPower.earthshakerTitan && slot == HardpointType.signature;
  int get windupStunActions => breaksWindup && tier == 3 ? 1 : 0;
  int get barrierHp =>
      power == OceanPower.earthshakerTitan && slot == HardpointType.utility
      ? [15, 25, 35][tier - 1]
      : 0;
  int get barrierEvasionBonus => tier == 3 ? 20 : 15;
  int get tidalShockwaveDamage => [12, 20, 30][tier - 1];

  String get description {
    final bonus = '+${(damageBonus * 100).round()}% weapon damage';
    return switch ((power, slot)) {
      (OceanPower.magmaVentLord, HardpointType.broadside) =>
        '$bonus. Ignites for $burningDuration turns.',
      (OceanPower.magmaVentLord, HardpointType.signature) =>
        '$bonus. ${appliesBurning ? 'Ignites, then triggers' : 'Against Burning targets, triggers'} Thermal Detonation for +${(thermalDetonationFraction * 100).round()}% Blast damage.',
      (OceanPower.magmaVentLord, _) =>
        'Ignites for $burningDuration turns. For $utilityDuration turns, monster movement deals $wakeMovementDamage Fire damage.${wakeBurnMultiplier > 1 ? ' Burning deals +${((wakeBurnMultiplier - 1) * 100).round()}% damage while the wake lasts.' : ''}',
      (OceanPower.tempestSovereign, HardpointType.broadside) =>
        '$bonus. Hits apply $staticChargeOnHit Static Charge.${doubleStaticChargeChance > 0 ? ' $doubleStaticChargeChance% chance to apply 2.' : ''}',
      (OceanPower.tempestSovereign, HardpointType.signature) =>
        '$bonus. +$critChanceBonus% Critical Hit chance. Hits apply $staticChargeOnHit Static Charge.',
      (OceanPower.tempestSovereign, _) =>
        'Applies $staticChargeOnActivation Static Charge. For $utilityDuration turns, enemy attacks trigger $stormRetaliationDamage Shock damage and $staticChargeOnRetaliation Static Charge.',
      (OceanPower.brinemother, HardpointType.broadside) =>
        '$bonus. Deals 2× damage to Carapace, melts $extraCarapaceMelt more, and applies $corrodedStacksApplied Corroded for $corrodedDuration turns.',
      (OceanPower.brinemother, HardpointType.signature) =>
        '$bonus. Damages flesh through Carapace while stripping it. Applies $corrodedStacksApplied Corroded for $corrodedDuration turns.${unarmoredDamageBonus > 0 ? ' +${(unarmoredDamageBonus * 100).round()}% damage against unarmored targets.' : ''}',
      (OceanPower.brinemother, _) =>
        'Clears enemy Obscurity, melts $extraCarapaceMelt Carapace, and applies $corrodedStacksApplied Corroded for $corrodedDuration turns.',
      (OceanPower.earthshakerTitan, HardpointType.broadside) =>
        '$bonus. Deals 1.5× damage to Carapace. Applies Shaken for 1 turn.',
      (OceanPower.earthshakerTitan, HardpointType.signature) =>
        '$bonus. Deals 1.5× damage to Carapace. Breaking a lethal windup deals +${(windupDamageBonus * 100).round()}% damage${windupStunActions > 0 ? ' and Stuns for $windupStunActions action' : '; the beast makes a normal attack instead'}.',
      (OceanPower.earthshakerTitan, _) =>
        'Creates a $barrierHp HP barrier for $utilityDuration turns. Grants +$barrierEvasionBonus% evasion while intact. Hits retaliate for $tidalShockwaveDamage Blast damage.',
    };
  }

  Map<String, dynamic> toJson() => {
    'power': power.name,
    'slot': slot.name,
    'tier': tier,
  };

  factory HardpointBlessing.fromJson(Map<String, dynamic> json) =>
      HardpointBlessing(
        power: OceanPower.values.byName(json['power'] as String),
        slot: HardpointType.values.byName(json['slot'] as String).canonical,
        tier: (json['tier'] as int? ?? 1).clamp(1, 3),
      );
}
