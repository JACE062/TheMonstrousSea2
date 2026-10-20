import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _FixedDraw extends SeededGameRng {
  _FixedDraw(this.draw, {this.percentile = 1}) : super(1);
  final double draw;
  final int percentile;
  @override
  double nextDouble() => draw;
  @override
  int d100() => percentile;
}

GameSession _session() => GameSession(rng: SeededGameRng(144))
  ..dispatch(const NameCaptain('Ward of the Sea'))
  ..dispatch(const ChooseShip(ShipClass.standard));

void _enterShrine(GameSession session) {
  session.phase = SessionPhase.restArea;
  session.seaChart.currentRow = 0;
  session.seaChart.currentCol = 0;
  session.seaChart.setNodeTypeAt(0, 1, EncounterNodeType.ancientShrine);
  session.dispatch(const AdvanceToNextBattle());
}

void main() {
  test('Arc purge is not immediately undone by the Feeding Frenzy pact', () {
    final session = _session()..dispatch(const VentureOutToSea());
    session.profile.activePacts.add(CovenantPactId.feedingFrenzy);
    session.currentMonster = createMonster(
      MonsterSpecies.shark,
      level: 1,
      rng: _FixedDraw(0),
    );
    final monster = session.currentMonster!;
    monster.maxHp = 1000;
    monster.currentHp = 500;
    monster.frenzyStacks = 2;
    monster.staticStacks = 2;
    monster.currentIntent = const MonsterIntent(
      id: MonsterIntentId.normalStrike,
      threatenedRanges: {CombatRange.medium},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1,
      estimatedDamage: 10,
    );
    session.ship!.blessings[HardpointType.utility] = const HardpointBlessing(
      power: OceanPower.tempestSovereign,
      slot: HardpointType.utility,
      tier: 2,
    );
    final events = session.dispatch(const ExecuteShipSpecialAction());
    expect(events.whereType<SharkFrenzyDisrupted>(), isNotEmpty);
    expect(monster.frenzyStacks, 0);
  });
  test(
    'A fatal monster hit ends the voyage even if storm retaliation kills it',
    () {
      final session = GameSession(rng: _FixedDraw(0, percentile: 50))
        ..dispatch(const NameCaptain('Last Lightning'))
        ..dispatch(const ChooseShip(ShipClass.standard))
        ..dispatch(const VentureOutToSea());
      session.ship!.currentHp = 1;
      session.ship!.currentEvasion = 0;
      session.ship!.blessings[HardpointType.utility] = const HardpointBlessing(
        power: OceanPower.tempestSovereign,
        slot: HardpointType.utility,
        tier: 1,
      );
      session.ship!.stormRiggingTurns = 2;
      session.currentMonster!.currentHp = 1;
      session.currentMonster!.carapacePlating = 0;
      session.currentMonster!.currentIntent = const MonsterIntent(
        id: MonsterIntentId.normalStrike,
        threatenedRanges: {CombatRange.medium},
        moveDelta: IntentMoveDelta.stationary,
        moveTiming: IntentMoveTiming.none,
        damageMultiplier: 1,
        estimatedDamage: 10,
      );
      session.dispatch(const BraceForImpact());
      expect(session.ship!.isAlive, isFalse);
      expect(session.currentMonster!.isAlive, isFalse);
      expect(session.phase, SessionPhase.death);
      expect(session.monstersDefeatedThisLife, 0);
    },
  );
  test('Shrine manifests two distinct powers, sampled deterministically', () {
    final a = _session();
    final b = _session();
    _enterShrine(a);
    _enterShrine(b);
    expect(a.shrineManifestedPowers.length, 2);
    expect(a.shrineManifestedPowers.toSet().length, 2);
    expect(a.shrineManifestedPowers, b.shrineManifestedPowers);
  });

  test(
    'Aligned powers receive exactly 2.5 weight and sample without replacement',
    () {
      final ship = _session().ship!;
      ship.blessings[HardpointType.broadside] = const HardpointBlessing(
        power: OceanPower.magmaVentLord,
        slot: HardpointType.broadside,
        tier: 1,
      );
      expect(shrinePowerWeight(ship, OceanPower.magmaVentLord), 2.5);
      expect(shrinePowerWeight(ship, OceanPower.tempestSovereign), 1);
      // 2.5 / 5.5 is the first draw's exact aligned boundary.
      expect(
        selectShrinePowers(ship, _FixedDraw(0.45)).first,
        OceanPower.magmaVentLord,
      );
      expect(
        selectShrinePowers(ship, _FixedDraw(0.46)).first,
        OceanPower.tempestSovereign,
      );
      expect(selectShrinePowers(ship, _FixedDraw(0)).toSet().length, 2);
    },
  );

  test('Eligibility excludes maxed and foreign dedications, including legacy slots', () {
    final ship = _session().ship!;
    for (final slot in blessingHardpoints) {
      ship.blessings[slot] = HardpointBlessing(
        power: OceanPower.brinemother,
        slot: slot,
        tier: 3,
      );
    }
    expect(selectShrinePowers(ship, _FixedDraw(0)), isEmpty);
    ship.blessings[HardpointType.utility] = const HardpointBlessing(
      power: OceanPower.brinemother,
      slot: HardpointType.utility,
      tier: 2,
    );
    expect(selectShrinePowers(ship, _FixedDraw(0)), [OceanPower.brinemother]);
    expect(
      canBlessHardpoint(ship, OceanPower.brinemother, HardpointType.prow),
      isFalse,
    );
    ship.blessings.remove(HardpointType.utility);
    expect(eligibleShrinePowers(ship), OceanPower.values);
  });

  test(
    'A shrine permits one dedication and upgrades it across later shrines',
    () {
      final session = _session();
      _enterShrine(session);
      final power = session.shrineManifestedPowers.first;
      final other = session.shrineManifestedPowers.last;
      session.dispatch(AcceptShrineBlessing(power, HardpointType.broadside));
      expect(session.ship!.blessings[HardpointType.broadside]!.tier, 1);
      session.dispatch(AcceptShrineBlessing(other, HardpointType.signature));
      session.dispatch(const CommuneWithShrine(ShrineChoice.ancientRunes));
      expect(session.ship!.blessings.length, 1);
      expect(session.gunneryAccuracyBoon, 0);
      for (final tier in [2, 3]) {
        _enterShrine(session);
        session.shrineManifestedPowers = [power, other];
        expect(
          () => session.dispatch(
            AcceptShrineBlessing(other, HardpointType.broadside),
          ),
          throwsStateError,
        );
        expect(session.hasCommunedAtCurrentShrine, isFalse);
        session.dispatch(AcceptShrineBlessing(power, HardpointType.broadside));
        expect(session.ship!.blessings[HardpointType.broadside]!.tier, tier);
      }
      _enterShrine(session);
      session.shrineManifestedPowers = [power];
      expect(
        () => session.dispatch(
          AcceptShrineBlessing(power, HardpointType.broadside),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'Unmanifested powers and non-shrine commands cannot dedicate sockets',
    () {
      final session = _session();
      const command = AcceptShrineBlessing(
        OceanPower.magmaVentLord,
        HardpointType.broadside,
      );
      expect(() => session.dispatch(command), throwsStateError);
      _enterShrine(session);
      session.shrineManifestedPowers = [OceanPower.brinemother];
      expect(() => session.dispatch(command), throwsStateError);
      expect(session.hasCommunedAtCurrentShrine, isFalse);
    },
  );

  test(
    'Runes remain available at a fully sovereign shrine and only grant once',
    () {
      final session = _session();
      for (final slot in blessingHardpoints) {
        session.ship!.blessings[slot] = HardpointBlessing(
          power: OceanPower.brinemother,
          slot: slot,
          tier: 3,
        );
      }
      _enterShrine(session);
      expect(session.shrineManifestedPowers, isEmpty);
      session.dispatch(const CommuneWithShrine(ShrineChoice.ancientRunes));
      session.dispatch(const CommuneWithShrine(ShrineChoice.ancientRunes));
      expect(session.gunneryAccuracyBoon, 10);
      expect(session.runicGuidanceBoon, 10);
      expect(session.seaChart.isRevealed(1, 0), isTrue);
    },
  );

  test('Blessings and pending runic guidance survive voyage serialization', () {
    final session = _session();
    _enterShrine(session);
    session.ship!.blessings[HardpointType.signature] = const HardpointBlessing(
      power: OceanPower.tempestSovereign,
      slot: HardpointType.signature,
      tier: 2,
    );
    session.dispatch(const CommuneWithShrine(ShrineChoice.ancientRunes));
    session.dispatch(const DepartShrine());
    final restored = GameSession(rng: SeededGameRng(1));
    VoyageSaveData.fromJson(VoyageSaveData.fromSession(session).toJson())
        .restoreToSession(restored);
    expect(restored.ship!.blessings[HardpointType.signature]!.tier, 2);
    expect(restored.runicGuidanceBoon, 10);
    expect(restored.gunneryAccuracyBoon, 10);
  });

  test(
    'Consecutive shrines refresh guidance without stacking or erasing drills',
    () {
      final session = _session();
      session.gunneryAccuracyBoon = 15;
      _enterShrine(session);
      session.dispatch(const CommuneWithShrine(ShrineChoice.ancientRunes));
      expect(session.gunneryAccuracyBoon, 25);
      _enterShrine(session);
      session.dispatch(const CommuneWithShrine(ShrineChoice.ancientRunes));
      expect(session.gunneryAccuracyBoon, 25);
      expect(session.runicGuidanceBoon, 10);
    },
  );

  test(
    'Quick consumable victory clears temporary powers but retains dedications',
    () {
      final session = GameSession(rng: _FixedDraw(0))
        ..dispatch(const NameCaptain('Quick Finish'))
        ..dispatch(const ChooseShip(ShipClass.standard))
        ..dispatch(const VentureOutToSea());
      final ship = session.ship!;
      ship.blessings[HardpointType.utility] = const HardpointBlessing(
        power: OceanPower.earthshakerTitan,
        slot: HardpointType.utility,
        tier: 2,
      );
      ship.basaltBarrierHp = 25;
      ship.basaltAegisTurns = 2;
      ship.stormRiggingTurns = 2;
      ship.boilingWakeTurns = 2;
      session.runicGuidanceBoon = 10;
      session.gunneryAccuracyBoon = 10;
      session.currentMonster!.currentHp = 1;
      session.currentMonster!.carapacePlating = 0;
      ship.cargo.clear();
      ship.cargo.add(
        generateConsumable(ConsumableType.blastPack, RarityLevel.common),
      );
      session.dispatch(const UseConsumableItem(0));
      expect(session.phase, SessionPhase.loot);
      expect(ship.basaltBarrierHp, 0);
      expect(ship.basaltAegisTurns, 0);
      expect(ship.stormRiggingTurns, 0);
      expect(ship.boilingWakeTurns, 0);
      expect(ship.blessings[HardpointType.utility]!.tier, 2);
      expect(session.runicGuidanceBoon, 0);
      expect(session.gunneryAccuracyBoon, 0);
    },
  );

  test(
    'Runic guidance lasts all volleys of next combat and expires on victory',
    () {
      final session = _session();
      _enterShrine(session);
      session.dispatch(const CommuneWithShrine(ShrineChoice.ancientRunes));
      session.phase = SessionPhase.restArea;
      session.seaChart.setNodeTypeAt(0, 2, EncounterNodeType.beastCombat);
      session.dispatch(const AdvanceToNextBattle());
      session.currentMonster!.maxHp = 10000;
      session.currentMonster!.currentHp = 10000;
      session.ship!.maxHp = 10000;
      session.ship!.currentHp = 10000;
      session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(session.gunneryAccuracyBoon, 10);
      session.currentMonster!.currentHp = 0;
      session.dispatch(const BraceForImpact());
      expect(session.phase, SessionPhase.loot);
      expect(session.gunneryAccuracyBoon, 0);
      expect(session.runicGuidanceBoon, 0);
    },
  );

  test('Refits retain dedications while the next voyage starts unblessed', () {
    final session = _session();
    session.ship!.blessings[HardpointType.broadside] = const HardpointBlessing(
      power: OceanPower.magmaVentLord,
      slot: HardpointType.broadside,
      tier: 2,
    );
    session.dispatch(const CommissionBlueprint(BlueprintId.standard));
    expect(session.ship!.blessings[HardpointType.broadside]!.tier, 2);
    session.dispatch(const VentureOutToSea());
    expect(session.ship!.blessings, isEmpty);
  });

  test(
    'Ghostwake relic procs once per weapon hit, not for Arc Discharge riders',
    () {
      final session = GameSession(rng: _FixedDraw(0))
        ..dispatch(const NameCaptain('Storm Rail'))
        ..profile.unlockedBlueprints.add(BlueprintId.clipper.name)
        ..dispatch(const ChooseShip(ShipClass.clipper))
        ..dispatch(const VentureOutToSea());
      session.profile.activeEldritchRelics.add(
        EldritchRelicId.ghostwakeCulverin.name,
      );
      session.ship!.blessings[HardpointType.signature] =
          const HardpointBlessing(
            power: OceanPower.tempestSovereign,
            slot: HardpointType.signature,
            tier: 3,
          );
      session.currentMonster!.maxHp = 10000;
      session.currentMonster!.currentHp = 10000;
      session.currentMonster!.carapacePlating = 0;
      session.currentMonster!.evasion = 0;
      final events = session.dispatch(
        const FireWeaponVolley(ShipWeaponType.precisionCulverin),
      );
      final arcs = events.whereType<AttackHit>().where(
        (hit) => hit.isBlessingDamage,
      );
      expect(arcs, isNotEmpty);
      final ghostwake = events.whereType<NarrationEvent>().where(
        (event) => event.message.contains('Ghostwake Rail-Culverin arcs'),
      );
      expect(ghostwake.single.message, contains('+8 Shock'));
    },
  );
}
