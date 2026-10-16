import 'package:monstrous_core/monstrous_core.dart';

/// Transparent illustrations in the approved simple sea-map style.
class PilotArt {
  const PilotArt._();

  static const standard = 'assets/art/ship_standard_map.png';
  static const freighter = 'assets/art/ship_freighter_pilot_v2.png';
  static const ironclad = 'assets/art/ship_ironclad_map_v2.png';
  static const corvette = 'assets/art/ship_corvette_map.png';
  static const flyingDutchman = 'assets/art/ship_flying_dutchman_map.png';
  static const shark = 'assets/art/monster_shark_map.png';
  static const serpent = 'assets/art/monster_serpent_map.png';
  static const jellyfish = 'assets/art/monster_jellyfish_map.png';
  static const squid = 'assets/art/monster_squid_map_v5.png';
  static const crustacean = 'assets/art/monster_crustacean_map.png';
  static const kraken = 'assets/art/monster_kraken_boss_v5.png';
  static const unstableTincture =
      'assets/art/icon_unstable_tincture_map_v4.png';
  static const blastPack = 'assets/art/icon_blast_pack_map.png';
  static const chakram = 'assets/art/icon_chakram_map.png';
  static const cannon = 'assets/art/icon_cannon_map.png';
  static const torpedoLauncher = 'assets/art/icon_torpedo_launcher_map_v2.png';
  static const bladeLauncher = 'assets/art/icon_blade_launcher_map.png';
  static const lightningRailgun = 'assets/art/icon_lightning_railgun_map.png';
  static const flamethrower = 'assets/art/icon_flamethrower_map_v2.png';
  static const treasure = 'assets/art/icon_treasure_map.png';
  static const helm = 'assets/art/icon_helm_map.png';
  static const anchor = 'assets/art/icon_anchor_map.png';
  static const cannons = 'assets/art/icon_cannons_map.png';
  static const portHaven = 'assets/art/icon_port_haven_map.png';
  static const defeatedMonster = 'assets/art/icon_skull_map.png';
  static const fog = 'assets/art/icon_fog_map.png';

  static const chartAssets = [portHaven, defeatedMonster, fog];

  static const allAssets = [
    standard,
    freighter,
    ironclad,
    corvette,
    flyingDutchman,
    shark,
    serpent,
    jellyfish,
    squid,
    crustacean,
    kraken,
    unstableTincture,
    blastPack,
    chakram,
    cannon,
    torpedoLauncher,
    bladeLauncher,
    lightningRailgun,
    flamethrower,
    treasure,
    helm,
    anchor,
    cannons,
    ...chartAssets,
  ];

  static String forShip(ShipState ship) {
    if (ship.id == 'flying_dutchman' || ship.name == 'Flying Dutchman') {
      return flyingDutchman;
    }
    return forShipClass(ship.shipClass);
  }

  static String forShipClass(ShipClass shipClass) => switch (shipClass) {
    ShipClass.standard => standard,
    ShipClass.freighter || ShipClass.corsair => freighter,
    ShipClass.ironclad || ShipClass.bombardier => ironclad,
    ShipClass.corvette || ShipClass.clipper => corvette,
  };

  static bool isKraken(MonsterState monster) =>
      monster.species == MonsterSpecies.kraken || monster.id == 'the_kraken';

  static String forMonster(MonsterState monster) {
    if (isKraken(monster)) return kraken;
    return forSpecies(monster.species);
  }

  static String forSpecies(MonsterSpecies species) => switch (species) {
    MonsterSpecies.shark => shark,
    MonsterSpecies.serpent => serpent,
    MonsterSpecies.jellyfish => jellyfish,
    MonsterSpecies.squid => squid,
    MonsterSpecies.crustacean => crustacean,
    MonsterSpecies.kraken => kraken,
    MonsterSpecies.worldSerpent => serpent,
    MonsterSpecies.ancientLeviathan => kraken,
  };
}
