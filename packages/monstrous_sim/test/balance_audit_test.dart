import 'dart:io';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';
import 'package:test/test.dart';

void main() {
  test('Balance Audit Simulation: 1000 runs across all strategies', () {
    const runner = SimulationRunner();
    final aggregateMetrics = SimulationMetrics();

    final strategies = <BotStrategy>[
      const RecklessBot(),
      const CautiousBot(),
      const GreedyBot(),
      RandomBot(rng: SeededGameRng(777)),
    ];

    const runsPerStrategy = 250;
    const baseSeed = 42;

    stdout.writeln('\n===============================================================');
    stdout.writeln('  RUNNING BALANCE AUDIT SIMULATION (1,000 RUNS)');
    stdout.writeln('===============================================================');

    for (final strategy in strategies) {
      final metrics = runner.runBatch(
        strategy: strategy,
        count: runsPerStrategy,
        baseSeed: baseSeed,
      );
      for (final r in metrics.results) {
        aggregateMetrics.add(r);
      }
    }

    stdout.writeln('\n-----------------------------------------------------------------------------------------');
    stdout.writeln('Strategy   | Runs | Win % | Avg Monsters | Avg Max Diff | Avg Rounds/Fight | Avg Gold');
    stdout.writeln('-----------------------------------------------------------------------------------------');

    for (final strategy in strategies) {
      final summary = aggregateMetrics.summarize(strategy.name);
      final name = summary.strategyName.padRight(10);
      final runs = summary.totalRuns.toString().padRight(4);
      final win = '${summary.winRate.toStringAsFixed(1)}%'.padRight(6);
      final monsters = summary.avgMonstersDefeated.toStringAsFixed(1).padRight(12);
      final diff = summary.avgHighestDifficulty.toStringAsFixed(1).padRight(12);
      final rounds = summary.avgRoundsPerCombat.toStringAsFixed(1).padRight(16);
      final gold = '${summary.avgGoldEarned.toStringAsFixed(0)}g';
      stdout.writeln('$name | $runs | $win | $monsters | $diff | $rounds | $gold');
    }
    stdout.writeln('-----------------------------------------------------------------------------------------\n');

    // Aggregate mortality analysis
    stdout.writeln('--- TOP CAUSES OF DEATH ---');
    final allDeaths = <String, int>{};
    for (final r in aggregateMetrics.results.where((r) => r.died)) {
      allDeaths[r.causeOfDeath] = (allDeaths[r.causeOfDeath] ?? 0) + 1;
    }
    final sortedDeaths = allDeaths.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedDeaths.take(8)) {
      final pct = ((entry.value / aggregateMetrics.results.where((r) => r.died).length) * 100).toStringAsFixed(1);
      stdout.writeln('  • ${entry.key}: ${entry.value} deaths ($pct%)');
    }

    stdout.writeln('\n--- SHIP CLASS PERFORMANCE ---');
    final classTotal = <ShipClass, int>{};
    final classWins = <ShipClass, int>{};
    for (final r in aggregateMetrics.results) {
      classTotal[r.shipClass] = (classTotal[r.shipClass] ?? 0) + 1;
      if (r.won) {
        classWins[r.shipClass] = (classWins[r.shipClass] ?? 0) + 1;
      }
    }
    final canonicalClasses =
        BlueprintId.values.map((b) => b.shipClass).toList();
    for (final sc in canonicalClasses) {
      final total = classTotal[sc] ?? 0;
      final wins = classWins[sc] ?? 0;
      final winRate = total > 0 ? (wins / total * 100).toStringAsFixed(1) : 'N/A';
      stdout.writeln('  • ${sc.name}: $total runs, $wins wins ($winRate% win rate)');
    }

    // Generate markdown report in reports/
    const reporter = MarkdownReporter();
    final markdown = reporter.generateReport(
      metrics: aggregateMetrics,
      totalRuns: aggregateMetrics.results.length,
      seed: baseSeed,
    );
    reporter.saveToFile(markdown, 'reports/report.md');
    stdout.writeln('\nSaved full report to reports/report.md');

    expect(aggregateMetrics.results.length, equals(1000));
  });
}
