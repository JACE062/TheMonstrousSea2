import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

const _small = WreckCargoProfile(
  glassMin: 1,
  glassMax: 1,
  ironChance: 100,
  supplyChance: 100,
  goldChance: 100,
  goldMin: 5,
  goldMax: 5,
);
const _rich = WreckCargoProfile(
  glassMin: 3,
  glassMax: 3,
  ironChance: 100,
  ironMax: 1,
  supplyChance: 100,
  goldChance: 100,
  goldMin: 20,
  goldMax: 20,
);
WreckTuning _tuning({bool ambush = false, bool fight = false}) => WreckTuning(
  approachAmbushChance: ambush ? 100 : 0,
  uncertainFightChance: fight ? 100 : 0,
  freshFightChance: fight ? 100 : 0,
  small: _small,
  deeper: _rich,
  fresh: _rich,
);

GameSession _offered(
  WreckCondition condition,
  WreckTuning tuning, {
  int seed = 4,
  bool apexPact = false,
}) {
  final session = GameSession(
    rng: SeededGameRng(seed),
    navigationTuning: NavigationTuning(wrecks: tuning),
    profile: ProfileData(
      activePacts: {if (apexPact) CovenantPactId.apexEmergence},
    ),
  )..dispatch(const BeginFirstVoyage('Wreck regression'));
  session.seaChart.advanceRegion(session.rng);
  session.seaChart.advanceRegion(session.rng);
  session.seaChart.currentLeg = 2;
  final state = session.seaChart.toJson()
    ..['courseOptions'] = [
      CourseOption(
        bearing: NavigationalBearing.deadAhead,
        nodeType: EncounterNodeType.shipwreckSalvage,
        difficultyLevel: 10,
        lookoutCall: 'A derelict ahead.',
        wreckSighting: WreckSighting(
          seed: 81,
          condition: condition,
          clearClue: true,
        ),
      ).toJson(),
    ];
  session.seaChart.restoreFromJson(state);
  session.phase = SessionPhase.helm;
  session.ship!.currentHp = 20;
  return session;
}

GameSession _arrive(
  WreckCondition condition,
  WreckTuning tuning, {
  bool apexPact = false,
}) =>
    _offered(condition, tuning, apexPact: apexPact)
      ..dispatch(const SteerCourse(NavigationalBearing.deadAhead));

GameSession _reload(GameSession session, WreckTuning tuning) {
  final restored = GameSession(
    rng: SeededGameRng(999),
    navigationTuning: NavigationTuning(wrecks: tuning),
    profile: ProfileData.fromJson(session.profile.toJson()),
  );
  VoyageSaveData.fromJson(VoyageSaveData.fromSession(session).toJson())
      .restoreToSession(restored);
  return restored;
}

List<GameEvent> _choose(GameSession session, WreckRecoveryChoice choice) =>
    session.dispatch(ChooseWreckRecovery(session.currentWreck!.id, choice));

void _win(GameSession session) {
  session.currentMonster!.currentHp = 0;
  session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
  expect(session.phase, SessionPhase.loot);
  expect(
    session.pendingLoot.length,
    inInclusiveRange(
      session.currentMonster!.isApex ? 2 : 1,
      session.currentMonster!.isApex ? 3 : 2,
    ),
  );
}

