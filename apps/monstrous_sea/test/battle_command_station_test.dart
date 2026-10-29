import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/battle_lookout.dart';
import 'package:monstrous_sea/src/widgets/combat_log_view.dart';
import 'package:monstrous_sea/src/widgets/ocean_power_badges.dart';
import 'package:monstrous_sea/src/widgets/armory_view.dart';

const _font = String.fromEnvironment('reviewFontPath');
const _capture = bool.fromEnvironment('captureCommandStation');

Future<void> _captureFrame(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('build/command-station-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (_font.isNotEmpty) {
      await (FontLoader(
        'CommandReview',
      )..addFont(File(_font).readAsBytes().then(ByteData.sublistView))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  for (final spec in [
    (
      hull: BlueprintId.standard,
      size: const Size(1280, 900),
      scale: 1.15,
      boss: false,
    ),
    (
      hull: BlueprintId.bombardier,
      size: const Size(1440, 1000),
      scale: 1.3,
      boss: true,
    ),
    (
      hull: BlueprintId.corsair,
      size: const Size(600, 1000),
      scale: 1.3,
      boss: true,
    ),
    (
      hull: BlueprintId.ironclad,
      size: const Size(1920, 1080),
      scale: 1.15,
      boss: false,
    ),
    (
      hull: BlueprintId.ironclad,
      size: const Size(360, 900),
      scale: 1.3,
      boss: false,
    ),
    (
      hull: BlueprintId.clipper,
      size: const Size(1024, 768),
      scale: 1.3,
      boss: false,
    ),
    (
      hull: BlueprintId.standard,
      size: const Size(800, 600),
      scale: 1.3,
      boss: false,
    ),
  ]) {
    testWidgets(
      '${spec.hull.name} command layout and modal bounds at ${spec.size.width}',
      (tester) async {
        tester.view.physicalSize = spec.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = GameController(
          session: GameSession(rng: SeededGameRng(42)),
          autoSave: false,
        )..dispatch(const BeginFirstVoyage('Command review'));
        controller.session.ship = createFlagshipFromBlueprint(
          spec.hull,
          rng: SeededGameRng(1),
        );
        final ship = controller.ship!;
        if (spec.hull == BlueprintId.standard) {
          // An older save retains its raw utility name; both views use current copy.
          final index = ship.hardpoints.indexWhere(
            (slot) => slot.type == HardpointType.utility,
          );
          ship.hardpoints[index] = HardpointSlot.fromJson({
            ...ship.hardpoints[index].toJson(),
            'name': 'Gunnery Drill',
          });
        }
        if (spec.hull == BlueprintId.ironclad) {
          for (final weapon in ship.equippedWeapons.where(
            (weapon) => weapon.weaponType == ShipWeaponType.prowRam,
          )) {
            weapon.chargeCountdown = 1;
          }
        }
        ship.maxCargo += 2;
        ship.cargo.addAll(
          List.generate(
            ship.maxCargo,
            (index) => generateConsumable(
              ConsumableType.values[index % ConsumableType.values.length],
              RarityLevel.common,
            ),
          ),
        );
        ship.blessings.addAll({
          if (spec.hull != BlueprintId.standard &&
              spec.hull != BlueprintId.ironclad)
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
        controller.session.currentMonster =
            createMonster(
                spec.boss ? MonsterSpecies.kraken : MonsterSpecies.serpent,
                level: 5,
                rng: SeededGameRng(3),
              )
              ..currentIntent = MonsterIntent.fromId(
                spec.boss
                    ? MonsterIntentId.squidSweepingTentacles
                    : MonsterIntentId.serpentFangedWhipRecoil,
              );
        final game = MonstrousSeaBattleGame(
          ship: ship,
          monster: controller.currentMonster!,
        );
        await tester.runAsync(() async {
          game.onGameResize(Vector2(spec.size.width, spec.size.height));
          // ignore: invalid_use_of_internal_member
          await game.load();
        });
        game.feedbackFontFamily = _font.isEmpty ? null : 'CommandReview';
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: InkTheme.themeData.copyWith(
                textTheme: InkTheme.themeData.textTheme.apply(
                  fontFamily: _font.isEmpty ? null : 'CommandReview',
                ),
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(spec.scale)),
                child: child!,
              ),
              home: ListenableBuilder(
                listenable: controller,
                builder: (context, _) =>
                    BattleScreen(controller: controller, game: game),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        game.pauseEngine();
        await tester.pumpAndSettle();
        expect(find.byType(CombatLogView), findsNothing);
        expect(find.byType(BattleLookout), findsOneWidget);
        expect(find.text('SHIP FITTINGS'), findsOneWidget);
        expect(find.text('Gunnery Drill'), findsNothing);
        if (spec.hull == BlueprintId.standard) {
          expect(find.text('Gun-Deck Bracing'), findsOneWidget);
        }
        final weapons = find.byKey(const ValueKey('weapon-cards'));
        final utility = find.byKey(const ValueKey('utility-row'));
        expect(
          tester.getRect(utility).top,
          greaterThan(tester.getRect(weapons).bottom),
        );
        final row = tester.widget<Row>(weapons);
        expect(row.children, hasLength(2));
        final broadside = tester.getRect(
          find.byKey(const ValueKey('hardpoint-broadside')),
        );
        final signature = tester.getRect(
          find.byKey(const ValueKey('hardpoint-signature')),
        );
        expect(signature.top, closeTo(broadside.top, 0.01));
        expect(signature.bottom, closeTo(broadside.bottom, 0.01));
        for (final badge in tester.widgetList<BlessingBadge>(
          find.byType(BlessingBadge),
        )) {
          final button = find.byKey(
            ValueKey('hardpoint-${badge.blessing.slot.name}'),
          );
          expect(
            tester.getRect(find.byWidget(badge)).top,
            closeTo(tester.getRect(button).bottom, 0.01),
            reason: 'Blessings hang below their own action',
          );
        }
        expect(find.text('UTILITY'), findsOneWidget);
        final helmPanel = tester.getRect(
          find.byKey(const ValueKey('helm-panel')),
        );
        for (final order in HelmOrder.values) {
          final card = tester.getRect(
            find.byKey(ValueKey('helm-${order.name}')),
          );
          expect(card.height, greaterThanOrEqualTo(88));
          expect(card.width, closeTo((helmPanel.width - 18) / 3, 0.01));
        }
        final beltBefore = tester.getRect(
          find.byKey(const ValueKey('tactical-belt')),
        );
        expect(
          beltBefore.bottom,
          closeTo(
            tester
                .getRect(find.byKey(const ValueKey('battle-dock-footer')))
                .bottom,
            0.01,
          ),
        );
        if (spec.size.width >= 1100) {
          final helm = tester.getRect(find.byKey(const ValueKey('helm-panel')));
          final hardpoints = tester.getRect(
            find.byKey(const ValueKey('hardpoint-panel')),
          );
          expect(helm.left, lessThan(hardpoints.left));
          expect(
            helm.width / (helm.width + hardpoints.width),
            closeTo(0.4, 0.01),
          );
          final lookout = tester.getRect(find.byType(BattleLookout));
          final sprites = game.children.whereType<PositionComponent>().where(
            (component) =>
                component.anchor == Anchor.center && component.width > 0,
          );
          for (final sprite in sprites) {
            expect(sprite.x + sprite.width / 2, lessThan(lookout.left));
          }
        }
        expect(tester.takeException(), isNull);
        await _captureFrame(
          tester,
          key,
          '${spec.hull.name}-${spec.size.width.toInt()}',
        );
        final lookoutBefore = tester.getRect(find.byType(BattleLookout));
        await tester.ensureVisible(utility);
        await tester.pump();
        expect(
          tester.getRect(find.byType(BattleLookout)),
          lookoutBefore,
          reason: 'The lookout remains fixed while commands scroll',
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('tactical-belt'))),
          beltBefore,
          reason: 'The belt remains on the bottom edge while commands scroll',
        );
        expect(
          find.byKey(const ValueKey('belt-help')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Chronicle Log'));
        await tester.pumpAndSettle();
        expect(find.byType(CombatLogView), findsOneWidget);
        expect(find.byType(Dialog), findsOneWidget);
        await _captureFrame(
          tester,
          key,
          '${spec.hull.name}-${spec.size.width.toInt()}-chronicle',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(CombatLogView), findsNothing);
        await tester.ensureVisible(find.byTooltip('Inspect monster intent'));
        await tester.tap(find.byTooltip('Inspect monster intent'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.textContaining('Prow Ram closes to Short'),
          spec.hull == BlueprintId.ironclad ? findsOneWidget : findsNothing,
        );
        expect(
          find.textContaining('Harpoon Winch attacks at its launch range'),
          spec.hull == BlueprintId.corsair ? findsOneWidget : findsNothing,
        );
        expect(
          find.textContaining('Evasive Rigging opens range'),
          spec.hull == BlueprintId.clipper ? findsOneWidget : findsNothing,
        );
        expect(
          find.textContaining('Skirmisher applies your helm'),
          findsNothing,
        );
        await _captureFrame(
          tester,
          key,
          '${spec.hull.name}-${spec.size.width.toInt()}-intent',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);
        if (spec.hull == BlueprintId.standard) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ArmoryView(controller: controller),
                ),
              ),
            ),
          );
          expect(find.text('SHIP FITTINGS & TACTICAL BELT'), findsOneWidget);
          expect(find.text('Gun-Deck Bracing'), findsOneWidget);
          expect(find.text('Gunnery Drill'), findsNothing);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      },
    );
  }
}
