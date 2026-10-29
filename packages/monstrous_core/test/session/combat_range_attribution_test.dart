import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _HitRng extends SeededGameRng {
  _HitRng() : super(17);

  @override
  int d100() => 50;
}

// Pure core sessions have no disk storage or production profile access.
GameSession _battle({ShipClass hull = ShipClass.standard}) {
  final session = GameSession(rng: _HitRng());
  session.dispatch(const NameCaptain('Range witness'));
  session.profile.unlockedBlueprints.add(BlueprintId.fromShipClass(hull).name);
  session.dispatch(ChooseShip(hull));
  session.dispatch(const VentureOutToSea());
  session.ship!.maxHp = 10000;
  session.ship!.currentHp = 10000;
  session.ship!.baseEvasion = 0;
  session.ship!.currentEvasion = 0;
  _monster(session, MonsterSpecies.shark, MonsterIntentId.sharkFrenziedJaws);
  return session;
}

void _monster(
  GameSession session,
  MonsterSpecies species,
  MonsterIntentId intent,
) {
  final monster = createMonster(species, level: 1, rng: session.rng);
  monster.maxHp = 10000;
  monster.currentHp = 10000;
  monster.evasion = 0;
  monster.currentIntent = MonsterIntent.fromId(intent);
  session.currentMonster = monster;
}

void _expectMovement(
  GameEvent event, {
  required CombatRange from,
  required CombatRange to,
  required CombatSide mover,
  required CombatSide instigator,
}) {
  expect(event, isA<CombatRangeChanged>());
  final movement = event as CombatRangeChanged;
  expect(movement.previousRange, from);
  expect(movement.newRange, to);
  expect(movement.mover, mover);
  expect(movement.instigator, instigator);
}

