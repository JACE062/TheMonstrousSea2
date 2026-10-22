import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/playtest/playtest_screen.dart';
import 'package:monstrous_sea/src/screens/caldera_outcome_screen.dart';
import 'package:monstrous_sea/src/screens/intro_screen.dart';
import 'package:monstrous_sea/src/screens/lineage_menu_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/services/lineage_store.dart';
import 'package:monstrous_sea/src/services/caldera_snapshot.dart';
import 'package:monstrous_sea/src/settings/game_settings.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/painters/cartouche_border_painter.dart';
import 'package:monstrous_sea/src/widgets/settings_dialog.dart';

const reviewFont = String.fromEnvironment('lineageFontPath');

class MenuTestBinding extends AutomatedTestWidgetsFlutterBinding {
  int exitCalls = 0;
  bool failExit = false;
  @override
  Future<ui.AppExitResponse> exitApplication(
    ui.AppExitType type, [
    int exitCode = 0,
  ]) async {
    exitCalls++;
    if (failExit) throw PlatformException(code: 'fixture');
    return ui.AppExitResponse.exit;
  }
}

class MemorySlotStorage extends StorageService {
  MemorySlotStorage(this.profile, {this.voyage})
    : super(baseDirectory: Directory('unused-menu-fixture'));
  ProfileData profile;
  VoyageSaveData? voyage;
  bool failSave = false;
  Completer<void>? saveGate;
  int writes = 0;
  CalderaSnapshot? snapshot;
  @override
  Future<void> saveCalderaSnapshot(CalderaSnapshot value) async {
    snapshot = CalderaSnapshot.fromJson(value.toJson());
  }

  @override
  Future<CalderaSnapshot?> loadCalderaSnapshot() async => snapshot;
  @override
  Future<ProfileData> loadProfile() async =>
      ProfileData.fromJson(profile.toJson());
  @override
  Future<VoyageSaveData?> loadVoyage() async =>
      voyage == null ? null : VoyageSaveData.fromJson(voyage!.toJson());
  @override
  Future<void> saveProfile(ProfileData value) async {
    writes++;
    await saveGate?.future;
    if (failSave) throw const FileSystemException('Fixture save failure');
    profile = ProfileData.fromJson(value.toJson());
  }

  @override
  Future<void> saveVoyage(VoyageSaveData value) async {
    voyage = VoyageSaveData.fromJson(value.toJson());
  }

  @override
  Future<bool> clearVoyage() async {
    voyage = null;
    return true;
  }
}

class MemoryLineages extends LineageStore {
  MemoryLineages() : super(rootStorage: MemorySlotStorage(ProfileData()));
  final slots = <LineageSlot>[];
  final saves = <String, MemorySlotStorage>{};
  String? active;
  bool failLoad = false;
  bool failOpen = false;
  bool failCreate = false;
  final unreadable = <String>{};

  LineageSlot seed(
    String label, {
    bool completed = false,
    bool withSnapshot = false,
  }) {
    CalderaSnapshot? snapshot;
    final session = GameSession(rng: SeededGameRng(42))
      ..dispatch(NameCaptain('Captain $label'))
      ..dispatch(const ChooseShip(ShipClass.standard));
    session.profile.hasBegunFirstVoyage = true;
    if (completed) {
      session.profile.metaInventory.add(leviathanCore: 1);
      session.phase = SessionPhase.expeditionVictory;
      if (withSnapshot) snapshot = CalderaSnapshot.fromSession(session);
      session.dispatch(
        const ResolveCalderaClimax(CalderaClimaxChoice.shatterCore),
      );
      session.dispatch(const AcknowledgeCalderaOutcome());
    }
    final slot = LineageSlot(id: 'test-${slots.length}', label: label);
    slots.add(slot);
    saves[slot.id] = MemorySlotStorage(
      session.profile,
      voyage: VoyageSaveData.fromSession(session),
    )..snapshot = snapshot;
    active ??= slot.id;
    return slot;
  }

