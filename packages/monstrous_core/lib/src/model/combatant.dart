import 'enums.dart';
import 'item.dart';

/// Base entity representing any participant in naval combat.
abstract class Combatant {
  Combatant({
    required this.id,
    required this.name,
    required this.level,
    required this.maxHp,
    int? currentHp,
    required this.armorClass,
    List<StatusEffect>? statusEffects,
  })  : currentHp = currentHp ?? maxHp,
        statusEffects = statusEffects ?? <StatusEffect>[];

  final String id;
  String name;
  int level;
  int maxHp;
  int currentHp;
  int armorClass;
  final List<StatusEffect> statusEffects;

  bool get isAlive => currentHp > 0;

  void applyDamage(int amount) {
    currentHp = (currentHp - amount).clamp(0, maxHp);
  }

  void heal(int amount) {
    currentHp = (currentHp + amount).clamp(0, maxHp);
  }

  void addStatus(StatusEffect effect) {
    if (!statusEffects.contains(effect)) {
      statusEffects.add(effect);
    }
  }

  void removeStatus(StatusEffect effect) {
    statusEffects.remove(effect);
  }

  bool hasStatus(StatusEffect effect) => statusEffects.contains(effect);
}

/// Dynamic state of the player's vessel.
class ShipState extends Combatant {
  ShipState({
    required super.id,
    required super.name,
    required super.level,
    required super.maxHp,
    super.currentHp,
    required super.armorClass,
    super.statusEffects,
    required this.shipClass,
    required this.maxCargo,
    List<Item>? cargo,
    required this.maxWeaponWeight,
    List<ShipWeapon>? equippedWeapons,
    this.baseEvasion = 0,
    int? currentEvasion,
    this.baseDmgReduction = 0,
    int? currentDmgReduction,
    this.dmgReductionMod = 0,
    this.gold = 0,
  })  : cargo = cargo ?? <Item>[],
        equippedWeapons = equippedWeapons ?? <ShipWeapon>[],
        currentEvasion = currentEvasion ?? baseEvasion,
        currentDmgReduction = currentDmgReduction ?? baseDmgReduction;

  final ShipClass shipClass;
  int maxCargo;
  final List<Item> cargo;
  int maxWeaponWeight;
  final List<ShipWeapon> equippedWeapons;

  int baseEvasion;
  int currentEvasion;

  int baseDmgReduction;
  int currentDmgReduction;
  int dmgReductionMod;

  int gold;

  int get currentWeaponWeight =>
      equippedWeapons.fold(0, (sum, w) => sum + w.equipWeight);

  List<ShipWeaponType> get equippedWeaponTypes =>
      equippedWeapons.map((w) => w.weaponType).toSet().toList();

  bool canEquipWeapon(ShipWeapon weapon) =>
      !equippedWeapons.contains(weapon) &&
      (currentWeaponWeight + weapon.equipWeight) <= maxWeaponWeight;

  bool equipWeapon(ShipWeapon weapon) {
    if (!canEquipWeapon(weapon)) return false;
    cargo.remove(weapon);
    equippedWeapons.add(weapon);
    equippedWeapons.sort();
    return true;
  }

  bool unequipWeapon(ShipWeapon weapon) {
    if (!equippedWeapons.contains(weapon)) return false;
    if (cargo.length >= maxCargo) return false;
    equippedWeapons.remove(weapon);
    cargo.add(weapon);
    cargo.sort();
    return true;
  }

  bool addCargo(Item item) {
    if (cargo.length >= maxCargo) return false;
    cargo.add(item);
    cargo.sort();
    return true;
  }

  bool removeCargo(Item item) => cargo.remove(item);

  void decrementChargeTimeOnWeapons() {
    for (final weapon in equippedWeapons) {
      weapon.decrementChargeCountdown();
    }
  }

  void sortCargo() => cargo.sort();
}

/// Dynamic state of a sea monster encounter.
class MonsterState extends Combatant {
  MonsterState({
    required super.id,
    required super.name,
    required super.level,
    required super.maxHp,
    super.currentHp,
    required super.armorClass,
    super.statusEffects,
    required this.species,
    List<MonsterWeapon>? usableWeapons,
    this.isObscured = false,
    this.obscuredAcMod = 0,
    this.numberOfTentacles = 0,
  }) : usableWeapons = usableWeapons ?? <MonsterWeapon>[];

  final MonsterSpecies species;
  final List<MonsterWeapon> usableWeapons;
  bool isObscured;
  int obscuredAcMod;
  int numberOfTentacles;

  int get effectiveArmorClass =>
      isObscured ? armorClass + obscuredAcMod : armorClass;

  void decrementChargeTimeOnWeapons() {
    for (final weapon in usableWeapons) {
      weapon.decrementChargeCountdown();
    }
  }
}
