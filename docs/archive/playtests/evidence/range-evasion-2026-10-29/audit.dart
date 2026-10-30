import 'dart:convert';
import 'dart:io';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';

void main(List<String> args) {
  final runs = args.isEmpty ? 100 : int.parse(args[0]);
  final progressed = args.length > 1 && args[1] == 'progressed';
  final rows = <Map<String, Object?>>[];
  const bot = CautiousBot();
  final clock = Stopwatch()..start();
  for (final hull in BlueprintId.values) {
    for (var i = 0; i < runs; i++) {
      final seed = 42 + 31 * i;
      final session = GameSession(
        rng: SeededGameRng(seed),
        profile: ProfileData(unlockedBlueprints: BlueprintId.values.map((b) => b.name).toSet()),
      );
      var steps = 0;
      var expedition = false;
      var death = false;
      var cap = false;
      var kraken = false;
      var worldSerpent = false;
      var attacks = 0;
      String? error;
      var commandName = 'setup';
      final ranges = <String, int>{};
      try {
        session.dispatch(const NameCaptain('Range Audit'));
        session.activeBoon = null;
        session.activeQuirk = null;
        session.dispatch(ChooseShip(hull.shipClass));
        session.dispatch(const VentureOutToSea());
        if (progressed) {
          session.ship = createFlagshipFromBlueprint(hull, level: 4, rng: session.rng, armamentTier: 1)..gold = 25;
          for (final slot in [HardpointType.broadside, HardpointType.signature, HardpointType.utility]) {
            temperShipHardpoint(session.ship!, slot);
            temperShipHardpoint(session.ship!, slot);
          }
        }
        while (steps < 2500) {
          expedition = session.isExpeditionWon;
          kraken = session.seaChart.timesCompleted >= 1;
          worldSerpent = session.seaChart.timesCompleted >= 2;
          death = session.phase == SessionPhase.death || !(session.ship?.isAlive ?? false);
          if (expedition || death || session.phase == SessionPhase.ended) break;
          final command = bot.decideNextAction(session);
          commandName = command.runtimeType.toString();
          if (session.phase == SessionPhase.battle) {
            ranges.update(session.combatRange.name, (v) => v + 1, ifAbsent: () => 1);
          }
          final events = session.dispatch(command);
          attacks += events.whereType<AttackAttempted>().length;
          steps++;
        }
        expedition = session.isExpeditionWon;
        kraken = session.seaChart.timesCompleted >= 1;
        worldSerpent = session.seaChart.timesCompleted >= 2;
        death = session.phase == SessionPhase.death || !(session.ship?.isAlive ?? false);
        cap = steps >= 2500 && !expedition && !death;
      } catch (e) {
        error = '$commandName at ${session.phase.name}: $e';
      }
      rows.add({
        'hull': hull.name, 'seed': seed, 'kraken': kraken,
        'worldSerpent': worldSerpent, 'expedition': expedition, 'death': death,
        'cap': cap, 'error': error, 'steps': steps, 'phase': session.phase.name,
        'region': session.seaChart.currentRegionIndex + 1,
        'monsters': session.monstersDefeatedThisLife,
        'hp': session.ship?.currentHp, 'maxHp': session.ship?.maxHp,
        'gold': session.ship?.gold, 'attacks': attacks, 'battleCommandRanges': ranges,
        'cause': death && session.lineage.history.isNotEmpty ? session.lineage.history.last.causeOfDeath : null,
      });
    }
    stdout.writeln('${hull.name}: $runs complete (${clock.elapsedMilliseconds} ms)');
  }
  File('range-evasion-${progressed ? 'progressed' : 'fresh'}-results.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
}
