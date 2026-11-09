import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/merchant_screen.dart';
import 'package:monstrous_sea/src/screens/respite_island_screen.dart';
import 'package:monstrous_sea/src/screens/shrine_screen.dart';
import 'package:monstrous_sea/src/screens/stronghold_screen.dart';
import 'package:monstrous_sea/src/screens/smuggler_screen.dart';
import 'package:monstrous_sea/src/screens/loot_screen.dart';
import 'package:monstrous_sea/src/screens/shipwreck_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/svg_asset_view.dart';
import 'package:monstrous_sea/src/widgets/pilot_art.dart';
import 'package:monstrous_sea/src/widgets/hull_patch_kit_button.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'navigation_layout_matrix_test.dart' show shell;

enum EncounterCase {
  merchant,
  merchantFull,
  merchantPoor,
  merchantEmpty,
  materials,
  sellBelt,
  merchantInspect,
  haven,
  havenSpent,
  havenInspect,
  havenMax,
  cove,
  refit,
  repairsSpent,
  shrine,
  shrineCompare,
  shrineForbidden,
  shrineSovereign,
  shrineComplete,
  stronghold,
  strongholdMax,
  strongholdInspect,
  smuggler,
  smugglerGift,
  smugglerSell,
  smugglerArmory,
  lootFull,
  lootAvailable,
  wreckAssess,
  wreckReceipt,
}

