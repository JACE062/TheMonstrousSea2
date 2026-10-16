import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Persistence & Serialization Tests', () {
    test('ProfileData preserves full meta-inventory, lineage, nemesis, blueprints, and civic levels', () {
      final tracker = LineageTracker(captainsLost: 2, totalMonstersDefeated: 14);
      tracker.recordDeath(const CaptainRecord(
        captainName: 'Alistair Vane',
        shipName: 'Sea Sprite',
        shipClass: ShipClass.corvette,
        monstersDefeated: 8,
        highestDifficultyReached: 2,
        causeOfDeath: 'Apex Megalodon',
      ));

      const nemesis = NemesisRecord(
        species: MonsterSpecies.shark,
        baseName: 'Apex Megalodon',
        moniker: 'Apex Megalodon — The Butcher of Captain Alistair',
        predecessorCaptain: 'Alistair',
        regionIndex: 1,
        level: 3,
        bonusHp: 40,
        bonusCarapace: 40,
        bountyGold: 250,
        bountySeaGlass: 11,
        bountyMonsterBone: 15,
        bountyBarnacles: 5,
      );

      final profile = ProfileData(
        metaInventory: MetaInventory(
          seaGlass: 50,
          monsterBone: 25,
          depthWroughtIron: 10,
          abyssalBarnacles: 4,
          krakenBeak: 1,
        ),
        lineageTracker: tracker,
        activeNemesis: nemesis,
        unlockedBlueprints: {'railgun_mk1', 'chitin_armor'},
        portCivicLevels: {'lighthouse': 2, 'memorial': 1},
        covenantHeat: 3,
      );

      final json = profile.toJson();
      final restored = ProfileData.fromJson(json);

      expect(restored.metaInventory.seaGlass, 50);
      expect(restored.metaInventory.krakenBeak, 1);
      expect(restored.lineageTracker.captainsLost, 3);
      expect(restored.lineageTracker.history.length, 1);
      expect(restored.lineageTracker.history.first.captainName, 'Alistair Vane');
      expect(restored.activeNemesis, isNotNull);
      expect(restored.activeNemesis!.moniker, contains('Alistair'));
      expect(restored.unlockedBlueprints, contains('railgun_mk1'));
      expect(restored.unlockedBlueprints, contains('chitin_armor'));
      expect(restored.portCivicLevels['lighthouse'], 2);
      expect(restored.portCivicLevels['memorial'], 1);
      expect(restored.covenantHeat, 3);
    });

    test('VoyageSaveData round-trips full mid-run session state with items, weapons, and traits', () {
      final rng = SeededGameRng(555);
      final ship = createShip(ShipClass.ironclad, level: 2, rng: rng);
      final cannon = generateShipWeapon(ShipWeaponType.cannon, 2, RarityLevel.rare, rng);
      final repair = generateConsumable(ConsumableType.unstableTincture, RarityLevel.common);
      ship.addCargo(cannon);
      ship.addCargo(repair);
      ship.equipWeapon(cannon);
      ship.gold = 175;

      final voyage = VoyageSaveData(
        captainName: 'Rowan Vane the Iron-Eyed',
        ship: ship,
        regionIndex: 1,
        currentRow: 2,
        currentCol: 3,
        timesCompleted: 1,
        activeBoonId: BloodlineTraitId.veteranCannoneer,
        activeQuirkId: BloodlineTraitId.bloodOath,
        phase: SessionPhase.restArea,
        battleRound: 4,
        monstersDefeatedThisLife: 5,
        highestDifficultyThisLife: 3,
        gunneryAccuracyBoon: 15,
      );

      final json = voyage.toJson();
      final restored = VoyageSaveData.fromJson(json);

      expect(restored.captainName, 'Rowan Vane the Iron-Eyed');
      expect(restored.ship.shipClass, ShipClass.ironclad);
      expect(restored.ship.level, 2);
      expect(restored.ship.gold, 175);
      expect(restored.ship.equippedWeapons.length, 1);
      expect(restored.ship.equippedWeapons.first.name, cannon.name);
      expect(restored.ship.cargo.length, 1);
      expect(restored.ship.cargo.first.name, repair.name);
      expect(restored.regionIndex, 1);
      expect(restored.currentRow, 2);
      expect(restored.currentCol, 3);
      expect(restored.activeBoonId, BloodlineTraitId.veteranCannoneer);
      expect(restored.activeQuirkId, BloodlineTraitId.bloodOath);
      expect(restored.phase, SessionPhase.restArea);
      expect(restored.battleRound, 4);
      expect(restored.monstersDefeatedThisLife, 5);
      expect(restored.highestDifficultyThisLife, 3);
      expect(restored.gunneryAccuracyBoon, 15);
    });
  });
}
