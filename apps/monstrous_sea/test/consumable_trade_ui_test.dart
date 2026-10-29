import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/screens/loot_screen.dart';
import 'package:monstrous_sea/src/screens/merchant_screen.dart';
import 'package:monstrous_sea/src/screens/smuggler_screen.dart';

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (const bool.fromEnvironment('captureMenuFixes')) {
      final loader = FontLoader('MenuReview')
        ..addFont(
          File('C:/Windows/Fonts/georgia.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      await loader.load();
    }
  });
  for (final width in [600.0, 800.0]) {
    testWidgets('full belt warning wraps at $width with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(13)),
        autoSave: false,
      );
      addTearDown(controller.dispose);
      controller.dispatch(const NameCaptain('Salvager'));
      controller.dispatch(const ChooseShip(ShipClass.standard));
      final ship = controller.ship!;
      ship.cargo
        ..clear()
        ..addAll(
          List.generate(
            ship.maxCargo,
            (_) => generateConsumable(
              ConsumableType.hullPatchKit,
              RarityLevel.common,
            ),
          ),
        );
      controller.session
        ..pendingLoot = [
          generateConsumable(ConsumableType.blastPack, RarityLevel.common),
        ]
        ..phase = SessionPhase.loot;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData.copyWith(
            textTheme: InkTheme.themeData.textTheme.apply(
              fontFamily: const bool.fromEnvironment('captureMenuFixes')
                  ? 'MenuReview'
                  : null,
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: key,
            child: LootScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final warning = find.text(
        'BELT FULL — Toss an item below to stow spoils',
      );
      expect(warning, findsOneWidget);
      final bounds = tester.getRect(warning);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(width));
      expect(
        bounds.overlaps(tester.getRect(find.text('TACTICAL BELT: 3 / 3'))),
        isFalse,
      );
      expect(ship.cargo.length, ship.maxCargo);
      expect(controller.pendingLoot, hasLength(1));
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('captureMenuFixes')) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('build/belt-full-${width.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
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
          autoSave: false,
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
