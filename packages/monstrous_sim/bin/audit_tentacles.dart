import 'dart:convert';
import 'dart:io';

import 'package:monstrous_core/monstrous_core.dart';

/// Isolated full-health encounter audit, not a voyage win-rate prediction.
/// No blessings, consumables, permanent stat upgrades or Master Refits.
/// The armor control removes starting armor; active utility can still add it.
/// Tactical policy is deliberately simple; stalled cells hit the step limit.
/// Usage: dart run bin/audit_tentacles.dart [runs-per-cell, default 100]
void main(List<String> args) {
  final runs = args.isEmpty ? 100 : int.parse(args.single);
  if (runs < 1) throw ArgumentError('runs must be positive');
  for (final (label, region, row, apex, boss) in [
    ('late-R1', 0, 3, false, false),
    ('Kraken', 0, 3, false, true),
    ('opening-R2', 1, 0, false, false),
    ('Apex-R2', 1, 0, true, false),
    ('late-R2', 1, 3, false, false),
    ('opening-R3', 2, 0, false, false),
  ]) {
    for (final bp in BlueprintId.values) {
      for (final upgraded in [false, true]) {
        for (final helm in [false, true]) {
          for (final stripArmor in [false, true]) {
            var wins = 0;
            var stalled = 0;
            var remainingHull = 0.0;
            var turns = 0;
            for (var i = 0; i < runs; i++) {
              final session = _encounter(
                seed: 42 + i * 31,
                bp: bp,
                region: region,
                row: row,
                apex: apex,
                boss: boss,
                upgraded: upgraded,
              );
              if (stripArmor) {
                session.ship!.baseDmgReduction = 0;
                session.ship!.currentDmgReduction = 0;
                session.ship!.dmgReductionMod = 0;
              }
              for (
                var step = 0;
                step < 240 && session.phase == SessionPhase.battle;
                step++
              ) {
                session.dispatch(_action(session, helm));
              }
              wins += session.phase == SessionPhase.loot ? 1 : 0;
              stalled += session.phase == SessionPhase.battle ? 1 : 0;
              remainingHull += session.ship!.currentHp / session.ship!.maxHp;
              turns += session.battleRound;
            }
            stdout.writeln(
              jsonEncode({
                'encounter': label,
                'blueprint': bp.name,
                'build': upgraded ? 'Hull-II-Mk-II' : 'Hull-I-Mk-I',
                'tactics': helm ? 'helm-and-utility' : 'fire-only',
                'armor': stripArmor
                    ? 'starting-armor-removed-control'
                    : 'intrinsic',
                'runs': runs,
                'wins': wins,
                'stalled': stalled,
                'meanHullFraction': remainingHull / runs,
                'meanBattleRound': turns / runs,
              }),
            );
          }
        }
      }
    }
  }
}

GameSession _encounter({
  required int seed,
  required BlueprintId bp,
  required int region,
  required int row,
  required bool apex,
  required bool boss,
  required bool upgraded,
}) {
  final session = GameSession(rng: SeededGameRng(seed));
  session.profile.unlockedBlueprints.add(bp.name);
  session.dispatch(const NameCaptain('Audit'));
  session.dispatch(ChooseShip(bp.shipClass));
  if (upgraded) {
    session.phase = SessionPhase.stronghold;
    session.ship!.gold = 4000;
    session.dispatch(const UpgradeShip());
    for (final slot in blessingHardpoints) {
      session.dispatch(TemperHardpoint(slot));
    }
  }
  final chart = session.seaChart;
  chart.restoreFromJson({
    ...chart.toJson(),
    'timesCompleted': region,
    'currentRow': row,
    'currentCol': 0,
    'currentLeg': boss ? SeaChart.totalLegsForRegion(region) - 1 : 1,
    'gridSpecies': List.generate(
      SeaChart.totalRows,
      (_) => List.filled(SeaChart.totalCols, MonsterSpecies.squid.name),
    ),
    'gridNodeTypes': List.generate(
      SeaChart.totalRows,
      (_) =>
          List.filled(SeaChart.totalCols, EncounterNodeType.beastCombat.name),
    ),
    'courseOptions': [
      {
        'bearing': NavigationalBearing.deadAhead.name,
        'nodeType': EncounterNodeType.beastCombat.name,
        'difficultyLevel': row + 1 + region * 4,
        'lookoutCall': 'Isolated audit encounter',
        'monsterSpecies': MonsterSpecies.squid.name,
        'isApex': apex,
      },
    ],
  });
  session.phase = SessionPhase.helm;
  session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
  if (session.phase != SessionPhase.battle) {
    throw StateError('Audit fixture did not enter battle');
  }
  return session;
}

Command _action(GameSession session, bool useHelm) {
  final ship = session.ship!;
  final monster = session.currentMonster!;
  final intent = monster.currentIntent;
  if (useHelm &&
      !ship.isGrappled &&
      intent != null &&
      session.lastHelmOrderThisTurn == HelmOrder.holdLine) {
    for (final order in session.combatRange.availableHelmOrders) {
      if (order == HelmOrder.holdLine) continue;
      final preview = intent.evaluatePreview(
        currentRange: session.combatRange,
        selectedHelmOrder: order,
        isMonsterPinned: monster.isPinnedThisTurn,
      );
      if (preview.status == IntentPreviewStatus.evadedByPosition) {
        return IssueHelmOrder(order);
      }
    }
  }
  if (useHelm && ship.isUtilityReady) {
    final shouldUse = switch (ship.resolvedBlueprintId) {
      BlueprintId.standard =>
        !ship.gunneryDrillBuffActive &&
            (intent?.threatenedRanges.contains(session.combatRange) ?? false),
      BlueprintId.ironclad => true,
      BlueprintId.clipper => ship.currentEvasion <= ship.baseEvasion,
      BlueprintId.bombardier => monster.isObscured,
      BlueprintId.corsair => ship.activeTetherTrapDistance == null,
    };
    if (shouldUse) return const ExecuteShipSpecialAction();
  }
  final weapons =
      ship.equippedWeapons
          .where(
            (w) =>
                w.isReady &&
                isWeaponTypeUsableAtRange(w.weaponType, session.combatRange),
          )
          .toList()
        ..sort(
          (a, b) =>
              (b.damage *
                      weaponRangeDamageMultiplier(
                        b.weaponType,
                        session.combatRange,
                      ))
                  .compareTo(
                    a.damage *
                        weaponRangeDamageMultiplier(
                          a.weaponType,
                          session.combatRange,
                        ),
                  ),
        );
  if (weapons.isNotEmpty) return FireWeaponVolley(weapons.first.weaponType);
  return ship.isUtilityReady
      ? const ExecuteShipSpecialAction()
      : const BraceForImpact();
}
