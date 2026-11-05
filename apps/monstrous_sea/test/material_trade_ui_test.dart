import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/merchant_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/material_trade_view.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);
  for (final width in [360.0, 1280.0]) {
    testWidgets('finite material trade works with a full belt at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(9)),
        autoSave: false,
      )..dispatch(const BeginFirstVoyage('Materials'));
      addTearDown(controller.dispose);
      controller.session
        ..phase = SessionPhase.merchant
        ..merchantMaterials = MaterialShipment(
          id: 'shop',
          seaGlass: 1,
          depthWroughtIron: 1,
        );
      controller.ship!.gold = 65;
      for (var i = 0; i < controller.ship!.maxCargo; i++) {
        controller.ship!.cargo.add(
          generateConsumable(ConsumableType.blastPack, RarityLevel.common),
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: MerchantScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final buyGlass = find.byKey(const ValueKey('buy-material-seaGlass'));
      await tester.ensureVisible(buyGlass);
      await tester.tap(buyGlass);
      await tester.pumpAndSettle();
      expect(controller.ship!.gold, 50);
      expect(controller.session.profile.metaInventory.seaGlass, 1);
      expect(find.text('SOLD OUT'), findsOneWidget);
      final buyIron = find.byKey(
        const ValueKey('buy-material-depthWroughtIron'),
      );
      await tester.ensureVisible(buyIron);
      await tester.tap(buyIron);
      await tester.pumpAndSettle();
      expect(controller.ship!.gold, 0);
      expect(controller.session.profile.metaInventory.depthWroughtIron, 1);
      expect(controller.ship!.cargo, hasLength(controller.ship!.maxCargo));
      expect(find.text('SOLD OUT'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'empty shipment remains visible and no shop stock appears before arrival',
    (tester) async {
      final c = GameController(
        session: GameSession(rng: SeededGameRng(2)),
        autoSave: false,
      )..dispatch(const BeginFirstVoyage('Empty shipment'));
      addTearDown(c.dispose);
      c.session
        ..phase = SessionPhase.smuggler
        ..smugglerMaterials = MaterialShipment(id: 'empty');
      await tester.pumpWidget(
        MaterialApp(
          home: ParchmentScaffold(body: MaterialTradeView(controller: c)),
        ),
      );
      expect(find.text('SOLD OUT'), findsNWidgets(2));
      c.session.phase = SessionPhase.helm;
      c.notifyListeners();
      await tester.pump();
      expect(find.text('PERMANENT MATERIALS'), findsNothing);
      expect(c.session.smugglerMaterials!.seaGlass, 0);
    },
  );
}
