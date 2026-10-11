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

  final List<String> combatLog = <String>[];
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
  List<GameEvent> dispatch(Command command) {
    final events = session.dispatch(command);
    lastEvents = events;

    for (final event in events) {
      final logLine = _formatEventForLog(event);
      if (logLine != null && logLine.isNotEmpty) {
        combatLog.add(logLine);
      }
    }

    notifyListeners();
    return events;
  }

  void setIsPlayingEvents(bool playing) {
    isPlayingEvents = playing;
    notifyListeners();
  }

  void clearLog() {
    combatLog.clear();
    notifyListeners();
  }

  String? _formatEventForLog(GameEvent event) {
    return switch (event) {
      BattleStarted(:final monsterName, :final difficulty, :final isBoss) =>
        isBoss
            ? 'THE KRAKEN RISES FROM THE ABYSS! Prepare all guns!'
            : 'Encountered $monsterName (Danger Level $difficulty)!',
      AttackHit(:final targetName, :final damage, :final damageType) =>
        '$targetName was struck for $damage $damageType damage!',
      AttackMissed(:final targetName) => 'The shot missed $targetName!',
      AttackEvaded(:final shipName, :final wasManeuver) =>
        '$shipName swiftly evaded incoming strike${wasManeuver ? ' via evasive maneuvers' : ''}!',
      DamageReduced(:final shipName, :final nullifiedAmount) =>
        '$shipName\'s reinforced plating absorbed $nullifiedAmount damage!',
      TentaclesSevered(:final countSevered, :final remainingTentacles) =>
        'Severed $countSevered tentacles! ($remainingTentacles remaining)',
      InkCloudDeployed(:final monsterName, :final acBonus) =>
        '$monsterName spewed a dense ink cloud! (+$acBonus AC)',
      StatusEffectTicked(:final targetName, :final effectName, :final damage, :final woreOff) =>
        '$targetName suffers $damage from $effectName${woreOff ? ' (cleared)' : ''}!',
      CombatantDefeated(:final name, :final flavorMessage) =>
        '$name was defeated! $flavorMessage',
      MonsterHesitated(:final monsterName) =>
        '$monsterName hesitated, gathering its fury.',
      FledToPort(:final shipName) =>
        '$shipName successfully broke off engagement and fled to port!',
      LootDropped(:final items) =>
        'Spoils salvaged: ${items.length} items recovered!',
      ItemAcquired(:final item) => 'Stowed ${item.name} into cargo hold.',
      ItemSold(:final item, :final goldEarned) =>
        'Sold ${item.name} for ${goldEarned}g.',
      AllTreasureSold(:final totalGold, :final itemsSold) =>
        'Exchanged $itemsSold treasures for ${totalGold}g.',
      ShipRepaired(:final repairedHp, :final goldCost) =>
        'Repaired $repairedHp hull points for ${goldCost}g.',
      CaptainLost(:final captainName, :final monstersDefeated) =>
        'Captain $captainName has perished in the watery deep ($monstersDefeated monsters slain).',
      NarrationEvent(:final message) => message,
      PhaseChanged() => null,
      AttackAttempted() => null,
    };
  }
}
