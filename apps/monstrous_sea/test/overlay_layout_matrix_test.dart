import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/playtest/playtest_host.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/services/caldera_snapshot.dart';
import 'package:monstrous_sea/src/settings/game_settings.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';
import 'package:monstrous_sea/src/widgets/pause_menu.dart';
import 'package:monstrous_sea/src/widgets/settings_dialog.dart';
import 'package:monstrous_sea/src/widgets/vessel_inspection.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;

enum Pane {
  pauseSaved,
  pauseUnsaved,
  pauseBlocked,
  pausePlaying,
  pauseNoTitle,
  pauseSaveError,
  pauseSaving,
  pauseExitError,
  settings,
  settingsInPause,
  settingsLive,
  inspection,
  inspectionNested,
  keyword,
  nested,
  pointerNested,
  actionNested,
  nativeTooltip,
  resizeHelp,
  helpSettings,
}

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  int exits = 0;
  @override
  Future<ui.AppExitResponse> exitApplication(
    ui.AppExitType type, [
    int exitCode = 0,
  ]) async {
    exits++;
    return ui.AppExitResponse.cancel;
  }
}

class _Store extends StorageService {
  _Store() : super(baseDirectory: Directory('unused-overlay-layout-fixture'));
  bool fail = false;
  Completer<void>? gate;
  int writes = 0;
  @override
  Future<void> saveProfile(ProfileData value) async {
    writes++;
    await gate?.future;
    if (fail) throw const FileSystemException('Fixture save failure');
  }

  @override
  Future<void> saveVoyage(VoyageSaveData value) async {}
  @override
  Future<bool> clearVoyage() async => true;
  @override
  Future<void> saveCalderaSnapshot(CalderaSnapshot value) async {}
}

GameController _fixture(
  Pane pane,
  _Store store, {
  BlueprintId hull = BlueprintId.bombardier,
  OceanPower power = OceanPower.tempestSovereign,
  bool fresh = false,
  SessionPhase phase = SessionPhase.port,
}) {
  final s = GameSession(rng: SeededGameRng(42))
    ..dispatch(
      const NameCaptain(
        'Alexandrina Waverley-Montgomery of the Saltbound Watch',
      ),
    );
  s.profile.unlockedBlueprints.add(hull.name);
  s.profile.blueprintArmamentTiers[hull.name] = fresh ? 1 : 3;
  s.profile.hasExpandedAuxiliarySlot = !fresh;
  s.profile.unlockedEldritchRelics.addAll(
    EldritchRelicId.values.map((r) => r.name),
  );
  s.profile.activeEldritchRelics.addAll(s.profile.unlockedEldritchRelics);
  s.dispatch(CommissionBlueprint(hull));
  s.activeBoon = BloodlineTrait.quartermaster;
  s.activeQuirk = BloodlineTrait.impatient;
  s.syncCaptainTraits();
  final ship = s.ship!;
  ship.name = 'The Unreturning Waverley-Montgomery Bloodbound Flagship';
  ship.currentHp = ship.maxHp ~/ 3;
  if (!fresh) {
    for (final slot in blessingHardpoints) {
      temperShipHardpoint(ship, slot);
      temperShipHardpoint(ship, slot);
      ship.blessings[slot] = HardpointBlessing(
        power: power,
        slot: slot,
        tier: 3,
      );
    }
    for (var i = 0; i < ship.maxCargo; i++) {
      ship.cargo.add(
        generateConsumable(
          ConsumableType.values[i % ConsumableType.values.length],
          RarityLevel.common,
        ),
      );
    }
  }
  s.currentMonster =
      createMonster(
          MonsterSpecies.squid,
          level: 9,
          isApex: true,
          rng: SeededGameRng(7),
        )
        ..spotterFlareTurns = 2
        ..spotterFlareAccuracyBonus = 23
        ..spotterFlareBlastBonus = .4;
  s.phase = pane == Pane.pauseBlocked ? SessionPhase.battle : phase;
  final c = GameController(
    session: s,
    storage: store,
    autoSave: pane.name.startsWith('pause') && pane != Pane.pauseUnsaved,
    retainPreparationCheckpoints: true,
  );
  c.isPlayingEvents = pane == Pane.pausePlaying;
  return c;
}

