import 'dart:io';

import 'package:args/args.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';

/// Paired, disposable captain-trait observations; never reads or writes saves.
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('runs', defaultsTo: '100', help: 'Seeds per R1 hull/trait.')
    ..addOption(
      'later-runs',
      defaultsTo: '50',
      help: 'Seeds per R2/R3 hull/trait.',
    )
    ..addOption('seed', defaultsTo: '42')
    ..addOption('max-steps', defaultsTo: '2500')
    ..addFlag('help', abbr: 'h', negatable: false);
  final args = parser.parse(arguments);
  if (args['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }
  final runs = int.parse(args['runs'] as String);
  final laterRuns = int.parse(args['later-runs'] as String);
  final seed = int.parse(args['seed'] as String);
  final maxSteps = int.parse(args['max-steps'] as String);
  if (runs < 1 || laterRuns < 0 || maxSteps < 1) {
    throw ArgumentError(
      'runs/max-steps must be positive; later-runs nonnegative',
    );
  }
  final report = StringBuffer('''# Seeded captain trait audit

Observational paired comparison using actual GameSession commands and CautiousBot.
Seeds: $seed + 31*i. R1: $runs seeds per hull/trait; R2/R3: $laterRuns each.
Each pair starts independently with BeginFirstVoyage, clears its initial captain
traits, then installs the same fresh factory hull (and starting gold 25) before
assigning the tested trait. All five hulls are tested regardless of unlock state.
R1 uses hull level I/Mk I. R2 uses level III/Mk II; R3 level IV/Mk III.
All use ancestral armament I, no initial blessings, no pacts, relics, monuments,
or other profile progression. Later scenarios advance the chart to the region,
then use TakeHelm from a synthetic rest checkpoint; no earlier rewards carry over.
Ordinary command-driven rewards/upgrades/blessings remain available to the bot.
Vendetta alone has a fixed ordinary shark Nemesis in the scenario's region;
its baseline receives the identical Nemesis. Other pairs have none.

Baselines are cached per region/hull/seed/Nemesis condition. Matching initial seeds
do not force matching later routes or random draws once decisions diverge.
Clear means crossing that scenario's regional Titan boundary (or reaching the
final expeditionVictory phase in R3); it is not full campaign victory. Kraken is
an actual R1 crossing only, not an inherited flag on later-region setup. Expedition
counts only the final victory phase. Death, command caps and exceptions are separate.
HP averages include dead hulls as zero. Delta is trait clear percentage minus its
matched baseline; these are strategy/build observations, not balance targets.
Command cap: $maxSteps. No player saves, native builds or tracked reports used.

| Scenario | Hull | Trait | N | Clear | Base clear | Delta pp | Kraken | Expedition | Death | Cap | Error | Mean monsters | Mean HP% |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
''');
  final failures = <String>[];
  final baselineCache = <String, _Result>{};
  final csv = StringBuffer(
    'region,hull,trait,seed,clear,kraken,expedition,death,cap,error,steps,monsters,hp_ratio,baseline_clear\n',
  );
  final traits = [...BloodlineTrait.allBoons, ...BloodlineTrait.allQuirks];
  var starts = 0;
  final clock = Stopwatch()..start();
  for (var region = 0; region < 3; region++) {
    final count = region == 0 ? runs : laterRuns;
    if (count == 0) continue;
    for (final hull in BlueprintId.values) {
      for (final trait in traits) {
        final results = <_Result>[];
        var baselineClears = 0;
        for (var i = 0; i < count; i++) {
          final runSeed = seed + i * 31;
          final nemesis = trait.id == BloodlineTraitId.bloodOath;
          final key = '$region/${hull.name}/$runSeed/$nemesis';
          final baseline = baselineCache.putIfAbsent(key, () {
            starts++;
            return _run(hull, region, runSeed, maxSteps, null, nemesis);
          });
          starts++;
          final result = _run(hull, region, runSeed, maxSteps, trait, nemesis);
          results.add(result);
          if (baseline.clear) baselineClears++;
          for (final entry in [
            (trait.name, result),
            ('baseline $key', baseline),
          ]) {
            if (entry.$2.error != null && failures.length < 30) {
              final description =
                  'R${region + 1}/${hull.name}/${entry.$1}/seed=$runSeed: ${entry.$2.error}';
              if (!failures.contains(description)) failures.add(description);
            }
          }
          csv.writeln(
            '${region + 1},${hull.name},${trait.id.name},$runSeed,'
            '${result.clear},${result.kraken},${result.expedition},${result.death},'
            '${result.cap},${result.error != null},${result.steps},'
            '${result.monsters},${result.hpRatio},${baseline.clear}',
          );
        }
        int total(bool Function(_Result) condition) =>
            results.where(condition).length;
        final clear = total((r) => r.clear);
        final delta = 100 * (clear - baselineClears) / count;
        final meanMonsters =
            results.fold<int>(0, (sum, r) => sum + r.monsters) / count;
        final meanHp =
            100 * results.fold<double>(0, (sum, r) => sum + r.hpRatio) / count;
        report.writeln(
          '| R${region + 1} | ${hull.name} | ${trait.name} | $count | '
          '$clear | $baselineClears | ${delta.toStringAsFixed(1)} | '
          '${total((r) => r.kraken)} | ${total((r) => r.expedition)} | '
          '${total((r) => r.death)} | ${total((r) => r.cap)} | '
          '${total((r) => r.error != null)} | ${meanMonsters.toStringAsFixed(2)} | '
          '${meanHp.toStringAsFixed(1)} |',
        );
      }
      stdout.writeln(
        'R${region + 1} ${hull.name} complete; $starts starts, '
        '${clock.elapsed.inSeconds}s',
      );
    }
  }
  report.writeln(
    '\n$starts actual starts, including ${baselineCache.length} cached baselines. '
    'Elapsed ${clock.elapsedMilliseconds} ms.',
  );
  final baselineErrors = baselineCache.values
      .where((r) => r.error != null)
      .length;
  final baselineCaps = baselineCache.values.where((r) => r.cap).length;
  report.writeln(
    'Unique baseline exceptions: $baselineErrors; caps: $baselineCaps.',
  );
  report.writeln('\n## Exception samples\n');
  report.writeln(
    failures.isEmpty ? 'None.' : failures.map((f) => '- $f').join('\n'),
  );
  final output = File('.dart_tool/captain-traits-report.md');
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(report.toString());
  File('.dart_tool/captain-traits-report.csv')
      .writeAsStringSync(csv.toString());
  stdout.writeln('Saved ${output.absolute.path}');
}

class _Result {
  bool clear = false;
  bool kraken = false;
  bool expedition = false;
  bool death = false;
  bool cap = false;
  String? error;
  int steps = 0;
  int monsters = 0;
  double hpRatio = 0;
}

_Result _run(
  BlueprintId hull,
  int region,
  int seed,
  int maxSteps,
  BloodlineTrait? trait,
  bool withNemesis,
) {
  final result = _Result();
  final session = GameSession(rng: SeededGameRng(seed));
  String commandName = 'setup';
  try {
    session.dispatch(const BeginFirstVoyage('Trait Audit'));
    session.activeBoon = null;
    session.activeQuirk = null;
    session.profile.activeBlueprintId = hull.name;
    session.ship = createFlagshipFromBlueprint(
      hull,
      level: region == 0 ? 1 : region + 2,
      rng: session.rng,
      armamentTier: 1,
    )..gold = 25;
    for (final slot in [
      HardpointType.broadside,
      HardpointType.signature,
      HardpointType.utility,
    ]) {
      for (var mark = 0; mark < region; mark++) {
        temperShipHardpoint(session.ship!, slot);
      }
    }
    if (withNemesis) {
      session.profile.activeNemesis = NemesisRecord(
        species: MonsterSpecies.shark,
        baseName: 'Audit Shark',
        moniker: 'Audit Nemesis',
        predecessorCaptain: 'Audit Predecessor',
        regionIndex: region,
        level: 2 + region * 4,
        bonusHp: 15 + region * 20,
        bonusCarapace: 35 + region * 20,
        bountyGold: 200,
        bountySeaGlass: 9,
        bountyMonsterBone: 12,
        bountyBarnacles: 4,
      );
    }
    if (trait?.isBoon == true) session.activeBoon = trait;
    if (trait?.isQuirk == true) session.activeQuirk = trait;
    if (region > 0) {
      for (var i = 0; i < region; i++) {
        session.seaChart.advanceRegion(session.rng);
      }
      session.phase = SessionPhase.restArea;
      session.dispatch(const TakeHelm());
    }
    const bot = CautiousBot();
    while (result.steps < maxSteps) {
      result.expedition = session.isExpeditionWon;
      result.kraken = region == 0 && session.seaChart.timesCompleted >= 1;
      result.clear =
          session.seaChart.timesCompleted > region || result.expedition;
      result.death =
          session.phase == SessionPhase.death ||
          !(session.ship?.isAlive ?? false);
      if (result.clear || result.death || session.phase == SessionPhase.ended)
        break;
      final command = bot.decideNextAction(session);
      commandName = command.runtimeType.toString();
      session.dispatch(command);
      result.steps++;
    }
    result.cap = result.steps >= maxSteps && !result.clear && !result.death;
  } catch (error) {
    result.error = '$commandName at ${session.phase.name}: $error';
  }
  result.monsters = session.monstersDefeatedThisLife;
  final ship = session.ship;
  result.hpRatio = ship == null || !ship.isAlive
      ? 0
      : ship.currentHp / ship.maxHp;
  return result;
}
