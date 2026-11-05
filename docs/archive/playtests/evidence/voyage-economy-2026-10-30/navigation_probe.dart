import 'dart:convert';
import 'package:monstrous_core/monstrous_core.dart';

void main() {
  final s = GameSession(rng: SeededGameRng(42))
    ..dispatch(const BeginFirstVoyage('Navigation audit'));
  s.seaChart
    ..timesCompleted = 1
    ..currentLeg = 3
    ..currentRow = 2
    ..currentCol = 3
    ..setNodeTypeAt(3, 4, EncounterNodeType.beastCombat);
  s.phase = SessionPhase.helm;
  final offer = s.seaChart.ensureCourseOptions(s.rng).singleWhere(
    (c) => c.bearing == NavigationalBearing.starboardTack,
  );
  final events = s.dispatch(const SteerCourse(NavigationalBearing.starboardTack));
  final battle = events.whereType<BattleStarted>().single;
  print(jsonEncode({
    'region': s.seaChart.currentRegionIndex + 1,
    'leg': s.seaChart.currentLeg,
    'offeredDifficulty': offer.difficultyLevel,
    'runtimeDifficulty': s.seaChart.currentDifficulty,
    'monsterLevel': s.currentMonster!.level,
    'isBoss': battle.isBoss,
    'species': s.currentMonster!.species.name,
    'row': s.seaChart.currentRow,
    'col': s.seaChart.currentCol,
    'offeredLevelGoldExample': calculateVictoryGold(offer.difficultyLevel, SeededGameRng(99)),
    'runtimeGoldExample': calculateVictoryGold(s.seaChart.currentDifficulty, SeededGameRng(99)),
  }));
}
