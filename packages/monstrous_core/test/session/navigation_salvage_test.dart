import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class SalvageRng extends SeededGameRng {
  SalvageRng() : super(42);
  final List<int> percentiles = [];

  @override
  int nextInt(int maxExclusive) => maxExclusive == 100 && percentiles.isNotEmpty
      ? percentiles.removeAt(0)
      : super.nextInt(maxExclusive);
}

GameSession wreck(SalvageRng rng) {
  final session = GameSession(rng: rng)
    ..dispatch(const BeginFirstVoyage('Salvager'));
  session.phase = SessionPhase.shipwreck;
  session.currentShipwreckName = 'Test Derelict';
  session.currentMonster = null;
  return session;
}

GameSession reload(GameSession session) {
  final restored = GameSession(
    rng: SeededGameRng(999),
    profile: ProfileData.fromJson(session.profile.toJson()),
  );
  VoyageSaveData.fromJson(VoyageSaveData.fromSession(session).toJson())
      .restoreToSession(restored);
  return restored;
}

void main() {
  test(
    'Blood Oath locks alternatives but keeps the Nemesis course available',
    () {
      final session = wreck(SalvageRng());
      session.hasSalvagedCurrentWreck = true;
      session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
      session.activeQuirk = BloodlineTrait.fromId(BloodlineTraitId.bloodOath);
      session.profile.activeNemesis = NemesisRecord.createFromDefeat(
        killer: createShark(level: 2, rng: session.rng),
        captainName: 'Predecessor',
        regionIndex: 0,
        rng: session.rng,
      );
      session.dispatch(const TakeHelm());
      for (final option in session.seaChart.currentCourseOptions) {
        expect(
          session.courseRestriction(option.bearing),
          option.isNemesis ? isNull : contains('Blood Oath'),
        );
      }
    },
  );

  for (final region in [0, 1, 2]) {
    for (final lucky in [true, false]) {
      test(
        'exploration reward thresholds and reload in region $region, lucky=$lucky',
        () {
          final rng = SalvageRng();
          final session = wreck(rng);
          session.seaChart.timesCompleted = region;
          rng.percentiles.addAll(lucky ? [24, 49] : [25, 50]);
          final events = session.dispatch(
            const SalvageShipwreck(ShipwreckChoice.munitions),
          );
          final materials = events.whereType<MetaCurrenciesAwarded>().single;
          expect(materials.seaGlass, inInclusiveRange(2, 4));
          expect(materials.depthWroughtIron, lucky ? 1 : 0);
          expect(session.ship!.cargo, hasLength(lucky ? 1 : 0));
          expect(session.ship!.cargo.whereType<ShipWeapon>(), isEmpty);
          expect(
            session.wreckSalvageReceipt.join(' '),
            contains(lucky ? 'Recovered' : 'No usable consumable'),
          );
          final restored = reload(session);
          expect(restored.currentShipwreckName, 'Test Derelict');
          expect(restored.wreckSalvageReceipt, session.wreckSalvageReceipt);
          final before = restored.profile.toJson();
          restored.dispatch(const SalvageShipwreck(ShipwreckChoice.munitions));
          expect(restored.profile.toJson(), before);
          expect(restored.ship!.cargo, hasLength(lucky ? 1 : 0));
        },
      );
    }
  }

  for (final leave in [false, true]) {
    test(
      'full belt overflow survives reload and must be resolved, leave=$leave',
      () {
        final rng = SalvageRng();
        var session = wreck(rng);
        for (var i = 0; i < session.ship!.maxCargo; i++) {
          session.ship!.addCargo(randomConsumable(1, rng));
        }
        rng.percentiles.addAll([0, 0]);
        session.dispatch(const SalvageShipwreck(ShipwreckChoice.munitions));
        final recovered = session.pendingLoot.single.name;
        session = reload(session);
        expect(session.pendingLoot.single.name, recovered);
        expect(() => session.dispatch(const TakeHelm()), throwsStateError);
        expect(
          () => session.dispatch(const AdvanceToNextBattle()),
          throwsStateError,
        );
        session.dispatch(const TakeAllLoot());
        expect(session.phase, SessionPhase.shipwreck);
        expect(session.pendingLoot, hasLength(1));
        if (leave) {
          session.dispatch(const LeaveRemainingLoot());
          expect(session.wreckSalvageReceipt.last, contains('left aboard'));
        } else {
          session.dispatch(const DropCargoItem(0));
          session.dispatch(const TakeLootItem(0));
          expect(session.ship!.cargo.last.name, recovered);
        }
        expect(session.pendingLoot, isEmpty);
        session = reload(session);
        expect(session.hasSalvagedCurrentWreck, isTrue);
        session.dispatch(const TakeHelm());
        expect(session.phase, SessionPhase.helm);
        final offers = session.seaChart.toJson()['courseOptions'];
        final restored = reload(session);
        expect(restored.seaChart.toJson()['courseOptions'], offers);
      },
    );
  }

  test(
    'strongbox and timber receipts show actual gold, healing and materials',
    () {
      final session = wreck(SalvageRng());
      final initialGold = session.ship!.gold;
      session.dispatch(const SalvageShipwreck(ShipwreckChoice.strongbox));
      final gold = session.ship!.gold - initialGold;
      expect(gold, inInclusiveRange(60, 120));
      expect(session.wreckSalvageReceipt, contains('$gold gold doubloons'));
      expect(
        session.wreckSalvageReceipt,
        contains('${session.profile.metaInventory.seaGlass} Sea Glass'),
      );
      final damaged = wreck(SalvageRng());
      damaged.ship!.currentHp = damaged.ship!.maxHp - 5;
      damaged.dispatch(const SalvageShipwreck(ShipwreckChoice.timbers));
      expect(damaged.wreckSalvageReceipt, contains('Restored 5 hull HP.'));
      expect(damaged.ship!.currentHp, damaged.ship!.maxHp);
      expect(reload(damaged).wreckSalvageReceipt, damaged.wreckSalvageReceipt);
      final healthy = wreck(SalvageRng());
      healthy.dispatch(const SalvageShipwreck(ShipwreckChoice.timbers));
      expect(healthy.wreckSalvageReceipt, contains('Restored 0 hull HP.'));
    },
  );

  test(
    'course restriction agrees with engine and exempts guaranteed convergence',
    () {
      final session = wreck(SalvageRng());
      session.hasSalvagedCurrentWreck = true;
      session.activeQuirk = BloodlineTrait.fromId(
        BloodlineTraitId.recklessHelmsman,
      );
      session.dispatch(const TakeHelm());
      expect(
        session.courseRestriction(NavigationalBearing.deadAhead),
        contains('Reckless Helmsman'),
      );
      final before = session.seaChart.toJson();
      expect(
        () =>
            session.dispatch(const SteerCourse(NavigationalBearing.deadAhead)),
        throwsStateError,
      );
      expect(session.seaChart.toJson(), before);
      expect(
        session.courseRestriction(NavigationalBearing.larboardTack),
        isNull,
      );
      for (final target in [
        session.seaChart.midpointHavenLeg,
        session.seaChart.totalLegs,
      ]) {
        session.seaChart.currentLeg = target - 1;
        session.seaChart.clearPendingCourses();
        session.seaChart.ensureCourseOptions(session.rng);
        expect(session.seaChart.currentCourseOptions, hasLength(1));
        expect(
          session.courseRestriction(NavigationalBearing.deadAhead),
          isNull,
        );
      }
    },
  );
}
