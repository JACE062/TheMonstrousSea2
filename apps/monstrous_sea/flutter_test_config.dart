import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';

/// Every test file gets a disposable default save root. Even a fixture that
/// forgets to disable autosave must never reach the player's real save files.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Directory? directory;
  final previous = StorageService.testDefaultDirectory;
  // Test bodies run in runner-owned zones after main has registered them.
  // Install the fallback for the suite's actual lifetime, not just main().
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('monstrous-test-root-');
    StorageService.testDefaultDirectory = directory;
  });
  tearDownAll(() async {
    StorageService.testDefaultDirectory = previous;
    final root = directory;
    if (root != null && await root.exists()) await root.delete(recursive: true);
  });
  await testMain();
}
