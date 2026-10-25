import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/death_screen.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

GameSession titanDeath(MonsterSpecies species) {
  final session = GameSession(rng: SeededGameRng(42))
    ..dispatch(const BeginFirstVoyage('Captain Thorne'));
  session.currentMonster = createMonster(species, level: 5, rng: session.rng);
  session.ship!.applyDamage(session.ship!.maxHp);
  session.dispatch(const ExecuteShipSpecialAction());
  return session;
}

class LegacyDeathStorage extends StorageService {
  LegacyDeathStorage(this.profileJson, this.voyageJson)
    : super(baseDirectory: Directory('unused-titan-death-fixture'));
  final Map<String, dynamic> profileJson;
  final Map<String, dynamic> voyageJson;

  @override
  Future<ProfileData> loadProfile() async => ProfileData.fromJson(profileJson);
  @override
  Future<VoyageSaveData?> loadVoyage() async =>
      VoyageSaveData.fromJson(voyageJson);
}

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);

  for (final species in [
    MonsterSpecies.kraken,
    MonsterSpecies.worldSerpent,
    MonsterSpecies.ancientLeviathan,
  ]) {
    testWidgets('$species death offers heirs without Nemesis or Vendetta', (
      tester,
    ) async {
      final controller = GameController(
        session: titanDeath(species),
        autoSave: false,
      );
      await tester.pumpWidget(
        MaterialApp(home: DeathScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.text('A WATERY GRAVE'), findsOneWidget);
      expect(find.textContaining('NEMESIS ASCENDED:'), findsNothing);
      expect(find.textContaining('Vengeance Bounty:'), findsNothing);
      expect(
        find.textContaining(
          RegExp('Blood Oath|Vendetta', caseSensitive: false),
        ),
        findsNothing,
      );
      expect(controller.pendingHeirCandidates, hasLength(3));
      expect(
        controller.lineage.history.single.causeOfDeath,
        species.displayName,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }

  testWidgets(
    'legacy Titan death reload preserves heirs and removes unsupported offer',
    (tester) async {
      final session = titanDeath(MonsterSpecies.kraken);
      final original = session.pendingHeirCandidates.first;
      session.pendingHeirCandidates[0] = HeirCandidate(
        defaultName: original.defaultName,
        boon: original.boon,
        quirk: BloodlineTrait.bloodOath,
      );
      final profile = session.profile.toJson();
      profile['activeNemesis'] = const NemesisRecord(
        species: MonsterSpecies.kraken,
        baseName: 'The Kraken',
        moniker: 'The Kraken — Devourer of the Thorne Bloodline',
        predecessorCaptain: 'Captain Thorne',
        regionIndex: 0,
        level: 5,
        bonusHp: 90,
        bonusCarapace: 50,
        bountyGold: 350,
        bountySeaGlass: 15,
        bountyMonsterBone: 21,
        bountyBarnacles: 7,
      ).toJson();
      final controller = GameController(
        storage: LegacyDeathStorage(
          profile,
          VoyageSaveData.fromSession(session).toJson(),
        ),
        autoSave: false,
      );
      await controller.initializeStorage();
      await tester.pumpWidget(
        MaterialApp(home: DeathScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(controller.activeNemesis, isNull);
      expect(find.textContaining('NEMESIS ASCENDED:'), findsNothing);
      expect(
        find.textContaining(
          RegExp('Blood Oath|Vendetta', caseSensitive: false),
        ),
        findsNothing,
      );
      expect(
        controller.pendingHeirCandidates.first.defaultName,
        original.defaultName,
      );
      expect(controller.pendingHeirCandidates.first.boon.id, original.boon.id);
      expect(controller.lineage.history, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
