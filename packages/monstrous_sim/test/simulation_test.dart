import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';
import 'package:test/test.dart';

void main() {
  group('Bot Strategies Decision Logic Tests', () {
    test('RecklessBot chooses Ironclad and always attacks or advances', () {
      const bot = RecklessBot();
      final session = GameSession(rng: SeededGameRng(100));

      // Initial captain naming
      var cmd = bot.decideNextAction(session);
      expect(cmd, isA<NameCaptain>());
      session.dispatch(cmd);

      // Ship choice
      cmd = bot.decideNextAction(session);
      expect(cmd, isA<ChooseShip>());
      expect((cmd as ChooseShip).shipClass, equals(ShipClass.ironclad));
      session.dispatch(cmd);

      // Port: ventures out
      cmd = bot.decideNextAction(session);
      expect(cmd, isA<VentureOutToSea>());
      session.dispatch(cmd);

      expect(session.phase, equals(SessionPhase.battle));

      // In battle: fires weapon volley
      cmd = bot.decideNextAction(session);
      expect(cmd, isA<FireWeaponVolley>());
    });

    test('CautiousBot attempts retreat or defense when hull is low', () {
      const bot = CautiousBot();
      final session = GameSession(rng: SeededGameRng(200));

      session.dispatch(bot.decideNextAction(session)); // Name captain
      session.dispatch(bot.decideNextAction(session)); // Choose ship
      session.dispatch(bot.decideNextAction(session)); // Venture out

      expect(session.phase, equals(SessionPhase.battle));

      // Heavily damage ship
      session.ship!.currentHp = (session.ship!.maxHp * 0.15).toInt();

      final cmd = bot.decideNextAction(session);
      expect(cmd, isA<ChangeCombatRange>());
      expect((cmd as ChangeCombatRange).targetRange, equals(CombatRange.long));
    });

    test('GreedyBot selects Freighter to optimize cargo hold and gold hoarding', () {
      const bot = GreedyBot();
      final session = GameSession(rng: SeededGameRng(300));

      session.dispatch(bot.decideNextAction(session));
      final shipCmd = bot.decideNextAction(session);
      expect(shipCmd, isA<ChooseShip>());
      expect((shipCmd as ChooseShip).shipClass, equals(ShipClass.freighter));
    });

    test('RandomBot produces legal actions across all phases', () {
      final bot = RandomBot(rng: SeededGameRng(400));
      final session = GameSession(rng: SeededGameRng(400));

      for (var i = 0; i < 20; i++) {
        if (session.phase == SessionPhase.ended) break;
        final cmd = bot.decideNextAction(session);
        expect(cmd, isNotNull);
        session.dispatch(cmd);
      }
    });
  });

  group('SimulationRunner Batch Execution Tests', () {
    test('Runs 100 deterministic simulations with 0 crashes or infinite loops', () {
      const runner = SimulationRunner();
      const bot = CautiousBot();

      final metrics = runner.runBatch(
        strategy: bot,
        count: 100,
        baseSeed: 42,
      );

      expect(metrics.results.length, equals(100));
      final summary = metrics.summarize(bot.name);
      expect(summary.totalRuns, equals(100));
      expect(summary.wins + summary.deaths, equals(100));
      expect(summary.avgMonstersDefeated, greaterThanOrEqualTo(0));
      expect(summary.avgHighestDifficulty, greaterThanOrEqualTo(1));
    });

    test('MarkdownReporter generates valid markdown with table and chart', () {
      const runner = SimulationRunner();
      final metrics = runner.runBatch(
        strategy: const RecklessBot(),
        count: 10,
        baseSeed: 99,
      );

      const reporter = MarkdownReporter();
      final report = reporter.generateReport(
        metrics: metrics,
        totalRuns: 10,
        seed: 99,
      );

      expect(report, contains('# The Monstrous Sea V2 — Monte Carlo Balance Simulation Report'));
      expect(report, contains('Executive Summary'));
      expect(report, contains('```mermaid'));
      expect(report, contains('xychart-beta'));
    });
  });
}