GameController fixture(
  EncounterCase state, {
  BlueprintId blueprint = BlueprintId.standard,
  OceanPower power = OceanPower.magmaVentLord,
  int region = 1,
}) {
  final c = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Alexandrina Waverley-Montgomery'));
  c.session
    ..currentMonster = null
    ..hasDefeatedCurrentEncounter = true;
  c.session.activeBoon = state.name.startsWith('smuggler')
      ? BloodlineTrait.smugglersKin
      : BloodlineTrait.skilledCarpenter;
  c.session.activeQuirk = state == EncounterCase.shrineForbidden
      ? BloodlineTrait.superstitious
      : BloodlineTrait.exactingShipwright;
  final maxed = [
    EncounterCase.havenMax,
    EncounterCase.strongholdMax,
  ].contains(state);
  c.session.ship = createFlagshipFromBlueprint(
    blueprint,
    level: maxed ? 4 : 1,
    rng: SeededGameRng(10),
  );
  c.session.syncCaptainTraits();
  final ship = c.ship!;
  ship
    ..currentHp = 10
    ..gold = 77777;
  if ([EncounterCase.merchantPoor].contains(state)) ship.gold = 0;
  if (maxed) {
    for (final slot in blessingHardpoints) {
      ship.hardpointMarks[slot] = 3;
    }
    ship.currentHp = ship.maxHp;
  }
  c.seaChart.timesCompleted = region;
  c.seaChart.currentLeg = c.seaChart.midpointHavenLeg;
  ship.cargo.clear();
  final full = [
    EncounterCase.merchantFull,
    EncounterCase.sellBelt,
    EncounterCase.merchantInspect,
    EncounterCase.strongholdInspect,
    EncounterCase.smugglerGift,
    EncounterCase.smugglerSell,
    EncounterCase.smugglerArmory,
    EncounterCase.lootFull,
    EncounterCase.wreckReceipt,
  ].contains(state);
  if (full) {
    for (var i = 0; i < ship.maxCargo; i++) {
      ship.cargo.add(
        generateConsumable(
          [
            ConsumableType.hullPatchKit,
            ConsumableType.alchemicalPitch,
            ConsumableType.krakenInkBomb,
            ConsumableType.blastPack,
          ][i % 4],
          RarityLevel.common,
        ),
      );
    }
  } else {
    ship.cargo.add(
      generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
    );
  }
  final stock = [
    for (final type in ConsumableType.values)
      generateConsumable(type, RarityLevel.common),
  ];
  if (state.name.startsWith('merchant') ||
      [EncounterCase.materials, EncounterCase.sellBelt].contains(state)) {
    c.session
      ..phase = SessionPhase.merchant
      ..merchantReturnPhase = region == 0
          ? SessionPhase.helm
          : SessionPhase.stronghold
      ..merchantStock = state == EncounterCase.merchantEmpty ? [] : stock
      ..onSaleMerchantIndex = 0
      ..merchantMaterials = MaterialShipment(
        id: 'audit-shop',
        seaGlass: 4,
        depthWroughtIron: 2,
      );
    if (region == 0) {
      c.seaChart.currentDestination = CourseDestination.specialistMerchant;
    }
  } else if (state.name.startsWith('shrine')) {
    c.session
      ..phase = SessionPhase.shrine
      ..currentShrineName = 'The Sunken Sanctuary of the Brinemother'
      ..shrineManifestedPowers = [
        power,
        OceanPower.values.firstWhere((p) => p != power),
      ];
    if (state == EncounterCase.shrineCompare) {
      ship.blessings[HardpointType.broadside] = HardpointBlessing(
        power: power,
        slot: HardpointType.broadside,
        tier: 2,
      );
      ship.blessings[HardpointType.signature] = HardpointBlessing(
        power: OceanPower.values.firstWhere((p) => p != power),
        slot: HardpointType.signature,
        tier: 2,
      );
    }
    if (state == EncounterCase.shrineSovereign) {
      for (final slot in blessingHardpoints) {
        ship.blessings[slot] = HardpointBlessing(
          power: power,
          slot: slot,
          tier: 3,
        );
      }
      c.session.shrineManifestedPowers = [];
    }
    c.session.hasCommunedAtCurrentShrine =
        state == EncounterCase.shrineComplete;
  } else if (state.name.startsWith('stronghold')) {
    c.session.phase = SessionPhase.stronghold;
  } else if (state.name.startsWith('smuggler')) {
    c.session
      ..phase = SessionPhase.smuggler
      ..smugglerStock = stock
      ..currentSmugglerName = 'The Lantern of the Drowned Mariner'
      ..smugglerMaterials = MaterialShipment(
        id: 'audit-ketch',
        seaGlass: 2,
        depthWroughtIron: 1,
      );
  } else if (state.name.startsWith('loot')) {
    c.session
      ..phase = SessionPhase.loot
      ..pendingLoot = stock
      ..lastGoldSalvaged = 125;
  } else if (state.name.startsWith('wreck')) {
    c.session
      ..phase = SessionPhase.shipwreck
      ..currentShipwreckName = 'The Shattered Crown of the Eastern Passage'
      ..currentWreck = WreckEncounter(
        id: 'audit-wreck',
        sighting: const WreckSighting(
          seed: 1,
          condition: WreckCondition.uncertain,
          clearClue: true,
        ),
        stage: state == EncounterCase.wreckReceipt
            ? WreckStage.receipt
            : WreckStage.assessment,
      )
      ..pendingLoot = state == EncounterCase.wreckReceipt ? stock : []
      ..wreckSalvageReceipt = [
        '2 Sea Glass · 1 Depth-Wrought Iron',
        'Recovered supplies from the flooded holds.',
      ];
  } else {
    c.session
      ..phase = SessionPhase.respiteIsland
      ..currentIslandName = 'Cormorant Sanctuary of the Western Shoals';
    c.seaChart.currentDestination = state == EncounterCase.cove
        ? CourseDestination.ordinary
        : state == EncounterCase.refit
        ? CourseDestination.repairRefit
        : CourseDestination.midpointHaven;
    if (state == EncounterCase.havenSpent) {
      c.session.hasDrilledAtCurrentIsland = true;
      c.session.shoreDrillBoon = 10;
    }
    if (state == EncounterCase.repairsSpent) {
      c.dispatch(const RepairShip(1));
    }
  }
  return c;
}

Widget screen(GameController c) => switch (c.phase) {
  SessionPhase.merchant => MerchantScreen(controller: c),
  SessionPhase.shrine => ShrineScreen(controller: c, onOpenChart: () {}),
  SessionPhase.stronghold => StrongholdScreen(
    controller: c,
    onOpenChart: () {},
  ),
  SessionPhase.smuggler => SmugglerScreen(controller: c, onOpenChart: () {}),
  SessionPhase.loot => LootScreen(controller: c),
  SessionPhase.shipwreck => ShipwreckScreen(controller: c, onOpenChart: () {}),
  _ => RespiteIslandScreen(controller: c, onOpenChart: () {}),
};

