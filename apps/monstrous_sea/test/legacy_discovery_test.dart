import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';

void main() {
  test(
    'failed Documents discovery cannot fall back to shared temporary saves',
    () async {
      final found = await StorageService.findLegacyDocumentsDirectory(
        documentsDirectory: () async =>
            throw const FileSystemException('Documents unavailable'),
      );
      expect(found, isNull);
    },
  );
  test('automatic discovery requires a Documents save; explicit restoration remains intact', () async {
    final root = await Directory.systemTemp.createTemp('sea-discovery-');
    addTearDown(() => root.delete(recursive: true));
    final documents = Directory('${root.path}/Documents')..createSync();
    expect(
      await StorageService.findLegacyDocumentsDirectory(
        documentsDirectory: () async => documents,
      ),
      isNull,
    );
    final source = StorageService(baseDirectory: documents);
    final owned = ProfileData(
      unlockedBlueprints: {'standard', 'ironclad'},
      hasBegunFirstVoyage: true,
    );
    await source.saveProfile(owned);
    expect(
      (await StorageService.findLegacyDocumentsDirectory(
        documentsDirectory: () async => documents,
      ))!.path,
      documents.path,
    );
    final restored = StorageService(
      baseDirectory: Directory('${root.path}/destination'),
      legacyDirectory: documents,
    );
    expect(
      (await restored.loadProfile()).isBlueprintUnlocked(BlueprintId.ironclad),
      isTrue,
    );
    expect(
      await File('${documents.path}/player_profile.json').readAsBytes(),
      await File('${root.path}/destination/player_profile.json').readAsBytes(),
    );
  });
}
