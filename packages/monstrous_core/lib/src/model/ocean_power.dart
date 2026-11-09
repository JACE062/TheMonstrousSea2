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

  String get description {
    final bonus = '+${(damageBonus * 100).round()}% weapon damage';
    return switch ((power, slot)) {
      (OceanPower.magmaVentLord, HardpointType.broadside) =>
        '$bonus. Ignites for 3 turns.',
      (OceanPower.magmaVentLord, HardpointType.signature) =>
        '$bonus. ${tier == 3 ? 'Ignites, then triggers' : 'Against Burning targets, triggers'} Thermal Detonation for +${[25, 40, 60][tier - 1]}% Blast damage without consuming Burning.',
      (OceanPower.magmaVentLord, _) =>
        'Ignites for 3 turns. For ${tier == 3 ? 3 : 2} turns, monster movement deals ${[12, 20, 30][tier - 1]} Fire damage.${tier == 3 ? ' Burning deals +50% damage while the wake lasts.' : ''}',
      (OceanPower.tempestSovereign, HardpointType.broadside) =>
        '$bonus. Hits apply 1 Static Charge.${tier == 3 ? ' 35% chance to apply 2.' : ''}',
      (OceanPower.tempestSovereign, HardpointType.signature) =>
        '$bonus. +$critChanceBonus% Critical Hit chance. Hits apply ${tier == 3 ? 3 : 2} Static Charge.',
      (OceanPower.tempestSovereign, _) =>
        'Applies ${tier == 3 ? 2 : 1} Static Charge. For 2 turns, enemy attacks trigger ${[10, 18, 26][tier - 1]} Shock damage and 1 Static Charge.',
      (OceanPower.brinemother, HardpointType.broadside) =>
        '$bonus. Deals 2× damage to Carapace, melts ${[4, 8, 12][tier - 1]} more, and applies ${tier == 3 ? 2 : 1} Corroded for 3 turns.',
      (OceanPower.brinemother, HardpointType.signature) =>
        '$bonus. Damages flesh through Carapace while stripping it. Applies ${tier == 3 ? 3 : 2} Corroded for 3 turns.${tier == 3 ? ' +15% damage against unarmored targets.' : ''}',
      (OceanPower.brinemother, _) =>
        'Clears enemy Obscurity, melts ${[8, 14, 22][tier - 1]} Carapace, and applies $tier Corroded for 3 turns.',
      (OceanPower.earthshakerTitan, HardpointType.broadside) =>
        '$bonus. Deals 1.5× damage to Carapace. Applies Shaken for 1 turn.',
      (OceanPower.earthshakerTitan, HardpointType.signature) =>
        '$bonus. Deals 1.5× damage to Carapace. Breaking a lethal windup deals +${tier == 3 ? 35 : 25}% damage${tier == 3 ? ' and Stuns for 1 action' : '; the beast makes a normal attack instead'}.',
      (OceanPower.earthshakerTitan, _) =>
        'Creates a ${[15, 25, 35][tier - 1]} HP barrier for 2 turns. Grants +${tier == 3 ? 20 : 15}% evasion while intact. Hits retaliate for ${[12, 20, 30][tier - 1]} Blast damage (1.5× against Carapace).',
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