  @override
  Future<LineageCatalog> load() async {
    if (failLoad) throw const FormatException('Fixture invalid catalog');
    return LineageCatalog(slots, activeId: active);
  }

  @override
  Future<List<LineageSummary>> summaries() async => [
    for (final slot in slots)
      LineageSummary(
        slot,
        profile: saves[slot.id]!.profile,
        error: unreadable.contains(slot.id) ? 'Save could not be read.' : null,
        canExploreOtherFate:
            saves[slot.id]!.snapshot != null ||
            slots.any((s) => s.alternateOf == slot.id),
        alternateId: slots
            .where((s) => s.alternateOf == slot.id)
            .firstOrNull
            ?.id,
      ),
  ];
  @override
  Future<LineageSlot> create(String label) async {
    if (failCreate) throw const FileSystemException('Fixture creation failure');
    final slot = LineageSlot(id: 'test-${slots.length}', label: label);
    slots.add(slot);
    saves[slot.id] = MemorySlotStorage(ProfileData());
    active = slot.id;
    return slot;
  }

  int branchCalls = 0;
  bool failBranch = false;
  @override
  Future<LineageSlot> exploreOtherFate(String sourceId) async {
    branchCalls++;
    if (failBranch) throw const FileSystemException('Fixture branch failure');
    final existing = slots.where((s) => s.alternateOf == sourceId).firstOrNull;
    if (existing != null) return existing;
    final snapshot = saves[sourceId]!.snapshot!;
    final slot = LineageSlot(
      id: 'test-${slots.length}',
      label: 'Other Fate',
      alternateOf: sourceId,
    );
    slots.add(slot);
    saves[slot.id] = MemorySlotStorage(
      ProfileData.fromJson(snapshot.profile.toJson()),
      voyage: VoyageSaveData.fromJson(snapshot.voyage.toJson()),
    );
    active = slot.id;
    return slot;
  }

  @override
  Future<StorageService> open(String id) async {
    if (failOpen) throw const FileSystemException('Fixture opening failure');
    active = id;
    return saves[id]!;
  }
}

Future<void> click(WidgetTester tester, String text) async {
  final button = find.text(text);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  // The real prologue intentionally animates its waves continuously.
  if (find.byType(IntroScreen).evaluate().isEmpty) {
    await tester.pumpAndSettle();
  }
}

Future<void> newLineage(WidgetTester tester, String label) async {
  await click(tester, 'NEW LINEAGE');
  await tester.enterText(find.byKey(const ValueKey('lineage-label')), label);
  await click(tester, 'CREATE LINEAGE');
}

