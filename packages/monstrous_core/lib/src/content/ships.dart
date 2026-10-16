import '../model/combatant.dart';
import '../model/covenant_of_the_deep.dart';
import '../model/enums.dart';
import '../model/flagship_blueprint.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';
import 'names/name_forge.dart';
import 'ship_weapons.dart';

int _shipIdCounter = 0;

/// Factory function to create a [ShipState] for a Standard Ship.
///
/// Formulas:
/// - HP: `50 + [40..60] * level`
/// - AC: `8 + 2 * level`
/// - Cargo: `5 + [10..20] * level`
/// - MaxWeight: `7 * level`
ShipState createStandardShip({
  required int level,
  required GameRng rng,
  String? name,
  String? id,
  List<ShipWeapon>? equippedWeapons,
}) {
  final shipName = name ?? NameForge.generateShipName(ShipClass.standard, rng);
  final shipId = id ?? 'ship_standard_${++_shipIdCounter}';
  final hp = 50 + rng.nextIntRange(40, 60) * level;
  final ac = 8 + 2 * level;
  final cargo = 5 + rng.nextIntRange(10, 20) * level;
  final maxWeight = 7 * level;

  return ShipState(
    id: shipId,
    name: shipName,
    level: level,
    maxHp: hp,
    armorClass: ac,
    shipClass: ShipClass.standard,
    maxCargo: cargo,
    maxWeaponWeight: maxWeight,
    equippedWeapons: equippedWeapons,
  );
}

/// Factory function to create a [ShipState] for a Freighter.
///
/// Formulas:
/// - HP: `25 + [80..120] * level`
/// - AC: `6 + 2 * level`
/// - Cargo: `[20..40] * level`
/// - MaxWeight: `3 * level`
ShipState createFreighter({
  required int level,
  required GameRng rng,
  String? name,
  String? id,
  List<ShipWeapon>? equippedWeapons,
}) {
  final shipName = name ?? NameForge.generateShipName(ShipClass.freighter, rng);
  final shipId = id ?? 'ship_freighter_${++_shipIdCounter}';
  final hp = 25 + rng.nextIntRange(80, 120) * level;
  final ac = 6 + 2 * level;
  final cargo = rng.nextIntRange(20, 40) * level;
  final maxWeight = 3 * level;

  return ShipState(
    id: shipId,
    name: shipName,
    level: level,
    maxHp: hp,
    armorClass: ac,
    shipClass: ShipClass.freighter,
    maxCargo: cargo,
    maxWeaponWeight: maxWeight,
    equippedWeapons: equippedWeapons,
  );
}

/// Factory function to create a [ShipState] for an Ironclad.
///
/// Formulas:
/// - HP: `25 + [65..85] * level`
/// - AC: `10 + 2 * level`
/// - Cargo: `5 + [5..7] * level`
/// - MaxWeight: `10 * level`
/// - baseDmgReduction: `3 * level`
/// - dmgReductionMod: `2 * level`
ShipState createIronclad({
  required int level,
  required GameRng rng,
  String? name,
  String? id,
  List<ShipWeapon>? equippedWeapons,
}) {
  final shipName = name ?? NameForge.generateShipName(ShipClass.ironclad, rng);
  final shipId = id ?? 'ship_ironclad_${++_shipIdCounter}';
  final hp = 25 + rng.nextIntRange(65, 85) * level;
  final ac = 10 + 2 * level;
  final cargo = 5 + rng.nextIntRange(5, 7) * level;
  final maxWeight = 10 * level;
  final baseDmgReduction = 3 * level;
  final dmgReductionMod = 2 * level;

  return ShipState(
    id: shipId,
    name: shipName,
    level: level,
    maxHp: hp,
    armorClass: ac,
    shipClass: ShipClass.ironclad,
    maxCargo: cargo,
    maxWeaponWeight: maxWeight,
    baseDmgReduction: baseDmgReduction,
    dmgReductionMod: dmgReductionMod,
    equippedWeapons: equippedWeapons,
  );
}

