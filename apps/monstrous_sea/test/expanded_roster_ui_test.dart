import 'package:flame/components.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/screens/shrine_screen.dart';
import 'package:monstrous_sea/src/screens/smuggler_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/armory_view.dart';

import 'combat_flow_test.dart' show mountBattle;

const reviewFont = String.fromEnvironment('reviewFontPath');
final captureKey = GlobalKey();

Future<void> capture(WidgetTester tester, String name) async {
  if (reviewFont.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.dart_tool/roster-review/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

GameController captain({BloodlineTrait? boon, BloodlineTrait? quirk}) {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(31)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Roster Test'));
  controller.session.activeBoon = boon;
  controller.session.activeQuirk = quirk;
  return controller;
}

Widget page(Widget child, double scale) => RepaintBoundary(
  key: captureKey,
  child: MaterialApp(
    theme: InkTheme.themeData.copyWith(
      textTheme: InkTheme.themeData.textTheme.apply(
        fontFamily: reviewFont.isEmpty ? null : 'RosterReview',
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  ),
);

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (reviewFont.isNotEmpty) {
      final loader = FontLoader('RosterReview')
        ..addFont(File(reviewFont).readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
  });
  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('smuggler gift and healing quote at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = captain(
          boon: BloodlineTrait.smugglersKin,
          quirk: BloodlineTrait.exactingShipwright,
        );
        addTearDown(controller.dispose);
        controller.session.phase = SessionPhase.smuggler;
        controller.ship!.currentHp = controller.ship!.maxHp ~/ 2;
        controller.session.smugglerStock = [
          generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
          generateConsumable(ConsumableType.krakenInkBomb, RarityLevel.common),
        ];
        controller.ship!.cargo.clear();
        await tester.pumpWidget(
          page(
            SmugglerScreen(controller: controller, onOpenChart: () {}),
            scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'SEASONED OAK PLANKS (+${controller.repairHpFor(0.25)} HP)',
          ),
          findsOneWidget,
        );
        expect(
          find.text('REPAIR (${controller.repairCostFor(0.25)}g)'),
          findsOneWidget,
        );
        while (controller.ship!.cargo.length < controller.ship!.maxCargo) {
          controller.ship!.cargo.add(
            generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
          );
        }
        controller.notify();
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Belt full. Free gift remains unclaimed.'),
          findsOneWidget,
        );
        final gift = find.byKey(const ValueKey('smuggler-gift-0'));
        expect(tester.widget<InkButton>(gift).onPressed, isNull);
        expect(controller.hasClaimedSmugglerGift, isFalse);
        await tester.ensureVisible(gift);
        await tester.pumpAndSettle();
        await capture(tester, 'smuggler-$width-$scale');
        controller.ship!.cargo.removeLast();
        controller.notify();
        await tester.pumpAndSettle();
        final gold = controller.ship!.gold;
        tester.widget<InkButton>(gift).onPressed!();
        await tester.pumpAndSettle();
        expect(controller.hasClaimedSmugglerGift, isTrue);
        expect(controller.ship!.gold, gold);
        expect(find.text('FREE GIFT'), findsNothing);
        expect(
          find.textContaining('Gift claimed for this visit.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
      testWidgets(
        'shrine omen keeps the other power and runes available at $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = captain(quirk: BloodlineTrait.superstitious);
          addTearDown(controller.dispose);
          controller.session.phase = SessionPhase.shrine;
          controller.session.shrineManifestedPowers = [
            OceanPower.magmaVentLord,
            OceanPower.tempestSovereign,
          ];
          await tester.pumpWidget(
            page(
              ShrineScreen(controller: controller, onOpenChart: () {}),
              scale,
            ),
          );
          await tester.pumpAndSettle();
          final blocked = controller.forbiddenShrinePower!;
          expect(
            tester
                .widget<InkButton>(
                  find.byKey(ValueKey('select-${blocked.name}')),
                )
                .onPressed,
            isNull,
          );
          expect(find.textContaining('ILL OMEN'), findsOneWidget);
          await tester.ensureVisible(find.textContaining('ILL OMEN'));
          await tester.pumpAndSettle();
          await capture(tester, 'shrine-$width-$scale');
          final allowed = controller.shrineManifestedPowers.firstWhere(
            (power) => power != blocked,
          );
          tester
              .widget<InkButton>(find.byKey(ValueKey('select-${allowed.name}')))
              .onPressed!();
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<InkButton>(
                  find.byKey(const ValueKey('bless-broadside')),
                )
                .onPressed,
            isNotNull,
          );
          expect(
            tester
                .widget<InkButton>(find.byKey(const ValueKey('read-runes')))
                .onPressed,
            isNotNull,
          );
          controller.session.shrineManifestedPowers = [blocked];
          controller.notify();
          await tester.pumpAndSettle();
          expect(controller.forbiddenShrinePower, isNull);
          expect(
            tester
                .widget<InkButton>(
                  find.byKey(ValueKey('select-${blocked.name}')),
                )
                .onPressed,
            isNotNull,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('Impatient explains pending and offers grappled recovery Brace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = captain(quirk: BloodlineTrait.impatient);
    addTearDown(controller.dispose);
    await mountBattle(tester, controller);
    expect(find.byKey(const ValueKey('impatient-combination')), findsOneWidget);
    controller.dispatch(const ExecuteShipSpecialAction(borrowNextAction: true));
    await tester.pump();
    expect(find.textContaining('Fire one weapon next.'), findsOneWidget);
    expect(find.byKey(const ValueKey('emergency-pass')), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is InkButton &&
            (w.semanticLabel?.contains('utility hardpoint') ?? false) &&
            w.onPressed != null,
      ),
      findsNothing,
    );
    controller.currentMonster!.currentHp = 1000;
    controller.dispatch(
      FireWeaponVolley(controller.ship!.equippedWeaponTypes.first),
    );
    expect(controller.isImpatientCombinationPending, isFalse);
    expect(controller.isImpatientRecovering, isTrue);
    controller.ship!.isGrappled = true;
    controller.notify();
    await tester.pump();
    expect(find.textContaining('Hardpoints unavailable.'), findsOneWidget);
    expect(
      tester
          .widget<InkButton>(find.byKey(const ValueKey('emergency-pass')))
          .onPressed,
      isNotNull,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is InkButton &&
            (w.semanticLabel?.startsWith('Fire ') ?? false) &&
            w.onPressed != null,
      ),
      findsNothing,
    );
    controller.dispatch(const BraceForImpact());
    expect(controller.isImpatientRecovering, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Skirmisher previews a shot before helm movement and exposes Brace',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = captain(quirk: BloodlineTrait.skirmisher);
      addTearDown(controller.dispose);
      controller.session.combatRange = CombatRange.long;
      controller.currentMonster!.currentIntent = MonsterIntent.fromId(
        MonsterIntentId.crustaceanBrineJet,
      );
      await mountBattle(tester, controller);
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label?.startsWith('Helm Order: Advance') ?? false),
        ),
      );
      await tester.pump();
      expect(controller.combatRange, CombatRange.long);
      final responsePreview = controller.currentMonster!.currentIntent!
          .evaluatePreview(
            currentRange: CombatRange.long,
            selectedHelmOrder: HelmOrder.advance,
          );
      expect(responsePreview.playerPostHelmRange, CombatRange.medium);
      expect(find.text(responsePreview.summaryBadge), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is InkButton &&
              (w.semanticLabel?.contains('volley at Long') ?? false),
        ),
        findsWidgets,
      );
      expect(
        find.textContaining('then maneuver before the response.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('late-helm-hint')), findsOneWidget);
      expect(find.byKey(const ValueKey('emergency-pass')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Precise Commander adds five accuracy once in weapon previews', (
    tester,
  ) async {
    final controller = captain();
    addTearDown(controller.dispose);
    controller.ship!.tempAccuracyPenalty = 20;
    final baseline = {
      for (final type in controller.ship!.equippedWeaponTypes)
        type: calculateHitChance(
          controller.ship!,
          controller.ship!.equippedWeapons.firstWhere(
            (w) => w.weaponType == type,
          ),
          controller.currentMonster!,
          range: controller.combatRange,
        ),
    };
    controller.session.activeBoon = BloodlineTrait.preciseCommander;
    await mountBattle(tester, controller);
    for (final chance in baseline.values) {
      final expected = (chance + 5).clamp(25, 95);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Tooltip &&
              (w.message?.contains('Opening shot accuracy: $expected%') ??
                  false),
        ),
        findsWidgets,
      );
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('battle trait timing fits $width / $scale', (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = captain(quirk: BloodlineTrait.impatient);
        addTearDown(controller.dispose);
        final game = MonstrousSeaBattleGame(
          ship: controller.ship!,
          monster: controller.currentMonster!,
        );
        await tester.runAsync(() async {
          game.onGameResize(Vector2(width, 1100));
          // ignore: invalid_use_of_internal_member
          await game.load();
        });
        await tester.pumpWidget(
          page(
            ListenableBuilder(
              listenable: controller,
              builder: (context, child) =>
                  BattleScreen(controller: controller, game: game),
            ),
            scale,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        controller.dispatch(
          const ExecuteShipSpecialAction(borrowNextAction: true),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.textContaining('Fire one weapon next.'), findsOneWidget);
        await capture(tester, 'battle-pending-$width-$scale');
        controller.currentMonster!.currentHp = 1000;
        controller.dispatch(
          FireWeaponVolley(controller.ship!.equippedWeaponTypes.first),
        );
        controller.ship!.isGrappled = true;
        controller.notify();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.textContaining('Hardpoints unavailable.'), findsOneWidget);
        expect(find.byKey(const ValueKey('emergency-pass')), findsOneWidget);
        await capture(tester, 'battle-recovery-$width-$scale');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  for (final blueprint in [BlueprintId.ironclad, BlueprintId.corsair]) {
    testWidgets(
      'late ${blueprint.name} action forecasts movement before Fall Back',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = captain(quirk: BloodlineTrait.skirmisher);
        addTearDown(controller.dispose);
        controller.session.ship = createFlagshipFromBlueprint(
          blueprint,
          rng: SeededGameRng(7),
        );
        controller.session.combatRange = CombatRange.medium;
        controller.currentMonster!.currentHp = 1000;
        controller.currentMonster!.currentIntent = MonsterIntent.fromId(
          MonsterIntentId.crustaceanTremorSlam,
        );
        final game = MonstrousSeaBattleGame(
          ship: controller.ship!,
          monster: controller.currentMonster!,
        );
        await tester.runAsync(() async {
          game.onGameResize(Vector2(1280, 1100));
          // ignore: invalid_use_of_internal_member
          await game.load();
        });
        await tester.pumpWidget(
          page(BattleScreen(controller: controller, game: game), 1.3),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label?.startsWith('Helm Order: Fall Back') ??
                    false),
          ),
        );
        await tester.pump();
        final weaponType = blueprint.signatureWeaponType;
        expect(
          controller.previewResponseRange(
            helmOrder: HelmOrder.fallBack,
            weaponType: weaponType,
          ),
          CombatRange.medium,
        );
        final tip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.byWidgetPredicate(
              (w) =>
                  w is InkButton &&
                  (w.semanticLabel?.startsWith(
                        'Fire ${weaponType.displayName} volley',
                      ) ??
                      false),
            ),
            matching: find.byType(Tooltip),
          ),
        );
        expect(tip.message, contains('After action: Medium Range'));
        expect(tip.message, contains('IN THREAT ZONE'));
        expect(
          find.byKey(const ValueKey('conditional-range-forecast')),
          findsOneWidget,
        );
        expect(
          find.textContaining('HELM ONLY · EVADED BY MANEUVER'),
          findsOneWidget,
        );
        if (reviewFont.isNotEmpty) {
          final tooltip = find.byWidgetPredicate((w) => identical(w, tip));
          tester.state<TooltipState>(tooltip).ensureTooltipVisible();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text(tip.message!), findsOneWidget);
          await capture(tester, 'forecast-${blueprint.name}');
        }
        // The global helm-only outcome is explicitly conditional; the specific
        // attack tooltip agrees with the real player-action movement order.
        controller.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
        controller.dispatch(FireWeaponVolley(weaponType));
        expect(controller.combatRange, CombatRange.medium);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'Daredevil activates at half hull and Armory retains captain descriptions',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = captain(
        boon: BloodlineTrait.preciseCommander,
        quirk: BloodlineTrait.daredevil,
      );
      addTearDown(controller.dispose);
      final halfHull = controller.ship!.maxHp ~/ 2;
      controller.ship!.currentHp = halfHull + 1;
      await mountBattle(tester, controller, textScale: 1.3);
      expect(
        find.text('DAREDEVIL · Bonus activates at 50% hull or less'),
        findsOneWidget,
      );
      controller.ship!.currentHp = halfHull;
      controller.notify();
      await tester.pump();
      expect(
        find.text('DAREDEVIL · +30% weapon damage · at/below 50% hull'),
        findsOneWidget,
      );
      await tester.pumpWidget(
        page(
          SingleChildScrollView(child: ArmoryView(controller: controller)),
          1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CAPTAIN TRAITS'), findsOneWidget);
      for (final trait in [controller.activeBoon!, controller.activeQuirk!]) {
        expect(find.text(trait.name), findsOneWidget);
        expect(find.text(trait.description), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
