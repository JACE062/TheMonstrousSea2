import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';

File fileIn(Directory directory, String name) =>
    File('${directory.path}${Platform.pathSeparator}$name');

void main() {
  late Directory sandbox;
  late Directory legacy;
  late Directory destination;
  late StorageService oldStorage;

  StorageService migratingStorage() =>
      StorageService(baseDirectory: destination, legacyDirectory: legacy);

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('sea2_migration_test_');
    legacy = Directory('${sandbox.path}/Documents');
    destination = Directory('${sandbox.path}/TheMonstrousSea2/Saves');
    oldStorage = StorageService(baseDirectory: legacy);
  });

  tearDown(() async => sandbox.delete(recursive: true));

  Future<void> saveLegacyPair() async {
    final session = GameSession(rng: SeededGameRng(42))
      ..dispatch(const BeginFirstVoyage('Returning Captain'));
    session.phase = SessionPhase.restArea;
    session.profile.metaInventory.add(seaGlass: 15, monsterBone: 8);
    await oldStorage.saveProfile(session.profile);
    await oldStorage.saveVoyage(VoyageSaveData.fromSession(session));
  }

  test(
    'Windows saves live in LocalAppData under the requested sequel name',
    () async {
      final directory = await StorageService.defaultSaveDirectory();
      expect(
        directory.path,
        '${Platform.environment['LOCALAPPDATA']}\\TheMonstrousSea2\\Saves',
      );
    },
    skip: !Platform.isWindows,
  );

  test(
    'imports the complete legacy pair byte-for-byte and restores progress',
    () async {
      await saveLegacyPair();
      final controller = GameController(
        storage: migratingStorage(),
        autoSave: false,
      );
      addTearDown(controller.dispose);
      await controller.initializeStorage();
      expect(controller.profile.metaInventory.seaGlass, 15);
      expect(controller.profile.metaInventory.monsterBone, 8);
      expect(controller.captainName, 'Returning Captain');
      expect(controller.phase, SessionPhase.helm);
      expect(controller.seaChart.currentLeg, 1);
      for (final name in [
        StorageService.profileFileName,
        StorageService.voyageFileName,
      ]) {
        expect(
          await fileIn(destination, name).readAsBytes(),
          await fileIn(legacy, name).readAsBytes(),
        );
      }
    },
  );

  test('parallel first loads share one import and subsequent saves use only the new location', () async {
    await saveLegacyPair();
    final storage = migratingStorage();
    final oldProfile = await fileIn(
      legacy,
      StorageService.profileFileName,
    ).readAsBytes();
    final oldVoyage = await fileIn(
      legacy,
      StorageService.voyageFileName,
    ).readAsBytes();
    final loaded = await Future.wait<Object?>([
      storage.loadProfile(),
      storage.loadVoyage(),
    ]);
    expect((loaded[0] as ProfileData).metaInventory.seaGlass, 15);
    expect((loaded[1] as VoyageSaveData).captainName, 'Returning Captain');
    await storage.saveProfile(ProfileData());
    await storage.clearVoyage();
    expect(
      await fileIn(legacy, StorageService.profileFileName).readAsBytes(),
      oldProfile,
    );
    expect(
      await fileIn(legacy, StorageService.voyageFileName).readAsBytes(),
      oldVoyage,
    );
    expect(
      (await migratingStorage().loadProfile()).metaInventory.isEmpty,
      isTrue,
    );
    expect(await migratingStorage().loadVoyage(), isNull);
  });

  test(
    'cleared voyages and deliberate save resets do not resurrect legacy files',
    () async {
      await saveLegacyPair();
      final storage = migratingStorage();
      await storage.loadProfile();
      await storage.clearVoyage();
      expect(await migratingStorage().loadVoyage(), isNull);
      await fileIn(destination, StorageService.profileFileName).delete();
      expect(
        (await migratingStorage().loadProfile()).hasBegunFirstVoyage,
        isFalse,
      );
      expect(await migratingStorage().hasActiveVoyage(), isFalse);
    },
  );

  test('a newer profile prevents importing a stale legacy voyage', () async {
    await saveLegacyPair();
    final newStorage = StorageService(baseDirectory: destination);
    await newStorage.saveProfile(
      ProfileData()..metaInventory.add(seaGlass: 99),
    );
    final storage = migratingStorage();
    expect((await storage.loadProfile()).metaInventory.seaGlass, 99);
    expect(await storage.loadVoyage(), isNull);
    expect(await oldStorage.hasActiveVoyage(), isTrue);
  });

  test(
    'an existing new voyage is never paired with a legacy profile',
    () async {
      await saveLegacyPair();
      await StorageService(baseDirectory: destination)
          .saveVoyage((await oldStorage.loadVoyage())!);
      final storage = migratingStorage();
      expect((await storage.loadProfile()).hasBegunFirstVoyage, isFalse);
      expect((await storage.loadVoyage())!.captainName, 'Returning Captain');
    },
  );

  test(
    'a legacy profile without a voyage migrates without inventing a checkpoint',
    () async {
      await oldStorage.saveProfile(
        ProfileData()..metaInventory.add(monsterBone: 7),
      );
      final storage = migratingStorage();
      expect((await storage.loadProfile()).metaInventory.monsterBone, 7);
      expect(await storage.loadVoyage(), isNull);
    },
  );

  test(
    'a fresh installation does not import legacy files added later',
    () async {
      expect(
        (await migratingStorage().loadProfile()).hasBegunFirstVoyage,
        isFalse,
      );
      await saveLegacyPair();
      expect(
        (await migratingStorage().loadProfile()).hasBegunFirstVoyage,
        isFalse,
      );
      expect(await migratingStorage().loadVoyage(), isNull);
    },
  );

  test('a failed partial import blocks loading and can resume on retry', () async {
    await saveLegacyPair();
    // A directory occupying the voyage filename makes that copy fail after
    // the profile has been copied, reproducing an interrupted two-file import.
    final obstruction = Directory(
      fileIn(destination, StorageService.voyageFileName).path,
    );
    await obstruction.create(recursive: true);
    final storage = migratingStorage();
    await expectLater(
      storage.loadProfile(),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      await fileIn(destination, StorageService.profileFileName).exists(),
      isTrue,
    );
    expect((await oldStorage.loadProfile()).metaInventory.seaGlass, 15);
    await obstruction.delete();
    expect((await storage.loadProfile()).metaInventory.seaGlass, 15);
    expect((await storage.loadVoyage())!.captainName, 'Returning Captain');
    await storage.clearVoyage();
    expect(await migratingStorage().loadVoyage(), isNull);
  });
}
