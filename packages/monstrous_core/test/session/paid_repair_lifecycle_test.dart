import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

final _captains = [
  (null, null, 1.0),
  (BloodlineTrait.skilledCarpenter, null, 1.2),
  (null, BloodlineTrait.exactingShipwright, .75),
  (BloodlineTrait.skilledCarpenter, BloodlineTrait.exactingShipwright, .9),
];

GameSession _haven((BloodlineTrait?, BloodlineTrait?, double) captain) {
  final session = GameSession(rng: SeededGameRng(42))
    ..dispatch(const BeginFirstVoyage('Repair regression'));
  session.activeBoon = captain.$1;
  session.activeQuirk = captain.$2;
  session.ship!
    ..maxHp = 200
    ..currentHp = 1
    ..gold = 10000;
  session.phase = SessionPhase.respiteIsland;
  session.seaChart
    ..currentLeg = 5
    ..currentDestination = CourseDestination.midpointHaven;
  return session;
}

GameSession _reload(GameSession session) {
  final restored = GameSession(
    rng: SeededGameRng(999),
    profile: ProfileData.fromJson(session.profile.toJson()),
  );
  VoyageSaveData.fromJson(VoyageSaveData.fromSession(session).toJson())
      .restoreToSession(restored);
  return restored;
}

void main() {
  for (var index = 0; index < _captains.length; index++) {
    test('captain $index can buy within a small purse without split/reload gain', () {
      var split = _haven(_captains[index]);
      final whole = _haven(_captains[index]);
      split.ship!.gold = 7;
      final quote = split.affordablePaidRepairQuote!;
      expect(quote.goldCost, lessThanOrEqualTo(7));
      expect(quote.restoredHp, greaterThan(0));
      expect(split.paidRepairWork.isLatched, isFalse);
      split.dispatch(const BuyAffordablePaidRepairs());
      split = _reload(split);
      split.ship!.gold += 5;
      split.dispatch(const BuyAffordablePaidRepairs());
      whole.ship!.gold = 12;
      whole.dispatch(const BuyAffordablePaidRepairs());
      expect(split.ship!.currentHp, whole.ship!.currentHp);
      expect(split.ship!.gold, whole.ship!.gold);
      expect(split.paidRepairWork.toJson(), whole.paidRepairWork.toJson());
    });
  }
  test('affordable ketch work rounds total price and rejects off-site use', () {
    final s = _haven(_captains.first)..phase = SessionPhase.smuggler;
    s.activeBoon = BloodlineTrait.smugglersKin;
    s.ship!.gold = 7;
    final quote = s.affordablePaidRepairQuote!;
    expect(quote.goldCost, lessThanOrEqualTo(7));
    s.dispatch(const BuyAffordablePaidRepairs());
    expect(s.paidRepairWork.goldSpent, quote.goldCost);
    expect(s.ship!.currentHp, 1 + quote.restoredHp);
    s.phase = SessionPhase.helm;
    expect(() => s.dispatch(const BuyAffordablePaidRepairs()), throwsStateError);
  });

  for (var c = 0; c < _captains.length; c++) {
    final captain = _captains[c];
    test(
      'captain $c quotes do not latch, upgrading before work determines allowance',
      () {
        final session = _haven(captain);
        expect(session.paidRepairQuote(1)!.totalWork, 50);
        expect(session.paidRepairWork.isLatched, isFalse);
        session.dispatch(const UpgradeShip());
        expect(session.ship!.maxHp, 250);
        expect(session.ship!.currentHp, 51);
        expect(session.paidRepairQuote(1)!.totalWork, 62);
        final before = session.ship!.currentHp;
        final event = session
            .dispatch(const RepairShip(1))
            .whereType<ShipRepaired>()
            .single;
        expect(session.paidRepairWork.maximumHullBasis, 250);
        expect(session.paidRepairWork.totalWork, 62);
        expect(event.repairedHp, (62 * captain.$3).round());
        expect(event.normalWorkUsed, session.paidRepairWork.spentWork);
        expect(session.ship!.currentHp, before + event.repairedHp);
      },
    );

    test(
      'captain $c partial/exhausted work never grows after upgrade or reload',
      () {
        var session = _haven(captain);
        session.dispatch(const RepairShip(.05));
        expect(session.paidRepairWork.spentWork, 10);
        expect(session.paidRepairWork.totalWork, 50);
        session = _reload(session);
        session.dispatch(const UpgradeShip());
        expect(session.paidRepairWork.maximumHullBasis, 200);
        expect(session.paidRepairQuote(1)!.totalWork, 50);
        session.dispatch(const RepairShip(1));
        expect(session.paidRepairWork.spentWork, 50);
        expect(session.paidRepairWork.restoredHp, (50 * captain.$3).round());
      expect(session.ship!.currentHp, 51 + (50 * captain.$3).round());
        final work = session.paidRepairWork.toJson();
        session = _reload(session);
        final hp = session.ship!.currentHp;
        session.dispatch(const UpgradeShip());
        expect(session.ship!.currentHp, hp + 50);
        expect(session.paidRepairWork.toJson(), work);
        expect(session.paidRepairQuote(1)!.restoredHp, 0);
        final gold = session.ship!.gold;
        session.dispatch(const RepairShip(1));
        expect(session.ship!.gold, gold);
        expect(session.paidRepairWork.toJson(), work);
      },
    );

    test(
      'captain $c careen and paid work are separate, used careen never reopens',
      () {
        final session = _haven(captain);
        final free = session
            .dispatch(const CareenHullAtIsland())
            .whereType<HullCareened>()
            .single
            .repairedHp;
        expect(free, (60 * captain.$3).round());
        expect(session.paidRepairWork.isLatched, isFalse);
        session.dispatch(const UpgradeShip());
        expect(session.hasChosenIslandDuty, isTrue);
        expect(
          session
              .dispatch(const CareenHullAtIsland())
              .whereType<HullCareened>(),
          isEmpty,
        );
        expect(session.paidRepairQuote(1)!.totalWork, 62);
        session.dispatch(const RepairShip(1));
        expect(session.paidRepairWork.restoredHp, (62 * captain.$3).round());
        expect(session.paidRepairWork.totalWork, 62);
        final upgradedFirst = _haven(captain)..dispatch(const UpgradeShip());
        expect(
          upgradedFirst
              .dispatch(const CareenHullAtIsland())
              .whereType<HullCareened>()
              .single
              .repairedHp,
          (75 * captain.$3).round(),
        );
      },
    );

    for (final price in [1.0, 1.125]) {
      test(
        'captain $c cumulative work/healing/price $price cannot be increased by splitting',
        () {
          final bulkShip = _haven(captain).ship!
            ..maxHp = 91
            ..currentHp = 1;
          // Captain fields are derived session context, not independent ship JSON.
          final splitShip = ShipState.fromJson(bulkShip.toJson())
            ..captainBoonId = bulkShip.captainBoonId
            ..captainQuirkId = bulkShip.captainQuirkId;
          final bulk = PaidRepairWork();
          final split = PaidRepairWork();
          final quote = quotePaidRepair(
            bulkShip,
            bulk,
            percentage: 1,
            allowanceFraction: .40,
            goldPerWork: price,
          );
          expect(applyPaidRepair(bulkShip, bulk, quote), isTrue);
          for (var attempt = 0; attempt < 40; attempt++) {
            final part = quotePaidRepair(
              splitShip,
              split,
              percentage: .05,
              allowanceFraction: .40,
              goldPerWork: price,
            );
            if (part.restoredHp == 0) break;
            expect(applyPaidRepair(splitShip, split, part), isTrue);
          }
          expect(splitShip.currentHp, bulkShip.currentHp);
          expect(split.spentWork, bulk.spentWork);
          expect(split.goldSpent, bulk.goldSpent);
          expect(split.restoredHp, bulk.restoredHp);
          expect(splitShip.gold, bulkShip.gold);
        },
      );
    }
    test('captain $c split repairs retain rounding endpoints across every checkpoint', () {
      var split = _haven(captain);
      split.ship!..maxHp = 91..currentHp = 1;
      split.seaChart.currentDestination = CourseDestination.repairRefit;
      final bulk = _haven(captain);
      bulk.ship!..maxHp = 91..currentHp = 1;
      bulk.seaChart.currentDestination = CourseDestination.repairRefit;
      bulk.dispatch(const RepairShip(1));
      for (var attempt = 0; attempt < 40; attempt++) {
        if (split.repairHpFor(.05) == 0) break;
        split.dispatch(const RepairShip(.05));
        split = _reload(split);
      }
      expect(split.ship!.currentHp, bulk.ship!.currentHp);
      expect(split.ship!.gold, bulk.ship!.gold);
      expect(split.paidRepairWork.toJson(), bulk.paidRepairWork.toJson());
    });
  }

  test('failed/zero-benefit purchases do not latch and stale quotes cannot buy work', () {
    final session = _haven(_captains.first);
    session.ship!.gold = 0;
    session.dispatch(const RepairShip(1));
    expect(session.paidRepairWork.isLatched, isFalse);
    session.ship!.gold = 10000;
    final quote = session.paidRepairQuote(1)!;
    session.dispatch(const UpgradeShip());
    expect(
      applyPaidRepair(session.ship!, session.paidRepairWork, quote),
      isFalse,
    );
    expect(session.paidRepairWork.isLatched, isFalse);
    session.ship!.currentHp = session.ship!.maxHp;
    session.dispatch(const RepairShip(1));
    expect(session.paidRepairWork.isLatched, isFalse);
  });

  test('missing-hull clipping spends minimum work and stores actual restoration separately', () {
    final session = _haven(_captains[1]);
    session.ship!.currentHp = 197;
    final quote = session.paidRepairQuote(1)!;
    expect(quote.restoredHp, 3);
    expect(quote.normalWork, 3);
    session.dispatch(const RepairShip(1));
    expect(session.ship!.currentHp, 200);
    expect(session.paidRepairWork.restoredHp, 3);
    expect(session.paidRepairWork.spentWork, 3);
    expect(session.paidRepairQuote(1)!.restoredHp, 0);
  });

  test(
    'Haven, final station and ketch capacities differ; stronghold is uncapped',
    () {
      final haven = _haven(_captains.first);
      expect(haven.paidRepairQuote(1)!.totalWork, 50);
      haven.seaChart.currentDestination = CourseDestination.repairRefit;
      expect(haven.paidRepairQuote(1)!.totalWork, 80);
      haven.phase = SessionPhase.smuggler;
      expect(haven.paidRepairQuote(1)!.totalWork, 40);
      haven.activeBoon = BloodlineTrait.smugglersKin;
      final kin = haven.paidRepairQuote(1)!;
      expect(kin.goldCost, 45); // 40 work × 1.5g × .75.
      haven.phase = SessionPhase.stronghold;
      expect(haven.paidRepairQuote(1)!.totalWork, isNull);
      haven.dispatch(const RepairShip(1));
      expect(haven.ship!.currentHp, haven.ship!.maxHp);
      expect(haven.paidRepairWork.totalWork, isNull);
    },
  );

  test('Brittle Oak and captain healing apply once while normal paid work stays separate', () {
    final session = _haven(_captains[1]);
    session.profile.activePacts.add(CovenantPactId.brittleOak);
    final free = session.dispatch(const CareenHullAtIsland()).whereType<HullCareened>().single;
    expect(free.repairedHp, 54); // 200 × .30 × .75 × 1.2.
    expect(session.paidRepairWork.isLatched, isFalse);
    final quote = session.paidRepairQuote(1)!;
    expect(quote.normalWork, 50);
    expect(quote.restoredHp, 60);
    expect(quote.goldCost, 65); // Existing regular-work Brittle Oak price.
    session.dispatch(const RepairShip(1));
    expect(session.paidRepairWork.spentWork, 50);
    expect(session.paidRepairWork.restoredHp, 60);
  });

  test('another actual service visit receives its own pool', () {
    final session = _haven(_captains.first)..dispatch(const RepairShip(1));
    expect(session.paidRepairWork.spentWork, 50);
    session.seaChart.currentLeg = session.seaChart.totalLegs - 1;
    session.dispatch(const DepartIsland());
    session.dispatch(const SteerCourse(NavigationalBearing.larboardTack));
    expect(session.isRepairRefitStop, isTrue);
    expect(session.paidRepairWork.spentWork, 0);
    expect(session.paidRepairWork.isLatched, isFalse);
    expect(session.paidRepairQuote(1)!.totalWork, 80);
  });

  for (final phase in [
    SessionPhase.battle,
    SessionPhase.loot,
    SessionPhase.shipwreck,
    SessionPhase.shrine,
    SessionPhase.port,
    SessionPhase.death,
    SessionPhase.ended,
  ]) {
    test('$phase does not expose paid repair work', () {
      final session = _haven(_captains.first)..phase = phase;
      final hp = session.ship!.currentHp;
      final gold = session.ship!.gold;
      expect(
        session.dispatch(const RepairShip(1)).whereType<ShipRepaired>(),
        isEmpty,
      );
      expect(session.ship!.currentHp, hp);
      expect(session.ship!.gold, gold);
    });
  }
}
