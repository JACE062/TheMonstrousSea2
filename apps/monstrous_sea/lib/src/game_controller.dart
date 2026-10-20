import 'package:flutter/foundation.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'services/storage_service.dart';

/// Central presentation coordinator bridging the Flutter UI and Flame battle scene
/// to the pure domain [GameSession].
class GameController extends ChangeNotifier {
  GameController({
    GameSession? session,
    StorageService? storage,
    this.autoSave = true,
  })  : session = session ?? GameSession(),
        storage = storage ?? StorageService(),
        narrationFormatter = const NarrationFormatter();

  final GameSession session;
  final StorageService storage;
  final NarrationFormatter narrationFormatter;
  final bool autoSave;

  final List<CombatLogEntry> structuredCombatLog = <CombatLogEntry>[];
  List<String> get combatLog =>
      structuredCombatLog.map((e) => e.message).toList();
  List<GameEvent> lastEvents = <GameEvent>[];
  bool isPlayingEvents = false;

  SessionPhase get phase => session.phase;
  ShipState? get ship => session.ship;
  MonsterState? get currentMonster => session.currentMonster;
  String get captainName => session.captainName;
  SeaChart get seaChart => session.seaChart;
  LineageTracker get lineage => session.lineage;
  ProfileData get profile => session.profile;
  MetaInventory get metaInventory => session.profile.metaInventory;
  NemesisRecord? get activeNemesis => session.profile.activeNemesis;
  List<HeirCandidate> get pendingHeirCandidates => session.pendingHeirCandidates;
  BloodlineTrait? get activeBoon => session.activeBoon;
  BloodlineTrait? get activeQuirk => session.activeQuirk;
  bool get isNemesisBattle => session.isNemesisBattle;
  List<Item> get pendingLoot => session.pendingLoot;
  List<Item> get merchantStock => session.merchantStock;
  int get lastGoldSalvaged => session.lastGoldSalvaged;

  bool get isRespiteIsland => session.seaChart.isRespiteIsland;
  bool get isShipwreck => session.seaChart.isShipwreck;
  bool get isSmugglerTrader => session.seaChart.isSmugglerTrader;
  bool get isAncientShrine => session.seaChart.isAncientShrine;
  bool get isRegionTitan => session.seaChart.isRegionTitan;
  bool get isFinalTitan => session.seaChart.isFinalTitan;
  String get currentRegionName => session.seaChart.currentRegionName;
  String get currentRegionSubtitle => session.seaChart.currentRegionSubtitle;
  String get currentIslandName => session.currentIslandName;
  String get currentShipwreckName => session.currentShipwreckName;
  String get currentSmugglerName => session.currentSmugglerName;
  List<Item> get smugglerStock => session.smugglerStock;
  String get currentShrineName => session.currentShrineName;
  String get currentShrineLore => session.currentShrineLore;
  List<OceanPower> get shrineManifestedPowers => session.shrineManifestedPowers;
  bool get hasCareenedAtCurrentIsland => session.hasCareenedAtCurrentIsland;
  bool get hasDrilledAtCurrentIsland => session.hasDrilledAtCurrentIsland;
  bool get hasSalvagedCurrentWreck => session.hasSalvagedCurrentWreck;
  bool get hasCommunedAtCurrentShrine => session.hasCommunedAtCurrentShrine;
  int get gunneryAccuracyBoon => session.gunneryAccuracyBoon;
  bool get canEmergencyRepairAtSea => session.canEmergencyRepairAtSea;
  int get emergencyRepairCost => session.emergencyRepairCost;
  CombatRange get combatRange => session.combatRange;

  /// Returns true if the encounter at the sea chart coordinate has been slain
  /// (e.g. during loot or rest area).
  bool get isCurrentEncounterDefeated =>
      phase == SessionPhase.restArea ||
      phase == SessionPhase.loot ||
      (currentMonster != null && !currentMonster!.isAlive);

  /// Dispatches [command] to domain engine, processes resulting events into logs,
  /// triggers persistence if enabled, and notifies UI listeners.
  List<GameEvent> dispatch(Command command, {bool deferNotification = false}) {
    final events = session.dispatch(command);
    lastEvents = events;

    for (final event in events) {
      final entry = _formatEventForLog(event);
      if (entry != null && entry.message.isNotEmpty) {
        structuredCombatLog.add(entry);
      }
    }

    if (autoSave) {
      _handleAutoSave(command, events);
    }

    if (!deferNotification) {
      notifyListeners();
    }
    return events;
  }

  /// Initializes the controller by loading persisted profile data and restoring any active voyage.
  Future<void> initializeStorage() async {
    final loadedProfile = await storage.loadProfile();
    session.profile = loadedProfile;

    final activeVoyage = await storage.loadVoyage();
    if (activeVoyage != null) {
      activeVoyage.restoreToSession(session);
    }
    notifyListeners();
  }

