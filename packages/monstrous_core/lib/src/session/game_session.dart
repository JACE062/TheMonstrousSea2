import 'dart:math';

import '../config/balance_config.dart';
import '../content/consumables.dart';
import '../content/ships.dart';
import '../model/bloodline_trait.dart';
import '../model/combatant.dart';
import '../model/covenant_of_the_deep.dart';
import '../model/enums.dart';
import '../model/flagship_blueprint.dart';
import '../model/item.dart';
import '../model/monster_intent.dart';
import '../model/nemesis.dart';
import '../model/ocean_power.dart';
import '../persistence/profile_data.dart';
import '../rng/game_rng.dart';
import '../rules/combat.dart';
import '../rules/economy.dart';
import '../rules/lineage.dart';
import '../rules/loot.dart';
import '../rules/monster_ai.dart';
import '../rules/sea_chart.dart';
import '../rules/shrine.dart';
import '../traits/trait.dart';
import 'commands.dart';
import 'events.dart';
import 'session_phase.dart';

/// Central state machine and session orchestrator for The Monstrous Sea.
///
/// Drives the complete game loop from captain creation, naval combat,
/// spoils distribution, port economy, and multi-generational lineage.
class GameSession {
  GameSession({
    GameRng? rng,
    this.config = BalanceConfig.standard,
    ProfileData? profile,
  })  : rng = rng ?? SeededGameRng(),
        seaChart = SeaChart(rng: rng ?? SeededGameRng()),
        profile = profile ?? ProfileData();

  final GameRng rng;
  final BalanceConfig config;
  final SeaChart seaChart;
  ProfileData profile;
  LineageTracker get lineage => profile.lineageTracker;

  List<HeirCandidate> pendingHeirCandidates = <HeirCandidate>[];
  BloodlineTrait? activeBoon;
  BloodlineTrait? activeQuirk;
  bool isNemesisBattle = false;
  SessionPhase merchantReturnPhase = SessionPhase.port;

  SessionPhase phase = SessionPhase.captainCreation;
  String captainName = '';
  ShipState? ship;
  MonsterState? currentMonster;
  /// Persists a completed encounter without retaining a live combat object.
  bool hasDefeatedCurrentEncounter = false;
  CombatRange combatRange = CombatRange.medium;
  HelmOrder lastHelmOrderThisTurn = HelmOrder.holdLine;
  bool _disruptedBossCatastropheThisTurn = false;
  bool _purgedFrenzyThisTurn = false;
  bool usedQuickConsumableThisTurn = false;
  int quickConsumablesUsedThisTurn = 0;
  List<Item> pendingLoot = <Item>[];
  List<Item> merchantStock = <Item>[];
  int? onSaleMerchantIndex;
  int lastGoldSalvaged = 0;

  /// Whether the player can still trigger a 0-turn-cost Quick Action consumable this round.
  bool get canUseQuickConsumableThisTurn =>
      phase == SessionPhase.battle && !usedQuickConsumableThisTurn;

  bool hasCareenedAtCurrentIsland = false;
  bool hasDrilledAtCurrentIsland = false;
  bool hasForagedAtCurrentIsland = false;

  /// Whether the ship is currently anchored at the grand guaranteed Midpoint Haven
  /// (as opposed to a procedural emergency secluded cove).
  bool get isCurrentIslandHaven =>
      phase == SessionPhase.respiteIsland &&
      seaChart.currentLeg == seaChart.midpointHavenLeg;

  bool get canUseVoyageShipwright =>
      phase == SessionPhase.stronghold || isCurrentIslandHaven;

  void _requireHomePort() {
    if (phase != SessionPhase.port) {
      throw StateError('Permanent progression is only available at the home port');
    }
  }

  /// Whether the crew has already spent their single shore duty at this island haven.
  bool get hasChosenIslandDuty =>
      hasCareenedAtCurrentIsland ||
      hasDrilledAtCurrentIsland ||
      hasForagedAtCurrentIsland;

  int gunneryAccuracyBoon = 0;

  /// Runic guidance is retained for every volley of the next combat.
  int runicGuidanceBoon = 0;
  String currentIslandName = '';
  String currentShipwreckName = '';
  bool hasSalvagedCurrentWreck = false;

  String currentSmugglerName = '';
  List<Item> smugglerStock = <Item>[];
  String currentShrineName = '';
  String currentShrineLore = '';
  bool hasCommunedAtCurrentShrine = false;
  List<OceanPower> shrineManifestedPowers = const [];

  bool get canEmergencyRepairAtSea =>
      ship != null && ship!.currentHp < (ship!.maxHp * 0.25).ceil();

  int get emergencyRepairCost => ship != null
      ? max(0, ((ship!.maxHp * 0.25).ceil() - ship!.currentHp) * 2)
      : 0;

  bool get isRegionBossEncounter =>
      currentMonster != null && (seaChart.isRegionTitan);

  bool get isExpeditionWon => phase == SessionPhase.expeditionVictory;

  int monstersDefeatedThisLife = 0;
  int highestDifficultyThisLife = 0;
  int battleRound = 0;

  /// Returns the current asking price for the item at [stockIndex] in the shop.
  int getMerchantAskingPrice(int stockIndex) {
    if (stockIndex < 0 || stockIndex >= merchantStock.length) return 0;
    return getMerchantBuyPrice(
      merchantStock[stockIndex],
      isOnSale: stockIndex == onSaleMerchantIndex,
    );
  }

  /// Refreshes the merchant's wares and randomly designates one item as on-sale.
  void refreshMerchantStock([int? difficulty]) {
    final diff = difficulty ?? highestDifficultyThisLife;
    merchantStock = generateMerchantStock(max(1, diff), rng);
    onSaleMerchantIndex =
        merchantStock.isNotEmpty ? rng.nextInt(merchantStock.length) : null;
  }

  final List<CombatTrait> traits = const <CombatTrait>[
    FortifyTrait(),
    EvasionTrait(),
    InkCloudTrait(),
    TentacleTrait(),
    CarapaceTrait(),
    SharkFrenzyTrait(),
    SerpentSlitherTrait(),
  ];

  /// Dispatches [command] to update session state and returns resulting events.
  List<GameEvent> dispatch(Command command) {
    return switch (command) {
      NameCaptain(:final name) => _handleNameCaptain(name),
      ChooseShip(:final shipClass, :final customName) =>
        _handleChooseShip(shipClass, customName),
      BeginFirstVoyage(:final captainName, :final customShipName) =>
        _handleBeginFirstVoyage(captainName, customShipName),
      VentureOutToSea(:final startingRow) =>
        _handleVentureOutToSea(startingRow),
      FireWeaponVolley(:final weaponType) =>
        _handleFireWeaponVolley(weaponType),
      IssueHelmOrder(:final order) =>
        _handleIssueHelmOrder(order),
      ChangeCombatRange(:final targetRange) =>
        _handleChangeCombatRange(targetRange),
      UseConsumableItem(:final cargoIndex) =>
        _handleUseConsumable(cargoIndex),
      ExecuteShipSpecialAction() => _handleShipSpecialAction(),
      BraceForImpact() => _handleBraceForImpact(),
      TakeLootItem(:final lootIndex) => _handleTakeLootItem(lootIndex),
      TakeAllLoot() => _handleTakeAllLoot(),
      LeaveRemainingLoot() => _handleLeaveRemainingLoot(),
      DropCargoItem(:final cargoIndex) => _handleDropCargo(cargoIndex),
      EquipCargoWeapon(:final cargoIndex) => _handleEquipCargoWeapon(cargoIndex),
      UnequipShipWeapon(:final equippedIndex) =>
        _handleUnequipShipWeapon(equippedIndex),
      AdvanceToNextBattle() => _handleAdvanceToNextBattle(),
      ReturnToPort() => _handleReturnToPort(),
      VisitMerchant() => _handleVisitMerchant(),
      LeaveMerchant() => _handleLeaveMerchant(),
      BuyMerchantItem(:final stockIndex) => _handleBuyMerchantItem(stockIndex),
      SellCargoItem(:final cargoIndex) => _handleSellCargoItem(cargoIndex),
      SellAllTreasure() => _handleSellAllTreasure(),
      RepairShip(:final percentage) => _handleRepairShip(percentage),
      UpgradeShip() => _handleUpgradeShip(),
      TemperHardpoint(:final slot) => _handleTemperHardpoint(slot),
      ContinueLineage(
        :final heirName,
        :final chosenClass,
        :final boon,
        :final quirk,
      ) =>
        _handleContinueLineage(heirName, chosenClass, boon: boon, quirk: quirk),
      AbandonHunt() => _handleAbandonHunt(),
      CareenHullAtIsland() => _handleCareenHullAtIsland(),
      DrillGunnersAtIsland() => _handleDrillGunnersAtIsland(),
      ForageShoalsAtIsland() => _handleForageShoalsAtIsland(),
      DepartIsland() => _handleDepartIsland(),
      SalvageShipwreck(:final choice) => _handleSalvageShipwreck(choice),
      ClaimExpeditionVictory() => _handleClaimExpeditionVictory(),
      ResolveCalderaClimax(:final choice) => _handleResolveCalderaClimax(choice),
      ToggleCovenantPact(:final pactId) => _handleToggleCovenantPact(pactId),
      UpgradeBlueprintArmament(:final blueprintId) =>
        _handleUpgradeBlueprintArmament(blueprintId),
      UnlockAuxiliaryExpansion() => _handleUnlockAuxiliaryExpansion(),
      UnlockEldritchRelic(:final relicId) => _handleUnlockEldritchRelic(relicId),
      UpgradeHarborMonument(:final monumentId) =>
        _handleUpgradeHarborMonument(monumentId),
      CommuneWithShrine(:final choice) => _handleCommuneWithShrine(choice),
      AcceptShrineBlessing(:final power, :final slot) =>
        _handleAcceptShrineBlessing(power, slot),
      DepartShrine() => _handleDepartShrine(),
      DepartSmuggler() => _handleDepartSmuggler(),
      SteerCourse(:final bearing) => _handleSteerCourse(bearing),
      TakeHelm() => _handleTakeHelm(),
      UnlockBlueprint(:final blueprintId) => _handleUnlockBlueprint(blueprintId),
      CommissionBlueprint(:final blueprintId) =>
        _handleCommissionBlueprint(blueprintId),
    };
  }

  List<GameEvent> _handleNameCaptain(String name) {
    if (phase != SessionPhase.captainCreation &&
        phase != SessionPhase.death) {
      throw StateError('Cannot name captain in phase $phase');
    }
    captainName = name;

    // Davy Jones Easter Egg
    if (name.equalsIgnoreCase('Davy Jones')) {
      profile.hasBegunFirstVoyage = true;
      final events = <GameEvent>[];
      ship = createFlyingDutchman();
      seaChart.currentRow = 3;
      seaChart.currentCol = 4;
      seaChart.maxRowReached = 3;
      currentMonster = seaChart.currentMonster(rng);
      battleRound = 1;
      combatRange = CombatRange.medium;
      lastHelmOrderThisTurn = HelmOrder.holdLine;
      _disruptedBossCatastropheThisTurn = false;
      usedQuickConsumableThisTurn = false;
      quickConsumablesUsedThisTurn = 0;
      currentMonster!.currentIntent = selectNextMonsterIntent(
        currentMonster!,
        combatRange,
        rng,
        battleRound: battleRound,
      );
      final prevPhase = phase.displayName;
      phase = SessionPhase.battle;

      events.add(PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ));
      events.add(BattleStarted(
        monsterName: currentMonster!.name,
        difficulty: seaChart.currentDifficulty,
        isBoss: true,
        monsterHp: currentMonster!.maxHp,
        monsterAc: currentMonster!.armorClass,
      ));
      events.add(MonsterIntentTelegraphed(
        monsterName: currentMonster!.name,
        intent: currentMonster!.currentIntent!,
      ));
      return events;
    }

