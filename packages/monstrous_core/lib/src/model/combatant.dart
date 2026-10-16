import 'enums.dart';
import 'flagship_blueprint.dart';
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
    int? maxWeaponWeight,
    List<ShipWeapon>? equippedWeapons,
    this.baseEvasion = 0,
    int? currentEvasion,
    this.baseDmgReduction = 0,
    int? currentDmgReduction,
    this.dmgReductionMod = 0,
    this.gold = 0,
    String? blueprintId,
    List<HardpointSlot>? hardpoints,
  })  : maxWeaponWeight = maxWeaponWeight ?? 10,
        blueprintId = blueprintId ?? shipClass.blueprintId.name,
        hardpoints = List<HardpointSlot>.from(
          hardpoints ??
              (FlagshipBlueprint.catalog[shipClass.blueprintId]?.hardpoints ??
                  const <HardpointSlot>[]),
        ),
        cargo = cargo ?? <Item>[],
        equippedWeapons = equippedWeapons ?? <ShipWeapon>[],
        currentEvasion = currentEvasion ?? baseEvasion,
        currentDmgReduction = currentDmgReduction ?? baseDmgReduction;

  final ShipClass shipClass;
  String blueprintId;
  final List<HardpointSlot> hardpoints;
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

  /// Total number of deck hardpoints available on this hull.
  int get maxHardpointSlots => hardpoints.length;

  /// Current number of mounted weapons.
  int get currentHardpointCount => equippedWeapons.length;

  /// Legacy accessor kept for telemetry and backward-compatibility.
  int get currentWeaponWeight =>
      equippedWeapons.fold(0, (sum, w) => sum + w.equipWeight);

  List<ShipWeaponType> get equippedWeaponTypes =>
      equippedWeapons.map((w) => w.weaponType).toSet().toList();

  /// Validates whether a weapon can be mounted on the flagship's open deck hardpoints.
  bool canEquipWeapon(ShipWeapon weapon) =>
      !equippedWeapons.contains(weapon) &&
      equippedWeapons.length < hardpoints.length;

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

  /// Refreshes all equipped weapons to ready status (0 cooldown) between battles.
  void resetWeaponCooldowns() {
    for (final weapon in equippedWeapons) {
      weapon.chargeCountdown = 0;
    }
  }

  void sortCargo() => cargo.sort();

  /// Resets temporary in-combat stat modifications (Fortify armor boost, Evasion boost)
  /// back to base hull characteristics and refreshes all gun batteries after a battle concludes.
  void resetCombatBoosts() {
    currentDmgReduction = baseDmgReduction;
    currentEvasion = baseEvasion;
    resetWeaponCooldowns();
  }

  factory ShipState.fromJson(Map<String, dynamic> json) {
    final shipClassName = json['shipClass'] as String? ?? 'standard';
    final shipClass = ShipClass.values.firstWhere(
      (e) => e.name == shipClassName,
      orElse: () => ShipClass.standard,
    );
    final cargoList = (json['cargo'] as List<dynamic>?)
        ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList();
    final weaponsList = (json['equippedWeapons'] as List<dynamic>?)
        ?.map((e) => ShipWeapon.fromJson(e as Map<String, dynamic>))
        .toList();

    final bpId = json['blueprintId'] as String? ?? shipClass.blueprintId.name;
    final hardpointsList = (json['hardpoints'] as List<dynamic>?)
        ?.map((e) => HardpointSlot.fromJson(e as Map<String, dynamic>))
        .toList();

    return ShipState(
      id: json['id'] as String? ?? 'player_ship',
      name: json['name'] as String? ?? 'The Sea Wanderer',
      level: json['level'] as int? ?? 1,
      maxHp: json['maxHp'] as int? ?? 100,
      currentHp: json['currentHp'] as int?,
      armorClass: json['armorClass'] as int? ?? 10,
      shipClass: shipClass,
      blueprintId: bpId,
      hardpoints: hardpointsList,
      maxCargo: json['maxCargo'] as int? ?? 10,
      cargo: cargoList,
      maxWeaponWeight: json['maxWeaponWeight'] as int? ?? 10,
      equippedWeapons: weaponsList,
      baseEvasion: json['baseEvasion'] as int? ?? 0,
      currentEvasion: json['currentEvasion'] as int?,
      baseDmgReduction: json['baseDmgReduction'] as int? ?? 0,
      currentDmgReduction: json['currentDmgReduction'] as int?,
      dmgReductionMod: json['dmgReductionMod'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'level': level,
        'maxHp': maxHp,
        'currentHp': currentHp,
        'armorClass': armorClass,
        'shipClass': shipClass.name,
        'blueprintId': blueprintId,
        'hardpoints': hardpoints.map((e) => e.toJson()).toList(),
        'maxCargo': maxCargo,
        'cargo': cargo.map((e) => e.toJson()).toList(),
        'maxWeaponWeight': maxWeaponWeight,
        'equippedWeapons': equippedWeapons.map((e) => e.toJson()).toList(),
        'baseEvasion': baseEvasion,
        'currentEvasion': currentEvasion,
        'baseDmgReduction': baseDmgReduction,
        'currentDmgReduction': currentDmgReduction,
        'dmgReductionMod': dmgReductionMod,
        'gold': gold,
      };
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
    this.carapacePlating = 0,
    int? maxCarapace,
    this.frenzyStacks = 0,
    this.evasion = 0,
    this.isApex = false,
    this.apexTitle,
  })  : maxCarapace = maxCarapace ?? carapacePlating,
        usableWeapons = usableWeapons ?? <MonsterWeapon>[];

  final MonsterSpecies species;
  final List<MonsterWeapon> usableWeapons;
  bool isApex;
  String? apexTitle;
  bool isObscured;
  int obscuredAcMod;
  int numberOfTentacles;

  /// Crustacean armored shell durability. Mitigates non-blast/fire attacks; shattered by blast.
  int carapacePlating;
  int maxCarapace;

  /// Shark damage ramping frenzy stacks (+25% damage per stack, disrupted by shock/stun).
  int frenzyStacks;

  /// Evasion chance percentage (e.g. Serpent slither).
  int evasion;

  int get effectiveArmorClass =>
      isObscured ? armorClass + obscuredAcMod : armorClass;

  void decrementChargeTimeOnWeapons() {
    for (final weapon in usableWeapons) {
      weapon.decrementChargeCountdown();
    }
  }
}
