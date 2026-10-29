import '../lore/blueprint_lore.dart';
import 'enums.dart';
import 'meta_inventory.dart';

/// Identifier for ancestral flagship blueprints.
enum BlueprintId {
  standard('Blueprint: Standard'),
  ironclad('Blueprint: Ironclad'),
  clipper('Blueprint: Clipper'),
  bombardier('Blueprint: Bombardier'),
  corsair('Blueprint: Corsair');

  const BlueprintId(this.displayName);
  final String displayName;

  ShipClass get shipClass => switch (this) {
        BlueprintId.standard => ShipClass.standard,
        BlueprintId.ironclad => ShipClass.ironclad,
        BlueprintId.clipper => ShipClass.clipper,
        BlueprintId.bombardier => ShipClass.bombardier,
        BlueprintId.corsair => ShipClass.corsair,
      };

  static BlueprintId fromShipClass(ShipClass shipClass) =>
      shipClass.blueprintId;

  /// Hull-specific Broadside hardpoint weapon type (0T cooldown).
  ShipWeaponType get broadsideWeaponType => switch (this) {
        BlueprintId.standard => ShipWeaponType.cannon,
        BlueprintId.ironclad => ShipWeaponType.heavyCarronade,
        BlueprintId.clipper => ShipWeaponType.swivelGun,
        BlueprintId.bombardier => ShipWeaponType.shrapnelHowitzer,
        BlueprintId.corsair => ShipWeaponType.chainShotBroadside,
      };

  /// Hull-specific Signature hardpoint weapon type (1T cooldown).
  ShipWeaponType get signatureWeaponType => switch (this) {
        BlueprintId.standard => ShipWeaponType.twinChasers,
        BlueprintId.ironclad => ShipWeaponType.prowRam,
        BlueprintId.clipper => ShipWeaponType.precisionCulverin,
        BlueprintId.bombardier => ShipWeaponType.heavyMortar,
        BlueprintId.corsair => ShipWeaponType.harpoonWinch,
      };

  /// Hull-specific Utility hardpoint mechanism (2T cooldown).
  UtilityHardpointId get utilityHardpoint => switch (this) {
        BlueprintId.standard => UtilityHardpointId.gunneryDrill,
        BlueprintId.ironclad => UtilityHardpointId.fortifyPlates,
        BlueprintId.clipper => UtilityHardpointId.evasiveRigging,
        BlueprintId.bombardier => UtilityHardpointId.spotterFlare,
        BlueprintId.corsair => UtilityHardpointId.driftingTetherTrap,
      };
}

extension ShipClassBlueprintExtension on ShipClass {
  BlueprintId get blueprintId => switch (this) {
        ShipClass.standard => BlueprintId.standard,
        ShipClass.ironclad => BlueprintId.ironclad,
        ShipClass.corvette || ShipClass.clipper => BlueprintId.clipper,
        ShipClass.freighter || ShipClass.corsair => BlueprintId.corsair,
        ShipClass.bombardier => BlueprintId.bombardier,
      };
}

/// Category for a ship's 3 intrinsic deck hardpoints (Broadside, Signature, Utility).
enum HardpointType {
  broadside('Broadside Battery'),
  signature('Signature Armament'),
  utility('Utility Rigging'),
  // Legacy aliases retained for save migration compatibility
  prow('Prow Mount'),
  mortar('Mortar Emplacement'),
  auxiliary('Auxiliary Deck Mount');

  const HardpointType(this.displayName);
  final String displayName;

  /// Normalizes legacy hardpoint types to the canonical 3-pillar hardpoint types.
  HardpointType get canonical => switch (this) {
        HardpointType.broadside || HardpointType.auxiliary =>
          HardpointType.broadside,
        HardpointType.signature ||
        HardpointType.prow ||
        HardpointType.mortar =>
          HardpointType.signature,
        HardpointType.utility => HardpointType.utility,
      };
}

/// Specification for a single hardpoint mount upon the Ancestral Flagship.
class HardpointSlot {
  const HardpointSlot({
    required this.id,
    required this.name,
    required this.type,
    this.isSignature = false,
  });

