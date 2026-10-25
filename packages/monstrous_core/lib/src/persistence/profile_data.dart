import '../model/covenant_of_the_deep.dart';
import '../model/flagship_blueprint.dart';
import '../model/meta_inventory.dart';
import '../model/nemesis.dart';
import '../rules/lineage.dart';

/// Represents the player's persistent account profile.
///
/// This data is preserved across all runs and saved to disk.
/// It tracks generational meta-currencies, unlocked equipment blueprints,
/// lineage history, port town improvements, covenant pacts, and the current nemesis.
class ProfileData {
  ProfileData({
    MetaInventory? metaInventory,
    LineageTracker? lineageTracker,
    NemesisRecord? activeNemesis,
    Set<String>? unlockedBlueprints,
    this.activeBlueprintId = 'standard',
    this.hasBegunFirstVoyage = false,
    Map<String, int>? portCivicLevels,
    int? covenantHeat,
    this.hasUnlockedCovenant = false,
    this.hasShatteredFont = false,
    this.ascensionLoopCount = 0,
    Set<CovenantPactId>? activePacts,
    Map<String, int>? blueprintArmamentTiers,
    this.hasExpandedAuxiliarySlot = false,
    Set<String>? unlockedEldritchRelics,
    Set<String>? activeEldritchRelics,
  }) : _activeNemesis = activeNemesis?.species.isRegionTitan == false
           ? activeNemesis
           : null,
       metaInventory = metaInventory ?? MetaInventory(),
       lineageTracker = lineageTracker ?? LineageTracker(),
       unlockedBlueprints =
           unlockedBlueprints ?? <String>{BlueprintId.standard.name},
       portCivicLevels = portCivicLevels ?? <String, int>{},
       activePacts = activePacts ?? <CovenantPactId>{},
       blueprintArmamentTiers = blueprintArmamentTiers ?? <String, int>{},
       unlockedEldritchRelics = unlockedEldritchRelics ?? <String>{},
       activeEldritchRelics = activeEldritchRelics ?? <String>{},
       _legacyHeatOverride = covenantHeat {
    // Ensure standard blueprint is always unlocked
    this.unlockedBlueprints.add(BlueprintId.standard.name);
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final metaJson = json['metaInventory'] as Map<String, dynamic>?;
    final lineageJson = json['lineageTracker'] as Map<String, dynamic>?;
    final nemesisJson = json['activeNemesis'] as Map<String, dynamic>?;

    final blueprintsList = json['unlockedBlueprints'] as List<dynamic>?;
    final activeBp = json['activeBlueprintId'] as String? ?? 'standard';
    final civicMap = json['portCivicLevels'] as Map<String, dynamic>?;
    final pactsList = json['activePacts'] as List<dynamic>?;
    final armamentMap = json['blueprintArmamentTiers'] as Map<String, dynamic>?;
    final unlockedRelicsList = json['unlockedEldritchRelics'] as List<dynamic>?;
    final activeRelicsList = json['activeEldritchRelics'] as List<dynamic>?;

    final parsedPacts = <CovenantPactId>{};
    if (pactsList != null) {
      for (final raw in pactsList) {
        final name = raw.toString();
        final match = CovenantPactId.values
            .where((p) => p.name == name)
            .firstOrNull;
        if (match != null) {
          parsedPacts.add(match);
        }
      }
    }

    return ProfileData(
      metaInventory: metaJson != null
          ? MetaInventory.fromJson(metaJson)
          : MetaInventory(),
      lineageTracker: lineageJson != null
          ? LineageTracker.fromJson(lineageJson)
          : LineageTracker(),
      activeNemesis: nemesisJson != null
          ? NemesisRecord.fromJson(nemesisJson)
          : null,
      unlockedBlueprints: blueprintsList != null
          ? blueprintsList.map((e) => e.toString()).toSet()
          : <String>{BlueprintId.standard.name},
      activeBlueprintId: activeBp,
      // Legacy profiles with earned progress belong to returning captains.
      hasBegunFirstVoyage:
          json['hasBegunFirstVoyage'] as bool? ??
          ((lineageJson?['history'] is List &&
                  (lineageJson!['history'] as List).isNotEmpty) ||
              (blueprintsList?.any((id) => id != 'standard') ?? false) ||
              (metaJson?.values.any((value) => value is num && value > 0) ??
                  false) ||
              (civicMap?.isNotEmpty ?? false) ||
              (armamentMap?.isNotEmpty ?? false) ||
              (unlockedRelicsList?.isNotEmpty ?? false) ||
              activeBp != 'standard' ||
              json['hasExpandedAuxiliarySlot'] == true ||
              json['hasUnlockedCovenant'] == true ||
              json['hasShatteredFont'] == true ||
              nemesisJson != null),
      portCivicLevels: civicMap != null
          ? civicMap.map((k, v) => MapEntry(k, v as int))
          : <String, int>{},
      covenantHeat: json['covenantHeat'] as int?,
      hasUnlockedCovenant: json['hasUnlockedCovenant'] as bool? ?? false,
      hasShatteredFont: json['hasShatteredFont'] as bool? ?? false,
      ascensionLoopCount: json['ascensionLoopCount'] as int? ?? 0,
      activePacts: parsedPacts,
      blueprintArmamentTiers: armamentMap != null
          ? armamentMap.map((k, v) => MapEntry(k, v as int))
          : <String, int>{},
      hasExpandedAuxiliarySlot:
          json['hasExpandedAuxiliarySlot'] as bool? ?? false,
      unlockedEldritchRelics: unlockedRelicsList != null
          ? unlockedRelicsList.map((e) => e.toString()).toSet()
          : <String>{},
      activeEldritchRelics: activeRelicsList != null
          ? activeRelicsList.map((e) => e.toString()).toSet()
          : <String>{},
    );
  }

