import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

import '../rules/combat_test.dart'
    show
        QueueGameRng,
        createTestMonster,
        createTestMonsterWeapon,
        createTestShip;

/// Deliberately limited to authoritative numerical outcomes. Effects snapshots
/// contain health/shell/limbs too, but using them here would hide missing facts.
class _Replay {
  _Replay(GameSession session)
    : shipHp = session.ship!.currentHp,
      monsterHp = session.currentMonster!.currentHp,
      shell = session.currentMonster!.carapacePlating,
      limbs = session.currentMonster!.numberOfTentacles,
      range = session.combatRange;

  int shipHp, monsterHp, shell, limbs;
  CombatRange range;

  List<Object> get numbers => [shipHp, monsterHp, shell, limbs, range];

  void _health(CombatSide? side, int hp) {
    expect(side, isNotNull, reason: 'Production health outcomes need identity');
    if (side == CombatSide.ship) {
      shipHp = hp;
    } else {
      monsterHp = hp;
    }
  }

  void apply(GameEvent event) {
    switch (event) {
      case AttackHit(:final target, :final remainingHp):
        _health(target, remainingHp);
      case CombatHealthChanged(:final target, :final remainingHp):
        _health(target, remainingHp);
      case StatusEffectTicked(:final target, :final remainingHp):
        expect(remainingHp, isNotNull);
        _health(target, remainingHp!);
      case MortarBackfireOccurred(:final remainingHp):
        shipHp = remainingHp;
      case ThermalScaldOccurred(:final remainingHp):
        shipHp = remainingHp;
      case CarapaceDamaged(:final remainingCarapace):
        shell = remainingCarapace;
      case CarapaceRestored(:final remainingCarapace):
        shell = remainingCarapace;
      case CarapaceAbsorbed(:final remainingCarapace):
        expect(remainingCarapace, isNotNull);
        shell = remainingCarapace!;
      case TentaclesSevered(:final remainingTentacles):
        limbs = remainingTentacles;
      case CombatRangeChanged(:final previousRange, :final newRange):
        expect(
          range,
          previousRange,
          reason: 'Range outcomes must form a chain',
        );
        range = newRange;
      case CombatEffectsChanged():
        // Ignore even the numerical fields captured inside event.state.
        break;
      default:
        break;
    }
  }
}

GameSession _battle({
  BlueprintId hull = BlueprintId.standard,
  MonsterSpecies species = MonsterSpecies.shark,
  BloodlineTrait? quirk,
}) {
  final rng = QueueGameRng();
  final session = GameSession(rng: rng)
    ..captainName = 'Presentation test'
    ..phase = SessionPhase.battle
    ..ship = createFlagshipFromBlueprint(hull, rng: rng, name: 'Shared name')
    ..activeQuirk = quirk
    ..currentMonster =
        (createTestMonster(
            species: species,
            maxHp: 1000,
            numberOfTentacles: species == MonsterSpecies.squid ? 4 : 0,
            weapons: [createTestMonsterWeapon(damage: 8)],
          )
          ..name = 'Shared name'
          ..currentIntent = MonsterIntent.fromId(MonsterIntentId.normalStrike));
  return session;
}

List<GameEvent> _check(
  GameSession session,
  Command command, {
  _Replay? replay,
}) {
  final display = replay ?? _Replay(session);
  final events = session.dispatch(command);
  for (final event in events) {
    final before = display.numbers;
    display.apply(event);
    if (event is CombatEffectsChanged) {
      expect(
        display.numbers,
        before,
        reason: 'An effects checkpoint must never repair numerical playback',
      );
    }
  }
  expect(display.shipHp, session.ship!.currentHp, reason: '$command ship HP');
  expect(
    display.monsterHp,
    session.currentMonster!.currentHp,
    reason: '$command monster HP',
  );
  expect(
    display.shell,
    session.currentMonster!.carapacePlating,
    reason: '$command shell',
  );
  expect(
    display.limbs,
    session.currentMonster!.numberOfTentacles,
    reason: '$command limbs',
  );
  if (session.phase == SessionPhase.battle) {
    expect(display.range, session.combatRange, reason: '$command range');
  }
  // Victory resets the engine range for its next encounter. The playback hold
  // retains the final impact range, which is tested explicitly below.
  return events;
}