/// Factory function to create a [ShipState] for a Corvette.
///
/// Formulas:
/// - HP: `40 + [30..50] * level`
/// - AC: `4 + 2 * level`
/// - Cargo: `5 + [5..15] * level`
/// - MaxWeight: `5 * level`
/// - baseEvasion: `(5 + 5 * level).clamp(0, 50)`
ShipState createCorvette({
  required int level,
  required GameRng rng,
  String? name,
  String? id,
  List<ShipWeapon>? equippedWeapons,
}) {
  final shipName = name ?? NameForge.generateShipName(ShipClass.corvette, rng);
  final shipId = id ?? 'ship_corvette_${++_shipIdCounter}';
  final hp = 40 + rng.nextIntRange(30, 50) * level;
  final ac = 4 + 2 * level;
  final cargo = 5 + rng.nextIntRange(5, 15) * level;
  final maxWeight = 5 * level;
  final baseEvasion = (5 + 5 * level).clamp(0, 50);

  return ShipState(
    id: shipId,
    name: shipName,
    level: level,
    maxHp: hp,
    armorClass: ac,
    shipClass: ShipClass.corvette,
    maxCargo: cargo,
    maxWeaponWeight: maxWeight,
    baseEvasion: baseEvasion,
    equippedWeapons: equippedWeapons,
  );
}

/// Factory function to create the legendary Flying Dutchman (Davy Jones special).
///
/// Stats:
/// - Class: Ironclad lvl 4
/// - HP: 1600
/// - AC: 18
/// - Cargo: 300
/// - MaxWeaponWeight: 50
/// - Equipped with legendary weapons (8 Cannons, 6 Blade Launchers,
///   2 Lightning Railguns, 2 Flamethrowers).
ShipState createFlyingDutchman({
  GameRng? rng,
  String? name,
  String? id,
}) {
  final effectiveRng = rng ?? SeededGameRng(42);
  final weapons = <ShipWeapon>[
    for (var i = 0; i < 8; i++)
      generateShipWeapon(
        ShipWeaponType.cannon,
        4,
        RarityLevel.legendary,
        effectiveRng,
      ),
    for (var i = 0; i < 6; i++)
      generateShipWeapon(
        ShipWeaponType.bladeLauncher,
        4,
        RarityLevel.legendary,
        effectiveRng,
      ),
    for (var i = 0; i < 2; i++)
      generateShipWeapon(
        ShipWeaponType.lightningRailgun,
        4,
        RarityLevel.legendary,
        effectiveRng,
      ),
    for (var i = 0; i < 2; i++)
      generateShipWeapon(
        ShipWeaponType.flamethrower,
        4,
        RarityLevel.legendary,
        effectiveRng,
      ),
  ];

  return ShipState(
    id: id ?? 'flying_dutchman',
    name: name ?? 'Flying Dutchman',
    level: 4,
    maxHp: 1600,
    armorClass: 18,
    shipClass: ShipClass.ironclad,
    maxCargo: 300,
    maxWeaponWeight: 50,
    baseDmgReduction: 8,
    dmgReductionMod: 8,
    equippedWeapons: weapons,
  );
}

