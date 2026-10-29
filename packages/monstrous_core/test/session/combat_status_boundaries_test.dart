import 'dart:convert';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _RollRng extends SeededGameRng {
  _RollRng(this.roll) : super(42);
  final int roll;
  @override
  int d100() => roll;
}

GameSession _battle() {
  final session = GameSession(rng: _RollRng(50))
    ..dispatch(const BeginFirstVoyage('Reed', customShipName: 'Resolute'));
  session.ship!
    ..maxHp = 500
    ..currentHp = 432
    ..level = 2;
  session.ship!.hardpointMarks[HardpointType.broadside] = 2;
  session.ship!.blessings[HardpointType.utility] = const HardpointBlessing(
    power: OceanPower.brinemother,
    slot: HardpointType.utility,
    tier: 2,
  );
  return session;
}

GameSession _reload(GameSession session) {
  final save = VoyageSaveData.fromJson(
    jsonDecode(jsonEncode(VoyageSaveData.fromSession(session).toJson()))
        as Map<String, dynamic>,
  );
  final restored = GameSession(rng: _RollRng(50), profile: session.profile);
  save.restoreToSession(restored);
  return restored;
}

void _expectBuild(ShipState ship, int hp) {
  expect(ship.currentHp, hp);
  expect(ship.maxHp, 500);
  expect(ship.level, 2);
  expect(ship.name, 'Resolute');
  expect(ship.markForHardpoint(HardpointType.broadside), 2);
  expect(ship.blessings[HardpointType.utility]?.tier, 2);
}

void _prepareCrabCourse(GameSession session) {
  final chart = session.seaChart.toJson();
  chart['gridSpecies'] = [
    for (final row in chart['gridSpecies'] as List)
      [for (final _ in row as List) MonsterSpecies.crustacean.name],
  ];
  session.seaChart.restoreFromJson(chart);
  session.seaChart.setNodeTypeAt(0, 1, EncounterNodeType.beastCombat);
}

void main() {
  for (final roll in [75, 76, 100]) {
    test('Poison keeps its existing 25% recovery boundary at roll $roll', () {
      final ship = _battle().ship!..addStatus(StatusEffect.poison);
      final hp = ship.currentHp;
      final result = updateStatusEffects(ship, 3, _RollRng(roll));
      expect(ship.currentHp, hp - 15);
      expect(ship.hasStatus(StatusEffect.poison), roll <= 75);
      expect(
        result.events.whereType<StatusEffectTicked>().single.woreOff,
        roll > 75,
      );
      expect(result.canAct, isTrue);
    });
  }

  test(
    'failed recovery allows repeated Poison ticks within the same fight',
    () {
      final ship = _battle().ship!..addStatus(StatusEffect.poison);
      final hp = ship.currentHp;
      for (var turn = 1; turn <= 3; turn++) {
        updateStatusEffects(ship, 2, _RollRng(75));
        expect(ship.currentHp, hp - 10 * turn);
        expect(ship.hasStatus(StatusEffect.poison), isTrue);
      }
    },
  );

  test(
    'combat reset clears all statuses without healing or changing build',
    () {
      final ship = _battle().ship!;
      final before = ship.toJson();
      for (final status in StatusEffect.values) {
        ship.addStatus(status);
      }
      ship.resetCombatBoosts();
      expect(ship.statusEffects, isEmpty);
      expect(ship.toJson(), before);
    },
  );

  test('World Serpent victory clears Poison before Region 3 crab without healing', () {
    var session = _battle();
    session.seaChart
      ..timesCompleted = 1
      ..currentLeg = session.seaChart.totalLegs;
    session.currentMonster = createWorldSerpent(rng: _RollRng(50))
      ..currentHp = 1
      ..evasion = 0;
    session.ship!.addStatus(StatusEffect.poison);
    final hp = session.ship!.currentHp;
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.cannon),
    );
    expect(session.phase, SessionPhase.loot);
    expect(session.ship!.statusEffects, isEmpty);
    _expectBuild(session.ship!, hp);
    // Terminal playback keeps the exact final impact and its preceding effects;
    // cleanup must not retroactively erase the captured Poison state.
    expect(events.whereType<AttackHit>().last.remainingHp, 0);
    expect(
      events.whereType<CombatEffectsChanged>().any(
        (event) =>
            event.target == CombatSide.ship &&
            event.state.statusEffects.contains(StatusEffect.poison),
      ),
      isTrue,
    );
    session.dispatch(const LeaveRemainingLoot());
    session.dispatch(const TakeHelm());
    expect(session.phase, SessionPhase.stronghold);
    expect(session.seaChart.currentRegionIndex, 2);
    session = _reload(session);
    _expectBuild(session.ship!, hp);
    expect(session.ship!.statusEffects, isEmpty);
    session.dispatch(const TakeHelm());
    _prepareCrabCourse(session);
    session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
    expect(session.currentMonster!.species, MonsterSpecies.crustacean);
    expect(session.ship!.statusEffects, isEmpty);
    _expectBuild(session.ship!, hp);
    session.currentMonster!.currentIntent = MonsterIntent.fromId(
      MonsterIntentId.normalStrike,
    );
    final crabTurn = session.dispatch(const BraceForImpact());
    expect(
      crabTurn.whereType<StatusEffectTicked>().where(
        (event) =>
            event.target == CombatSide.ship && event.effectName == 'Poison',
      ),
      isEmpty,
    );
  });

  for (final phase in [
    SessionPhase.loot,
    SessionPhase.restArea,
    SessionPhase.helm,
    SessionPhase.stronghold,
  ]) {
    test(
      'dirty in-memory ${phase.name} checkpoint drops combat statuses only',
      () {
        final session = _battle()..phase = phase;
        for (final status in StatusEffect.values) {
          session.ship!.addStatus(status);
        }
        final expected = session.ship!.toJson();
        final saved = VoyageSaveData.fromSession(session);
        expect(saved.ship.statusEffects, hasLength(3));
        final restored = GameSession(rng: _RollRng(50));
        saved.restoreToSession(restored);
        expect(restored.ship!.statusEffects, isEmpty);
        expect(restored.ship!.toJson(), expected);
      },
    );
  }

  test('serialized older status fields cannot reinstate Poison on reload', () {
    final session = _battle()..phase = SessionPhase.stronghold;
    session.ship!.addStatus(StatusEffect.poison);
    final json = VoyageSaveData.fromSession(session).toJson();
    (json['ship'] as Map<String, dynamic>)['statusEffects'] = ['poison'];
    final restored = GameSession(rng: _RollRng(50));
    VoyageSaveData.fromJson(json).restoreToSession(restored);
    expect(restored.ship!.statusEffects, isEmpty);
    _expectBuild(restored.ship!, 432);
  });

  test(
    'encounter startup clears dirty in-memory statuses without a reload',
    () {
      final session = _battle()..phase = SessionPhase.stronghold;
      session.seaChart.timesCompleted = 2;
      session.seaChart.currentLeg = 0;
      session.dispatch(const TakeHelm());
      _prepareCrabCourse(session);
      final hp = session.ship!.currentHp;
      session.ship!.addStatus(StatusEffect.poison);
      session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
      expect(session.ship!.statusEffects, isEmpty);
      _expectBuild(session.ship!, hp);
    },
  );
}