String snapshot(GameController c) => jsonEncode({
  'profile': c.profile.toJson(),
  'ship': c.ship!.toJson(),
  'chart': c.seaChart.toJson(),
  'phase': c.phase.name,
  'playing': c.isPlayingEvents,
  'hp': c.currentMonster!.currentHp,
});

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> checkControls(
  WidgetTester tester,
  Finder scope,
  Size size, {
  bool allText = false,
}) async {
  expect(tester.takeException(), isNull);
  for (final element
      in find
          .descendant(of: scope, matching: find.byType(InkButton))
          .evaluate()
          .toList()) {
    final target = find.byElementPredicate((e) => identical(e, element));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    final label = (element.widget as InkButton).label;
    expect(target.hitTestable(), findsOneWidget, reason: label);
    final rect = tester.getRect(target);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(size.width));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(size.height));
    for (final text
        in find
            .descendant(of: target, matching: find.byType(RichText))
            .evaluate()) {
      expect(
        (text.renderObject! as RenderParagraph).didExceedMaxLines,
        isFalse,
        reason: 'Clipped action: $label',
      );
    }
  }
  if (allText) {
    for (final text
        in find
            .descendant(of: scope, matching: find.byType(RichText))
            .evaluate()) {
      expect(
        (text.renderObject! as RenderParagraph).didExceedMaxLines,
        isFalse,
        reason:
            'Clipped dialog text: ${(text.widget as RichText).text.toPlainText()}',
      );
    }
  }
  expect(tester.takeException(), isNull);
}

void checkHelp(WidgetTester tester, String term, Size size) {
  final help = find.byKey(ValueKey('mechanic-help-$term'));
  expect(help, findsOneWidget);
  final rect = tester.getRect(help);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(size.height));
  expect(find.byTooltip('Close explanation'), findsNothing);
  expect(find.byKey(ValueKey('mechanic-dismiss-$term')), findsOneWidget);
  for (final text
      in find
          .descendant(of: help, matching: find.byType(RichText))
          .evaluate()) {
    expect(
      (text.renderObject! as RenderParagraph).didExceedMaxLines,
      isFalse,
      reason: 'Clipped keyword: $term',
    );
  }
}

