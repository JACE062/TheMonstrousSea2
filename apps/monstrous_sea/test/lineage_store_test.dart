import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/services/lineage_store.dart';
import 'package:monstrous_sea/src/services/caldera_snapshot.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';

void main() {
  late Directory root;
  late StorageService original;
  late LineageStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('sea-lineage-');
    original = StorageService(baseDirectory: root);
    store = LineageStore(rootStorage: original);
  });
  tearDown(() => root.delete(recursive: true));

  File rootFile(String name) => File('${root.path}/$name');
  File slotFile(String id, String name) =>
      File('${root.path}/lineages/$id/$name');
  GameSession voyage() => GameSession(rng: SeededGameRng(42))
    ..dispatch(const NameCaptain('Original Captain'))
    ..dispatch(const ChooseShip(ShipClass.standard));

  Future<GameController> loadController(String id) async {
    final controller = GameController(
      storage: await store.open(id),
      autoSave: false,
      retainPreparationCheckpoints: true,
    );
    addTearDown(controller.dispose);
    await controller.initializeStorage();
    return controller;
  }

  Future<LineageSlot> completedWithSnapshot() async {
    final slot = await store.create('Peaceful lineage');
    final controller = await loadController(slot.id);
    controller.session.dispatch(const BeginFirstVoyage('Mara Thorne'));
    controller.profile.metaInventory.add(leviathanCore: 1, seaGlass: 23);
    controller.session.phase = SessionPhase.expeditionVictory;
    await controller.persistState();
    controller.dispatch(
      const ResolveCalderaClimax(CalderaClimaxChoice.shatterCore),
    );
    controller.dispatch(const AcknowledgeCalderaOutcome());
    await controller.persistState();
    return slot;
  }

  test('alternate copies pre-choice progress and keeps the completed source byte-for-byte', () async {
    final source = await completedWithSnapshot();
    final sourceProfile = await slotFile(
      source.id,
      StorageService.profileFileName,
    ).readAsString();
    final sourceVoyage = await slotFile(
      source.id,
      StorageService.voyageFileName,
    ).readAsString();
    final before = await (await store.open(source.id)).loadCalderaSnapshot();
    final alternate = await store.exploreOtherFate(source.id);
    expect(alternate.alternateOf, source.id);
    final branch = await loadController(alternate.id);
    expect(branch.phase, SessionPhase.expeditionVictory);
    expect(branch.profile.toJson(), before!.profile.toJson());
    expect(
      VoyageSaveData.fromSession(branch.session).toJson(),
      before.voyage.toJson(),
    );
    expect(branch.profile.hasShatteredFont, isFalse);
    expect(branch.profile.metaInventory.leviathanCore, 1);
    branch.dispatch(const ResolveCalderaClimax(CalderaClimaxChoice.claimCore));
    branch.dispatch(const AcknowledgeCalderaOutcome());
    branch.profile.metaInventory.add(seaGlass: 8);
    await branch.persistState();
    final repeat = await Future.wait(
      List.generate(3, (_) => store.exploreOtherFate(source.id)),
    );
    expect(repeat.map((s) => s.id).toSet(), {alternate.id});
    final resumed = await loadController(alternate.id);
    expect(resumed.phase, SessionPhase.death);
    expect(resumed.profile.ascensionLoopCount, 1);
    expect(resumed.profile.metaInventory.seaGlass, 31);
    expect(resumed.profile.hasUnlockedCovenant, isTrue);
    expect(resumed.profile.metaInventory.leviathanCore, 1);
    expect(
      resumed.pendingHeirCandidates.map((h) => h.toJson()),
      branch.pendingHeirCandidates.map((h) => h.toJson()),
    );
    expect((await store.load()).slots, hasLength(2));
    expect(
      await slotFile(source.id, StorageService.profileFileName).readAsString(),
      sourceProfile,
    );
    expect(
      await slotFile(source.id, StorageService.voyageFileName).readAsString(),
      sourceVoyage,
    );
    await expectLater(
      store.exploreOtherFate(alternate.id),
      throwsArgumentError,
    );
  });

  test(
    'a damaged published alternate is never replaced with a fresh branch',
    () async {
      final source = await completedWithSnapshot();
      final alternate = await store.exploreOtherFate(source.id);
      final damaged = slotFile(alternate.id, StorageService.profileFileName);
      await damaged.writeAsString('{damaged existing progression');
      await expectLater(
        store.exploreOtherFate(source.id),
        throwsFormatException,
      );
      expect(await damaged.readAsString(), '{damaged existing progression');
      expect((await store.load()).slots, hasLength(2));
      expect((await loadController(source.id)).phase, SessionPhase.ended);
    },
  );

  test('branch publication failure retries without exposing or duplicating staged data', () async {
    final source = await completedWithSnapshot();
    final pending = Directory(
      '${root.path}/${LineageStore.catalogName}.pending',
    );
    await pending.create();
    await expectLater(
      store.exploreOtherFate(source.id),
      throwsA(isA<FileSystemException>()),
    );
    expect((await store.load()).slots, hasLength(1));
    await pending.delete();
    final branch = await store.exploreOtherFate(source.id);
    expect((await store.load()).slots, hasLength(2));
    expect(
      (await loadController(branch.id)).phase,
      SessionPhase.expeditionVictory,
    );
  });

  test('missing or damaged snapshots leave legacy endings readable without fabricating a branch', () async {
    final source = await completedWithSnapshot();
    final file = slotFile(source.id, StorageService.calderaSnapshotFileName);
    for (final contents in [
      null,
      '{broken',
      jsonEncode({'version': 99}),
    ]) {
      if (contents == null) {
        await file.delete();
      } else {
        await file.writeAsString(contents);
      }
      final summary = (await store.summaries()).single;
      expect(summary.readable, isTrue);
      expect(summary.canExploreOtherFate, isFalse);
      await expectLater(store.exploreOtherFate(source.id), throwsA(anything));
      expect((await store.load()).slots, hasLength(1));
      expect((await loadController(source.id)).phase, SessionPhase.ended);
    }
  });

  test(
    'uncompleted and already resolved snapshots cannot be used for branching',
    () async {
      final slot = await store.create('Unfinished');
      await expectLater(store.exploreOtherFate(slot.id), throwsStateError);
      final session = voyage()..phase = SessionPhase.expeditionVictory;
      final snapshot = CalderaSnapshot.fromSession(session).toJson();
      for (final phase in ['ended', 'death', 'port']) {
        final changed =
            jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
        (changed['voyage'] as Map)['phase'] = phase;
        expect(() => CalderaSnapshot.fromJson(changed), throwsFormatException);
      }
      (snapshot['profile'] as Map)['hasShatteredFont'] = true;
      expect(() => CalderaSnapshot.fromJson(snapshot), throwsFormatException);
    },
  );

  test(
    'empty root creates no fabricated lineage; labels never become paths',
    () async {
      expect((await store.load()).slots, isEmpty);
      final slot = await store.create('../../My save');
      expect(slot.id, isNot(contains('My save')));
      expect(slot.label, '../../My save');
      final controller = await loadController(slot.id);
      expect(controller.profile.unlockedBlueprints, {'standard'});
      expect(controller.profile.hasBegunFirstVoyage, isFalse);
      expect((await store.load()).activeId, slot.id);
      expect(await rootFile(StorageService.profileFileName).exists(), isFalse);
    },
  );

  test(
    'single save migrates byte-for-byte once and originals remain backups',
    () async {
      final session = voyage()..phase = SessionPhase.helm;
      session.profile.metaInventory.add(seaGlass: 15);
      session.ship!.gold = 123;
      await original.saveProfile(session.profile);
      await original.saveVoyage(VoyageSaveData.fromSession(session));
      final sourceProfile = await rootFile(StorageService.profileFileName)
          .readAsBytes();
      final sourceVoyage = await rootFile(StorageService.voyageFileName)
          .readAsBytes();
      final catalog = await store.load();
      expect(catalog.slots.single.label, 'Original Lineage');
      expect(
        await slotFile(
          'original',
          StorageService.profileFileName,
        ).readAsBytes(),
        sourceProfile,
      );
      expect(
        await slotFile('original', StorageService.voyageFileName).readAsBytes(),
        sourceVoyage,
      );
      final restored = await loadController('original');
      expect(restored.ship!.gold, 123);
      expect(restored.captainName, 'Original Captain');
      restored.profile.metaInventory.add(monsterBone: 7);
      await restored.persistState();
      // A new store instance must trust the catalog/slot, never overwrite it.
      store = LineageStore(rootStorage: original);
      expect((await store.load()).slots, hasLength(1));
      expect(
        (await loadController('original')).profile.metaInventory.monsterBone,
        7,
      );
      expect(
        await rootFile(StorageService.profileFileName).readAsBytes(),
        sourceProfile,
      );
      expect(
        await rootFile(StorageService.voyageFileName).readAsBytes(),
        sourceVoyage,
      );
    },
  );

  test(
    'Documents import completes before creating the original lineage',
    () async {
      final legacy = Directory('${root.path}/Documents');
      final source = StorageService(baseDirectory: legacy);
      await source.saveProfile(ProfileData()..metaInventory.add(seaGlass: 9));
      final destination = Directory('${root.path}/Saves');
      store = LineageStore(
        rootStorage: StorageService(
          baseDirectory: destination,
          legacyDirectory: legacy,
        ),
      );
      expect((await store.load()).slots.single.id, 'original');
      expect(
        (await loadController('original')).profile.metaInventory.seaGlass,
        9,
      );
      expect(
        await File('${legacy.path}/${StorageService.profileFileName}').exists(),
        isTrue,
      );
    },
  );

  test(
    'separate slots retain independent unlocks, gold and completed endings',
    () async {
      final first = await store.create('Finished family');
      final firstController = await loadController(first.id);
      firstController.dispatch(const NameCaptain('Mara'));
      firstController.dispatch(const ChooseShip(ShipClass.standard));
      firstController.profile.unlockedBlueprints.add('ironclad');
      firstController.profile.metaInventory.add(seaGlass: 40, leviathanCore: 1);
      firstController.session.phase = SessionPhase.expeditionVictory;
      firstController.dispatch(
        const ResolveCalderaClimax(CalderaClimaxChoice.shatterCore),
      );
      firstController.dispatch(const AcknowledgeCalderaOutcome());
      await firstController.persistState();
      final second = await store.create('Another family');
      final fresh = await loadController(second.id);
      expect(fresh.profile.unlockedBlueprints, {'standard'});
      expect(fresh.profile.hasShatteredFont, isFalse);
      expect(fresh.profile.metaInventory.seaGlass, 0);
      expect(fresh.lineage.history, isEmpty);
      final completed = await loadController(first.id);
      expect(completed.phase, SessionPhase.ended);
      expect(completed.session.hasReadCalderaOutcome, isTrue);
      expect(completed.profile.metaInventory.seaGlass, 40);
      expect(completed.profile.unlockedBlueprints, contains('ironclad'));
    },
  );

  test(
    'home preparation and ordinary heir offers survive switching/restart',
    () async {
      final slot = await store.create('Preparation');
      final controller = await loadController(slot.id);
      controller.dispatch(const NameCaptain('Existing captain'));
      controller.dispatch(const ChooseShip(ShipClass.standard));
      controller.ship!.gold = 98;
      await controller.persistState();
      final home = await loadController(slot.id);
      expect(home.phase, SessionPhase.port);
      expect(home.captainName, 'Existing captain');
      expect(home.ship!.gold, 98);
      home.session.phase = SessionPhase.death;
      home.session.pendingHeirCandidates = generateHeirCandidates(
        rng: home.session.rng,
        previousCaptainName: 'Mara Thorne',
      );
      final offers = home.pendingHeirCandidates.map((h) => h.toJson()).toList();
      await home.persistState();
      final heirSelection = await loadController(slot.id);
      expect(heirSelection.phase, SessionPhase.death);
      expect(
        heirSelection.pendingHeirCandidates.map((h) => h.toJson()).toList(),
        offers,
      );
    },
  );

  test(
    'failed catalog publication retries the same complete legacy import',
    () async {
      await original.saveProfile(voyage().profile);
      final source = await rootFile(StorageService.profileFileName)
          .readAsBytes();
      final blocker = Directory(
        '${root.path}/${LineageStore.catalogName}.pending',
      );
      await blocker.create();
      await expectLater(store.load(), throwsA(isA<FileSystemException>()));
      expect(await rootFile(LineageStore.catalogName).exists(), isFalse);
      expect(await rootFile('.lineages_import_pending').exists(), isTrue);
      await blocker.delete();
      expect((await store.load()).slots.single.id, 'original');
      expect(
        await slotFile(
          'original',
          StorageService.profileFileName,
        ).readAsBytes(),
        source,
      );
      expect(
        await rootFile(StorageService.profileFileName).readAsBytes(),
        source,
      );
    },
  );

  test('missing catalog cannot overwrite existing slotted saves from stale backups', () async {
    await original.saveProfile(voyage().profile);
    await store.load();
    final controller = await loadController('original');
    controller.profile.metaInventory.add(seaGlass: 17);
    await controller.persistState();
    final slotBytes = await slotFile(
      'original',
      StorageService.profileFileName,
    ).readAsBytes();
    await rootFile(LineageStore.catalogName).delete();
    await expectLater(store.load(), throwsFormatException);
    expect(
      await slotFile('original', StorageService.profileFileName).readAsBytes(),
      slotBytes,
    );
  });

  test(
    'unreadable slot is reported while another lineage remains usable',
    () async {
      final broken = await store.create('Broken save');
      final healthy = await store.create('Healthy save');
      await slotFile(
        broken.id,
        StorageService.profileFileName,
      ).writeAsString('{broken');
      final summaries = await store.summaries();
      expect(summaries.first.readable, isFalse);
      expect(summaries.last.readable, isTrue);
      await expectLater(store.open(broken.id), throwsFormatException);
      expect(
        (await loadController(healthy.id)).profile.hasBegunFirstVoyage,
        isFalse,
      );
      expect(
        await slotFile(
          broken.id,
          StorageService.profileFileName,
        ).readAsString(),
        '{broken',
      );
    },
  );

  test(
    'broken voyage and missing profile are never silently replaced',
    () async {
      final slot = await store.create('Damaged voyage');
      await slotFile(
        slot.id,
        StorageService.voyageFileName,
      ).writeAsString('{broken');
      await expectLater(store.open(slot.id), throwsFormatException);
      await slotFile(slot.id, StorageService.profileFileName).delete();
      expect((await store.summaries()).single.readable, isFalse);
      await expectLater(
        store.open(slot.id),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test('invalid catalog identities and unknown selections cannot escape the save root', () async {
    for (final id in ['../escape', 'original/../../escape', '', 'DUPLICATE']) {
      await rootFile(LineageStore.catalogName).writeAsString(
        jsonEncode({
          'version': 1,
          'slots': [
            {'id': id, 'label': 'Bad entry'},
          ],
          'activeId': id,
        }),
      );
      await expectLater(store.load(), throwsFormatException);
    }
    await rootFile(LineageStore.catalogName).writeAsString('{broken');
    await expectLater(store.load(), throwsFormatException);
  });

  test(
    'concurrent creation is serialized and labels/IDs do not merge lineages',
    () async {
      final slots = await Future.wait(
        List.generate(4, (_) => store.create('Same label')),
      );
      expect(slots.map((s) => s.id).toSet(), hasLength(4));
      expect((await store.load()).slots, hasLength(4));
      await expectLater(store.open('../outside'), throwsArgumentError);
      await expectLater(store.create('   '), throwsArgumentError);
      await expectLater(store.create('x' * 61), throwsArgumentError);
    },
  );
}
