import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';

const _reviewFontPath = String.fromEnvironment('reviewFontPath');

GameController stormNavigator() {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Windreader'));
  controller.session.activeBoon = BloodlineTrait.stormSeer;
  controller.session.phase = SessionPhase.restArea;
  controller.session.currentMonster = null;
  controller.session.hasDefeatedCurrentEncounter = true;
  controller.dispatch(const TakeHelm());
  return controller;
}

Widget helm(GameController controller, {double scale = 1.15}) => MaterialApp(
  theme: InkTheme.themeData.copyWith(
    textTheme: InkTheme.themeData.textTheme.apply(
      fontFamily: _reviewFontPath.isEmpty ? null : 'TraitReview',
    ),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: HelmScreen(controller: controller, onOpenChart: () {}),
);

InkButton redrawButton(WidgetTester tester) =>
    tester.widget<InkButton>(find.byKey(const ValueKey('storm-seer-redraw')));

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (_reviewFontPath.isNotEmpty) {
      final loader = FontLoader('TraitReview')
        ..addFont(
          File(_reviewFontPath).readAsBytes().then(ByteData.sublistView),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets(
        'redraw is spent once and visibly explained at $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = stormNavigator();
          addTearDown(controller.dispose);
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: captureKey,
              child: helm(controller, scale: scale),
            ),
          );
          await tester.pumpAndSettle();
          final leg = controller.currentLeg;
          final history = controller.voyageLog.length;
          final staleAction = redrawButton(tester).onPressed!;
          await tester.ensureVisible(
            find.byKey(const ValueKey('storm-seer-redraw')),
          );
          if (_reviewFontPath.isNotEmpty) {
            await tester.ensureVisible(find.text('STORM-SEER'));
            await tester.pumpAndSettle();
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(captureKey),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                '.dart_tool/trait-review/helm-$width-$scale.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
            await tester.ensureVisible(
              find.byKey(const ValueKey('storm-seer-redraw')),
            );
          }
          await tester.tap(find.byKey(const ValueKey('storm-seer-redraw')));
          await tester.pump();
          expect(redrawButton(tester).onPressed, isNull);
          expect(
            find.text(controller.stormSeerRedrawRestriction!),
            findsOneWidget,
          );
          final offers = controller.seaChart.toJson()['courseOptions'];
          staleAction();
          expect(controller.seaChart.toJson()['courseOptions'], offers);
          expect(controller.currentLeg, leg);
          expect(controller.voyageLog.length, history);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('Overzealous accuracy tooltips at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = GameController(
          session: GameSession(rng: SeededGameRng(42)),
          autoSave: false,
        )..dispatch(const BeginFirstVoyage('Gunner'));
        addTearDown(controller.dispose);
        controller.session.currentMonster =
            createMonster(MonsterSpecies.shark, level: 1, rng: SeededGameRng(8))
              ..currentIntent = MonsterIntent.fromId(
                MonsterIntentId.sharkBreachingLunge,
              );
        final game = MonstrousSeaBattleGame(
          ship: controller.ship!,
          monster: controller.currentMonster!,
        );
        await tester.runAsync(() async {
          game.onGameResize(Vector2(width, 1000));
          // Load codecs outside the fake widget clock, as in art recovery tests.
          // ignore: invalid_use_of_internal_member
          await game.load();
        });
        Widget battle() => MaterialApp(
          theme: InkTheme.themeData,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: BattleScreen(controller: controller, game: game),
        );
        await tester.pumpWidget(battle());
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Tooltip &&
                w.message?.contains('Opening shot accuracy: 85%') == true,
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Tooltip &&
                w.message?.contains('Opening shot accuracy: 95%') == true,
          ),
          findsOneWidget,
        );
        controller.session.activeQuirk = BloodlineTrait.overzealousGunner;
        await tester.pumpWidget(battle());
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Tooltip &&
                w.message?.contains('Opening shot accuracy: 75%') == true,
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Tooltip &&
                w.message?.contains('Opening shot accuracy: 85%') == true,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final titan in [false, true]) {
    testWidgets(
      'convergent ${titan ? 'Titan' : 'Haven'} keeps redraw disabled',
      (tester) async {
        final controller = stormNavigator();
        addTearDown(controller.dispose);
        controller.seaChart.currentLeg =
            (titan ? controller.totalLegs : controller.midpointHavenLeg) - 1;
        controller.seaChart.clearPendingCourses();
        controller.seaChart.ensureCourseOptions(controller.session.rng);
        expect(controller.currentCourseOptions, hasLength(1));
        await tester.pumpWidget(helm(controller));
        await tester.pumpAndSettle();
        expect(redrawButton(tester).onPressed, isNull);
        expect(
          find.text(controller.stormSeerRedrawRestriction!),
          findsOneWidget,
        );
        expect(controller.stormSeerRedrawRegion, isNull);
      },
    );
  }

  testWidgets('redraw belongs only to Storm-Seer captains', (tester) async {
    final controller = stormNavigator();
    addTearDown(controller.dispose);
    controller.session.activeBoon = BloodlineTrait.veteranCannoneer;
    await tester.pumpWidget(helm(controller));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('storm-seer-redraw')), findsNothing);
  });

  testWidgets('Vendetta compulsion visibly disables the redraw', (
    tester,
  ) async {
    final controller = stormNavigator();
    addTearDown(controller.dispose);
    controller.session.activeQuirk = BloodlineTrait.bloodOath;
    final chart = controller.seaChart.toJson();
    final options = chart['courseOptions'] as List;
    (options.first as Map<String, dynamic>)['isNemesis'] = true;
    controller.seaChart.restoreFromJson(chart);
    await tester.pumpWidget(helm(controller));
    await tester.pumpAndSettle();
    expect(redrawButton(tester).onPressed, isNull);
    expect(find.text(controller.stormSeerRedrawRestriction!), findsOneWidget);
    expect(controller.stormSeerRedrawRestriction, contains('Vendetta'));
  });

  testWidgets('outgoing helm rejects a retained redraw callback', (
    tester,
  ) async {
    final controller = stormNavigator();
    addTearDown(controller.dispose);
    final chart = controller.seaChart.toJson();
    chart['courseOptions'] = [
      for (final bearing in NavigationalBearing.values)
        {
          'bearing': bearing.name,
          'nodeType': EncounterNodeType.shipwreckSalvage.name,
          'difficultyLevel': 1,
          'lookoutCall': 'Departure ${bearing.name}',
        },
    ];
    controller.seaChart.restoreFromJson(chart);
    await tester.pumpWidget(helm(controller));
    await tester.pumpAndSettle();
    final redraw = redrawButton(tester).onPressed!;
    final steer = tester.widget<InkButton>(
      find
          .byWidgetPredicate(
            (w) => w is InkButton && w.label == 'STEER THIS HEADING',
          )
          .first,
    );
    steer.onPressed!();
    redraw();
    await tester.pump();
    expect(controller.phase, SessionPhase.shipwreck);
    expect(controller.stormSeerRedrawRegion, isNull);
    expect(find.textContaining('Departure'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('restored helm shows redraw already spent in this region', (
    tester,
  ) async {
    final original = stormNavigator();
    addTearDown(original.dispose);
    original.dispatch(const RedrawStormSeerCourses());
    final snapshot = VoyageSaveData.fromJson(
      VoyageSaveData.fromSession(original.session).toJson(),
    );
    final restored = GameController(
      session: GameSession(rng: SeededGameRng(7)),
      autoSave: false,
    );
    addTearDown(restored.dispose);
    snapshot.restoreToSession(restored.session);
    await tester.pumpWidget(helm(restored));
    await tester.pumpAndSettle();
    expect(redrawButton(tester).onPressed, isNull);
    expect(find.text(restored.stormSeerRedrawRestriction!), findsOneWidget);
    expect(restored.stormSeerRedrawRegion, restored.seaChart.timesCompleted);
  });
}
