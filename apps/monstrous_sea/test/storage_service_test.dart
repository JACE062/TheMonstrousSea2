import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';

void main() {
  group('StorageService Tests', () {
    late Directory tempDir;
    late StorageService storage;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('monstrous_sea_storage_test_');
      storage = StorageService(baseDirectory: tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('loadProfile returns empty profile when no file exists', () async {
      final profile = await storage.loadProfile();
      expect(profile.metaInventory.isEmpty, isTrue);
      expect(profile.activeNemesis, isNull);
      expect(profile.lineageTracker.captainsLost, 0);
    });

    test('saveProfile persists profile data and loadProfile recovers it', () async {
      final profile = ProfileData();
      profile.metaInventory.add(
        seaGlass: 15,
        monsterBone: 8,
        depthWroughtIron: 3,
        abyssalBarnacles: 2,
      );

      final rng = SeededGameRng(42);
      final killer = createMonster(MonsterSpecies.shark, level: 3, rng: rng);
      final nemesis = NemesisRecord.createFromDefeat(
        killer: killer,
        captainName: 'Captain Jonathan',
        regionIndex: 1,
        rng: rng,
      );
      profile.activeNemesis = nemesis;
      profile.lineageTracker.recordDeath(const CaptainRecord(
        captainName: 'Captain Jonathan',
        shipName: 'The Dauntless',
        shipClass: ShipClass.standard,
        monstersDefeated: 5,
        highestDifficultyReached: 3,
        causeOfDeath: 'Apex Shark',
      ));

      await storage.saveProfile(profile);

      final loaded = await storage.loadProfile();
      expect(loaded.metaInventory.seaGlass, 15);
      expect(loaded.metaInventory.monsterBone, 8);
      expect(loaded.metaInventory.depthWroughtIron, 3);
      expect(loaded.metaInventory.abyssalBarnacles, 2);
      expect(loaded.activeNemesis, isNotNull);
      expect(loaded.activeNemesis!.predecessorCaptain, 'Captain Jonathan');
      expect(loaded.activeNemesis!.moniker, contains('Jonathan'));
      expect(loaded.lineageTracker.captainsLost, 1);
    });

    test('Voyage save lifecycle: save, detect, load, and clear', () async {
      expect(await storage.hasActiveVoyage(), isFalse);
      expect(await storage.loadVoyage(), isNull);

      final rng = SeededGameRng(42);
      final ship = createShip(ShipClass.ironclad, level: 2, rng: rng);
      final voyage = VoyageSaveData(
        captainName: 'Captain Cordelia',
        ship: ship,
        regionIndex: 1,
        currentRow: 2,
        currentCol: 3,
        timesCompleted: 1,
        activeBoonId: BloodlineTraitId.veteranCannoneer,
        activeQuirkId: BloodlineTraitId.bloodOath,
        phase: SessionPhase.restArea,
      );

      await storage.saveVoyage(voyage);

      expect(await storage.hasActiveVoyage(), isTrue);

      final loaded = await storage.loadVoyage();
      expect(loaded, isNotNull);
      expect(loaded!.captainName, 'Captain Cordelia');
      expect(loaded.ship.shipClass, ShipClass.ironclad);
      expect(loaded.regionIndex, 1);
      expect(loaded.currentRow, 2);
      expect(loaded.currentCol, 3);
      expect(loaded.activeBoonId, BloodlineTraitId.veteranCannoneer);
      expect(loaded.activeQuirkId, BloodlineTraitId.bloodOath);
      expect(loaded.phase, SessionPhase.restArea);

      // Clearing voyage deletes file (anti-scumming)
      final cleared = await storage.clearVoyage();
      expect(cleared, isTrue);
      expect(await storage.hasActiveVoyage(), isFalse);
      expect(await storage.loadVoyage(), isNull);
    });
  });
}
