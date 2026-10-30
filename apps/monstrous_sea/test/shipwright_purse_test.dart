import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/voyage_shipwright_view.dart';

GameController atVoyageShipwright({
  required SessionPhase phase,
  int gold = 417,
}) {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Reed'));
  controller.seaChart.currentLeg = controller.seaChart.midpointHavenLeg;
  controller.session.phase = phase;
  controller.ship!.gold = gold;
  return controller;
}

Widget shipwrightApp(GameController controller, {double width = 360}) =>
    MaterialApp(
      theme: InkTheme.themeData,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: const TextScaler.linear(1.3),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: VoyageShipwrightView(controller: controller),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);

  for (final phase in [SessionPhase.respiteIsland, SessionPhase.stronghold]) {
    testWidgets('shows live purse at ${phase.name}', (tester) async {
      final controller = atVoyageShipwright(phase: phase);
      addTearDown(controller.dispose);
      await tester.pumpWidget(shipwrightApp(controller));

      final purse = find.byKey(const ValueKey('voyage-shipwright-purse'));
      expect(purse, findsOneWidget);
      expect(tester.widget<Text>(purse).data, 'PURSE: 417g');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('purse and upgrade affordability update after spending', (
    tester,
  ) async {
    final controller = atVoyageShipwright(
      phase: SessionPhase.stronghold,
      gold: 100,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(shipwrightApp(controller));
    final purse = find.byKey(const ValueKey('voyage-shipwright-purse'));
    final upgrade = find.text('UPGRADE TIER · 100g');

    expect(tester.widget<Text>(purse).data, 'PURSE: 100g');
    expect(
      tester
          .widget<InkWell>(
            find.ancestor(of: upgrade, matching: find.byType(InkWell)).first,
          )
          .onTap,
      isNotNull,
    );
    await tester.tap(upgrade);
    await tester.pump();

    expect(controller.ship!.gold, 0);
    expect(tester.widget<Text>(purse).data, 'PURSE: 0g');
    expect(
      tester
          .widget<InkWell>(
            find
                .ancestor(
                  of: find.text('UPGRADE TIER · 250g'),
                  matching: find.byType(InkWell),
                )
                .first,
          )
          .onTap,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits at 360px and 130% text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = atVoyageShipwright(phase: SessionPhase.stronghold);
    addTearDown(controller.dispose);
    await tester.pumpWidget(shipwrightApp(controller));

    expect(find.text('PURSE: 417g'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
