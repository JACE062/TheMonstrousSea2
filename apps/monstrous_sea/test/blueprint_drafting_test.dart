import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';

void main() {
  group('Shipwright Drafting Table & Blueprint Unlocks', () {
    testWidgets(
        'PortScreen opens Blueprints dialog, displays hardpoints, unlocks and commissions Ironclad',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
      );

      controller.dispatch(const NameCaptain('Albatross'));
      controller.dispatch(const ChooseShip(ShipClass.standard));

      expect(controller.ship?.blueprintId, BlueprintId.standard.name);
      expect(controller.phase, SessionPhase.port);

      await tester.pumpWidget(MaterialApp(
        home: PortScreen(
          controller: controller,
          onOpenChart: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Verify PortScreen has BLUEPRINTS action button
      final blueprintsBtn = find.text('BLUEPRINTS');
      expect(blueprintsBtn, findsOneWidget);

      // Tap BLUEPRINTS button to open dialog
      await tester.tap(blueprintsBtn);
      await tester.pumpAndSettle();

      // Verify dialog header
      expect(find.text("SHIPWRIGHT'S DRAFTING TABLE"), findsOneWidget);
      expect(find.text('Active: STANDARD'), findsOneWidget);

      // Verify Meta-Currency ledger labels
      expect(find.textContaining('Sea Glass'), findsWidgets);
      expect(find.textContaining('Monster Bone'), findsWidgets);
      expect(find.textContaining('Depth Iron'), findsWidgets);
      expect(find.textContaining('Barnacles'), findsWidgets);

      // Verify all 5 Blueprints are listed
      expect(find.textContaining('BLUEPRINT: STANDARD'), findsOneWidget);
      expect(find.textContaining('BLUEPRINT: IRONCLAD'), findsOneWidget);
      expect(find.textContaining('BLUEPRINT: CLIPPER'), findsOneWidget);
      expect(find.textContaining('BLUEPRINT: BOMBARDIER'), findsOneWidget);
      expect(find.textContaining('BLUEPRINT: CORSAIR'), findsOneWidget);

      // Standard is active hull
      expect(find.text('ACTIVE HULL'), findsOneWidget);

      // Currently, player has 0 materials, so Ironclad says LACKS MATERIALS
      expect(find.text('LACKS MATERIALS'), findsWidgets);

      // Grant exact Tier 1 unlock materials for Ironclad
      controller.session.profile.metaInventory.add(
        seaGlass: 15,
        monsterBone: 10,
      );

      // Close dialog
      final closeBtn = find.text('Close');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Reopen dialog with updated profile materials
      await tester.tap(blueprintsBtn);
      await tester.pumpAndSettle();

      // Ironclad can now be unlocked!
      final unlockBtn = find.widgetWithText(InkWell, 'UNLOCK');
      expect(unlockBtn, findsWidgets);

      // Tap UNLOCK on Ironclad
      await tester.tap(unlockBtn.first);
      await tester.pumpAndSettle();

      // Verify Ironclad is now unlocked in profile
      expect(
          controller.session.profile.isBlueprintUnlocked(BlueprintId.ironclad),
          isTrue);
      // Meta-currencies were deducted
      expect(controller.session.profile.metaInventory.seaGlass, equals(0));
      expect(controller.session.profile.metaInventory.monsterBone, equals(0));

      // Now the button for Ironclad is COMMISSION
      final commissionBtn = find.widgetWithText(InkWell, 'COMMISSION');
      expect(commissionBtn, findsOneWidget);

      // Tap COMMISSION
      await tester.tap(commissionBtn);
      await tester.pumpAndSettle();

      // Dialog should close and active ship should now be Ironclad
      expect(find.text("SHIPWRIGHT'S DRAFTING TABLE"), findsNothing);
      expect(controller.ship?.blueprintId, BlueprintId.ironclad.name);
      expect(controller.ship?.shipClass, ShipClass.ironclad);
      expect(controller.ship?.baseDmgReduction, equals(3));
      expect(
        controller.ship?.equippedWeapons
            .any((w) => w.weaponType == ShipWeaponType.prowRam),
        isTrue,
      );
    });
  });
}
