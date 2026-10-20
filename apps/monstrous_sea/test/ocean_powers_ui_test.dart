import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/shrine_screen.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/ocean_power_badges.dart';

import 'combat_flow_test.dart' show mountBattle;

GameController shrineController() {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(31)),
    autoSave: false,
  );
  controller.dispatch(const NameCaptain('Ahab'));
  controller.dispatch(const ChooseShip(ShipClass.standard));
  controller.session.phase = SessionPhase.shrine;
  controller.session.shrineManifestedPowers = [
    OceanPower.magmaVentLord,
    OceanPower.tempestSovereign,
  ];
  return controller;
}

Future<void> selectPower(WidgetTester tester, OceanPower power) async {
  final finder = find.byKey(ValueKey('select-${power.name}'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [360.0, 1200.0]) {
    testWidgets(
      'Battle exposes blessed hardpoints and status at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = shrineController();
        addTearDown(controller.dispose);
        controller.session.phase = SessionPhase.port;
        controller.dispatch(const VentureOutToSea());
        controller.ship!.blessings.addAll({
          HardpointType.broadside: const HardpointBlessing(
            power: OceanPower.magmaVentLord,
            slot: HardpointType.broadside,
            tier: 1,
          ),
          HardpointType.signature: const HardpointBlessing(
            power: OceanPower.tempestSovereign,
            slot: HardpointType.signature,
            tier: 2,
          ),
          HardpointType.utility: const HardpointBlessing(
            power: OceanPower.earthshakerTitan,
            slot: HardpointType.utility,
            tier: 3,
          ),
        });
        controller.ship!.basaltBarrierHp = 35;
        controller.ship!.basaltAegisTurns = 2;
        controller.currentMonster!.staticStacks = 2;
        controller.currentMonster!.corrodedStacks = 3;
        controller.currentMonster!.corrodedTurns = 2;
        await mountBattle(tester, controller);
        expect(find.byType(BlessingBadge), findsNWidgets(3));
        expect(find.text('Static Charge (2/3)'), findsOneWidget);
        expect(find.text('Corroded (3/3) · 2T'), findsOneWidget);
        expect(find.text('Basalt Barrier: 35 HP'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [360.0, 1200.0]) {
    testWidgets(
      'Shrine previews, switching, dedication locks and upgrade at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = shrineController();
        addTearDown(controller.dispose);
        controller.ship!.blessings.addAll({
          HardpointType.broadside: const HardpointBlessing(
            power: OceanPower.magmaVentLord,
            slot: HardpointType.broadside,
            tier: 1,
          ),
          HardpointType.signature: const HardpointBlessing(
            power: OceanPower.tempestSovereign,
            slot: HardpointType.signature,
            tier: 1,
          ),
          HardpointType.utility: const HardpointBlessing(
            power: OceanPower.magmaVentLord,
            slot: HardpointType.utility,
            tier: 3,
          ),
        });
        await tester.pumpWidget(
          MaterialApp(
            home: ShrineScreen(controller: controller, onOpenChart: () {}),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('hardpoint-broadside')), findsNothing);
        await selectPower(tester, OceanPower.magmaVentLord);
        expect(find.text('Weapon damage +10% → +20%'), findsOneWidget);
        expect(find.text('Dedicated to The Tempest Sovereign'), findsOneWidget);
        expect(find.text('Max Sovereign Tier Reached'), findsOneWidget);
        expect(
          tester
              .widget<InkButton>(find.byKey(const ValueKey('bless-signature')))
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<InkButton>(find.byKey(const ValueKey('bless-utility')))
              .onPressed,
          isNull,
        );
        await selectPower(tester, OceanPower.tempestSovereign);
        expect(find.text('Dedicated to The Magma Vent-Lord'), findsNWidgets(2));
        expect(
          tester
              .widget<InkButton>(find.byKey(const ValueKey('bless-signature')))
              .onPressed,
          isNotNull,
        );
        expect(controller.hasCommunedAtCurrentShrine, isFalse);
        await selectPower(tester, OceanPower.magmaVentLord);
        final upgrade = find.byKey(const ValueKey('bless-broadside'));
        await tester.ensureVisible(upgrade);
        await tester.tap(upgrade);
        await tester.pumpAndSettle();
        expect(controller.ship!.blessings[HardpointType.broadside]!.tier, 2);
        expect(find.text('COMMUNION COMPLETE'), findsOneWidget);
        expect(find.text('DEPART SHRINE & SET SAIL'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('An open socket previews Tier I and accepts the selected power', (
    tester,
  ) async {
    final controller = shrineController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ShrineScreen(controller: controller, onOpenChart: () {}),
      ),
    );
    await selectPower(tester, OceanPower.tempestSovereign);
    expect(find.text('Tier I'), findsNWidgets(3));
    final dedicate = find.byKey(const ValueKey('bless-utility'));
    await tester.ensureVisible(dedicate);
    await tester.tap(dedicate);
    await tester.pumpAndSettle();
    expect(
      controller.ship!.blessings[HardpointType.utility]!.power,
      OceanPower.tempestSovereign,
    );
    expect(controller.ship!.blessings[HardpointType.utility]!.tier, 1);
  });

  testWidgets('Runes remain available when no power can manifest', (
    tester,
  ) async {
    final controller = shrineController();
    addTearDown(controller.dispose);
    controller.session.shrineManifestedPowers = [];
    await tester.pumpWidget(
      MaterialApp(
        home: ShrineScreen(controller: controller, onOpenChart: () {}),
      ),
    );
    final runes = find.byKey(const ValueKey('read-runes'));
    await tester.ensureVisible(runes);
    await tester.tap(runes);
    await tester.pumpAndSettle();
    expect(controller.hasCommunedAtCurrentShrine, isTrue);
    expect(controller.gunneryAccuracyBoon, 10);
    expect(controller.ship!.blessings, isEmpty);
  });

  testWidgets('Combat blessing and status badges wrap in compact panels', (
    tester,
  ) async {
    final controller = shrineController();
    addTearDown(controller.dispose);
    controller.session.phase = SessionPhase.port;
    controller.dispatch(const VentureOutToSea());
    final monster = controller.currentMonster!;
    monster.staticStacks = 2;
    monster.corrodedStacks = 3;
    monster.corrodedTurns = 2;
    monster.isElectroJolted = true;
    monster.burnTurns = 3;
    monster.tremorAccPenalty = 15;
    final ship = controller.ship!;
    ship.basaltBarrierHp = 25;
    ship.basaltAegisTurns = 2;
    ship.stormRiggingTurns = 2;
    ship.boilingWakeTurns = 3;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              child: Column(
                children: [
                  const BlessingBadge(
                    blessing: HardpointBlessing(
                      power: OceanPower.tempestSovereign,
                      slot: HardpointType.signature,
                      tier: 2,
                    ),
                  ),
                  ShipPowerStatusBadges(ship: ship),
                  MonsterPowerStatusBadges(monster: monster),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Static Charge (2/3)'), findsOneWidget);
    expect(find.text('Corroded (3/3) · 2T'), findsOneWidget);
    expect(find.text('Basalt Barrier: 25 HP'), findsOneWidget);
    expect(find.textContaining('Tier II · Thunderclap Prow'), findsOneWidget);
    expect(find.text('Electro-Jolt (1T)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
