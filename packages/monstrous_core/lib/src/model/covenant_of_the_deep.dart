import '../lore/eldritch_lore.dart';
import 'enums.dart';
import 'flagship_blueprint.dart';
import 'meta_inventory.dart';

/// The defining narrative and mechanical choice at the Primordial Caldera
/// after vanquishing The Ancient Leviathan in Region 3.
enum CalderaClimaxChoice {
  /// Detonates the Leviathan Core inside the Abyssal Font, destroying the
  /// primordial birthplace of monsters, curing the generational salt-sickness,
  /// and concluding the main narrative loop.
  shatterCore('Shatter the Core'),

  /// Retains the Leviathan Core. The captain is consumed by deep-sea madness,
  /// and the flagship returns to port with the Core fused into its keel—
  /// unlocking the Covenant of the Deep and the post-end eldritch loop.
  claimCore('Claim the Core');

  const CalderaClimaxChoice(this.displayName);
  final String displayName;
}

/// Identifiers for pacts ratified at the Abyssal Covenant Altar in Port.
///
/// Each active pact adds its [CovenantPact.burden] to the voyage's total
/// **Pact Burden**.
enum CovenantPactId {
  abyssalVigor,
  calcifiedCarapace,
  feedingFrenzy,
  chokingFog,
  brittleOak,
  volatileEnvirons,
  apexEmergence,
}

/// Definition of a single Covenant Pact modifier.
class CovenantPact {
  const CovenantPact({
    required this.id,
    required this.name,
    required this.burden,
    required this.flavor,
    required this.effectDescription,
  });

  final CovenantPactId id;
  final String name;

  /// The Pact Burden added when this pact is active (1 or 2).
  final int burden;
  final String flavor;
  final String effectDescription;

  static final Map<CovenantPactId, CovenantPact> catalog = {
    CovenantPactId.abyssalVigor: CovenantPact(
      id: CovenantPactId.abyssalVigor,
      name: EldritchLore.pacts[CovenantPactId.abyssalVigor]!.name,
      burden: 1,
      flavor: EldritchLore.pacts[CovenantPactId.abyssalVigor]!.flavor,
      effectDescription: EldritchLore.pacts[CovenantPactId.abyssalVigor]!.effectDescription,
    ),
    CovenantPactId.calcifiedCarapace: CovenantPact(
      id: CovenantPactId.calcifiedCarapace,
      name: EldritchLore.pacts[CovenantPactId.calcifiedCarapace]!.name,
      burden: 1,
      flavor: EldritchLore.pacts[CovenantPactId.calcifiedCarapace]!.flavor,
      effectDescription: EldritchLore.pacts[CovenantPactId.calcifiedCarapace]!.effectDescription,
    ),
    CovenantPactId.feedingFrenzy: CovenantPact(
      id: CovenantPactId.feedingFrenzy,
      name: EldritchLore.pacts[CovenantPactId.feedingFrenzy]!.name,
      burden: 1,
      flavor: EldritchLore.pacts[CovenantPactId.feedingFrenzy]!.flavor,
      effectDescription: EldritchLore.pacts[CovenantPactId.feedingFrenzy]!.effectDescription,
    ),
    CovenantPactId.chokingFog: CovenantPact(
      id: CovenantPactId.chokingFog,
      name: EldritchLore.pacts[CovenantPactId.chokingFog]!.name,
      burden: 1,
      flavor: EldritchLore.pacts[CovenantPactId.chokingFog]!.flavor,
      effectDescription: EldritchLore.pacts[CovenantPactId.chokingFog]!.effectDescription,
    ),
    CovenantPactId.brittleOak: CovenantPact(
      id: CovenantPactId.brittleOak,
      name: EldritchLore.pacts[CovenantPactId.brittleOak]!.name,
      burden: 1,
      flavor: EldritchLore.pacts[CovenantPactId.brittleOak]!.flavor,
      effectDescription: EldritchLore.pacts[CovenantPactId.brittleOak]!.effectDescription,
    ),
    CovenantPactId.volatileEnvirons: CovenantPact(
      id: CovenantPactId.volatileEnvirons,
      name: EldritchLore.pacts[CovenantPactId.volatileEnvirons]!.name,
      burden: 2,
      flavor: EldritchLore.pacts[CovenantPactId.volatileEnvirons]!.flavor,
      effectDescription: EldritchLore.pacts[CovenantPactId.volatileEnvirons]!.effectDescription,
    ),
    CovenantPactId.apexEmergence: CovenantPact(
      id: CovenantPactId.apexEmergence,
      name: EldritchLore.pacts[CovenantPactId.apexEmergence]!.name,
      burden: 2,
      flavor: EldritchLore.pacts[CovenantPactId.apexEmergence]!.flavor,
      effectDescription: EldritchLore.pacts[CovenantPactId.apexEmergence]!.effectDescription,
    ),
  };
}

