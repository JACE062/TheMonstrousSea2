import 'package:monstrous_core/monstrous_core.dart';

/// Granular outcome of an individual automated voyage run.
class RunResult {
  const RunResult({
    required this.runIndex,
    required this.strategyName,
    required this.won,
    required this.died,
    required this.shipClass,
    required this.monstersDefeated,
    required this.highestDifficulty,
    required this.loopsCompleted,
    required this.goldEarned,
    required this.battleRoundsTotal,
    required this.causeOfDeath,
    required this.totalSteps,
  });

  final int runIndex;
  final String strategyName;
  final bool won;
  final bool died;
  final ShipClass shipClass;
  final int monstersDefeated;
  final int highestDifficulty;
  final int loopsCompleted;
  final int goldEarned;
  final int battleRoundsTotal;
  final String causeOfDeath;
  final int totalSteps;

  String toCsv() =>
      '$runIndex,$strategyName,$won,$died,${shipClass.name},$monstersDefeated,$highestDifficulty,$loopsCompleted,$goldEarned,$battleRoundsTotal,"$causeOfDeath",$totalSteps';

  static String csvHeader() =>
      'run_index,strategy,won,died,ship_class,monsters_defeated,highest_difficulty,loops_completed,gold,battle_rounds,cause_of_death,total_steps';
}

/// Aggregated statistical evaluation for a specific bot strategy.
class StrategySummary {
  StrategySummary({
    required this.strategyName,
    required this.totalRuns,
    required this.wins,
    required this.deaths,
    required this.avgMonstersDefeated,
    required this.avgHighestDifficulty,
    required this.avgGoldEarned,
    required this.avgRoundsPerCombat,
    required this.causeOfDeathCounts,
    required this.shipClassCounts,
    required this.shipClassWins,
  });

  final String strategyName;
  final int totalRuns;
  final int wins;
  final int deaths;
  final double avgMonstersDefeated;
  final double avgHighestDifficulty;
  final double avgGoldEarned;
  final double avgRoundsPerCombat;
  final Map<String, int> causeOfDeathCounts;
  final Map<ShipClass, int> shipClassCounts;
  final Map<ShipClass, int> shipClassWins;

  double get winRate => totalRuns > 0 ? (wins / totalRuns) * 100 : 0.0;
  double get deathRate => totalRuns > 0 ? (deaths / totalRuns) * 100 : 0.0;
}

/// Aggregator and statistical analyzer across all simulation runs.
class SimulationMetrics {
  final List<RunResult> results = <RunResult>[];

  void add(RunResult result) {
    results.add(result);
  }

  StrategySummary summarize(String strategyName) {
    final runs = results.where((r) => r.strategyName == strategyName).toList();
    if (runs.isEmpty) {
      return StrategySummary(
        strategyName: strategyName,
        totalRuns: 0,
        wins: 0,
        deaths: 0,
        avgMonstersDefeated: 0,
        avgHighestDifficulty: 0,
        avgGoldEarned: 0,
        avgRoundsPerCombat: 0,
        causeOfDeathCounts: const {},
        shipClassCounts: const {},
        shipClassWins: const {},
      );
    }

    var wins = 0;
    var deaths = 0;
    var totalMonsters = 0;
    var totalHighestDiff = 0;
    var totalGold = 0;
    var totalRounds = 0;
    final deathsByCause = <String, int>{};
    final classCounts = <ShipClass, int>{};
    final classWins = <ShipClass, int>{};

    for (final r in runs) {
      if (r.won) wins++;
      if (r.died) {
        deaths++;
        deathsByCause[r.causeOfDeath] = (deathsByCause[r.causeOfDeath] ?? 0) + 1;
      }
      totalMonsters += r.monstersDefeated;
      totalHighestDiff += r.highestDifficulty;
      totalGold += r.goldEarned;
      totalRounds += r.battleRoundsTotal;

      classCounts[r.shipClass] = (classCounts[r.shipClass] ?? 0) + 1;
      if (r.won) {
        classWins[r.shipClass] = (classWins[r.shipClass] ?? 0) + 1;
      }
    }

    final n = runs.length;
    return StrategySummary(
      strategyName: strategyName,
      totalRuns: n,
      wins: wins,
      deaths: deaths,
      avgMonstersDefeated: totalMonsters / n,
      avgHighestDifficulty: totalHighestDiff / n,
      avgGoldEarned: totalGold / n,
      avgRoundsPerCombat:
          (totalMonsters + deaths) > 0 ? totalRounds / (totalMonsters + deaths) : 0.0,
      causeOfDeathCounts: deathsByCause,
      shipClassCounts: classCounts,
      shipClassWins: classWins,
    );
  }

  List<String> get strategyNames =>
      results.map((r) => r.strategyName).toSet().toList();
}
