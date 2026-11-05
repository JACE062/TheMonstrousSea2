import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'arrival is not victory; explicit outcomes and earlier regions round-trip',
    () {
      final chart = SeaChart(rng: SeededGameRng(7))..beginVoyage();
      expect(chart.voyageLog.single.combatWon, isFalse);
      chart.recordCurrentOutcome(combatWon: true);
      chart.advanceRegion(SeededGameRng(8));
      expect(chart.voyageLog.single.combatWon, isTrue);
      expect(chart.voyageLog.single.regionIndex, 0);
      chart.ensureCourseOptions(SeededGameRng(9));
      chart.steerCourse(chart.currentCourseOptions.first.bearing);
      expect(chart.voyageLog.last.regionIndex, 1);
      chart.recordCurrentOutcome(wreckPassed: true);
      final restored = SeaChart(rng: SeededGameRng(999))
        ..restoreFromJson(chart.toJson());
      expect(restored.toJson(), chart.toJson());
      expect(restored.voyageLog.first.combatWon, isTrue);
      expect(restored.voyageLog.last.combatWon, isFalse);
      expect(restored.voyageLog.last.wreckPassed, isTrue);
      restored.reset();
      expect(restored.voyageLog, isEmpty);
    },
  );

  test(
    'actual battle and separate wreck cargo settle independent history facts',
    () {
      final s = GameSession(
        rng: SeededGameRng(4),
        navigationTuning: const NavigationTuning(
          wrecks: WreckTuning(approachAmbushChance: 100),
        ),
      )..dispatch(const BeginFirstVoyage('History'));
      s.currentMonster!.currentHp = 0;
      s.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(s.seaChart.voyageLog.single.combatWon, isTrue);
      s.dispatch(const LeaveRemainingLoot());
      s.dispatch(const TakeHelm());
      final json = s.seaChart.toJson()
        ..['courseOptions'] = [
          const CourseOption(
            bearing: NavigationalBearing.larboardTack,
            nodeType: EncounterNodeType.shipwreckSalvage,
            difficultyLevel: 1,
            lookoutCall: 'Wreck',
            wreckSighting: WreckSighting(
              seed: 1,
              condition: WreckCondition.fresh,
              clearClue: true,
            ),
          ).toJson(),
        ];
      s.seaChart.restoreFromJson(json);
      s.dispatch(const SteerCourse(NavigationalBearing.larboardTack));
      expect(s.seaChart.voyageLog.last.combatWon, isFalse);
      s.currentMonster!.currentHp = 0;
      s.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(s.seaChart.voyageLog.last.combatWon, isTrue);
      expect(s.seaChart.voyageLog.last.wreckRecovered, isFalse);
      s.dispatch(const LeaveRemainingLoot());
      s.dispatch(
        ChooseWreckRecovery(
          s.currentWreck!.id,
          WreckRecoveryChoice.recoverClearedCargo,
        ),
      );
      expect(s.seaChart.voyageLog.last.wreckRecovered, isTrue);
      expect(s.seaChart.voyageLog.last.combatWon, isTrue);
      expect(s.seaChart.voyageLog.last.wreckPassed, isFalse);
    },
  );
}