Future<void> review(
  WidgetTester tester,
  Pane pane,
  Size size, {
  double scale = 1.15,
  BlueprintId hull = BlueprintId.bombardier,
  OceanPower power = OceanPower.tempestSovereign,
  bool fresh = false,
  bool plain = false,
  Alignment anchor = Alignment.topLeft,
  String term = 'Static Charge',
  SessionPhase phase = SessionPhase.port,
  bool proof = false,
}) async {
  final settings = GameSettings.instance;
  final oldScale = settings.fontScale, oldPlain = settings.highLegibilityFont;
  settings.setFontScale(scale);
  settings.setHighLegibilityFont(plain);
  addTearDown(() {
    settings.setFontScale(oldScale);
    settings.setHighLegibilityFont(oldPlain);
  });
  final store = _Store();
  final c = _fixture(
    pane,
    store,
    hull: hull,
    power: power,
    fresh: fresh,
    phase: phase,
  );
  addTearDown(c.dispose);
  final before = snapshot(c);
  final exitsBefore = (TestWidgetsFlutterBinding.instance as _Binding).exits;
  var actions = 0, returns = 0;
  final key = GlobalKey();
  await mountChartFocus(
    tester,
    const SizedBox.shrink(),
    GlobalKey(),
    size,
    scale: scale,
  );
  final helpMode = [
    Pane.keyword,
    Pane.nested,
    Pane.pointerNested,
    Pane.actionNested,
    Pane.nativeTooltip,
    Pane.resizeHelp,
    Pane.helpSettings,
  ].contains(pane);
  final mechanics = MechanicContext(
    ship: c.ship,
    monster: c.currentMonster,
    regionIndex: 2,
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          theme: InkTheme.themeData,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.fontScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: PlaytestHost(
            gameBuilder: (_) => const SizedBox.shrink(),
            child: PauseMenuHost(
              controller: c,
              label: 'The Waverley-Montgomery Lineage and its Everlasting Hunt',
              onReturnToTitle: pane == Pane.pauseNoTitle
                  ? null
                  : () => returns++,
              child: ParchmentScaffold(
                body: Builder(
                  builder: (context) => helpMode
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Align(
                            alignment: anchor,
                            child: SizedBox(
                              width: 180,
                              child: MechanicScope(
                                data: mechanics,
                                child: pane == Pane.nativeTooltip
                                    ? Tooltip(
                                        message: c
                                            .ship!
                                            .equippedWeapons
                                            .first
                                            .description,
                                        child: IconButton(
                                          key: const ValueKey('native-tip'),
                                          onPressed: () => actions++,
                                          icon: const Icon(Icons.info_outline),
                                        ),
                                      )
                                    : pane == Pane.actionNested
                                    ? MechanicTooltip(
                                        message: 'Applies Static Charge.',
                                        child: InkButton(
                                          label: 'ACTION',
                                          onPressed: () => actions++,
                                        ),
                                      )
                                    : MechanicText(term, mechanics: mechanics),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkButton(
                                  label: 'OPEN PAUSE',
                                  onPressed: PauseMenuScope.maybeOf(context)!
                                      .openMenu,
                                ),
                                InkButton(
                                  label: 'OPEN SETTINGS',
                                  onPressed: () => SettingsDialog.show(context),
                                ),
                                InspectVesselButton(controller: c),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final suffix =
      '${pane.name}-${size.width.toInt()}-$scale-${plain ? 'plain' : 'ink'}-${hull.index}${power.index}${fresh ? 'f' : 'm'}-${anchor.x.toInt()}${anchor.y.toInt()}-${term.replaceAll(' ', '_')}';
  if (pane.name.startsWith('pause') || pane == Pane.settingsInPause) {
    final previous = Focus.of(tester.element(find.text('OPEN PAUSE')));
    previous.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('PAUSED'), findsOneWidget);
    const checkpoints = {
      SessionPhase.captainCreation,
      SessionPhase.port,
      SessionPhase.stronghold,
      SessionPhase.merchant,
      SessionPhase.helm,
      SessionPhase.loot,
      SessionPhase.shipwreck,
      SessionPhase.expeditionVictory,
      SessionPhase.death,
      SessionPhase.ended,
    };
    final allowed = checkpoints.contains(c.phase) && !c.isPlayingEvents;
    expect(
      tester
              .widget<InkButton>(find.byKey(const ValueKey('pause-exit')))
              .onPressed !=
          null,
      allowed,
    );
    expect(
      tester
              .widget<InkButton>(find.byKey(const ValueKey('pause-return')))
              .onPressed !=
          null,
      allowed && pane != Pane.pauseNoTitle,
    );
    if (pane == Pane.pauseSaveError || pane == Pane.pauseSaving) {
      store.fail = pane == Pane.pauseSaveError;
      if (pane == Pane.pauseSaving) store.gate = Completer<void>();
      await tap(tester, find.byKey(const ValueKey('pause-return')));
      expect(store.writes, 1);
      if (pane == Pane.pauseSaveError) {
        expect(
          find.textContaining('Could not save your progress'),
          findsOneWidget,
        );
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(find.text('PAUSED'), findsOneWidget);
      }
    } else if (pane == Pane.pauseExitError) {
      await tap(tester, find.byKey(const ValueKey('pause-exit')));
      expect(find.textContaining('The game could not close'), findsOneWidget);
    }
    if (proof) await captureChartFocusProof(tester, key, suffix);
    await checkControls(tester, find.byType(AlertDialog), size);
    if (pane == Pane.settingsInPause) {
      await tap(tester, find.byKey(const ValueKey('pause-settings')));
      await checkControls(
        tester,
        find.byType(SettingsDialog),
        size,
        allText: true,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsDialog), findsNothing);
      expect(find.text('PAUSED'), findsOneWidget);
    }
    if (pane != Pane.pauseSaving) {
      await tap(tester, find.byKey(const ValueKey('pause-resume')));
      expect(find.text('PAUSED'), findsNothing);
      expect(previous.hasPrimaryFocus, isTrue);
    }
  } else if (pane == Pane.settings || pane == Pane.settingsLive) {
    await tap(tester, find.text('OPEN SETTINGS'));
    if (proof) await captureChartFocusProof(tester, key, suffix);
    await checkControls(
      tester,
      find.byType(SettingsDialog),
      size,
      allText: true,
    );
    if (pane == Pane.settingsLive) {
      for (final label in [
        'Normal',
        'Extra Large',
        'Large',
        'High Legibility',
        'Atmospheric Ink',
      ]) {
        await tap(tester, find.text(label));
        await checkControls(
          tester,
          find.byType(SettingsDialog),
          size,
          allText: true,
        );
      }
    }
    await tap(tester, find.text('DONE'));
    expect(find.byType(SettingsDialog), findsNothing);
  } else if (pane == Pane.inspection || pane == Pane.inspectionNested) {
    await tap(tester, find.text('INSPECT VESSEL'));
    if (proof) await captureChartFocusProof(tester, key, suffix);
    await checkControls(tester, find.byType(Dialog), size, allText: true);
    if (proof) await captureChartFocusProof(tester, key, '$suffix-controls');
    if (pane == Pane.inspectionNested) {
      await tap(
        tester,
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.text('Static Charge'),
            )
            .first,
      );
      checkHelp(tester, 'Static Charge', size);
      await tap(
        tester,
        find
            .descendant(
              of: find.byKey(const ValueKey('mechanic-help-Static Charge')),
              matching: find.text('Arc Discharge'),
            )
            .first,
      );
      checkHelp(tester, 'Arc Discharge', size);
      if (proof) await captureChartFocusProof(tester, key, '$suffix-help');
      for (final term in ['Arc Discharge', 'Static Charge']) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('mechanic-help-$term')), findsNothing);
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('PAUSED'), findsNothing);
      }
    }
    await tap(tester, find.text('CLOSE INSPECTION'));
    expect(find.byType(Dialog), findsNothing);
  } else if (pane == Pane.nativeTooltip) {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('native-tip'))),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(c.ship!.equippedWeapons.first.description),
      findsOneWidget,
    );
    final box = tester.getRect(
      find.text(c.ship!.equippedWeapons.first.description),
    );
    expect(box.left, greaterThanOrEqualTo(0));
    expect(box.right, lessThanOrEqualTo(size.width));
    expect(box.top, greaterThanOrEqualTo(0));
    expect(box.bottom, lessThanOrEqualTo(size.height));
    if (proof) await captureChartFocusProof(tester, key, suffix);
    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(seconds: 1));
  } else {
    final chain = <String>[];
    TestGesture? mouse;
    if (pane == Pane.pointerNested) {
      // PlaytestHost has its own outer autofocus. Keep game shortcuts in the
      // active game's focus path before testing help that does not take focus.
      var gameFocus = Focus.of(tester.element(find.byType(MechanicText).first));
      while (!gameFocus.canRequestFocus) {
        gameFocus = gameFocus.parent!;
      }
      gameFocus.requestFocus();
      await tester.pump();
      mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text(term)));
      await tester.pumpAndSettle();
    } else if (pane == Pane.actionNested) {
      final focus = Focus.of(tester.element(find.text('ACTION')));
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      chain.add('action');
      await tap(tester, find.text('Static Charge').last);
    } else {
      await tap(tester, find.text(term));
    }
    chain.add(term);
    checkHelp(tester, term, size);
    if (pane == Pane.helpSettings) {
      SettingsDialog.show(tester.element(find.byType(MechanicText).first));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsDialog), findsNothing);
      checkHelp(tester, term, size);
      expect(find.text('PAUSED'), findsNothing);
    }
    if ([Pane.nested, Pane.pointerNested, Pane.actionNested].contains(pane)) {
      if (mouse != null) {
        await mouse.moveTo(tester.getCenter(find.text('Arc Discharge')));
        await tester.pumpAndSettle();
      } else {
        await tap(tester, find.text('Arc Discharge'));
      }
      chain.add('Arc Discharge');
      checkHelp(tester, 'Arc Discharge', size);
      if (pane == Pane.nested) {
        await tap(tester, find.text('Stun'));
        chain.add('Stun');
        checkHelp(tester, 'Stun', size);
        if (size.width >= 1280) {
          final cards = chain
              .map(
                (term) =>
                    tester.getRect(find.byKey(ValueKey('mechanic-help-$term'))),
              )
              .toList();
          for (var i = 0; i < cards.length; i++) {
            for (var j = i + 1; j < cards.length; j++) {
              expect(
                cards[i].overlaps(cards[j]),
                isFalse,
                reason: 'Nested help should use available desktop space.',
              );
            }
          }
        }
      }
    }
    if (proof) await captureChartFocusProof(tester, key, suffix);
    if (pane == Pane.resizeHelp) {
      for (final resized in [const Size(360, 900), size]) {
        tester.view.physicalSize = resized;
        await tester.pumpAndSettle();
        checkHelp(tester, term, resized);
      }
    }
    var firstEscape = true;
    for (final open in chain.reversed) {
      if (pane == Pane.pointerNested) {
        if (firstEscape) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
        } else {
          await tester.sendKeyRepeatEvent(LogicalKeyboardKey.escape);
        }
        firstEscape = false;
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      }
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('mechanic-help-$open')),
        findsNothing,
        reason: 'Escape must close the front help before opening Pause.',
      );
      expect(find.text('PAUSED'), findsNothing);
    }
    if (pane == Pane.pointerNested) {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('PAUSED'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('pause-resume')));
  }
  expect(snapshot(c), before);
  expect(actions, 0);
  expect(returns, 0);
  expect(
    (TestWidgetsFlutterBinding.instance as _Binding).exits,
    exitsBefore + (pane == Pane.pauseExitError ? 1 : 0),
  );
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
  store.gate?.complete();
  await tester.pumpAndSettle();
}

