import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';
import 'package:monstrous_sea/src/widgets/armory_view.dart';
import 'package:monstrous_sea/src/widgets/utility_description.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/screens/shrine_screen.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;

Future<void> mount(
  WidgetTester tester,
  Widget child,
  GlobalKey key,
  double width,
) => mountChartFocus(
  tester,
  Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 600, child: child),
      ),
    ),
  ),
  key,
  Size(width, 900),
  scale: 1.3,
);

void main() {
  for (final width in [360.0, 1280.0]) {
    testWidgets('prospective Burning values and nested help at $width', (
      tester,
    ) async {
      final ship = createFlagshipFromBlueprint(
        BlueprintId.standard,
        level: 1,
        rng: SeededGameRng(1),
      );
      const preview = HardpointBlessing(
        power: OceanPower.magmaVentLord,
        slot: HardpointType.broadside,
        tier: 3,
      );
      final key = GlobalKey();
      await mount(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MechanicText(
              preview.description,
              mechanics: MechanicContext(
                ship: ship,
                blessing: preview,
                regionIndex: 2,
              ),
            ),
            MechanicText(
              'Applies Static Charge.',
              mechanics: MechanicContext(ship: ship),
            ),
          ],
        ),
        key,
        width,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Ignites')));
      await tester.pumpAndSettle();
      expect(find.textContaining('18 Fire damage per turn'), findsOneWidget);
      await captureChartFocusProof(tester, key, 'burning-$width');
      await mouse.moveTo(const Offset(10, 880));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await mouse.moveTo(tester.getCenter(find.text('Static Charge')));
      await tester.pumpAndSettle();
      await mouse.moveTo(tester.getCenter(find.text('Arc Discharge')));
      await tester.pumpAndSettle();
      await mouse.moveTo(
        tester.getCenter(
          find.byKey(const ValueKey('mechanic-help-Arc Discharge')),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byKey(const ValueKey('mechanic-help-Static Charge')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mechanic-help-Arc Discharge')),
        findsOneWidget,
      );
      await captureChartFocusProof(tester, key, 'nested-$width');
      if (width == 1280) {
        expect(
          tester
              .getRect(
                find.byKey(const ValueKey('mechanic-help-Static Charge')),
              )
              .overlaps(
                tester.getRect(
                  find.byKey(const ValueKey('mechanic-help-Arc Discharge')),
                ),
              ),
          isFalse,
        );
      }
      for (final name in ['Static Charge', 'Arc Discharge']) {
        final rect = tester.getRect(
          find.byKey(ValueKey('mechanic-help-$name')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
        expect(rect.bottom, lessThanOrEqualTo(900));
      }
      expect(ship.blessings, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('keywords support keyboard, Escape and touch dismissal', (
    tester,
  ) async {
    final key = GlobalKey();
    await mount(
      tester,
      const MechanicText('Critical Hit chance. Carapace.'),
      key,
      360,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mechanic-help-Critical Hits')),
      findsOneWidget,
    );
    await captureChartFocusProof(tester, key, 'critical-360');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mechanic-help-Critical Hits')),
      findsNothing,
    );
    await tester.longPress(find.text('Carapace'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mechanic-help-Carapace')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(355, 890));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mechanic-help-Carapace')), findsNothing);
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel('Critical Hits. Show explanation'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'action help opens by long press without dispatching its action',
    (tester) async {
      var presses = 0;
      final key = GlobalKey();
      await mount(
        tester,
        MechanicTooltip(
          message: 'Illuminates the beast for 2 turns.',
          child: InkButton(label: 'FLARE', onPressed: () => presses++),
        ),
        key,
        360,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('mechanic-help-action')),
        findsOneWidget,
      );
      expect(presses, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.longPress(find.text('FLARE'));
      await tester.pumpAndSettle();
      expect(presses, 0);
      await tester.tap(find.text('Illuminates'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('mechanic-help-Illuminated')),
        findsOneWidget,
      );
      await captureChartFocusProof(tester, key, 'illuminated-360');
      expect(presses, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  test('prospective help preserves current builds and uses their highest power tier', () {
    final ship =
        createFlagshipFromBlueprint(BlueprintId.standard, rng: SeededGameRng(2))
          ..blessings[HardpointType.signature] = const HardpointBlessing(
            power: OceanPower.magmaVentLord,
            slot: HardpointType.signature,
            tier: 3,
          );
    final before = ship.toJson();
    final monster = createMonster(
      MonsterSpecies.shark,
      level: 1,
      rng: SeededGameRng(3),
    )..tremorAccPenalty = 10;
    const lowerMagma = HardpointBlessing(
      power: OceanPower.magmaVentLord,
      slot: HardpointType.broadside,
      tier: 1,
    );
    const brine = HardpointBlessing(
      power: OceanPower.brinemother,
      slot: HardpointType.broadside,
      tier: 3,
    );
    const earth = HardpointBlessing(
      power: OceanPower.earthshakerTitan,
      slot: HardpointType.broadside,
      tier: 3,
    );
    final data = MechanicContext(ship: ship, monster: monster);
    expect(
      data.withBlessing(lowerMagma).explanation('Burning'),
      contains('15 Fire damage'),
    );
    expect(data.withBlessing(brine).explanation('Corroded'), contains('12%'));
    expect(data.withBlessing(earth).explanation('Shaken'), contains('20%'));
    expect(data.explanation('Shaken'), contains('10%'));
    const earthUtility = HardpointBlessing(
      power: OceanPower.earthshakerTitan,
      slot: HardpointType.utility,
      tier: 3,
    );
    expect(
      data.withBlessing(earthUtility).explanation('Shaken'),
      contains('10%'),
    );
    ship.blessings[HardpointType.broadside] = const HardpointBlessing(
      power: OceanPower.earthshakerTitan,
      slot: HardpointType.broadside,
      tier: 1,
    );
    expect(
      MechanicContext(ship: ship, blessing: earthUtility).explanation('Shaken'),
      contains('10%'),
    );
    ship.blessings.remove(HardpointType.broadside);
    expect(ship.toJson(), before);
    expect(monster.tremorAccPenalty, 10);
  });

  testWidgets(
    'home retains Flare stats and inspection links scaled Illuminated',
    (tester) async {
      final controller =
          GameController(
              session: GameSession(
                rng: SeededGameRng(4),
                profile: ProfileData(
                  unlockedBlueprints: {BlueprintId.bombardier.name},
                ),
              ),
              autoSave: false,
            )
            ..dispatch(const NameCaptain('Keyword review'))
            ..dispatch(const ChooseShip(ShipClass.bombardier));
      addTearDown(controller.dispose);
      final key = GlobalKey();
      await mount(
        tester,
        PortScreen(controller: controller, onOpenChart: () {}),
        key,
        1280,
      );
      await tester.ensureVisible(find.text('BLUEPRINTS'));
      await tester.tap(find.text('BLUEPRINTS'));
      await tester.pumpAndSettle();
      final details = find.byWidgetPredicate(
        (w) =>
            w is MechanicText &&
            w.text == spotterFlareDescription(detailed: true),
      );
      expect(details, findsOneWidget);
      await tester.ensureVisible(details);
      await tester.pumpAndSettle();
      await captureChartFocusProof(tester, key, 'home-flare-stats');
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      controller.ship!.hardpointMarks[HardpointType.utility] = 3;
      await mount(
        tester,
        SingleChildScrollView(child: ArmoryView(controller: controller)),
        key,
        1280,
      );
      final normal = find.byWidgetPredicate(
        (w) => w is MechanicText && w.text == spotterFlareDescription(),
      );
      expect(normal, findsOneWidget);
      await tester.ensureVisible(normal);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Illuminates'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is MechanicText &&
              w.text.contains('+21% shot accuracy') &&
              w.text.contains('+35% Blast'),
        ),
        findsOneWidget,
      );
      await captureChartFocusProof(tester, key, 'inspection-flare-scaled');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'shrine comparison exposes exact Burning damage before choosing',
    (tester) async {
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(5)),
        autoSave: false,
      )..dispatch(const BeginFirstVoyage('Shrine reader'));
      addTearDown(controller.dispose);
      controller.seaChart.advanceRegion(controller.session.rng);
      controller.seaChart.advanceRegion(controller.session.rng);
      controller.session.phase = SessionPhase.shrine;
      controller.session.shrineManifestedPowers = [
        OceanPower.magmaVentLord,
        OceanPower.brinemother,
      ];
      controller.ship!.blessings[HardpointType.signature] =
          const HardpointBlessing(
            power: OceanPower.magmaVentLord,
            slot: HardpointType.signature,
            tier: 2,
          );
      final before = controller.ship!.toJson();
      final key = GlobalKey();
      await mount(
        tester,
        ShrineScreen(controller: controller, onOpenChart: () {}),
        key,
        1280,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('select-magmaVentLord')),
      );
      await tester.tap(find.byKey(const ValueKey('select-magmaVentLord')));
      await tester.pumpAndSettle();
      final keyword = find.descendant(
        of: find.byKey(const ValueKey('hardpoint-broadside')),
        matching: find.text('Burning'),
      ).first;
      await tester.ensureVisible(keyword);
      await tester.tap(keyword);
      await tester.pumpAndSettle();
      expect(find.textContaining('12 Fire damage per turn'), findsOneWidget);
      expect(controller.ship!.toJson(), before);
      expect(controller.hasCommunedAtCurrentShrine, isFalse);
      await captureChartFocusProof(tester, key, 'shrine-comparison');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