/// Factory function to create a [ShipState] from an ancestral [FlagshipBlueprint].
///
/// Sets up the flagship according to its blueprint specifications:
/// - Base stats: HP, AC, Evasion, Cargo, Damage Reduction.
/// - Hardpoints: configured from the blueprint.
/// - Starting weapons: mounts the blueprint's signature weapon (if any) and baseline weapons:
///   * Standard: 2 Cannons
///   * Ironclad: Prow Ram + Cannon
///   * Clipper: Precision Culverin + Cannon
///   * Bombardier: Heavy Mortar + 2 Cannons
///   * Corsair: Harpoon Winch + Cannon
ShipState createFlagshipFromBlueprint(
  BlueprintId blueprintId, {
  int level = 1,
  required GameRng rng,
  String? name,
  String? id,
  List<ShipWeapon>? equippedWeapons,
  int armamentTier = 1,
  bool hasExpandedAuxiliarySlot = false,
  int bonusMaxHp = 0,
}) {
  final bp = FlagshipBlueprint.catalog[blueprintId] ??
      FlagshipBlueprint.catalog[BlueprintId.standard]!;
  final shipName = name ?? NameForge.generateShipName(bp.id.shipClass, rng);
  final shipId = id ?? 'flagship_${blueprintId.name}_${++_shipIdCounter}';

  final hp = bp.baseHp + (level - 1) * 40 + bonusMaxHp;
  final ac = bp.baseArmorClass + (level - 1) * 2;
  final cargo = bp.baseCargo + (level - 1) * 5;
  final baseMaxWeight = switch (blueprintId) {
    BlueprintId.standard => 7 * level,
    BlueprintId.ironclad => 10 * level,
    BlueprintId.clipper => 6 * level,
    BlueprintId.bombardier => 8 * level,
    BlueprintId.corsair => 7 * level,
  };
  final maxWeight = baseMaxWeight + (hasExpandedAuxiliarySlot ? 2 : 0);
  final evasion = (bp.baseEvasion + (level - 1) * 5).clamp(0, 50);
  final dmgReduction = bp.baseDamageReduction + (level - 1) * 2;
  final dmgReductionMod = blueprintId == BlueprintId.ironclad ? 2 * level : 0;

  final hardpoints = hasExpandedAuxiliarySlot
      ? <HardpointSlot>[
          ...bp.hardpoints,
          const HardpointSlot(
            id: 'reserve_aux',
            name: 'Reserve Aux Mount',
            type: HardpointType.auxiliary,
          ),
        ]
      : bp.hardpoints;

  final weapons = equippedWeapons ??
      _createDefaultWeaponsForBlueprint(
        blueprintId,
        level,
        rng,
        armamentTier: armamentTier,
      );

  final ship = ShipState(
    id: shipId,
    name: shipName,
    level: level,
    maxHp: hp,
    armorClass: ac,
    shipClass: bp.id.shipClass,
    blueprintId: blueprintId.name,
    hardpoints: hardpoints,
    maxCargo: cargo,
    maxWeaponWeight: maxWeight,
    baseEvasion: evasion,
    baseDmgReduction: dmgReduction,
    dmgReductionMod: dmgReductionMod,
    equippedWeapons: weapons,
  );
  for (final w in weapons) {
    if (!ship.cargo.contains(w)) {
      ship.addCargo(w);
    }
  }
  return ship;
}

List<ShipWeapon> _createDefaultWeaponsForBlueprint(
  BlueprintId blueprintId,
  int level,
  GameRng rng, {
  int armamentTier = 1,
}) {
  final rarity = rarityForLevel(level);
  final weapons = switch (blueprintId) {
    BlueprintId.standard => [
        generateShipWeapon(ShipWeaponType.cannon, level, rarity, rng),
        generateShipWeapon(ShipWeaponType.cannon, level, rarity, rng),
      ],
    BlueprintId.ironclad => [
        generateShipWeapon(ShipWeaponType.prowRam, level, rarity, rng),
        generateShipWeapon(ShipWeaponType.cannon, level, rarity, rng),
      ],
    BlueprintId.clipper => [
        generateShipWeapon(ShipWeaponType.precisionCulverin, level, rarity, rng),
        generateShipWeapon(ShipWeaponType.cannon, level, rarity, rng),
      ],
    BlueprintId.bombardier => [
        generateShipWeapon(ShipWeaponType.heavyMortar, level, rarity, rng),
        generateShipWeapon(ShipWeaponType.cannon, level, rarity, rng),
        generateShipWeapon(ShipWeaponType.cannon, level, rarity, rng),
      ],
    BlueprintId.corsair => [
        generateShipWeapon(ShipWeaponType.harpoonWinch, level, rarity, rng),
        generateShipWeapon(ShipWeaponType.cannon, level, rarity, rng),
      ],
  };

  if (armamentTier > 1) {
    final mult = BlueprintArmamentProgression.damageMultiplierForTier(
      armamentTier,
    );
    final numeral = armamentTier == 2 ? 'II' : 'III';
    for (final w in weapons) {
      if (w.isSignature || blueprintId == BlueprintId.standard) {
        w.damage = (w.damage * mult).round();
        w.name = '${w.name} $numeral';
      }
    }
  }
  return weapons;
}