  final String id;
  final String name;
  final HardpointType type;
  final bool isSignature;

  /// Current player-facing label, without rewriting names stored in older saves.
  String get displayName => id == 'utility_drill'
      ? UtilityHardpointId.gunneryDrill.displayName
      : name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'isSignature': isSignature,
      };

  factory HardpointSlot.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'broadside';
    final parsedType = HardpointType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => HardpointType.broadside,
    );
    return HardpointSlot(
      id: json['id'] as String? ?? 'broadside',
      name: json['name'] as String? ?? parsedType.displayName,
      type: parsedType,
      isSignature: json['isSignature'] as bool? ?? false,
    );
  }
}

/// An ancestral naval engineering blueprint defining a specialized refit of the Flagship.
class FlagshipBlueprint {
  const FlagshipBlueprint({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.tacticalRole,
    required this.unlockCost,
    required this.baseHp,
    required this.baseEvasion,
    required this.baseArmorClass,
    required this.baseCargo,
    required this.baseDamageReduction,
    required this.hardpoints,
    required this.signatureWeaponId,
  });

  final BlueprintId id;
  final String name;
  final String subtitle;
  final String description;
  final String tacticalRole;
  final MetaCost unlockCost;

  final int baseHp;
  final int baseEvasion;
  final int baseArmorClass;

  /// Tactical Consumable Belt slot capacity (3 baseline, 4 for Corsair).
  final int baseCargo;
  final int baseDamageReduction;

  final List<HardpointSlot> hardpoints;
  final String? signatureWeaponId;

  /// Default baseline blueprint unlocked from the start of the family bloodline.
  static const BlueprintId defaultStartingBlueprint = BlueprintId.standard;

