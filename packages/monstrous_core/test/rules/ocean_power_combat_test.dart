import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

import 'combat_test.dart'
    show
        QueueGameRng,
        createTestShip,
        createTestMonster,
        createTestShipWeapon,
        createTestMonsterWeapon;

void bless(ShipState ship, OceanPower power, HardpointType slot, int tier) {
  ship.blessings[slot] = HardpointBlessing(
    power: power,
    slot: slot,
    tier: tier,
  );
}

void main() {
  test(
    'Acid-Bore Mortar preserves its 2x shell crushing while bypassing armor',
    () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 1000)..carapacePlating = 1000;
      bless(ship, OceanPower.brinemother, HardpointType.signature, 2);
      calculateAttack(
        ship,
        createTestShipWeapon(
          type: ShipWeaponType.heavyMortar,
          damage: 100,
          damageType: DamageType.blast,
        ),
        monster,
        QueueGameRng(),
        [],
        0,
        1,
        CombatRange.long,
      );
      expect(monster.currentHp, 875);
      expect(monster.carapacePlating, 750);
    },
  );

  test('Calcify purges ignition duration before a later legacy Burn', () {
    final ship = createTestShip();
    final monster =
        createTestMonster(species: MonsterSpecies.crustacean, maxHp: 1000)
          ..currentIntent = MonsterIntent.fromId(
            MonsterIntentId.crustaceanCalcifyCarapace,
          );
    bless(ship, OceanPower.magmaVentLord, HardpointType.broadside, 3);
    calculateAttack(ship, createTestShipWeapon(), monster, QueueGameRng());
    expect(monster.burnTurns, 3);
    executeMonsterIntent(monster, ship, QueueGameRng(), CombatRange.medium);
    expect(monster.hasStatus(StatusEffect.burn), isFalse);
    expect(monster.burnTurns, 0);
    monster.addStatus(StatusEffect.burn);
    final (_, events) = updateStatusEffects(
      monster,
      1,
      QueueGameRng(d100Rolls: [100]),
      BalanceConfig.standard,
      ship,
      0,
    );
    expect(events.whereType<StatusEffectTicked>().single.damage, 5);
    expect(monster.hasStatus(StatusEffect.burn), isFalse);
  });

  test('Thermal Detonation benefits from flare and Corroded exactly once', () {
    final ship = createTestShip();
    final monster = createTestMonster(maxHp: 1000)
      ..spotterFlareTurns = 2
      ..spotterFlareBlastBonus = 0.25
      ..corrodedStacks = 3
      ..addStatus(StatusEffect.burn);
    bless(ship, OceanPower.magmaVentLord, HardpointType.signature, 2);
    bless(ship, OceanPower.brinemother, HardpointType.utility, 3);
    final (_, events) = calculateAttack(
      ship,
      createTestShipWeapon(type: ShipWeaponType.twinChasers, damage: 100),
      monster,
      QueueGameRng(),
    );
    expect(events.whereType<AttackHit>().map((e) => e.damage), [170, 68]);
  });

  group('Magma Vent-Lord', () {
    for (var tier = 1; tier <= 3; tier++) {
      test(
        'Tier $tier Magma Volley respects falloff and ignites for exactly 3 turns',
        () {
          final ship = createTestShip();
          final monster = createTestMonster(maxHp: 1000);
          bless(ship, OceanPower.magmaVentLord, HardpointType.broadside, tier);
          final weapon = createTestShipWeapon(
            type: ShipWeaponType.heavyCarronade,
            damage: 100,
          );
          final (result, _) = calculateAttack(
            ship,
            weapon,
            monster,
            QueueGameRng(),
            [],
            0,
            1,
            CombatRange.long,
          );
          expect(result.damage, [39, 42, 46][tier - 1]);
          expect(monster.burnTurns, 3);
          final hp = monster.currentHp;
          for (var turn = 0; turn < 3; turn++) {
            updateStatusEffects(
              monster,
              99,
              QueueGameRng(d100Rolls: [100]),
              BalanceConfig.standard,
              ship,
              0,
            );
          }
          expect(hp - monster.currentHp, [18, 30, 45][tier - 1]);
          expect(monster.burnTurns, 0);
          expect(monster.hasStatus(StatusEffect.burn), isFalse);
        },
      );

      test(
        'Tier $tier Caldera blast uses original damage and preserves Burn',
        () {
          final ship = createTestShip();
          final monster = createTestMonster(maxHp: 1000)
            ..addStatus(StatusEffect.burn);
          bless(ship, OceanPower.magmaVentLord, HardpointType.signature, tier);
          final (_, events) = calculateAttack(
            ship,
            createTestShipWeapon(type: ShipWeaponType.twinChasers, damage: 100),
            monster,
            QueueGameRng(),
          );
          final hits = events.whereType<AttackHit>().toList();
          expect(
            hits.map((hit) => hit.damage).toList(),
            [
              [115, 25],
              [125, 40],
              [140, 60],
            ][tier - 1],
          );
          expect(hits.last.isBlessingDamage, isTrue);
          expect(hits.last.damageType, DamageType.blast.displayName);
          expect(monster.hasStatus(StatusEffect.burn), isTrue);
        },
      );
    }

    test('Tier III Caldera ignites and detonates an unburned target; Blast crushes armor', () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 1000)..carapacePlating = 1000;
      bless(ship, OceanPower.magmaVentLord, HardpointType.signature, 3);
      calculateAttack(
        ship,
        createTestShipWeapon(type: ShipWeaponType.twinChasers, damage: 100),
        monster,
        QueueGameRng(),
      );
      expect(monster.carapacePlating, 770); // 140 kinetic + 60 * 1.5 Blast.
      expect(monster.currentHp, 1000);
      expect(monster.burnTurns, 3);
    });

    test('highest Magma tier governs ignition, with 10% per region and active wake boost', () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 1000);
      bless(ship, OceanPower.magmaVentLord, HardpointType.broadside, 1);
      bless(ship, OceanPower.magmaVentLord, HardpointType.utility, 3);
      activateUtilityBlessing(ship, monster);
      final (_, events) = updateStatusEffects(
        monster,
        99,
        QueueGameRng(),
        BalanceConfig.standard,
        ship,
        2,
      );
      expect(events.whereType<StatusEffectTicked>().single.damage, 27);
      monster.burnTurns = 0; // Legacy pitch/flamethrower burn also gets +50%.
      final (_, legacyEvents) = updateStatusEffects(
        monster,
        2,
        QueueGameRng(),
        BalanceConfig.standard,
        ship,
        0,
      );
      expect(legacyEvents.whereType<StatusEffectTicked>().single.damage, 15);
    });

    test('Boiling Wake damages each traversed band and kills before a charge attack', () {
      final ship = createTestShip();
      final monster =
          createTestMonster(
              maxHp: 50,
              species: MonsterSpecies.serpent,
              weapons: [createTestMonsterWeapon(damage: 100)],
            )
            ..currentIntent = MonsterIntent.fromId(
              MonsterIntentId.serpentAbyssalUnderStrike,
            );
      bless(ship, OceanPower.magmaVentLord, HardpointType.utility, 3);
      activateUtilityBlessing(ship, monster);
      final (range, events) = executeMonsterIntent(
        monster,
        ship,
        QueueGameRng(),
        CombatRange.long,
      );
      expect(range, CombatRange.short);
      expect(monster.isAlive, isFalse);
      expect(ship.currentHp, 100);
      expect(events.whereType<AttackHit>().map((hit) => hit.damage).toList(), [
        30,
        20,
      ]);
    });

    test('Pinned monster does not move through Boiling Wake', () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 1000)
        ..isPinnedThisTurn = true
        ..currentIntent = MonsterIntent.fromId(
          MonsterIntentId.sharkBreachingLunge,
        );
      bless(ship, OceanPower.magmaVentLord, HardpointType.utility, 1);
      activateUtilityBlessing(ship, monster);
      executeMonsterIntent(monster, ship, QueueGameRng(), CombatRange.medium);
      expect(monster.currentHp, 1000);
    });
  });

  group('Tempest Sovereign', () {
    test('Broadside stacks discharge at three, purge Frenzy, and jolt normal actions', () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 1000)..frenzyStacks = 3;
      bless(ship, OceanPower.tempestSovereign, HardpointType.broadside, 1);
      final weapon = createTestShipWeapon(damage: 100);
      calculateAttack(ship, weapon, monster, QueueGameRng());
      expect(monster.staticStacks, 1);
      calculateAttack(ship, weapon, monster, QueueGameRng());
      expect(monster.staticStacks, 2);
      calculateAttack(ship, weapon, monster, QueueGameRng());
      expect(monster.staticStacks, 0);
      expect(monster.currentHp, 658); // Three 110 hits and one 12 Shock burst.
      expect(monster.frenzyStacks, 0);
      expect(monster.isElectroJolted, isTrue);
      expect(monster.hasStatus(StatusEffect.stun), isFalse);
    });

    test(
      'Tier III Broadside extra-stack roll uses deterministic 35% threshold',
      () {
        final ship = createTestShip();
        bless(ship, OceanPower.tempestSovereign, HardpointType.broadside, 3);
        for (final roll in [35, 36]) {
          final monster = createTestMonster(maxHp: 1000);
          calculateAttack(
            ship,
            createTestShipWeapon(),
            monster,
            QueueGameRng(d100Rolls: [1, roll]),
          );
          expect(monster.staticStacks, roll == 35 ? 2 : 1);
        }
      },
    );

    for (var tier = 1; tier <= 3; tier++) {
      test('Tier $tier Signature critical chance and static stacks', () {
        final ship = createTestShip();
        bless(ship, OceanPower.tempestSovereign, HardpointType.signature, tier);
        final monster = createTestMonster(maxHp: 1000);
        final (result, events) = calculateAttack(
          ship,
          createTestShipWeapon(type: ShipWeaponType.twinChasers, damage: 100),
          monster,
          QueueGameRng(d100Rolls: [1, tier == 3 ? 20 : 15]),
        );
        expect(result.damage, [173, 188, 203][tier - 1]);
        expect(monster.staticStacks, tier == 3 ? 0 : 2);
        if (tier == 3) expect(events.whereType<AttackHit>().last.damage, 28);
      });
    }

    test(
      'Arc shatters lethal windup and deterministically denies only one action',
      () {
        final ship = createTestShip();
        final monster =
            createTestMonster(maxHp: 1000, species: MonsterSpecies.kraken)
              ..currentIntent = MonsterIntent.fromId(
                MonsterIntentId.bossKrakenWindup,
              );
        bless(ship, OceanPower.tempestSovereign, HardpointType.signature, 3);
        calculateAttack(
          ship,
          createTestShipWeapon(type: ShipWeaponType.twinChasers),
          monster,
          QueueGameRng(),
        );
        expect(monster.currentIntent!.isBossWindup, isFalse);
        expect(monster.hasStatus(StatusEffect.stun), isTrue);
        expect(
          updateStatusEffects(monster, 1, QueueGameRng(d100Rolls: [1])).canAct,
          isFalse,
        );
        expect(
          updateStatusEffects(monster, 1, QueueGameRng(d100Rolls: [1])).canAct,
          isTrue,
        );
        expect(
          monster.isIntentOnCooldown(MonsterIntentId.bossKrakenWindup),
          isTrue,
        );
      },
    );

    test('Electro-Jolt and Corroded reduce the next full monster action', () {
      final ship = createTestShip(maxHp: 1000);
      final monster = createTestMonster()
        ..isElectroJolted = true
        ..corrodedStacks = 3
        ..corrodedTurns = 3
        ..tremorAccPenalty = 15;
      final weapon = createTestMonsterWeapon(damage: 100, hitModifier: 90);
      expect(calculateHitChance(monster, weapon, ship), 45);
      final (result, _) = calculateAttack(
        monster,
        weapon,
        ship,
        QueueGameRng(d100Rolls: [1, 100]),
      );
      expect(result.damage, 64); // 100 * .85 * .75, rounded once.
      finishOceanPowerTurn(ship, monster);
      expect(monster.isElectroJolted, isFalse);
      expect(monster.tremorAccPenalty, 0);
      expect(monster.corrodedTurns, 2);
    });

    test('Storm Rigging arcs on missed attacks and newly reactive jolt survives cleanup', () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 1000);
      bless(ship, OceanPower.tempestSovereign, HardpointType.utility, 3);
      activateUtilityBlessing(ship, monster);
      expect(monster.staticStacks, 2);
      calculateAttack(
        monster,
        createTestMonsterWeapon(),
        ship,
        QueueGameRng(d100Rolls: [100]),
      );
      expect(monster.currentHp, 946); // 26 arc + 28 discharge.
      expect(monster.isElectroJolted, isTrue);
      finishOceanPowerTurn(ship, monster, electroJoltWasActiveAtStart: false);
      expect(monster.isElectroJolted, isTrue);
      expect(ship.stormRiggingTurns, 1);
    });

    test('Reactive lethal arc stops remaining tentacles', () {
      final ship = createTestShip();
      final monster =
          createTestMonster(
              maxHp: 20,
              species: MonsterSpecies.squid,
              numberOfTentacles: 5,
              weapons: [
                createTestMonsterWeapon(
                  type: MonsterWeaponType.tentacle,
                  damage: 10,
                ),
              ],
            )
            ..currentIntent = MonsterIntent.fromId(
              MonsterIntentId.squidSweepingTentacles,
            );
      bless(ship, OceanPower.tempestSovereign, HardpointType.utility, 3);
      activateUtilityBlessing(ship, monster);
      executeMonsterIntent(monster, ship, QueueGameRng(), CombatRange.medium);
      expect(ship.currentHp, 90);
      expect(monster.isAlive, isFalse);
    });
  });

  group('Brinemother', () {
    for (var tier = 1; tier <= 3; tier++) {
      test('Tier $tier Broadside doubles shell damage and adds flat melt', () {
        final ship = createTestShip();
        final monster = createTestMonster(maxHp: 1000)..carapacePlating = 1000;
        bless(ship, OceanPower.brinemother, HardpointType.broadside, tier);
        calculateAttack(
          ship,
          createTestShipWeapon(damage: 100),
          monster,
          QueueGameRng(),
        );
        expect(monster.carapacePlating, [776, 756, 738][tier - 1]);
        expect(monster.currentHp, 1000);
        expect(monster.corrodedStacks, tier == 3 ? 2 : 1);
      });

      test('Tier $tier Acid-Bore bypasses all armor while stripping it', () {
        final ship = createTestShip();
        final monster = createTestMonster(maxHp: 1000)..carapacePlating = 1000;
        bless(ship, OceanPower.brinemother, HardpointType.signature, tier);
        calculateAttack(
          ship,
          createTestShipWeapon(
            type: ShipWeaponType.precisionCulverin,
            damage: 100,
          ),
          monster,
          QueueGameRng(),
          [],
          0,
          1,
          CombatRange.long,
        );
        expect(monster.currentHp, [885, 875, 865][tier - 1]);
        expect(monster.carapacePlating, [885, 875, 865][tier - 1]);
        expect(monster.corrodedStacks, tier == 3 ? 3 : 2);
      });

      test(
        'Tier $tier Miasma clears obscurity, melts armor and applies corrosion',
        () {
          final ship = createTestShip();
          final monster = createTestMonster(isObscured: true)
            ..carapacePlating = 100;
          bless(ship, OceanPower.brinemother, HardpointType.utility, tier);
          activateUtilityBlessing(ship, monster);
          expect(monster.isObscured, isFalse);
          expect(monster.carapacePlating, [92, 86, 78][tier - 1]);
          expect(monster.corrodedStacks, tier);
          expect(monster.corrodedTurns, 3);
        },
      );
    }

    test(
      'Tier III unarmored Signature gains 15%; Corroded applies before armor',
      () {
        final ship = createTestShip();
        final monster = createTestMonster(maxHp: 1000)..corrodedStacks = 3;
        bless(ship, OceanPower.brinemother, HardpointType.signature, 3);
        final (result, _) = calculateAttack(
          ship,
          createTestShipWeapon(type: ShipWeaponType.twinChasers, damage: 100),
          monster,
          QueueGameRng(),
        );
        expect(result.damage, 211); // round(100*1.35*1.15)=155; 155*1.36=211.
        monster.carapacePlating = 1000;
        calculateAttack(
          ship,
          createTestShipWeapon(damage: 100),
          monster,
          QueueGameRng(),
        );
        expect(monster.carapacePlating, 864);
      },
    );

    test('Corroded amplifies Burn, typed riders, and traps once; expires after 3 actions', () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 1000)
        ..corrodedStacks = 3
        ..corrodedTurns = 3
        ..addStatus(StatusEffect.burn);
      bless(ship, OceanPower.brinemother, HardpointType.signature, 3);
      var hp = monster.currentHp;
      updateStatusEffects(
        monster,
        2,
        QueueGameRng(),
        BalanceConfig.standard,
        ship,
      );
      expect(hp - monster.currentHp, 14);
      hp = monster.currentHp;
      dealBlessingDamage(
        ship,
        monster,
        100,
        DamageType.fire,
        source: 'Test Wake',
      );
      expect(hp - monster.currentHp, 136);
      hp = monster.currentHp;
      ship.activeTetherTrapDistance = 1;
      ship.activeTetherTrapDamage = 100;
      detonateTetherTrap(
        ship,
        monster,
        QueueGameRng(),
        [],
        reason: 'Test trap',
      );
      expect(hp - monster.currentHp, 136);
      for (var i = 0; i < 3; i++) {
        finishOceanPowerTurn(ship, monster);
      }
      expect(monster.corrodedStacks, 0);
    });
  });

  group('Earthshaker Titan', () {
    for (var tier = 1; tier <= 3; tier++) {
      test(
        'Tier $tier Tremor Volley crushes shell and shakes accuracy for one turn',
        () {
          final ship = createTestShip();
          final monster = createTestMonster(maxHp: 1000)
            ..carapacePlating = 1000;
          bless(
            ship,
            OceanPower.earthshakerTitan,
            HardpointType.broadside,
            tier,
          );
          calculateAttack(
            ship,
            createTestShipWeapon(damage: 100),
            monster,
            QueueGameRng(),
          );
          expect(monster.carapacePlating, [827, 812, 797][tier - 1]);
          expect(monster.tremorAccPenalty, [10, 15, 20][tier - 1]);
          finishOceanPowerTurn(ship, monster);
          expect(monster.tremorAccPenalty, 0);
        },
      );

      test('Tier $tier Fault-Line breaks windup into a real normal strike', () {
        final ship = createTestShip();
        final monster =
            createTestMonster(
                maxHp: 1000,
                species: MonsterSpecies.kraken,
                weapons: [createTestMonsterWeapon(damage: 10)],
              )
              ..currentIntent = MonsterIntent.fromId(
                MonsterIntentId.bossKrakenWindup,
              );
        bless(ship, OceanPower.earthshakerTitan, HardpointType.signature, tier);
        final (result, _) = calculateAttack(
          ship,
          createTestShipWeapon(type: ShipWeaponType.twinChasers, damage: 100),
          monster,
          QueueGameRng(),
        );
        expect(result.damage, [150, 169, 203][tier - 1]);
        expect(monster.currentIntent!.id, MonsterIntentId.normalStrike);
        expect(monster.hasStatus(StatusEffect.stun), tier == 3);
        if (tier < 3) {
          executeMonsterIntent(
            monster,
            ship,
            QueueGameRng(),
            CombatRange.medium,
          );
          expect(ship.currentHp, 90);
          expect(ship.hasStatus(StatusEffect.poison), isFalse);
        }
      });

      test(
        'Tier $tier Basalt absorbs hit, grants evasion, and retaliates once when broken',
        () {
          final ship = createTestShip();
          final monster = createTestMonster(maxHp: 1000)
            ..carapacePlating = 1000;
          bless(ship, OceanPower.earthshakerTitan, HardpointType.utility, tier);
          activateUtilityBlessing(ship, monster);
          final barrier = [15, 25, 35][tier - 1];
          expect(ship.basaltBarrierHp, barrier);
          // Roll 15 falls within the temporary Aegis evasion, but not base evasion.
          final (dodge, _) = calculateAttack(
            monster,
            createTestMonsterWeapon(damage: 100),
            ship,
            QueueGameRng(d100Rolls: [1, 15]),
          );
          expect(dodge.wasEvaded, isTrue);
          expect(ship.basaltBarrierHp, barrier);
          calculateAttack(
            monster,
            createTestMonsterWeapon(damage: 100),
            ship,
            QueueGameRng(d100Rolls: [1, 100]),
          );
          expect(ship.currentHp, barrier);
          expect(ship.basaltBarrierHp, 0);
          expect(monster.carapacePlating, [982, 970, 955][tier - 1]);
        },
      );
    }

    test(
      'Aegis expires after two monster actions without altering base evasion',
      () {
        final ship = createTestShip(baseEvasion: 10);
        final monster = createTestMonster();
        bless(ship, OceanPower.earthshakerTitan, HardpointType.utility, 3);
        activateUtilityBlessing(ship, monster);
        finishOceanPowerTurn(ship, monster);
        expect(ship.basaltBarrierHp, 35);
        finishOceanPowerTurn(ship, monster);
        expect(ship.basaltBarrierHp, 0);
        expect(ship.currentEvasion, 10);
      },
    );
  });

  test('Evaded hits and misses never apply blessings or remove armor', () {
    final ship = createTestShip();
    final monster = createTestMonster(maxHp: 1000)
      ..evasion = 80
      ..carapacePlating = 1000;
    bless(ship, OceanPower.brinemother, HardpointType.broadside, 3);
    calculateAttack(
      ship,
      createTestShipWeapon(damage: 100),
      monster,
      QueueGameRng(d100Rolls: [1, 1]),
    );
    calculateAttack(
      ship,
      createTestShipWeapon(damage: 100),
      monster,
      QueueGameRng(d100Rolls: [100]),
    );
    expect(monster.corrodedStacks, 0);
    expect(monster.carapacePlating, 1000);
    expect(monster.currentHp, 1000);
  });

  test(
    'Retired refit weapons do not inherit intrinsic Broadside blessings',
    () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 1000);
      bless(ship, OceanPower.magmaVentLord, HardpointType.broadside, 3);
      final (result, _) = calculateAttack(
        ship,
        createTestShipWeapon(type: ShipWeaponType.bladeLauncher, damage: 100),
        monster,
        QueueGameRng(),
      );
      expect(result.damage, 100);
      expect(monster.hasStatus(StatusEffect.burn), isFalse);
    },
  );
}
