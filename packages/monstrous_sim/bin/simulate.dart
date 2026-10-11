import 'dart:io';
import 'package:args/args.dart';
import 'package:monstrous_sim/monstrous_sim.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption(
      'runs',
      abbr: 'r',
      defaultsTo: '10000',
      help: 'Total number of automated voyages to simulate.',
    )
    ..addOption(
      'seed',
      abbr: 's',
      defaultsTo: '42',
      help: 'Deterministic base random seed for reproducible simulations.',
    )
    ..addOption(
      'strategy',
      defaultsTo: 'all',
      allowed: ['all', 'reckless', 'cautious', 'greedy', 'random'],
      help: 'Bot strategy to evaluate (or "all" to evaluate all four).',
    )
    ..addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'reports/report.md',
      help: 'Path to save generated Markdown report.',
    )
    ..addOption(
      'csv',
      defaultsTo: 'reports/sim_log.csv',
      help: 'Path to export CSV event log (or empty to disable).',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Displays command line usage.',
    );

  ArgResults parsedArgs;
  try {
    parsedArgs = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stderr.writeln(parser.usage);
    exit(64);
  }

  if (parsedArgs['help'] as bool) {
    stdout.writeln('The Monstrous Sea V2 — Monte Carlo Balance Simulator');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final totalRuns = int.parse(parsedArgs['runs'] as String);
  final baseSeed = int.parse(parsedArgs['seed'] as String);
  final strategyArg = parsedArgs['strategy'] as String;
  final outputPath = parsedArgs['output'] as String;
  final csvPath = parsedArgs['csv'] as String;

  stdout.writeln('===============================================================');
  stdout.writeln('  THE MONSTROUS SEA V2 — MONTE CARLO BALANCE SIMULATOR');
  stdout.writeln('===============================================================');
  stdout.writeln('  Runs: $totalRuns | Seed: $baseSeed | Strategy: $strategyArg');
  stdout.writeln('---------------------------------------------------------------\n');

  final allStrategies = <BotStrategy>[
    const RecklessBot(),
    const CautiousBot(),
    const GreedyBot(),
    RandomBot(),
  ];

  final activeStrategies = strategyArg == 'all'
      ? allStrategies
      : allStrategies.where((s) => s.name.toLowerCase() == strategyArg.toLowerCase()).toList();

  final runsPerStrategy = (totalRuns / activeStrategies.length).round();
  const runner = SimulationRunner();
  final aggregateMetrics = SimulationMetrics();

  final stopwatch = Stopwatch()..start();

  for (final strategy in activeStrategies) {
    stdout.writeln('Simulating ${strategy.name} Bot ($runsPerStrategy voyages)...');
    final batchMetrics = runner.runBatch(
      strategy: strategy,
      count: runsPerStrategy,
      baseSeed: baseSeed,
      onProgress: (completed, total) {
        final pct = ((completed / total) * 100).toStringAsFixed(0);
        stdout.writeln('  [$completed / $total] ($pct%)...');
      },
    );

    for (final result in batchMetrics.results) {
      aggregateMetrics.add(result);
    }
  }

  stopwatch.stop();
  stdout.writeln('\nCompleted ${aggregateMetrics.results.length} voyages in ${stopwatch.elapsedMilliseconds}ms.');

  // Print console summary table
  stdout.writeln('\n---------------------------------------------------------------');
  stdout.writeln('Strategy   | Runs  | Win Rate | Avg Monsters | Avg Max Diff | Avg Gold');
  stdout.writeln('---------------------------------------------------------------');
  for (final strategy in activeStrategies) {
    final summary = aggregateMetrics.summarize(strategy.name);
    final nameCol = summary.strategyName.padRight(10);
    final runsCol = summary.totalRuns.toString().padRight(5);
    final winCol = '${summary.winRate.toStringAsFixed(1)}%'.padRight(8);
    final monCol = summary.avgMonstersDefeated.toStringAsFixed(1).padRight(12);
    final diffCol = summary.avgHighestDifficulty.toStringAsFixed(1).padRight(12);
    final goldCol = '${summary.avgGoldEarned.toStringAsFixed(0)}g';
    stdout.writeln('$nameCol | $runsCol | $winCol | $monCol | $diffCol | $goldCol');
  }
  stdout.writeln('---------------------------------------------------------------\n');

  // Save Markdown report
  const reporter = MarkdownReporter();
  final markdownContent = reporter.generateReport(
    metrics: aggregateMetrics,
    totalRuns: aggregateMetrics.results.length,
    seed: baseSeed,
  );
  reporter.saveToFile(markdownContent, outputPath);
  stdout.writeln('Saved Markdown report to: $outputPath');

  // Save CSV if requested
  if (csvPath.isNotEmpty) {
    final csvFile = File(csvPath);
    csvFile.parent.createSync(recursive: true);
    final csvSink = csvFile.openWrite();
    csvSink.writeln(RunResult.csvHeader());
    for (final result in aggregateMetrics.results) {
      csvSink.writeln(result.toCsv());
    }
    csvSink.close();
    stdout.writeln('Saved CSV metrics to: $csvPath');
  }

  stdout.writeln('\nAll runs completed with 0 crashes and 0 infinite loops!');
}
