import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/caldera_outcome_screen.dart';
import 'package:monstrous_sea/src/screens/death_screen.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

const fontPath = String.fromEnvironment('endingFontPath');

GameController caldera({StorageService? storage}) {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    storage: storage,
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Mara Thorne'));
  controller.profile.metaInventory.add(leviathanCore: 1);
  controller.session.phase = SessionPhase.expeditionVictory;
  return controller;
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File('build/ending-$name.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (fontPath.isNotEmpty) {
      await (FontLoader('EndingReview')
            ..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });

  for (final choice in CalderaClimaxChoice.values) {
    for (final width in [360.0, 1280.0]) {
      for (final scale in [1.15, 1.3]) {
        testWidgets('$choice is read before continuation at $width / $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = caldera();
          addTearDown(controller.dispose);
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                theme: InkTheme.themeData.copyWith(
                  textTheme: InkTheme.themeData.textTheme.apply(
                    fontFamily: fontPath.isEmpty ? null : 'EndingReview',
                  ),
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: GameOrchestratorView(
                  controller: controller,
                  skipIntro: true,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final lore = EldritchLore.calderaClimax[choice]!;
          expect(find.text(lore.promptTitle), findsOneWidget);
          expect(find.text(lore.consequence), findsOneWidget);
          expect(find.text(lore.narrativeOutcome), findsNothing);
          final button = find.text(lore.displayName.toUpperCase());
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.byType(CalderaOutcomeScreen), findsOneWidget);
          expect(find.text(lore.narrativeOutcome), findsOneWidget);
          expect(find.byType(DeathScreen), findsNothing);
          if (fontPath.isNotEmpty && scale == 1.3) {
            await capture(
              tester,
              key,
              '${choice.name}-${width.toInt()}-outcome',
            );
          }
          final proceed = find.text(
            choice == CalderaClimaxChoice.claimCore
                ? 'CHOOSE AN HEIR'
                : 'THE HUNT IS ENDED',
          );
          await tester.ensureVisible(proceed);
          await tester.tap(proceed);
          await tester.pumpAndSettle();
          expect(controller.session.hasReadCalderaOutcome, isTrue);
          if (choice == CalderaClimaxChoice.claimCore) {
            expect(find.byType(DeathScreen), findsOneWidget);
            expect(
              find.text(EldritchLore.claimSuccessionTitle),
              findsOneWidget,
            );
            expect(find.text('ASCENDED INTO THE DEEP'), findsNothing);
          } else {
            expect(find.byType(HuntEndedScreen), findsOneWidget);
            expect(find.text(EldritchLore.huntEndedMessage), findsOneWidget);
            expect(find.text('START'), findsNothing);
            expect(find.text('EXIT GAME'), findsOneWidget);
            await tester.ensureVisible(find.text('EXIT GAME'));
            if (fontPath.isNotEmpty && scale == 1.3) {
              await capture(tester, key, '${width.toInt()}-completed');
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    test(
      '$choice survives disk restart before and after acknowledgement',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'monstrous-ending-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final storage = StorageService(baseDirectory: directory);
        final controller = caldera(storage: storage);
        addTearDown(controller.dispose);
        await controller.persistState();
        final beforeChoice = GameController(storage: storage, autoSave: false);
        addTearDown(beforeChoice.dispose);
        await beforeChoice.initializeStorage();
        expect(beforeChoice.phase, SessionPhase.expeditionVictory);
        beforeChoice.dispatch(ResolveCalderaClimax(choice));
        await beforeChoice.persistState();
        final restored = GameController(storage: storage, autoSave: false);
        addTearDown(restored.dispose);
        await restored.initializeStorage();
        expect(restored.session.calderaOutcome, choice);
        expect(restored.session.hasReadCalderaOutcome, isFalse);
        expect(
          restored.profile.ascensionLoopCount,
          choice == CalderaClimaxChoice.claimCore ? 1 : 0,
        );
        expect(
          restored.profile.metaInventory.leviathanCore,
          choice == CalderaClimaxChoice.claimCore ? 1 : 0,
        );
        final heirs = restored.pendingHeirCandidates
            .map((h) => h.toJson())
            .toList();
        restored.dispatch(const AcknowledgeCalderaOutcome());
        await restored.persistState();
        final acknowledged = GameController(storage: storage, autoSave: false);
        addTearDown(acknowledged.dispose);
        await acknowledged.initializeStorage();
        expect(acknowledged.session.hasReadCalderaOutcome, isTrue);
        expect(
          acknowledged.pendingHeirCandidates.map((h) => h.toJson()).toList(),
          heirs,
        );
        expect(
          acknowledged.profile.ascensionLoopCount,
          restored.profile.ascensionLoopCount,
        );
        if (choice == CalderaClimaxChoice.claimCore) {
          final heir = acknowledged.pendingHeirCandidates.first;
          acknowledged.dispatch(
            ContinueLineage(heir.defaultName, ShipClass.standard),
          );
          await acknowledged.persistState();
          expect(await storage.hasActiveVoyage(), isFalse);
          expect(acknowledged.session.calderaOutcome, isNull);
        }
      },
    );
  }

  test('older completed profile returns to a finished hunt without altering unlocks', () async {
    final directory = await Directory.systemTemp.createTemp('monstrous-ended-');
    addTearDown(() => directory.delete(recursive: true));
    final storage = StorageService(baseDirectory: directory);
    final profile = ProfileData(
      hasShatteredFont: true,
      hasUnlockedCovenant: true,
    );
    await storage.saveProfile(profile);
    final controller = GameController(storage: storage, autoSave: false);
    addTearDown(controller.dispose);
    await controller.initializeStorage();
    expect(controller.phase, SessionPhase.ended);
    expect(controller.profile.hasUnlockedCovenant, isTrue);
    expect(controller.session.calderaOutcome, isNull);
  });
}