/// Pre-loop Titan Trophy progression: Blueprint Signature Armament Tiers &
/// Deck Reserve Auxiliary Expansion.
class BlueprintArmamentProgression {
  const BlueprintArmamentProgression._();

  static const int maxTier = 3;

  /// Cost to upgrade any Blueprint's signature armament from Tier I to Tier II.
  /// Designed as the "First Kraken Kill Power-Up Milestone" to prepare for Region 2.
  static const MetaCost tier2Cost = MetaCost(
    krakenBeak: 1,
    seaGlass: 10,
    monsterBone: 8,
  );

  /// Cost to upgrade any Blueprint's signature armament from Tier II to Tier III.
  /// Incorporates diminishing returns (2 Beaks + 1 Serpent Scale + rare materials).
  static const MetaCost tier3Cost = MetaCost(
    krakenBeak: 2,
    serpentScale: 1,
    depthWroughtIron: 8,
    abyssalBarnacles: 6,
  );

  /// Cost to reinforce the flagship's deck with an extra Auxiliary Hardpoint
  /// (+1 Reserve Aux Slot & +2 Max Weapon Weight) for mid-run weapon swapping.
  static const MetaCost auxiliaryExpansionCost = MetaCost(
    krakenBeak: 1,
    serpentScale: 1,
    depthWroughtIron: 10,
  );

  static MetaCost? costForNextTier(int currentTier) {
    if (currentTier == 1) return tier2Cost;
    if (currentTier == 2) return tier3Cost;
    return null;
  }

  /// Multiplier applied to signature weapon base damage for the given [tier].
  /// Tier 1 = 1.0x, Tier 2 = 1.25x, Tier 3 = 1.45x (diminishing return curve).
  static double damageMultiplierForTier(int tier) {
    if (tier <= 1) return 1.0;
    if (tier == 2) return 1.25;
    return 1.45;
  }
}

/// Post-loop Chapter 2: Transformative Eldritch Relic Weapons unlocked using
/// multiple Titan Trophies + Primordial Cinders after claiming the Core.
enum EldritchRelicId {
  siphonRam,
  ghostwakeCulverin,
  brimstoneMortar,
  sinewWinch,
}

class EldritchRelicDef {
  const EldritchRelicDef({
    required this.id,
    required this.name,
    required this.blueprintId,
    required this.weaponType,
    required this.unlockCost,
    required this.description,
    required this.effectSummary,
  });

  final EldritchRelicId id;
  final String name;
  final BlueprintId blueprintId;
  final ShipWeaponType weaponType;
  final MetaCost unlockCost;
  final String description;
  final String effectSummary;

