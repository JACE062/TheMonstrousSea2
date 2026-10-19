import 'package:monstrous_core/monstrous_core.dart';
import '../metrics/simulation_metrics.dart';
import '../strategy/bot_strategy.dart';

/// Drives automated headless simulation runs with execution guards
/// to prevent infinite loops and collect statistical metrics.
class SimulationRunner {
  const SimulationRunner({
    this.maxStepsPerRun = 2500,
    this.endless = false,
  });

  final int maxStepsPerRun;
  final bool endless;

  /// Executes a single automated voyage using [strategy] and deterministic [seed].
  RunResult runSingle({
    required BotStrategy strategy,
    required int runIndex,
    required int seed,
  }) {
    final rng = SeededGameRng(seed);
    final session = GameSession(rng: rng);
    var steps = 0;
    var won = false;
    var died = false;
    var totalRounds = 0;
    var causeOfDeath = 'None (Survived)';

    while (session.phase != SessionPhase.ended && steps < maxStepsPerRun) {
      steps++;

      // In non-endless mode, beating the Kraken (loop >= 1) or winning expedition triggers victory
      if (!endless &&
          (session.seaChart.timesCompleted >= 1 || session.isExpeditionWon)) {
        won = true;
        break;
      }

      if (session.phase == SessionPhase.death) {
        died = true;
        causeOfDeath = session.lineage.history.isNotEmpty
            ? session.lineage.history.last.causeOfDeath
            : (session.currentMonster?.name ?? 'The Undying Sea');
        session.dispatch(const AbandonHunt());
        break;
      }

      final command = strategy.decideNextAction(session);
      final events = session.dispatch(command);

      for (final event in events) {
        if (event is AttackAttempted) {
          totalRounds++;
        }
      }

      // Check if Kraken map was completed or expedition won during this step
      if (session.seaChart.timesCompleted >= 1 || session.isExpeditionWon) {
        won = true;
        if (!endless) break;
      }
    }

    if (!won && !died) {
      died = true;
      causeOfDeath = 'Adrift at Sea (Lost in Fog)';
    }

    final shipClass = session.ship?.shipClass ?? ShipClass.standard;

    return RunResult(
      runIndex: runIndex,
      strategyName: strategy.name,
      won: won,
      died: died,
      shipClass: shipClass,
      monstersDefeated: session.monstersDefeatedThisLife,
      highestDifficulty: session.highestDifficultyThisLife,
      loopsCompleted: session.seaChart.timesCompleted,
      goldEarned: session.ship?.gold ?? 0,
      battleRoundsTotal: totalRounds,
      causeOfDeath: causeOfDeath,
      totalSteps: steps,
    );
  }

  /// Runs a batch of [count] simulation voyages and records the metrics.
  SimulationMetrics runBatch({
    required BotStrategy strategy,
    required int count,
    required int baseSeed,
    void Function(int completed, int total)? onProgress,
  }) {
    final metrics = SimulationMetrics();

    for (var i = 0; i < count; i++) {
      final seed = baseSeed + i * 31;
      final result = runSingle(
        strategy: strategy,
        runIndex: i + 1,
        seed: seed,
      );
      metrics.add(result);
      if (onProgress != null && (i + 1) % 500 == 0) {
        onProgress(i + 1, count);
      }
    }

    return metrics;
  }
}
