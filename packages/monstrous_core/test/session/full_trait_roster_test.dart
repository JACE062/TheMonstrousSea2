import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Certain extends SeededGameRng {
  _Certain() : super(12);
  @override
  int d100() => 1;
}

GameSession _battle({
  BloodlineTrait? boon,
  BloodlineTrait? quirk,
  ShipClass hull = ShipClass.standard,
}) {
  final s = GameSession(rng: _Certain());
  s.profile.unlockedBlueprints.add(hull.blueprintId.name);
  s.dispatch(const NameCaptain('Test Captain'));
  s.dispatch(ChooseShip(hull));
  s.activeBoon = boon;
  s.activeQuirk = quirk;
  s.dispatch(const VentureOutToSea());
  s.currentMonster = createMonster(MonsterSpecies.shark, level: 1, rng: s.rng)
    ..maxHp = 10000
    ..currentHp = 10000
    ..evasion = 0
    ..carapacePlating = 0;
  s.ship!
    ..maxHp = 10000
    ..currentHp = 10000;
  for (final w in s.ship!.equippedWeapons) {
    w.hitModifier = 90;
    w.statusEffect = null;
  }
  return s;
}

void main() {
  test(
    'Skirmisher commits helm once and resolves after weapon, before response',
    () {
      final s = _battle(quirk: BloodlineTrait.skirmisher);
      s.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
      expect(s.combatRange, CombatRange.medium);
      expect(
        () => s.dispatch(const IssueHelmOrder(HelmOrder.advance)),
        throwsStateError,
      );
      final events = s.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      final helm = events.indexWhere(
        (e) => e is CombatRangeChanged && e.reason.contains('Skirmisher'),
      );
      final shot = events.indexWhere(
        (e) => e is AttackAttempted && e.attackerName == s.ship!.name,
      );
      final enemy = events.indexWhere(
        (e) => e is AttackAttempted && e.attackerName == s.currentMonster!.name,
      );
      expect(helm, greaterThan(shot));
      if (enemy >= 0) expect(helm, lessThan(enemy));
    },
  );

  test(
    'late legacy helm follows intrinsic Ram movement; grapple locks commitment',
    () {
      final s = _battle(
        quirk: BloodlineTrait.skirmisher,
        hull: ShipClass.ironclad,
      );
      s.dispatch(const ChangeCombatRange(CombatRange.long));
      final events = s.dispatch(const FireWeaponVolley(ShipWeaponType.prowRam));
      final shifts = events.whereType<CombatRangeChanged>().toList();
      final ram = shifts.indexWhere((e) => e.reason.contains('Prow Ram'));
      final late = shifts.indexWhere((e) => e.reason.contains('Skirmisher'));
      expect(ram, greaterThanOrEqualTo(0));
      expect(late, greaterThan(ram));
      expect(shifts[late].previousRange, CombatRange.short);
      expect(shifts[late].newRange, CombatRange.medium);
      s.ship!.isGrappled = true;
      expect(
        () => s.dispatch(const IssueHelmOrder(HelmOrder.advance)),
        throwsStateError,
      );
      s.dispatch(const IssueHelmOrder(HelmOrder.holdLine));
    },
  );

  test(
    'late helm cannot make an unusable weapon fire before its range shift',
    () {
      final s = _battle(
        quirk: BloodlineTrait.skirmisher,
        hull: ShipClass.ironclad,
      );
      s.combatRange = CombatRange.long;
      s.dispatch(const IssueHelmOrder(HelmOrder.advance));
      expect(
        () => s.dispatch(const FireWeaponVolley(ShipWeaponType.prowRam)),
        throwsStateError,
      );
      expect(s.combatRange, CombatRange.long);
      expect(() => s.dispatch(const BraceForImpact()), returnsNormally);
    },
  );

  test('Impatient combo gives one response, preserves both cooldowns, then belt/helm/Brace recovery', () {
    final s = _battle(quirk: BloodlineTrait.impatient);
    expect(s.canStartImpatientCombination, isTrue);
    final round = s.battleRound;
    s.dispatch(const ExecuteShipSpecialAction(borrowNextAction: true));
    expect(s.battleRound, round);
    expect(s.isImpatientCombinationPending, isTrue);
    expect(() => s.dispatch(const BraceForImpact()), throwsStateError);
    expect(
      () => s.dispatch(const ExecuteShipSpecialAction()),
      throwsStateError,
    );
    expect(
      () => s.dispatch(const IssueHelmOrder(HelmOrder.advance)),
      throwsStateError,
    );
    s.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
    expect(s.battleRound, round + 1);
    expect(s.ship!.utilityCooldown, 2);
    final cannon = s.ship!.equippedWeapons.firstWhere(
      (w) => w.weaponType == ShipWeaponType.cannon,
    );
    expect(cannon.chargeCountdown, cannon.chargeTime);
    expect(s.isImpatientRecovering, isTrue);
    expect(
      () => s.dispatch(const FireWeaponVolley(ShipWeaponType.cannon)),
      throwsStateError,
    );
    expect(
      () => s.dispatch(const ExecuteShipSpecialAction()),
      throwsStateError,
    );
    s.ship!.cargo.add(
      generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
    );
    s.dispatch(UseConsumableItem(s.ship!.cargo.length - 1));
    s.dispatch(const IssueHelmOrder(HelmOrder.holdLine));
    s.dispatch(const BraceForImpact());
    expect(s.battleRound, round + 2);
    expect(s.isImpatientRecovering, isFalse);
    expect(s.ship!.utilityCooldown, 1);
  });

  test('Impatient opt-in gates and normal utility remain intact', () {
    final plain = _battle();
    expect(
      () => plain.dispatch(
        const ExecuteShipSpecialAction(borrowNextAction: true),
      ),
      throwsStateError,
    );
    final s = _battle(quirk: BloodlineTrait.impatient);
    for (final w in s.ship!.equippedWeapons) {
      w.chargeCountdown = 2;
    }
    expect(s.canStartImpatientCombination, isFalse);
    expect(
      () => s.dispatch(const ExecuteShipSpecialAction(borrowNextAction: true)),
      throwsStateError,
    );
    final round = s.battleRound;
    s.dispatch(const ExecuteShipSpecialAction());
    expect(s.battleRound, round + 1);
    expect(s.isImpatientRecovering, isFalse);
  });

  test(
    'Quartermaster never stacks across assignment, commission, checkpoint',
    () {
      final s = _battle(boon: BloodlineTrait.quartermaster);
      final capacity = s.ship!.maxCargo;
      s.activeBoon = BloodlineTrait.quartermaster;
      s.syncCaptainTraits();
      expect(s.ship!.maxCargo, capacity);
      s.phase = SessionPhase.helm;
      final saved = VoyageSaveData.fromSession(s);
      final restored = GameSession(rng: _Certain(), profile: s.profile);
      saved.restoreToSession(restored);
      restored.syncCaptainTraits();
      expect(restored.ship!.maxCargo, capacity);
      restored.phase = SessionPhase.port;
      restored.dispatch(const CommissionBlueprint(BlueprintId.standard));
      expect(restored.ship!.maxCargo, capacity);
    },
  );

  test('healing modifies nominal before cap, repair quotes match paid result, triage reaches floor', () {
    final s = _battle(
      boon: BloodlineTrait.skilledCarpenter,
      quirk: BloodlineTrait.exactingShipwright,
    );
    s.ship!
      ..maxHp = 200
      ..currentHp = 170
      ..gold = 10000;
    s.phase = SessionPhase.respiteIsland;
    s.seaChart.currentLeg = s.seaChart.midpointHavenLeg;
    final healed = s
        .dispatch(const CareenHullAtIsland())
        .whereType<HullCareened>()
        .single;
    expect(healed.repairedHp, 30);
    s.ship!.currentHp = 100;
    s.phase = SessionPhase.smuggler;
    final quoteHp = s.repairHpFor(0.30);
    final quoteGold = s.repairCostFor(0.30);
    expect(quoteHp, 54);
    final paid = s
        .dispatch(const RepairShip(0.30))
        .whereType<ShipRepaired>()
        .single;
    expect(paid.repairedHp, quoteHp);
    expect(paid.goldCost, quoteGold);
    s.ship!.currentHp = 1;
    s.phase = SessionPhase.helm;
    final cost = s.emergencyRepairCost;
    final triage = s
        .dispatch(const RepairShip(1))
        .whereType<ShipRepaired>()
        .single;
    expect(s.ship!.currentHp, 50);
    expect(triage.goldCost, cost);
    expect(cost, greaterThan(49 * 2));
  });

  test(
    'Smuggler chosen free stock gift cannot be consumed by full belt, persists',
    () {
      final s = _battle(boon: BloodlineTrait.smugglersKin);
      s.phase = SessionPhase.smuggler;
      s.smugglerStock = [
        generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
        generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
      ];
      while (s.ship!.cargo.length < s.ship!.maxCargo) {
        s.ship!.cargo.add(
          generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
        );
      }
      expect(() => s.dispatch(const ClaimSmugglerGift(1)), throwsStateError);
      expect(s.hasClaimedSmugglerGift, isFalse);
      s.ship!.cargo.removeLast();
      final gift = s.smugglerStock[1];
      final gold = s.ship!.gold;
      s.dispatch(const ClaimSmugglerGift(1));
      expect(s.ship!.cargo.last, same(gift));
      expect(s.ship!.gold, gold);
      expect(s.hasClaimedSmugglerGift, isTrue);
      expect(() => s.dispatch(const ClaimSmugglerGift(0)), throwsStateError);
      final restored = GameSession(rng: _Certain(), profile: s.profile);
      VoyageSaveData.fromSession(s).restoreToSession(restored);
      expect(restored.hasClaimedSmugglerGift, isTrue);
    },
  );

  test(
    'Superstitious lock is stable and sole eligible manifestation is allowed',
    () {
      final s = _battle(quirk: BloodlineTrait.superstitious);
      s.phase = SessionPhase.shrine;
      s.shrineOmenSeed = 42;
      s.restoreShrineManifestations();
      final blocked = s.forbiddenShrinePower!;
      expect(
        s.shrineBlessingRestriction(blocked, HardpointType.broadside),
        contains('omen'),
      );
      expect(
        () =>
            s.dispatch(AcceptShrineBlessing(blocked, HardpointType.broadside)),
        throwsStateError,
      );
      s.restoreShrineManifestations();
      expect(s.forbiddenShrinePower, blocked);
      s.shrineManifestedPowers = [blocked];
      expect(s.forbiddenShrinePower, isNull);
      s.dispatch(AcceptShrineBlessing(blocked, HardpointType.broadside));
      expect(s.hasCommunedAtCurrentShrine, isTrue);
    },
  );

  test('fractional percentage sources combine once before rounding', () {
    final s = _battle(
      boon: BloodlineTrait.skilledCarpenter,
      quirk: BloodlineTrait.exactingShipwright,
    );
    s.ship!
      ..maxHp = 91
      ..currentHp = 1;
    s.phase = SessionPhase.respiteIsland;
    s.seaChart.currentLeg = s.seaChart.midpointHavenLeg;
    expect(s.careenHealingHp, 25);
    expect(
      s
          .dispatch(const CareenHullAtIsland())
          .whereType<HullCareened>()
          .single
          .repairedHp,
      25,
    );
    s.ship!.currentHp = 1;
    s.phase = SessionPhase.battle;
    s.ship!.cargo.add(
      generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
    );
    expect(s.hullPatchHealingHp, 25);
    s.dispatch(UseConsumableItem(s.ship!.cargo.length - 1));
    expect(s.ship!.currentHp, 26);
  });

  test('Daredevil grants weapon damage at exact half current maximum only', () {
    int damageAt(int hp, {bool daredevil = true}) {
      final s = _battle(quirk: daredevil ? BloodlineTrait.daredevil : null);
      s.ship!.currentHp = hp;
      return s
          .dispatch(const FireWeaponVolley(ShipWeaponType.cannon))
          .whereType<AttackHit>()
          .where((e) => e.targetName == s.currentMonster!.name)
          .fold(0, (sum, hit) => sum + hit.damage);
    }

    final baseline = damageAt(5000, daredevil: false);
    expect(damageAt(5001), baseline);
    expect(damageAt(5000), greaterThan(baseline));
    expect(damageAt(4999), damageAt(5000));
  });

  test('Impatient stages reset on victory, death, and real departure', () {
    final win = _battle(quirk: BloodlineTrait.impatient);
    win.dispatch(const ExecuteShipSpecialAction(borrowNextAction: true));
    win.currentMonster!.currentHp = 1;
    win.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
    expect(win.phase, SessionPhase.loot);
    expect(win.isImpatientCombinationPending, isFalse);
    expect(win.isImpatientRecovering, isFalse);
    final dead = _battle(quirk: BloodlineTrait.impatient);
    dead.dispatch(const ExecuteShipSpecialAction(borrowNextAction: true));
    dead.ship!.currentHp = 0;
    dead.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
    expect(dead.phase, SessionPhase.death);
    expect(dead.isImpatientCombinationPending, isFalse);
    expect(dead.isImpatientRecovering, isFalse);
    final fresh = _battle(quirk: BloodlineTrait.impatient);
    fresh.dispatch(const ExecuteShipSpecialAction(borrowNextAction: true));
    fresh.phase = SessionPhase.port;
    fresh.dispatch(const VentureOutToSea());
    expect(fresh.isImpatientCombinationPending, isFalse);
    expect(fresh.isImpatientRecovering, isFalse);
  });

  test('Superstitious transfers precisely three combat outcomes to shrine', () {
    final baseCounts = <EncounterNodeType, int>{};
    final omenCounts = <EncounterNodeType, int>{};
    for (var roll = 0; roll < 100; roll++) {
      for (final superstitious in [false, true]) {
        final chart = SeaChart(rng: SeededGameRng(1));
        chart.currentLeg = 2;
        final offers = chart.generateCourseOptions(
          _NavigationRoll(roll),
          null,
          false,
          false,
          superstitious,
        );
        final counts = superstitious ? omenCounts : baseCounts;
        for (final option in offers) {
          counts.update(option.nodeType, (n) => n + 1, ifAbsent: () => 1);
        }
      }
    }
    expect(
      omenCounts[EncounterNodeType.ancientShrine],
      baseCounts[EncounterNodeType.ancientShrine]! + 9,
    );
    expect(
      omenCounts[EncounterNodeType.beastCombat],
      baseCounts[EncounterNodeType.beastCombat]! - 9,
    );
    for (final type in [
      EncounterNodeType.shipwreckSalvage,
      EncounterNodeType.respiteIsland,
      EncounterNodeType.smugglerTrader,
    ]) {
      expect(omenCounts[type], baseCounts[type]);
    }
  });

  test('Smuggler kin repair discount applies to repair bill, never goods', () {
    final s = _battle(boon: BloodlineTrait.smugglersKin);
    s.phase = SessionPhase.smuggler;
    s.ship!
      ..maxHp = 200
      ..currentHp = 1
      ..gold = 1000;
    expect(s.repairHpFor(0.30), 60);
    expect(s.repairCostFor(0.30), (60 * 1.5 * 0.75).ceil());
    s.smugglerStock = [
      generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
    ];
    final asking = s.smugglerStock.single.value;
    s.dispatch(const BuyMerchantItem(0));
    expect(s.ship!.gold, 1000 - asking);
  });

  test(
    'Quartermaster preserves custom capacity and modifies it by one only',
    () {
      final s = _battle();
      s.ship!.maxCargo = 10;
      s.activeBoon = BloodlineTrait.quartermaster;
      expect(s.ship!.maxCargo, 11);
      s.activeQuirk = BloodlineTrait.daredevil;
      expect(s.ship!.maxCargo, 11);
      s.activeBoon = null;
      expect(s.ship!.maxCargo, 10);
    },
  );
}

class _NavigationRoll extends SeededGameRng {
  _NavigationRoll(this.roll) : super(10);
  final int roll;
  @override
  int nextInt(int maxExclusive) => roll % maxExclusive;
}
