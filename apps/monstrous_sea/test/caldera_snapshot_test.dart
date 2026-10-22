import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/services/caldera_snapshot.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';

class FailingSnapshotStorage extends StorageService {
  FailingSnapshotStorage(Directory directory)
    : super(baseDirectory: directory, strictReads: true);
  bool fail = true;
  @override
  Future<void> saveCalderaSnapshot(CalderaSnapshot snapshot) async {
    if (fail) throw const FileSystemException('Fixture snapshot failure');
    return super.saveCalderaSnapshot(snapshot);
  }
}

GameSession atCaldera() => GameSession(rng: SeededGameRng(42))
  ..dispatch(const BeginFirstVoyage('Mara Thorne'))
  ..profile.metaInventory.add(leviathanCore: 1, seaGlass: 12)
  ..phase = SessionPhase.expeditionVictory;

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('sea-fate-snapshot-'),
  );
  tearDown(() => root.delete(recursive: true));

  test(
    'loaded choice captures before mutation even when immediately resolved',
    () async {
      final storage = StorageService(baseDirectory: root, strictReads: true);
      final session = atCaldera();
      await storage.saveProfile(session.profile);
      await storage.saveVoyage(VoyageSaveData.fromSession(session));
      final controller = GameController(storage: storage);
      addTearDown(controller.dispose);
      await controller.initializeStorage();
      controller.dispatch(
        const ResolveCalderaClimax(CalderaClimaxChoice.claimCore),
      );
      await controller.persistState();
      final snapshot = (await storage.loadCalderaSnapshot())!;
      expect(snapshot.profile.hasUnlockedCovenant, isFalse);
      expect(snapshot.profile.ascensionLoopCount, 0);
      expect(snapshot.profile.metaInventory.leviathanCore, 1);
      expect(snapshot.voyage.calderaOutcome, isNull);
      expect((await storage.loadProfile()).ascensionLoopCount, 1);
      final savedJson = snapshot.toJson();
      controller.profile.metaInventory.add(seaGlass: 20);
      await controller.persistState();
      expect((await storage.loadCalderaSnapshot())!.toJson(), savedJson);
    },
  );

  test('snapshot failure prevents publishing ending; retry retains exact pre-choice state', () async {
    final storage = FailingSnapshotStorage(root);
    final controller = GameController(session: atCaldera(), storage: storage);
    addTearDown(controller.dispose);
    controller.dispatch(
      const ResolveCalderaClimax(CalderaClimaxChoice.shatterCore),
    );
    await expectLater(
      controller.persistState(),
      throwsA(isA<FileSystemException>()),
    );
    expect((await storage.loadProfile()).hasShatteredFont, isFalse);
    expect(await storage.loadVoyage(), isNull);
    storage.fail = false;
    await controller.persistState();
    expect((await storage.loadProfile()).hasShatteredFont, isTrue);
    expect(
      (await storage.loadCalderaSnapshot())!
          .profile
          .metaInventory
          .leviathanCore,
      1,
    );
  });

  test('a later voyage replaces the snapshot without undoing earlier Covenant progress', () async {
    final storage = StorageService(baseDirectory: root, strictReads: true);
    final controller = GameController(session: atCaldera(), storage: storage);
    addTearDown(controller.dispose);
    controller.dispatch(
      const ResolveCalderaClimax(CalderaClimaxChoice.claimCore),
    );
    await controller.persistState();
    controller.dispatch(const AcknowledgeCalderaOutcome());
    controller.dispatch(
      const ContinueLineage('Elin Thorne', ShipClass.standard),
    );
    // Stand in for the next voyage reaching its final, supported choice stop.
    controller.session.phase = SessionPhase.expeditionVictory;
    controller.profile.metaInventory.add(leviathanCore: 1, seaGlass: 5);
    await controller.persistState();
    controller.dispatch(
      const ResolveCalderaClimax(CalderaClimaxChoice.shatterCore),
    );
    await controller.persistState();
    final snapshot = (await storage.loadCalderaSnapshot())!;
    expect(snapshot.voyage.captainName, 'Elin Thorne');
    expect(snapshot.profile.hasShatteredFont, isFalse);
    expect(snapshot.profile.hasUnlockedCovenant, isTrue);
    expect(snapshot.profile.ascensionLoopCount, 1);
    expect(snapshot.profile.metaInventory.leviathanCore, 2);
    expect(snapshot.profile.metaInventory.seaGlass, 17);
  });

  test(
    'debug-style unsaved choices create no snapshot or progress files',
    () async {
      final controller = GameController(
        session: atCaldera(),
        storage: StorageService(baseDirectory: root),
        autoSave: false,
      );
      addTearDown(controller.dispose);
      controller.dispatch(
        const ResolveCalderaClimax(CalderaClimaxChoice.claimCore),
      );
      expect(await root.list().toList(), isEmpty);
    },
  );
}
