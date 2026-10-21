import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Connect extends SeededGameRng {
  _Connect([this.weaponIndex = 0]) : super(42);
  final int weaponIndex;
  int calls = 0;
  @override
  int d100() => (calls++).isEven ? 1 : 100;
  @override
  int nextInt(int maxExclusive) => weaponIndex % maxExclusive;
}

MonsterState _squid() => createSquid(
  level: 5,
  rng: SeededGameRng(42),
)..currentIntent = MonsterIntent.fromId(MonsterIntentId.squidSweepingTentacles);

ShipState _ship(BlueprintId bp) =>
    createFlagshipFromBlueprint(bp, rng: SeededGameRng(42));

List<GameEvent> _sweep(
  MonsterState monster,
  ShipState ship, [
  int selection = 0,
]) {
  monster.currentIntent = MonsterIntent.fromId(
    MonsterIntentId.squidSweepingTentacles,
  );
  return executeMonsterIntent(
    monster,
    ship,
    _Connect(selection),
    CombatRange.medium,
  ).$2;
}

void main() {
  for (final (level, perHit) in [(7, 5), (9, 6), (11, 7), (12, 7)]) {
    for (final bp in BlueprintId.values) {
      test('level $level sweep deals $perHit per limb against ${bp.name}', () {
        final monster = createSquid(level: level, rng: SeededGameRng(42));
        final ship = _ship(bp);
        final before = ship.currentHp;
        final expected = (perHit - ship.currentDmgReduction).clamp(0, perHit);
        final events = _sweep(monster, ship);
        expect(events.whereType<AttackAttempted>().length, 8);
        expect(
          events.whereType<AttackHit>().map((e) => e.damage),
          everyElement(expected),
        );
        expect(before - ship.currentHp, expected * 8);
        final preview =
            MonsterIntent.fromId(MonsterIntentId.squidSweepingTentacles)
                .evaluatePreview(
                  currentRange: CombatRange.medium,
                  selectedHelmOrder: HelmOrder.holdLine,
                  tentacleCount: 8,
                  damagePerTentacle: perHit,
                );
        expect(preview.estimatedDamage, perHit * 8);
      });
    }
  }

  for (final (level, hp, limbs) in [
    (1, 40, 4),
    (4, 100, 7),
    (5, 120, 8),
    (8, 180, 8),
    (9, 200, 8),
  ]) {
    test('level $level ordinary and Apex scaling remain below limb cap', () {
      final normal = createSquid(level: level, rng: SeededGameRng(42));
      final apex = createMonster(
        MonsterSpecies.squid,
        level: level,
        rng: SeededGameRng(42),
        isApex: true,
      );
      expect(normal.maxHp, hp);
      expect(normal.numberOfTentacles, limbs);
      expect(apex.maxHp, (hp * 1.3).round());
      expect(apex.numberOfTentacles, limbs + 2);
    });
  }

  test('opening R2 squid is a regional step, not the Kraken profile', () {
    final chart = SeaChart(timesCompleted: 1, rng: SeededGameRng(42));
    chart.restoreFromJson({
      ...chart.toJson(),
      'currentLeg': 2,
      'gridSpecies': List.generate(
        SeaChart.totalRows,
        (_) => List.filled(SeaChart.totalCols, MonsterSpecies.squid.name),
      ),
    });
    final monster = chart.currentMonster(SeededGameRng(42));
    final kraken = createKraken();
    expect(monster.level, 5);
    expect(monster.maxHp, 120);
    expect(monster.numberOfTentacles, 8);
    expect(kraken.maxHp, 300);
    expect(kraken.numberOfTentacles, 12);
    expect(MonsterIntent.krakenMaelstromBaseDamage, 38);
  });

  for (final bp in BlueprintId.values) {
    for (final upgraded in [false, true]) {
      test(
        '${bp.name} upgraded=$upgraded: sweep uses limbs, retains per-hit armor',
        () {
          final ship = _ship(bp);
          if (upgraded) {
            upgradeShipState(ship);
            for (final slot in blessingHardpoints) {
              temperShipHardpoint(ship, slot);
            }
          }
          final before = ship.currentHp;
          final perHit = (4 - ship.currentDmgReduction).clamp(0, 4);
          final events = _sweep(_squid(), ship);
          expect(events.whereType<AttackAttempted>().length, 8);
          expect(ship.currentHp, before - perHit * 8);
          expect(
            events.whereType<AttackHit>().map((e) => e.damage),
            everyElement(perHit),
          );
        },
      );
    }
    test('${bp.name}: existing intrinsic severing reduces the next sweep', () {
      for (final slot in [HardpointType.broadside, HardpointType.signature]) {
        final ship = _ship(bp);
        final weapon = ship.equippedWeapons.firstWhere(
          (w) => w.isSignature == (slot == HardpointType.signature),
        );
        final monster = _squid();
        final canSever =
            weapon.damageType == DamageType.slicing ||
            weapon.weaponType == ShipWeaponType.harpoonWinch;
        calculateAttack(ship, weapon, monster, _Connect());
        expect(monster.numberOfTentacles, canSever ? lessThan(8) : 8);
        final remaining = monster.numberOfTentacles;
        final events = _sweep(monster, ship);
        expect(events.whereType<AttackAttempted>().length, remaining);
      }
    });
    test(
      '${bp.name}: helm avoids a sweep without needing severing or armor',
      () {
        final session = GameSession(rng: SeededGameRng(42));
        session.profile.unlockedBlueprints.add(bp.name);
        session.dispatch(ChooseShip(bp.shipClass));
        session.dispatch(const VentureOutToSea());
        session.currentMonster = _squid();
        session.ship!.currentDmgReduction = 0;
        final before = session.ship!.currentHp;
        session.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
        final events = session.dispatch(
          FireWeaponVolley(bp.broadsideWeaponType),
        );
        expect(events.whereType<MonsterAttackOutOfRange>(), isNotEmpty);
        expect(session.ship!.currentHp, before);
      },
    );
  }

  for (final choice in [0, 1]) {
    test('sweep ignores arbitrary normal weapon choice $choice', () {
      final monster = _squid();
      final ship = _ship(BlueprintId.standard);
      final events = _sweep(monster, ship, choice);
      expect(events.whereType<AttackAttempted>().length, 8);
      expect(
        events.whereType<AttackAttempted>().map((e) => e.weaponName),
        everyElement(monster.usableWeapons.last.name),
      );
      expect(ship.maxHp - ship.currentHp, 32);
    });
  }

  test('missing tentacle weapon never substitutes a ram', () {
    final monster = _squid()
      ..usableWeapons.removeWhere(
        (w) => w.monsterWeaponType == MonsterWeaponType.tentacle,
      );
    final ship = _ship(BlueprintId.standard);
    final events = _sweep(monster, ship);
    expect(events.whereType<MonsterHesitated>(), isNotEmpty);
    expect(events.whereType<AttackAttempted>(), isEmpty);
    expect(ship.currentHp, ship.maxHp);
  });

  test('severed Kraken limbs weaken sweeps without weakening maelstrom', () {
    final monster = createKraken()..numberOfTentacles = 3;
    final ship = _ship(BlueprintId.standard);
    final events = _sweep(monster, ship);
    expect(events.whereType<AttackAttempted>().length, 3);
    expect(ship.maxHp - ship.currentHp, 12);
    monster.currentIntent = MonsterIntent.fromId(
      MonsterIntentId.bossKrakenCatastrophe,
    );
    ship.currentHp = ship.maxHp;
    executeMonsterIntent(monster, ship, _Connect(), CombatRange.medium);
    expect(ship.maxHp - ship.currentHp, 38);
  });

  test('preview tracks remaining strikes, gross damage and helm escape', () {
    final intent = MonsterIntent.fromId(MonsterIntentId.squidSweepingTentacles);
    final preview = intent.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.holdLine,
      tentacleCount: 8,
      damagePerTentacle: 4,
    );
    expect(preview.estimatedDamage, 32);
    expect(preview.summaryBadge, contains('8 x 4 base Blast'));
    final escaped = intent.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.fallBack,
      tentacleCount: 8,
      damagePerTentacle: 4,
    );
    expect(escaped.estimatedDamage, 0);
    expect(escaped.isSafe, isTrue);
    final disarmed = intent.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.holdLine,
      tentacleCount: 0,
      damagePerTentacle: 4,
    );
    expect(disarmed.estimatedDamage, 0);
    expect(disarmed.isSafe, isTrue);
    final monster = _squid()..numberOfTentacles = 0;
    final events = _sweep(monster, _ship(BlueprintId.standard));
    expect(events.whereType<AttackAttempted>(), isEmpty);
    expect(events.whereType<AttackMissed>(), isEmpty);
  });
}