  /// Full catalog of all ancestral blueprints, each mounting strictly 3 intrinsic hardpoints:
  /// 1. Broadside (0T CD)
  /// 2. Signature (1T CD)
  /// 3. Utility (2T CD)
  static final Map<BlueprintId, FlagshipBlueprint> catalog = {
    // 1. STANDARD BARQUE (Default Starting Hull)
    BlueprintId.standard: FlagshipBlueprint(
      id: BlueprintId.standard,
      name: BlueprintLore.standard.name,
      subtitle: BlueprintLore.standard.subtitle,
      description: BlueprintLore.standard.description,
      tacticalRole: BlueprintLore.standard.tacticalRole,
      unlockCost: const MetaCost(), // Free by default
      baseHp: 90,
      baseEvasion: 10,
      baseArmorClass: 10,
      baseCargo: 3,
      baseDamageReduction: 0,
      hardpoints: const [
        HardpointSlot(
          id: 'broadside_cannon',
          name: 'Naval Cannon Battery',
          type: HardpointType.broadside,
        ),
        HardpointSlot(
          id: 'signature_chasers',
          name: 'Twin Chaser Cannons',
          type: HardpointType.signature,
          isSignature: true,
        ),
        HardpointSlot(
          id: 'utility_drill',
          name: 'Gun-Deck Bracing',
          type: HardpointType.utility,
        ),
      ],
      signatureWeaponId: 'twin_chasers',
    ),

    // 2. IRONCLAD (Defensive Battering Juggernaut - Tier 1 Unlock)
    BlueprintId.ironclad: FlagshipBlueprint(
      id: BlueprintId.ironclad,
      name: BlueprintLore.ironclad.name,
      subtitle: BlueprintLore.ironclad.subtitle,
      description: BlueprintLore.ironclad.description,
      tacticalRole: BlueprintLore.ironclad.tacticalRole,
      unlockCost: const MetaCost(seaGlass: 15, monsterBone: 10),
      baseHp: 110,
      baseEvasion: 0,
      baseArmorClass: 14,
      baseCargo: 3,
      baseDamageReduction: 3,
      hardpoints: const [
        HardpointSlot(
          id: 'broadside_carronades',
          name: 'Heavy Carronades',
          type: HardpointType.broadside,
        ),
        HardpointSlot(
          id: 'prow_ram',
          name: 'Reinforced Prow Ram',
          type: HardpointType.signature,
          isSignature: true,
        ),
        HardpointSlot(
          id: 'utility_fortify',
          name: 'Fortify Iron Plates',
          type: HardpointType.utility,
        ),
      ],
      signatureWeaponId: 'prow_ram',
    ),

    // 3. CLIPPER (High Speed, Critical Evasion Skiff - Tier 1 Unlock)
    BlueprintId.clipper: FlagshipBlueprint(
      id: BlueprintId.clipper,
      name: BlueprintLore.clipper.name,
      subtitle: BlueprintLore.clipper.subtitle,
      description: BlueprintLore.clipper.description,
      tacticalRole: BlueprintLore.clipper.tacticalRole,
      unlockCost: const MetaCost(seaGlass: 15, monsterBone: 10),
      baseHp: 75,
      baseEvasion: 25,
      baseArmorClass: 8,
      baseCargo: 3,
      baseDamageReduction: 0,
      hardpoints: const [
        HardpointSlot(
          id: 'broadside_swivel',
          name: 'Long-Barrel Swivel Guns',
          type: HardpointType.broadside,
        ),
        HardpointSlot(
          id: 'prow_chaser',
          name: 'Precision Culverin',
          type: HardpointType.signature,
          isSignature: true,
        ),
        HardpointSlot(
          id: 'utility_evasive',
          name: 'Evasive Rigging',
          type: HardpointType.utility,
        ),
      ],
      signatureWeaponId: 'precision_culverin',
    ),

    // 4. BOMBARDIER (High-Angle Siege Artillery - Tier 2 Unlock)
    BlueprintId.bombardier: FlagshipBlueprint(
      id: BlueprintId.bombardier,
      name: BlueprintLore.bombardier.name,
      subtitle: BlueprintLore.bombardier.subtitle,
      description: BlueprintLore.bombardier.description,
      tacticalRole: BlueprintLore.bombardier.tacticalRole,
      unlockCost: const MetaCost(depthWroughtIron: 8, abyssalBarnacles: 6),
      baseHp: 95,
      baseEvasion: 5,
      baseArmorClass: 10,
      baseCargo: 3,
      baseDamageReduction: 0,
      hardpoints: const [
        HardpointSlot(
          id: 'broadside_howitzers',
          name: 'Shrapnel Howitzers',
          type: HardpointType.broadside,
        ),
        HardpointSlot(
          id: 'mortar_deck',
          name: 'Heavy Siege Mortar',
          type: HardpointType.signature,
          isSignature: true,
        ),
        HardpointSlot(
          id: 'utility_flare',
          name: 'Phosphor Spotter Flare',
          type: HardpointType.utility,
        ),
      ],
      signatureWeaponId: 'heavy_mortar',
    ),

    // 5. CORSAIR (Tactical Harpoons, Traps & Siphons - Tier 2 Unlock)
    BlueprintId.corsair: FlagshipBlueprint(
      id: BlueprintId.corsair,
      name: BlueprintLore.corsair.name,
      subtitle: BlueprintLore.corsair.subtitle,
      description: BlueprintLore.corsair.description,
      tacticalRole: BlueprintLore.corsair.tacticalRole,
      unlockCost: const MetaCost(depthWroughtIron: 8, abyssalBarnacles: 6),
      baseHp: 85,
      baseEvasion: 15,
      baseArmorClass: 10,
      baseCargo: 4,
      baseDamageReduction: 0,
      hardpoints: const [
        HardpointSlot(
          id: 'broadside_chainshot',
          name: 'Chain-Shot Broadside',
          type: HardpointType.broadside,
        ),
        HardpointSlot(
          id: 'signature_harpoon',
          name: 'Harpoon Winch',
          type: HardpointType.signature,
          isSignature: true,
        ),
        HardpointSlot(
          id: 'utility_trap',
          name: 'Drifting Tether-Trap',
          type: HardpointType.utility,
        ),
      ],
      signatureWeaponId: 'harpoon_winch',
    ),
  };
}
