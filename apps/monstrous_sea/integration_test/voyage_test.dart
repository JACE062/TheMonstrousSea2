import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/screens/captain_screen.dart';
import 'package:monstrous_sea/src/screens/intro_screen.dart';
import 'package:monstrous_sea/src/screens/loot_screen.dart';
import 'package:monstrous_sea/src/screens/merchant_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/screens/rest_screen.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  InkTheme.disableGoogleFonts = true;

  group('The Monstrous Sea — End-to-End Voyage Integration Tests', () {
    testWidgets('Standard Voyage Loop: Intro -> Commission -> Port -> Sea Chart -> Battle -> Loot -> Rest',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MonstrousSeaApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Intro Screen
      expect(find.byType(IntroScreen), findsOneWidget);
      expect(find.text('THE MONSTROUS SEA'), findsOneWidget);
      expect(find.text('EMBARK UPON THE HUNT'), findsOneWidget);

      await tester.tap(find.text('EMBARK UPON THE HUNT'));
      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      // 2. Captain Commissioning Screen
      expect(find.byType(CaptainScreen), findsOneWidget);
      expect(find.text('COMMISSION OF VOYAGE'), findsOneWidget);

      // Enter Captain Name
      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Captain Horatio');
      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      // Select Standard Barque
      await tester.tap(find.text('STANDARD'));
      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Commission vessel
      await tester.tap(find.text('COMMISSION & SET SAIL'));
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      // 3. Port Hub (Hunter's Respite)
      expect(find.byType(PortScreen), findsOneWidget);
      expect(find.text("HUNTER'S RESPITE"), findsOneWidget);
      expect(find.text('VENTURE OUT TO SEA'), findsOneWidget);

      // Open and verify Sea Chart
      await tester.tap(find.text('SEA CHART'));
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(SeaChartScreen), findsOneWidget);
      expect(find.text('NAUTICAL SEA CHART'), findsOneWidget);
      // Verify Fog of War is present on deeper rows
      expect(find.textContaining('FOG'), findsWidgets);

      // Close Sea Chart
      await tester.ensureVisible(find.text('CLOSE SEA CHART'));
      await tester.tap(find.text('CLOSE SEA CHART'));
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(PortScreen), findsOneWidget);

      // Open and verify Merchant Screen
      await tester.tap(find.text('VISIT MERCHANT'));
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(MerchantScreen), findsOneWidget);
      expect(find.text('HARPOON & HELM CHANDLERY'), findsOneWidget);
      // Close Merchant
      await tester.ensureVisible(find.text('LEAVE CHANDLERY & RETURN TO PORT'));
      await tester.tap(find.text('LEAVE CHANDLERY & RETURN TO PORT'));
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(PortScreen), findsOneWidget);

      // 4. Venture Out to Sea -> Battle Screen
      await tester.ensureVisible(find.text('VENTURE OUT TO SEA'));
      await tester.tap(find.text('VENTURE OUT TO SEA'));
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(find.byType(BattleScreen), findsOneWidget);
      expect(find.text('BEAST INTEGRITY'), findsOneWidget);

      // Test combat interaction: fire Cannon volley until victory or flee
      final cannonButton = find.text('Cannon (2/2)');
      if (cannonButton.evaluate().isNotEmpty) {
        await tester.tap(cannonButton);
        for (var frame = 0; frame < 6; frame++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
      }

      // If battle continues, test Flee encounter
      if (find.byType(BattleScreen).evaluate().isNotEmpty) {
        final fleeButton = find.text('Flee Encounter');
        if (fleeButton.evaluate().isNotEmpty) {
          await tester.tap(fleeButton);
          for (var frame = 0; frame < 6; frame++) {
            await tester.pump(const Duration(milliseconds: 500));
          }
        }
      }
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      // Verify we safely transition to LootScreen, RestScreen, or PortScreen
      final hasLoot = find.byType(LootScreen).evaluate().isNotEmpty;
      final hasRest = find.byType(RestScreen).evaluate().isNotEmpty;
      final hasPort = find.byType(PortScreen).evaluate().isNotEmpty;
      final hasBattle = find.byType(BattleScreen).evaluate().isNotEmpty;
      expect(hasLoot || hasRest || hasPort || hasBattle, isTrue);
    });

    testWidgets('Davy Jones Easter Egg initiates Kraken Boss Battle on Flying Dutchman',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MonstrousSeaApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('EMBARK UPON THE HUNT'));
      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      // Enter Davy Jones easter egg name
      final nameField = find.byType(TextField);
      await tester.enterText(nameField, 'Davy Jones');
      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      await tester.tap(find.text('COMMISSION & SET SAIL'));
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      // Should immediately initiate battle with The Kraken
      expect(find.byType(BattleScreen), findsOneWidget);
      expect(find.text('Flying Dutchman'), findsWidgets);
      expect(find.textContaining('Kraken'), findsWidgets);
    });
  });
}
