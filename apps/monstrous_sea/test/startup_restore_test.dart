import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/captain_screen.dart';
import 'package:monstrous_sea/src/screens/intro_screen.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

class _StartupStorage extends StorageService {
  _StartupStorage(this.profileFuture, {this.voyage});
  Future<ProfileData> profileFuture;
  final VoyageSaveData? voyage;
  @override
  Future<ProfileData> loadProfile() => profileFuture;
  @override
  Future<VoyageSaveData?> loadVoyage() async => voyage;
}

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);

  testWidgets(
    'failed save initialization offers retry without starting a fresh voyage',
    (tester) async {
      final profileReady = Completer<ProfileData>();
      final storage = _StartupStorage(profileReady.future);
      final controller = GameController(storage: storage, autoSave: false);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: GameOrchestratorView(controller: controller, loadStorage: true),
        ),
      );
      profileReady.completeError(
        const FileSystemException('Import interrupted'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load your saved progress.'), findsOneWidget);
      expect(find.byType(CaptainScreen), findsNothing);
      expect(find.byType(IntroScreen), findsNothing);
      storage.profileFuture = Future.value(
        ProfileData(hasBegunFirstVoyage: true),
      );
      await tester.tap(find.text('RETRY'));
      await tester.pumpAndSettle();
      expect(find.byType(CaptainScreen), findsOneWidget);
      expect(find.byType(IntroScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Startup waits for profile and restores saved chart progress instead of showing first-run menus',
    (tester) async {
      final saved = GameSession(rng: SeededGameRng(42))
        ..dispatch(const NameCaptain('Returning Captain'))
        ..dispatch(const ChooseShip(ShipClass.standard))
        ..dispatch(const VentureOutToSea());
      saved.phase = SessionPhase.restArea;
      saved.seaChart.currentLeg = 2;
      final profileReady = Completer<ProfileData>();
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(5)),
        autoSave: false,
        storage: _StartupStorage(
          profileReady.future,
          voyage: VoyageSaveData.fromSession(saved),
        ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: GameOrchestratorView(controller: controller, loadStorage: true),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CaptainScreen), findsNothing);
      profileReady.complete(ProfileData(hasBegunFirstVoyage: true));
      await tester.pumpAndSettle();
      expect(find.byType(HelmScreen), findsOneWidget);
      expect(controller.captainName, 'Returning Captain');
      expect(controller.seaChart.currentLeg, 2);
      expect(find.byType(IntroScreen), findsNothing);
    },
  );

  testWidgets(
    'Returning profile keeps earned blueprints and bypasses first-voyage prologue',
    (tester) async {
      final controller = GameController(
        autoSave: false,
        storage: _StartupStorage(
          Future.value(
            ProfileData(
              hasBegunFirstVoyage: true,
              unlockedBlueprints: {'standard', 'ironclad'},
              activeBlueprintId: 'ironclad',
            ),
          ),
        ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: GameOrchestratorView(controller: controller, loadStorage: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CaptainScreen), findsOneWidget);
      expect(find.byType(IntroScreen), findsNothing);
      expect(find.text('TAKE COMMAND'), findsOneWidget);
      expect(
        controller.profile.isBlueprintUnlocked(BlueprintId.ironclad),
        isTrue,
      );
    },
  );
}
