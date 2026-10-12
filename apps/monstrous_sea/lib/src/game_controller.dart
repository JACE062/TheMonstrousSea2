import 'package:flutter/foundation.dart';
import 'package:monstrous_core/monstrous_core.dart';

/// Central presentation coordinator bridging the Flutter UI and Flame battle scene
/// to the pure domain [GameSession].
class GameController extends ChangeNotifier {
  GameController({GameSession? session})
      : session = session ?? GameSession(),
        narrationFormatter = const NarrationFormatter();

  final GameSession session;
  final NarrationFormatter narrationFormatter;

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
  List<Item> get pendingLoot => session.pendingLoot;
  List<Item> get merchantStock => session.merchantStock;

  /// Dispatches [command] to domain engine, processes resulting events into logs,
  /// and notifies UI listeners.
  List<GameEvent> dispatch(Command command, {bool deferNotification = false}) {
    final events = session.dispatch(command);
    lastEvents = events;

    for (final event in events) {
      final entry = _formatEventForLog(event);
      if (entry != null && entry.message.isNotEmpty) {
        structuredCombatLog.add(entry);
      }
    }

    if (!deferNotification) {
      notifyListeners();
    }
    return events;
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
      FleeFailed(:final shipName) => CombatLogEntry(
          message: '$shipName attempted to turn tail and flee, but the beast cut off all escape!',
          actor: CombatLogActor.ship,
          isCritical: true,
        ),
      BattleStarted(:final monsterName, :final difficulty, :final isBoss) => CombatLogEntry(
          message: isBoss
              ? 'THE KRAKEN RISES FROM THE ABYSS! Prepare all guns!'
              : 'Encountered $monsterName (Danger Level $difficulty)!',
          actor: CombatLogActor.ambient,
          isCritical: isBoss,
        ),
      AttackHit(:final targetName, :final damage, :final damageType) =>
        targetName == currentMonster?.name
            ? CombatLogEntry(
                message: '$targetName was struck for $damage $damageType damage!',
                actor: CombatLogActor.ship,
              )
            : CombatLogEntry(
                message: '$targetName was struck for $damage $damageType damage!',
                actor: CombatLogActor.monster,
                isCritical: true,
              ),
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
      FledToPort(:final shipName) => CombatLogEntry(
          message: '$shipName successfully broke off engagement and fled to port!',
          actor: CombatLogActor.ship,
        ),
      LootDropped(:final items) => CombatLogEntry(
          message: 'Spoils salvaged: ${items.length} items recovered!',
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
      CaptainLost(:final captainName, :final monstersDefeated) => CombatLogEntry(
          message: 'Captain $captainName has perished in the watery deep ($monstersDefeated monsters slain).',
          actor: CombatLogActor.ambient,
          isCritical: true,
        ),
      NarrationEvent(:final message) => CombatLogEntry(
          message: message,
          actor: CombatLogActor.ambient,
        ),
      PhaseChanged() => null,
      AttackAttempted() => null,
    };
  }
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
