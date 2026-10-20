import 'dart:convert';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

GameSession preparedTitan(int region) {
  final session = GameSession(rng: SeededGameRng(42))
    ..dispatch(const BeginFirstVoyage('Reed', customShipName: 'Resolute'));
  session.seaChart.timesCompleted = region;
  session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
  session.phase = SessionPhase.respiteIsland;
  session.ship!.gold = 4000;
  session.dispatch(const UpgradeShip());
  for (final slot in blessingHardpoints) {
    session.dispatch(TemperHardpoint(slot));
    session.ship!.blessings[slot] = HardpointBlessing(
      power: OceanPower.brinemother,
      slot: slot,
      tier: 2,
    );
  }
  session.ship!.addCargo(
    generateConsumable(ConsumableType.blastPack, RarityLevel.common),
  );
  session.ship!.applyDamage(20);
  session.monstersDefeatedThisLife = 8;
  session.highestDifficultyThisLife = 5;
  session.seaChart.currentLeg = session.seaChart.totalLegs;
  session.hasDefeatedCurrentEncounter = true;
  session.currentMonster = null;
  session.phase = SessionPhase.restArea;
  return session;
}

GameSession reload(GameSession session) {
  final save = VoyageSaveData.fromJson(
    jsonDecode(jsonEncode(VoyageSaveData.fromSession(session).toJson()))
        as Map<String, dynamic>,
  );
  final restored = GameSession(
    rng: SeededGameRng(42),
    profile: ProfileData.fromJson(session.profile.toJson()),
  );
  save.restoreToSession(restored);
  return restored;
}

void main() {
  for (final region in [0, 1]) {
    for (final advance in [const TakeHelm(), const AdvanceToNextBattle()]) {
      test(
        'region $region ${advance.runtimeType} preserves the build through stronghold and next combat',
        () {
          var session = reload(preparedTitan(region));
          final shipBefore = session.ship!.toJson();
          final events = session.dispatch(advance);
          expect(events.whereType<RegionTransitioned>(), hasLength(1));
          expect(session.phase, SessionPhase.stronghold);
          expect(session.seaChart.currentRegionIndex, region + 1);
          expect(session.seaChart.currentLeg, 0);
          expect(session.ship!.toJson(), shipBefore);
          session = reload(session);
          expect(session.phase, SessionPhase.stronghold);
          expect(session.ship!.toJson(), shipBefore);
          session.dispatch(const TakeHelm());
          session = reload(session);
          expect(session.ship!.toJson(), shipBefore);
          session.seaChart.setNodeTypeAt(0, 1, EncounterNodeType.beastCombat);
          session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
          expect(session.phase, SessionPhase.battle);
          expect(session.seaChart.currentLeg, 1);
          expect(session.captainName, 'Reed');
          expect(session.ship!.name, 'Resolute');
          expect(session.ship!.level, 2);
          expect(session.ship!.hardpointMarks.values, everyElement(2));
          expect(
            session.ship!.blessings.values.map((b) => b.tier),
            everyElement(2),
          );
          expect(session.ship!.gold, shipBefore['gold']);
          expect(session.ship!.cargo, hasLength(1));
          expect(session.monstersDefeatedThisLife, 8);
        },
      );
    }
  }

  test(
    'strongholds and Havens charge the same gold and enforce identical caps',
    () {
      final haven = preparedTitan(0)..phase = SessionPhase.respiteIsland;
      haven.seaChart.currentLeg = haven.seaChart.midpointHavenLeg;
      final stronghold = reload(haven)..phase = SessionPhase.stronghold;
      for (final command in [
        const UpgradeShip(),
        const UpgradeShip(),
        const UpgradeShip(),
        const TemperHardpoint(HardpointType.broadside),
        const TemperHardpoint(HardpointType.broadside),
      ]) {
        haven.dispatch(command);
        stronghold.dispatch(command);
        expect(stronghold.ship!.toJson(), haven.ship!.toJson());
      }
      expect(stronghold.ship!.level, 4);
      expect(stronghold.ship!.markForHardpoint(HardpointType.broadside), 3);
      final before = stronghold.ship!.toJson();
      stronghold.dispatch(const UpgradeShip());
      stronghold.dispatch(const TemperHardpoint(HardpointType.broadside));
      expect(stronghold.ship!.toJson(), before);
      stronghold.ship!.gold = 0;
      final noGold = stronghold.ship!.toJson();
      stronghold.dispatch(const TemperHardpoint(HardpointType.utility));
      expect(stronghold.ship!.toJson(), noGold);
    },
  );

  test('stronghold merchant returns to the same berth after reload', () {
    var session = preparedTitan(0)..dispatch(const TakeHelm());
    session.dispatch(const VisitMerchant());
    session = reload(session);
    expect(session.phase, SessionPhase.merchant);
    expect(session.merchantReturnPhase, SessionPhase.stronghold);
    session.dispatch(const LeaveMerchant());
    expect(session.phase, SessionPhase.stronghold);
    expect(session.ship!.level, 2);
  });

  test(
    'legacy stronghold and merchant checkpoints do not become home visits',
    () {
      final original = preparedTitan(0)..dispatch(const TakeHelm());
      for (final phase in ['port', 'merchant']) {
        for (final hasChart in [true, false]) {
          final json = VoyageSaveData.fromSession(original).toJson()
            ..['phase'] = phase
            ..remove('merchantReturnPhase');
          if (!hasChart) json.remove('seaChartState');
          final restored = GameSession(rng: SeededGameRng(1));
          VoyageSaveData.fromJson(json).restoreToSession(restored);
          if (phase == 'merchant') restored.dispatch(const LeaveMerchant());
          expect(restored.phase, SessionPhase.stronghold);
          expect(
            restored.seaChart.currentLeg,
          0,
          );
          expect(restored.ship!.blessings, hasLength(3));
          restored.dispatch(const VentureOutToSea());
          expect(restored.phase, SessionPhase.helm);
          expect(restored.ship!.level, 2);
        }
      }
    },
  );

  test('permanent progression cannot be bought at sea or at a stronghold', () {
    final session = preparedTitan(0)..dispatch(const TakeHelm());
    final commands = <Command>[
      const UnlockBlueprint(BlueprintId.ironclad),
      const CommissionBlueprint(BlueprintId.standard),
      const UpgradeBlueprintArmament(BlueprintId.standard),
      const UnlockAuxiliaryExpansion(),
      const UnlockEldritchRelic(EldritchRelicId.siphonRam),
      const UpgradeHarborMonument(HarborMonumentId.obsidianObelisk),
      const ToggleCovenantPact(CovenantPactId.chokingFog),
      const ReturnToPort(),
    ];
    for (final phase in [
      SessionPhase.stronghold,
      SessionPhase.helm,
      SessionPhase.merchant,
      SessionPhase.restArea,
    ]) {
      session.phase = phase;
      final before = jsonEncode(session.profile.toJson());
      for (final command in commands) {
        expect(
          () => session.dispatch(command),
          throwsStateError,
          reason: '$phase ${command.runtimeType}',
        );
        expect(jsonEncode(session.profile.toJson()), before);
      }
    }
  });
}
