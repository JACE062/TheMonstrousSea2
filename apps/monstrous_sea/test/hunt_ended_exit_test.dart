import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppExitResponse, AppExitType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';

// Flutter's default test binding rejects required exit requests before reaching
// the platform channel. Record this boundary without closing the test runner.
class ExitTestBinding extends AutomatedTestWidgetsFlutterBinding {
  late Future<AppExitResponse> Function(AppExitType, int) onExit;

  @override
  Future<AppExitResponse> exitApplication(
    AppExitType type, [
    int exitCode = 0,
  ]) => onExit(type, exitCode);
}

// In-memory persistence with controllable writes; never reaches player files.
class EndingStorage extends StorageService {
  EndingStorage() : super(baseDirectory: Directory('unused-ending-fixture'));

  Completer<void>? writeGate;
  bool failVoyageWrite = false;
  int profileWrites = 0;
  int voyageWrites = 0;
  ProfileData? savedProfile;
  VoyageSaveData? savedVoyage;

  @override
  Future<void> saveProfile(ProfileData profile) async {
    profileWrites++;
    await writeGate?.future;
    savedProfile = ProfileData.fromJson(profile.toJson());
  }

  @override
  Future<void> saveVoyage(VoyageSaveData voyage) async {
    voyageWrites++;
    if (failVoyageWrite) {
      throw const FileSystemException('Fixture write failure');
    }
    savedVoyage = VoyageSaveData.fromJson(voyage.toJson());
  }

  @override
  Future<ProfileData> loadProfile() async =>
      ProfileData.fromJson(savedProfile!.toJson());

  @override
  Future<VoyageSaveData?> loadVoyage() async => savedVoyage == null
      ? null
      : VoyageSaveData.fromJson(savedVoyage!.toJson());

  @override
  Future<bool> clearVoyage() async {
    savedVoyage = null;
    return true;
  }
}

GameController completedHunt(EndingStorage storage, {bool autoSave = true}) {
  final session = GameSession(rng: SeededGameRng(42))
    ..dispatch(const BeginFirstVoyage('Mara Thorne'));
  session.profile.metaInventory.add(leviathanCore: 1);
  session.phase = SessionPhase.expeditionVictory;
  session.dispatch(const ResolveCalderaClimax(CalderaClimaxChoice.shatterCore));
  session.dispatch(const AcknowledgeCalderaOutcome());
  return GameController(session: session, storage: storage, autoSave: autoSave);
}

Future<void> showEnding(WidgetTester tester, GameController controller) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: InkTheme.themeData,
      home: GameOrchestratorView(controller: controller, skipIntro: true),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final binding = ExitTestBinding();
  setUpAll(() => InkTheme.disableGoogleFonts = true);

  testWidgets(
    'Exit waits for queued and final saves and ignores duplicate taps',
    (tester) async {
      final storage = EndingStorage()..writeGate = Completer<void>();
      final controller = completedHunt(storage);
      addTearDown(controller.dispose);
      var exitCalls = 0;
      binding.onExit = (type, exitCode) async {
        exitCalls++;
        expect(type, AppExitType.required);
        expect(exitCode, 0);
        expect(storage.profileWrites, 2);
        expect(storage.voyageWrites, 2);
        expect(storage.savedProfile!.hasShatteredFont, isTrue);
        expect(storage.savedVoyage!.hasReadCalderaOutcome, isTrue);
        return AppExitResponse.exit;
      };

      final pendingSave = controller.persistState();
      await showEnding(tester, controller);
      final button = tester.widget<InkButton>(find.byType(InkButton));
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      expect(find.text('EXITING…'), findsOneWidget);
      expect(
        tester.widget<InkButton>(find.byType(InkButton)).onPressed,
        isNull,
      );
      expect(exitCalls, 0);
      expect(storage.profileWrites, 1);

      storage.writeGate!.complete();
      await pendingSave;
      await tester.pumpAndSettle();
      expect(exitCalls, 1);
      final restored = GameController(storage: storage, autoSave: false);
      addTearDown(restored.dispose);
      await restored.initializeStorage();
      expect(restored.phase, SessionPhase.ended);
      expect(restored.session.calderaOutcome, CalderaClimaxChoice.shatterCore);
      expect(restored.session.hasReadCalderaOutcome, isTrue);
      expect(restored.profile.toJson(), controller.profile.toJson());
    },
  );

  testWidgets('Failed ending checkpoint keeps the game open and allows retry', (
    tester,
  ) async {
    final storage = EndingStorage()..failVoyageWrite = true;
    final controller = completedHunt(storage);
    addTearDown(controller.dispose);
    var exitCalls = 0;
    binding.onExit = (_, _) async {
      exitCalls++;
      return AppExitResponse.exit;
    };
    await showEnding(tester, controller);
    await tester.tap(find.text('EXIT GAME'));
    await tester.pumpAndSettle();
    expect(exitCalls, 0);
    expect(find.textContaining('could not be saved'), findsOneWidget);
    expect(find.text('EXIT GAME'), findsOneWidget);

    storage.failVoyageWrite = false;
    await tester.tap(find.text('EXIT GAME'));
    await tester.pumpAndSettle();
    expect(exitCalls, 1);
    expect(storage.voyageWrites, 2);
    expect(find.textContaining('could not be saved'), findsNothing);
  });

  for (final response in ['error', 'cancel', 'exit']) {
    testWidgets('Unsaved playtest exits without writes; platform $response', (
      tester,
    ) async {
      final storage = EndingStorage();
      final controller = completedHunt(storage, autoSave: false);
      addTearDown(controller.dispose);
      var exitCalls = 0;
      binding.onExit = (_, _) async {
        exitCalls++;
        if (response == 'error' && exitCalls == 1) {
          throw PlatformException(code: 'fixture');
        }
        return response == 'cancel' && exitCalls == 1
            ? AppExitResponse.cancel
            : AppExitResponse.exit;
      };
      await showEnding(tester, controller);
      await tester.tap(find.text('EXIT GAME'));
      await tester.pumpAndSettle();
      expect(exitCalls, 1);
      expect(storage.profileWrites, 0);
      expect(storage.voyageWrites, 0);
      if (response != 'exit') {
        expect(find.textContaining('could not close'), findsOneWidget);
        await tester.tap(find.text('EXIT GAME'));
        await tester.pumpAndSettle();
        expect(exitCalls, 2);
        expect(find.textContaining('could not close'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
