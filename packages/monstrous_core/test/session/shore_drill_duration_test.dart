import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Hits extends SeededGameRng {
  _Hits() : super(7);
  @override
  int d100() => 1;
}

GameSession _drilled() {
  final session = GameSession(
    rng: _Hits(),
    navigationTuning: const NavigationTuning(
      wrecks: WreckTuning(approachAmbushChance: 100),
    ),
  )..dispatch(const BeginFirstVoyage('Drill regression'));
  session.phase = SessionPhase.respiteIsland;
  session.seaChart.currentDestination = CourseDestination.midpointHaven;
  session.seaChart.currentLeg = 5;
  session.dispatch(const DrillGunnersAtIsland());
  session.ship!
    ..maxHp = 1000000
    ..currentHp = 1000000;
  return session;
}

void _enter(GameSession session, CourseOption option) {
  if (session.phase != SessionPhase.helm) session.dispatch(const TakeHelm());
  final state = session.seaChart.toJson()
    ..['courseOptions'] = [option.toJson()];
  session.seaChart.restoreFromJson(state);
  session.dispatch(SteerCourse(option.bearing));
}

CourseOption _ordinary(EncounterNodeType type) => CourseOption(
  bearing: NavigationalBearing.deadAhead,
  nodeType: type,
  difficultyLevel: 4,
  lookoutCall: 'Duration regression',
  monsterSpecies: MonsterSpecies.shark,
);

void main() {
  test('drill survives peaceful encounters/reload, refreshes and benefits every volley', () {
    var session = _drilled();
    expect(session.gunneryAccuracyBoon, 10);
    _enter(session, _ordinary(EncounterNodeType.ancientShrine));
    expect(session.gunneryAccuracyBoon, 10);
    session.dispatch(const DepartShrine());
    _enter(session, _ordinary(EncounterNodeType.respiteIsland));
    session.dispatch(const DrillGunnersAtIsland());
    expect(session.gunneryAccuracyBoon, 10, reason: 'Refresh does not stack');
    final saved = VoyageSaveData.fromJson(
      VoyageSaveData.fromSession(session).toJson(),
    );
    session = GameSession(rng: _Hits(), profile: session.profile);
    saved.restoreToSession(session);
    expect(session.shoreDrillBoon, 10);
    _enter(session, _ordinary(EncounterNodeType.beastCombat));
    session.currentMonster!
      ..maxHp = 1000000
      ..currentHp = 1000000
      ..evasion = 0
      ..carapacePlating = 0;
    for (var turn = 0; turn < 3; turn++) {
      final events = session.dispatch(
        const FireWeaponVolley(ShipWeaponType.cannon),
      );
      expect(events.whereType<AttackAttempted>().first.targetAc, 95);
      expect(session.gunneryAccuracyBoon, 10);
    }
    session.currentMonster!.currentHp = 0;
    session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
    expect(session.gunneryAccuracyBoon, 0);
    expect(session.shoreDrillBoon, 0);
  });

  for (final kind in ['wreck', 'Nemesis', 'Titan']) {
    test('drill lasts the whole $kind fight and expires at its victory', () {
      final session = _drilled();
      if (kind == 'wreck') {
        _enter(
          session,
          const CourseOption(
            bearing: NavigationalBearing.deadAhead,
            nodeType: EncounterNodeType.shipwreckSalvage,
            difficultyLevel: 4,
            lookoutCall: 'Wreck',
            wreckSighting: WreckSighting(
              seed: 81,
              condition: WreckCondition.fresh,
              clearClue: true,
            ),
          ),
        );
      } else if (kind == 'Nemesis') {
        session.profile.activeNemesis = NemesisRecord(
          species: MonsterSpecies.shark,
          baseName: 'Shark',
          moniker: 'Old Red',
          predecessorCaptain: 'Reed',
          regionIndex: 0,
          level: 4,
          bonusHp: 10,
          bonusCarapace: 2,
          bountyGold: 50,
          bountySeaGlass: 2,
          bountyMonsterBone: 2,
          bountyBarnacles: 1,
        );
        _enter(
          session,
          const CourseOption(
            bearing: NavigationalBearing.deadAhead,
            nodeType: EncounterNodeType.beastCombat,
            difficultyLevel: 4,
            monsterSpecies: MonsterSpecies.shark,
            lookoutCall: 'Nemesis',
            isNemesis: true,
          ),
        );
      } else {
        _enter(
          session,
          const CourseOption(
            bearing: NavigationalBearing.deadAhead,
            nodeType: EncounterNodeType.regionTitan,
            difficultyLevel: 5,
            lookoutCall: 'Titan',
            destination: CourseDestination.titan,
          ),
        );
      }
      expect(session.phase, SessionPhase.battle);
      session.currentMonster!
        ..maxHp = 1000000
        ..currentHp = 1000000;
      for (var turn = 0; turn < 3; turn++) {
        session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
        expect(session.shoreDrillBoon, 10);
        expect(session.gunneryAccuracyBoon, 10);
      }
      session.currentMonster!.currentHp = 0;
      session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(session.shoreDrillBoon, 0);
      expect(session.gunneryAccuracyBoon, 0);
    });
  }

  test('runes remain separate, and drill refresh preserves their nonstacking bonus', () {
    final session = _drilled();
    _enter(session, _ordinary(EncounterNodeType.ancientShrine));
    session.dispatch(const CommuneWithShrine(ShrineChoice.ancientRunes));
    expect(session.runicGuidanceBoon, 10);
    expect(session.gunneryAccuracyBoon, 20);
    session.dispatch(const DepartShrine());
    _enter(session, _ordinary(EncounterNodeType.respiteIsland));
    session.dispatch(const DrillGunnersAtIsland());
    expect(session.runicGuidanceBoon, 10);
    expect(session.gunneryAccuracyBoon, 20);
  });
}
