import 'enums.dart';
import 'flagship_blueprint.dart';
import 'item.dart';
import 'monster_intent.dart';

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
    this.isGrappled = false,
    this.tempAccuracyPenalty = 0,
    this.utilityCooldown = 0,
    Map<HardpointType, int>? hardpointMarks,
    this.isAnchoredThisTurn = false,
    this.isBracedByDrill = false,
    this.gunneryDrillBuffActive = false,
    this.pitchCoatingActive = false,
    this.activeTetherTrapDistance,
    this.activeTetherTrapDamage = 0,
  })  : maxWeaponWeight = maxWeaponWeight ?? 10,
        blueprintId = blueprintId ?? shipClass.blueprintId.name,
        hardpoints = List<HardpointSlot>.from(
          hardpoints ??
              (FlagshipBlueprint.catalog[shipClass.blueprintId]?.hardpoints ??
                  const <HardpointSlot>[]),
        ),
        hardpointMarks = <HardpointType, int>{
          HardpointType.broadside: 1,
          HardpointType.signature: 1,
          HardpointType.utility: 1,
          ...?hardpointMarks,
        },
        cargo = cargo ?? <Item>[],
        equippedWeapons = equippedWeapons ?? <ShipWeapon>[],
        currentEvasion = currentEvasion ?? baseEvasion,
        currentDmgReduction = currentDmgReduction ?? baseDmgReduction;

  ShipClass shipClass;
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

  /// True if the ship's rudder/hull is grappled by a Squid/Kraken beak for the current turn,
  /// locking Helm Orders to [HelmOrder.holdLine].
  bool isGrappled;

  /// Temporary accuracy penalty from monster wake/flash abilities (cleared after 1 round).
  int tempAccuracyPenalty;

  /// Remaining turn cooldown on the ship's Utility Hardpoint (2T max).
  int utilityCooldown;

  /// Tempering Marks (`1` = Mk I, `2` = Mk II, `3` = Mk III) for each of the 3 hardpoints.
  final Map<HardpointType, int> hardpointMarks;

  /// True if Ironclad's Fortify Iron Plates anchored the hull this round against monster push/pull.
  bool isAnchoredThisTurn;

  /// True if Standard's Gunnery Drill braced the crew this round (-20% incoming damage).
  bool isBracedByDrill;

  /// True if Standard's Gunnery Drill empowered the next offensive volley (+15% Accuracy, +20% Damage).
  bool gunneryDrillBuffActive;

  /// True if an Alchemical Pitch Flask coated the next offensive volley (+25% Fire damage & Burn).
  bool pitchCoatingActive;

  /// Current distance (in range bands: 0, 1, or 2) from a deployed Corsair Drifting Tether-Trap to the monster.
  int? activeTetherTrapDistance;

  /// Base Slicing damage stored in the active Corsair Drifting Tether-Trap.
  int activeTetherTrapDamage;

  /// Resolves the active [BlueprintId] for this hull.
  BlueprintId get resolvedBlueprintId => BlueprintId.values.firstWhere(
        (b) => b.name == blueprintId,
        orElse: () => shipClass.blueprintId,
      );

  /// The blueprint's intrinsic Utility Hardpoint mechanism.
  UtilityHardpointId get utilityHardpoint =>
      resolvedBlueprintId.utilityHardpoint;

  /// True if the Utility Hardpoint is off cooldown and ready to activate.
  bool get isUtilityReady => utilityCooldown <= 0;

  /// Returns the current Tempering Mark (`1`..`3`) for [slot].
  int markForHardpoint(HardpointType slot) =>
      (hardpointMarks[slot.canonical] ?? 1).clamp(1, 3);

  /// Returns the Roman numeral label (`Mk I`, `Mk II`, `Mk III`) for [slot]'s Tempering Mark.
  String markLabelForHardpoint(HardpointType slot) =>
      switch (markForHardpoint(slot)) {
        2 => 'Mk II',
        3 => 'Mk III',
        _ => 'Mk I',
      };

  /// Returns the damage/potency multiplier (`1.0`, `1.2`, `1.4`) for [slot]'s Tempering Mark.
  double multiplierForHardpointMark(HardpointType slot) =>
      switch (markForHardpoint(slot)) {
        2 => 1.20,
        3 => 1.40,
        _ => 1.00,
      };

  /// Alias for [multiplierForHardpointMark].
  double hardpointMarkMultiplier(HardpointType slot) =>
      multiplierForHardpointMark(slot);

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
    if (utilityCooldown > 0) {
      utilityCooldown--;
    }
  }

  /// Refreshes all equipped weapons and the utility hardpoint to ready status (0 cooldown) between battles.
  void resetWeaponCooldowns() {
    for (final weapon in equippedWeapons) {
      weapon.chargeCountdown = 0;
    }
    utilityCooldown = 0;
  }

  void sortCargo() => cargo.sort();

  /// Resets temporary in-combat stat modifications (Fortify armor boost, Evasion boost, Grapple, Utility buffs/traps)
  /// back to base hull characteristics and refreshes all gun batteries after a battle concludes.
  void resetCombatBoosts() {
    currentDmgReduction = baseDmgReduction;
    currentEvasion = baseEvasion;
    isGrappled = false;
    tempAccuracyPenalty = 0;
    isAnchoredThisTurn = false;
    isBracedByDrill = false;
    gunneryDrillBuffActive = false;
    pitchCoatingActive = false;
    activeTetherTrapDistance = null;
    activeTetherTrapDamage = 0;
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

    final rawMarks = json['hardpointMarks'] as Map<String, dynamic>?;
    final parsedMarks = <HardpointType, int>{
      HardpointType.broadside: 1,
      HardpointType.signature: 1,
      HardpointType.utility: 1,
    };
    if (rawMarks != null) {
      for (final entry in rawMarks.entries) {
        final key = HardpointType.values
            .firstWhere(
              (h) => h.name == entry.key,
              orElse: () => HardpointType.broadside,
            )
            .canonical;
        parsedMarks[key] = (entry.value as int? ?? 1).clamp(1, 3);
      }
    }

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
      maxCargo: json['maxCargo'] as int? ?? 3,
      cargo: cargoList,
      maxWeaponWeight: json['maxWeaponWeight'] as int? ?? 10,
      equippedWeapons: weaponsList,
      baseEvasion: json['baseEvasion'] as int? ?? 0,
      currentEvasion: json['currentEvasion'] as int?,
      baseDmgReduction: json['baseDmgReduction'] as int? ?? 0,
      currentDmgReduction: json['currentDmgReduction'] as int?,
      dmgReductionMod: json['dmgReductionMod'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      isGrappled: json['isGrappled'] as bool? ?? false,
      tempAccuracyPenalty: json['tempAccuracyPenalty'] as int? ?? 0,
      utilityCooldown: json['utilityCooldown'] as int? ?? 0,
      hardpointMarks: parsedMarks,
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
        'isGrappled': isGrappled,
        'tempAccuracyPenalty': tempAccuracyPenalty,
        'utilityCooldown': utilityCooldown,
        'hardpointMarks': {
          for (final entry in hardpointMarks.entries)
            entry.key.name: entry.value,
        },
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
    this.currentIntent,
    Map<MonsterIntentId, int>? intentCooldowns,
    this.isPinnedThisTurn = false,
    this.windupDamageTaken = 0,
    this.lastExecutedIntentId,
    this.spotterFlareTurns = 0,
    this.spotterFlareBlastBonus = 0.25,
    this.spotterFlareAccuracyBonus = 15,
  })  : maxCarapace = maxCarapace ?? carapacePlating,
        usableWeapons = usableWeapons ?? <MonsterWeapon>[],
        intentCooldowns = intentCooldowns ?? <MonsterIntentId, int>{};

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

  /// Telegraphed intention for the current combat round.
  MonsterIntent? currentIntent;

  /// Active turn cooldowns per intent ID to prevent ability spam.
  final Map<MonsterIntentId, int> intentCooldowns;

  /// True if hit by a Harpoon Winch, Tether-Trap, or Stun this round, canceling the
  /// movement component of the monster's intent and halving its evasion.
  bool isPinnedThisTurn;

  /// Legacy field retained for serialization/test compatibility.
  int windupDamageTaken;

  /// Last executed intent ID for anti-repeat weighting.
  MonsterIntentId? lastExecutedIntentId;

  /// Remaining turns of Bombardier Phosphor Spotter Flare illumination on this monster.
  int spotterFlareTurns;

  /// Bonus Blast damage multiplier while illuminated by a Spotter Flare (default +25%).
  double spotterFlareBlastBonus;

  /// Bonus accuracy granted against this monster while illuminated by a Spotter Flare (default +15%).
  int spotterFlareAccuracyBonus;

  bool get isIlluminatedByFlare => spotterFlareTurns > 0;

  int get effectiveArmorClass =>
      (isObscured && !isIlluminatedByFlare) ? armorClass + obscuredAcMod : armorClass;

  bool isIntentOnCooldown(MonsterIntentId id) =>
      (intentCooldowns[id] ?? 0) > 0;

  void setIntentCooldown(MonsterIntentId id, int turns) {
    if (turns > 0) {
      intentCooldowns[id] = turns;
    }
  }

  void tickIntentCooldowns() {
    final keys = intentCooldowns.keys.toList();
    for (final k in keys) {
      final next = (intentCooldowns[k] ?? 0) - 1;
      if (next <= 0) {
        intentCooldowns.remove(k);
      } else {
        intentCooldowns[k] = next;
      }
    }
  }

  void tickSpotterFlare() {
    if (spotterFlareTurns > 0) {
      spotterFlareTurns--;
    }
  }

  void decrementChargeTimeOnWeapons() {
    for (final weapon in usableWeapons) {
      weapon.decrementChargeCountdown();
    }
  }
}
