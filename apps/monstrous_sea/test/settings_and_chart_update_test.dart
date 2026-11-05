import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';
import 'package:monstrous_sea/src/settings/game_settings.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/settings_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  InkTheme.disableGoogleFonts = true;

  tearDown(() {
    GameSettings.instance.resetDefaults();
  });

  group('GameSettings & SettingsDialog', () {
    testWidgets('Toggling font scale updates GameSettings and scales UI', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SettingsDialog.show(context),
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );

      // Verify default state
      expect(GameSettings.instance.fontScale, 1.15);
      expect(GameSettings.instance.highLegibilityFont, false);

      // Open SettingsDialog
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS & ACCESSIBILITY'), findsOneWidget);

      // Tap 'Large' (115%)
      await tester.tap(find.text('Large'));
      await tester.pumpAndSettle();
      expect(GameSettings.instance.fontScale, closeTo(1.15, 0.01));

      // Tap 'Extra Large' (130%)
      await tester.tap(find.text('Extra Large'));
      await tester.pumpAndSettle();
      expect(GameSettings.instance.fontScale, closeTo(1.30, 0.01));

      // Tap 'High Legibility'
      await tester.tap(find.text('High Legibility'));
      await tester.pumpAndSettle();
      expect(GameSettings.instance.highLegibilityFont, true);

      // Tap 'Reset to Default'
      await tester.ensureVisible(find.text('Reset to Default'));
      await tester.tap(find.text('Reset to Default'));
      await tester.pumpAndSettle();
      expect(GameSettings.instance.fontScale, 1.15);
      expect(GameSettings.instance.highLegibilityFont, false);

      // Close dialog
      await tester.ensureVisible(find.text('DONE'));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(find.text('SETTINGS & ACCESSIBILITY'), findsNothing);
    });
  });

  group('SeaChartScreen recorded outcomes', () {
    for (final won in [false, true]) {
      testWidgets('arrival and actual victory remain distinct: won=$won', (tester) async {
        final chart = SeaChart(rng: SeededGameRng(8))..beginVoyage();
        if (won) chart.recordCurrentOutcome(combatWon: true);
        await tester.pumpWidget(MaterialApp(theme: InkTheme.themeData,
          home: SeaChartScreen(seaChart: chart, isCurrentDefeated: !won, onClose: () {})));
        await tester.pumpAndSettle();
        expect(find.text(won ? 'VICTORY' : 'ARRIVED'), findsOneWidget);
        expect(find.text(won ? 'ARRIVED' : 'VICTORY'), findsNothing);
        expect(find.text('VESSEL'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
