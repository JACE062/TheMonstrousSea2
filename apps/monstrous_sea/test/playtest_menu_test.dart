import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/playtest/playtest_host.dart';
import 'package:monstrous_sea/src/playtest/playtest_screen.dart';
import 'package:monstrous_sea/src/screens/caldera_outcome_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';

const reviewFont = String.fromEnvironment('playtestFontPath');

Future<void> select(WidgetTester tester, String label, String value) async {
  final field = find.byKey(ValueKey(label));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/playtest-$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (reviewFont.isNotEmpty) {
      await (FontLoader(
            'PlaytestReview',
          )..addFont(File(reviewFont).readAsBytes().then(ByteData.sublistView)))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('configure, launch, relaunch and edit at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final launches = <GameController>[];
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: InkTheme.themeData.copyWith(
                textTheme: InkTheme.themeData.textTheme.apply(
                  fontFamily: reviewFont.isEmpty ? null : 'PlaytestReview',
                ),
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: PlaytestScreen(
                gameBuilder: (controller) {
                  if (launches.isEmpty ||
                      !identical(launches.last, controller)) {
                    launches.add(controller);
                  }
                  return const ParchmentScaffold(
                    body: Center(child: Text('RUNNING SCENARIO')),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('LAUNCH PLAYTEST').hitTestable(), findsOneWidget);
        if (reviewFont.isNotEmpty && scale == 1.3) {
          await screenshot(tester, key, '${width.toInt()}-menu');
        }
        await select(tester, 'Blueprint', ShipClass.bombardier.displayName);
        await select(tester, 'Hull tier', 'Tier 3');
        await select(tester, 'Ancestral signature tier', 'Tier 2');
        await select(tester, 'Destination', 'Region Titan');
        await select(tester, 'Region', SeaChart.regionName(1));
        await select(tester, 'broadside Mk', 'Mk III');
        await select(
          tester,
          'signature dedication',
          OceanPower.brinemother.displayName,
        );
        await select(tester, 'signature blessing tier', 'Tier III');
        await select(
          tester,
          'utility dedication',
          OceanPower.earthshakerTitan.displayName,
        );
        await select(tester, 'utility blessing tier', 'Tier II');
        final gold = find.byKey(const ValueKey('playtest-gold'));
        await tester.ensureVisible(gold);
        await tester.enterText(gold, '888');
        final launch = find.text('LAUNCH PLAYTEST');
        await tester.ensureVisible(launch);
        await tester.tap(launch);
        await tester.pumpAndSettle();
        expect(find.text('RUNNING SCENARIO'), findsOneWidget);
        final first = launches.single;
        expect(first.ship!.blueprintId, BlueprintId.bombardier.name);
        expect(first.ship!.level, 3);
        expect(first.profile.armamentTierFor(BlueprintId.bombardier), 2);
        expect(first.ship!.markForHardpoint(HardpointType.broadside), 3);
        expect(first.ship!.blessings[HardpointType.signature]!.tier, 3);
        expect(
          first.ship!.blessings[HardpointType.utility]!.power,
          OceanPower.earthshakerTitan,
        );
        expect(first.currentMonster!.species, MonsterSpecies.worldSerpent);
        expect(first.ship!.gold, 888);
        first.ship!.gold = 0;
        await tester.tap(find.text('RELAUNCH'));
        await tester.pumpAndSettle();
        expect(launches, hasLength(2));
        expect(launches.last.ship!.gold, 888);
        expect(launches.last.ship!.currentHp, launches.last.ship!.maxHp);
        await tester.tap(find.text('CHANGE SCENARIO'));
        await tester.pumpAndSettle();
        expect(find.text('PLAYTEST MENU'), findsOneWidget);
        final bp = tester.widget<DropdownButton<BlueprintId>>(
          find.byKey(const ValueKey('Blueprint')),
        );
        expect(bp.value, BlueprintId.bombardier);
        await select(tester, 'signature dedication', 'No blessing');
        await tester.ensureVisible(launch);
        await tester.tap(launch);
        await tester.pumpAndSettle();
        expect(
          launches.last.ship!.blessings.containsKey(HardpointType.signature),
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('invalid numeric input stays in the menu with a useful error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlaytestScreen(
          gameBuilder: (_) => throw StateError('Invalid input must not launch'),
        ),
      ),
    );
    final gold = find.byKey(const ValueKey('playtest-gold'));
    await tester.ensureVisible(gold);
    await tester.enterText(gold, '-10');
    await tester.ensureVisible(find.text('LAUNCH PLAYTEST'));
    await tester.tap(find.text('LAUNCH PLAYTEST'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number from 0 to 999999.'), findsOneWidget);
  });

  testWidgets(
    'F10 reaches both ending outcomes without changing the suspended normal game',
    (tester) async {
      final normal = GameController(autoSave: false)
        ..dispatch(const NameCaptain('Real Captain'))
        ..dispatch(const ChooseShip(ShipClass.standard));
      addTearDown(normal.dispose);
      normal.ship!.gold = 321;
      final profileBefore = normal.profile.toJson();
      final phases = <SessionPhase>[];
      normal.addListener(() => phases.add(normal.phase));
      await tester.pumpWidget(MonstrousSeaApp(controller: normal));
      await tester.pumpAndSettle();
      expect(find.byType(PortScreen), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(find.byType(PlaytestScreen), findsOneWidget);
      await select(tester, 'Destination', 'Caldera ending choice');
      final region = tester.widget<DropdownButton<int>>(
        find.byKey(const ValueKey('Region')),
      );
      expect(region.value, 2);
      expect(region.onChanged, isNull);
      for (final choice in CalderaClimaxChoice.values) {
        await tester.ensureVisible(find.text('LAUNCH PLAYTEST'));
        await tester.tap(find.text('LAUNCH PLAYTEST'));
        await tester.pumpAndSettle();
        final choose = find.text(choice.displayName.toUpperCase());
        await tester.ensureVisible(choose);
        await tester.tap(choose);
        await tester.pumpAndSettle();
        expect(find.byType(CalderaOutcomeScreen), findsOneWidget);
        expect(
          find.text(EldritchLore.calderaClimax[choice]!.narrativeOutcome),
          findsOneWidget,
        );
        await tester.tap(find.text('CHANGE SCENARIO'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();
      expect(find.byType(PortScreen), findsOneWidget);
      expect(normal.phase, SessionPhase.port);
      expect(normal.ship!.gold, 321);
      expect(normal.profile.toJson(), profileBefore);
      expect(phases, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'direct playtest startup defers mounting the normal game until return',
    (tester) async {
      var normalBuilds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PlaytestHost(
            openOnStart: true,
            gameBuilder: (_) => const SizedBox.shrink(),
            child: Builder(
              builder: (_) {
                normalBuilds++;
                return const ParchmentScaffold(body: Text('NORMAL GAME'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PlaytestScreen), findsOneWidget);
      expect(normalBuilds, 0);
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();
      expect(find.text('NORMAL GAME'), findsOneWidget);
      expect(normalBuilds, greaterThan(0));
    },
  );
}
