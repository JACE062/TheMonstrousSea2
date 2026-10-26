import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Rolls extends SeededGameRng {
  _Rolls(this.rolls) : super(1);
  final List<int> rolls;
  @override
  int d100() => rolls.isEmpty ? 100 : rolls.removeAt(0);
}

ShipState _ship() => createFlagshipFromBlueprint(
  BlueprintId.standard,
  rng: SeededGameRng(1),
);

MonsterState _monster() => createMonster(
  MonsterSpecies.crustacean,
  level: 1,
  rng: SeededGameRng(1),
);

void main() {
  test('healing combines multiplicatively, rounds once, and caps last', () {
    final ship = _ship()
      ..maxHp = 100
      ..currentHp = 0
      ..captainBoonId = BloodlineTraitId.skilledCarpenter
      ..captainQuirkId = BloodlineTraitId.exactingShipwright;
    expect(ship.captainHealingMultiplier, closeTo(0.9, 1e-9));
    expect(ship.previewHealing(30), 27);
    expect(ship.previewHealing(1), 1);
    ship.maxHp = 91;
    expect(ship.previewHealing(ship.maxHp * 0.30), 25);
    ship.maxHp = 100;
    ship.heal(30);
    expect(ship.currentHp, 27);
    ship.currentHp = 96;
    expect(ship.previewHealing(30), 4);
    ship.heal(ship.nominalHealingFor(4));
    expect(ship.currentHp, 100);
    ship
      ..currentHp = 0
      ..captainBoonId = null;
    ship.heal(ship.nominalHealingFor(100));
    expect(ship.currentHp, 100);
    final restored = ShipState.fromJson(ship.toJson());
    expect(restored.captainBoonId, isNull);
    expect(restored.captainQuirkId, isNull);
  });

  test('Precise Commander adds accuracy before both bounds', () {
    final ship = _ship()..captainBoonId = BloodlineTraitId.preciseCommander;
    final cannon = ship.equippedWeapons.first;
    final monster = _monster()..carapacePlating = 0;
    cannon.hitModifier = 85;
    expect(calculateHitChance(ship, cannon, monster), 90);
    expect(calculateHitChance(ship, cannon, monster, accuracyBonus: 50), 95);
    expect(calculateHitChance(ship, cannon, monster, accuracyBonus: -100), 25);
  });

  test('repair inverse always buys the minimum nominal healing needed', () {
    final ship = _ship()..maxHp = 100;
    for (final skilled in [false, true]) {
      for (final exacting in [false, true]) {
        ship
          ..captainBoonId = skilled ? BloodlineTraitId.skilledCarpenter : null
          ..captainQuirkId = exacting ? BloodlineTraitId.exactingShipwright : null;
        for (var missing = 1; missing <= 100; missing++) {
          ship.currentHp = 100 - missing;
          final nominal = ship.nominalHealingFor(missing);
          expect(ship.previewHealing(nominal), missing);
          expect(ship.previewHealing(nominal - 1), lessThan(missing));
        }
      }
    }
  });

  test('Reckless evasion survives the first dodge and works against Titans', () {
    final ship = _ship()
      ..baseEvasion = 0
      ..currentEvasion = 20
      ..captainQuirkId = BloodlineTraitId.recklessHelmsman;
    final titan = createKraken(rng: SeededGameRng(1));
    AttackResult attempt() => AttackResult(
      didHit: true,
      damage: 4,
      damageType: DamageType.slicing,
      description: '',
      combatRange: CombatRange.medium,
    );
    final first = attempt();
    const EvasionTrait().onIncomingAttack(ship, titan, first, _Rolls([25]));
    expect(first.wasEvaded, isTrue);
    expect(ship.currentEvasion, 0);
    final second = attempt();
    const EvasionTrait().onIncomingAttack(ship, titan, second, _Rolls([10]));
    expect(second.wasEvaded, isTrue);
  });

  test('Exacting carries fractional reduction after armor and before barrier', () {
    final ship = _ship()
      ..captainQuirkId = BloodlineTraitId.exactingShipwright
      ..currentDmgReduction = 2
      ..basaltBarrierHp = 10
      ..basaltAegisTurns = 2
      ..blessings[HardpointType.utility] = HardpointBlessing(
        slot: HardpointType.utility,
        power: OceanPower.earthshakerTitan,
        tier: 1,
      );
    final monster = _monster();
    final weapon = monster.usableWeapons.first
      ..damage = 6
      ..statusEffect = null;
    final initialHp = ship.currentHp;
    for (var i = 0; i < 5; i++) {
      calculateAttack(monster, weapon, ship, _Rolls([]), const [], 0, 1,
          CombatRange.medium, true);
    }
    // Five attacks leave 20 after flat armor, reduced to 18, then 10 barrier.
    expect(ship.currentHp, initialHp - 8);
    expect(ship.basaltBarrierHp, 0);
    expect(ship.exactingReductionRemainder, closeTo(0, 1e-9));
    ship.applyDamage(4);
    expect(ship.currentHp, initialHp - 12);
    ship.exactingReductionRemainder = 0.4;
    final restored = ShipState.fromJson(ship.toJson());
    expect(restored.exactingReductionRemainder, 0);
    ship.resetCombatBoosts();
    expect(ship.exactingReductionRemainder, 0);
  });

  test('Iron Constitution halves Burn and Poison without changing recovery', () {
    final ship = _ship()
      ..captainBoonId = BloodlineTraitId.ironConstitution
      ..captainQuirkId = BloodlineTraitId.exactingShipwright
      ..addStatus(StatusEffect.burn)
      ..addStatus(StatusEffect.poison);
    final initialHp = ship.currentHp;
    final events = updateStatusEffects(ship, 2, _Rolls([1, 100])).$2;
    expect(ship.currentHp, initialHp - 10);
    expect(events.whereType<StatusEffectTicked>().map((e) => e.damage), [5, 5]);
    expect(ship.hasStatus(StatusEffect.burn), isTrue);
    expect(ship.hasStatus(StatusEffect.poison), isFalse);
    expect(ship.exactingReductionRemainder, 0);
  });

  test('Veteran boosts shell damage only and excludes elemental riders', () {
    final ship = _ship();
    final weapon = ship.equippedWeapons.first..damage = 20;
    final baseline = _monster()..carapacePlating = 100;
    final veteran = _monster()..carapacePlating = 100;
    final baseResult = calculateAttack(ship, weapon, baseline, _Rolls([1])).$1;
    ship.captainBoonId = BloodlineTraitId.veteranCannoneer;
    final result = calculateAttack(ship, weapon, veteran, _Rolls([1])).$1;
    expect(100 - veteran.carapacePlating,
        ((100 - baseline.carapacePlating) * 1.25).round());
    expect(result.damage - result.nullifiedDamage,
        baseResult.damage - baseResult.nullifiedDamage);
    final riderTarget = _monster()..carapacePlating = 100;
    dealBlessingDamage(ship, riderTarget, 20, DamageType.piercing, source: 'test');
    expect(riderTarget.carapacePlating, 80);
  });
}
