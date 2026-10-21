import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';

void main() {
  test(
    'suite redirects a forgotten default autosave away from production',
    () async {
      final storage = StorageService();
      expect(
        storage.baseDirectory,
        isNotNull,
        reason: 'flutter_test_config must isolate default storage',
      );
      final production = await StorageService.defaultSaveDirectory();
      expect(
        storage.baseDirectory!.absolute.path,
        isNot(production.absolute.path),
      );

      // Reproduce the old art-fixture pattern safely: default autosave and a
      // fixture-only unlock that bypasses the purchase. It really reaches disk,
      // but the suite guard must keep that data in the disposable test root.
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
      );
      addTearDown(controller.dispose);
      controller.dispatch(const NameCaptain('Art fixture'));
      controller.profile.unlockedBlueprints.add(BlueprintId.ironclad.name);
      controller.dispatch(const ChooseShip(ShipClass.ironclad));
      await controller.persistState();
      expect(
        controller.storage.baseDirectory!.path,
        storage.baseDirectory!.path,
      );
      final saved = await storage.loadProfile();
      expect(saved.isBlueprintUnlocked(BlueprintId.ironclad), isTrue);
      expect(saved.metaInventory.isEmpty, isTrue);
      expect(
        await File('${storage.baseDirectory!.path}/player_profile.json')
            .exists(),
        isTrue,
      );
      expect(
        await File('${storage.baseDirectory!.path}/.legacy_migration_complete')
            .exists(),
        isFalse,
      );
    },
  );

  test(
    'nested async isolation is scoped and explicit directories take priority',
    () async {
      final outer = StorageService().baseDirectory!;
      final nested = await Directory.systemTemp.createTemp(
        'monstrous-nested-root-',
      );
      final explicit = await Directory.systemTemp.createTemp(
        'monstrous-explicit-root-',
      );
      addTearDown(() => nested.delete(recursive: true));
      addTearDown(() => explicit.delete(recursive: true));
      await StorageService.withIsolatedStorage(nested, () async {
        await Future<void>.delayed(Duration.zero);
        expect(StorageService().baseDirectory!.path, nested.path);
        final service = StorageService(baseDirectory: explicit);
        await service.saveProfile(ProfileData());
        expect(
          await File('${explicit.path}/player_profile.json').exists(),
          isTrue,
        );
        expect(
          await File('${nested.path}/player_profile.json').exists(),
          isFalse,
        );
      });
      expect(StorageService().baseDirectory!.path, outer.path);
    },
  );
}