/// General dispatcher creating a [ShipState] by [shipClass].
ShipState createShip(
  ShipClass shipClass, {
  required int level,
  required GameRng rng,
  String? name,
  String? id,
  List<ShipWeapon>? equippedWeapons,
}) {
  switch (shipClass) {
    case ShipClass.standard:
      return createStandardShip(
        level: level,
        rng: rng,
        name: name,
        id: id,
        equippedWeapons: equippedWeapons,
      );
    case ShipClass.freighter:
      return createFreighter(
        level: level,
        rng: rng,
        name: name,
        id: id,
        equippedWeapons: equippedWeapons,
      );
    case ShipClass.ironclad:
      return createIronclad(
        level: level,
        rng: rng,
        name: name,
        id: id,
        equippedWeapons: equippedWeapons,
      );
    case ShipClass.corvette:
      return createCorvette(
        level: level,
        rng: rng,
        name: name,
        id: id,
        equippedWeapons: equippedWeapons,
      );
    case ShipClass.clipper:
      return createFlagshipFromBlueprint(
        BlueprintId.clipper,
        level: level,
        rng: rng,
        name: name,
        id: id,
        equippedWeapons: equippedWeapons,
      );
    case ShipClass.bombardier:
      return createFlagshipFromBlueprint(
        BlueprintId.bombardier,
        level: level,
        rng: rng,
        name: name,
        id: id,
        equippedWeapons: equippedWeapons,
      );
    case ShipClass.corsair:
      return createFlagshipFromBlueprint(
        BlueprintId.corsair,
        level: level,
        rng: rng,
        name: name,
        id: id,
        equippedWeapons: equippedWeapons,
      );
  }
}

/// Returns the gold cost to refit and upgrade a ship from [currentLevel] to `currentLevel + 1`.
int calculateShipUpgradeCost(int currentLevel) {
  return switch (currentLevel) {
    1 => 100,
    2 => 250,
    3 => 500,
    _ => 0,
  };
}

/// Refits [ship] to its next level tier, expanding max HP, cargo, gun deck weight,
/// and unique class defense traits (Damage Reduction on Ironclad, Evasion on Corvette/Clipper).
void upgradeShipState(ShipState ship) {
  if (ship.level >= 4) return;
  ship.level++;
  final lvl = ship.level;

  switch (ship.shipClass) {
    case ShipClass.standard:
      const hpGain = 50;
      ship.maxHp += hpGain;
      ship.currentHp = (ship.currentHp + hpGain).clamp(0, ship.maxHp);
      ship.maxWeaponWeight = 7 * lvl;
      ship.maxCargo += 15;
    case ShipClass.freighter:
      const hpGain = 100;
      ship.maxHp += hpGain;
      ship.currentHp = (ship.currentHp + hpGain).clamp(0, ship.maxHp);
      ship.maxWeaponWeight = 3 * lvl;
      ship.maxCargo += 25;
    case ShipClass.ironclad:
      const hpGain = 75;
      ship.maxHp += hpGain;
      ship.currentHp = (ship.currentHp + hpGain).clamp(0, ship.maxHp);
      ship.maxWeaponWeight = 10 * lvl;
      ship.maxCargo += 6;
      ship.baseDmgReduction = 3 * lvl;
      ship.currentDmgReduction = ship.baseDmgReduction;
      ship.dmgReductionMod = 2 * lvl;
    case ShipClass.corvette:
      const hpGain = 40;
      ship.maxHp += hpGain;
      ship.currentHp = (ship.currentHp + hpGain).clamp(0, ship.maxHp);
      ship.maxWeaponWeight = 5 * lvl;
      ship.maxCargo += 10;
      ship.baseEvasion = (5 + 5 * lvl).clamp(0, 50);
      ship.currentEvasion = ship.baseEvasion;
    case ShipClass.clipper:
      const hpGain = 40;
      ship.maxHp += hpGain;
      ship.currentHp = (ship.currentHp + hpGain).clamp(0, ship.maxHp);
      ship.maxWeaponWeight = 6 * lvl;
      ship.maxCargo += 10;
      ship.baseEvasion = (ship.baseEvasion + 5).clamp(0, 50);
      ship.currentEvasion = ship.baseEvasion;
    case ShipClass.bombardier:
      const hpGain = 45;
      ship.maxHp += hpGain;
      ship.currentHp = (ship.currentHp + hpGain).clamp(0, ship.maxHp);
      ship.maxWeaponWeight = 8 * lvl;
      ship.maxCargo += 12;
    case ShipClass.corsair:
      const hpGain = 45;
      ship.maxHp += hpGain;
      ship.currentHp = (ship.currentHp + hpGain).clamp(0, ship.maxHp);
      ship.maxWeaponWeight = 7 * lvl;
      ship.maxCargo += 20;
      ship.baseEvasion = (ship.baseEvasion + 3).clamp(0, 50);
      ship.currentEvasion = ship.baseEvasion;
  }
}