String snapshot(GameController c) => jsonEncode({
  'ship': c.ship!.toJson(),
  'profile': c.profile.toJson(),
  'chart': c.seaChart.toJson(),
  'repair': c.session.paidRepairWork.toJson(),
  'stock': c.session.merchantStock.map((i) => i.toJson()).toList(),
  'pending': c.pendingLoot.map((i) => i.toJson()).toList(),
});

Future<void> auditButtons(WidgetTester tester, {Finder? scope}) async {
  final targets =
      (scope == null
              ? find.byType(InkButton)
              : find.descendant(of: scope, matching: find.byType(InkButton)))
          .evaluate()
          .toList();
  expect(targets, isNotEmpty);
  for (final element in targets) {
    if (!element.mounted) continue;
    final target = find.byElementPredicate((e) => identical(e, element));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    expect(
      target.hitTestable(),
      findsOneWidget,
      reason: (element.widget as InkButton).label,
    );
    final rect = tester.getRect(target);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(size.width));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(size.height));
    if (!InkTheme.disableGoogleFonts) {
      for (final node
          in find
              .descendant(of: target, matching: find.byType(RichText))
              .evaluate()) {
        expect(
          (node.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
          reason:
              'Action label clipped: ${(element.widget as InkButton).label}',
        );
      }
    }
    expect(tester.takeException(), isNull);
  }
}

