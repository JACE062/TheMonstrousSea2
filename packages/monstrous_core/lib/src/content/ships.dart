import '../model/combatant.dart';
import '../model/enums.dart';
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
  }
}
