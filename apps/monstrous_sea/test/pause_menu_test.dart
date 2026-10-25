import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/loot_screen.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/pause_menu.dart';
import 'package:monstrous_sea/src/widgets/settings_dialog.dart';

const _font = String.fromEnvironment('reviewFontPath');

class _HitRng extends SeededGameRng {
  _HitRng() : super(42);
  @override
  int d100() => 1;
}

class _ExitBinding extends AutomatedTestWidgetsFlutterBinding {
  int calls = 0;
  bool fail = false;
  @override
  Future<ui.AppExitResponse> exitApplication(
    ui.AppExitType type, [
    int exitCode = 0,
  ]) async {
    calls++;
    if (fail) throw PlatformException(code: 'fixture');
    return ui.AppExitResponse.exit;
  }
}

class _Storage extends StorageService {
  _Storage() : super(baseDirectory: Directory('unused-pause-fixture'));
  Completer<void>? gate;
  bool fail = false;
  final savedGold = <int>[];
  int profiles = 0;
  @override
  Future<void> saveProfile(ProfileData profile) async {
    profiles++;
    await gate?.future;
    if (fail) throw const FileSystemException('fixture');
  }

  @override
  Future<void> saveVoyage(VoyageSaveData voyage) async =>
      savedGold.add(voyage.ship.gold);
  @override
  Future<bool> clearVoyage() async => true;
}

GameController _controller({_Storage? storage, bool autoSave = true}) {
  final session = GameSession(rng: SeededGameRng(42))
    ..dispatch(const NameCaptain('Pause captain'))
    ..dispatch(const ChooseShip(ShipClass.standard));
  return GameController(
    session: session,
    storage: storage ?? _Storage(),
    autoSave: autoSave,
    retainPreparationCheckpoints: true,
  );
}