void main() {
  _Binding();
  setUpAll(() async {
    InkTheme.disableGoogleFonts = const String.fromEnvironment('artFontCache')
        .isEmpty;
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final testPackage = packages.cast<Map>().singleWhere(
      (p) => p['name'] == 'flutter_test',
    );
    final sdk = Directory.fromUri(
      config.uri.resolve(testPackage['rootUri'] as String),
    ).parent.parent;
    final loader = FontLoader('Roboto');
    for (final face in ['regular', 'bold', 'italic', 'bolditalic']) {
      loader.addFont(
        File('${sdk.path}/bin/cache/artifacts/material_fonts/roboto-$face.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    }
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  const sizes = [Size(360, 900), Size(800, 480), Size(1280, 850)];
  for (final pane in Pane.values) {
    for (final size in sizes) {
      testWidgets(
        '115% ${pane.name} $size',
        (tester) => review(
          tester,
          pane,
          size,
          proof:
              size.width == 360 ||
              (size.width == 800 &&
                  [
                    Pane.settings,
                    Pane.inspection,
                    Pane.pauseSaving,
                  ].contains(pane)),
        ),
      );
    }
  }
  for (final phase in SessionPhase.values) {
    for (final size in [sizes.first, sizes.last]) {
      testWidgets(
        'Pause checkpoint ${phase.name} $size',
        (tester) => review(tester, Pane.pauseSaved, size, phase: phase),
      );
    }
  }
  for (final hull in BlueprintId.values) {
    for (final size in sizes) {
      testWidgets(
        'Fresh inspection ${hull.name} $size',
        (tester) =>
            review(tester, Pane.inspection, size, hull: hull, fresh: true),
      );
      for (final power in OceanPower.values) {
        testWidgets(
          'Full inspection ${hull.name} ${power.name} $size',
          (tester) =>
              review(tester, Pane.inspection, size, hull: hull, power: power),
        );
      }
    }
  }
  const terms = [
    'Burning',
    'Illuminated',
    'Static Charge',
    'Arc Discharge',
    'Corroded',
    'Pinned',
    'Carapace',
    'Critical Hits',
    'Shaken',
    'Obscurity',
    'Anchored',
    'Grappled',
    'Stun',
    'Poison',
    'Frenzy',
    'Electro-Jolt',
    'Thermal Detonation',
  ];
  for (final term in terms) {
    for (final size in sizes) {
      testWidgets(
        'Keyword $term $size',
        (tester) => review(tester, Pane.keyword, size, term: term),
      );
    }
  }
  for (final scale in [1.15, 1.3]) {
    for (final size in sizes) {
      for (final pane in [
        Pane.settingsLive,
        Pane.settingsInPause,
        Pane.inspectionNested,
        Pane.nested,
      ]) {
        testWidgets(
          'Plain $scale ${pane.name} $size',
          (tester) => review(
            tester,
            pane,
            size,
            scale: scale,
            plain: true,
            proof: size.width == 360,
          ),
        );
      }
    }
    for (final anchor in [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ]) {
      for (final pane in [Pane.nested, Pane.actionNested, Pane.nativeTooltip]) {
        testWidgets(
          'Corner $scale $anchor ${pane.name}',
          (tester) => review(
            tester,
            pane,
            sizes.last,
            scale: scale,
            anchor: anchor,
            proof: anchor == Alignment.bottomRight,
          ),
        );
      }
    }
  }
}
