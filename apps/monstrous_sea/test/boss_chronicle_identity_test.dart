import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';

void main() {
  for (final (region, name) in [
    (0, 'The Kraken'),
    (1, 'The World Serpent'),
    (2, 'The Ancient Leviathan'),
  ]) {
    test('Chronicle opens the actual $name encounter', () {
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      )..dispatch(const BeginFirstVoyage('Chronicle Tester'));
      addTearDown(controller.dispose);
      controller.seaChart
        ..timesCompleted = region
        ..currentLeg = controller.seaChart.totalLegs - 1;
      controller.session.phase = SessionPhase.restArea;
      controller.dispatch(const TakeHelm());
      final previousEntries = controller.structuredCombatLog.length;
      final events = controller.dispatch(
        const SteerCourse(NavigationalBearing.deadAhead),
      );
      final encounter = events.whereType<BattleStarted>().single;
      expect(encounter.isBoss, isTrue);
      expect(encounter.monsterName, name);
      final opening = controller.structuredCombatLog
          .skip(previousEntries)
          .singleWhere(
            (entry) => entry.message.contains(' RISES FROM THE ABYSS!'),
          );
      expect(
        opening.message,
        '${name.toUpperCase()} RISES FROM THE ABYSS! Prepare all guns!',
      );
      expect(opening.actor.name, 'ambient');
      expect(opening.isCritical, isTrue);
      expect(controller.combatLog.join(), isNot(contains('The The ')));
    });
  }

  test('ordinary encounter opening keeps its name, difficulty and styling', () {
    final controller = GameController(
      session: GameSession(rng: SeededGameRng(42)),
      autoSave: false,
    );
    addTearDown(controller.dispose);
    final events = controller.dispatch(
      const BeginFirstVoyage('Chronicle Tester'),
    );
    final encounter = events.whereType<BattleStarted>().single;
    expect(encounter.isBoss, isFalse);
    final opening = controller.structuredCombatLog.singleWhere(
      (entry) =>
          entry.message ==
          'Encountered ${encounter.monsterName} (Danger Level ${encounter.difficulty})!',
    );
    expect(opening.actor.name, 'ambient');
    expect(opening.isCritical, isFalse);
  });
}
