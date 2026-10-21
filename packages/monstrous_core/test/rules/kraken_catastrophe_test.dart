import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _NoAttackRolls extends SeededGameRng {
  _NoAttackRolls() : super(42);
  @override
  int d100() =>
      throw StateError('Unavoidable release must not roll accuracy/dodge');
  @override
  int nextInt(int maxExclusive) =>
      throw StateError('Release must not select a weapon');
}

class _FixedRoll extends SeededGameRng {
  _FixedRoll(this.roll) : super(42);
  final int roll;
  @override
  int d100() => roll;
}

MonsterState _kraken() => createKraken(rng: SeededGameRng(42))
  ..currentIntent = MonsterIntent.fromId(MonsterIntentId.bossKrakenCatastrophe);

ShipState _ship([BlueprintId bp = BlueprintId.standard]) =>
    createFlagshipFromBlueprint(bp, rng: SeededGameRng(42));

List<GameEvent> _release(
  MonsterState kraken,
  ShipState ship, [
  CombatRange range = CombatRange.medium,
]) => executeMonsterIntent(kraken, ship, _NoAttackRolls(), range).$2;

GameSession _battle() {
  final session = GameSession(rng: _FixedRoll(50));
  session.dispatch(const NameCaptain('Test'));
  session.dispatch(const ChooseShip(ShipClass.standard));
  session.dispatch(const VentureOutToSea());
  session.currentMonster = _kraken()
    ..maxHp = 1000
    ..currentHp = 1000;
  return session;
}

