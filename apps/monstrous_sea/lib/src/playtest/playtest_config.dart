import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../services/storage_service.dart';

enum PlaytestDestination { regionStart, titan, caldera }

const playtestSlots = [
  HardpointType.broadside,
  HardpointType.signature,
  HardpointType.utility,
];

class PlaytestHardpoint {
  const PlaytestHardpoint({this.mark = 1, this.power, this.blessingTier = 1});
  final int mark;
  final OceanPower? power;
  final int blessingTier;
}

class PlaytestConfig {
  PlaytestConfig({
    this.blueprint = BlueprintId.standard,
    this.hullTier = 1,
    this.armamentTier = 1,
    this.region = 0,
    this.destination = PlaytestDestination.regionStart,
    this.gold = 250,
    this.seed = 42,
    Map<HardpointType, PlaytestHardpoint> hardpoints = const {},
  }) : hardpoints = Map.unmodifiable({
         for (final slot in playtestSlots)
           slot: hardpoints[slot] ?? const PlaytestHardpoint(),
       }) {
    RangeError.checkValueInInterval(hullTier, 1, 4, 'hullTier');
    RangeError.checkValueInInterval(armamentTier, 1, 3, 'armamentTier');
    RangeError.checkValueInInterval(region, 0, 2, 'region');
    RangeError.checkValueInInterval(gold, 0, 999999, 'gold');
    RangeError.checkValueInInterval(seed, 0, 2147483647, 'seed');
    for (final hardpoint in this.hardpoints.values) {
      RangeError.checkValueInInterval(hardpoint.mark, 1, 3, 'mark');
      RangeError.checkValueInInterval(
        hardpoint.blessingTier,
        1,
        3,
        'blessingTier',
      );
    }
  }

  final BlueprintId blueprint;
  final int hullTier;
  final int armamentTier;
  final int region;
  final PlaytestDestination destination;
  final int gold;
  final int seed;
  final Map<HardpointType, PlaytestHardpoint> hardpoints;
  int get effectiveRegion =>
      destination == PlaytestDestination.caldera ? 2 : region;
}

/// Debug adapter only: set up a fresh build, then enter encounters through the
/// normal commands so Titan stats, hazards, intents, loot and progression apply.
GameController createPlaytestController(PlaytestConfig config) {
  if (!kDebugMode) throw StateError('Playtest tools require a debug build');
  final session = GameSession(rng: SeededGameRng(config.seed));
  // A second guard if a future tool explicitly persists a test controller:
  // this directory can never resolve to the live save root or legacy import.
  final directory = Directory(
    '${Directory.systemTemp.path}/TheMonstrousSea2_Playtests/'
    '${DateTime.now().microsecondsSinceEpoch}',
  );
  final controller = GameController(
    session: session,
    storage: StorageService(baseDirectory: directory),
    autoSave: false,
  );
  session.profile
    ..hasBegunFirstVoyage = true
    ..activeBlueprintId = config.blueprint.name;
  session.profile.unlockedBlueprints.add(config.blueprint.name);
  session.profile.blueprintArmamentTiers[config.blueprint.name] =
      config.armamentTier;
  session.captainName = 'Playtest Captain';
  session.ship = createFlagshipFromBlueprint(
    config.blueprint,
    level: config.hullTier,
    rng: session.rng,
    name: 'Playtest ${config.blueprint.shipClass.displayName}',
    armamentTier: config.armamentTier,
  )..gold = config.gold;
  for (final slot in playtestSlots) {
    final setup = config.hardpoints[slot]!;
    for (var mark = 1; mark < setup.mark; mark++) {
      temperShipHardpoint(session.ship!, slot);
    }
    if (setup.power != null) {
      session.ship!.blessings[slot] = HardpointBlessing(
        power: setup.power!,
        slot: slot,
        tier: setup.blessingTier,
      );
    }
  }
  for (var region = 0; region < config.effectiveRegion; region++) {
    session.seaChart.advanceRegion(session.rng);
  }

  if (config.destination == PlaytestDestination.caldera) {
    session.seaChart
      ..currentLeg = session.seaChart.totalLegs
      ..currentRow = SeaChart.bossRow
      ..currentCol = SeaChart.bossCol;
    session.profile.metaInventory.add(leviathanCore: 1);
    session.hasDefeatedCurrentEncounter = true;
    session.phase = SessionPhase.expeditionVictory;
  } else {
    if (config.destination == PlaytestDestination.titan) {
      session.seaChart
        ..currentLeg = session.seaChart.totalLegs - 1
        ..currentRow = SeaChart.bossRow
        ..currentCol = SeaChart.bossCol - 1;
    }
    // A synthetic rest checkpoint avoids the home departure's intentional
    // build reset. This setup phase is never shown to the player.
    session.phase = SessionPhase.restArea;
    controller.dispatch(const TakeHelm());
    if (config.destination == PlaytestDestination.titan) {
      controller.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
    }
  }
  return controller;
}
