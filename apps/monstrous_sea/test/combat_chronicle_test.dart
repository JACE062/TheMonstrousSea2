import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/combat_log_view.dart';

CombatLogEntry marker(String message) =>
    CombatLogEntry(message: message, actor: CombatLogActor.ship);

void sink(GameController controller) {
  controller.ship!.applyDamage(controller.ship!.maxHp);
  controller.dispatch(const ExecuteShipSpecialAction());
  expect(controller.phase, SessionPhase.death);
}

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);

  test('three successive voyages keep only their own live Chronicle', () {
    final controller = GameController(
      session: GameSession(rng: SeededGameRng(42)),
      autoSave: false,
    );
    addTearDown(controller.dispose);
    controller.structuredCombatLog.add(marker('Before the first departure'));
    controller.dispatch(const BeginFirstVoyage('Founder'));
    expect(controller.combatLog, isNot(contains('Before the first departure')));
    expect(
      controller.combatLog.any((m) => m.startsWith('Encountered ')),
      isTrue,
    );

    for (var generation = 1; generation <= 2; generation++) {
      final previous = 'Voyage $generation battle history';
      controller.structuredCombatLog.add(marker(previous));
      sink(controller);
      expect(controller.combatLog, contains(previous));
      controller.dispatch(
        ContinueLineage('Heir $generation', ShipClass.standard),
      );
      expect(controller.combatLog, isNot(contains(previous)));
      controller.structuredCombatLog.add(marker('Home preparations'));
      controller.dispatch(const VentureOutToSea());
      expect(controller.phase, SessionPhase.battle);
      expect(controller.combatLog, isNot(contains('Home preparations')));
      expect(
        controller.combatLog.any((m) => m.startsWith('Encountered ')),
        isTrue,
      );
    }
    expect(controller.lineage.captainsLost, 2);
  });

  test('ordinary rewards, strongholds and rejected actions retain voyage history', () {
    final controller = GameController(
      session: GameSession(rng: SeededGameRng(42)),
      autoSave: false,
    )..dispatch(const BeginFirstVoyage('Continuity'));
    addTearDown(controller.dispose);
    controller.structuredCombatLog.add(marker('Earlier encounter'));
    controller.currentMonster!.currentHp = 0;
    controller.dispatch(
      FireWeaponVolley(controller.ship!.equippedWeapons.first.weaponType),
    );
    expect(controller.phase, SessionPhase.loot);
    controller.dispatch(const LeaveRemainingLoot());
    expect(controller.phase, SessionPhase.helm);
    expect(controller.combatLog, contains('Earlier encounter'));

    // Arrive at an actual completed Titan checkpoint, then use normal routing.
    controller.seaChart.currentLeg = controller.seaChart.totalLegs;
    controller.session.phase = SessionPhase.restArea;
    controller.session.hasDefeatedCurrentEncounter = true;
    controller.dispatch(const TakeHelm());
    expect(controller.phase, SessionPhase.stronghold);
    controller.dispatch(const VentureOutToSea());
    expect(controller.phase, SessionPhase.helm);
    expect(controller.combatLog, contains('Earlier encounter'));
    final before = controller.combatLog;
    expect(
      () => controller.dispatch(const BeginFirstVoyage('Invalid')),
      throwsStateError,
    );
    expect(controller.combatLog, before);
  });

  test(
    'compatibility home-to-helm departure also starts a fresh Chronicle',
    () {
      final controller = GameController(autoSave: false);
      addTearDown(controller.dispose);
      controller.dispatch(const NameCaptain('Compatibility'));
      controller.dispatch(const ChooseShip(ShipClass.standard));
      controller.structuredCombatLog.add(marker('Home history'));
      controller.dispatch(const TakeHelm());
      expect(controller.phase, SessionPhase.helm);
      expect(controller.combatLog, isNot(contains('Home history')));
    },
  );

  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets(
        'Chronicle opens latest and respects history at $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final entries = List.generate(
            120,
            (i) => marker(
              'Round $i: ${List.filled(i % 5 + 1, 'The cannon volley strikes the beast.').join(' ')}',
            ),
          );
          entries.add(marker('Latest opening intent'));
          late StateSetter refresh;
          await tester.pumpWidget(
            MaterialApp(
              theme: InkTheme.themeData,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    refresh = setState;
                    return SizedBox(
                      height: 170,
                      child: CombatLogView(entries: entries),
                    );
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final scrollable = find.descendant(
            of: find.byType(CombatLogView),
            matching: find.byType(Scrollable),
          );
          final position = tester.state<ScrollableState>(scrollable).position;
          expect(position.extentAfter, 0);
          expect(
            find.text('Latest opening intent').hitTestable(),
            findsOneWidget,
          );

          refresh(() => entries.add(marker('Live volley')));
          await tester.pumpAndSettle();
          expect(position.extentAfter, 0);
          expect(find.text('Live volley').hitTestable(), findsOneWidget);

          await tester.drag(scrollable, const Offset(0, 110));
          await tester.pumpAndSettle();
          expect(find.text('LATEST MESSAGES'), findsOneWidget);
          final readingOffset = position.pixels;
          refresh(
            () => entries.addAll([marker('New action'), marker('New intent')]),
          );
          await tester.pumpAndSettle();
          expect(position.pixels, closeTo(readingOffset, 0.01));
          expect(find.text('LATEST MESSAGES'), findsOneWidget);

          await tester.tap(find.text('LATEST MESSAGES'));
          await tester.pumpAndSettle();
          expect(position.extentAfter, 0);
          expect(find.text('New intent').hitTestable(), findsOneWidget);
          expect(find.text('LATEST MESSAGES'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('mouse wheel history, resize and a fresh encounter view', (
    tester,
  ) async {
    final entries = List.generate(
      80,
      (i) => marker('Earlier voyage action $i'),
    );
    late StateSetter refresh;
    var key = 0;
    var height = 160.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              return SizedBox(
                height: height,
                child: CombatLogView(key: ValueKey(key), entries: entries),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable);
    var position = tester.state<ScrollableState>(scrollable).position;
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(scrollable),
        scrollDelta: const Offset(0, -100),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('LATEST MESSAGES'), findsOneWidget);
    final offset = position.pixels;
    refresh(() {
      entries.add(marker('Next encounter opening intent'));
      height = 120;
    });
    await tester.pumpAndSettle();
    expect(position.pixels, closeTo(offset, 0.01));

    // A new battle mounts a fresh view over the same voyage history.
    refresh(() => key++);
    await tester.pumpAndSettle();
    position = tester.state<ScrollableState>(scrollable).position;
    expect(position.extentAfter, 0);
    expect(
      find.text('Next encounter opening intent').hitTestable(),
      findsOneWidget,
    );
    refresh(() => height = 48);
    await tester.pumpAndSettle();
    expect(position.extentAfter, 0);
    expect(tester.takeException(), isNull);
  });
}