void main() {
  test(
    'Ram closes before its attempt and hit, retaining Medium charge damage',
    () {
      final session = _battle(hull: ShipClass.ironclad);
      final ram = session.ship!.equippedWeapons.singleWhere(
        (weapon) => weapon.weaponType == ShipWeaponType.prowRam,
      )..damage = 20;
      final events = session.dispatch(
        const FireWeaponVolley(ShipWeaponType.prowRam),
      );
      final shift = events.indexWhere((event) => event is CombatRangeChanged);
      final attempt = events.indexWhere(
        (event) =>
            event is AttackAttempted && event.attacker == CombatSide.ship,
      );
      final hit = events.whereType<AttackHit>().firstWhere(
        (event) => event.target == CombatSide.monster,
      );
      expect(shift, lessThan(attempt));
      expect(attempt, lessThan(events.indexOf(hit)));
      expect(hit.damage, 25, reason: '20 × 1.25 Medium charge bonus');
      expect((events[shift] as CombatRangeChanged).newRange, CombatRange.short);
      expect(ram.chargeCountdown, greaterThan(0));
    },
  );

  test('Ram already at Short has no phantom charge and keeps Short damage', () {
    final session = _battle(hull: ShipClass.ironclad)
      ..combatRange = CombatRange.short;
    session.ship!.equippedWeapons
            .singleWhere(
              (weapon) => weapon.weaponType == ShipWeaponType.prowRam,
            )
            .damage =
        20;
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.prowRam),
    );
    expect(events.whereType<CombatRangeChanged>(), isEmpty);
    expect(
      events
          .whereType<AttackHit>()
          .firstWhere((event) => event.target == CombatSide.monster)
          .damage,
      20,
    );
  });

  test('a missed Ram still closes before the attempted impact', () {
    final session = _battle(hull: ShipClass.ironclad);
    session.ship!.equippedWeapons
            .singleWhere(
              (weapon) => weapon.weaponType == ShipWeaponType.prowRam,
            )
            .hitModifier =
        0;
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.prowRam),
    );
    final shift = events.indexWhere((event) => event is CombatRangeChanged);
    final miss = events.indexWhere(
      (event) => event is AttackMissed && event.target == CombatSide.monster,
    );
    expect(shift, greaterThanOrEqualTo(0));
    expect(miss, greaterThan(shift));
    expect(session.combatRange, CombatRange.short);
  });

  test('a lethal Ram shows the charge before the fatal hit and cleanup', () {
    final session = _battle(hull: ShipClass.ironclad);
    session.currentMonster!.currentHp = 1;
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.prowRam),
    );
    final shift = events.indexWhere((event) => event is CombatRangeChanged);
    final hit = events.indexWhere(
      (event) => event is AttackHit && event.target == CombatSide.monster,
    );
    expect(shift, greaterThanOrEqualTo(0));
    expect(hit, greaterThan(shift));
    expect(session.phase, SessionPhase.loot);
  });

  for (final (range, damage) in [
    (CombatRange.long, 17),
    (CombatRange.medium, 20),
    (CombatRange.short, 17),
  ]) {
    test(
      'Harpoon hits from $range before pulling, with launch-range damage',
      () {
        final session = _battle(hull: ShipClass.corsair)..combatRange = range;
        session.ship!.equippedWeapons
                .singleWhere(
                  (weapon) => weapon.weaponType == ShipWeaponType.harpoonWinch,
                )
                .damage =
            20;
        final events = session.dispatch(
          const FireWeaponVolley(ShipWeaponType.harpoonWinch),
        );
        final hit = events.whereType<AttackHit>().firstWhere(
          (event) => event.target == CombatSide.monster,
        );
        expect(hit.damage, damage);
        final shifts = events.whereType<CombatRangeChanged>().toList();
        if (range == CombatRange.short) {
          expect(shifts, isEmpty);
        } else {
          expect(
            events.indexOf(shifts.first),
            greaterThan(events.indexOf(hit)),
          );
          expect(shifts.first.previousRange, range);
          expect(shifts.first.newRange, range.closer);
        }
      },
    );
  }

  test('ordinary helm movement belongs to the ship', () {
    final session = _battle();
    final events = session.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
    _expectMovement(
      events.whereType<CombatRangeChanged>().single,
      from: CombatRange.medium,
      to: CombatRange.long,
      mover: CombatSide.ship,
      instigator: CombatSide.ship,
    );
  });

  test('Short-to-Medium serpent retreat belongs to the monster', () {
    final session = _battle();
    session.combatRange = CombatRange.short;
    _monster(
      session,
      MonsterSpecies.serpent,
      MonsterIntentId.serpentFangedWhipRecoil,
    );
    final events = session.dispatch(const BraceForImpact());
    _expectMovement(
      events.whereType<CombatRangeChanged>().single,
      from: CombatRange.short,
      to: CombatRange.medium,
      mover: CombatSide.monster,
      instigator: CombatSide.monster,
    );
  });

  test('squid pull moves the ship and is caused by the monster', () {
    final session = _battle();
    _monster(
      session,
      MonsterSpecies.squid,
      MonsterIntentId.squidFeedingTentacleSnare,
    );
    final events = session.dispatch(const BraceForImpact());
    _expectMovement(
      events.whereType<CombatRangeChanged>().single,
      from: CombatRange.medium,
      to: CombatRange.short,
      mover: CombatSide.ship,
      instigator: CombatSide.monster,
    );
  });

  test('Harpoon moves the monster and is caused by the ship', () {
    final session = _battle(hull: ShipClass.corsair);
    session.combatRange = CombatRange.long;
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.harpoonWinch),
    );
    _expectMovement(
      events.whereType<CombatRangeChanged>().single,
      from: CombatRange.long,
      to: CombatRange.medium,
      mover: CombatSide.monster,
      instigator: CombatSide.ship,
    );
  });

  test('Ram moves the ship itself', () {
    final session = _battle(hull: ShipClass.ironclad);
    final events = session.dispatch(
      const FireWeaponVolley(ShipWeaponType.prowRam),
    );
    _expectMovement(
      events.whereType<CombatRangeChanged>().single,
      from: CombatRange.medium,
      to: CombatRange.short,
      mover: CombatSide.ship,
      instigator: CombatSide.ship,
    );
  });

  test('Evasive Rigging moves the ship itself', () {
    final session = _battle(hull: ShipClass.corvette);
    final events = session.dispatch(const ExecuteShipSpecialAction());
    _expectMovement(
      events.whereType<CombatRangeChanged>().single,
      from: CombatRange.medium,
      to: CombatRange.long,
      mover: CombatSide.ship,
      instigator: CombatSide.ship,
    );
  });

  test('Evasive Rigging opens range before its damaging utility rider', () {
    final session = _battle(hull: ShipClass.clipper);
    session.ship!.blessings[HardpointType.utility] = const HardpointBlessing(
      power: OceanPower.tempestSovereign,
      slot: HardpointType.utility,
      tier: 1,
    );
    session.currentMonster!.staticStacks = 2;
    final events = session.dispatch(const ExecuteShipSpecialAction());
    final shift = events.indexWhere((event) => event is CombatRangeChanged);
    final discharge = events.indexWhere(
      (event) => event is AttackHit && event.source == 'Arc Discharge',
    );
    expect(shift, greaterThanOrEqualTo(0));
    expect(discharge, greaterThan(shift));
  });

  test('Skirmisher late helm moves the ship itself', () {
    final session = _battle();
    session.activeQuirk = BloodlineTrait.skirmisher;
    final commitment = session.dispatch(
      const IssueHelmOrder(HelmOrder.fallBack),
    );
    expect(commitment.whereType<CombatRangeChanged>(), isEmpty);
    final events = session.dispatch(const BraceForImpact());
    _expectMovement(
      events.whereType<CombatRangeChanged>().single,
      from: CombatRange.medium,
      to: CombatRange.long,
      mover: CombatSide.ship,
      instigator: CombatSide.ship,
    );
  });

  test('charge and both ambush steps belong to the monster', () {
    final session = _battle();
    _monster(
      session,
      MonsterSpecies.shark,
      MonsterIntentId.sharkBreachingLunge,
    );
    final charge = session.dispatch(const BraceForImpact());
    _expectMovement(
      charge.whereType<CombatRangeChanged>().single,
      from: CombatRange.medium,
      to: CombatRange.short,
      mover: CombatSide.monster,
      instigator: CombatSide.monster,
    );

    session.combatRange = CombatRange.long;
    _monster(
      session,
      MonsterSpecies.serpent,
      MonsterIntentId.serpentAbyssalUnderStrike,
    );
    final ambush = session
        .dispatch(const BraceForImpact())
        .whereType<CombatRangeChanged>()
        .toList();
    expect(ambush, hasLength(2));
    _expectMovement(
      ambush[0],
      from: CombatRange.long,
      to: CombatRange.medium,
      mover: CombatSide.monster,
      instigator: CombatSide.monster,
    );
    _expectMovement(
      ambush[1],
      from: CombatRange.medium,
      to: CombatRange.short,
      mover: CombatSide.monster,
      instigator: CombatSide.monster,
    );
  });
}