  static final Map<EldritchRelicId, EldritchRelicDef> catalog = {
    EldritchRelicId.siphonRam: EldritchRelicDef(
      id: EldritchRelicId.siphonRam,
      name: EldritchLore.relics[EldritchRelicId.siphonRam]!.name,
      blueprintId: BlueprintId.ironclad,
      weaponType: ShipWeaponType.prowRam,
      unlockCost: const MetaCost(
        krakenBeak: 2,
        leviathanCore: 1,
        primordialCinders: 3,
      ),
      description: EldritchLore.relics[EldritchRelicId.siphonRam]!.description,
      effectSummary: EldritchLore.relics[EldritchRelicId.siphonRam]!.effectSummary,
    ),
    EldritchRelicId.ghostwakeCulverin: EldritchRelicDef(
      id: EldritchRelicId.ghostwakeCulverin,
      name: EldritchLore.relics[EldritchRelicId.ghostwakeCulverin]!.name,
      blueprintId: BlueprintId.clipper,
      weaponType: ShipWeaponType.precisionCulverin,
      unlockCost: const MetaCost(
        krakenBeak: 2,
        serpentScale: 1,
        primordialCinders: 3,
      ),
      description: EldritchLore.relics[EldritchRelicId.ghostwakeCulverin]!.description,
      effectSummary: EldritchLore.relics[EldritchRelicId.ghostwakeCulverin]!.effectSummary,
    ),
    EldritchRelicId.brimstoneMortar: EldritchRelicDef(
      id: EldritchRelicId.brimstoneMortar,
      name: EldritchLore.relics[EldritchRelicId.brimstoneMortar]!.name,
      blueprintId: BlueprintId.bombardier,
      weaponType: ShipWeaponType.heavyMortar,
      unlockCost: const MetaCost(
        serpentScale: 2,
        leviathanCore: 1,
        primordialCinders: 4,
      ),
      description: EldritchLore.relics[EldritchRelicId.brimstoneMortar]!.description,
      effectSummary: EldritchLore.relics[EldritchRelicId.brimstoneMortar]!.effectSummary,
    ),
    EldritchRelicId.sinewWinch: EldritchRelicDef(
      id: EldritchRelicId.sinewWinch,
      name: EldritchLore.relics[EldritchRelicId.sinewWinch]!.name,
      blueprintId: BlueprintId.corsair,
      weaponType: ShipWeaponType.harpoonWinch,
      unlockCost: const MetaCost(
        krakenBeak: 1,
        serpentScale: 1,
        leviathanCore: 1,
        primordialCinders: 4,
      ),
      description: EldritchLore.relics[EldritchRelicId.sinewWinch]!.description,
      effectSummary: EldritchLore.relics[EldritchRelicId.sinewWinch]!.effectSummary,
    ),
  };
}

/// Post-loop Chapter 3: Cursed Harbor Monuments for long-term loopers.
/// Escalating trophy & cinder sinks granting modest incremental bonuses.
enum HarborMonumentId {
  obsidianObelisk,
  serpentEffigy,
  calderaBrazier,
}

class HarborMonumentDef {
  const HarborMonumentDef({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.bonusPerRankDescription,
  });

  final HarborMonumentId id;
  final String name;
  final String subtitle;
  final String bonusPerRankDescription;

  /// Escalating cost for upgrading to [targetRank] (1-indexed).
  MetaCost costForRank(int targetRank) {
    final r = targetRank.clamp(1, 99);
    switch (id) {
      case HarborMonumentId.obsidianObelisk:
        return MetaCost(
          krakenBeak: r,
          primordialCinders: r,
          seaGlass: r * 5,
        );
      case HarborMonumentId.serpentEffigy:
        return MetaCost(
          serpentScale: r,
          primordialCinders: r,
          monsterBone: r * 5,
        );
      case HarborMonumentId.calderaBrazier:
        return MetaCost(
          leviathanCore: 1,
          primordialCinders: r * 2,
          depthWroughtIron: r * 4,
        );
    }
  }

  static final Map<HarborMonumentId, HarborMonumentDef> catalog = {
    HarborMonumentId.obsidianObelisk: HarborMonumentDef(
      id: HarborMonumentId.obsidianObelisk,
      name: EldritchLore.monuments[HarborMonumentId.obsidianObelisk]!.name,
      subtitle: EldritchLore.monuments[HarborMonumentId.obsidianObelisk]!.subtitle,
      bonusPerRankDescription:
          EldritchLore.monuments[HarborMonumentId.obsidianObelisk]!.bonusPerRankDescription,
    ),
    HarborMonumentId.serpentEffigy: HarborMonumentDef(
      id: HarborMonumentId.serpentEffigy,
      name: EldritchLore.monuments[HarborMonumentId.serpentEffigy]!.name,
      subtitle: EldritchLore.monuments[HarborMonumentId.serpentEffigy]!.subtitle,
      bonusPerRankDescription:
          EldritchLore.monuments[HarborMonumentId.serpentEffigy]!.bonusPerRankDescription,
    ),
    HarborMonumentId.calderaBrazier: HarborMonumentDef(
      id: HarborMonumentId.calderaBrazier,
      name: EldritchLore.monuments[HarborMonumentId.calderaBrazier]!.name,
      subtitle: EldritchLore.monuments[HarborMonumentId.calderaBrazier]!.subtitle,
      bonusPerRankDescription:
          EldritchLore.monuments[HarborMonumentId.calderaBrazier]!.bonusPerRankDescription,
    ),
  };
}
