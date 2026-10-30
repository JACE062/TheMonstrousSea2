import 'dart:convert';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  test('ordinary monster intent keeps its leading article', () {
    final line = const NarrationFormatter().format(
      MonsterIntentTelegraphed(
        monsterName: 'Crimson Shark',
        intent: MonsterIntent.fromId(MonsterIntentId.sharkFrenziedJaws),
      ),
    );
    expect(line, contains(': The Crimson Shark '));
  });

  for (final (region, name) in [
    (0, 'The Kraken'),
    (1, 'The World Serpent'),
    (2, 'The Ancient Leviathan'),
  ]) {
    test('$name approach agrees with battle identity', () {
      final session = GameSession(rng: SeededGameRng(42))
        ..dispatch(const BeginFirstVoyage('Test'));
      session.seaChart.timesCompleted = region;
      session.seaChart.currentLeg = session.seaChart.totalLegs - 1;
      session.phase = SessionPhase.restArea;
      final helm = session.dispatch(const TakeHelm());
      expect(
        helm
            .whereType<HelmApproached>()
            .single
            .availableCourses
            .single
            .lookoutCall,
        contains(name),
      );
      final events = session.dispatch(
        const SteerCourse(NavigationalBearing.deadAhead),
      );
      expect(
        events.whereType<CourseSteered>().single.lookoutCall,
        contains(name),
      );
      expect(events.whereType<BattleStarted>().single.monsterName, name);
      expect(session.currentMonster!.name, name);
      final intentLine = const NarrationFormatter().format(
        events.whereType<MonsterIntentTelegraphed>().single,
      );
      expect(intentLine, contains(': $name '));
      expect(intentLine, isNot(contains('The The ')));
    });

    test('$name repairs only old cached Titan approach copy', () {
      final chart = SeaChart(rng: SeededGameRng(42))..timesCompleted = region;
      chart.currentLeg = chart.totalLegs - 1;
      chart.ensureCourseOptions();
      final saved =
          jsonDecode(jsonEncode(chart.toJson())) as Map<String, dynamic>;
      final option =
          (saved['courseOptions'] as List).single as Map<String, dynamic>;
      option['lookoutCall'] = 'Old Titan alias';
      final before = Map<String, dynamic>.from(option);
      final restored = SeaChart(rng: SeededGameRng(1))..restoreFromJson(saved);
      expect(restored.currentCourseOptions.single.lookoutCall, contains(name));
      final actual =
          (restored.toJson()['courseOptions'] as List).single
              as Map<String, dynamic>;
      actual['lookoutCall'] = before['lookoutCall'];
      expect(actual, before);
      expect(restored.toJson()['voyageLog'], saved['voyageLog']);

      for (final isNemesis in [false, true]) {
        option['nodeType'] = EncounterNodeType.beastCombat.name;
        option['isNemesis'] = isNemesis;
        option['monsterSpecies'] = MonsterSpecies.serpent.name;
        option['lookoutCall'] = isNemesis
            ? 'Captain Reed\'s custom nemesis'
            : 'Generated Abyssal Wyrm';
        restored.restoreFromJson(saved);
        expect(
          restored.currentCourseOptions.single.lookoutCall,
          option['lookoutCall'],
        );
      }
    });
  }
}
