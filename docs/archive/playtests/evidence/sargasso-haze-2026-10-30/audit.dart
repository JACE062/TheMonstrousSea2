import 'dart:convert';
import 'dart:io';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';

// Synthetic arrival, not a played Region1: create a captain/hull, advance the
// real chart once, then approach via restArea/TakeHelm. This avoids home's
// refit reset. Bot chooses real SteerCourse commands and normal rewards follow.
// No traits, blessings, relics or pacts at setup; later shrine rewards are normal.
// Stop at chart.timesCompleted>=2 (World Serpent defeated), never Kraken alone.
void main(List<String> args) {
  final runs = args.isEmpty ? 50 : int.parse(args[0]);
  final version = args.length > 1 ? args[1] : 'unknown';
  final rows = <Map<String,Object?>>[];
  const bot = CautiousBot();
  for (final level in [2,4]) {
    final mark = level == 2 ? 1 : 3;
    for (final hull in BlueprintId.values) {
      for (var i=0;i<runs;i++) {
        final seed=42+31*i;
        final s=GameSession(rng:SeededGameRng(seed),profile:ProfileData(unlockedBlueprints:{hull.name}));
        var steps=0, shipAttacks=0, shipMisses=0, battles=0, hazeVerified=0;
        int? startRegion, firstPenalty;
        var death=false, clear=false, cap=false;
        String? error;
        var commandName='setup';
        try {
          s.dispatch(const NameCaptain('Sargasso Audit'));
          s.activeBoon=null; s.activeQuirk=null;
          s.dispatch(ChooseShip(hull.shipClass));
          s.ship=createFlagshipFromBlueprint(hull,level:level,rng:s.rng,armamentTier:1)..gold=25;
          for (final slot in [HardpointType.broadside,HardpointType.signature,HardpointType.utility]) {
            for (var m=1;m<mark;m++) { temperShipHardpoint(s.ship!,slot); }
          }
          s.seaChart.advanceRegion(s.rng);
          s.phase=SessionPhase.restArea;
          s.dispatch(const TakeHelm());
          startRegion=s.seaChart.currentRegionIndex;
          if(startRegion!=1 || s.seaChart.timesCompleted!=1 || s.phase!=SessionPhase.helm) {
            throw StateError('Setup is not a Sargasso arrival');
          }
          if(s.ship!.blessings.isNotEmpty || s.profile.activeEldritchRelics.isNotEmpty) {
            throw StateError('Setup contains blessings/relics');
          }
          while(steps<2500) {
            clear=s.seaChart.timesCompleted>=2;
            death=s.phase==SessionPhase.death || !s.ship!.isAlive;
            if(clear || death || s.phase==SessionPhase.ended) break;
            final previousPhase=s.phase;
            final command=bot.decideNextAction(s);
            commandName=command.runtimeType.toString();
            final events=s.dispatch(command);
            steps++;
            shipAttacks+=events.whereType<AttackAttempted>().where((e)=>e.attacker==CombatSide.ship).length;
            shipMisses+=events.whereType<AttackMissed>().where((e)=>e.target==CombatSide.monster).length;
            if(previousPhase!=SessionPhase.battle && s.phase==SessionPhase.battle) {
              battles++;
              final monster=s.currentMonster!;
              firstPenalty ??= monster.obscurityAccuracyPenalty;
              if(s.seaChart.currentRegionIndex!=1 || !monster.isObscured) {
                throw StateError('Sargasso encounter missing obscurity');
              }
              if(version=='after' && monster.obscuredAcMod<10) {
                throw StateError('Sargasso haze did not supply minimum10');
              }
              hazeVerified++;
            }
          }
          clear=s.seaChart.timesCompleted>=2;
          death=s.phase==SessionPhase.death || !s.ship!.isAlive;
          cap=steps>=2500 && !clear && !death;
          if(battles==0 || hazeVerified!=battles) throw StateError('No verified haze encounters');
        } catch(e) {error='$commandName at ${s.phase.name}: $e';}
        rows.add({'version':version,'build':'hull$level-mk$mark','hull':hull.name,'seed':seed,
          'startRegion':startRegion,'firstPenalty':firstPenalty,'battles':battles,'hazeVerified':hazeVerified,
          'clear':clear,'death':death,'cap':cap,'error':error,'steps':steps,
          'monsters':s.monstersDefeatedThisLife,'shipAttacks':shipAttacks,'shipMisses':shipMisses,
          'phase':s.phase.name,'timesCompleted':s.seaChart.timesCompleted});
      }
      stdout.writeln('$version hull$level-mk$mark ${hull.name}: $runs complete');
    }
  }
  File('../../results-$version.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
}
