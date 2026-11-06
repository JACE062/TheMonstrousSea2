import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/merchant_screen.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';
import 'package:monstrous_sea/src/screens/stronghold_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/hull_gauge.dart';
import 'package:monstrous_sea/src/widgets/nautical_chart.dart';
import 'package:monstrous_sea/src/widgets/svg_asset_view.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'stronghold_flow_test.dart' show atStronghold;

GameController berthed(int region) {
  final c = atStronghold(region: region - 1);
  final json = c.seaChart.toJson();
  final original = Map<String, dynamic>.from((json['voyageLog'] as List).first);
  json['voyageLog'] = [
    for (var r = 0; r < region; r++)
      {
        ...original,
        'leg': 11 + r * 2,
        'regionIndex': r,
        'bearing': NavigationalBearing.deadAhead.name,
        'monsterSpecies':
            (r == 0 ? MonsterSpecies.kraken : MonsterSpecies.serpent).name,
        'combatWon': true,
        'destination': CourseDestination.titan.name,
      },
  ];
  c.seaChart.restoreFromJson(json);
  return c;
}

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );
  for (final width in [360.0, 1920.0]) {
    testWidgets(
      'merchant tabs trade and inspect without losing stock at $width',
      (tester) async {
        final c = GameController(
          session: GameSession(rng: SeededGameRng(14)),
          autoSave: false,
        )..dispatch(const BeginFirstVoyage('Chandler'));
        addTearDown(c.dispose);
        c.session.phase = SessionPhase.restArea;
        c.seaChart.currentLeg = c.seaChart.totalLegs - 1;
        c.dispatch(const TakeHelm());
        c.dispatch(const SteerCourse(NavigationalBearing.starboardTack));
        expect(c.phase, SessionPhase.merchant);
        c.ship!.gold = 200;
        c.ship!.currentHp = 40;
        c.session.merchantStock = [
          generateConsumable(ConsumableType.blastPack, RarityLevel.common),
        ];
        c.session.onSaleMerchantIndex = -1;
        c.ship!.cargo.clear();
        final key = GlobalKey();
        await mountChartFocus(
          tester,
          MerchantScreen(controller: c),
          key,
          Size(width, 1080),
          scale: 1.15,
        );
        final before = c.seaChart.toJson();
        await tester.tap(find.text('INSPECT VESSEL'));
        await tester.pumpAndSettle();
        expect(find.text('SHIP FITTINGS & TACTICAL BELT'), findsOneWidget);
        c.ship!.applyDamage(3);
        c.notify();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<HullGauge>(
                find.descendant(
                  of: find.byType(Dialog),
                  matching: find.byType(HullGauge),
                ),
              )
              .currentHp,
          37,
        );
        await tester.tap(find.text('CLOSE INSPECTION'));
        await tester.pumpAndSettle();
        Future<void> tab(int n) async {
          final button = find.byKey(ValueKey('merchant-tab-$n'));
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
        }

        expect(find.text('PERMANENT MATERIALS'), findsNothing);
        final buy = find.text('BUY');
        await tester.ensureVisible(buy);
        if (const String.fromEnvironment('mapFocusProofPath').isNotEmpty) {
          await tester.runAsync(
            () => precacheImage(
              AssetImage(
                SvgAssetView.pathForItem(c.session.merchantStock.first),
              ),
              key.currentContext!,
            ),
          );
          await captureChartFocusProof(
            tester,
            key,
            'merchant-stock-${width.toInt()}',
          );
        }
        await tester.tap(buy);
        await tester.pumpAndSettle();
        expect(c.ship!.cargo, hasLength(1));
        expect(c.session.merchantStock, isEmpty);
        await tab(2);
        await tester.ensureVisible(find.text('SELL'));
        await tester.tap(find.text('SELL'));
        await tester.pumpAndSettle();
        expect(c.ship!.cargo, isEmpty);
        await tab(1);
        final shipment = c.session.currentMaterialShipment!;
        final quantity = shipment.seaGlass;
        final button = find.byKey(const ValueKey('buy-material-seaGlass'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(shipment.seaGlass, quantity - 1);
        await tab(0);
        await tab(1);
        expect(c.session.currentMaterialShipment!.seaGlass, quantity - 1);
        expect(c.seaChart.toJson(), before);
        await captureChartFocusProof(
          tester,
          key,
          'merchant-materials-${width.toInt()}',
        );
        await tab(0);
        await tester.ensureVisible(find.text('INSPECT VESSEL'));
        await captureChartFocusProof(tester, key, 'merchant-${width.toInt()}');
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final region in [1, 2]) {
    testWidgets(
      'vessel berths at stronghold $region and history stays immutable',
      (tester) async {
        final c = berthed(region);
        addTearDown(c.dispose);
        final before = c.seaChart.toJson();
        final key = GlobalKey();
        await mountChartFocus(
          tester,
          SeaChartScreen(
            seaChart: c.seaChart,
            ship: c.ship,
            isInPort: true,
            onClose: () {},
          ),
          key,
          const Size(1920, 1080),
          scale: 1.15,
        );
        final map = find.byKey(const ValueKey('nautical-map-viewport'));
        expect(tester.getSize(map).width, greaterThan(1800));
        expect(tester.getSize(map).height, greaterThan(800));
        expect(find.textContaining('Midpoint choice'), findsNothing);
        final port = tester.getCenter(
          find.byKey(ValueKey('chart-port-$region')),
        );
        final vessel = tester.getCenter(
          find.byKey(const ValueKey('chart-current-vessel')),
        );
        final scale = tester
            .widget<InteractiveViewer>(map)
            .transformationController!
            .value
            .getMaxScaleOnAxis();
        expect(vessel.dx, closeTo(port.dx, .01));
        expect(vessel.dy + 23 * scale, closeTo(port.dy, .01));
        final battle = tester.getCenter(
          find.byKey(ValueKey('voyage-marker-${region - 1}')),
        );
        expect(port.dx, greaterThan(battle.dx));
        expect(find.byKey(const ValueKey('chart-port-1')), findsOneWidget);
        await tester.drag(map, const Offset(60, -50));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('locate-chart-vessel')));
        await tester.pumpAndSettle();
        await captureChartFocusProof(tester, key, 'stronghold-chart-$region');
        tester.view.physicalSize = const Size(360, 1000);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('locate-chart-vessel')));
        await tester.pumpAndSettle();
        expect(
          tester
              .getRect(find.byKey(ValueKey('chart-port-$region')))
              .overlaps(tester.getRect(map)),
          isTrue,
        );
        expect(tester.getSize(map).height, greaterThan(400));
        await captureChartFocusProof(
          tester,
          key,
          'stronghold-chart-$region-compact',
        );
        await tester.tap(find.text('VOYAGE LOG'));
        await tester.pumpAndSettle();
        expect(find.text('VICTORY'), findsNWidgets(region));
        await tester.tap(find.text('CLOSE LOGBOOK'));
        await tester.pumpAndSettle();
        // The same berth remains the starting point after departing the stronghold.
        final geometry = NauticalRouteGeometry(
          c.seaChart.voyageLog,
          regionIndex: region,
        );
        expect(geometry.ports.last.position, geometry.currentPosition);
        expect(c.seaChart.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('stronghold uses the shared inspection action', (tester) async {
    final c = berthed(1);
    addTearDown(c.dispose);
    final key = GlobalKey();
    await mountChartFocus(
      tester,
      StrongholdScreen(controller: c, onOpenChart: () {}),
      key,
      const Size(1280, 1100),
    );
    expect(find.text('SHIP FITTINGS & BELT INSPECTION'), findsNothing);
    await tester.ensureVisible(find.text('INSPECT VESSEL'));
    await tester.tap(find.text('INSPECT VESSEL'));
    await tester.pumpAndSettle();
    expect(find.text('SHIP FITTINGS & TACTICAL BELT'), findsOneWidget);
    await captureChartFocusProof(tester, key, 'stronghold-inspection');
    await tester.tap(find.text('CLOSE INSPECTION'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('FORT KRAKENWATCH'));
    await captureChartFocusProof(tester, key, 'stronghold-controls');
    expect(c.phase, SessionPhase.stronghold);
    expect(tester.takeException(), isNull);
  });
}
