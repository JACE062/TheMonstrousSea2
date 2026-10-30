import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/armory_view.dart';

import 'combat_flow_test.dart' show mountBattle;

GameController _clipper(int mark) {
  final session = GameSession(
    rng: SeededGameRng(42),
    profile: ProfileData(unlockedBlueprints: {BlueprintId.clipper.name}),
  );
  final controller = GameController(session: session, autoSave: false)
    ..dispatch(const NameCaptain('Rigging review'))
    ..dispatch(const ChooseShip(ShipClass.clipper))
    ..dispatch(const VentureOutToSea());
  session.ship!.hardpointMarks[HardpointType.utility] = mark;
  return controller;
}

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);
  for (final (mark, bonus, total) in [(1, 25, 50), (2, 40, 65), (3, 55, 80)]) {
    testWidgets('Mk $mark inspection and battle show +$bonus% / $total%', (
      tester,
    ) async {
      final controller = _clipper(mark);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArmoryView(controller: controller),
            ),
          ),
        ),
      );
      final numericCopy = 'Sets evasion to $total% (+$bonus% above base)';
      expect(find.textContaining(numericCopy), findsOneWidget);
      expect(find.textContaining('Doubles evasion'), findsNothing);

      await mountBattle(tester, controller);
      expect(
        find.byWidgetPredicate(
          (w) => w is Tooltip && (w.message?.contains(numericCopy) ?? false),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
