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
    testWidgets('Toggling font scale updates GameSettings and scales UI', (tester) async {
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
      expect(GameSettings.instance.fontScale, 1.0);
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
      expect(GameSettings.instance.fontScale, 1.0);
      expect(GameSettings.instance.highLegibilityFont, false);

      // Close dialog
      await tester.ensureVisible(find.text('DONE'));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(find.text('SETTINGS & ACCESSIBILITY'), findsNothing);
    });
  });

  group('SeaChartScreen Defeated Status & VESSEL Overlap', () {
    testWidgets('Defeated monster immediately reflects on sea chart during rest/loot', (tester) async {
      final chart = SeaChart(currentRow: 1, currentCol: 2);

      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData,
          home: SeaChartScreen(
            seaChart: chart,
            isInPort: false,
            isCurrentDefeated: true,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // With isCurrentDefeated = true:
      // Row 0 has 5 completed sectors.
      // Row 1 cols 0 and 1 were completed previously.
      // Row 1 col 2 was just defeated! Total completed = 5 + 2 + 1 = 8 sectors.
      expect(find.text('DEFEATED'), findsNWidgets(8));

      // Current vessel marker is on Row 1 Col 2
      expect(find.text('VESSEL'), findsOneWidget);

      // Verify the VESSEL marker and DEFEATED marker on the current cell do not overlap vertically
      final vesselFinder = find.text('VESSEL');
      final defeatedFinder = find.text('DEFEATED');

      final vesselBox = tester.getRect(vesselFinder);
      // The current sector's DEFEATED label is in the same cell as vesselBox (Row 1 Col 2)
      Rect? currentDefeatedBox;
      for (final element in tester.widgetList<Text>(defeatedFinder)) {
        final box = tester.getRect(find.byWidget(element));
        if ((box.center.dx - vesselBox.center.dx).abs() < 25 &&
            (box.center.dy - vesselBox.center.dy).abs() < 50) {
          currentDefeatedBox = box;
          break;
        }
      }

      expect(currentDefeatedBox, isNotNull);
      // VESSEL is at top (Positioned top: 3), DEFEATED is below the monster/skull art
      expect(vesselBox.bottom, lessThan(currentDefeatedBox!.top));
    });

    testWidgets('Underway sea chart shows alive monster art when not yet defeated', (tester) async {
      final chart = SeaChart(currentRow: 1, currentCol: 2);

      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData,
          home: SeaChartScreen(
            seaChart: chart,
            isInPort: false,
            isCurrentDefeated: false,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When not defeated, row 1 col 2 still has living monster
      // Completed = 5 (row 0) + 2 (row 1 cols 0, 1) = 7
      expect(find.text('DEFEATED'), findsNWidgets(7));
      expect(find.text('VESSEL'), findsOneWidget);

      // The species name for row 1 col 2 should be displayed
      final species = chart.speciesAt(1, 2);
      expect(find.text(species.name.toUpperCase()), findsWidgets);

      // VESSEL is at the top of the cell and doesn't overlap the species label
      final vesselBox = tester.getRect(find.text('VESSEL'));
      final speciesFinder = find.text(species.name.toUpperCase());
      Rect? currentSpeciesBox;
      for (final element in tester.widgetList<Text>(speciesFinder)) {
        final box = tester.getRect(find.byWidget(element));
        if ((box.center.dx - vesselBox.center.dx).abs() < 25) {
          currentSpeciesBox = box;
          break;
        }
      }
      expect(currentSpeciesBox, isNotNull);
      expect(vesselBox.bottom, lessThan(currentSpeciesBox!.top));
    });
  });
}
