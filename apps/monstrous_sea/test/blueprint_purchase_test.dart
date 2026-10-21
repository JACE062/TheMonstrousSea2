import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/parchment_card.dart';

GameController returnWithMaterials({StorageService? storage}) {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    storage: storage,
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Founder'));
  controller.metaInventory.add(seaGlass: 20, monsterBone: 15);
  controller.ship!.applyDamage(controller.ship!.maxHp);
  controller.dispatch(const ExecuteShipSpecialAction());
  expect(controller.phase, SessionPhase.death);
  controller.dispatch(const ContinueLineage('Heir', ShipClass.standard));
  expect(controller.phase, SessionPhase.port);
  return controller;
}

Finder ironcladCard() => find.ancestor(
  of: find.text('BLUEPRINT: IRONCLAD'),
  matching: find.byType(ParchmentCard),
);

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);

  testWidgets(
    'first port menu keeps affordable Ironclad locked until a paid click',
    (tester) async {
      final controller = returnWithMaterials();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MonstrousSeaApp(controller: controller));
      await tester.pumpAndSettle();
      for (var visit = 0; visit < 2; visit++) {
        await tester.ensureVisible(find.text('BLUEPRINTS'));
        await tester.tap(find.text('BLUEPRINTS'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: ironcladCard(), matching: find.text('UNLOCK')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: ironcladCard(),
            matching: find.text('COMMISSION'),
          ),
          findsNothing,
        );
        expect(controller.profile.unlockedBlueprints, {'standard'});
        expect(controller.metaInventory.seaGlass, 20);
        expect(controller.metaInventory.monsterBone, 15);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('BLUEPRINTS'));
      await tester.pumpAndSettle();
      final unlock = find.descendant(
        of: ironcladCard(),
        matching: find.text('UNLOCK'),
      );
      await tester.ensureVisible(unlock);
      await tester.tap(unlock);
      await tester.pumpAndSettle();
      expect(
        controller.profile.isBlueprintUnlocked(BlueprintId.ironclad),
        isTrue,
      );
      expect(controller.metaInventory.seaGlass, 5);
      expect(controller.metaInventory.monsterBone, 5);
      final commission = find.descendant(
        of: ironcladCard(),
        matching: find.text('COMMISSION'),
      );
      await tester.ensureVisible(commission);
      await tester.tap(commission);
      await tester.pumpAndSettle();
      expect(controller.ship!.resolvedBlueprintId, BlueprintId.ironclad);
      expect(controller.metaInventory.seaGlass, 5);
      expect(controller.metaInventory.monsterBone, 5);
      expect(tester.takeException(), isNull);
    },
  );

  test('affordability, death, succession and reload never grant an unpaid blueprint', () async {
    final directory = await Directory.systemTemp.createTemp(
      'monstrous-blueprint-purchase-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = StorageService(baseDirectory: directory);
    final controller = returnWithMaterials(storage: storage);
    addTearDown(controller.dispose);
    for (var check = 0; check < 10; check++) {
      expect(
        controller.profile.canUnlockBlueprint(BlueprintId.ironclad),
        isTrue,
      );
    }
    expect(controller.profile.unlockedBlueprints, {'standard'});
    await controller.persistState();
    final restored = GameController(storage: storage, autoSave: false);
    addTearDown(restored.dispose);
    await restored.initializeStorage();
    expect(restored.profile.unlockedBlueprints, {'standard'});
    expect(restored.metaInventory.seaGlass, 20);
    expect(restored.metaInventory.monsterBone, 15);
    restored.dispatch(const NameCaptain('Returning Heir'));
    restored.dispatch(const ChooseShip(ShipClass.standard));
    restored.dispatch(const UnlockBlueprint(BlueprintId.ironclad));
    // Repeated requests cannot double-charge an already purchased blueprint.
    restored.dispatch(const UnlockBlueprint(BlueprintId.ironclad));
    await restored.persistState();
    final purchased = await storage.loadProfile();
    expect(purchased.isBlueprintUnlocked(BlueprintId.ironclad), isTrue);
    expect(purchased.metaInventory.seaGlass, 5);
    expect(purchased.metaInventory.monsterBone, 5);
    expect(purchased.isBlueprintUnlocked(BlueprintId.clipper), isFalse);
  });
}
