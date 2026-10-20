import 'dart:convert';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

GameSession fresh() => GameSession(rng: SeededGameRng(84));

void main() {
  test('restoring a defeated titan checkpoint advances regions without repeating the boss', () {
    final session = fresh()..dispatch(const BeginFirstVoyage('Davy Jones'));
    session.currentMonster!.currentHp = 1;
    while (session.phase == SessionPhase.battle) {
      session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
    }
    session.dispatch(const TakeAllLoot());
    expect(session.phase, SessionPhase.restArea);
    final saved = VoyageSaveData.fromJson(
      jsonDecode(jsonEncode(VoyageSaveData.fromSession(session).toJson()))
          as Map<String, dynamic>,
    );
    final restored = fresh();
    saved.restoreToSession(restored);
    expect(restored.currentMonster, isNull);
    expect(restored.hasDefeatedCurrentEncounter, isTrue);
    final events = restored.dispatch(const AdvanceToNextBattle());
    expect(events.whereType<RegionTransitioned>(), hasLength(1));
    expect(restored.phase, SessionPhase.stronghold);
    expect(restored.seaChart.currentRegionIndex, 1);
    expect(restored.seaChart.currentLeg, 0);
  });

  test('an heir starts a fresh voyage with permanent upgrades and no previous voyage refits', () {
    final session = fresh()..dispatch(const BeginFirstVoyage('Reed'));
    session.profile.blueprintArmamentTiers[BlueprintId.standard.name] = 2;
    session.profile.hasExpandedAuxiliarySlot = true;
    session.ship!.gold = 1000;
    final beltItem = generateConsumable(
      ConsumableType.blastPack,
      RarityLevel.common,
    );
    session.ship!.addCargo(beltItem);
    session.phase = SessionPhase.respiteIsland;
    session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
    session.dispatch(const UpgradeShip());
    session.dispatch(const TemperHardpoint(HardpointType.broadside));
    session.dispatch(const TemperHardpoint(HardpointType.signature));
    session.phase = SessionPhase.battle;
    session.ship!.applyDamage(session.ship!.maxHp);
    session.dispatch(const ExecuteShipSpecialAction());
    session.dispatch(const ContinueLineage('Next Reed', ShipClass.standard));
    session.dispatch(const VentureOutToSea());
    expect(session.ship!.level, 1);
    expect(session.ship!.hardpointMarks.values, everyElement(1));
    expect(session.ship!.gold, 25);
    expect(session.ship!.cargo, isEmpty);
    expect(
      session.ship!.equippedWeapons.where((w) => w.isSignature).single.name,
      endsWith('II'),
    );
    expect(
      session.ship!.maxHp,
      FlagshipBlueprint.catalog[BlueprintId.standard]!.baseHp,
    );
    expect(session.ship!.currentHp, session.ship!.maxHp);
  });

  test(
    'first voyage names and commissions Standard straight into combat at Leg 1',
    () {
      final session = fresh();
      final events = session.dispatch(
        const BeginFirstVoyage('Captain Reed', customShipName: 'Resolute'),
      );
      expect(session.captainName, 'Captain Reed');
      expect(session.ship!.name, 'Resolute');
      expect(session.ship!.blueprintId, BlueprintId.standard.name);
      expect(session.phase, SessionPhase.battle);
      expect(session.currentMonster, isNotNull);
      expect(events.whereType<BattleStarted>(), hasLength(1));
      expect(session.seaChart.currentLeg, 1);
      expect(session.seaChart.voyageLog.single.leg, 1);
      expect(session.profile.hasBegunFirstVoyage, isTrue);
      expect(session.ship!.hardpointMarks.values, everyElement(1));
      expect(session.ship!.level, 1);
    },
  );

  test(
    'Davy Jones still enters Kraken combat through first-voyage onboarding',
    () {
      final session = fresh()..dispatch(const BeginFirstVoyage('Davy Jones'));
      expect(session.phase, SessionPhase.battle);
      expect(session.ship!.name, 'Flying Dutchman');
      expect(session.currentMonster!.species, MonsterSpecies.kraken);
    },
  );

  for (final shipClass in ShipClass.values.where(
    (s) => s != ShipClass.standard,
  )) {
    test('ChooseShip requires the actual blueprint unlock for $shipClass', () {
      final session = fresh()..dispatch(const NameCaptain('Lock Test'));
      expect(() => session.dispatch(ChooseShip(shipClass)), throwsStateError);
      expect(session.ship, isNull);
      expect(session.phase, SessionPhase.captainCreation);
      session.profile.unlockedBlueprints.add(
        BlueprintId.fromShipClass(shipClass).name,
      );
      session.dispatch(ChooseShip(shipClass));
      expect(session.phase, SessionPhase.port);
      expect(
        session.ship!.blueprintId,
        BlueprintId.fromShipClass(shipClass).name,
      );
    });
  }

  test(
    'locked heir blueprint rejects before changing name, traits, or candidates',
    () {
      final session = fresh()
        ..dispatch(const BeginFirstVoyage('Original Captain'))
        ..phase = SessionPhase.death;
      final previousShip = session.ship;
      expect(
        () => session.dispatch(
          const ContinueLineage('Intruder', ShipClass.corvette),
        ),
        throwsStateError,
      );
      expect(session.captainName, 'Original Captain');
      expect(session.ship, same(previousShip));
      expect(session.phase, SessionPhase.death);
    },
  );

  test('port cannot temper or refit even with unlimited gold; Haven can', () {
    final session = fresh()..dispatch(const ChooseShip(ShipClass.standard));
    session.ship!.gold = 10000;
    expect(() => session.dispatch(const UpgradeShip()), throwsStateError);
    expect(
      () => session.dispatch(const TemperHardpoint(HardpointType.signature)),
      throwsStateError,
    );
    expect(session.ship!.gold, 10000);
    expect(session.ship!.level, 1);
    expect(session.ship!.markForHardpoint(HardpointType.signature), 1);
    session.phase = SessionPhase.respiteIsland;
    session.seaChart.currentLeg = 2;
    expect(
      session.dispatch(const UpgradeShip()).whereType<ShipUpgraded>(),
      isEmpty,
    );
    expect(
      session
          .dispatch(const TemperHardpoint(HardpointType.signature))
          .whereType<HardpointTempered>(),
      isEmpty,
    );
    session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
    expect(
      session.dispatch(const UpgradeShip()).whereType<ShipUpgraded>(),
      hasLength(1),
    );
    expect(
      session
          .dispatch(const TemperHardpoint(HardpointType.signature))
          .whereType<HardpointTempered>(),
      hasLength(1),
    );
  });

  test('new commissioning starts base hull and all Mk I despite old ship and auxiliary unlock', () {
    final session = fresh()..dispatch(const ChooseShip(ShipClass.standard));
    session.profile.hasExpandedAuxiliarySlot = true;
    session.ship!.level = 4;
    temperShipHardpoint(session.ship!, HardpointType.broadside);
    session.dispatch(const CommissionBlueprint(BlueprintId.standard));
    expect(session.ship!.level, 1);
    expect(session.ship!.hardpointMarks.values, everyElement(1));
    final expected = createFlagshipFromBlueprint(
      BlueprintId.standard,
      rng: SeededGameRng(2),
      hasExpandedAuxiliarySlot: true,
    );
    expect(session.ship!.maxHp, expected.maxHp);
    expect(session.ship!.maxCargo, expected.maxCargo);
  });

  test('legacy Advance and SteerCourse share accurate Leg 1, 2, 3 trail', () {
    final session = fresh()..dispatch(const BeginFirstVoyage('Navigator'));
    for (var col = 1; col < 4; col++) {
      session.seaChart.setNodeTypeAt(0, col, EncounterNodeType.beastCombat);
    }
    session.currentMonster!.currentHp = 0;
    session.phase = SessionPhase.restArea;
    session.dispatch(const AdvanceToNextBattle());
    expect(session.phase, SessionPhase.battle);
    expect(session.seaChart.currentLeg, 2);
    expect(session.seaChart.voyageLog.map((e) => e.leg), [1, 2]);
    session.currentMonster!.currentHp = 0;
    session.phase = SessionPhase.restArea;
    session.dispatch(const TakeHelm());
    session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
    expect(session.seaChart.currentLeg, 3);
    expect(session.seaChart.voyageLog.map((e) => e.leg), [1, 2, 3]);
    expect(
      session.seaChart.voyageLog.last.chartRow,
      session.seaChart.currentRow,
    );
    expect(
      session.seaChart.voyageLog.last.chartCol,
      session.seaChart.currentCol,
    );
  });

  test(
    'heading coordinate prediction agrees across the chart row boundary',
    () {
      final chart = SeaChart(currentRow: 0, currentCol: 4, currentLeg: 5);
      chart.setNodeTypeAt(1, 0, EncounterNodeType.ancientShrine);
      final chosen = chart.steerCourse(NavigationalBearing.deadAhead);
      expect(chosen.nodeType, EncounterNodeType.ancientShrine);
      expect(chart.currentNodeType, EncounterNodeType.ancientShrine);
      expect((chart.currentRow, chart.currentCol), (1, 0));
    },
  );

  test(
    'early visits to old boss coordinates do not shorten ten-leg regions',
    () {
      final chart = SeaChart(currentRow: 3, currentCol: 3, currentLeg: 3);
      chart.setNodeTypeAt(3, 4, EncounterNodeType.beastCombat);
      chart.steerCourse(NavigationalBearing.deadAhead);
      expect(chart.currentLeg, 4);
      expect(chart.isRegionTitan, isFalse);
      expect(
        chart.ensureCourseOptions().single.nodeType,
        EncounterNodeType.respiteIsland,
      );
    },
  );

  test(
    'new departure clears the previous voyage trail and starts Leg 1 again',
    () {
      final session = fresh()..dispatch(const BeginFirstVoyage('Navigator'));
      session.seaChart.steerCourse(NavigationalBearing.deadAhead);
      session.phase = SessionPhase.port;
      session.dispatch(const VentureOutToSea());
      expect(session.seaChart.currentLeg, 1);
      expect(session.seaChart.voyageLog, hasLength(1));
      expect(
        (session.seaChart.currentRow, session.seaChart.currentCol),
        (0, 0),
      );
      expect(session.phase, SessionPhase.battle);
    },
  );

  test('voyage save restores trail, current leg, current encounter, and exact offered courses', () {
    final session = fresh()..dispatch(const BeginFirstVoyage('Navigator'));
    session.seaChart.steerCourse(NavigationalBearing.starboardTack);
    session.phase = SessionPhase.restArea;
    session.dispatch(const TakeHelm());
    final original = session.seaChart.toJson();
    final encoded = jsonEncode(VoyageSaveData.fromSession(session).toJson());
    final save = VoyageSaveData.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    final restored = GameSession(rng: SeededGameRng(999));
    save.restoreToSession(restored);
    expect(restored.seaChart.toJson(), original);
    expect(restored.profile.hasBegunFirstVoyage, isTrue);
    final selected = restored.seaChart.currentCourseOptions.first;
    restored.dispatch(SteerCourse(selected.bearing));
    expect(restored.seaChart.currentLeg, 3);
    expect(restored.seaChart.voyageLog.last.nodeType, selected.nodeType);
  });

  test(
    'profile first-voyage flag persists and legacy earned progress migrates',
    () {
      expect(
        ProfileData.fromJson(ProfileData().toJson()).hasBegunFirstVoyage,
        isFalse,
      );
      final session = fresh()..dispatch(const BeginFirstVoyage('Reed'));
      expect(
        ProfileData.fromJson(session.profile.toJson()).hasBegunFirstVoyage,
        isTrue,
      );
      final legacy = ProfileData().toJson()..remove('hasBegunFirstVoyage');
      legacy['metaInventory'] = MetaInventory(seaGlass: 1).toJson();
      expect(ProfileData.fromJson(legacy).hasBegunFirstVoyage, isTrue);
    },
  );

  test(
    'spent legacy consumable cannot use a quick action or grant its effect',
    () {
      final session = fresh()..dispatch(const BeginFirstVoyage('Reed'));
      final item = generateConsumable(
        ConsumableType.hullPatchKit,
        RarityLevel.common,
      )..usesLeft = 0;
      session.ship!.addCargo(item);
      session.ship!.currentHp = 10;
      expect(
        () =>
            session.dispatch(UseConsumableItem(session.ship!.cargo.length - 1)),
        throwsStateError,
      );
      expect(session.ship!.currentHp, 10);
      expect(session.quickConsumablesUsedThisTurn, 0);
    },
  );
}
