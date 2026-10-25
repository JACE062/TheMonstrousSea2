import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/respite_island_screen.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

import 'combat_flow_test.dart' show mountBattle;

GameController _controller() =>
    GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      )
      ..dispatch(const NameCaptain('Playtest Captain'))
      ..dispatch(const ChooseShip(ShipClass.standard));

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);
  testWidgets(
    'Emergency pass appears only when all turn-ending hardpoints are unavailable',
    (tester) async {
      final controller = _controller()..dispatch(const VentureOutToSea());
      addTearDown(controller.dispose);
      await mountBattle(tester, controller);
      expect(find.byKey(const ValueKey('emergency-pass')), findsNothing);
      for (final weapon in controller.ship!.equippedWeapons) {
        weapon.chargeCountdown = 2;
      }
      controller.ship!.utilityCooldown = 0;
      // Rebuild with a fresh scene so the readiness state is observed directly.
      await tester.pumpWidget(const SizedBox());
      await mountBattle(tester, controller);
      expect(find.byKey(const ValueKey('emergency-pass')), findsNothing);
      controller.ship!.utilityCooldown = 2;
      controller.ship!.cargo.add(
        generateConsumable(ConsumableType.blastPack, RarityLevel.common),
      );
      await tester.pumpWidget(const SizedBox());
      await mountBattle(tester, controller);
      expect(find.byKey(const ValueKey('emergency-pass')), findsOneWidget);
      expect(find.text('Blast Pack'), findsOneWidget);
      expect(find.text('5 Blast · 75% hit'), findsOneWidget);
      expect(find.text('SINGLE USE · 0T QUICK ACTION'), findsNothing);
      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .any((s) => RegExp('[⚡🎯⚠⚓🔥⛓]').hasMatch(s)),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 1200.0]) {
    testWidgets(
      'Island duties have consistent ink and inspect-only armory at $width with 130% text',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _controller();
        addTearDown(controller.dispose);
        controller.session.phase = SessionPhase.respiteIsland;
        controller.ship!.currentHp -= 10;
        await tester.pumpWidget(
          MaterialApp(
            theme: InkTheme.themeData,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: RespiteIslandScreen(
              controller: controller,
              onOpenChart: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final duties = tester.widgetList<Text>(
          find.textContaining('Shore Duty Option'),
        );
        expect(duties.length, 3);
        expect(duties.map((t) => t.style!.color).toSet(), {
          InkTheme.inkPrimary,
        });
        final inspect = find.text('INSPECT VESSEL');
        await tester.ensureVisible(inspect);
        await tester.tap(inspect);
        await tester.pumpAndSettle();
        expect(find.textContaining('Equip deck weapons'), findsNothing);
        expect(find.textContaining('Temper ('), findsNothing);
        expect(
          find.textContaining('HARDPOINTS & TACTICAL BELT'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'Chart uses authoritative second leg and resets vessel marker in port',
    (tester) async {
      final chart = SeaChart(currentLeg: 2);
      await tester.pumpWidget(
        MaterialApp(
          home: SeaChartScreen(
            seaChart: chart,
            isCurrentDefeated: true,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('DEFEATED'), findsNWidgets(2));
      expect(find.textContaining('Leg 2 of 10'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: SeaChartScreen(seaChart: chart, isInPort: true, onClose: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('DEFEATED'), findsNothing);
      expect(find.text('VESSEL'), findsOneWidget);
    },
  );
}
