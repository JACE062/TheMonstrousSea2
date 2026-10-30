import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _DodgeRoll extends SeededGameRng {
  _DodgeRoll(this.roll) : super(1);
  final int roll;
  int calls = 0;

  @override
  int d100() {
    calls++;
    return roll;
  }
}

ShipState _ship() =>
    createFlagshipFromBlueprint(BlueprintId.clipper, rng: SeededGameRng(1));

MonsterState _monster() =>
    createMonster(MonsterSpecies.serpent, level: 1, rng: SeededGameRng(1));

AttackResult _attack() =>
    AttackResult(didHit: true, damage: 4, damageType: DamageType.piercing);

void main() {
  test(
    'ship displayed threshold matches every d100 outcome and roll count',
    () {
      // Current evasion includes the Sargasso reduction and temporary boosts.
      for (final (current, reckless, tier, barrier, turns, expected) in [
        (25, false, 0, 0, 0, 25),
        (15, false, 0, 0, 0, 15),
        (15, true, 0, 0, 0, 25),
        (50, true, 1, 15, 2, 75),
        (50, true, 2, 25, 2, 75),
        (50, true, 3, 35, 2, 80),
        (50, true, 3, 0, 2, 60),
        (50, true, 3, 35, 0, 60),
        (100, true, 3, 35, 2, 95),
        (-20, false, 0, 0, 0, 0),
      ]) {
        for (var roll = 1; roll <= 100; roll++) {
          final ship = _ship()
            ..currentEvasion = current
            ..captainQuirkId = reckless
                ? BloodlineTraitId.recklessHelmsman
                : null
            ..basaltBarrierHp = barrier
            ..basaltAegisTurns = turns;
          if (tier > 0) {
            ship.blessings[HardpointType.utility] = HardpointBlessing(
              slot: HardpointType.utility,
              power: OceanPower.earthshakerTitan,
              tier: tier,
            );
          }
          expect(ship.effectiveEvasion, expected);
          final rng = _DodgeRoll(roll);
          final result = _attack();
          const EvasionTrait().onIncomingAttack(ship, _monster(), result, rng);
          expect(result.wasEvaded, roll <= expected);
          expect(rng.calls, 1);
        }
      }
    },
  );

  test('monster threshold preserves Pin, Flare, bounds and RNG draws', () {
    for (final innate in [-20, 0, 20, 30, 250]) {
      for (final pinned in [false, true]) {
        for (final flare in [false, true]) {
          final raw = flare ? 0 : (pinned ? innate ~/ 2 : innate);
          final monster = _monster()
            ..evasion = innate
            ..isPinnedThisTurn = pinned
            ..spotterFlareTurns = flare ? 1 : 0;
          expect(monster.effectiveEvasion, raw.clamp(0, 100));
          for (var roll = 1; roll <= 100; roll++) {
            final rng = _DodgeRoll(roll);
            final result = _attack();
            const SerpentSlitherTrait().onIncomingAttack(
              monster,
              _ship(),
              result,
              rng,
            );
            expect(result.wasEvaded, roll <= raw);
            expect(rng.calls, raw > 0 ? 1 : 0);
          }
        }
      }
    }
  });

  test('captain context stays frozen through capture and obscurity copy', () {
    final ship = _ship()
      ..captainBoonId = BloodlineTraitId.skilledCarpenter
      ..captainQuirkId = BloodlineTraitId.recklessHelmsman;
    final captured = CombatantPresentation.capture(ship);
    ship
      ..captainBoonId = BloodlineTraitId.veteranCannoneer
      ..captainQuirkId = BloodlineTraitId.exactingShipwright;
    final copied = captured.withObscurity(true);
    for (final snapshot in [captured, copied]) {
      expect(snapshot.captainBoonId, BloodlineTraitId.skilledCarpenter);
      expect(snapshot.captainQuirkId, BloodlineTraitId.recklessHelmsman);
    }
    expect(copied.isObscured, isTrue);
    final monster = CombatantPresentation.capture(_monster());
    expect(monster.captainBoonId, isNull);
    expect(monster.captainQuirkId, isNull);
  });
}
