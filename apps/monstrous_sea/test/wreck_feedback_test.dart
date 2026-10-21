import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/shipwreck_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

Future<void> mountWreck(
  WidgetTester tester,
  GameController controller,
  double scale, {
  Key? captureKey,
}) async {
  InkTheme.disableGoogleFonts = true;
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) =>
              ShipwreckScreen(controller: controller, onOpenChart: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GameController fullWreck() {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Salvager'));
  controller.session.phase = SessionPhase.shipwreck;
  controller.session.hasSalvagedCurrentWreck = true;
  controller.session.currentShipwreckName = 'The Forgotten Brig';
  for (var i = 0; i < controller.ship!.maxCargo; i++) {
    controller.ship!.addCargo(randomConsumable(1, SeededGameRng(i)));
  }
  controller.session.pendingLoot = [randomConsumable(1, SeededGameRng(55))];
  controller.session.wreckSalvageReceipt = [
    '3 Sea Glass',
    '1 Depth-Wrought Iron',
    'Recovered ${controller.pendingLoot.single.name}.',
  ];
  return controller;
}

void main() {
  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('salvage receipt and belt recovery at $width, text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = fullWreck();
        addTearDown(controller.dispose);
        await mountWreck(tester, controller, scale);
        expect(
          find.textContaining('3 Sea Glass\n1 Depth-Wrought Iron'),
          findsOneWidget,
        );
        expect(find.textContaining('Belt full.'), findsOneWidget);
        final jettison = find.textContaining('JETTISON ');
        await tester.ensureVisible(jettison.first);
        await tester.tap(jettison.first);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('STOW SUPPLY'));
        await tester.tap(find.text('STOW SUPPLY'));
        await tester.pumpAndSettle();
        expect(controller.pendingLoot, isEmpty);
        expect(controller.phase, SessionPhase.shipwreck);
        await tester.ensureVisible(find.text('LEAVE WRECK & TAKE THE HELM'));
        await tester.tap(find.text('LEAVE WRECK & TAKE THE HELM'));
        await tester.pumpAndSettle();
        expect(controller.phase, SessionPhase.helm);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'wreck choice describes current probabilities and no retired weapons',
    (tester) async {
      final controller = fullWreck();
      addTearDown(controller.dispose);
      controller.session.hasSalvagedCurrentWreck = false;
      controller.pendingLoot.clear();
      await mountWreck(tester, controller, 1.3);
      expect(
        find.textContaining('25% chance: 1 Depth-Wrought Iron'),
        findsOneWidget,
      );
      expect(find.textContaining('Military-Grade Weapon'), findsNothing);
      expect(
        find.textContaining('60–120 gold doubloons + 2–4 Sea Glass'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
