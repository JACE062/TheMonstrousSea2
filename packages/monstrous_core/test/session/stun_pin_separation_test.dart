import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _StunRng extends SeededGameRng {
  _StunRng() : super(42);

  bool selectStun = false;

  @override
  int nextInt(int maxExclusive) =>
      selectStun && maxExclusive == 3 ? 2 : super.nextInt(maxExclusive);

  // Hits accuracy, but is evaded at 20% dodge and not at Pin's 10%.
  @override
  int d100() => 15;
}

GameSession _battle({MonsterSpecies species = MonsterSpecies.serpent}) {
  final rng = _StunRng();
  final session = GameSession(rng: rng);
  session.dispatch(const NameCaptain('Test'));
  session.dispatch(const ChooseShip(ShipClass.standard));
  session.dispatch(const VentureOutToSea());
  session.phase = SessionPhase.battle;
  session.combatRange = CombatRange.long;
  session.currentMonster = createMonster(species, level: 3, rng: rng)
    ..maxHp = 1000
    ..currentHp = 1000
    ..evasion = 20
    ..isObscured = false
    ..currentIntent = MonsterIntent.fromId(
      MonsterIntentId.serpentAbyssalUnderStrike,
    );
  rng.selectStun = true;
  session.ship!.cargo
    ..clear()
    ..add(
      generateConsumable(ConsumableType.unstableTincture, RarityLevel.common),
    );
  return session;
}

void _expectNoPin(Iterable<GameEvent> events) {
  expect(
    events.whereType<CombatEffectsChanged>().where(
      (event) =>
          event.target == CombatSide.monster && event.state.isPinnedThisTurn,
    ),
    isEmpty,
  );
}

void main() {
  test('quick Stun preserves normal dodge and denies movement and attack once', () {
    final session = _battle();
    final monster = session.currentMonster!;
    final hp = session.ship!.currentHp;
    final stunEvents = session.dispatch(const UseConsumableItem(0));

    expect(monster.hasStatus(StatusEffect.stun), isTrue);
    expect(monster.isPinnedThisTurn, isFalse);
    expect(monster.effectiveEvasion, 20);
    _expectNoPin(stunEvents);

    final response = session.dispatch(const BraceForImpact());
    expect(session.combatRange, CombatRange.long);
    expect(session.ship!.currentHp, hp);
    expect(response.whereType<CombatRangeChanged>(), isEmpty);
    expect(response.whereType<AttackAttempted>(), isEmpty);
    expect(monster.hasStatus(StatusEffect.stun), isFalse);
    _expectNoPin(response);

    // The next response can move and attack again; Stun is not a lasting lock.
    monster.currentIntent = MonsterIntent.fromId(
      MonsterIntentId.serpentAbyssalUnderStrike,
    );
    final nextResponse = session.dispatch(const BraceForImpact());
    expect(session.combatRange, CombatRange.short);
    expect(nextResponse.whereType<AttackAttempted>(), isNotEmpty);
  });

  test('a follow-up ordinary volley against Stun does not gain half dodge', () {
    final session = _battle();
    session.dispatch(const UseConsumableItem(0));
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.cannon),
    );
    expect(
      events.whereType<AttackEvaded>().where(
        (event) => event.target == CombatSide.monster,
      ),
      isNotEmpty,
    );
    _expectNoPin(events);
  });

  test('an ordinary hit on existing Stun does not add Pin', () {
    final session = _battle();
    session.currentMonster!
      ..evasion = 0
      ..addStatus(StatusEffect.stun);
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.cannon),
    );
    expect(
      events.whereType<AttackHit>().where(
        (event) => event.target == CombatSide.monster,
      ),
      isNotEmpty,
    );
    _expectNoPin(events);
  });

  for (final intent in [
    MonsterIntentId.bossKrakenWindup,
    MonsterIntentId.bossKrakenCatastrophe,
  ]) {
    test('Stun interrupts ${intent.name} without Pin', () {
      final session = _battle(species: MonsterSpecies.kraken);
      final monster = session.currentMonster!
        ..currentIntent = MonsterIntent.fromId(intent);
      final hp = session.ship!.currentHp;
      final events = session.dispatch(const UseConsumableItem(0));
      expect(events.whereType<MonsterIntentDisrupted>(), hasLength(1));
      expect(monster.currentIntent, isNull);
      expect(
        monster.isIntentOnCooldown(MonsterIntentId.bossKrakenWindup),
        isTrue,
      );
      expect(monster.isPinnedThisTurn, isFalse);
      expect(monster.effectiveEvasion, 20);
      _expectNoPin(events);
      final response = session.dispatch(const BraceForImpact());
      expect(session.ship!.currentHp, hp);
      expect(response.whereType<AttackAttempted>(), isEmpty);
      expect(monster.hasStatus(StatusEffect.stun), isFalse);
      _expectNoPin(response);
    });
  }

  test('Stun preserves independent trap Pin and its dodge reduction', () {
    final session = _battle();
    final monster = session.currentMonster!;
    session.ship!
      ..activeTetherTrapDistance = 0
      ..activeTetherTrapDamage = 1;
    detonateTetherTrap(
      session.ship!,
      monster,
      session.rng,
      const [],
      reason: 'Test',
    );
    expect(monster.isPinnedThisTurn, isTrue);
    session.dispatch(const UseConsumableItem(0));
    expect(monster.hasStatus(StatusEffect.stun), isTrue);
    expect(monster.isPinnedThisTurn, isTrue);
    expect(monster.effectiveEvasion, 10);
  });

  for (final (blueprint, weapon) in [
    (BlueprintId.corsair, ShipWeaponType.harpoonWinch),
    (BlueprintId.bombardier, ShipWeaponType.heavyMortar),
  ]) {
    test('${weapon.name} still Pins a stunned monster', () {
      final session = _battle();
      session.ship = createFlagshipFromBlueprint(
        blueprint,
        rng: SeededGameRng(1),
      );
      session.currentMonster!.addStatus(StatusEffect.stun);
      // Guarantee a hit to exercise the ordnance path, rather than innate dodge.
      session.currentMonster!.evasion = 0;
      final events = session.dispatch(FireWeaponVolley(weapon));
      expect(
        events.whereType<CombatEffectsChanged>().any(
          (event) =>
              event.target == CombatSide.monster &&
              event.state.isPinnedThisTurn &&
              event.state.statusEffects.contains(StatusEffect.stun),
        ),
        isTrue,
      );
    });
  }

  test('Blast Pack retains independent Pin and half dodge', () {
    final session = _battle();
    session.ship!.cargo
      ..clear()
      ..add(generateConsumable(ConsumableType.blastPack, RarityLevel.common));
    session.dispatch(const UseConsumableItem(0));
    expect(session.currentMonster!.isPinnedThisTurn, isTrue);
    expect(session.currentMonster!.effectiveEvasion, 10);
    expect(session.currentMonster!.hasStatus(StatusEffect.stun), isFalse);
  });
}