void main() {
  for (final bp in BlueprintId.values) {
    for (final range in CombatRange.values) {
      test('${bp.name} at ${range.name}: release cannot miss or be dodged', () {
        final kraken = _kraken()..tremorAccPenalty = 100;
        final ship = _ship(bp)..currentEvasion = 95;
        final expected = bp == BlueprintId.ironclad ? 35 : 38;
        final events = _release(kraken, ship, range);
        expect(ship.maxHp - ship.currentHp, expected);
        expect(events.whereType<AttackHit>().single.damage, expected);
        expect(events.whereType<AttackMissed>(), isEmpty);
        expect(events.whereType<AttackEvaded>(), isEmpty);
        expect(events.whereType<AttackAttempted>(), isEmpty);
        expect(ship.currentEvasion, 95); // No dodge boost is consumed.
        expect(
          kraken.isIntentOnCooldown(MonsterIntentId.bossKrakenWindup),
          isTrue,
        );
      });
    }
  }

  test('dedicated profile works without normal weapons or tentacles', () {
    final kraken = _kraken()
      ..usableWeapons.clear()
      ..numberOfTentacles = 0;
    final ship = _ship();
    _release(kraken, ship);
    expect(ship.maxHp - ship.currentHp, 38);
  });

  for (final (brace, barrier, corroded, jolted, expected) in [
    (true, 0, 0, false, 30),
    (false, 20, 0, false, 18),
    (true, 20, 0, false, 10),
    (false, 0, 3, true, 24),
    (true, 0, 3, true, 19),
  ]) {
    test(
      'mitigation: brace=$brace barrier=$barrier corrosion=$corroded jolt=$jolted',
      () {
        final kraken = _kraken()
          ..corrodedStacks = corroded
          ..isElectroJolted = jolted;
        final ship = _ship()
          ..isBracedByDrill = brace
          ..basaltBarrierHp = barrier
          ..basaltAegisTurns = barrier > 0 ? 2 : 0;
        if (barrier > 0) {
          ship.blessings[HardpointType.utility] = const HardpointBlessing(
            power: OceanPower.earthshakerTitan,
            slot: HardpointType.utility,
            tier: 1,
          );
        }
        _release(kraken, ship);
        expect(ship.maxHp - ship.currentHp, expected);
        if (barrier > 0) {
          expect(ship.basaltBarrierHp, 0);
          expect(
            kraken.currentHp,
            kraken.maxHp - 12,
          ); // Barrier retaliation still fires.
        }
      },
    );
  }

  test('preview is 38 base Blast, distinct from defensive reductions', () {
    final intent = MonsterIntent.fromId(MonsterIntentId.bossKrakenCatastrophe);
    final preview = intent.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.fallBack,
    );
    expect(intent.damageMultiplier, 1);
    expect(preview.estimatedDamage, 38);
    expect(preview.summaryBadge, contains('38 base Blast'));
    expect(preview.summaryBadge, contains('UNAVOIDABLE'));
    expect(preview.summaryBadge, contains('before weakening and defenses'));
    // Older serialized multipliers must not amplify the dedicated profile again.
    final kraken = _kraken()
      ..currentIntent = MonsterIntent.fromJson({
        ...intent.toJson(),
        'damageMultiplier': 1.65,
      });
    final ship = _ship();
    _release(kraken, ship);
    expect(ship.maxHp - ship.currentHp, 38);
  });

  test('windup grants a full no-strike turn before the release', () {
    final session = _battle();
    session.currentMonster!.currentIntent = MonsterIntent.fromId(
      MonsterIntentId.bossKrakenWindup,
    );
    final hp = session.ship!.currentHp;
    session.dispatch(const ExecuteShipSpecialAction());
    expect(session.ship!.currentHp, hp);
    expect(
      session.currentMonster!.currentIntent!.id,
      MonsterIntentId.bossKrakenCatastrophe,
    );
    session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
    expect(session.ship!.currentHp, hp - 38);
  });

  test('Stun cancels the imminent release through session status handling', () {
    final session = _battle();
    session.currentMonster!.addStatus(StatusEffect.stun);
    final hp = session.ship!.currentHp;
    session.dispatch(const ExecuteShipSpecialAction());
    expect(session.ship!.currentHp, hp);
    expect(session.currentMonster!.currentIntent?.isUnavoidable, isNot(true));
  });

  test('Harpoon disrupts the imminent release', () {
    final session = _battle()..ship = _ship(BlueprintId.corsair);
    final hp = session.ship!.currentHp;
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.harpoonWinch),
    );
    expect(events.whereType<MonsterIntentDisrupted>(), isNotEmpty);
    expect(session.ship!.currentHp, hp);
    expect(
      session.currentMonster!.isIntentOnCooldown(
        MonsterIntentId.bossKrakenWindup,
      ),
      isTrue,
    );
  });

  test('Fault-Line Shatter still breaks the imminent release', () {
    final session = _battle();
    session.ship!.blessings[HardpointType.signature] = const HardpointBlessing(
      power: OceanPower.earthshakerTitan,
      slot: HardpointType.signature,
      tier: 3,
    );
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.twinChasers),
    );
    expect(
      events.whereType<NarrationEvent>().any(
        (e) => e.message.contains('breaks the lethal windup'),
      ),
      isTrue,
    );
    expect(
      session.currentMonster!.isIntentOnCooldown(
        MonsterIntentId.bossKrakenWindup,
      ),
      isTrue,
    );
    expect(
      events.whereType<NarrationEvent>().any(
        (e) => e.message.contains('cannot miss'),
      ),
      isFalse,
    );
  });

  test('ordinary Kraken and other Titan strikes retain accuracy checks', () {
    for (final (monster, intent) in [
      (_kraken(), MonsterIntentId.squidConstrictingBeak),
      (
        createWorldSerpent(level: 5, rng: SeededGameRng(42)),
        MonsterIntentId.bossWorldSerpentCatastrophe,
      ),
      (
        createAncientLeviathan(level: 5, rng: SeededGameRng(42)),
        MonsterIntentId.bossLeviathanCatastrophe,
      ),
    ]) {
      monster.currentIntent = MonsterIntent.fromId(intent);
      final events = executeMonsterIntent(
        monster,
        _ship(),
        _FixedRoll(100),
        CombatRange.short,
      ).$2;
      expect(events.whereType<AttackMissed>(), isNotEmpty);
    }
  });
}