Future<void> _mount(
  WidgetTester tester,
  GameController controller, {
  VoidCallback? onReturn,
  Widget? body,
  double scale = 1.15,
  GlobalKey? captureKey,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        theme: _font.isEmpty
            ? InkTheme.themeData
            : InkTheme.themeData.copyWith(
                textTheme: InkTheme.themeData.textTheme.apply(
                  fontFamily: 'PauseReview',
                ),
              ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: PauseMenuHost(
          controller: controller,
          label: 'Original Lineage',
          onReturnToTitle: onReturn,
          child: Scaffold(
            body: Column(
              children: [const PauseMenuButton(), body ?? const Text('VOYAGE')],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
  expect(find.text('PAUSED'), findsOneWidget);
}

InkButton _button(WidgetTester tester, String key) =>
    tester.widget<InkButton>(find.byKey(ValueKey(key)));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  final binding = _ExitBinding();
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (_font.isNotEmpty) {
      await (FontLoader(
        'PauseReview',
      )..addFont(File(_font).readAsBytes().then(ByteData.sublistView))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  setUp(() {
    binding.calls = 0;
    binding.fail = false;
  });

  testWidgets(
    'Esc nests settings, blocks gameplay, resumes and restores focus',
    (tester) async {
      final controller = _controller(autoSave: false);
      final focus = FocusNode();
      var actions = 0;
      await _mount(
        tester,
        controller,
        body: Focus(
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.keyA) {
              actions++;
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextButton(
            focusNode: focus,
            onPressed: () => actions++,
            child: const Text('FIRE'),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await _open(tester);
      expect(find.text('Original Lineage'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      expect(actions, 0);
      expect(focus.hasFocus, isFalse);
      // The barrier may dismiss Pause, but the pointer must never reach FIRE.
      await tester.tap(find.text('FIRE'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(actions, 0);
      if (find.text('PAUSED').evaluate().isEmpty) await _open(tester);
      await _tap(tester, 'pause-settings');
      expect(find.byType(SettingsDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsDialog), findsNothing);
      expect(find.text('PAUSED'), findsOneWidget);
      await _tap(tester, 'pause-resume');
      expect(find.text('PAUSED'), findsNothing);
      expect(focus.hasFocus, isTrue);
      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      focus.dispose();
      controller.dispose();
    },
  );

  testWidgets(
    'every unsupported encounter and playback disables both departures',
    (tester) async {
      final controller = _controller();
      await _mount(tester, controller, onReturn: () {});
      await _open(tester);
      for (final phase in [
        SessionPhase.battle,
        SessionPhase.restArea,
        SessionPhase.shrine,
        SessionPhase.smuggler,
        SessionPhase.respiteIsland,
      ]) {
        controller.session.phase = phase;
        controller.notify();
        await tester.pumpAndSettle();
        expect(
          _button(tester, 'pause-return').onPressed,
          isNull,
          reason: '$phase',
        );
        expect(
          find.textContaining('unfinished encounters cannot be resumed'),
          findsOneWidget,
        );
        expect(
          _button(tester, 'pause-exit').onPressed,
          isNull,
          reason: '$phase',
        );
      }
      for (final phase in [
        SessionPhase.captainCreation,
        SessionPhase.port,
        SessionPhase.stronghold,
        SessionPhase.helm,
        SessionPhase.loot,
        SessionPhase.shipwreck,
        SessionPhase.merchant,
        SessionPhase.expeditionVictory,
        SessionPhase.death,
        SessionPhase.ended,
      ]) {
        controller.session.phase = phase;
        controller.setIsPlayingEvents(true);
        await tester.pumpAndSettle();
        expect(
          _button(tester, 'pause-return').onPressed,
          isNull,
          reason: '$phase playback',
        );
        expect(
          find.textContaining('An action is still playing'),
          findsOneWidget,
        );
        expect(
          _button(tester, 'pause-exit').onPressed,
          isNull,
          reason: '$phase playback',
        );
      }
      // Playback is allowed to complete while the menu remains visible.
      controller.setIsPlayingEvents(false);
      await tester.pumpAndSettle();
      expect(_button(tester, 'pause-return').onPressed, isNotNull);
      expect(_button(tester, 'pause-exit').onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'return drains queued snapshots and ignores dismissal while saving',
    (tester) async {
      final storage = _Storage()..gate = Completer<void>();
      final controller = _controller(storage: storage);
      controller.ship!.gold = 101;
      final earlier = controller.persistState();
      var returned = 0;
      await _mount(tester, controller, onReturn: () => returned++);
      controller.ship!.gold = 202;
      await _open(tester);
      await tester.tap(find.byKey(const ValueKey('pause-return')));
      await tester.pump();
      expect(find.text('SAVING…'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(find.text('PAUSED'), findsOneWidget);
      expect(returned, 0);
      storage.gate!.complete();
      await earlier;
      await tester.pumpAndSettle();
      expect(storage.savedGold, [101, 202]);
      expect(returned, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('fatal volley survives Pause and parent rebuild without replay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GameController(
      session: GameSession(rng: _HitRng()),
      autoSave: false,
    )..dispatch(const BeginFirstVoyage('Paused volley'));
    controller.ship!.cargo.add(
      generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common),
    );
    final monster = controller.currentMonster!..currentHp = 1;
    late StateSetter rebuild;
    late MonstrousSeaBattleGame game;
    // Begin the cold codec loads outside the fake widget clock, then await
    // the game actually created by the orchestrator rather than a test double.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData,
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return PauseMenuHost(
                controller: controller,
                label: 'Unsaved battle',
                onReturnToTitle: () {},
                child: GameOrchestratorView(
                  controller: controller,
                  skipIntro: true,
                ),
              );
            },
          ),
        ),
      );
      game =
          tester
                  .widget<GameWidget>(
                    find.byWidgetPredicate((widget) => widget is GameWidget),
                  )
                  .game
              as MonstrousSeaBattleGame;
      await game.toBeLoaded();
    });
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.isLoaded, isTrue);
    await tester.tap(find.byKey(const ValueKey('belt-help')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('TACTICAL BELT'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('TACTICAL BELT'), findsNothing);
    expect(find.text('PAUSED'), findsNothing);
    await tester.tap(find.text('Naval Cannon Battery'));
    await tester.pump();
    expect(controller.phase, SessionPhase.loot);
    expect(controller.isPlayingEvents, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('PAUSED'), findsOneWidget);
    rebuild(() {});
    await tester.pump();
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.byType(LootScreen), findsNothing);
    expect(
      tester
          .widget<GameWidget>(
            find.byWidgetPredicate((widget) => widget is GameWidget),
          )
          .game,
      same(game),
    );
    expect(controller.isPlayingEvents, isTrue);
    expect(_button(tester, 'pause-return').onPressed, isNull);
    expect(_button(tester, 'pause-exit').onPressed, isNull);
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(controller.isPlayingEvents, isFalse);
    expect(find.byType(LootScreen), findsOneWidget);
    expect(find.byType(BattleScreen), findsNothing);
    expect(find.text('PAUSED'), findsOneWidget);
    expect(_button(tester, 'pause-return').onPressed, isNotNull);
    expect(_button(tester, 'pause-exit').onPressed, isNotNull);
    final gold = controller.ship!.gold;
    final logs = List.of(controller.combatLog);
    final loot = List.of(controller.pendingLoot);
    final hp = monster.currentHp;
    await tester.tap(find.byKey(const ValueKey('pause-resume')));
    await tester.pumpAndSettle();
    expect(controller.ship!.gold, gold);
    expect(controller.combatLog, logs);
    expect(controller.pendingLoot, loot);
    expect(monster.currentHp, hp);
    expect(controller.isPlayingEvents, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  for (final exit in [false, true]) {
    testWidgets(
      '${exit ? 'exit' : 'return'} retries failed saves before leaving',
      (tester) async {
        final storage = _Storage()..fail = true;
        final controller = _controller(storage: storage);
        var returned = 0;
        await _mount(tester, controller, onReturn: () => returned++);
        await _open(tester);
        final key = exit ? 'pause-exit' : 'pause-return';
        await _tap(tester, key);
        expect(
          find.textContaining('Could not save your progress'),
          findsOneWidget,
        );
        expect(returned, 0);
        expect(binding.calls, 0);
        storage.fail = false;
        await _tap(tester, key);
        expect(storage.profiles, 2);
        expect(exit ? binding.calls : returned, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      },
    );
  }

  testWidgets('exit waits for saving and prevents duplicate exit requests', (
    tester,
  ) async {
    final storage = _Storage()..gate = Completer<void>();
    final controller = _controller(storage: storage);
    await _mount(tester, controller);
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('pause-exit')));
    await tester.pump();
    expect(binding.calls, 0);
    expect(_button(tester, 'pause-resume').onPressed, isNull);
    expect(_button(tester, 'pause-settings').onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('pause-exit')));
    await tester.pump();
    expect(storage.profiles, 1);
    storage.gate!.complete();
    await tester.pumpAndSettle();
    expect(binding.calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'platform exit failure is retryable and unsaved sessions never write',
    (tester) async {
      final storage = _Storage();
      final controller = _controller(storage: storage, autoSave: false);
      await _mount(tester, controller);
      await _open(tester);
      expect(find.text('EXIT GAME'), findsOneWidget);
      binding.fail = true;
      await _tap(tester, 'pause-exit');
      expect(find.textContaining('The game could not close'), findsOneWidget);
      binding.fail = false;
      await _tap(tester, 'pause-exit');
      expect(binding.calls, 2);
      expect(storage.profiles, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('pause fits $width at $scale text', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _controller();
        final capture = GlobalKey();
        await _mount(
          tester,
          controller,
          onReturn: () {},
          scale: scale,
          captureKey: capture,
        );
        await tester.tap(find.byKey(const ValueKey('pause-menu-button')));
        await tester.pumpAndSettle();
        expect(find.text('PAUSED'), findsOneWidget);
        for (final key in [
          'pause-resume',
          'pause-settings',
          'pause-return',
          'pause-exit',
        ]) {
          await tester.ensureVisible(find.byKey(ValueKey(key)));
          expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        if (_font.isNotEmpty && scale == 1.3) {
          await tester.runAsync(() async {
            final image = await tester
                .renderObject<RenderRepaintBoundary>(find.byKey(capture))
                .toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final output = File('build/pause-${width.toInt()}.png');
              await output.parent.create(recursive: true);
              await output.writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }
}