  final MetaInventory metaInventory;
  final LineageTracker lineageTracker;
  NemesisRecord? _activeNemesis;

  /// Older saves can contain Titan records. Retain the death ledger, but never
  /// revive those records as future encounters or Vendetta targets.
  NemesisRecord? get activeNemesis => _activeNemesis;
  set activeNemesis(NemesisRecord? value) {
    _activeNemesis = value?.species.isRegionTitan == false ? value : null;
  }

  final Set<String> unlockedBlueprints;
  String activeBlueprintId;
  bool hasBegunFirstVoyage;
  final Map<String, int> portCivicLevels;

  bool hasUnlockedCovenant;
  bool hasShatteredFont;
  int ascensionLoopCount;
  final Set<CovenantPactId> activePacts;
  final Map<String, int> blueprintArmamentTiers;
  bool hasExpandedAuxiliarySlot;
  final Set<String> unlockedEldritchRelics;
  final Set<String> activeEldritchRelics;

  int? _legacyHeatOverride;

  /// Total Pact Burden calculated from all active [CovenantPact]s.
  int get totalPactBurden {
    if (activePacts.isNotEmpty) {
      return activePacts.fold(
        0,
        (sum, id) => sum + (CovenantPact.catalog[id]?.burden ?? 0),
      );
    }
    return _legacyHeatOverride ?? 0;
  }

  /// Backward-compatible alias for [totalPactBurden].
  int get covenantHeat => totalPactBurden;
  set covenantHeat(int value) {
    _legacyHeatOverride = value;
  }

  bool isPactActive(CovenantPactId id) => activePacts.contains(id);

  void togglePact(CovenantPactId id) {
    _legacyHeatOverride = null;
    if (activePacts.contains(id)) {
      activePacts.remove(id);
    } else {
      activePacts.add(id);
    }
  }

  bool isBlueprintUnlocked(BlueprintId id) =>
      unlockedBlueprints.contains(id.name);

  bool canUnlockBlueprint(BlueprintId id) {
    if (isBlueprintUnlocked(id)) return false;
    final bp = FlagshipBlueprint.catalog[id];
    if (bp == null) return false;
    return metaInventory.canAffordCost(bp.unlockCost);
  }

  bool unlockBlueprint(BlueprintId id) {
    if (!canUnlockBlueprint(id)) return false;
    final bp = FlagshipBlueprint.catalog[id]!;
    if (metaInventory.spendCost(bp.unlockCost)) {
      unlockedBlueprints.add(id.name);
      return true;
    }
    return false;
  }

  /// Returns the current signature armament tier (1..3) for [id].
  int armamentTierFor(BlueprintId id) => (blueprintArmamentTiers[id.name] ?? 1)
      .clamp(1, BlueprintArmamentProgression.maxTier);

  bool canUpgradeBlueprintArmament(BlueprintId id) {
    if (!isBlueprintUnlocked(id)) return false;
    final currentTier = armamentTierFor(id);
    final nextCost = BlueprintArmamentProgression.costForNextTier(currentTier);
    if (nextCost == null) return false;
    return metaInventory.canAffordCost(nextCost);
  }