void main() {
  final binding = MenuTestBinding();
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (reviewFont.isNotEmpty) {
      await (FontLoader(
            'Roboto',
          )..addFont(File(reviewFont).readAsBytes().then(ByteData.sublistView)))
          .load();
      await (FontLoader(
            'LineageReview',
          )..addFont(File(reviewFont).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });
  setUp(() {
    binding.exitCalls = 0;
    binding.failExit = false;
  });

  testWidgets(
    'real app starts at menu; settings and new lineage lead to the introduction',
    (tester) async {
      final store = MemoryLineages();
      await tester.pumpWidget(MonstrousSeaApp(lineageStore: store));
      await tester.pumpAndSettle();
      expect(find.byType(LineageMenuScreen), findsOneWidget);
      expect(find.byType(IntroScreen), findsNothing);
      expect(
        tester
            .widget<InkButton>(find.widgetWithText(InkButton, 'CONTINUE'))
            .onPressed,
        isNull,
      );
      await click(tester, 'SETTINGS');
      expect(find.byType(SettingsDialog), findsOneWidget);
      await tester.tap(find.byTooltip('Close settings'));
      await tester.pumpAndSettle();
      await click(tester, 'NEW LINEAGE');
      await click(tester, 'CREATE LINEAGE');
      expect(find.text('Enter a label for this save.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('lineage-label')),
        'New family',
      );
      await click(tester, 'CREATE LINEAGE');
      expect(find.byType(IntroScreen), findsOneWidget);
      expect(store.slots.single.label, 'New family');
      expect(store.saves.values.single.profile.unlockedBlueprints, {
        'standard',
      });
      await click(tester, 'TITLE MENU');
      expect(find.byType(LineageMenuScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'other fate opens a branch, retries failure, then resumes the same changed save',
    (tester) async {
      final store = MemoryLineages();
      final source = store.seed(
        'Peaceful',
        completed: true,
        withSnapshot: true,
      );
      await tester.pumpWidget(MonstrousSeaApp(lineageStore: store));
      await tester.pumpAndSettle();
      store.failBranch = true;
      await click(tester, 'EXPLORE THE OTHER FATE');
      expect(store.slots, hasLength(1));
      expect(
        find.textContaining('alternate fate could not be opened'),
        findsOneWidget,
      );
      store.failBranch = false;
      await click(tester, 'RETRY');
      await click(tester, 'EXPLORE THE OTHER FATE');
      expect(store.slots, hasLength(2));
      final choice = EldritchLore.calderaClimax[CalderaClimaxChoice.claimCore]!;
      await click(tester, choice.displayName.toUpperCase());
      await click(tester, 'CHOOSE AN HEIR');
      await click(tester, 'TITLE MENU');
      final alternate = store.slots.last;
      expect(alternate.alternateOf, source.id);
      expect(store.saves[alternate.id]!.profile.ascensionLoopCount, 1);
      expect(store.saves[source.id]!.profile.hasShatteredFont, isTrue);
      await tester.ensureVisible(find.byKey(ValueKey('select-${source.id}')));
      await tester.tap(find.byKey(ValueKey('select-${source.id}')));
      await tester.pumpAndSettle();
      await click(tester, 'CONTINUE OTHER FATE');
      expect(store.slots, hasLength(2));
      expect(find.text(choice.promptTitle), findsNothing);
      expect(store.saves[alternate.id]!.profile.ascensionLoopCount, 1);
      await click(tester, 'TITLE MENU');
    },
  );

  for (final size in [const Size(360, 900), const Size(1600, 1000)]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('prologue controls share its frame at $size / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = MemoryLineages();
        final captureKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: MonstrousSeaApp(lineageStore: store),
          ),
        );
        await tester.pumpAndSettle();
        await newLineage(tester, 'Original Lineage');
        // Override the real app's chosen scale while keeping its complete shell.
        final introContext = tester.element(find.byType(IntroScreen));
        // Set the supported scale through the application's settings model.
        final settings = GameSettings.instance;
        final previousScale = settings.fontScale;
        settings.setFontScale(scale);
        addTearDown(() => settings.setFontScale(previousScale));
        await tester.pump(const Duration(seconds: 60));
        await tester.pump(const Duration(milliseconds: 600));
        expect(introContext.mounted, isTrue);
        final border = find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is CartoucheBorderPainter,
        );
        expect(border, findsOneWidget);
        final interior = tester.getRect(border).deflate(12);
        for (final text in [
          'Original Lineage',
          'TITLE MENU',
          'PLAYTEST MENU  •  F10',
          'EMBARK UPON THE HUNT',
        ]) {
          final control = tester.getRect(find.text(text));
          expect(
            interior.contains(control.topLeft),
            isTrue,
            reason: '$text above/outside frame',
          );
          expect(
            interior.contains(control.bottomRight),
            isTrue,
            reason: '$text below/outside frame',
          );
        }
        expect(tester.takeException(), isNull);
        if (reviewFont.isNotEmpty && scale == 1.3) {
          await tester.runAsync(() async {
            final image = await tester
                .renderObject<RenderRepaintBoundary>(find.byKey(captureKey))
                .toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('build/framed-intro-${size.width.toInt()}.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
        await click(tester, 'TITLE MENU');
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
    'switching lineages saves home preparation and resumes the correct captain',
    (tester) async {
      final store = MemoryLineages();
      final original = store.seed('Original');
      GameController? active;
      await tester.pumpWidget(
        MaterialApp(
          home: LineageMenuScreen(
            store: store,
            gameBuilder: (controller, returnToMenu) {
              active = controller;
              return GameOrchestratorView(
                controller: controller,
                skipIntro: true,
                onReturnToMenu: returnToMenu,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await click(tester, 'CONTINUE');
      expect(find.byType(PortScreen), findsOneWidget);
      active!.ship!.gold = 777;
      await click(tester, 'TITLE MENU');
      expect(store.saves[original.id]!.voyage!.ship.gold, 777);
      await newLineage(tester, 'Second');
      expect(active!.profile.hasBegunFirstVoyage, isFalse);
      expect(active!.profile.metaInventory.seaGlass, 0);
      await click(tester, 'TITLE MENU');
      final selectOriginal = find.byKey(ValueKey('select-${original.id}'));
      await tester.ensureVisible(selectOriginal);
      await tester.tap(selectOriginal);
      await tester.pumpAndSettle();
      await click(tester, 'CONTINUE');
      expect(active!.captainName, 'Captain Original');
      expect(active!.ship!.gold, 777);
      await click(tester, 'TITLE MENU');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completed lineage can return to menu without erasing its ending',
    (tester) async {
      final store = MemoryLineages()..seed('Completed', completed: true);
      await tester.pumpWidget(MonstrousSeaApp(lineageStore: store));
      await tester.pumpAndSettle();
      expect(find.text('Completed hunt · Ending preserved'), findsOneWidget);
      await click(tester, 'CONTINUE');
      expect(find.byType(HuntEndedScreen), findsOneWidget);
      expect(find.text('RETURN TO MENU'), findsOneWidget);
      await click(tester, 'RETURN TO MENU');
      expect(find.byType(LineageMenuScreen), findsOneWidget);
      await newLineage(tester, 'Fresh');
      expect(store.saves.values.first.profile.hasShatteredFont, isTrue);
      expect(store.saves.values.last.profile.hasShatteredFont, isFalse);
      await click(tester, 'TITLE MENU');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'encounters block menu departure; failed and delayed saves protect the active game',
    (tester) async {
      final store = MemoryLineages()..seed('At sea');
      GameController? active;
      var bodyClicks = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: LineageMenuScreen(
            store: store,
            gameBuilder: (controller, _) {
              active = controller;
              return ParchmentScaffold(
                body: TextButton(
                  onPressed: () => bodyClicks++,
                  child: const Text('BODY ACTION'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await click(tester, 'CONTINUE');
      for (final phase in [
        SessionPhase.battle,
        SessionPhase.shrine,
        SessionPhase.smuggler,
        SessionPhase.respiteIsland,
      ]) {
        active!.session.phase = phase;
        active!.notify();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'TITLE MENU'))
              .onPressed,
          isNull,
        );
        final context = tester.element(find.text('BODY ACTION'));
        await Navigator.of(context).maybePop();
        await tester.pumpAndSettle();
        expect(find.text('BODY ACTION'), findsOneWidget);
      }
      active!.session.phase = SessionPhase.port;
      active!.notify();
      await tester.pumpAndSettle();
      final save = store.saves.values.single..failSave = true;
      await click(tester, 'TITLE MENU');
      expect(
        find.textContaining('Could not save your progress'),
        findsOneWidget,
      );
      expect(find.text('BODY ACTION'), findsOneWidget);
      save.failSave = false;
      save.saveGate = Completer<void>();
      await tester.tap(find.text('TITLE MENU'));
      await tester.pump();
      await tester.tap(find.text('BODY ACTION'), warnIfMissed: false);
      expect(bodyClicks, 0);
      expect(find.text('SAVING…'), findsOneWidget);
      save.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LineageMenuScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalog, create and open failures are retryable and never start fresh gameplay',
    (tester) async {
      final store = MemoryLineages()
        ..seed('Preserved')
        ..failLoad = true;
      await tester.pumpWidget(MonstrousSeaApp(lineageStore: store));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be loaded'), findsOneWidget);
      expect(find.byType(IntroScreen), findsNothing);
      store.failLoad = false;
      await click(tester, 'RETRY');
      store.failOpen = true;
      await click(tester, 'CONTINUE');
      expect(find.textContaining('could not be opened'), findsOneWidget);
      expect(find.byType(PortScreen), findsNothing);
      store.failOpen = false;
      await click(tester, 'RETRY');
      store.failCreate = true;
      await newLineage(tester, 'Unwritten');
      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(store.slots, hasLength(1));
      store.failCreate = false;
      await click(tester, 'RETRY');
      await click(tester, 'CONTINUE');
      expect(find.byType(PortScreen), findsOneWidget);
      await click(tester, 'TITLE MENU');
    },
  );

  testWidgets('title-menu exit retries platform failures', (tester) async {
    await tester.pumpWidget(MonstrousSeaApp(lineageStore: MemoryLineages()));
    await tester.pumpAndSettle();
    binding.failExit = true;
    await click(tester, 'EXIT GAME');
    expect(find.textContaining('could not close'), findsOneWidget);
    binding.failExit = false;
    await click(tester, 'EXIT GAME');
    expect(binding.exitCalls, 2);
    expect(find.textContaining('could not close'), findsNothing);
  });

  testWidgets(
    'F10 remains reachable inside a slotted game and resumes the same captain',
    (tester) async {
      final store = MemoryLineages()..seed('Original');
      final profileBefore = store.saves.values.single.profile.toJson();
      await tester.pumpWidget(MonstrousSeaApp(lineageStore: store));
      await tester.pumpAndSettle();
      await click(tester, 'CONTINUE');
      expect(find.byType(PortScreen), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(find.byType(PlaytestScreen), findsOneWidget);
      await click(tester, 'CLOSE');
      expect(find.byType(PortScreen), findsOneWidget);
      expect(store.saves.values.single.profile.toJson(), profileBefore);
      await click(tester, 'TITLE MENU');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an unreadable selected slot can retry without blocking another save',
    (tester) async {
      final store = MemoryLineages();
      final first = store.seed('Needs repair');
      final second = store.seed('Healthy');
      store.unreadable.add(first.id);
      await tester.pumpWidget(MonstrousSeaApp(lineageStore: store));
      await tester.pumpAndSettle();
      expect(find.text('RETRY LOAD'), findsOneWidget);
      expect(
        tester
            .widget<InkButton>(find.widgetWithText(InkButton, 'CONTINUE'))
            .onPressed,
        isNull,
      );
      final select = find.byKey(ValueKey('select-${second.id}'));
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      await click(tester, 'CONTINUE');
      expect(store.active, second.id);
      await click(tester, 'TITLE MENU');
      store.unreadable.clear();
      await click(tester, 'RETRY LOAD');
      expect(find.text('Save could not be read.'), findsNothing);
    },
  );

  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('menu and new-lineage dialog fit at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = MemoryLineages()
          ..seed('Original Lineage')
          ..seed('A completed family with a long save label', completed: true);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: InkTheme.themeData.copyWith(
                textTheme: InkTheme.themeData.textTheme.apply(
                  fontFamily: reviewFont.isEmpty ? null : 'LineageReview',
                ),
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: LineageMenuScreen(
                store: store,
                gameBuilder: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (reviewFont.isNotEmpty && scale == 1.3) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(key),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final output = File('build/lineage-menu-${width.toInt()}.png');
              await output.parent.create(recursive: true);
              await output.writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
        await click(tester, 'NEW LINEAGE');
        await tester.enterText(
          find.byKey(const ValueKey('lineage-label')),
          'A new beginning',
        );
        expect(tester.takeException(), isNull);
        await click(tester, 'CANCEL');
      });
    }
  }
}
