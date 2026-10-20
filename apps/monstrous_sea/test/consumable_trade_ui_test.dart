import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/loot_screen.dart';
import 'package:monstrous_sea/src/screens/merchant_screen.dart';
import 'package:monstrous_sea/src/screens/smuggler_screen.dart';

void main() {
  for (final screen in ['merchant', 'loot', 'smuggler']) {
    testWidgets(
      '$screen uses single-use Tactical Belt labels for legacy bottles',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = GameController(
          session: GameSession(rng: SeededGameRng(13)),
        );
        controller.dispatch(const NameCaptain('Bottle Trader'));
        controller.dispatch(const ChooseShip(ShipClass.standard));
        final legacy =
            generateConsumable(
                ConsumableType.alchemicalPitch,
                RarityLevel.common,
              ).toJson()
              ..['rarity'] = 'rare'
              ..['maxUses'] = 2
              ..['usesLeft'] = 2;
        final bottle = Consumable.fromJson(legacy);
        // Also verify these screens never present the inherited rarity field.
        bottle.rarity = RarityLevel.rare;
        controller.ship!.cargo
          ..clear()
          ..add(bottle);
        controller.session.merchantStock = [bottle];
        controller.session.smugglerStock = [bottle];
        controller.session.pendingLoot = [bottle];
        controller.session.phase = switch (screen) {
          'merchant' => SessionPhase.merchant,
          'loot' => SessionPhase.loot,
          _ => SessionPhase.smuggler,
        };
        final widget = switch (screen) {
          'merchant' => MerchantScreen(controller: controller),
          'loot' => LootScreen(controller: controller),
          _ => SmugglerScreen(controller: controller, onOpenChart: () {}),
        };
        await tester.pumpWidget(MaterialApp(home: widget));
        await tester.pumpAndSettle();
        expect(find.textContaining('Single use'), findsWidgets);
        expect(find.textContaining('TACTICAL BELT'), findsWidgets);
        expect(
          find.textContaining(RegExp(r'\b[Rr][Aa][Rr][Ee]\b')),
          findsNothing,
        );
        expect(
          find.textContaining(
            RegExp(r'2\s*(use|charge)', caseSensitive: false),
          ),
          findsNothing,
        );
        expect(find.textContaining('CARGO HOLD'), findsNothing);
        expect(tester.takeException(), isNull);
        if (screen == 'smuggler') {
          await tester.tap(find.text('SELL FROM BELT (1)'));
          await tester.pumpAndSettle();
          expect(find.text('Single use · Value: 25g'), findsOneWidget);
          expect(find.textContaining('RARE'), findsNothing);
        }
        controller.dispose();
      },
    );
  }
}