void main() {
  for (final condition in WreckCondition.values) {
    for (final apexPact in [false, true]) {
      test(
        '$condition approach ambush is normal, opens full cargo once, pact=$apexPact',
        () {
          final tuning = _tuning(ambush: true, fight: true);
          var session = _offered(condition, tuning, apexPact: apexPact);
          final arrival = session.dispatch(
            const SteerCourse(NavigationalBearing.deadAhead),
          );
          expect(session.phase, SessionPhase.battle);
          expect(session.currentMonster!.isApex, isFalse);
          expect(session.currentMonster!.species.isRegionTitan, isFalse);
          expect(session.currentMonster!.level, 10);
          expect(
            session.ship!.currentHp,
            20,
            reason: 'Ambush adds no free opening attack',
          );
          expect(arrival.whereType<AttackAttempted>(), isEmpty);
          expect(session.currentWreck!.approachAmbush, isTrue);
          expect(session.profile.metaInventory.seaGlass, 0);
          final cargo = session.currentWreck!.cargo!.toJson();
          _win(session);
          final creatureGold = session.ship!.gold;
          final organics = session.profile.metaInventory.monsterBone;
          expect(organics, inInclusiveRange(1, 2));
          expect(session.profile.metaInventory.depthWroughtIron, 0);
          session = _reload(session, tuning);
          session.dispatch(const LeaveRemainingLoot());
          expect(session.phase, SessionPhase.shipwreck);
          expect(session.currentWreck!.stage, WreckStage.recovery);
          expect(session.currentWreck!.threatCleared, isTrue);
          expect(
            () => _choose(session, WreckRecoveryChoice.deeperRecovery),
            throwsStateError,
          );
          _choose(session, WreckRecoveryChoice.recoverClearedCargo);
          expect(session.currentWreck!.cargo!.toJson(), cargo);
          expect(
            session.profile.metaInventory.seaGlass,
            condition == WreckCondition.pickedClean ? 1 : 3,
          );
          expect(session.profile.metaInventory.depthWroughtIron, 1);
          expect(
            session.ship!.gold,
            creatureGold + (condition == WreckCondition.pickedClean ? 5 : 20),
          );
          expect(session.profile.metaInventory.monsterBone, organics);
          expect(
            session.ship!.currentHp,
            20,
            reason: 'Cargo never heals directly',
          );
          expect(session.pendingLoot, hasLength(1));
          final claimed = session.profile.toJson();
          session = _reload(session, tuning);
          _choose(session, WreckRecoveryChoice.recoverClearedCargo);
          _choose(session, WreckRecoveryChoice.deeperRecovery);
          expect(session.profile.toJson(), claimed);
          expect(session.currentWreck!.stage, WreckStage.receipt);
          expect(
            () => _choose(session, WreckRecoveryChoice.depart),
            throwsStateError,
          );
          session.dispatch(const TakeAllLoot());
          final id = session.currentWreck!.id;
          _choose(session, WreckRecoveryChoice.depart);
          expect(session.phase, SessionPhase.helm);
          expect(session.seaChart.currentLeg, 3);
          expect(
            () => session.dispatch(
              ChooseWreckRecovery(id, WreckRecoveryChoice.recoverClearedCargo),
            ),
            throwsStateError,
          );
        },
      );
    }

    test('$condition can pass empty, using one slot without a deduction', () {
      final session = _arrive(condition, _tuning());
      final profile = session.profile.toJson();
      final gold = session.ship!.gold;
      _choose(session, WreckRecoveryChoice.passBy);
      expect(session.phase, SessionPhase.helm);
      expect(session.seaChart.currentLeg, 3);
      expect(session.profile.toJson(), profile);
      expect(session.ship!.gold, gold);
      expect(session.ship!.currentHp, 20);
      expect(session.pendingLoot, isEmpty);
    });
  }

  for (final condition in [WreckCondition.uncertain, WreckCondition.fresh]) {
    test(
      '$condition committed fight may be Apex and keeps full kill loot plus cargo',
      () {
        final session = _arrive(
          condition,
          _tuning(fight: true),
          apexPact: true,
        );
        _choose(session, WreckRecoveryChoice.deeperRecovery);
        expect(session.phase, SessionPhase.battle);
        expect(session.currentMonster!.isApex, isTrue);
        expect(session.currentWreck!.committed, isTrue);
        _win(session);
        expect(
          session.profile.metaInventory.monsterBone,
          inInclusiveRange(2, 3),
        );
        expect(session.profile.metaInventory.seaGlass, 0);
        session.dispatch(const LeaveRemainingLoot());
        _choose(session, WreckRecoveryChoice.recoverClearedCargo);
        expect(session.profile.metaInventory.seaGlass, 3);
      },
    );

    test(
      '$condition quiet recovery has cargo and no creature loot or immediate healing',
      () {
        final session = _arrive(condition, _tuning());
        final gold = session.ship!.gold;
        _choose(session, WreckRecoveryChoice.deeperRecovery);
        expect(session.phase, SessionPhase.shipwreck);
        expect(session.currentWreck!.stage, WreckStage.receipt);
        expect(session.monstersDefeatedThisLife, 0);
        expect(session.profile.metaInventory.monsterBone, 0);
        expect(session.ship!.gold, gold + 20);
        expect(session.ship!.currentHp, 20);
        expect(session.profile.metaInventory.seaGlass, 3);
        expect(session.pendingLoot, hasLength(1));
      },
    );
  }

  test('condition gates enforce quick/deep exclusivity and fresh has no quick haul', () {
    final fresh = _arrive(WreckCondition.fresh, _tuning());
    expect(
      () => _choose(fresh, WreckRecoveryChoice.quickSalvage),
      throwsStateError,
    );
    final picked = _arrive(WreckCondition.pickedClean, _tuning());
    expect(
      () => _choose(picked, WreckRecoveryChoice.deeperRecovery),
      throwsStateError,
    );
    final uncertain = _arrive(WreckCondition.uncertain, _tuning(fight: true));
    _choose(uncertain, WreckRecoveryChoice.quickSalvage);
    final profile = uncertain.profile.toJson();
    _choose(uncertain, WreckRecoveryChoice.deeperRecovery);
    expect(uncertain.phase, SessionPhase.shipwreck);
    expect(uncertain.currentWreck!.stage, WreckStage.receipt);
    expect(uncertain.profile.toJson(), profile);
    expect(uncertain.profile.metaInventory.seaGlass, 1);
  });

  test(
    'full belt resolves creature spoils before the independent wreck supply',
    () {
      final session = _arrive(WreckCondition.fresh, _tuning(ambush: true));
      for (var i = 0; i < session.ship!.maxCargo; i++) {
        session.ship!.addCargo(
          generateConsumable(ConsumableType.blastPack, RarityLevel.common),
        );
      }
      _win(session);
      final count = session.pendingLoot.length;
      session.dispatch(const TakeAllLoot());
      expect(session.phase, SessionPhase.loot);
      expect(session.pendingLoot, hasLength(count));
      session.dispatch(const LeaveRemainingLoot());
      _choose(session, WreckRecoveryChoice.recoverClearedCargo);
      expect(session.pendingLoot, hasLength(1));
      session.dispatch(const TakeAllLoot());
      expect(session.pendingLoot, hasLength(1));
      session.dispatch(const DropCargoItem(0));
      session.dispatch(const TakeLootItem(0));
      expect(session.pendingLoot, isEmpty);
      expect(session.phase, SessionPhase.shipwreck);
      expect(session.ship!.cargo, hasLength(session.ship!.maxCargo));
    },
  );

  test('death during recovery never banks unearned cargo', () {
    final session = _arrive(WreckCondition.fresh, _tuning(fight: true));
    _choose(session, WreckRecoveryChoice.deeperRecovery);
    session.ship!.currentHp = 0;
    session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
    expect(session.phase, SessionPhase.death);
    expect(session.currentWreck!.stage, WreckStage.lost);
    expect(session.profile.metaInventory.seaGlass, 0);
    expect(session.profile.metaInventory.depthWroughtIron, 0);
    expect(
      () => _choose(session, WreckRecoveryChoice.recoverClearedCargo),
      throwsStateError,
    );
  });

  test('supported reloads preserve assessment decisions and deterministic threat/cargo', () {
    final tuning = _tuning(fight: true);
    final original = _arrive(WreckCondition.fresh, tuning);
    final resumed = _reload(original, tuning);
    _choose(original, WreckRecoveryChoice.deeperRecovery);
    _choose(resumed, WreckRecoveryChoice.deeperRecovery);
    expect(resumed.currentWreck!.toJson(), original.currentWreck!.toJson());
    expect(resumed.currentMonster!.name, original.currentMonster!.name);
    expect(resumed.currentMonster!.maxHp, original.currentMonster!.maxHp);
    expect(resumed.currentMonster!.isApex, original.currentMonster!.isApex);
  });

  test('retired selectable rewards and stale wreck IDs cannot grant cargo', () {
    final session = _arrive(WreckCondition.uncertain, _tuning());
    final before = session.profile.toJson();
    expect(
      () => session.dispatch(const SalvageShipwreck(ShipwreckChoice.timbers)),
      throwsStateError,
    );
    expect(
      () => session.dispatch(
        const ChooseWreckRecovery(
          'another wreck',
          WreckRecoveryChoice.quickSalvage,
        ),
      ),
      throwsStateError,
    );
    expect(session.profile.toJson(), before);
  });
}
