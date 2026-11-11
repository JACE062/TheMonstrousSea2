import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  for (final blueprint in BlueprintId.values) {
    for (final level in [1, 2, 3, 4]) {
      for (var mark = 1; mark <= 3; mark++) {
        test(
          '${blueprint.name} utility potency matches activation at hull $level Mk $mark',
          () {
            final session = GameSession(rng: SeededGameRng(17))
              ..dispatch(const BeginFirstVoyage('Potency witness'));
            final ship = createFlagshipFromBlueprint(
              blueprint,
              level: level,
              rng: session.rng,
            );
            while (ship.markForHardpoint(HardpointType.utility) < mark) {
              temperShipHardpoint(ship, HardpointType.utility);
            }
            session.ship = ship;
            session.activeQuirk = BloodlineTrait.impatient;
            session.currentMonster =
                createMonster(MonsterSpecies.shark, level: 1, rng: session.rng)
                  ..maxHp = 10000
                  ..currentHp = 10000;
            session.phase = SessionPhase.battle;
            session.combatRange = CombatRange.medium;
            final previousReduction = ship.currentDmgReduction;
            // Borrowing isolates activation from the monster response/expiry.
            session.dispatch(
              const ExecuteShipSpecialAction(borrowNextAction: true),
            );
            expect(session.isImpatientCombinationPending, isTrue);
            switch (blueprint) {
              case BlueprintId.standard:
                expect(ship.gunneryDrillBuffActive, isTrue);
                expect(
                  (ship.bracedVolleyDamageBonus * 100).round(),
                  [20, 24, 28][mark - 1],
                );
              case BlueprintId.ironclad:
                expect(
                  ship.currentDmgReduction - previousReduction,
                  ship.fortifyDamageReductionGain,
                );
                expect(ship.isAnchoredThisTurn, isTrue);
              case BlueprintId.clipper:
                expect(ship.currentEvasion, ship.evasiveRiggingEvasion);
                expect(ship.evasiveRiggingBonus, [25, 40, 55][mark - 1]);
              case BlueprintId.bombardier:
                expect(
                  session.currentMonster!.spotterFlareAccuracyBonus,
                  ship.spotterFlareAccuracyBonus,
                );
                expect(
                  session.currentMonster!.spotterFlareBlastBonus,
                  ship.spotterFlareBlastBonus,
                );
                expect(session.currentMonster!.spotterFlareTurns, 2);
              case BlueprintId.corsair:
                expect(ship.activeTetherTrapDamage, ship.tetherTrapDamage);
                expect(ship.activeTetherTrapDistance, 1);
            }
          },
        );
      }
    }
  }
}
