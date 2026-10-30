import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

import 'combat_test.dart' show QueueGameRng, createTestMonsterWeapon;

// All sessions are pure core state, with no storage or production saves.
GameSession _battle(int mark, {CombatRange range = CombatRange.medium}) {
  final rng = QueueGameRng()..defaultD100 = 100;
  final session = GameSession(rng: rng);
  session.dispatch(const NameCaptain('Rigging witness'));
  session.profile.unlockedBlueprints.add(BlueprintId.clipper.name);
  session.dispatch(const ChooseShip(ShipClass.clipper));
  session.dispatch(const VentureOutToSea());
  session.combatRange = range;
  session.ship!.hardpointMarks[HardpointType.utility] = mark;
  session.currentMonster = createMonster(
    MonsterSpecies.shark,
    level: 1,
    rng: rng,
  )..currentIntent = MonsterIntent.fromId(MonsterIntentId.sharkFrenziedJaws);
  return session;
}

AttackResult _strike(GameSession session, int dodgeRoll) => calculateAttack(
  session.currentMonster!,
  createTestMonsterWeapon(damage: 1, hitModifier: 100),
  session.ship!,
  QueueGameRng(d100Rolls: [1, dodgeRoll]),
  const [],
  0,
  1,
  session.combatRange,
).$1;

void main() {
  for (var mark = 1; mark <= 3; mark++) {
    final bonus = [25, 40, 55][mark - 1];
    final boosted = 25 + bonus;

    test('Mk $mark utility applies $bonus bonus until a successful dodge', () {
      final session = _battle(mark);
      final ship = session.ship!;
      session.dispatch(const ExecuteShipSpecialAction());
      expect(ship.baseEvasion, 25);
      expect(ship.evasiveRiggingBonus, bonus);
      expect(ship.evasiveRiggingEvasion, boosted);
      expect(ship.currentEvasion, boosted);
      expect(ship.effectiveEvasion, boosted);

      expect(_strike(session, boosted + 1).wasEvaded, isFalse);
      expect(ship.currentEvasion, boosted);
      expect(_strike(session, boosted).wasEvaded, isTrue);
      expect(ship.currentEvasion, 25);
      expect(_strike(session, 26).wasEvaded, isFalse);
    });

    test('Mk $mark repeat utility activation does not stack', () {
      final session = _battle(mark);
      session.dispatch(const ExecuteShipSpecialAction());
      session.dispatch(const BraceForImpact());
      expect(session.ship!.utilityCooldown, 1);
      session.dispatch(const BraceForImpact());
      expect(session.ship!.utilityCooldown, 0);
      session.dispatch(const ExecuteShipSpecialAction());
      expect(session.ship!.currentEvasion, boosted);
    });

    for (final range in CombatRange.values) {
      for (final grappled in [false, true]) {
        test('Mk $mark movement/cooldown at $range grapple=$grappled', () {
          final session = _battle(mark, range: range);
          session.ship!.isGrappled = grappled;
          final events = session.dispatch(const ExecuteShipSpecialAction());
          final moves = events.whereType<CombatRangeChanged>();
          final shouldMove = !grappled && range != CombatRange.long;
          expect(moves.length, shouldMove ? 1 : 0);
          if (shouldMove) {
            expect(moves.single.previousRange, range);
            expect(moves.single.newRange, range.farther);
            expect(moves.single.mover, CombatSide.ship);
          }
          expect(session.combatRange, shouldMove ? range.farther : range);
          expect(session.ship!.currentEvasion, boosted);
          expect(session.ship!.utilityCooldown, 2);
          expect(
            () => session.dispatch(const ExecuteShipSpecialAction()),
            throwsStateError,
          );
        });
      }
    }

    test('Mk $mark preserves captain/Basalt bonuses and the 95% cap', () {
      for (final tier in [1, 3]) {
        final session = _battle(mark);
        session.activeQuirk = BloodlineTrait.recklessHelmsman;
        final ship = session.ship!;
        ship.blessings[HardpointType.utility] = HardpointBlessing(
          slot: HardpointType.utility,
          power: OceanPower.earthshakerTitan,
          tier: tier,
        );
        session.dispatch(const ExecuteShipSpecialAction());
        expect(ship.basaltBarrierHp, greaterThan(0));
        expect(ship.basaltAegisTurns, greaterThan(0));
        final expected = (boosted + 10 + (tier == 3 ? 20 : 15)).clamp(0, 95);
        expect(ship.currentEvasion, boosted);
        expect(ship.effectiveEvasion, expected);
        expect(_strike(session, expected + 1).wasEvaded, isFalse);
        expect(ship.currentEvasion, boosted);
        expect(_strike(session, ship.effectiveEvasion).wasEvaded, isTrue);
        expect(ship.currentEvasion, 25);
        expect(ship.captainEvasionBonus, 10);
      }
    });
  }

  test('tier IV hull retains its stronger base with additive Mk bonuses', () {
    final session = _battle(1);
    session.ship = createFlagshipFromBlueprint(
      BlueprintId.clipper,
      level: 4,
      rng: session.rng,
    );
    final ship = session.ship!;
    expect(ship.baseEvasion, 40);
    for (final (mark, boosted) in [(1, 65), (2, 80), (3, 95)]) {
      ship.hardpointMarks[HardpointType.utility] = mark;
      ship.utilityCooldown = 0;
      session.dispatch(const ExecuteShipSpecialAction());
      expect(ship.currentEvasion, boosted);
    }
  });

  test('utility mark and raw boost bounds use canonical progression rules', () {
    final ship = _battle(1).ship!;
    for (final (mark, bonus) in [
      (-1, 25),
      (0, 25),
      (1, 25),
      (3, 55),
      (4, 55),
    ]) {
      ship.hardpointMarks[HardpointType.utility] = mark;
      expect(ship.evasiveRiggingBonus, bonus);
    }
    ship.hardpointMarks.remove(HardpointType.utility);
    expect(ship.evasiveRiggingBonus, 25);
    ship.baseEvasion = 90;
    expect(ship.evasiveRiggingEvasion, 100);
    ship.baseEvasion = -100;
    expect(ship.evasiveRiggingEvasion, 0);
  });
}