Future<void> review(
  WidgetTester tester,
  EncounterCase state,
  Size size, {
  double scale = 1.15,
  BlueprintId blueprint = BlueprintId.standard,
  OceanPower power = OceanPower.magmaVentLord,
  bool capture = false,
  int region = 1,
}) async {
  final c = fixture(state, blueprint: blueprint, power: power, region: region);
  addTearDown(c.dispose);
  final before = snapshot(c);
  final key = GlobalKey();
  await mountChartFocus(tester, shell(c, screen(c)), key, size, scale: scale);
  expect(tester.takeException(), isNull);
  if ([EncounterCase.materials, EncounterCase.sellBelt].contains(state)) {
    final tab = find.byKey(
      ValueKey('merchant-tab-${state == EncounterCase.materials ? 1 : 2}'),
    );
    await tester.ensureVisible(tab);
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }
  if (state == EncounterCase.smugglerSell) {
    final tab = find.widgetWithText(
      InkButton,
      size.width < 600
          ? 'SELL BELT (${c.ship!.cargo.length})'
          : 'SELL FROM BELT (${c.ship!.cargo.length})',
    );
    await tester.ensureVisible(tab);
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }
  if ([
    EncounterCase.shrine,
    EncounterCase.shrineCompare,
    EncounterCase.shrineForbidden,
  ].contains(state)) {
    final choice = c.shrineManifestedPowers.firstWhere(
      (p) => p != c.forbiddenShrinePower,
    );
    final button = find.byKey(ValueKey('select-${choice.name}'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }
  if (state == EncounterCase.smugglerArmory) {
    final button = find.widgetWithText(InkButton, 'MANAGE ARMORY');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }
  if (state == EncounterCase.havenInspect) {
    final button = find.widgetWithText(InkButton, 'INSPECT VESSEL');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }
  final proofName =
      '${state.name}-${size.width.toInt()}-$scale-${blueprint.name}';
  Future<void> proof(String suffix) async {
    await tester.runAsync(() async {
      final paths = <String>{
        PilotArt.helm,
        PilotArt.portHaven,
        PilotArt.anchor,
        PilotArt.cannons,
        for (final item in [
          ...c.ship!.cargo,
          ...c.session.merchantStock,
          ...c.session.smugglerStock,
          ...c.pendingLoot,
        ])
          SvgAssetView.pathForItem(item),
      };
      for (final path in paths.where((p) => p.endsWith('.png'))) {
        await precacheImage(AssetImage(path), key.currentContext!);
      }
    });
    await captureChartFocusProof(tester, key, '$proofName-$suffix');
  }

  if (capture) {
    final focus = switch (state) {
      EncounterCase.merchantFull => c.session.merchantStock.first.name,
      EncounterCase.materials => 'PERMANENT MATERIALS',
      EncounterCase.haven => 'SHORE DUTY · CHOOSE ONE',
      EncounterCase.shrineCompare => '2 · DEDICATE A FITTING',
      EncounterCase.lootAvailable => c.pendingLoot.first.name,
      _ => null,
    };
    if (focus != null) {
      await tester.ensureVisible(find.text(focus).first);
      await tester.pumpAndSettle();
    }
    await proof('content');
  }
  await auditButtons(tester);
  if (state == EncounterCase.lootAvailable && size.width < 600) {
    final kit = find.byWidgetPredicate(
      (w) => w is HullPatchKitButton && w.itemId == c.ship!.cargo.first.id,
    );
    final jettison = find.byWidgetPredicate(
      (w) =>
          w is InkButton &&
          w.semanticLabel ==
              'Jettison ${c.ship!.cargo.first.name} into the sea',
    );
    expect(
      tester.getTopLeft(jettison).dy - tester.getBottomLeft(kit).dy,
      greaterThanOrEqualTo(7.99),
      reason: 'Keep patch and jettison actions separated.',
    );
  }
  if ([
    EncounterCase.merchantInspect,
    EncounterCase.strongholdInspect,
  ].contains(state)) {
    final button = find.widgetWithText(InkButton, 'INSPECT VESSEL');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await auditButtons(tester, scope: find.byType(Dialog));
  }
  if (capture) await proof('controls');
  expect(
    snapshot(c),
    before,
    reason: 'Reviewing controls must not spend supplies, money or repairs.',
  );
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );
  for (final state in EncounterCase.values) {
    for (final size in [
      const Size(360, 900),
      const Size(800, 480),
      const Size(1280, 850),
    ]) {
      testWidgets('115% ${state.name} at $size', (tester) async {
        await review(
          tester,
          state,
          size,
          capture:
              size.width != 800 &&
              [
                EncounterCase.merchantFull,
                EncounterCase.materials,
                EncounterCase.haven,
                EncounterCase.shrineCompare,
                EncounterCase.strongholdInspect,
                EncounterCase.lootAvailable,
              ].contains(state),
        );
      });
    }
  }
  for (final blueprint in BlueprintId.values) {
    for (final state in [
      EncounterCase.havenMax,
      EncounterCase.strongholdInspect,
      EncounterCase.shrineCompare,
    ]) {
      for (final width in [360.0, 1280.0]) {
        testWidgets('115% ${blueprint.name} ${state.name} at $width', (
          tester,
        ) async {
          await review(tester, state, Size(width, 900), blueprint: blueprint);
        });
      }
    }
  }
  for (final power in OceanPower.values) {
    for (final width in [360.0, 800.0, 1280.0]) {
      testWidgets('115% shrine ${power.name} comparison at $width', (
        tester,
      ) async {
        await review(
          tester,
          EncounterCase.shrineCompare,
          Size(width, 900),
          power: power,
        );
      });
    }
  }
  for (final state in [
    EncounterCase.merchantFull,
    EncounterCase.materials,
    EncounterCase.havenMax,
    EncounterCase.shrineCompare,
    EncounterCase.shrineForbidden,
    EncounterCase.strongholdInspect,
    EncounterCase.smugglerGift,
    EncounterCase.lootFull,
    EncounterCase.lootAvailable,
    EncounterCase.wreckReceipt,
  ]) {
    for (final width in [360.0, 1280.0]) {
      testWidgets('130% ${state.name} at $width', (tester) async {
        await review(tester, state, Size(width, 900), scale: 1.3);
      });
    }
  }
  for (final region in [0, 2]) {
    for (final state in [
      EncounterCase.merchant,
      EncounterCase.haven,
      EncounterCase.shrineForbidden,
    ]) {
      for (final width in [360.0, 1280.0]) {
        testWidgets('115% region $region ${state.name} at $width', (
          tester,
        ) async {
          await review(tester, state, Size(width, 900), region: region);
        });
      }
    }
  }
  for (final width in [360.0, 1280.0]) {
    testWidgets('115% Iron Bastion inspection at $width', (tester) async {
      await review(
        tester,
        EncounterCase.strongholdInspect,
        Size(width, 900),
        region: 2,
      );
    });
  }
}
