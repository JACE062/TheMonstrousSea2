import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Rolls extends SeededGameRng {
  _Rolls(List<int> rolls) : _rolls = [...rolls], super(1);
  final List<int> _rolls;

  @override
  int d100() => _rolls.removeAt(0);
}

final _monster = createMonster(
  MonsterSpecies.shark,
  level: 1,
  rng: SeededGameRng(1),
);

final _weapon = MonsterWeapon(
  id: 'evasion-probe',
  name: 'Strike',
  description: '',
  rarity: RarityLevel.common,
  damage: 4,
  hitModifier: 95,
  chargeTime: 0,
  chargeCountdown: 0,
  damageType: DamageType.piercing,
  monsterWeaponType: MonsterWeaponType.jaws,
);

ShipState _ship(BlueprintId blueprint) =>
    createFlagshipFromBlueprint(blueprint, rng: SeededGameRng(1));

AttackResult _attempt(CombatRange range) => AttackResult(
  didHit: true,
  damage: 4,
  damageType: DamageType.piercing,
  combatRange: range,
);

void main() {
  for (final range in CombatRange.values) {
    for (final blueprint in BlueprintId.values) {
      test('${blueprint.name} uses base dodge at $range in real attacks', () {
        final ship = _ship(blueprint);
        for (final roll in [ship.baseEvasion, ship.baseEvasion + 1]) {
          // A d100 cannot roll zero, including for Ironclad's zero base dodge.
          final dodgeRoll = roll < 1 ? 1 : roll;
          final (result, events) = calculateAttack(
            _monster,
            _weapon,
            ship,
            _Rolls([1, dodgeRoll]),
            const [],
            0,
            1,
            range,
          );
          final dodged = dodgeRoll <= ship.baseEvasion;
          expect(result.didHit, isTrue);
          expect(result.wasEvaded, dodged);
          expect(events.whereType<AttackEvaded>().isNotEmpty, dodged);
          expect(ship.currentEvasion, ship.baseEvasion);
        }
      });
    }

    test('captain and live Basalt dodge bonuses remain at $range', () {
      for (final reckless in [false, true]) {
        for (final tier in [0, 1, 3]) {
          final ship = _ship(BlueprintId.clipper);
          if (reckless) {
            ship.captainQuirkId = BloodlineTraitId.recklessHelmsman;
          }
          if (tier > 0) {
            ship.basaltBarrierHp = 15;
            ship.basaltAegisTurns = 2;
            ship.blessings[HardpointType.utility] = HardpointBlessing(
              slot: HardpointType.utility,
              power: OceanPower.earthshakerTitan,
              tier: tier,
            );
          }
          final expected =
              25 +
              (reckless ? 10 : 0) +
              (tier == 0
                  ? 0
                  : tier == 3
                  ? 20
                  : 15);
          for (final roll in [expected, expected + 1]) {
            final result = _attempt(range);
            const EvasionTrait().onIncomingAttack(
              ship,
              _monster,
              result,
              _Rolls([roll]),
            );
            expect(result.wasEvaded, roll <= expected);
          }
          if (tier > 0) {
            for (final barrierExpired in [true, false]) {
              ship.basaltBarrierHp = barrierExpired ? 0 : 15;
              ship.basaltAegisTurns = barrierExpired ? 2 : 0;
              final result = _attempt(range);
              const EvasionTrait().onIncomingAttack(
                ship,
                _monster,
                result,
                _Rolls([25 + (reckless ? 10 : 0) + 1]),
              );
              expect(result.wasEvaded, isFalse);
            }
          }
        }
      }
    });

    test('Evasive Rigging persists until a successful dodge at $range', () {
      final ship = _ship(BlueprintId.clipper);
      const trait = EvasionTrait();
      trait.executeSpecialAction(ship, _monster, _Rolls([]));
      expect(ship.currentEvasion, 50);

      final hit = _attempt(range);
      trait.onIncomingAttack(ship, _monster, hit, _Rolls([51]));
      expect(hit.wasEvaded, isFalse);
      expect(ship.currentEvasion, 50);

      final dodge = _attempt(range);
      trait.onIncomingAttack(ship, _monster, dodge, _Rolls([50]));
      expect(dodge.wasEvaded, isTrue);
      expect(ship.currentEvasion, 25);

      final after = _attempt(range);
      trait.onIncomingAttack(ship, _monster, after, _Rolls([26]));
      expect(after.wasEvaded, isFalse);
    });

    test('dodge retains its 95% ceiling at $range', () {
      for (final roll in [95, 96]) {
        final ship = _ship(BlueprintId.clipper)..currentEvasion = 100;
        final result = _attempt(range);
        const EvasionTrait().onIncomingAttack(
          ship,
          _monster,
          result,
          _Rolls([roll]),
        );
        expect(result.wasEvaded, roll == 95);
      }
    });

    test('unavoidable strikes bypass dodge without consuming it at $range', () {
      final ship = _ship(BlueprintId.clipper)..currentEvasion = 100;
      final before = ship.currentHp;
      final (result, events) = calculateAttack(
        _monster,
        _weapon,
        ship,
        _Rolls([]),
        const [],
        0,
        1,
        range,
        true,
      );
      expect(result.wasEvaded, isFalse);
      expect(ship.currentHp, before - 4);
      expect(ship.currentEvasion, 100);
      expect(events.whereType<AttackEvaded>(), isEmpty);
    });
  }
}
