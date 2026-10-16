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

/// Category and mounting requirements for a ship's deck hardpoints.
enum HardpointType {
  broadside('Broadside Battery'),
  prow('Prow Mount'),
  mortar('Mortar Emplacement'),
  utility('Utility Rigging'),
  auxiliary('Auxiliary Deck Mount');

  const HardpointType(this.displayName);
  final String displayName;
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'isSignature': isSignature,
      };

  factory HardpointSlot.fromJson(Map<String, dynamic> json) => HardpointSlot(
        id: json['id'] as String,
        name: json['name'] as String,
        type: HardpointType.values.byName(json['type'] as String),
        isSignature: json['isSignature'] as bool? ?? false,
      );
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
  final int baseCargo;
  final int baseDamageReduction;

  final List<HardpointSlot> hardpoints;
  final String? signatureWeaponId;

  /// Default baseline blueprint unlocked from the start of the family bloodline.
  static const BlueprintId defaultStartingBlueprint = BlueprintId.standard;

  /// Full catalog of all ancestral blueprints.
  static final Map<BlueprintId, FlagshipBlueprint> catalog = {
    // 1. STANDARD BARQUE (Default Starting Hull)
    BlueprintId.standard: FlagshipBlueprint(
      id: BlueprintId.standard,
      name: BlueprintLore.standard.name,
      subtitle: BlueprintLore.standard.subtitle,
      description: BlueprintLore.standard.description,
      tacticalRole: BlueprintLore.standard.tacticalRole,
      unlockCost: MetaCost(), // Free by default
      baseHp: 90,
      baseEvasion: 10,
      baseArmorClass: 10,
      baseCargo: 15,
      baseDamageReduction: 0,
      hardpoints: [
        HardpointSlot(id: 'broadside_port', name: 'Port Battery', type: HardpointType.broadside),
        HardpointSlot(id: 'broadside_starboard', name: 'Starboard Battery', type: HardpointType.broadside),
        HardpointSlot(id: 'auxiliary_deck', name: 'Auxiliary Mount', type: HardpointType.auxiliary),
      ],
      signatureWeaponId: null,
    ),

    // 2. IRONCLAD (Defensive Battering Juggernaut - Tier 1 Unlock)
    BlueprintId.ironclad: FlagshipBlueprint(
      id: BlueprintId.ironclad,
      name: BlueprintLore.ironclad.name,
      subtitle: BlueprintLore.ironclad.subtitle,
      description: BlueprintLore.ironclad.description,
      tacticalRole: BlueprintLore.ironclad.tacticalRole,
      unlockCost: MetaCost(seaGlass: 15, monsterBone: 10),
      baseHp: 110,
      baseEvasion: 0,
      baseArmorClass: 14,
      baseCargo: 10,
      baseDamageReduction: 3,
      hardpoints: [
        HardpointSlot(id: 'prow_ram', name: 'Reinforced Prow', type: HardpointType.prow, isSignature: true),
        HardpointSlot(id: 'broadside_battery', name: 'Plated Broadside', type: HardpointType.broadside),
        HardpointSlot(id: 'auxiliary_deck', name: 'Auxiliary Mount', type: HardpointType.auxiliary),
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
      unlockCost: MetaCost(seaGlass: 15, monsterBone: 10),
      baseHp: 75,
      baseEvasion: 25,
      baseArmorClass: 8,
      baseCargo: 12,
      baseDamageReduction: 0,
      hardpoints: [
        HardpointSlot(id: 'prow_chaser', name: 'Precision Chaser', type: HardpointType.prow, isSignature: true),
        HardpointSlot(id: 'broadside_swivel', name: 'Swivel Broadside', type: HardpointType.broadside),
        HardpointSlot(id: 'auxiliary_deck', name: 'Auxiliary Mount', type: HardpointType.auxiliary),
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
      unlockCost: MetaCost(depthWroughtIron: 8, abyssalBarnacles: 6),
      baseHp: 95,
      baseEvasion: 5,
      baseArmorClass: 10,
      baseCargo: 14,
      baseDamageReduction: 0,
      hardpoints: [
        HardpointSlot(id: 'mortar_deck', name: 'Mortar Emplacement', type: HardpointType.mortar, isSignature: true),
        HardpointSlot(id: 'broadside_port', name: 'Port Broadside', type: HardpointType.broadside),
        HardpointSlot(id: 'broadside_starboard', name: 'Starboard Broadside', type: HardpointType.broadside),
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
      unlockCost: MetaCost(depthWroughtIron: 8, abyssalBarnacles: 6),
      baseHp: 85,
      baseEvasion: 15,
      baseArmorClass: 10,
      baseCargo: 25,
      baseDamageReduction: 0,
      hardpoints: [
        HardpointSlot(id: 'utility_rig', name: 'Utility Rigging', type: HardpointType.utility, isSignature: true),
        HardpointSlot(id: 'broadside_deck', name: 'Deck Battery', type: HardpointType.broadside),
        HardpointSlot(id: 'auxiliary_deck', name: 'Auxiliary Mount', type: HardpointType.auxiliary),
      ],
      signatureWeaponId: 'harpoon_winch',
    ),
  };
}
