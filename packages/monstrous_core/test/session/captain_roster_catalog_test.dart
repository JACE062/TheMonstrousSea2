import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  test('eight Boons and eight Quirks have distinct current catalog IDs', () {
    expect(BloodlineTrait.allBoons, hasLength(8));
    expect(BloodlineTrait.allQuirks, hasLength(8));
    expect(BloodlineTrait.allTraits.map((trait) => trait.id).toSet(), hasLength(16));
    expect(BloodlineTrait.allBoons.every((trait) => trait.isBoon), isTrue);
    expect(BloodlineTrait.allQuirks.every((trait) => trait.isQuirk), isTrue);
    expect(BloodlineTrait.allQuirks.any((trait) => trait.id == BloodlineTraitId.saltAddict), isFalse);
    expect(BloodlineTrait.preciseCommander.name, 'Precise Commander');
  });

  test('current traits and legacy Salt-Addict resolve through catalog serialization', () {
    for (final trait in BloodlineTrait.allTraits) {
      expect(BloodlineTrait.fromJson(trait.toJson()), same(trait));
    }
    expect(BloodlineTrait.fromJson({'id': 'saltAddict'}), same(BloodlineTrait.exactingShipwright));
    expect(BloodlineTrait.saltAddict, same(BloodlineTrait.exactingShipwright));
  });

  test('seeded heir offers vary across pool, are unique within set, and obey Vendetta eligibility', () {
    final seenBoons = <BloodlineTraitId>{};
    final seenQuirks = <BloodlineTraitId>{};
    for (var seed = 0; seed < 120; seed++) {
      final heirs = generateHeirCandidates(rng: SeededGameRng(seed), nemesisSpecies: MonsterSpecies.shark);
      final repeat = generateHeirCandidates(rng: SeededGameRng(seed), nemesisSpecies: MonsterSpecies.shark);
      expect(heirs.map((heir) => heir.toJson()).toList(), repeat.map((heir) => heir.toJson()).toList());
      expect(heirs.map((heir) => heir.boon.id).toSet(), hasLength(3));
      expect(heirs.map((heir) => heir.quirk.id).toSet(), hasLength(3));
      expect(heirs.map((heir) => heir.defaultName).toSet(), hasLength(3));
      expect(heirs.where((heir) => heir.quirk.id == BloodlineTraitId.bloodOath), hasLength(1));
      seenBoons.addAll(heirs.map((heir) => heir.boon.id));
      seenQuirks.addAll(heirs.map((heir) => heir.quirk.id));
      for (final species in [null, MonsterSpecies.kraken, MonsterSpecies.worldSerpent, MonsterSpecies.ancientLeviathan]) {
        final eligible = generateHeirCandidates(rng: SeededGameRng(seed), nemesisSpecies: species);
        expect(eligible.any((heir) => heir.quirk.id == BloodlineTraitId.bloodOath), isFalse);
      }
    }
    expect(seenBoons, hasLength(8));
    expect(seenQuirks, hasLength(8));
  });

  test('Quartermaster capacity and derived healing survive repeated checkpoints without stacking', () {
    var session = GameSession(rng: SeededGameRng(101))
      ..dispatch(const BeginFirstVoyage('Captain Reed'));
    session.activeBoon = BloodlineTrait.quartermaster;
    session.activeQuirk = BloodlineTrait.exactingShipwright;
    expect(session.ship!.maxCargo, 4);
    session.phase = SessionPhase.helm;
    session.shrineOmenSeed = 811;
    session.hasClaimedSmugglerGift = true;
    for (var reload = 0; reload < 5; reload++) {
      final json = VoyageSaveData.fromSession(session).toJson();
      final next = GameSession(rng: SeededGameRng(999), profile: ProfileData.fromJson(session.profile.toJson()));
      VoyageSaveData.fromJson(json).restoreToSession(next);
      expect(next.ship!.maxCargo, 4);
      expect(next.ship!.captainHealingMultiplier, 0.75);
      expect(next.shrineOmenSeed, 811);
      expect(next.hasClaimedSmugglerGift, isTrue);
      session = next;
    }
    session.activeBoon = BloodlineTrait.skilledCarpenter;
    expect(session.ship!.maxCargo, 3);
    expect(session.ship!.captainHealingMultiplier, closeTo(0.9, 1e-9));
  });

  test('legacy active quirk checkpoints adopt Exacting without touching the death ledger', () {
    final session = GameSession(rng: SeededGameRng(4))
      ..dispatch(const BeginFirstVoyage('Captain Reed'));
    session.phase = SessionPhase.helm;
    final json = VoyageSaveData.fromSession(session).toJson()..['activeQuirkId'] = 'saltAddict';
    final restored = GameSession(rng: SeededGameRng(5), profile: session.profile);
    VoyageSaveData.fromJson(json).restoreToSession(restored);
    expect(restored.activeQuirk, same(BloodlineTrait.exactingShipwright));
    expect(restored.ship!.captainHealingMultiplier, 0.75);
    expect(restored.lineage.history, isEmpty);
  });

  test('hull refit restoration uses healing modifiers while retaining full new capacity', () {
    final session = GameSession(rng: SeededGameRng(4))
      ..dispatch(const BeginFirstVoyage('Captain Reed'));
    session.activeBoon = BloodlineTrait.skilledCarpenter;
    session.activeQuirk = BloodlineTrait.exactingShipwright;
    final oldMax = session.ship!.maxHp;
    session.ship!.currentHp = 10;
    upgradeShipState(session.ship!);
    expect(session.ship!.maxHp, oldMax + 50);
    expect(session.ship!.currentHp, 55); // 10 + round(50 * 1.2 * .75)
  });

  test('Quartermaster commission allocates the extra slot before transferring supplies', () {
    final session = GameSession(rng: SeededGameRng(14))
      ..dispatch(const BeginFirstVoyage('Captain Reed'));
    session.activeBoon = BloodlineTrait.quartermaster;
    for (var i = 0; i < 4; i++) {
      session.ship!.addCargo(generateConsumable(ConsumableType.hullPatchKit,
          RarityLevel.common, id: 'supply-$i'));
    }
    session.profile.unlockedBlueprints.add(BlueprintId.clipper.name);
    session.phase = SessionPhase.port;
    session.dispatch(const CommissionBlueprint(BlueprintId.clipper));
    expect(session.ship!.maxCargo, 4);
    expect(session.ship!.cargo.map((item) => item.id),
        ['supply-0', 'supply-1', 'supply-2', 'supply-3']);
  });

  test('Quartermaster succession allocates the slot before Corsair supply inheritance', () {
    final session = GameSession(rng: SeededGameRng(15))
      ..dispatch(const BeginFirstVoyage('Captain Reed'));
    session.ship = createFlagshipFromBlueprint(BlueprintId.corsair, rng: SeededGameRng(16));
    for (var i = 0; i < 4; i++) {
      session.ship!.addCargo(generateConsumable(ConsumableType.hullPatchKit,
          RarityLevel.common, id: 'inherited-$i'));
    }
    session.phase = SessionPhase.death;
    session.dispatch(ContinueLineage('Heir Reed', ShipClass.standard,
        boon: BloodlineTrait.quartermaster, quirk: BloodlineTrait.exactingShipwright));
    expect(session.ship!.maxCargo, 4);
    expect(session.ship!.cargo.map((item) => item.id),
        ['inherited-0', 'inherited-1', 'inherited-2', 'inherited-3']);
  });

  for (final blueprint in [BlueprintId.ironclad, BlueprintId.corsair]) {
    test('Skirmisher ${blueprint.name} predicts intrinsic movement before late helm', () {
      final session = GameSession(rng: SeededGameRng(21))
        ..dispatch(const BeginFirstVoyage('Captain Reed'));
      session.ship = createFlagshipFromBlueprint(blueprint, rng: SeededGameRng(22));
      session.activeQuirk = BloodlineTrait.skirmisher;
      session.combatRange = CombatRange.medium;
      session.currentMonster = createSquid(level: 1, rng: SeededGameRng(3))
        ..maxHp = 10000
        ..currentHp = 10000
        ..currentIntent = MonsterIntent.fromId(MonsterIntentId.squidSweepingTentacles);
      final type = blueprint.signatureWeaponType;
      final predicted = session.previewResponseRange(helmOrder: HelmOrder.fallBack, weaponType: type);
      expect(predicted, CombatRange.medium);
      session.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
      expect(session.combatRange, CombatRange.medium);
      session.dispatch(FireWeaponVolley(type));
      expect(session.combatRange, predicted);
    });
  }
}
