import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/captain_screen.dart';
import 'package:monstrous_sea/src/screens/intro_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/settings/game_settings.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/armory_view.dart';
import 'package:monstrous_sea/src/widgets/settings_dialog.dart';
import 'package:monstrous_sea/src/widgets/typewriter_text.dart';
import 'package:monstrous_sea/src/widgets/weapon_stats_view.dart';

Widget largeTextApp(Widget child) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(1.3)),
    child: child!,
  ),
  home: child,
);

void main() {
  setUp(() {
    InkTheme.disableGoogleFonts = true;
  });
  tearDown(() {
    GameSettings.instance.resetDefaults();
  });

  test('Reading size defaults and resets to115 percent', () {
    expect(GameSettings.instance.fontScale, 1.15);
    GameSettings.instance.setFontScale(1.3);
    GameSettings.instance.resetDefaults();
    expect(GameSettings.instance.fontScale, 1.15);
  });

  testWidgets(
    'Fresh captain names and sails Standard directly into combat without class picker',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        largeTextApp(CaptainScreen(controller: controller)),
      );
      expect(find.text('CHOOSE STARTING VESSEL'), findsNothing);
      expect(find.text('IRONCLAD'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Rowan Tide');
      final begin = find.text('BEGIN FIRST VOYAGE');
      await tester.ensureVisible(begin);
      await tester.tap(begin);
      await tester.pumpAndSettle();
      expect(controller.captainName, 'Rowan Tide');
      expect(controller.phase, SessionPhase.battle);
      expect(controller.ship!.shipClass, ShipClass.standard);
      expect(controller.profile.unlockedBlueprints, {
        BlueprintId.standard.name,
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Returning bloodline takes command at port with unlocked blueprint',
    (tester) async {
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      );
      addTearDown(controller.dispose);
      controller.profile.hasBegunFirstVoyage = true;
      controller.profile.unlockedBlueprints.add(BlueprintId.clipper.name);
      controller.profile.activeBlueprintId = BlueprintId.clipper.name;
      await tester.pumpWidget(
        largeTextApp(CaptainScreen(controller: controller)),
      );
      await tester.ensureVisible(find.text('TAKE COMMAND'));
      await tester.tap(find.text('TAKE COMMAND'));
      await tester.pumpAndSettle();
      expect(controller.phase, SessionPhase.port);
      expect(controller.ship!.shipClass, ShipClass.clipper);
      expect(find.text('CHOOSE STARTING VESSEL'), findsNothing);
    },
  );

  testWidgets(
    'Intro explains the inherited obligation without revealing the ending choices',
    (tester) async {
      await tester.pumpWidget(largeTextApp(IntroScreen(onStart: () {})));
      final copy = tester
          .widget<TypewriterText>(find.byType(TypewriterText))
          .text;
      expect(copy, contains('Bloodbound Ship'));
      expect(copy, contains('Salt-Sickness'));
      expect(copy, contains('heir'));
      expect(copy, isNot(contains('Abyssal Font')));
      expect(copy, isNot(contains('Claim the Core')));
      expect(copy, isNot(contains('Shatter the Core')));
      expect(copy, isNot(contains('[3, 4]')));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Armory inspects marks blessings ancestral refits and single-use belt at360px',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      );
      addTearDown(controller.dispose);
      controller.dispatch(const NameCaptain('Rowan'));
      controller.dispatch(const ChooseShip(ShipClass.standard));
      controller.ship!.gold = 1000;
      controller.ship!.cargo.clear();
      controller.ship!.cargo.add(generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common));
      controller.ship!.blessings[HardpointType.broadside] =
          const HardpointBlessing(
            power: OceanPower.magmaVentLord,
            slot: HardpointType.broadside,
            tier: 2,
          );
      await tester.pumpWidget(
        largeTextApp(
          Scaffold(
            body: SingleChildScrollView(
              child: ArmoryView(controller: controller),
            ),
          ),
        ),
      );
      expect(find.textContaining('Magma Volley'), findsOneWidget);
      expect(find.text('Ancestral armament: Tier 1'), findsOneWidget);
      expect(find.textContaining('85% base accuracy'), findsWidgets);
      expect(find.textContaining('+85 Hit'), findsNothing);
      expect(find.textContaining('Temper ('), findsNothing);
      expect(find.textContaining('Equip'), findsNothing);
      expect(find.text('Single use'), findsOneWidget);
      expect(find.textContaining('/1 Uses'), findsNothing);
      for (final badge in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(WeaponStatsView),
          matching: find.byType(Text),
        ),
      )) {
        expect(badge.style!.fontSize, greaterThanOrEqualTo(12));
      }
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('JETTISON'));
      await tester.tap(find.text('JETTISON'));
      await tester.pumpAndSettle();
      expect(controller.ship!.cargo, isEmpty);
    },
  );

  testWidgets(
    'Home port has no drydock and remains readable at360px with130percent text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      );
      addTearDown(controller.dispose);
      controller.dispatch(const NameCaptain('Rowan'));
      controller.dispatch(const ChooseShip(ShipClass.standard));
      await tester.pumpWidget(
        largeTextApp(PortScreen(controller: controller, onOpenChart: () {})),
      );
      await tester.pumpAndSettle();
      expect(find.text('DRYDOCK'), findsNothing);
      expect(find.text('BLUEPRINTS'), findsOneWidget);
      expect(find.textContaining('Temper ('), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('BLUEPRINTS'));
      await tester.tap(find.text('BLUEPRINTS'));
      await tester.pumpAndSettle();
      expect(find.text('RESERVE AUXILIARY HARDPOINT EXPANSION'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Settings fit compact130percent layout', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      largeTextApp(const Scaffold(body: SettingsDialog())),
    );
    await tester.pumpAndSettle();
    expect(find.text('115%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