    return const <GameEvent>[];
  }

  List<GameEvent> _handleChooseShip(ShipClass shipClass, String? customName) {
    if (phase != SessionPhase.captainCreation) {
      throw StateError('Cannot choose starting ship in phase $phase');
    }
    final bpId = BlueprintId.fromShipClass(shipClass);
    if (!profile.isBlueprintUnlocked(bpId)) {
      throw StateError('Blueprint $bpId is not unlocked');
    }
    ship = createFlagshipFromBlueprint(
      bpId,
      level: 1,
      rng: rng,
      name: (customName != null && customName.isNotEmpty) ? customName : null,
      armamentTier: profile.armamentTierFor(bpId),
      hasExpandedAuxiliarySlot: profile.hasExpandedAuxiliarySlot,
      bonusMaxHp: profile.monumentBonusMaxHp,
    );
    ship!.shipClass = shipClass;
    if (shipClass == ShipClass.corvette) {
      ship!.maxWeaponWeight = 5;
      ship!.baseEvasion = 10;
      ship!.currentEvasion = 10;
    }
    profile.activeBlueprintId = bpId.name;
    ship!.gold = 25;

    refreshMerchantStock(1);
    final prevPhase = phase.displayName;
    phase = SessionPhase.port;

    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleBeginFirstVoyage(String name, String? shipName) {
    if (phase != SessionPhase.captainCreation) {
      throw StateError('Cannot begin a first voyage in phase $phase');
    }
    if (name.trim().isEmpty) throw ArgumentError('Captain name cannot be empty');
    final events = <GameEvent>[..._handleNameCaptain(name.trim())];
    if (phase == SessionPhase.battle) return events; // Davy Jones.
    events.addAll(_handleChooseShip(ShipClass.standard, shipName));
    events.addAll(_handleVentureOutToSea());
    return events;
  }

  List<GameEvent> _handleUnlockBlueprint(BlueprintId blueprintId) {
    _requireHomePort();
    final bp = FlagshipBlueprint.catalog[blueprintId];
    if (bp == null) {
      throw ArgumentError('Unknown blueprint: $blueprintId');
    }
    if (profile.isBlueprintUnlocked(blueprintId)) {
      return const <GameEvent>[];
    }
    if (!profile.canUnlockBlueprint(blueprintId)) {
      throw StateError('Cannot afford blueprint $blueprintId');
    }
    profile.unlockBlueprint(blueprintId);
    return <GameEvent>[
      BlueprintUnlocked(
        blueprintId: blueprintId,
        blueprintName: bp.name,
        remainingCurrencies: profile.metaInventory,
      ),
    ];
  }

  List<GameEvent> _handleCommissionBlueprint(BlueprintId blueprintId) {
    if (phase != SessionPhase.port && phase != SessionPhase.captainCreation) {
      throw StateError('Cannot commission blueprints in phase $phase');
    }
    final bp = FlagshipBlueprint.catalog[blueprintId];
    if (bp == null) {
      throw ArgumentError('Unknown blueprint: $blueprintId');
    }
    if (!profile.isBlueprintUnlocked(blueprintId)) {
      throw StateError('Blueprint $blueprintId is not unlocked');
    }
    profile.activeBlueprintId = blueprintId.name;

    final oldGold = ship?.gold ?? 25;
    final oldName = (ship != null && ship!.name.isNotEmpty)
        ? ship!.name
        : (captainName.isNotEmpty ? '$captainName\'s Flagship' : null);
    final oldCargo =
        ship?.cargo != null ? List<Item>.from(ship!.cargo) : <Item>[];

    final newShip = createFlagshipFromBlueprint(
      blueprintId,
      level: 1,
      rng: rng,
      name: oldName,
      armamentTier: profile.armamentTierFor(blueprintId),
      hasExpandedAuxiliarySlot: profile.hasExpandedAuxiliarySlot,
      bonusMaxHp: profile.monumentBonusMaxHp,
    );
    newShip.gold = oldGold;
    newShip.blessings.addAll(ship?.blessings ?? {});

    for (final item in oldCargo) {
      if (item is ShipWeapon) continue;
      newShip.addCargo(item);
    }

    ship = newShip;

    return <GameEvent>[
      BlueprintCommissioned(
        blueprintId: blueprintId,
        blueprintName: bp.name,
        ship: newShip,
      ),
    ];
  }

  List<GameEvent> _handleToggleCovenantPact(CovenantPactId pactId) {
    if (phase != SessionPhase.port) {
      throw StateError('Can only modify Covenant Pacts while at Port');
    }
    if (!profile.hasUnlockedCovenant) {
      throw StateError('Covenant of the Deep has not been unlocked yet');
    }
    profile.togglePact(pactId);
    final isActive = profile.isPactActive(pactId);
    final pact = CovenantPact.catalog[pactId]!;
    return <GameEvent>[
      CovenantPactToggled(
        pactId: pactId,
        isActive: isActive,
        totalPactBurden: profile.totalPactBurden,
      ),
      NarrationEvent(
        isActive
            ? 'Covenant Pact ratified: ${pact.name} (+${pact.burden} Pact Burden).'
            : 'Covenant Pact rescinded: ${pact.name}.',
      ),
    ];
  }

  List<GameEvent> _handleUpgradeBlueprintArmament(BlueprintId blueprintId) {
    _requireHomePort();
    if (!profile.canUpgradeBlueprintArmament(blueprintId)) {
      throw StateError('Cannot upgrade armament for $blueprintId');
    }
    profile.upgradeBlueprintArmament(blueprintId);
    final newTier = profile.armamentTierFor(blueprintId);
    if (ship != null && ship!.blueprintId == blueprintId.name) {
      // Refresh signature weapon tier on the active flagship
      final mult = BlueprintArmamentProgression.damageMultiplierForTier(newTier);
      final prevMult =
          BlueprintArmamentProgression.damageMultiplierForTier(newTier - 1);
      final numeral = newTier == 2 ? 'II' : 'III';
      for (final w in ship!.equippedWeapons) {
        if (w.isSignature || blueprintId == BlueprintId.standard) {
          w.damage = ((w.damage / prevMult) * mult).round();
          final baseName = w.name.replaceAll(RegExp(r' (II|III)$'), '');
          w.name = '$baseName $numeral';
        }
      }
    }
    final bp = FlagshipBlueprint.catalog[blueprintId]!;
    return <GameEvent>[
      BlueprintArmamentUpgraded(blueprintId: blueprintId, newTier: newTier),
      NarrationEvent(
        '${bp.name} signature armament upgraded to Tier $newTier!',
      ),
    ];
  }

  List<GameEvent> _handleUnlockAuxiliaryExpansion() {
    _requireHomePort();
    if (!profile.canUnlockAuxiliaryExpansion()) {
      throw StateError('Cannot unlock Reserve Auxiliary Hardpoint expansion');
    }
    profile.unlockAuxiliaryExpansion();
    if (ship != null) {
      ship!.maxCargo += 1;
      ship!.maxWeaponWeight += 2;
    }
    return const <GameEvent>[
      AuxiliaryExpansionUnlocked(),
      NarrationEvent(
        'Tactical Belt expanded (+1 Slot)!',
      ),
    ];
  }

  List<GameEvent> _handleUnlockEldritchRelic(EldritchRelicId relicId) {
    _requireHomePort();
    if (!profile.canUnlockEldritchRelic(relicId)) {
      throw StateError('Cannot unlock Eldritch Relic $relicId');
    }
    profile.unlockEldritchRelic(relicId);
    final def = EldritchRelicDef.catalog[relicId]!;
    return <GameEvent>[
      EldritchRelicUnlocked(relicId: relicId, relicName: def.name),
      NarrationEvent(
        'Forged Eldritch Relic at the Covenant Altar: ${def.name}!',
      ),
    ];
  }

  List<GameEvent> _handleUpgradeHarborMonument(HarborMonumentId monumentId) {
    _requireHomePort();
    if (!profile.canUpgradeMonument(monumentId)) {
      throw StateError('Cannot upgrade Harbor Monument $monumentId');
    }
    profile.upgradeMonument(monumentId);
    final newRank = profile.monumentRank(monumentId);
    if (monumentId == HarborMonumentId.obsidianObelisk && ship != null) {
      ship!.maxHp += 5;
      ship!.currentHp += 5;
    }
    final def = HarborMonumentDef.catalog[monumentId]!;
    return <GameEvent>[
      HarborMonumentUpgraded(monumentId: monumentId, newRank: newRank),
      NarrationEvent(
        '${def.name} consecrated to Rank $newRank (${def.bonusPerRankDescription})!',
      ),
    ];
  }

  List<GameEvent> _handleVentureOutToSea([int startingRow = 0]) {
    if (phase == SessionPhase.stronghold) return _handleTakeHelm();
    if (phase != SessionPhase.port) {
      throw StateError('Cannot venture out to sea from $phase');
    }
    final clampedRow = startingRow.clamp(0, seaChart.maxRowReached);
    profile.hasBegunFirstVoyage = true;
    _resetVoyageRefits();
    // A departure from port begins a fresh voyage; blessings are run-scoped.
    ship?.blessings.clear();
    gunneryAccuracyBoon = 0;
    runicGuidanceBoon = 0;
    shrineManifestedPowers = const [];
    seaChart.beginVoyage(startingRow: clampedRow);
    return _startEncounter();
  }

  void _resetVoyageRefits() {
    final vessel = ship;
    if (vessel == null || captainName.equalsIgnoreCase('Davy Jones') ||
        (vessel.level == 1 && vessel.hardpointMarks.values.every((mark) => mark == 1))) {
      return;
    }
    final blueprint = BlueprintId.fromShipClass(vessel.shipClass);
    final base = createFlagshipFromBlueprint(blueprint, rng: rng,
        id: vessel.id, name: vessel.name,
        armamentTier: profile.armamentTierFor(blueprint),
        hasExpandedAuxiliarySlot: profile.hasExpandedAuxiliarySlot,
        bonusMaxHp: profile.monumentBonusMaxHp);
    // Gold and cargo belong to the captain. Only temporary ship refits reset.
    vessel
      ..level = 1
      ..maxHp = base.maxHp
      ..currentHp = base.maxHp
      ..armorClass = base.armorClass
      ..maxCargo = base.maxCargo
      ..maxWeaponWeight = base.maxWeaponWeight
      ..baseEvasion = base.baseEvasion
      ..baseDmgReduction = base.baseDmgReduction
      ..dmgReductionMod = base.dmgReductionMod;
    vessel.hardpointMarks..clear()..addAll(base.hardpointMarks);
    vessel.equippedWeapons..clear()..addAll(base.equippedWeapons);
  }

  List<GameEvent> _handleAdvanceToNextBattle() {
    if (phase == SessionPhase.stronghold) return _handleTakeHelm();
    if (phase == SessionPhase.helm) {
      return _handleSteerCourse(NavigationalBearing.deadAhead);
    }
    if (phase == SessionPhase.smuggler) {
      return _handleDepartSmuggler();
    }
    if (phase == SessionPhase.shrine) {
      return _handleDepartShrine();
    }
    if (phase != SessionPhase.restArea && phase != SessionPhase.shipwreck) {
      throw StateError('Cannot advance to next battle from $phase');
    }
    if (phase == SessionPhase.shipwreck && !hasSalvagedCurrentWreck) {
      throw StateError(
          'Must choose a salvage action before departing the shipwreck derelict');
    }

    // Check if we just defeated the Region Boss at [3][4] or leg totalLegs
    if (phase == SessionPhase.restArea &&
        seaChart.isRegionTitan &&
        (hasDefeatedCurrentEncounter || currentMonster?.isAlive == false)) {
      if (seaChart.currentRegionIndex >= SeaChart.totalRegions - 1) {
        // Slain the Region 3 Final Titan! Grand Victory!
        final prevPhase = phase.displayName;
        phase = SessionPhase.expeditionVictory;
        return <GameEvent>[
          PhaseChanged(
            previousPhase: prevPhase,
            newPhase: phase.displayName,
          ),
          ExpeditionWon(
            captainName: captainName,
            shipName: ship!.name,
            monstersDefeated: monstersDefeatedThisLife,
            goldAmassed: ship!.gold,
          ),
        ];
      } else {
        // Transition to next region via after-region stronghold!
        final prevRegion = seaChart.currentRegionName;
        seaChart.advanceRegion(rng);
        final nextRegion = seaChart.currentRegionName;
        final stronghold = seaChart.currentPortName;
        refreshMerchantStock(seaChart.currentDifficulty);

        final prevPhase = phase.displayName;
        phase = SessionPhase.stronghold;
        return <GameEvent>[
          RegionTransitioned(
            previousRegion: prevRegion,
            newRegion: nextRegion,
            narrative:
                'The titan sinks into the deep! The passage clears, and your ship makes berth at $stronghold, fortified gateway to $nextRegion.',
          ),
          PhaseChanged(
            previousPhase: prevPhase,
            newPhase: phase.displayName,
          ),
        ];
      }
    }

    final events = _handleTakeHelm();
    if (phase == SessionPhase.helm) {
      final options = seaChart.currentCourseOptions;
      final compelledNemesis = activeQuirk?.id == BloodlineTraitId.bloodOath
          ? options.where((option) => option.isNemesis).firstOrNull
          : null;
      final bearing =
          compelledNemesis?.bearing ??
          (activeQuirk?.id == BloodlineTraitId.recklessHelmsman &&
                  options.length > 1
              ? options
                    .firstWhere(
                      (o) => o.bearing != NavigationalBearing.deadAhead,
                    )
                    .bearing
              : NavigationalBearing.deadAhead);
      events.addAll(_handleSteerCourse(bearing));
    }
    return events;
  }

  List<GameEvent> _handleTakeHelm() {
    if (phase != SessionPhase.restArea &&
        phase != SessionPhase.respiteIsland &&
        phase != SessionPhase.shipwreck &&
        phase != SessionPhase.smuggler &&
        phase != SessionPhase.shrine &&
        phase != SessionPhase.port &&
        phase != SessionPhase.stronghold) {
      throw StateError('Cannot take helm from phase $phase');
    }
    if (phase == SessionPhase.port) {
      _resetVoyageRefits();
      ship?.blessings.clear();
      gunneryAccuracyBoon = 0;
      runicGuidanceBoon = 0;
      shrineManifestedPowers = const [];
    }
    if (phase == SessionPhase.shipwreck && !hasSalvagedCurrentWreck) {
      throw StateError(
          'Must choose a salvage action before departing the shipwreck derelict');
    }

    // Check if we just defeated the Region Boss at [3][4] or leg totalLegs
    if ((phase == SessionPhase.restArea || phase == SessionPhase.loot) &&
        seaChart.isRegionTitan &&
        (hasDefeatedCurrentEncounter || currentMonster?.isAlive == false)) {
      if (seaChart.currentRegionIndex >= SeaChart.totalRegions - 1) {
        final prevPhase = phase.displayName;
        phase = SessionPhase.expeditionVictory;
        return <GameEvent>[
          PhaseChanged(
            previousPhase: prevPhase,
            newPhase: phase.displayName,
          ),
          ExpeditionWon(
            captainName: captainName,
            shipName: ship!.name,
            monstersDefeated: monstersDefeatedThisLife,
            goldAmassed: ship!.gold,
          ),
        ];
      } else {
        final prevRegion = seaChart.currentRegionName;
        seaChart.advanceRegion(rng);
        final nextRegion = seaChart.currentRegionName;
        final stronghold = seaChart.currentPortName;
        refreshMerchantStock(seaChart.currentDifficulty);

        final prevPhase = phase.displayName;
        phase = SessionPhase.stronghold;
        return <GameEvent>[
          RegionTransitioned(
            previousRegion: prevRegion,
            newRegion: nextRegion,
            narrative:
                'The titan sinks into the deep! The passage clears, and your ship makes berth at $stronghold, fortified gateway to $nextRegion.',
          ),
          PhaseChanged(
            previousPhase: prevPhase,
            newPhase: phase.displayName,
          ),
        ];
      }
    }

    final prevPhase = phase.displayName;
    phase = SessionPhase.helm;
    final courses = seaChart.ensureCourseOptions(
      rng,
      profile.activeNemesis,
      profile.isPactActive(CovenantPactId.chokingFog),
      profile.isPactActive(CovenantPactId.apexEmergence),
    );
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
      HelmApproached(
        currentLeg: seaChart.currentLeg,
        totalLegs: seaChart.totalLegs,
        regionName: seaChart.currentRegionName,
        availableCourses: courses,
      ),
    ];
  }

  List<GameEvent> _handleSteerCourse(NavigationalBearing bearing) {
    if (phase != SessionPhase.helm) {
      throw StateError('Cannot steer course from phase $phase');
    }

    // Also support restored/legacy helm states with no cached offers. Never
    // let SeaChart's context-free fallback generate a session's course choices.
    seaChart.ensureCourseOptions(
      rng,
      profile.activeNemesis,
      profile.isPactActive(CovenantPactId.chokingFog),
      profile.isPactActive(CovenantPactId.apexEmergence),
    );

    // Reckless Helmsman: "Dead Ahead" heading is disabled at sea
    if (activeQuirk?.id == BloodlineTraitId.recklessHelmsman &&
        bearing == NavigationalBearing.deadAhead &&
        seaChart.currentCourseOptions.length > 1) {
      throw StateError('Reckless Helmsman refuses to steer Dead Ahead!');
    }

    // Blood Oath: If Nemesis is visible on the helm, wheel locks onto it
    if (activeQuirk?.id == BloodlineTraitId.bloodOath) {
      final nemesisCourse = seaChart.currentCourseOptions
          .where((opt) => opt.isNemesis)
          .firstOrNull;
      if (nemesisCourse != null && bearing != nemesisCourse.bearing) {
        throw StateError(
          'Blood Oath compels the wheel: you cannot steer away from your Nemesis!',
        );
      }
    }

    final chosen = seaChart.steerCourse(bearing, rng);
    profile.hasBegunFirstVoyage = true;
    final events = <GameEvent>[
      CourseSteered(
        bearing: bearing,
        nodeType: chosen.nodeType,
        leg: seaChart.currentLeg,
        lookoutCall: chosen.lookoutCall,
      ),
    ];

    events.addAll(_startEncounter());
    return events;
  }

  List<GameEvent> _startEncounter() {
    hasDefeatedCurrentEncounter = false;
    if (ship == null || !ship!.isAlive) {
      return _resolvePlayerDeath();
    }
    ship!.resetCombatBoosts();
    ship!.resetWeaponCooldowns();
    _purgedFrenzyThisTurn = false;

    // Reckless Helmsman: steering Port or Starboard grants +10% evasion during combat
    if (activeQuirk?.id == BloodlineTraitId.recklessHelmsman &&
        seaChart.voyageLog.isNotEmpty &&
        seaChart.voyageLog.last.bearing != NavigationalBearing.deadAhead) {
      ship!.currentEvasion = min(90, ship!.currentEvasion + 10);
    }

    final events = <GameEvent>[];

    final nodeType = seaChart.currentNodeType;
    if (nodeType == EncounterNodeType.respiteIsland) {
      hasCareenedAtCurrentIsland = false;
      hasDrilledAtCurrentIsland = false;
      hasForagedAtCurrentIsland = false;
      final isHaven = seaChart.currentLeg == seaChart.midpointHavenLeg;
      currentIslandName = isHaven
          ? switch (seaChart.currentRegionIndex) {
              0 => "The Siren's Rest Haven",
              1 => "Sargasso Sanctuary Key",
              _ => "Caldera Refuge Atoll",
            }
          : _generateIslandName();
      final prevPhase = phase.displayName;
      phase = SessionPhase.respiteIsland;
      events.add(PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ));
      events.add(RespiteIslandReached(
        islandName: currentIslandName,
        description: isHaven
            ? 'A grand fortified haven with calm deep-water berths, freshwater springs, and traveling shipwrights.'
            : 'A secluded sandy atoll with calm surf, where seabirds wheel overhead offering emergency respite.',
      ));
      return events;
    }

    if (nodeType == EncounterNodeType.shipwreckSalvage) {
      hasSalvagedCurrentWreck = false;
      currentShipwreckName = _generateShipwreckName();
      final prevPhase = phase.displayName;
      phase = SessionPhase.shipwreck;
      events.add(PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ));
      events.add(ShipwreckDiscovered(
        shipwreckName: currentShipwreckName,
        description:
            'A battered merchant galleon drifting in the morning mist, hull breached and flotsam trailing behind.',
      ));
      return events;
    }

    if (nodeType == EncounterNodeType.smugglerTrader) {
      currentSmugglerName = _generateSmugglerName();
      smugglerStock = generateMerchantStock(max(1, seaChart.currentDifficulty + 1), rng);
      final prevPhase = phase.displayName;
      phase = SessionPhase.smuggler;
      events.add(PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ));
      events.add(SmugglerEncountered(
        smugglerName: currentSmugglerName,
        description:
            'A clandestine merchant ketch riding the ocean swells under muffled lanterns, peddling contraband munitions.',
      ));
      return events;
    }

    if (nodeType == EncounterNodeType.ancientShrine) {
      hasCommunedAtCurrentShrine = false;
      currentShrineName = _generateShrineName();
      currentShrineLore = _generateShrineLore();
      shrineManifestedPowers = selectShrinePowers(ship!, rng);
      final prevPhase = phase.displayName;
      phase = SessionPhase.shrine;
      events.add(PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ));
      events.add(ShrineDiscovered(
        shrineName: currentShrineName,
        loreInscription: currentShrineLore,
      ));
      return events;
    }

    if (seaChart.currentIsNemesis && profile.activeNemesis != null) {
      currentMonster = profile.activeNemesis!.instantiateMonster(rng);
      isNemesisBattle = true;
    } else {
      currentMonster = seaChart.currentMonster(rng);
      isNemesisBattle = false;
    }
    battleRound = 1;
    combatRange = CombatRange.medium;

    // Apply Covenant of the Deep Pacts to the spawned monster:
    if (profile.isPactActive(CovenantPactId.abyssalVigor)) {
      currentMonster!.maxHp = (currentMonster!.maxHp * 1.25).round();
      currentMonster!.currentHp = currentMonster!.maxHp;
    }
    if (profile.isPactActive(CovenantPactId.calcifiedCarapace)) {
      currentMonster!.maxCarapace += 10;
      currentMonster!.carapacePlating += 10;
    }
    if (profile.isPactActive(CovenantPactId.feedingFrenzy)) {
      for (final mw in currentMonster!.usableWeapons) {
        mw.damage = (mw.damage * 1.15).round();
      }
    }

    // Environmental Hazards by Region:
    if (seaChart.currentRegionIndex == 1) {
      // Region 2: The Sargasso Drift
      // Tangled Kelp slows ship maneuvering (-10% evasion, or -20% under Volatile Environs)
      final kelpPenalty =
          profile.isPactActive(CovenantPactId.volatileEnvirons) ? 20 : 10;
      ship!.currentEvasion = max(0, ship!.currentEvasion - kelpPenalty);
      // Phosphor Haze cloaks the beast in obscurity
      currentMonster!.isObscured = true;
      events.add(NarrationEvent(
        'Sargasso Hazard: Tangled Kelp fouls the rudder (-$kelpPenalty% evasion) and Phosphor Haze cloaks the beast in obscurity!',
      ));
    }

    final prevPhase = phase.displayName;
    phase = SessionPhase.battle;
    lastHelmOrderThisTurn = HelmOrder.holdLine;
    _disruptedBossCatastropheThisTurn = false;
    usedQuickConsumableThisTurn = false;
    quickConsumablesUsedThisTurn = 0;
    currentMonster!.currentIntent = selectNextMonsterIntent(
      currentMonster!,
      combatRange,
      rng,
      battleRound: battleRound,
    );

    events.add(PhaseChanged(
      previousPhase: prevPhase,
      newPhase: phase.displayName,
    ));
    if (isNemesisBattle) {
      events.add(NemesisSpawned(nemesis: profile.activeNemesis!));
    }
    events.add(BattleStarted(
      monsterName: currentMonster!.name,
      difficulty: seaChart.currentDifficulty,
      isBoss: seaChart.isRegionTitan,
      monsterHp: currentMonster!.maxHp,
      monsterAc: currentMonster!.armorClass,
      isApex: currentMonster!.isApex,
      apexTitle: currentMonster!.apexTitle,
    ));
    events.add(MonsterIntentTelegraphed(
      monsterName: currentMonster!.name,
      intent: currentMonster!.currentIntent!,
    ));
    return events;
  }

  /// Evaluates player hits against active monster intents for pinning and Boss Wind-Up disruption.
  List<GameEvent> _evaluatePlayerHitIntentInteractions({
    required int totalDamageDealt,
    ShipWeaponType? weaponType,
    ConsumableType? consumableType,
    StatusEffect? inflictedStatus,
  }) {
    if (currentMonster == null || !currentMonster!.isAlive) {
      return const <GameEvent>[];
    }
    final events = <GameEvent>[];

    final isPinningOrdnance = weaponType == ShipWeaponType.harpoonWinch ||
        weaponType == ShipWeaponType.heavyMortar ||
        consumableType == ConsumableType.blastPack ||
        inflictedStatus == StatusEffect.stun ||
        currentMonster!.hasStatus(StatusEffect.stun);

    if (isPinningOrdnance) {
      currentMonster!.isPinnedThisTurn = true;
    }

    final intent = currentMonster!.currentIntent;
    if (intent != null &&
        (intent.isBossWindup || intent.isBossCatastropheStrike)) {
      currentMonster!.windupDamageTaken += totalDamageDealt;

      if (isPinningOrdnance) {
        final reason = switch (weaponType) {
          ShipWeaponType.heavyMortar =>
            'Heavy Mortar concussive blast shattered the titan\'s stance!',
          ShipWeaponType.harpoonWinch =>
            'Harpoon Winch cables wrenched the titan off-balance!',
          _ => 'Concussive shockwave disrupted the catastrophic charge!',
        };

        events.add(MonsterIntentDisrupted(
          monsterName: currentMonster!.name,
          intentName: intent.name,
          reason: reason,
        ));

        switch (currentMonster!.species) {
          case MonsterSpecies.kraken:
            currentMonster!.setIntentCooldown(
              MonsterIntentId.bossKrakenWindup,
              3,
            );
          case MonsterSpecies.worldSerpent:
            currentMonster!.setIntentCooldown(
              MonsterIntentId.bossWorldSerpentWindup,
              3,
            );
          case MonsterSpecies.ancientLeviathan:
            currentMonster!.setIntentCooldown(
              MonsterIntentId.bossLeviathanWindup,
              3,
            );
          default:
            break;
        }
        currentMonster!.windupDamageTaken = 0;
        currentMonster!.currentIntent = null;
        _disruptedBossCatastropheThisTurn = true;
      }
    }

    return events;
  }

  List<GameEvent> _handleFireWeaponVolley(ShipWeaponType weaponType) {
    if (phase != SessionPhase.battle || ship == null || currentMonster == null) {
      throw StateError('Cannot fire weapons outside of battle');
    }
    if (!isWeaponTypeUsableAtRange(weaponType, combatRange)) {
      throw StateError(
          'Cannot fire ${weaponType.displayName} at ${combatRange.displayName}');
    }
    final events = <GameEvent>[];

    var accuracyBoon = gunneryAccuracyBoon;
    gunneryAccuracyBoon = runicGuidanceBoon;

    double damageMultiplier = profile.monumentWeaponDamageMultiplier;
    if (activeQuirk?.id == BloodlineTraitId.saltAddict) {
      damageMultiplier *= 1.15;
    }
    if (isNemesisBattle &&
        (activeBoon?.id == BloodlineTraitId.bloodOath ||
            activeQuirk?.id == BloodlineTraitId.bloodOath)) {
      damageMultiplier *= 1.30;
    }
    if (activeQuirk?.id == BloodlineTraitId.overzealousGunner) {
      damageMultiplier *= 1.15;
    }

    // Consume Gunnery Drill utility buff (+15% Accuracy, +20% * markMult Damage)
    if (ship!.gunneryDrillBuffActive) {
      ship!.gunneryDrillBuffActive = false;
      final utilMult = ship!.hardpointMarkMultiplier(HardpointType.utility);
      final drillBonusPct = (20 * utilMult).round();
      accuracyBoon += 15;
      damageMultiplier *= (1.0 + 0.20 * utilMult);
      events.add(NarrationEvent(
        'Gunnery Drill volley: +15% Accuracy and +$drillBonusPct% Damage!',
      ));
    }

    // Consume Alchemical Pitch Flask buff (+25% Fire Damage + Burn on hit)
    final hadPitchCoating = ship!.pitchCoatingActive;
    if (hadPitchCoating) {
      ship!.pitchCoatingActive = false;
      damageMultiplier *= 1.25;
    }

    // Ghostwake Rail-Culverin: ignores monster Obscurity
    final hasGhostwake =
        weaponType == ShipWeaponType.precisionCulverin &&
            profile.isEldritchRelicActive(EldritchRelicId.ghostwakeCulverin);
    final savedObscured = currentMonster!.isObscured;
    if (hasGhostwake) {
      currentMonster!.isObscured = false;
    }

    // Player volley
    final volleyEvents = executeShipWeaponVolley(
      ship!,
      weaponType,
      currentMonster!,
      rng,
      traits,
      accuracyBoon,
      damageMultiplier,
      combatRange,
    );
    if (hasGhostwake) {
      currentMonster!.isObscured = savedObscured;
    }
    events.addAll(volleyEvents);
    _purgedFrenzyThisTurn =
        volleyEvents.whereType<SharkFrenzyDisrupted>().isNotEmpty;

    // If flagship was destroyed by point-blank mortar backfire
    if (!ship!.isAlive) {
      events.addAll(_resolvePlayerDeath());
      return events;
    }

    // Evaluate Post-Loop Eldritch Relic Weapon & Pitch Coating effects on hit
    final resolvedHits = volleyEvents
        .whereType<AttackHit>()
        .where((e) => e.targetName == currentMonster!.name && !e.isBlessingDamage)
        .toList();
    final carapaceHits = volleyEvents
        .whereType<CarapaceDamaged>()
        .where((e) => e.monsterName == currentMonster!.name)
        .toList();

    var totalDamageDealt =
        volleyEvents.whereType<AttackHit>()
            .where((e) => e.targetName == currentMonster!.name)
            .fold<int>(0, (sum, e) => sum + e.damage) +
            carapaceHits.fold<int>(0, (sum, e) => sum + e.damageDealt);

    if (resolvedHits.isNotEmpty || carapaceHits.isNotEmpty) {
      if (hadPitchCoating && currentMonster!.isAlive) {
        currentMonster!.addStatus(StatusEffect.burn);
        events.add(NarrationEvent(
          'Alchemical Pitch ignites ${currentMonster!.name} in inextinguishable flames (Burn)!',
        ));
      }

      if (weaponType == ShipWeaponType.prowRam &&
          profile.isEldritchRelicActive(EldritchRelicId.siphonRam)) {
        final totalHullDmg =
            resolvedHits.fold<int>(0, (sum, e) => sum + e.damage);
        if (totalHullDmg > 0) {
          final leechHeal = max(1, (totalHullDmg * 0.30).round());
          ship!.heal(leechHeal);
          events.add(NarrationEvent(
            'Abyssal Siphon Ram drinks the beast\'s lifeblood, restoring $leechHeal hull HP!',
          ));
        }
      }

      if (hasGhostwake && currentMonster!.isAlive) {
        final shockDmg = amplifyMonsterDamage(
          ship!, currentMonster!, resolvedHits.length * 8);
        currentMonster!.applyDamage(shockDmg);
        totalDamageDealt += shockDmg;
        events.add(NarrationEvent(
          'Ghostwake Rail-Culverin arcs abyssal lightning for +$shockDmg Shock damage!',
        ));
      }

      if (weaponType == ShipWeaponType.heavyMortar &&
          profile.isEldritchRelicActive(EldritchRelicId.brimstoneMortar) &&
          currentMonster!.isAlive) {
        currentMonster!.addStatus(StatusEffect.burn);
        events.add(const NarrationEvent(
          'Caldera Brimstone Mortar coats the beast in searing hydrothermal sulfur (Burn)!',
        ));
      }

      if (weaponType == ShipWeaponType.harpoonWinch &&
          profile.isEldritchRelicActive(EldritchRelicId.sinewWinch) &&
          currentMonster!.isAlive) {
        currentMonster!.addStatus(StatusEffect.poison);
        events.add(const NarrationEvent(
          'Kraken-Sinew Drag Winch constricts the quarry with venomous abyssal barbs (Poison)!',
        ));
      }

      events.addAll(_evaluatePlayerHitIntentInteractions(
        totalDamageDealt: totalDamageDealt,
        weaponType: weaponType,
      ));
    }

    // Action-driven momentum range shifts:
    // Prow Ram surges into Short Range
    if (weaponType == ShipWeaponType.prowRam && combatRange != CombatRange.short) {
      final prev = combatRange;
      combatRange = CombatRange.short;
      events.add(CombatRangeChanged(
        previousRange: prev,
        newRange: combatRange,
        reason: 'Prow Ram kinetic charge surged into point-blank range!',
      ));
    }
    // Harpoon Winch reels 1 band closer (and pulls monster into Drifting Tether-Trap if active!)
    if (weaponType == ShipWeaponType.harpoonWinch && combatRange != CombatRange.short) {
      final prev = combatRange;
      combatRange = combatRange.closer;
      events.add(CombatRangeChanged(
        previousRange: prev,
        newRange: combatRange,
        reason: 'Harpoon Winch tightened cables, reeling the quarry closer!',
      ));
      events.addAll(triggerBoilingWake(ship!, currentMonster!));
      if (ship!.activeTetherTrapDistance != null && currentMonster!.isAlive) {
        ship!.activeTetherTrapDistance = ship!.activeTetherTrapDistance! - 1;
        if (ship!.activeTetherTrapDistance! <= 0) {
          events.addAll(detonateTetherTrap(
            ship!,
            currentMonster!,
            rng,
            traits,
            reason:
                'Harpoon Winch dragged ${currentMonster!.name} straight into the floating net',
          ));
        }
      }
    }

    // Check if monster defeated
    if (!currentMonster!.isAlive) {
      events.addAll(_resolveMonsterDefeat());
      return events;
    }

    // Monster response turn
    events.addAll(_resolveMonsterTurn(firedWeaponType: weaponType));
    return events;
  }

  List<GameEvent> _handleIssueHelmOrder(HelmOrder order) {
    if (phase != SessionPhase.battle || ship == null || currentMonster == null) {
      throw StateError('Cannot issue helm orders outside of battle');
    }
    if (ship!.isGrappled && order != HelmOrder.holdLine) {
      throw StateError(
          'Cannot maneuver while grappled by ${currentMonster!.name}; helm is locked to Hold Line!');
    }
    if (!combatRange.availableHelmOrders.contains(order)) {
      throw StateError(
          'Helm order ${order.displayName} is not permitted at ${combatRange.displayName}');
    }
    lastHelmOrderThisTurn = order;
    final targetRange = combatRange.rangeAfterHelmOrder(order);
    if (combatRange == targetRange) {
      return <GameEvent>[
        NarrationEvent(
            'The helm holds steady at ${combatRange.displayName}.'),
      ];
    }
    final prev = combatRange;
    combatRange = targetRange;
    return <GameEvent>[
      CombatRangeChanged(
        previousRange: prev,
        newRange: combatRange,
        reason:
            'Helm ordered to ${order.displayName} (${prev.displayName} -> ${targetRange.displayName}).',
      ),
    ];
  }

  List<GameEvent> _handleChangeCombatRange(CombatRange targetRange) {
    if (phase != SessionPhase.battle || ship == null || currentMonster == null) {
      throw StateError('Cannot change combat range outside of battle');
    }
    if (combatRange == targetRange) return const <GameEvent>[];
    if (ship!.isGrappled) {
      throw StateError(
          'Cannot maneuver while grappled by ${currentMonster!.name}; helm is locked to Hold Line!');
    }
    final isLegalStep = (combatRange == CombatRange.long && targetRange == CombatRange.medium) ||
        (combatRange == CombatRange.medium && (targetRange == CombatRange.short || targetRange == CombatRange.long)) ||
        (combatRange == CombatRange.short && targetRange == CombatRange.medium);
    if (!isLegalStep) {
      throw StateError(
          'Cannot shift directly from $combatRange to $targetRange in a single helm maneuver');
    }
    final prev = combatRange;
    lastHelmOrderThisTurn =
        targetRange == prev.closer ? HelmOrder.advance : HelmOrder.fallBack;
    combatRange = targetRange;
    return <GameEvent>[
      CombatRangeChanged(
        previousRange: prev,
        newRange: combatRange,
        reason: 'Helm shifted course to ${targetRange.displayName}!',
      ),
    ];
  }

  List<GameEvent> _handleUseConsumable(int cargoIndex) {
    if (phase != SessionPhase.battle || ship == null || currentMonster == null) {
      throw StateError('Cannot use consumable outside of battle');
    }
    if (cargoIndex < 0 || cargoIndex >= ship!.cargo.length) {
      throw RangeError('Invalid cargo index: $cargoIndex');
    }
    final item = ship!.cargo[cargoIndex];
    if (item is! Consumable) {
      throw ArgumentError('Item at index $cargoIndex is not a consumable');
    }
    if (item.isDepleted) throw StateError('This consumable has already been spent');
    final maxQuickItems =
        activeBoon?.id == BloodlineTraitId.drillmaster ? 2 : 1;
    if (quickConsumablesUsedThisTurn >= maxQuickItems) {
      throw StateError(
          'Already used the maximum Quick Action consumables allowed this round');
    }

    quickConsumablesUsedThisTurn++;
    usedQuickConsumableThisTurn = quickConsumablesUsedThisTurn >= maxQuickItems;

    final events = <GameEvent>[];
    item.usesLeft--;

    switch (item.type) {
      case ConsumableType.hullPatchKit:
        final healAmt = max(1, (ship!.maxHp * 0.30).round());
        ship!.heal(healAmt);
        events.add(NarrationEvent(
          'Quick Action (0T): ${item.name} braced hull breaches, restoring $healAmt HP (${ship!.currentHp}/${ship!.maxHp})!',
        ));
      case ConsumableType.krakenInkBomb:
        ship!.currentEvasion = min(95, ship!.currentEvasion + 25);
        events.add(NarrationEvent(
          'Quick Action (0T): ${item.name} billows an abyssal smoke screen (+25% Evasion)!',
        ));
      case ConsumableType.alchemicalPitch:
        ship!.pitchCoatingActive = true;
        events.add(NarrationEvent(
          'Quick Action (0T): ${item.name} coats the deck guns in incendiary pitch (+25% Fire damage & Burn on next volley)!',
        ));
      case ConsumableType.unstableTincture:
      case ConsumableType.blastPack:
      case ConsumableType.chakram:
        final result = resolveConsumableEffect(item, rng);
        if (result.didHit) {
          final damage =
              amplifyMonsterDamage(ship!, currentMonster!, result.damage);
          if (result.damage > 0) {
            if (item.type == ConsumableType.blastPack &&
                currentMonster!.carapacePlating > 0) {
              final blastCarapace = damage * 2;
              if (currentMonster!.carapacePlating > blastCarapace) {
                currentMonster!.carapacePlating -= blastCarapace;
                events.add(CarapaceDamaged(
                  monsterName: currentMonster!.name,
                  damageDealt: blastCarapace,
                  remainingCarapace: currentMonster!.carapacePlating,
                  wasShattered: false,
                ));
              } else {
                final broken = currentMonster!.carapacePlating;
                final overflow =
                    max(0, damage - (broken ~/ 2));
                currentMonster!.carapacePlating = 0;
                events.add(CarapaceDamaged(
                  monsterName: currentMonster!.name,
                  damageDealt: broken,
                  remainingCarapace: 0,
                  wasShattered: true,
                ));
                if (overflow > 0) {
                  currentMonster!.applyDamage(overflow);
                  events.add(AttackHit(
                    targetName: currentMonster!.name,
                    damage: overflow,
                    damageType: result.damageType.displayName,
                    remainingHp: currentMonster!.currentHp,
                  ));
                }
              }
            } else {
              currentMonster!.applyDamage(damage);
              events.add(AttackHit(
                targetName: currentMonster!.name,
                damage: damage,
                damageType: result.damageType.displayName,
                remainingHp: currentMonster!.currentHp,
              ));
            }
          }
          if (result.statusEffect != null) {
            currentMonster!.addStatus(result.statusEffect!);
            events.add(NarrationEvent(
              result.description.isNotEmpty
                  ? result.description
                  : '${item.name} inflicts ${result.statusEffect!.displayName}!',
            ));
          }
          events.addAll(_evaluatePlayerHitIntentInteractions(
            totalDamageDealt: damage,
            consumableType: item.type,
            inflictedStatus: result.statusEffect,
          ));
        } else {
          events.add(AttackMissed(targetName: currentMonster!.name));
        }
    }

    if (item.isDepleted) {
      ship!.cargo.removeAt(cargoIndex);
    }

    // Check if monster defeated
    if (!currentMonster!.isAlive) {
      events.addAll(_resolveMonsterDefeat());
      return events;
    }

    if (activeBoon?.id == BloodlineTraitId.drillmaster) {
      events.add(const NarrationEvent(
        "Drillmaster: Quick hands primed the munition without forfeiting the ship's combat initiative!",
      ));
    }

    // Tactical Belt consumables are 0-Turn-Cost Quick Actions!
    return events;
  }

  List<GameEvent> _handleShipSpecialAction() {
    if (phase != SessionPhase.battle || ship == null) {
      throw StateError('Cannot use special action outside of battle');
    }
    if (!ship!.isAlive) {
      return _resolveMonsterTurn(usedUtility: true);
    }
    if (ship!.utilityCooldown > 0) {
      throw StateError(
          'Utility hardpoint is on cooldown (${ship!.utilityCooldown}T remaining)');
    }
    final events = <GameEvent>[];

    final bpId = BlueprintId.values.firstWhere(
      (b) => b.name == ship!.blueprintId,
      orElse: () => ship!.shipClass.blueprintId,
    );
    final utility = bpId.utilityHardpoint;
    final markMult = ship!.hardpointMarkMultiplier(HardpointType.utility);
    ship!.utilityCooldown = 2;

    switch (utility) {
      case UtilityHardpointId.gunneryDrill:
        ship!.isBracedByDrill = true;
        ship!.gunneryDrillBuffActive = true;
        final dmgBonusPct = (20 * markMult).round();
        events.add(NarrationEvent(
          'Gunnery Drill: ${ship!.name}\'s crew braces behind the gunwales (-20% incoming damage this round) and sights guns (+15% Accuracy & +$dmgBonusPct% Damage on next volley)!',
        ));
      case UtilityHardpointId.fortifyPlates:
        final msg = const FortifyTrait().executeSpecialAction(
          ship!,
          currentMonster!,
          rng,
        );
        if (msg.isNotEmpty) {
          events.add(NarrationEvent(msg));
        }
      case UtilityHardpointId.evasiveRigging:
        final msg = const EvasionTrait().executeSpecialAction(
          ship!,
          currentMonster!,
          rng,
        );
        if (msg.isNotEmpty) {
          events.add(NarrationEvent(msg));
        }
        if (combatRange != CombatRange.long && !ship!.isGrappled) {
          final prev = combatRange;
          combatRange = combatRange.farther;
          events.add(CombatRangeChanged(
            previousRange: prev,
            newRange: combatRange,
            reason:
                'Evasive Rigging caught the wind, falling back to open water!',
          ));
        }
      case UtilityHardpointId.driftingTetherTrap:
        final trapDamage = ((16 + 5 * (ship!.level - 1)) * markMult).round();
        ship!.activeTetherTrapDamage = trapDamage;
        switch (combatRange) {
          case CombatRange.short:
            ship!.activeTetherTrapDistance = 0;
            events.addAll(detonateTetherTrap(
              ship!,
              currentMonster!,
              rng,
              traits,
              reason:
                  '${ship!.name} launched a Drifting Tether-Trap at point-blank range',
            ));
            if (!currentMonster!.isAlive) {
              events.addAll(_resolveMonsterDefeat());
              return events;
            }
          case CombatRange.medium:
            ship!.activeTetherTrapDistance = 1;
            events.add(NarrationEvent(
              '${ship!.name} launches a Drifting Tether-Trap into Short Range (Distance to ${currentMonster!.name}: 1 band)!',
            ));
          case CombatRange.long:
            ship!.activeTetherTrapDistance = 2;
            events.add(NarrationEvent(
              '${ship!.name} launches a Drifting Tether-Trap into Medium Range (Distance to ${currentMonster!.name}: 2 bands)!',
            ));
        }
      case UtilityHardpointId.spotterFlare:
        currentMonster!.spotterFlareTurns = 2;
        currentMonster!.spotterFlareAccuracyBonus = (15 * markMult).round();
        currentMonster!.spotterFlareBlastBonus = 0.25 * markMult;
        currentMonster!.isObscured = false;
        currentMonster!.evasion = 0;
        events.add(NarrationEvent(
          '${ship!.name} fires a Phosphor Spotter Flare! ${currentMonster!.name} is illuminated for 2 turns (Obscurity & Evasion suppressed, +${currentMonster!.spotterFlareAccuracyBonus}% Accuracy, +${(currentMonster!.spotterFlareBlastBonus * 100).round()}% Blast damage taken)!',
        ));
    }

    final blessingEvents = activateUtilityBlessing(ship!, currentMonster!);
    events.addAll(blessingEvents);
    _purgedFrenzyThisTurn =
        blessingEvents.whereType<SharkFrenzyDisrupted>().isNotEmpty;
    if (!currentMonster!.isAlive) {
      events.addAll(_resolveMonsterDefeat());
      return events;
    }
    // Monster response turn
    events.addAll(_resolveMonsterTurn(usedUtility: true));
    return events;
  }

  List<GameEvent> _handleBraceForImpact() {
    if (phase != SessionPhase.battle || ship == null) {
      throw StateError('Cannot brace for impact outside of battle');
    }
    final events = <GameEvent>[];

    // Defensive bracing: +10% evasion for the incoming monster turn
    ship!.currentEvasion = min(90, ship!.currentEvasion + 10);
    events.add(NarrationEvent(
      '${ship!.name}\'s crew braces behind the gunwales (+10% Evasion) while ordnance reloads!',
    ));

    // Monster response turn
    events.addAll(_resolveMonsterTurn());
    return events;
  }

  List<GameEvent> _resolveMonsterTurn({
    ShipWeaponType? firedWeaponType,
    bool usedUtility = false,
  }) {
    final events = <GameEvent>[];
    final electroJoltWasActiveAtStart = currentMonster!.isElectroJolted;

    // Expire single-round ship debuffs after the player's turn has concluded
    ship!.isGrappled = false;
    ship!.tempAccuracyPenalty = 0;
    usedQuickConsumableThisTurn = false;
    quickConsumablesUsedThisTurn = 0;

    // Status effect tick on monster
    final monsterStatus = updateStatusEffects(
      currentMonster!,
      seaChart.currentDifficulty,
      rng,
      config,
      ship!,
      seaChart.currentRegionIndex,
    );
    events.addAll(monsterStatus.events);
    if (!currentMonster!.isAlive) {
      events.addAll(_resolveMonsterDefeat());
      return events;
    }

    // Feeding Frenzy Pact: Shark triggers frenzy at <= 60% HP instead of 40%
    if (profile.isPactActive(CovenantPactId.feedingFrenzy) &&
        !_purgedFrenzyThisTurn &&
        currentMonster!.species == MonsterSpecies.shark &&
        currentMonster!.frenzyStacks == 0 &&
        currentMonster!.currentHp <= (currentMonster!.maxHp * 0.60).round()) {
      currentMonster!.frenzyStacks = 1;
      events.add(SharkFrenzyRoared(
        monsterName: currentMonster!.name,
        stacks: 1,
      ));
    }

    // Monster executes its telegraphed intent if it can act and wasn't disrupted
    if (_disruptedBossCatastropheThisTurn) {
      events.add(MonsterHesitated(currentMonster!.name));
      currentMonster!.tickIntentCooldowns();
      currentMonster!.isPinnedThisTurn = false;
    } else if (monsterStatus.canAct) {
      if (currentMonster!.currentIntent != null) {
        final (newRange, intentEvents) = executeMonsterIntent(
          currentMonster!,
          ship!,
          rng,
          combatRange,
          config,
          traits,
          lastHelmOrderThisTurn,
        );
        combatRange = newRange;
        events.addAll(intentEvents);
      } else {
        events.addAll(takeMonsterTurn(
          currentMonster!,
          ship!,
          rng,
          config,
          traits,
          combatRange,
        ));
      }
    } else {
      currentMonster!.tickIntentCooldowns();
      currentMonster!.isPinnedThisTurn = false;
      currentMonster!.currentIntent = null;
    }

    finishOceanPowerTurn(ship!, currentMonster!,
        electroJoltWasActiveAtStart: electroJoltWasActiveAtStart);
    _purgedFrenzyThisTurn = false;
    _disruptedBossCatastropheThisTurn = false;
    lastHelmOrderThisTurn = HelmOrder.holdLine;
    ship!.isAnchoredThisTurn = false;
    ship!.isBracedByDrill = false;

    // A fatal strike remains fatal even when reactive powers also kill its source.
    if (!ship!.isAlive) {
      events.addAll(_resolvePlayerDeath());
      return events;
    }

    // Check if monster died from reactive powers or a trap during its movement.
    if (!currentMonster!.isAlive) {
      events.addAll(_resolveMonsterDefeat());
      return events;
    }

    // End of round: decrement cooldowns on weapons/utility NOT used this turn
    for (final weapon in ship!.equippedWeapons) {
      if (weapon.weaponType != firedWeaponType) {
        weapon.decrementChargeCountdown();
      }
    }
    if (!usedUtility && ship!.utilityCooldown > 0) {
      ship!.utilityCooldown--;
    }
    currentMonster!.tickSpotterFlare();

    // Region 3 Hazard: Thermal Caldera Scald every 3 combat rounds (or every 2 rounds for 15 dmg under Volatile Environs)
    final volatileActive =
        profile.isPactActive(CovenantPactId.volatileEnvirons);
    final scaldInterval = volatileActive ? 2 : 3;
    if (seaChart.currentRegionIndex == 2 && battleRound % scaldInterval == 0) {
      final scaldDamage = volatileActive ? 15 : 10;
      ship!.applyDamage(scaldDamage);
      events.add(ThermalScaldOccurred(
        shipName: ship!.name,
        damage: scaldDamage,
        remainingHp: ship!.currentHp,
      ));
      if (!ship!.isAlive) {
        events.addAll(_resolvePlayerDeath());
        return events;
      }
    }

    battleRound++;

    // Start of new round: Ocean current drifts Corsair Tether-Trap 1 space closer to the monster
    if (ship!.activeTetherTrapDistance != null && currentMonster!.isAlive) {
      ship!.activeTetherTrapDistance = ship!.activeTetherTrapDistance! - 1;
      if (ship!.activeTetherTrapDistance! <= 0) {
        events.addAll(detonateTetherTrap(
          ship!,
          currentMonster!,
          rng,
          traits,
          reason:
              'Ocean currents drifted the Tether-Trap into ${currentMonster!.name}',
        ));
        if (!currentMonster!.isAlive) {
          events.addAll(_resolveMonsterDefeat());
          return events;
        }
      } else {
        events.add(NarrationEvent(
          'Ocean currents drift the Tether-Trap closer to ${currentMonster!.name} (Distance: ${ship!.activeTetherTrapDistance} band)!',
        ));
      }
    }

    // Status effect tick on ship
    final shipStatus = updateStatusEffects(
      ship!,
      seaChart.currentDifficulty,
      rng,
      config,
    );
    events.addAll(shipStatus.events);
    if (!ship!.isAlive) {
      events.addAll(_resolvePlayerDeath());
      return events;
    }

    // Select and telegraph the monster's intent for the next combat round
    if (currentMonster != null &&
        currentMonster!.isAlive &&
        currentMonster!.currentIntent == null) {
      final nextIntent = selectNextMonsterIntent(
        currentMonster!,
        combatRange,
        rng,
        battleRound: battleRound,
      );
      currentMonster!.currentIntent = nextIntent;
      events.add(MonsterIntentTelegraphed(
        monsterName: currentMonster!.name,
        intent: nextIntent,
      ));
    }

    return events;
  }

  List<GameEvent> _resolveMonsterDefeat() {
    final events = <GameEvent>[];
    runicGuidanceBoon = 0;
    gunneryAccuracyBoon = 0;
    monstersDefeatedThisLife++;
    hasDefeatedCurrentEncounter = true;
    highestDifficultyThisLife = max(
      highestDifficultyThisLife,
      seaChart.currentDifficulty,
    );

    final isApex = currentMonster?.isApex ?? false;
    final rawGold = calculateVictoryGold(
      seaChart.currentDifficulty,
      rng,
      isApex: isApex,
    );
    final goldSalvaged =
        (rawGold * profile.monumentBountyGoldMultiplier).round();
    if (ship != null) {
      ship!.gold += goldSalvaged;
    }
    lastGoldSalvaged = goldSalvaged;

    pendingLoot = generateTacticalVictoryLoot(
      seaChart.currentDifficulty,
      rng,
      1,
      2,
      isApex,
    );
    ship!.decrementChargeTimeOnWeapons();
    ship!.resetCombatBoosts();
    combatRange = CombatRange.medium;

    final prevPhase = phase.displayName;
    phase = SessionPhase.loot;

    events.add(PhaseChanged(
      previousPhase: prevPhase,
      newPhase: phase.displayName,
    ));
    events.add(LootDropped(
      items: List<Item>.from(pendingLoot),
      goldSalvaged: goldSalvaged,
    ));

    // Meta-currency & Nemesis reward resolution
    if (isNemesisBattle && profile.activeNemesis != null) {
      final nem = profile.activeNemesis!;
      if (ship != null) {
        ship!.gold += nem.bountyGold;
      }
      profile.metaInventory.add(
        seaGlass: nem.bountySeaGlass,
        monsterBone: nem.bountyMonsterBone,
        abyssalBarnacles: nem.bountyBarnacles,
      );
      events.add(NemesisSlain(nemesis: nem));
      events.add(MetaCurrenciesAwarded(
        seaGlass: nem.bountySeaGlass,
        monsterBone: nem.bountyMonsterBone,
        abyssalBarnacles: nem.bountyBarnacles,
        reason: 'Nemesis Slain: ${nem.moniker}',
      ));
      profile.activeNemesis = null;
      isNemesisBattle = false;
    } else {
      final boneDrop = rng.nextIntRange(1, 2) + (isApex ? 1 : 0);
      final barnacleDrop =
          (isApex || seaChart.currentRegionIndex >= 1) && rng.nextInt(100) < 35
              ? 1
              : 0;
      final krakenDrop =
          currentMonster?.species == MonsterSpecies.kraken ? 1 : 0;
      final serpentDrop =
          currentMonster?.species == MonsterSpecies.worldSerpent ? 1 : 0;
      final leviathanDrop =
          currentMonster?.species == MonsterSpecies.ancientLeviathan ? 1 : 0;

      // Primordial Cinders drop strictly from Region Titans defeated under active Pact Burden
      final burden = profile.totalPactBurden;
      final cinderDrop = burden > 0
          ? switch (currentMonster?.species) {
              MonsterSpecies.kraken => 1 + (burden ~/ 2),
              MonsterSpecies.worldSerpent => 2 + (burden ~/ 2),
              MonsterSpecies.ancientLeviathan => 3 + burden,
              _ => 0,
            }
          : 0;

      profile.metaInventory.add(
        monsterBone: boneDrop,
        abyssalBarnacles: barnacleDrop,
        krakenBeak: krakenDrop,
        serpentScale: serpentDrop,
        leviathanCore: leviathanDrop,
        primordialCinders: cinderDrop,
      );

      events.add(MetaCurrenciesAwarded(
        monsterBone: boneDrop,
        abyssalBarnacles: barnacleDrop,
        krakenBeak: krakenDrop,
        serpentScale: serpentDrop,
        leviathanCore: leviathanDrop,
        primordialCinders: cinderDrop,
        reason: 'Harvested from ${currentMonster?.name ?? 'sea beast'}',
      ));
    }

    return events;
  }

  List<GameEvent> _resolvePlayerDeath() {
    final events = <GameEvent>[];
    ship?.resetCombatBoosts();
    runicGuidanceBoon = 0;
    gunneryAccuracyBoon = 0;
    lineage.recordDeath(CaptainRecord(
      captainName: captainName,
      shipName: ship!.name,
      shipClass: ship!.shipClass,
      monstersDefeated: monstersDefeatedThisLife,
      highestDifficultyReached: highestDifficultyThisLife,
      causeOfDeath: currentMonster?.name ?? 'The Undying Sea',
    ));

    // Empower Nemesis if slain by a monster
    if (currentMonster != null) {
      final nemesis = NemesisRecord.createFromDefeat(
        killer: currentMonster!,
        captainName: captainName.isNotEmpty ? captainName : 'Unknown Captain',
        regionIndex: seaChart.currentRegionIndex,
        rng: rng,
      );
      profile.activeNemesis = nemesis;
      events.add(NemesisSpawned(nemesis: nemesis));
    }

    // Generate 3 Heir Candidates for succession
    pendingHeirCandidates = generateHeirCandidates(
      rng: rng,
      previousCaptainName: captainName,
      nemesisSpecies: profile.activeNemesis?.species,
      count: 3,
    );

    final prevPhase = phase.displayName;
    phase = SessionPhase.death;

    events.add(PhaseChanged(
      previousPhase: prevPhase,
      newPhase: phase.displayName,
    ));
    events.add(CaptainLost(
      captainName: captainName,
      monstersDefeated: monstersDefeatedThisLife,
      highestDifficulty: highestDifficultyThisLife,
    ));
    return events;
  }

  List<GameEvent> _handleTakeLootItem(int lootIndex) {
    if (phase != SessionPhase.loot || ship == null) {
      throw StateError('Cannot take loot outside of loot phase');
    }
    if (lootIndex < 0 || lootIndex >= pendingLoot.length) {
      throw RangeError('Invalid loot index: $lootIndex');
    }
    final item = pendingLoot[lootIndex];
    if (ship!.addCargo(item)) {
      pendingLoot.removeAt(lootIndex);
      final events = <GameEvent>[ItemAcquired(item: item)];
      if (pendingLoot.isEmpty) {
        final prevPhase = phase.displayName;
        phase = SessionPhase.restArea;
        events.add(PhaseChanged(
          previousPhase: prevPhase,
          newPhase: phase.displayName,
        ));
      }
      return events;
    }
    return <GameEvent>[
      NarrationEvent('Cargo Hold is full! Cannot take ${item.name}'),
    ];
  }

  List<GameEvent> _handleTakeAllLoot() {
    if (phase != SessionPhase.loot || ship == null) {
      throw StateError('Cannot take loot outside of loot phase');
    }
    final events = <GameEvent>[];
    final itemsToKeep = <Item>[];

    for (final item in pendingLoot) {
      if (ship!.addCargo(item)) {
        events.add(ItemAcquired(item: item));
      } else {
        itemsToKeep.add(item);
      }
    }
    pendingLoot = itemsToKeep;
    if (pendingLoot.isEmpty) {
      final prevPhase = phase.displayName;
      phase = SessionPhase.restArea;
      events.add(PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ));
    }
    return events;
  }

  List<GameEvent> _handleLeaveRemainingLoot() {
    if (phase != SessionPhase.loot) {
      throw StateError('Cannot leave loot outside of loot phase');
    }
    pendingLoot.clear();
    final prevPhase = phase.displayName;
    phase = SessionPhase.restArea;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleDropCargo(int cargoIndex) {
    if (ship == null || cargoIndex < 0 || cargoIndex >= ship!.cargo.length) {
      throw RangeError('Invalid cargo index: $cargoIndex');
    }
    final dropped = ship!.cargo.removeAt(cargoIndex);
    return <GameEvent>[
      NarrationEvent('${dropped.name} jettisoned into the sea.'),
    ];
  }

  List<GameEvent> _handleEquipCargoWeapon(int cargoIndex) {
    if (ship == null || cargoIndex < 0 || cargoIndex >= ship!.cargo.length) {
      throw RangeError('Invalid cargo index: $cargoIndex');
    }
    final item = ship!.cargo[cargoIndex];
    if (item is! ShipWeapon) {
      throw ArgumentError('Item at index $cargoIndex is not a ship weapon');
    }
    if (ship!.equipWeapon(item)) {
      return <GameEvent>[
        NarrationEvent('${item.name} equipped.'),
      ];
    }
    return <GameEvent>[
      NarrationEvent('Cannot equip ${item.name}: no open deck hardpoints available.'),
    ];
  }

  List<GameEvent> _handleUnequipShipWeapon(int equippedIndex) {
    if (ship == null ||
        equippedIndex < 0 ||
        equippedIndex >= ship!.equippedWeapons.length) {
      throw RangeError('Invalid equipped index: $equippedIndex');
    }
    final weapon = ship!.equippedWeapons[equippedIndex];
    if (ship!.unequipWeapon(weapon)) {
      return <GameEvent>[
        NarrationEvent('${weapon.name} unequipped to cargo hold.'),
      ];
    }
    return <GameEvent>[
      NarrationEvent('No cargo hold space available to unequip ${weapon.name}.'),
    ];
  }

  List<GameEvent> _handleReturnToPort() {
    throw StateError('The home port is only available between voyages after succession');
  }

  List<GameEvent> _handleVisitMerchant() {
    if (phase != SessionPhase.port && phase != SessionPhase.stronghold) {
      throw StateError('Cannot visit merchant from $phase');
    }
    final prevPhase = phase.displayName;
    merchantReturnPhase = phase;
    phase = SessionPhase.merchant;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleLeaveMerchant() {
    if (phase != SessionPhase.merchant) {
      throw StateError('Cannot leave merchant from $phase');
    }
    final prevPhase = phase.displayName;
    phase = merchantReturnPhase;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleBuyMerchantItem(int stockIndex) {
    if ((phase != SessionPhase.merchant && phase != SessionPhase.smuggler) || ship == null) {
      throw StateError('Cannot buy items outside of merchant shop or smuggler ketch');
    }
    final stock = phase == SessionPhase.smuggler ? smugglerStock : merchantStock;
    if (stockIndex < 0 || stockIndex >= stock.length) {
      throw RangeError('Invalid stock index: $stockIndex');
    }
    final item = stock[stockIndex];
    final cost = phase == SessionPhase.smuggler ? item.value : getMerchantAskingPrice(stockIndex);
    if (buyItem(ship!, item, price: cost)) {
      stock.removeAt(stockIndex);
      if (phase == SessionPhase.merchant && onSaleMerchantIndex != null) {
        if (stockIndex == onSaleMerchantIndex) {
          onSaleMerchantIndex = null;
        } else if (stockIndex < onSaleMerchantIndex!) {
          onSaleMerchantIndex = onSaleMerchantIndex! - 1;
        }
      }
      return <GameEvent>[ItemAcquired(item: item)];
    }
    return <GameEvent>[
      NarrationEvent('Cannot purchase ${item.name}: insufficient gold or cargo.'),
    ];
  }

  List<GameEvent> _handleSellCargoItem(int cargoIndex) {
    if ((phase != SessionPhase.merchant && phase != SessionPhase.smuggler) || ship == null) {
      throw StateError('Cannot sell items outside of merchant shop or smuggler ketch');
    }
    if (cargoIndex < 0 || cargoIndex >= ship!.cargo.length) {
      throw RangeError('Invalid cargo index: $cargoIndex');
    }
    final item = ship!.cargo[cargoIndex];
    final goldEarned = item.value;
    if (sellItem(ship!, item)) {
      return <GameEvent>[ItemSold(item: item, goldEarned: goldEarned)];
    }
    return const <GameEvent>[];
  }

  List<GameEvent> _handleSellAllTreasure() {
    if (ship == null) throw StateError('No ship available');
    final (totalGold, itemsSold) = sellAllTreasure(ship!);
    return <GameEvent>[
      AllTreasureSold(totalGold: totalGold, itemsSold: itemsSold),
    ];
  }

  List<GameEvent> _handleRepairShip(double percentage) {
    if (ship == null) throw StateError('No ship available');

    // Smuggler repairs hull at sea using black market oak timbers (1.5x gold)
    if (phase == SessionPhase.smuggler) {
      final missingHp = ship!.maxHp - ship!.currentHp;
      final hpToHeal = min((ship!.maxHp * percentage).round(), missingHp);
      if (hpToHeal <= 0) {
        return const <GameEvent>[NarrationEvent('Hull is already sound.')];
      }
      final cost = (hpToHeal * 1.5).ceil();
      if (ship!.gold < cost) {
        return <GameEvent>[
          NarrationEvent('Smuggler demands $cost gold doubloons for oak timbers and pitch.'),
        ];
      }
      ship!.gold -= cost;
      ship!.heal(hpToHeal);
      return <GameEvent>[
        ShipRepaired(repairedHp: hpToHeal, goldCost: cost, newHp: ship!.currentHp),
        NarrationEvent('The smuggler crew patched hull breaches with seasoned oak planks (+$hpToHeal HP).'),
      ];
    }

    // In open sea rest area, open repairs are limited to Carpenter's Emergency Triage (<25% HP floor)
    if (phase == SessionPhase.restArea) {
      final criticalFloor = (ship!.maxHp * 0.25).ceil();
      if (ship!.currentHp >= criticalFloor) {
        return <GameEvent>[
          const NarrationEvent(
            'The open sea is too turbulent for routine repairs. Seek a Respite Island or voyage stronghold.',
          ),
        ];
      }
      final hpNeeded = criticalFloor - ship!.currentHp;
      final cost = hpNeeded * 2; // Emergency rate: 2g per HP
      if (ship!.gold < cost) {
        return <GameEvent>[
          NarrationEvent(
            'Insufficient gold for carpenter emergency triage ($cost gold needed).',
          ),
        ];
      }
      ship!.gold -= cost;
      ship!.heal(hpNeeded);
      return <GameEvent>[
        ShipRepaired(
          repairedHp: hpNeeded,
          goldCost: cost,
          newHp: ship!.currentHp,
        ),
        const NarrationEvent(
          "Carpenter's emergency triage patched the hull to the 25% seaworthy floor.",
        ),
      ];
    }

    final baseCost = calculateRepairCost(ship!, percentage);
    if (baseCost <= 0) {
      return <GameEvent>[
        NarrationEvent('${ship!.name} needs no repairs!'),
      ];
    }
    final brittleOak = profile.isPactActive(CovenantPactId.brittleOak);
    final cost = brittleOak ? (baseCost * 1.30).ceil() : baseCost;
    if (ship!.gold < cost) {
      return <GameEvent>[
        NarrationEvent('Insufficient gold to repair ${ship!.name}.'),
      ];
    }
    ship!.gold -= cost;
    ship!.heal(baseCost);
    return <GameEvent>[
      ShipRepaired(repairedHp: baseCost, goldCost: cost, newHp: ship!.currentHp),
    ];
  }

  List<GameEvent> _handleUpgradeShip() {
    if (ship == null) throw StateError('No ship available');
    if (phase != SessionPhase.respiteIsland && phase != SessionPhase.stronghold) {
      throw StateError('Ship refits are only available at a voyage Haven or stronghold');
    }
    if (phase == SessionPhase.respiteIsland && !isCurrentIslandHaven) {
      return const <GameEvent>[
        NarrationEvent('No traveling shipwright dwells on this secluded atoll to refit your vessel.'),
      ];
    }
    final currentLevel = ship!.level;
    if (currentLevel >= 4) {
      return <GameEvent>[
        NarrationEvent('${ship!.name} has reached maximum naval refit tier (Level 4)!'),
      ];
    }
    final cost = calculateShipUpgradeCost(currentLevel);
    if (ship!.gold < cost) {
      return <GameEvent>[
        NarrationEvent('Insufficient gold to refit ${ship!.name} (Requires ${cost}g, have ${ship!.gold}g).'),
      ];
    }

    ship!.gold -= cost;
    upgradeShipState(ship!);

    return <GameEvent>[
      ShipUpgraded(
        ship: ship!,
        newLevel: ship!.level,
        goldCost: cost,
      ),
    ];
  }

  List<GameEvent> _handleTemperHardpoint(HardpointType slot) {
    if (ship == null) throw StateError('No ship available');
    if (phase != SessionPhase.respiteIsland && phase != SessionPhase.stronghold) {
      throw StateError('Hardpoint tempering is only available at a voyage Haven or stronghold');
    }
    if (phase == SessionPhase.respiteIsland && !isCurrentIslandHaven) {
      return const <GameEvent>[
        NarrationEvent('No master armourer dwells on this secluded atoll to temper your hardpoints.'),
      ];
    }
    final canonical = slot.canonical;
    final currentMark = ship!.markForHardpoint(canonical);
    if (currentMark >= 3) {
      return <GameEvent>[
        NarrationEvent('${canonical.displayName} hardpoint has already reached maximum temper (Mk III)!'),
      ];
    }
    final cost = calculateHardpointTemperCost(currentMark);
    if (ship!.gold < cost) {
      return <GameEvent>[
        NarrationEvent(
          'Insufficient gold to temper ${canonical.displayName} hardpoint (Requires ${cost}g, have ${ship!.gold}g).',
        ),
      ];
    }

    ship!.gold -= cost;
    temperShipHardpoint(ship!, canonical);
    final newMark = ship!.markForHardpoint(canonical);

    return <GameEvent>[
      HardpointTempered(
        slot: canonical,
        newMark: newMark,
        goldCost: cost,
      ),
      NarrationEvent(
        'Tempered ${canonical.displayName} mount to ${ship!.markLabelForHardpoint(canonical)} (+20% base potency)!',
      ),
    ];
  }

  List<GameEvent> _handleCareenHullAtIsland() {
    if (phase != SessionPhase.respiteIsland || ship == null) {
      throw StateError('Cannot careen hull outside of respite island');
    }
    if (hasChosenIslandDuty) {
      return const <GameEvent>[
        NarrationEvent("The crew's shore duty is already spent on this island haven; tides compel the ship to depart."),
      ];
    }
    final careenPct = isCurrentIslandHaven ? 0.30 : 0.20;
    var healAmount = min(
      (ship!.maxHp * careenPct).round(),
      ship!.maxHp - ship!.currentHp,
    );
    if (activeQuirk?.id == BloodlineTraitId.saltAddict) {
      healAmount = (healAmount * 0.75).round();
    }
    if (profile.isPactActive(CovenantPactId.brittleOak)) {
      healAmount = (healAmount * 0.75).round();
    }
    if (healAmount <= 0) {
      return const <GameEvent>[
        NarrationEvent('Hull timbers are already in pristine condition!'),
      ];
    }
    ship!.heal(healAmount);
    hasCareenedAtCurrentIsland = true;
    return <GameEvent>[
      HullCareened(repairedHp: healAmount, newHp: ship!.currentHp),
      NarrationEvent(
        isCurrentIslandHaven
            ? 'The shipwrights careened the hull in the calm shallows of the Grand Haven, caulking seams with oakum and pitch (+$healAmount HP).'
            : 'The crew careened the hull on the sands of the secluded cove, caulking the worst breaches with driftwood pitch (+$healAmount HP).',
      ),
    ];
  }

  List<GameEvent> _handleDrillGunnersAtIsland() {
    if (phase != SessionPhase.respiteIsland || ship == null) {
      throw StateError('Cannot drill gunners outside of respite island');
    }
    if (hasChosenIslandDuty) {
      return const <GameEvent>[
        NarrationEvent("The crew's shore duty is already spent on this island haven; tides compel the ship to depart."),
      ];
    }
    gunneryAccuracyBoon = 15 + runicGuidanceBoon;
    hasDrilledAtCurrentIsland = true;
    return const <GameEvent>[
      GunnersDrilled(bonusHitChance: 15),
      NarrationEvent(
        'Gunners sighted their cannons and practiced volleys (+15% accuracy boon on next engagement).',
      ),
    ];
  }

  List<GameEvent> _handleForageShoalsAtIsland() {
    if (phase != SessionPhase.respiteIsland || ship == null) {
      throw StateError('Cannot forage shoals outside of respite island');
    }
    if (hasChosenIslandDuty) {
      return const <GameEvent>[
        NarrationEvent("The crew's shore duty is already spent on this island haven; tides compel the ship to depart."),
      ];
    }
    final bounty = isCurrentIslandHaven
        ? rng.nextIntRange(40, 60)
        : rng.nextIntRange(25, 35);
    ship!.gold += bounty;
    hasForagedAtCurrentIsland = true;
    return <GameEvent>[
      IslandForaged(goldFound: bounty),
      NarrationEvent(
        isCurrentIslandHaven
            ? 'The landing party foraged the haven shoals and trading drift, recovering $bounty gold doubloons.'
            : 'The landing party scavenged the cove beach and tide pools, recovering $bounty gold doubloons.',
      ),
    ];
  }

  List<GameEvent> _handleDepartIsland() {
    if (phase != SessionPhase.respiteIsland) {
      throw StateError('Cannot depart island from $phase');
    }
    return _handleTakeHelm();
  }

  List<GameEvent> _handleSalvageShipwreck(ShipwreckChoice choice) {
    if (phase != SessionPhase.shipwreck || ship == null) {
      throw StateError('Cannot salvage shipwreck outside of shipwreck encounter');
    }
    if (hasSalvagedCurrentWreck) {
      return const <GameEvent>[
        NarrationEvent('The derelict hull has already been picked clean.'),
      ];
    }
    hasSalvagedCurrentWreck = true;
    final events = <GameEvent>[];

    switch (choice) {
      case ShipwreckChoice.munitions:
        final itemLevel = max(1, seaChart.currentDifficulty);
        final item = randomConsumable(itemLevel, rng);
        if (ship!.cargo.length < ship!.maxCargo) {
          ship!.addCargo(item);
          events.add(ItemAcquired(item: item));
        } else {
          pendingLoot.add(item);
        }
        if (seaChart.currentRegionIndex >= 1 && rng.nextInt(100) < 50) {
          profile.metaInventory.add(depthWroughtIron: 1);
          events.add(const MetaCurrenciesAwarded(
            depthWroughtIron: 1,
            reason: 'Salvaged depth-wrought iron plating from wreck',
          ));
        }
        events.add(ShipwreckSalvaged(
          flavorMessage: 'Recovered military-grade ${item.name} from the shattered armory!',
          choice: choice,
        ));

      case ShipwreckChoice.strongbox:
        final bounty = rng.nextIntRange(60, 120);
        ship!.gold += bounty;
        final seaGlass = rng.nextIntRange(2, 4);
        profile.metaInventory.add(seaGlass: seaGlass);
        events.add(ShipwreckSalvaged(
          flavorMessage: "Cracked the captain's iron lockbox and salvaged $bounty gold doubloons!",
          choice: choice,
        ));
        events.add(MetaCurrenciesAwarded(
          seaGlass: seaGlass,
          reason: 'Salvaged sea glass from strongbox',
        ));

      case ShipwreckChoice.timbers:
        final rawHeal = min(
          (ship!.maxHp * 0.25).round(),
          ship!.maxHp - ship!.currentHp,
        );
        var heal = activeQuirk?.id == BloodlineTraitId.saltAddict
            ? (rawHeal * 0.75).round()
            : rawHeal;
        if (profile.isPactActive(CovenantPactId.brittleOak)) {
          heal = (heal * 0.75).round();
        }
        ship!.heal(heal);
        final seaGlass = rng.nextIntRange(1, 2);
        profile.metaInventory.add(seaGlass: seaGlass);
        events.add(ShipwreckSalvaged(
          flavorMessage: 'Stripped stout oak and copper plating from the wreck, restoring $heal HP to hull!',
          choice: choice,
        ));
        events.add(MetaCurrenciesAwarded(
          seaGlass: seaGlass,
          reason: 'Recovered sea glass lodged in timbers',
        ));
    }

    return events;
  }

  List<GameEvent> _handleClaimExpeditionVictory() {
    return _handleResolveCalderaClimax(CalderaClimaxChoice.shatterCore);
  }

  List<GameEvent> _handleResolveCalderaClimax(CalderaClimaxChoice choice) {
    if (phase != SessionPhase.expeditionVictory) {
      throw StateError('Cannot resolve caldera climax from $phase');
    }

    switch (choice) {
      case CalderaClimaxChoice.shatterCore:
        // Consume the Leviathan Core to detonate and collapse the Abyssal Font
        if (profile.metaInventory.leviathanCore > 0) {
          profile.metaInventory.spend(leviathanCore: 1);
        }
        profile.hasShatteredFont = true;
        final prevPhase = phase.displayName;
        phase = SessionPhase.ended;
        const narrative =
            'The Leviathan Core shatters inside the hydrothermal fissure! The Abyssal Font implodes, quenching the birthplace of monsters forever and lifting the salt-sickness from your bloodline.';
        return <GameEvent>[
          PhaseChanged(previousPhase: prevPhase, newPhase: phase.displayName),
          CalderaClimaxResolved(
            choice: choice,
            captainName: captainName,
            narrative: narrative,
          ),
          NarrationEvent(
            'Captain $captainName has conquered The Monstrous Sea! $narrative',
          ),
        ];

      case CalderaClimaxChoice.claimCore:
        // Retain the Core, unlock the Covenant of the Deep, and loop to the next heir
        profile.hasUnlockedCovenant = true;
        profile.ascensionLoopCount++;
        lineage.recordDeath(CaptainRecord(
          captainName: captainName,
          shipName: ship?.name ?? 'Flagship',
          shipClass: ship?.shipClass ?? ShipClass.standard,
          monstersDefeated: monstersDefeatedThisLife,
          highestDifficultyReached: highestDifficultyThisLife,
          causeOfDeath: 'Ascended as Warden of the Primordial Caldera',
        ));
        pendingHeirCandidates = generateHeirCandidates(
          rng: rng,
          previousCaptainName: captainName,
          nemesisSpecies: profile.activeNemesis?.species,
          count: 3,
        );
        final prevPhase = phase.displayName;
        phase = SessionPhase.death;
        const narrative =
            'Overcome by deep-sea madness, the captain claims the Primordial Core! The flagship returns alone to harbor with the glowing Core fused into its keel, awakening the Covenant of the Deep.';
        return <GameEvent>[
          PhaseChanged(previousPhase: prevPhase, newPhase: phase.displayName),
          CalderaClimaxResolved(
            choice: choice,
            captainName: captainName,
            narrative: narrative,
          ),
          const NarrationEvent(narrative),
        ];
    }
  }

  static const List<String> _islandAdjectives = [
    'Sheltered',
    'Whispering',
    'Cormorant',
    'Barnacle',
    "Smuggler's",
    'Seagull',
    'Fogbound',
    'Sunken',
    'Coral',
    'Osprey',
  ];

  static const List<String> _islandNouns = [
    'Shoal',
    'Key',
    'Spit',
    'Atoll',
    'Haven',
    'Cove',
    'Reach',
    'Reef',
  ];

  String _generateIslandName() {
    final adj = _islandAdjectives[rng.nextInt(_islandAdjectives.length)];
    final noun = _islandNouns[rng.nextInt(_islandNouns.length)];
    return '$adj $noun';
  }

  static const List<String> _shipwreckNames = [
    'The Forsaken Galleon',
    'Derelict of the Mary Celeste',
    'The Shattered Caravel',
    'The Ghost Brigantine',
    'Wreck of the Black Pearl',
    "The Sea Rover's Ruin",
    'Hulk of the Albatross',
  ];

  String _generateShipwreckName() {
    return _shipwreckNames[rng.nextInt(_shipwreckNames.length)];
  }

  List<GameEvent> _handleDepartSmuggler() {
    if (phase != SessionPhase.smuggler) {
      throw StateError('Cannot depart smuggler from $phase');
    }
    return _handleTakeHelm();
  }

  List<GameEvent> _handleAcceptShrineBlessing(OceanPower power, HardpointType slot) {
    if (phase != SessionPhase.shrine || ship == null) {
      throw StateError('Cannot accept a blessing outside of shrine phase');
    }
    if (hasCommunedAtCurrentShrine) {
      return const [
        NarrationEvent('The altar has gone cold; its blessing is already bestowed.'),
      ];
    }
    if (!shrineManifestedPowers.contains(power)) {
      throw StateError('That Primordial has not manifested at this shrine');
    }
    final blessing = previewShrineBlessing(ship!, power, slot);
    if (blessing == null) {
      throw StateError(
          'This hardpoint is dedicated to another power or already sovereign');
    }
    ship!.blessings[slot] = blessing;
    hasCommunedAtCurrentShrine = true;
    return [
      NarrationEvent('${blessing.title}: ${blessing.tierLabel}. ${blessing.description}'),
    ];
  }

  List<GameEvent> _handleCommuneWithShrine(ShrineChoice choice) {
    if (phase != SessionPhase.shrine || ship == null) {
      throw StateError('Cannot commune at shrine outside of shrine phase');
    }
    if (hasCommunedAtCurrentShrine && choice != ShrineChoice.leave) {
      return const <GameEvent>[
        NarrationEvent('The altar has gone cold; the spirits accept no further offerings.'),
      ];
    }
    final events = <GameEvent>[];
    switch (choice) {
      case ShrineChoice.tribute:
        if (ship!.gold < 30) {
          return const <GameEvent>[
            NarrationEvent('The shrine demands an offering of 30 gold doubloons to grant the sea\'s favor.'),
          ];
        }
        ship!.gold -= 30;
        hasCommunedAtCurrentShrine = true;
        gunneryAccuracyBoon += 15;
        events.add(ShrineCommuned(
          shrineName: currentShrineName,
          choice: choice,
          outcomeNarrative: 'Golden coins sink into the deep. A gentle following wind guides your guns (+15% accuracy boon).',
        ));
      case ShrineChoice.abyssalPact:
        if (activeQuirk?.id == BloodlineTraitId.superstitious) {
          return const <GameEvent>[
            NarrationEvent(
              "Superstitious captain recoils in dread, refusing to sign away the bloodline's soul to the abyss!",
            ),
          ];
        }
        final damage = (ship!.maxHp * 0.20).round();
        if (ship!.currentHp <= damage) {
          return const <GameEvent>[
            NarrationEvent('Your hull is too fractured to endure the abyssal pact without foundering!'),
          ];
        }
        ship!.applyDamage(damage);
        hasCommunedAtCurrentShrine = true;
        final relic = randomConsumable(seaChart.currentDifficulty + 1, rng);
        if (ship!.cargo.length < ship!.maxCargo) {
          ship!.addCargo(relic);
          events.add(ItemAcquired(item: relic));
        } else {
          pendingLoot.add(relic);
        }
        events.add(ShrineCommuned(
          shrineName: currentShrineName,
          choice: choice,
          outcomeNarrative: 'Timbers groan and splinter (-$damage HP)! From the foaming brine, the deep bestows ${relic.name}.',
        ));
      case ShrineChoice.ancientRunes:
        hasCommunedAtCurrentShrine = true;
        final nextRow = seaChart.currentRow + 1;
        seaChart.revealRow(nextRow);
        gunneryAccuracyBoon = gunneryAccuracyBoon - runicGuidanceBoon + 10;
        runicGuidanceBoon = 10;
        events.add(ShrineCommuned(
          shrineName: currentShrineName,
          choice: choice,
          outcomeNarrative: 'The runes glow with phosphorescence! The fog lifts across the soundings ahead, and the crew charts safe passage (+10% accuracy boon).',
        ));
      case ShrineChoice.leave:
        return _handleDepartShrine();
    }
    return events;
  }

  List<GameEvent> _handleDepartShrine() {
    if (phase != SessionPhase.shrine) {
      throw StateError('Cannot depart shrine from $phase');
    }
    return _handleTakeHelm();
  }

  static const List<String> _smugglerAdjectives = [
    'The Shadowed',
    "Cutthroat's",
    'The Midnight',
    'The Salt-Stained',
    'Corsair\'s',
    'The Gilded',
    'The Phantom',
    'The Smuggler\'s',
  ];

  static const List<String> _smugglerTypes = [
    'Ketch',
    'Brigantine',
    'Barque',
    'Skiff',
    'Sloop',
    'Pinnace',
  ];

  String _generateSmugglerName() {
    final adj = _smugglerAdjectives[rng.nextInt(_smugglerAdjectives.length)];
    final type = _smugglerTypes[rng.nextInt(_smugglerTypes.length)];
    return '$adj $type';
  }

  static const List<String> _shrineTitles = [
    'Shrine of the Abyssal Siren',
    'Monolith of the North Star',
    'Altar of the Ancient Tides',
    'The Phosphor Spire',
    'The Drowned Mariner\'s Obelisk',
    'Pillar of the Leviathan',
    'Sanctum of the Weeping Coral',
  ];

  String _generateShrineName() {
    return _shrineTitles[rng.nextInt(_shrineTitles.length)];
  }

  String _generateShrineLore() {
    final region = seaChart.currentRegionIndex;
    if (region == 0) {
      const lore = [
        'Runes carved into barnacled basalt: "Beware the Siren Shoals, where sweet voices mask the crushing embrace of the multi-tentacled Kraken."',
        'Ancient logbook scrap embedded in coral: "We charted seven reefs before the beast struck. The cannons shattered its tentacles, yet deeper perils lie beyond."',
        'Petrified ship wheel inscribed with gold leaf: "Hunter\'s Respite was once a fortress of twelve ships. Only one returned from the Leviathan Trench."',
      ];
      return lore[rng.nextInt(lore.length)];
    } else if (region == 1) {
      const lore = [
        'Etched into petrified drift-kelp: "The Sargasso Drift has swallowed an armada of ghost galleons. The World Serpent encircles their bones in phosphorescent coils."',
        'Runic brass compass pointing into the fog: "He who strikes the serpent\'s flank with piercing ordnance shall pierce its coiling evasion."',
        'Inscribed upon a shattered figurehead: "We were stalled three weeks in the doldrums before the sea began to churn with venom."',
      ];
      return lore[rng.nextInt(lore.length)];
    } else {
      const lore = [
        'Carved into smoking obsidian: "The Boiling Reach is the crucible of the deep. Steam vents hide the Ancient Leviathan whose scales withstand any normal blast."',
        'Iron plaque scorched by sulfurous fire: "Only heavy broadsides and tempered hulls will endure the thermal calderas of the final domain."',
        'Ancient mariner proverb carved in stone: "The monster shall perish, and the captain\'s glory shall endure across the age of sail."',
      ];
      return lore[rng.nextInt(lore.length)];
    }
  }

  List<GameEvent> _handleContinueLineage(
    String heirName,
    ShipClass chosenClass, {
    BloodlineTrait? boon,
    BloodlineTrait? quirk,
  }) {
    if (phase != SessionPhase.death || ship == null) {
      throw StateError('Cannot continue lineage outside of death phase');
    }
    final blueprintId = BlueprintId.fromShipClass(chosenClass);
    if (!profile.isBlueprintUnlocked(blueprintId)) {
      throw StateError('Blueprint $blueprintId is not unlocked');
    }
    captainName = heirName;
    activeBoon = boon;
    activeQuirk = quirk;
    pendingHeirCandidates = <HeirCandidate>[];

    final previousShip = ship!;
    final armamentTier = profile.armamentTierFor(blueprintId);
    final heirShip = createFlagshipFromBlueprint(
      blueprintId,
      level: 1,
      rng: rng,
      armamentTier: armamentTier,
      hasExpandedAuxiliarySlot: profile.hasExpandedAuxiliarySlot,
      bonusMaxHp: profile.monumentBonusMaxHp,
    )..shipClass = chosenClass;

    if (previousShip.shipClass == ShipClass.freighter ||
        previousShip.shipClass == ShipClass.corsair) {
      heirShip.gold = (previousShip.gold * 0.05).toInt();
      for (final item in previousShip.cargo) {
        if (heirShip.cargo.length < heirShip.maxCargo) {
          heirShip.cargo.add(item);
        } else {
          break;
        }
      }
    } else {
      heirShip.gold = 25;
      heirShip.cargo.clear();
    }
    ship = heirShip;
    monstersDefeatedThisLife = 0;
    highestDifficultyThisLife = 0;
    seaChart.reset(resetMaxRow: true);
    refreshMerchantStock(1);

    final prevPhase = phase.displayName;
    phase = SessionPhase.port;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
      HeirSelected(
        heirName: heirName,
        chosenClass: chosenClass,
        boon: boon,
        quirk: quirk,
      ),
    ];
  }

  List<GameEvent> _handleAbandonHunt() {
    if (phase != SessionPhase.death) {
      throw StateError('Cannot abandon hunt outside of death phase');
    }
    final prevPhase = phase.displayName;
    phase = SessionPhase.ended;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
      NarrationEvent(
        'The Undying Sea has prevailed, but no longer shall the Hunt consume your lineage...',
      ),
    ];
  }
}

extension _StringCaseExtension on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}