  bool upgradeBlueprintArmament(BlueprintId id) {
    if (!canUpgradeBlueprintArmament(id)) return false;
    final currentTier = armamentTierFor(id);
    final nextCost = BlueprintArmamentProgression.costForNextTier(currentTier)!;
    if (metaInventory.spendCost(nextCost)) {
      blueprintArmamentTiers[id.name] = currentTier + 1;
      return true;
    }
    return false;
  }

  bool canUnlockAuxiliaryExpansion() {
    if (hasExpandedAuxiliarySlot) return false;
    return metaInventory.canAffordCost(
      BlueprintArmamentProgression.auxiliaryExpansionCost,
    );
  }

  bool unlockAuxiliaryExpansion() {
    if (!canUnlockAuxiliaryExpansion()) return false;
    if (metaInventory.spendCost(
      BlueprintArmamentProgression.auxiliaryExpansionCost,
    )) {
      hasExpandedAuxiliarySlot = true;
      return true;
    }
    return false;
  }

  bool isEldritchRelicUnlocked(EldritchRelicId id) =>
      unlockedEldritchRelics.contains(id.name);

  bool isEldritchRelicActive(EldritchRelicId id) =>
      activeEldritchRelics.contains(id.name);

  bool canUnlockEldritchRelic(EldritchRelicId id) {
    if (!hasUnlockedCovenant) return false;
    if (isEldritchRelicUnlocked(id)) return false;
    final def = EldritchRelicDef.catalog[id];
    if (def == null) return false;
    if (!isBlueprintUnlocked(def.blueprintId)) return false;
    return metaInventory.canAffordCost(def.unlockCost);
  }

  bool unlockEldritchRelic(EldritchRelicId id) {
    if (!canUnlockEldritchRelic(id)) return false;
    final def = EldritchRelicDef.catalog[id]!;
    if (metaInventory.spendCost(def.unlockCost)) {
      unlockedEldritchRelics.add(id.name);
      activeEldritchRelics.add(id.name);
      return true;
    }
    return false;
  }

  int monumentRank(HarborMonumentId id) => portCivicLevels[id.name] ?? 0;

  bool canUpgradeMonument(HarborMonumentId id) {
    if (!hasUnlockedCovenant) return false;
    final def = HarborMonumentDef.catalog[id];
    if (def == null) return false;
    final nextRank = monumentRank(id) + 1;
    return metaInventory.canAffordCost(def.costForRank(nextRank));
  }

  bool upgradeMonument(HarborMonumentId id) {
    if (!canUpgradeMonument(id)) return false;
    final def = HarborMonumentDef.catalog[id]!;
    final nextRank = monumentRank(id) + 1;
    if (metaInventory.spendCost(def.costForRank(nextRank))) {
      portCivicLevels[id.name] = nextRank;
      return true;
    }
    return false;
  }

  /// Total bonus Max HP granted by the Obsidian Tide-Obelisk monument.
  int get monumentBonusMaxHp =>
      monumentRank(HarborMonumentId.obsidianObelisk) * 5;

  /// Multiplier for Monster Bounty Gold granted by the Idol of the Coiled Deep.
  double get monumentBountyGoldMultiplier =>
      1.0 + (monumentRank(HarborMonumentId.serpentEffigy) * 0.10);

  /// Multiplier for Weapon Damage granted by the Brazier of the Eternal Rim.
  double get monumentWeaponDamageMultiplier =>
      1.0 + (monumentRank(HarborMonumentId.calderaBrazier) * 0.05);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'metaInventory': metaInventory.toJson(),
    'lineageTracker': lineageTracker.toJson(),
    'activeNemesis': activeNemesis?.toJson(),
    'unlockedBlueprints': unlockedBlueprints.toList(),
    'activeBlueprintId': activeBlueprintId,
    'hasBegunFirstVoyage': hasBegunFirstVoyage,
    'portCivicLevels': portCivicLevels,
    'covenantHeat': totalPactBurden,
    'hasUnlockedCovenant': hasUnlockedCovenant,
    'hasShatteredFont': hasShatteredFont,
    'ascensionLoopCount': ascensionLoopCount,
    'activePacts': activePacts.map((p) => p.name).toList(),
    'blueprintArmamentTiers': blueprintArmamentTiers,
    'hasExpandedAuxiliarySlot': hasExpandedAuxiliarySlot,
    'unlockedEldritchRelics': unlockedEldritchRelics.toList(),
    'activeEldritchRelics': activeEldritchRelics.toList(),
  };
}
