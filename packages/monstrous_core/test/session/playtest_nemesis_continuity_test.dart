import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

NemesisRecord nemesisFor(int region, GameRng rng) =>
    NemesisRecord.createFromDefeat(
      killer: createShark(level: 2, rng: rng),
      captainName: 'Predecessor',
      regionIndex: region,
      rng: rng,
    );

void approachHelm(GameSession session) {
  if (session.phase == SessionPhase.battle) {
    session.currentMonster!.applyDamage(session.currentMonster!.maxHp);
    session.dispatch(
      FireWeaponVolley(session.ship!.equippedWeapons.first.weaponType),
    );
    session.dispatch(const LeaveRemainingLoot());
  }
  if (session.phase == SessionPhase.shipwreck) {
    session.dispatch(const SalvageShipwreck(ShipwreckChoice.timbers));
  }
  session.dispatch(const TakeHelm());
}

void main() {
  for (var region = 0; region < SeaChart.totalRegions; region++) {
    test(
      'region $region guarantees optional Nemesis courses only after Haven',
      () {
        final rng = SeededGameRng(42 + region);
        final profile = ProfileData(activeNemesis: nemesisFor(region, rng));
        final session = GameSession(rng: rng, profile: profile);
        session.seaChart.timesCompleted = region;
        session.dispatch(const BeginFirstVoyage('Navigator'));

        while (session.seaChart.currentLeg < session.seaChart.totalLegs) {
          approachHelm(session);
          final chart = session.seaChart;
          final targetLeg = chart.currentLeg + 1;
          final options = chart.currentCourseOptions;
          final nemeses = options.where((option) => option.isNemesis);
          if (targetLeg > chart.midpointHavenLeg &&
              targetLeg < chart.totalLegs) {
            expect(nemeses, hasLength(1), reason: 'upcoming leg $targetLeg');
            expect(options, hasLength(3));
            expect(
              nemeses.single.bearing,
              isNot(NavigationalBearing.deadAhead),
            );
            expect(
              nemeses.single.lookoutCall,
              contains(profile.activeNemesis!.moniker),
            );
          } else {
            expect(nemeses, isEmpty, reason: 'upcoming leg $targetLeg');
          }
          if (targetLeg == chart.midpointHavenLeg ||
              targetLeg == chart.totalLegs) {
            expect(options, hasLength(1));
          }

          // Avoiding vengeance is valid without Blood Oath, including every
          // second-half offer. Follow the real session flow, not a leg jump.
          session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
          expect(chart.currentIsNemesis, isFalse);
          expect(chart.currentCourseOptions, isEmpty);
        }
        expect(profile.activeNemesis, isNotNull);
        expect(session.seaChart.hasEncounteredNemesisThisVoyage, isFalse);
      },
    );
  }

  test('legacy boss coordinates cannot veto an eligible Nemesis course', () {
    final rng = SeededGameRng(55);
    final chart = SeaChart(
      currentRow: 3,
      currentCol: 3,
      currentLeg: 5,
      rng: rng,
    );
    final nemesis = nemesisFor(0, rng);
    final options = chart.ensureCourseOptions(rng, nemesis);
    final selected = options.singleWhere((option) => option.isNemesis);
    chart.steerCourse(selected.bearing, rng);
    expect(chart.currentIsNemesis, isTrue);
    expect(chart.hasEncounteredNemesisThisVoyage, isTrue);
    expect(
      chart.ensureCourseOptions(rng, nemesis).where((o) => o.isNemesis),
      isEmpty,
    );
  });

  test('a Nemesis from a different region is not offered', () {
    final rng = SeededGameRng(77);
    final chart = SeaChart(currentLeg: 6, rng: rng);
    expect(
      chart
          .ensureCourseOptions(rng, nemesisFor(1, rng))
          .where((o) => o.isNemesis),
      isEmpty,
    );
  });

  test(
    'legacy advance honors Blood Oath instead of selecting a forbidden course',
    () {
      final rng = SeededGameRng(19);
      final session = GameSession(
        rng: rng,
        profile: ProfileData(activeNemesis: nemesisFor(0, rng)),
      )..dispatch(const BeginFirstVoyage('Avenger'));
      session.activeQuirk = BloodlineTrait.bloodOath;
      session.phase = SessionPhase.restArea;
      session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
      session.dispatch(const AdvanceToNextBattle());
      expect(session.phase, SessionPhase.battle);
      expect(session.isNemesisBattle, isTrue);
    },
  );

  test('later courses retain Covenant fog and Apex context', () {
    final session = GameSession(
      rng: SeededGameRng(73),
      profile: ProfileData(
        activePacts: {CovenantPactId.chokingFog, CovenantPactId.apexEmergence},
      ),
    )..seaChart.timesCompleted = 2;
    session.dispatch(const BeginFirstVoyage('Navigator'));
    var combatOffers = 0;
    for (var leg = 2; leg < session.seaChart.midpointHavenLeg; leg++) {
      approachHelm(session);
      for (final option in session.seaChart.currentCourseOptions) {
        expect(option.lookoutCall, contains('completely obscured'));
        if (option.nodeType == EncounterNodeType.beastCombat) {
          combatOffers++;
          // Region 3's 50% Apex chance doubles to 100% under the pact.
          expect(option.isApex, isTrue);
        }
      }
      session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
    }
    expect(combatOffers, greaterThan(0));
  });

  test('legacy unseen cached offers are regenerated with restored Nemesis context', () {
    final rng = SeededGameRng(12);
    final profile = ProfileData(activeNemesis: nemesisFor(0, rng));
    final session = GameSession(rng: rng, profile: profile)
      ..dispatch(const BeginFirstVoyage('Navigator'));
    session.phase = SessionPhase.restArea;
    session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
    // Simulate an old checkpoint: offers were cached without profile context.
    expect(
      session.seaChart.ensureCourseOptions(rng).where((o) => o.isNemesis),
      isEmpty,
    );
    final saved = VoyageSaveData.fromJson(
      VoyageSaveData.fromSession(session).toJson(),
    );
    final restored = GameSession(
      rng: SeededGameRng(13),
      profile: ProfileData.fromJson(profile.toJson()),
    );
    saved.restoreToSession(restored);
    restored.dispatch(const TakeHelm());
    expect(
      restored.seaChart.currentCourseOptions.where((o) => o.isNemesis),
      hasLength(1),
    );

    // Once the player has seen the choices at the helm, reload must preserve
    // those exact choices and their Nemesis bearing rather than rerolling them.
    final helmSave = VoyageSaveData.fromJson(
      VoyageSaveData.fromSession(restored).toJson(),
    );
    final resumed = GameSession(
      rng: SeededGameRng(99),
      profile: ProfileData.fromJson(profile.toJson()),
    );
    helmSave.restoreToSession(resumed);
    expect(resumed.seaChart.toJson(), restored.seaChart.toJson());
    final nemesisCourse = resumed.seaChart.currentCourseOptions.singleWhere(
      (o) => o.isNemesis,
    );
    resumed.dispatch(SteerCourse(nemesisCourse.bearing));
    expect(resumed.isNemesisBattle, isTrue);
    expect(resumed.currentMonster!.name, profile.activeNemesis!.moniker);
  });

  test('two actual deaths record two captains, not six heir candidates', () {
    final session = GameSession(rng: SeededGameRng(123))
      ..dispatch(const BeginFirstVoyage('Founder'));
    for (var death = 1; death <= 2; death++) {
      session.ship!.applyDamage(session.ship!.maxHp);
      final events = session.dispatch(const ExecuteShipSpecialAction());
      expect(events.whereType<CaptainLost>(), hasLength(1));
      expect(session.pendingHeirCandidates, hasLength(3));
      expect(session.lineage.captainsLost, death);
      expect(session.lineage.history, hasLength(death));
      if (death == 1) {
        final candidate = session.pendingHeirCandidates[1];
        session.dispatch(
          ContinueLineage(
            'Heir',
            ShipClass.standard,
            boon: candidate.boon,
            quirk: candidate.quirk,
          ),
        );
        expect(session.lineage.captainsLost, 1);
        session.dispatch(const VentureOutToSea());
      }
    }
    final loaded = ProfileData.fromJson(session.profile.toJson());
    expect(loaded.lineageTracker.captainsLost, 2);
    expect(loaded.lineageTracker.history.map((record) => record.captainName), [
      'Founder',
      'Heir',
    ]);
  });
}
