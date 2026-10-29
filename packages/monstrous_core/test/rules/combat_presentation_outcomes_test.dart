import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

import 'combat_test.dart'
    show
        QueueGameRng,
        createTestShip,
        createTestMonster,
        createTestShipWeapon,
        createTestMonsterWeapon;

void main() {
  test('armor, barrier and reactive impact retain separate ordered facts', () {
    final ship = createTestShip(baseDmgReduction: 3)
      ..basaltBarrierHp = 7
      ..basaltAegisTurns = 2
      ..blessings[HardpointType.utility] = const HardpointBlessing(
        power: OceanPower.earthshakerTitan,
        slot: HardpointType.utility,
        tier: 1,
      );
    final monster = createTestMonster();
    final (_, events) = calculateAttack(
      monster,
      createTestMonsterWeapon(damage: 20),
      ship,
      QueueGameRng(),
      const [],
      0,
      1,
      CombatRange.medium,
      true,
    );

    final reductions = events.whereType<DamageReduced>().toList();
    expect(reductions.map((event) => event.defense), [
      DefenseKind.mitigation,
      DefenseKind.barrier,
    ]);
    expect(reductions.map((event) => event.nullifiedAmount), [3, 7]);
    expect(reductions.last.remainingBarrierHp, 0);
    final impacts = events.whereType<AttackHit>().toList();
    expect(impacts.map((event) => event.target), [
      CombatSide.ship,
      CombatSide.monster,
    ]);
    expect(impacts.map((event) => event.remainingHp), [90, 88]);
    expect(impacts.first.source, isNull);
    expect(impacts.last.source, 'Tidal Shockwave');
    expect(
      events.indexOf(reductions.last),
      lessThan(events.indexOf(impacts.first)),
    );
    final barrierState = events.whereType<CombatEffectsChanged>().first.state;
    expect(barrierState.basaltBarrierHp, 0);
    // Later cleanup cannot overwrite the already emitted defense snapshot.
    ship.resetCombatBoosts();
    expect(barrierState.basaltAegisTurns, 2);
  });

  test(
    'weapon status application precedes tick and exact expiration state',
    () {
      final ship = createTestShip();
      final monster = createTestMonster();
      final (_, attackEvents) = calculateAttack(
        ship,
        createTestShipWeapon(damage: 10, statusEffect: StatusEffect.poison),
        monster,
        QueueGameRng(),
      );
      final applied = attackEvents.whereType<CombatEffectsChanged>().single;
      expect(applied.target, CombatSide.monster);
      expect(applied.state.statusEffects, [StatusEffect.poison]);
      expect(
        attackEvents.indexOf(applied),
        greaterThan(attackEvents.indexWhere((event) => event is AttackHit)),
      );

      final (_, tickEvents) = updateStatusEffects(
        monster,
        1,
        QueueGameRng(d100Rolls: [100]),
      );
      final tick = tickEvents.whereType<StatusEffectTicked>().single;
      expect(tick.target, CombatSide.monster);
      expect(tick.remainingHp, 85);
      expect(tick.woreOff, isTrue);
      expect(
        tickEvents.whereType<CombatEffectsChanged>().single.state.statusEffects,
        isEmpty,
      );
      expect(applied.state.statusEffects, [StatusEffect.poison]);
    },
  );

  test(
    'Static shows threshold, consumption, impact then windup disruption',
    () {
      final ship = createTestShip()
        ..blessings[HardpointType.utility] = const HardpointBlessing(
          power: OceanPower.tempestSovereign,
          slot: HardpointType.utility,
          tier: 1,
        );
      final monster = createTestMonster(species: MonsterSpecies.kraken)
        ..staticStacks = 2
        ..currentIntent = MonsterIntent.fromId(
          MonsterIntentId.bossKrakenWindup,
        );

      final events = activateUtilityBlessing(ship, monster);
      final stages = events
          .whereType<CombatEffectsChanged>()
          .where((event) => event.target == CombatSide.monster)
          .toList();
      expect(stages.map((event) => event.state.staticStacks), [3, 0, 0]);
      expect(stages.first.state.currentIntent!.isBossWindup, isTrue);
      expect(stages.first.state.statusEffects, isEmpty);
      expect(stages.last.state.currentIntent!.id, MonsterIntentId.normalStrike);
      expect(stages.last.state.statusEffects, [StatusEffect.stun]);
      final impact = events.whereType<AttackHit>().single;
      expect(impact.source, 'Arc Discharge');
      final disrupted = events.whereType<MonsterIntentDisrupted>().single;
      expect(
        disrupted.intentName,
        MonsterIntent.fromId(MonsterIntentId.bossKrakenWindup).name,
      );
      expect(disrupted.reason, contains('Arc Discharge'));
      expect(events.indexOf(impact), lessThan(events.indexOf(disrupted)));
      expect(events.indexOf(disrupted), lessThan(events.indexOf(stages.last)));
      expect(events.indexOf(stages[1]), lessThan(events.indexOf(impact)));
      expect(events.indexOf(impact), lessThan(events.indexOf(stages.last)));
      monster.removeStatus(StatusEffect.stun);
      expect(stages.last.state.statusEffects, [StatusEffect.stun]);
    },
  );

  test('Calcify reports actual capped shell restoration and status purge', () {
    final ship = createTestShip();
    final monster = createTestMonster(species: MonsterSpecies.crustacean)
      ..carapacePlating = 95
      ..maxCarapace = 100
      ..burnTurns = 2
      ..addStatus(StatusEffect.burn)
      ..addStatus(StatusEffect.poison)
      ..isPinnedThisTurn = true
      ..currentIntent = MonsterIntent.fromId(
        MonsterIntentId.crustaceanCalcifyCarapace,
      );

    final (_, events) = executeMonsterIntent(
      monster,
      ship,
      QueueGameRng(),
      CombatRange.medium,
    );
    final restoration = events.whereType<CarapaceRestored>().single;
    expect(restoration.restoredAmount, 5);
    expect(restoration.remainingCarapace, 100);
    final stages = events.whereType<CombatEffectsChanged>().toList();
    expect(stages.first.state.statusEffects, isEmpty);
    expect(stages.first.state.burnTurns, 0);
    expect(stages.last.state.isPinnedThisTurn, isFalse);
    expect(stages.last.state.currentIntent, isNull);
  });

  test(
    'end-of-response expiration reports buffs and stacks without rewriting HP',
    () {
      final ship = createTestShip()
        ..basaltBarrierHp = 9
        ..basaltAegisTurns = 1
        ..boilingWakeTurns = 1
        ..stormRiggingTurns = 1;
      final monster = createTestMonster()
        ..corrodedStacks = 2
        ..corrodedTurns = 1
        ..isElectroJolted = true
        ..tremorAccPenalty = 10;
      final events = finishOceanPowerTurn(ship, monster);
      final stages = events.whereType<CombatEffectsChanged>().toList();
      expect(stages.map((event) => event.target), [
        CombatSide.ship,
        CombatSide.monster,
      ]);
      expect(stages.first.state.basaltBarrierHp, 0);
      expect(stages.first.state.basaltAegisTurns, 0);
      expect(stages.first.state.boilingWakeTurns, 0);
      expect(stages.first.state.stormRiggingTurns, 0);
      expect(stages.last.state.corrodedStacks, 0);
      expect(stages.last.state.isElectroJolted, isFalse);
      expect(stages.last.state.tremorAccPenalty, 0);
      expect(events.whereType<AttackHit>(), isEmpty);
      expect(events.whereType<CombatHealthChanged>(), isEmpty);
    },
  );

  test(
    'consumed evasion and dispersed ink are recorded at their own outcome',
    () {
      final ship = createTestShip()..currentEvasion = 40;
      final monster = createTestMonster();
      final (_, dodgeEvents) = calculateAttack(
        monster,
        createTestMonsterWeapon(),
        ship,
        QueueGameRng(d100Rolls: [1, 1]),
      );
      expect(
        dodgeEvents.whereType<AttackEvaded>().single.target,
        CombatSide.ship,
      );
      expect(
        dodgeEvents
            .whereType<CombatEffectsChanged>()
            .first
            .state
            .currentEvasion,
        0,
      );

      final squid = createTestMonster(
        species: MonsterSpecies.squid,
        isObscured: true,
      );
      final (_, inkEvents) = calculateAttack(
        ship,
        createTestShipWeapon(),
        squid,
        QueueGameRng(d100Rolls: [1, 1]),
      );
      final dispersed = inkEvents.whereType<CombatEffectsChanged>().single;
      expect(dispersed.target, CombatSide.monster);
      expect(dispersed.state.isObscured, isFalse);
    },
  );

  test('Fault-Line Shatter names the original windup before its effects checkpoint', () {
    final ship = createTestShip()
      ..blessings[HardpointType.signature] = const HardpointBlessing(
        power: OceanPower.earthshakerTitan,
        slot: HardpointType.signature,
        tier: 3,
      );
    final monster = createTestMonster(
      species: MonsterSpecies.kraken,
      maxHp: 1000,
    )..currentIntent = MonsterIntent.fromId(MonsterIntentId.bossKrakenWindup);
    final originalIntent = monster.currentIntent!;
    final (_, events) = calculateAttack(
      ship,
      createTestShipWeapon(type: ShipWeaponType.twinChasers),
      monster,
      QueueGameRng(),
    );
    final disrupted = events.whereType<MonsterIntentDisrupted>().single;
    expect(disrupted.intentName, originalIntent.name);
    expect(disrupted.reason, contains('Fault-Line Shatter'));
    expect(
      events.whereType<NarrationEvent>().any(
        (event) =>
            event.message == 'Fault-Line Shatter breaks the lethal windup!',
      ),
      isTrue,
    );
    final effects = events.whereType<CombatEffectsChanged>().last;
    expect(events.indexOf(disrupted), lessThan(events.indexOf(effects)));
    expect(effects.state.currentIntent!.id, MonsterIntentId.normalStrike);
    expect(effects.state.statusEffects, [StatusEffect.stun]);
  });

  test('Wake and Thermal Detonation retain their distinct impact sources', () {
    final ship = createTestShip()
      ..boilingWakeTurns = 1
      ..blessings[HardpointType.utility] = const HardpointBlessing(
        power: OceanPower.magmaVentLord,
        slot: HardpointType.utility,
        tier: 1,
      )
      ..blessings[HardpointType.signature] = const HardpointBlessing(
        power: OceanPower.magmaVentLord,
        slot: HardpointType.signature,
        tier: 3,
      );
    final monster = createTestMonster(maxHp: 1000);
    final wake = triggerBoilingWake(ship, monster);
    expect(wake.whereType<AttackHit>().single.source, 'Boiling Wake');
    final (_, events) = calculateAttack(
      ship,
      createTestShipWeapon(type: ShipWeaponType.twinChasers),
      monster,
      QueueGameRng(),
    );
    expect(events.whereType<AttackHit>().map((event) => event.source), [
      null,
      'Thermal Detonation',
    ]);
  });
}