  /// Persists current profile and voyage states to disk.
  Future<void> persistState() async {
    await storage.saveProfile(session.profile);
    if (phase == SessionPhase.death || phase == SessionPhase.port) {
      await storage.clearVoyage();
    } else if (phase == SessionPhase.helm ||
        phase == SessionPhase.restArea ||
        phase == SessionPhase.respiteIsland) {
      final snapshot = VoyageSaveData.fromSession(session);
      await storage.saveVoyage(snapshot);
    }
  }

  void _handleAutoSave(Command command, List<GameEvent> events) {
    persistState().catchError((error) {
      debugPrint('GameController persistence error: $error');
    });
  }

  /// Triggers a state notification to subscribers (e.g. after animation settle).
  void notify() => notifyListeners();

  void setIsPlayingEvents(bool playing) {
    isPlayingEvents = playing;
    notifyListeners();
  }

  void clearLog() {
    structuredCombatLog.clear();
    notifyListeners();
  }

  CombatLogEntry? _formatEventForLog(GameEvent event) {
    return switch (event) {
      BattleStarted(:final monsterName, :final difficulty, :final isBoss) => CombatLogEntry(
          message: isBoss
              ? 'THE KRAKEN RISES FROM THE ABYSS! Prepare all guns!'
              : 'Encountered $monsterName (Danger Level $difficulty)!',
          actor: CombatLogActor.ambient,
          isCritical: isBoss,
        ),
      AttackHit(:final targetName, :final damage, :final damageType) =>
        damage == 0
            ? null
            : (targetName == currentMonster?.name
                ? CombatLogEntry(
                    message: '$targetName was struck for $damage $damageType damage!',
                    actor: CombatLogActor.ship,
                  )
                : CombatLogEntry(
                    message: '$targetName was struck for $damage $damageType damage!',
                    actor: CombatLogActor.monster,
                    isCritical: true,
                  )),
      AttackMissed(:final targetName) =>
        targetName == currentMonster?.name
            ? CombatLogEntry(
                message: 'The shot missed $targetName!',
                actor: CombatLogActor.ship,
              )
            : CombatLogEntry(
                message: 'The beast\'s attack missed $targetName!',
                actor: CombatLogActor.monster,
              ),
      AttackEvaded(:final shipName, :final wasManeuver) => CombatLogEntry(
          message: '$shipName swiftly evaded incoming strike${wasManeuver ? ' via evasive maneuvers' : ''}!',
          actor: CombatLogActor.ship,
        ),
      DamageReduced(:final shipName, :final nullifiedAmount) => CombatLogEntry(
          message: '$shipName\'s reinforced plating absorbed $nullifiedAmount damage!',
          actor: CombatLogActor.ship,
        ),
      TentaclesSevered(:final countSevered, :final remainingTentacles) => CombatLogEntry(
          message: 'Severed $countSevered tentacles! ($remainingTentacles remaining)',
          actor: CombatLogActor.ship,
        ),
      InkCloudDeployed(:final monsterName, :final acBonus) => CombatLogEntry(
          message: '$monsterName spewed a dense ink cloud! (+$acBonus AC)',
          actor: CombatLogActor.monster,
        ),
      CarapaceAbsorbed(:final monsterName, :final absorbedAmount, :final penetratingDamage) => CombatLogEntry(
          message: penetratingDamage > 0
              ? '$monsterName\'s carapace deflected $absorbedAmount damage ($penetratingDamage penetrated to vitality)!'
              : '$monsterName\'s thick carapace deflected the strike completely ($absorbedAmount damage absorbed)!',
          actor: CombatLogActor.monster,
        ),
      CarapaceDamaged(:final monsterName, :final damageDealt, :final remainingCarapace, :final wasShattered) =>
        wasShattered
            ? CombatLogEntry(
                message: 'CRACK! Explosive blast SHATTERED $monsterName\'s carapace armor! The beast is now vulnerable!',
                actor: CombatLogActor.ship,
                isCritical: true,
              )
            : CombatLogEntry(
                message: 'Explosive blast blasted $damageDealt carapace plating off $monsterName ($remainingCarapace plating remaining)!',
                actor: CombatLogActor.ship,
              ),
      SharkFrenzyRoared(:final monsterName, :final stacks) => CombatLogEntry(
          message: '$monsterName roared with primal fury! (Frenzy x$stacks)',
          actor: CombatLogActor.monster,
          isCritical: true,
        ),
      SharkFrenzyDisrupted(:final monsterName) => CombatLogEntry(
          message: 'Shock disrupted $monsterName\'s frenzy!',
          actor: CombatLogActor.ship,
        ),
      SerpentSlithered(:final monsterName) => CombatLogEntry(
          message: '$monsterName slithered into evasive coils!',
          actor: CombatLogActor.monster,
        ),
      StatusEffectTicked(:final targetName, :final effectName, :final damage, :final woreOff) =>
        targetName == currentMonster?.name
            ? CombatLogEntry(
                message: '$targetName suffers $damage from $effectName${woreOff ? ' (cleared)' : ''}!',
                actor: CombatLogActor.ship,
              )
            : CombatLogEntry(
                message: '$targetName suffers $damage from $effectName${woreOff ? ' (cleared)' : ''}!',
                actor: CombatLogActor.monster,
              ),
      CombatantDefeated(:final name, :final flavorMessage) =>
        name == currentMonster?.name
            ? CombatLogEntry(
                message: '$name was defeated! $flavorMessage',
                actor: CombatLogActor.ship,
                isCritical: true,
              )
            : CombatLogEntry(
                message: '$name was defeated! $flavorMessage',
                actor: CombatLogActor.monster,
                isCritical: true,
              ),
      MonsterHesitated(:final monsterName) => CombatLogEntry(
          message: '$monsterName hesitated, gathering its fury.',
          actor: CombatLogActor.monster,
        ),
      LootDropped(:final items, :final goldSalvaged) => CombatLogEntry(
          message: goldSalvaged > 0
              ? 'Spoils salvaged: $goldSalvaged gold doubloons and ${items.length} item${items.length == 1 ? '' : 's'} recovered!'
              : 'Spoils salvaged: ${items.length} item${items.length == 1 ? '' : 's'} recovered!',
          actor: CombatLogActor.ambient,
        ),
      ItemAcquired(:final item) => CombatLogEntry(
          message: 'Stowed ${item.name} into cargo hold.',
          actor: CombatLogActor.ambient,
        ),
      ItemSold(:final item, :final goldEarned) => CombatLogEntry(
          message: 'Sold ${item.name} for ${goldEarned}g.',
          actor: CombatLogActor.ambient,
        ),
      AllTreasureSold(:final totalGold, :final itemsSold) => CombatLogEntry(
          message: 'Exchanged $itemsSold treasures for ${totalGold}g.',
          actor: CombatLogActor.ambient,
        ),
      ShipRepaired(:final repairedHp, :final goldCost) => CombatLogEntry(
          message: 'Repaired $repairedHp hull points for ${goldCost}g.',
          actor: CombatLogActor.ambient,
        ),
      ShipUpgraded(:final ship, :final newLevel, :final goldCost) => CombatLogEntry(
          message: 'Refitted ${ship.name} to Tier $newLevel for ${goldCost}g.',
          actor: CombatLogActor.ambient,
          isCritical: true,
        ),
      CaptainLost(:final captainName, :final monstersDefeated) => CombatLogEntry(
          message: 'Captain $captainName has perished in the watery deep ($monstersDefeated monsters slain).',
          actor: CombatLogActor.ambient,
          isCritical: true,
        ),
      RespiteIslandReached(:final islandName) => CombatLogEntry(
          message: 'Anchored at sheltered haven: $islandName.',
          actor: CombatLogActor.ambient,
        ),
      HullCareened(:final repairedHp) => CombatLogEntry(
          message: 'Careened hull in the shallows, restoring $repairedHp vitality.',
          actor: CombatLogActor.ship,
        ),
      GunnersDrilled(:final bonusHitChance) => CombatLogEntry(
          message: 'Gunners drilled pattern volleys (+$bonusHitChance% accuracy boon).',
          actor: CombatLogActor.ship,
        ),
      IslandForaged(:final goldFound) => CombatLogEntry(
          message: 'Crew foraged hidden shoals, recovering $goldFound gold doubloons.',
          actor: CombatLogActor.ship,
        ),
      ShipwreckDiscovered(:final shipwreckName) => CombatLogEntry(
          message: 'Spotted floating derelict: $shipwreckName.',
          actor: CombatLogActor.ambient,
        ),
      ShipwreckSalvaged(:final flavorMessage) => CombatLogEntry(
          message: flavorMessage,
          actor: CombatLogActor.ambient,
        ),
      RegionTransitioned(:final newRegion) => CombatLogEntry(
          message: 'VOYAGE EXPEDITION ADVANCES: Entering $newRegion!',
          actor: CombatLogActor.ambient,
          isCritical: true,
        ),
      ExpeditionWon(:final captainName, :final monstersDefeated, :final goldAmassed) => CombatLogEntry(
          message:
              'GRAND EXPEDITION VICTORY: Captain $captainName conquered The Monstrous Sea! ($monstersDefeated beasts slain, ${goldAmassed}g amassed)',
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      SmugglerEncountered(:final smugglerName) => CombatLogEntry(
          message: 'Spotted wandering merchant ketch: $smugglerName.',
          actor: CombatLogActor.ambient,
        ),
      ShrineDiscovered(:final shrineName) => CombatLogEntry(
          message: 'Beheld ancient sea shrine: $shrineName.',
          actor: CombatLogActor.ambient,
          isCritical: true,
        ),
      ShrineCommuned(:final outcomeNarrative) => CombatLogEntry(
          message: outcomeNarrative,
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      ThermalScaldOccurred(:final damage, :final remainingHp) => CombatLogEntry(
          message: 'The boiling caldera scalds the hull for $damage thermal damage ($remainingHp HP remaining)!',
          actor: CombatLogActor.ambient,
          isCritical: true,
        ),
      HelmApproached(:final currentLeg, :final totalLegs) => CombatLogEntry(
          message: 'At the Helm: Assessing courses for Leg ${currentLeg + 1} of $totalLegs.',
          actor: CombatLogActor.ambient,
        ),
      CourseSteered(:final bearing, :final leg, :final lookoutCall) => CombatLogEntry(
          message: 'Steered ${bearing.shortName} into Leg $leg. Lookout: "$lookoutCall"',
          actor: CombatLogActor.ship,
        ),
      MetaCurrenciesAwarded() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.ambient,
        ),
      NemesisSpawned(:final nemesis) => CombatLogEntry(
          message: 'NEMESIS RISES: ${nemesis.moniker} emerges to terrorize the bloodline once more!',
          actor: CombatLogActor.monster,
          isCritical: true,
        ),
      NemesisSlain(:final nemesis) => CombatLogEntry(
          message: 'VENGEANCE CLAIMED! Avenged predecessor ${nemesis.predecessorCaptain} by slaying ${nemesis.moniker}!',
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      HeirSelected(:final heirName, :final chosenClass, :final boon, :final quirk) => CombatLogEntry(
          message: '$heirName takes command as ${chosenClass.name.toUpperCase()} (Boon: ${boon?.name ?? 'None'}, Quirk: ${quirk?.name ?? 'None'}).',
          actor: CombatLogActor.ambient,
          isCritical: true,
        ),
      BlueprintUnlocked(:final blueprintName) => CombatLogEntry(
          message: 'BLUEPRINT UNLOCKED: Naval architects draft specifications for $blueprintName!',
          actor: CombatLogActor.ambient,
          isCritical: true,
        ),
      BlueprintCommissioned(:final blueprintName, :final ship) => CombatLogEntry(
          message: 'FLAGSHIP COMMISSIONED: ${ship.name} reconfigured under $blueprintName specifications.',
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      CalderaClimaxResolved(:final narrative) => CombatLogEntry(
          message: narrative,
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      CovenantPactToggled() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.ambient,
        ),
      BlueprintArmamentUpgraded() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      AuxiliaryExpansionUnlocked() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      EldritchRelicUnlocked() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      HarborMonumentUpgraded() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.ambient,
          isCritical: true,
        ),
      NarrationEvent(:final message) => CombatLogEntry(
          message: message,
          actor: CombatLogActor.ambient,
        ),
      CombatRangeChanged(:final newRange, :final reason) => CombatLogEntry(
          message: 'Tactical range shifted to ${newRange.displayName}. $reason',
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      MortarBackfireOccurred(:final shipName, :final damage, :final remainingHp) => CombatLogEntry(
          message: 'BACKFIRE! Point-blank mortar blast splashes $shipName for $damage damage ($remainingHp HP remaining)!',
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      MonsterIntentTelegraphed(:final intent) => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.monster,
          isCritical: intent.isBossWindup || intent.isBossCatastropheStrike,
        ),
      MonsterAttackOutOfRange() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.ship,
        ),
      HeadOnCollisionOccurred() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.monster,
          isCritical: true,
        ),
      MonsterIntentDisrupted() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      ShipGrappled() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.monster,
          isCritical: true,
        ),
      HardpointTempered() => CombatLogEntry(
          message: narrationFormatter.format(event),
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      PhaseChanged() => null,
      AttackAttempted() => null,
    };
  }

  List<CourseOption> get currentCourseOptions => session.seaChart.currentCourseOptions;
  int get currentLeg => session.seaChart.currentLeg;
  int get totalLegs => session.seaChart.totalLegs;
  int get midpointHavenLeg => session.seaChart.midpointHavenLeg;
  bool get isCurrentIslandHaven => session.isCurrentIslandHaven;
  List<VoyageLegRecord> get voyageLog => session.seaChart.voyageLog;
}

/// Identifies the originator of an event in the naval chronicle.
enum CombatLogActor {
  ship,
  monster,
  ambient,
}

/// A structured record in the combat chronicle for differentiated visual display.
class CombatLogEntry {
  const CombatLogEntry({
    required this.message,
    required this.actor,
    this.isCritical = false,
  });

  final String message;
  final CombatLogActor actor;
  final bool isCritical;
}