void main() {
  test(
    'effects snapshots cannot secretly repair HP, shell or limb playback',
    () {
      final session = _battle(species: MonsterSpecies.squid);
      final display = _Replay(session);
      final before = display.numbers;
      final unrelatedShip = createTestShip(maxHp: 3);
      final unrelatedMonster = createTestMonster(
        maxHp: 7,
        numberOfTentacles: 99,
      )..carapacePlating = 999;
      display.apply(CombatEffectsChanged.capture(unrelatedShip));
      display.apply(CombatEffectsChanged.capture(unrelatedMonster));
      expect(display.numbers, before);
    },
  );

  for (final hull in BlueprintId.values) {
    for (final species in [
      MonsterSpecies.shark,
      MonsterSpecies.squid,
      MonsterSpecies.crustacean,
      MonsterSpecies.serpent,
    ]) {
      test(
        '${hull.name}/${species.name}: utility, statuses and both hardpoints replay',
        () {
          final session = _battle(hull: hull, species: species);
          final monster = session.currentMonster!
            ..addStatus(StatusEffect.burn)
            ..addStatus(StatusEffect.poison);
          if (species == MonsterSpecies.crustacean) {
            monster
              ..maxCarapace = 100
              ..carapacePlating = 60
              ..currentIntent = MonsterIntent.fromId(
                MonsterIntentId.crustaceanCalcifyCarapace,
              );
          }
          if (species == MonsterSpecies.squid) monster.isObscured = true;
          if (species == MonsterSpecies.shark) monster.frenzyStacks = 2;
          session.ship!.blessings[HardpointType.utility] =
              const HardpointBlessing(
                power: OceanPower.earthshakerTitan,
                slot: HardpointType.utility,
                tier: 1,
              );
          final display = _Replay(session);
          _check(session, const ExecuteShipSpecialAction(), replay: display);
          for (final weapon in session.ship!.equippedWeapons) {
            if (!isWeaponTypeUsableAtRange(
              weapon.weaponType,
              session.combatRange,
            )) {
              _check(
                session,
                const IssueHelmOrder(HelmOrder.advance),
                replay: display,
              );
            }
            _check(
              session,
              FireWeaponVolley(weapon.weaponType),
              replay: display,
            );
          }
        },
      );
    }
  }

  for (final item in ConsumableType.values) {
    test(
      '${item.name}: quick item then attack retain independent outcomes',
      () {
        final session = _battle(species: MonsterSpecies.crustacean);
        session.ship!
          ..currentHp = 20
          ..cargo.add(generateConsumable(item, RarityLevel.common));
        session.currentMonster!
          ..maxCarapace = 8
          ..carapacePlating = 8;
        final display = _Replay(session);
        final round = session.battleRound;
        final quick = _check(
          session,
          const UseConsumableItem(0),
          replay: display,
        );
        expect(session.battleRound, round);
        if (item == ConsumableType.hullPatchKit) {
          final healed = quick.whereType<CombatHealthChanged>().single;
          expect(healed.isHealing, isTrue);
          expect(display.shipHp, greaterThan(20));
        }
        _check(
          session,
          const FireWeaponVolley(ShipWeaponType.cannon),
          replay: display,
        );
      },
    );
  }

  test('Siphon heal and Ghostwake damage are replayed before the response', () {
    for (final (hull, relic, weapon) in [
      (BlueprintId.ironclad, EldritchRelicId.siphonRam, ShipWeaponType.prowRam),
      (
        BlueprintId.clipper,
        EldritchRelicId.ghostwakeCulverin,
        ShipWeaponType.precisionCulverin,
      ),
    ]) {
      final session = _battle(hull: hull);
      session.ship!.currentHp = 20;
      session.profile.activeEldritchRelics.add(relic.name);
      final events = _check(session, FireWeaponVolley(weapon));
      final change = events.whereType<CombatHealthChanged>().single;
      expect(change.amount, greaterThan(0));
      expect(change.isHealing, relic == EldritchRelicId.siphonRam);
      final enemy = events.indexWhere(
        (event) =>
            event is AttackAttempted && event.attacker == CombatSide.monster,
      );
      if (enemy >= 0) expect(events.indexOf(change), lessThan(enemy));
    }
  });

  test('Ghostwake ignores ink without displaying a false clear/reapply rider frame', () {
    final session = _battle(
      hull: BlueprintId.clipper,
      species: MonsterSpecies.squid,
    );
    session.profile.activeEldritchRelics.add(
      EldritchRelicId.ghostwakeCulverin.name,
    );
    session.currentMonster!.isObscured = true;
    session.ship!.blessings[HardpointType.signature] = const HardpointBlessing(
      power: OceanPower.magmaVentLord,
      slot: HardpointType.signature,
      tier: 3,
    );
    session.ship!.equippedWeapons
            .firstWhere(
              (weapon) => weapon.weaponType == ShipWeaponType.precisionCulverin,
            )
            .statusEffect =
        StatusEffect.poison;

    final events = _check(
      session,
      const FireWeaponVolley(ShipWeaponType.precisionCulverin),
    );
    final frames = events
        .whereType<CombatEffectsChanged>()
        .where((event) => event.target == CombatSide.monster)
        .toList();
    expect(frames, isNotEmpty);
    expect(frames.every((frame) => frame.state.isObscured), isTrue);
    expect(session.currentMonster!.isObscured, isTrue);
    expect(events.whereType<InkCloudDeployed>(), isEmpty);
    final firstImpact = events.whereType<AttackHit>().first;
    expect(frames.first.state.currentHp, firstImpact.remainingHp);
    expect(
      frames.first.state.currentHp,
      greaterThan(session.currentMonster!.currentHp),
    );
    expect(frames.first.state.statusEffects, [StatusEffect.poison]);
    expect(
      frames.any(
        (frame) => frame.state.statusEffects.contains(StatusEffect.burn),
      ),
      isTrue,
    );
    // Sanitization copies the emitted stage; later mutations cannot alter it.
    session.currentMonster!.removeStatus(StatusEffect.poison);
    expect(frames.first.state.statusEffects, [StatusEffect.poison]);
  });

  test(
    'Impatient quick items and recovery replay without an extra response',
    () {
      final session = _battle(quirk: BloodlineTrait.impatient);
      final display = _Replay(session);
      final round = session.battleRound;
      _check(
        session,
        const ExecuteShipSpecialAction(borrowNextAction: true),
        replay: display,
      );
      expect(session.battleRound, round);
      expect(session.isImpatientCombinationPending, isTrue);
      session.ship!.cargo.add(
        generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
      );
      _check(session, const UseConsumableItem(0), replay: display);
      expect(session.battleRound, round);
      _check(
        session,
        const FireWeaponVolley(ShipWeaponType.cannon),
        replay: display,
      );
      expect(session.isImpatientRecovering, isTrue);
      expect(session.battleRound, round + 1);
      _check(
        session,
        const IssueHelmOrder(HelmOrder.holdLine),
        replay: display,
      );
      _check(session, const BraceForImpact(), replay: display);
      expect(session.isImpatientRecovering, isFalse);
      expect(session.battleRound, round + 2);
    },
  );

  test('Skirmisher follows Ram or Harpoon movement before the response', () {
    for (final (hull, weapon) in [
      (BlueprintId.ironclad, ShipWeaponType.prowRam),
      (BlueprintId.corsair, ShipWeaponType.harpoonWinch),
    ]) {
      final session = _battle(hull: hull, quirk: BloodlineTrait.skirmisher);
      final display = _Replay(session);
      _check(
        session,
        const IssueHelmOrder(HelmOrder.fallBack),
        replay: display,
      );
      final events = _check(session, FireWeaponVolley(weapon), replay: display);
      final shifts = events.whereType<CombatRangeChanged>().toList();
      expect(shifts[0].newRange, CombatRange.short);
      expect(shifts[1].previousRange, CombatRange.short);
      expect(shifts[1].newRange, CombatRange.medium);
      expect(shifts[1].reason, contains('Skirmisher'));
      final attempt = events.indexWhere(
        (event) =>
            event is AttackAttempted && event.attacker == CombatSide.ship,
      );
      final hit = events.indexWhere(
        (event) => event is AttackHit && event.target == CombatSide.monster,
      );
      expect(
        events.indexOf(shifts[0]),
        weapon == ShipWeaponType.prowRam ? lessThan(attempt) : greaterThan(hit),
      );
      expect(events.indexOf(shifts[1]), greaterThan(hit));
      final enemy = events.indexWhere(
        (event) =>
            event is AttackAttempted && event.attacker == CombatSide.monster,
      );
      if (enemy >= 0) expect(events.indexOf(shifts[1]), lessThan(enemy));
    }
  });

  test(
    'fatal backfire and a fatal strike plus reactive kill retain both deaths',
    () {
      final mortar = _battle(hull: BlueprintId.bombardier)
        ..combatRange = CombatRange.short;
      mortar.ship!.currentHp = 1;
      final backfire = _check(
        mortar,
        const FireWeaponVolley(ShipWeaponType.heavyMortar),
      );
      expect(mortar.phase, SessionPhase.death);
      expect(
        backfire.whereType<MortarBackfireOccurred>().single.remainingHp,
        0,
      );

      final reactive = _battle();
      reactive.ship!
        ..currentHp = 1
        ..basaltBarrierHp = 1
        ..basaltAegisTurns = 2
        ..blessings[HardpointType.utility] = const HardpointBlessing(
          power: OceanPower.earthshakerTitan,
          slot: HardpointType.utility,
          tier: 1,
        );
      reactive.currentMonster!.currentHp = 1;
      final events = _check(reactive, const BraceForImpact());
      final hits = events.whereType<AttackHit>().toList();
      expect(hits.map((event) => event.target), [
        CombatSide.ship,
        CombatSide.monster,
      ]);
      expect(hits.map((event) => event.remainingHp), [0, 0]);
      expect(reactive.phase, SessionPhase.death);
    },
  );

  test('victory holds the final Ram impact range through engine cleanup', () {
    final session = _battle(hull: BlueprintId.ironclad);
    session.currentMonster!.currentHp = 1;
    final display = _Replay(session);
    _check(
      session,
      const FireWeaponVolley(ShipWeaponType.prowRam),
      replay: display,
    );
    expect(session.phase, SessionPhase.loot);
    expect(display.range, CombatRange.short);
    expect(session.combatRange, CombatRange.medium);
  });

  test(
    'fatal status ticks preserve exact health independently of snapshots',
    () {
      final monsterDeath = _battle();
      monsterDeath.currentMonster!
        ..currentHp = 1
        ..addStatus(StatusEffect.burn);
      _check(monsterDeath, const BraceForImpact());
      expect(monsterDeath.phase, SessionPhase.loot);

      final shipDeath = _battle(species: MonsterSpecies.kraken);
      shipDeath.ship!
        ..currentHp = 1
        ..addStatus(StatusEffect.poison);
      shipDeath.currentMonster!.currentIntent = MonsterIntent.fromId(
        MonsterIntentId.bossKrakenWindup,
      );
      _check(shipDeath, const BraceForImpact());
      expect(shipDeath.phase, SessionPhase.death);
    },
  );

  test(
    'Harpoon, Wake and trap retain shell, tentacle and health endpoints',
    () {
      final session = _battle(
        hull: BlueprintId.corsair,
        species: MonsterSpecies.squid,
      );
      session.ship!
        ..activeTetherTrapDistance = 1
        ..activeTetherTrapDamage = 16
        ..boilingWakeTurns = 2
        ..blessings[HardpointType.utility] = const HardpointBlessing(
          power: OceanPower.magmaVentLord,
          slot: HardpointType.utility,
          tier: 1,
        );
      session.currentMonster!
        ..maxCarapace = 60
        ..carapacePlating = 60;
      final events = _check(
        session,
        const FireWeaponVolley(ShipWeaponType.harpoonWinch),
      );
      expect(events.whereType<CarapaceAbsorbed>(), isNotEmpty);
      expect(events.whereType<TentaclesSevered>(), isNotEmpty);
      expect(
        events.whereType<AttackHit>().where((event) => event.isBlessingDamage),
        isNotEmpty,
      );
      expect(session.ship!.activeTetherTrapDistance, isNull);
    },
  );

  test('caldera scald follows the attack with its own exact hull endpoint', () {
    final session = _battle();
    session.seaChart.timesCompleted = 2;
    session.battleRound = 3;
    final events = _check(session, const BraceForImpact());
    final scald = events.whereType<ThermalScaldOccurred>().single;
    final attack = events.whereType<AttackHit>().firstWhere(
      (event) => event.target == CombatSide.ship,
    );
    expect(events.indexOf(scald), greaterThan(events.indexOf(attack)));
    expect(scald.remainingHp, attack.remainingHp - scald.damage);
  });
}
