import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Encounter Variety: Smuggler\'s Ketch & Ancient Sea Shrine', () {
    test('Smuggler Ketch: trade contraband, repair with oak planks, and depart', () {
      final session = GameSession(rng: SeededGameRng(101));
      session.dispatch(const NameCaptain('Jack'));
      session.dispatch(const ChooseShip(ShipClass.standard));

      // Setup ship state: damaged hull and gold
      session.ship!.currentHp = 40;
      session.ship!.gold = 150;

      // Position ship right before a Smuggler's Ketch
      session.seaChart.currentRow = 1;
      session.seaChart.currentCol = 1;
      session.seaChart.setNodeTypeAt(1, 2, EncounterNodeType.smugglerTrader);
      session.phase = SessionPhase.restArea;

      // Advance into the smuggler encounter
      final advanceEvents = session.dispatch(const AdvanceToNextBattle());

      expect(session.phase, equals(SessionPhase.smuggler));
      expect(session.seaChart.isSmugglerTrader, isTrue);
      expect(session.currentSmugglerName, isNotEmpty);
      expect(session.smugglerStock, isNotEmpty);
      expect(advanceEvents.whereType<SmugglerEncountered>(), isNotEmpty);

      // Buy black market item from smuggler
      final initialStockCount = session.smugglerStock.length;
      final itemToBuy = session.smugglerStock[0];
      final itemCost = itemToBuy.value;
      final preBuyGold = session.ship!.gold;

      final buyEvents = session.dispatch(const BuyMerchantItem(0));
      expect(buyEvents.whereType<ItemAcquired>(), isNotEmpty);
      expect(session.ship!.cargo.contains(itemToBuy), isTrue);
      expect(session.ship!.gold, equals(preBuyGold - itemCost));
      expect(session.smugglerStock.length, equals(initialStockCount - 1));

      // Sell cargo item to smuggler
      final cargoIndex = session.ship!.cargo.indexOf(itemToBuy);
      final sellEvents = session.dispatch(SellCargoItem(cargoIndex));
      expect(sellEvents.whereType<ItemSold>(), isNotEmpty);
      expect(session.ship!.cargo.contains(itemToBuy), isFalse);

      // Repair with seasoned oak timbers (1.5x black market rate)
      final preRepairHp = session.ship!.currentHp;
      final repairEvents = session.dispatch(const RepairShip(0.25));
      expect(repairEvents.whereType<ShipRepaired>(), isNotEmpty);
      expect(session.ship!.currentHp, greaterThan(preRepairHp));

      // Depart smuggler continues the expedition to the helm
      session.seaChart.setNodeTypeAt(1, 3, EncounterNodeType.beastCombat);
      final departEvents = session.dispatch(const DepartSmuggler());
      expect(session.phase, equals(SessionPhase.helm));
      expect(departEvents.whereType<HelmApproached>(), isNotEmpty);

      final steerEvents = session.dispatch(
        const SteerCourse(NavigationalBearing.deadAhead),
      );
      expect(session.phase, isNot(equals(SessionPhase.helm)));
      expect(steerEvents.whereType<CourseSteered>(), isNotEmpty);
    });

    test('Ancient Sea Shrine: Offer Tribute of Gold grants sea favor accuracy boon', () {
      final session = GameSession(rng: SeededGameRng(202));
      session.dispatch(const NameCaptain('Sinbad'));
      session.dispatch(const ChooseShip(ShipClass.corvette));

      session.ship!.gold = 50;

      // Position ship right before an Ancient Sea Shrine
      session.seaChart.currentRow = 1;
      session.seaChart.currentCol = 0;
      session.seaChart.setNodeTypeAt(1, 1, EncounterNodeType.ancientShrine);
      session.phase = SessionPhase.restArea;

      // Advance into shrine
      final advanceEvents = session.dispatch(const AdvanceToNextBattle());
      expect(session.phase, equals(SessionPhase.shrine));
      expect(session.seaChart.isAncientShrine, isTrue);
      expect(session.currentShrineName, isNotEmpty);
      expect(session.currentShrineLore, isNotEmpty);
      expect(advanceEvents.whereType<ShrineDiscovered>(), isNotEmpty);

      // Offer tribute (30 gold)
      final tributeEvents = session.dispatch(
        const CommuneWithShrine(ShrineChoice.tribute),
      );
      expect(tributeEvents.whereType<ShrineCommuned>(), isNotEmpty);
      expect(session.ship!.gold, equals(20)); // 50 - 30
      expect(session.gunneryAccuracyBoon, equals(15));
      expect(session.hasCommunedAtCurrentShrine, isTrue);

      // Secondary offerings are rejected
      final repeatEvents = session.dispatch(
        const CommuneWithShrine(ShrineChoice.ancientRunes),
      );
      expect(repeatEvents.whereType<ShrineCommuned>(), isEmpty);

      // Depart shrine to helm
      session.seaChart.setNodeTypeAt(1, 2, EncounterNodeType.beastCombat);
      final departEvents = session.dispatch(const DepartShrine());
      expect(session.phase, equals(SessionPhase.helm));
      expect(departEvents.whereType<HelmApproached>(), isNotEmpty);

      final steerEvents = session.dispatch(
        const SteerCourse(NavigationalBearing.deadAhead),
      );
      expect(session.phase, isNot(equals(SessionPhase.helm)));
      expect(steerEvents.whereType<CourseSteered>(), isNotEmpty);
    });

    test('Ancient Sea Shrine: Abyssal Pact sacrifices hull integrity for a relic weapon', () {
      final session = GameSession(rng: SeededGameRng(303));
      session.dispatch(const NameCaptain('Morgan'));
      session.dispatch(const ChooseShip(ShipClass.ironclad));

      final startHp = session.ship!.currentHp;
      final cargoCount = session.ship!.cargo.length;

      // Enter shrine
      session.seaChart.currentRow = 0;
      session.seaChart.currentCol = 1;
      session.seaChart.setNodeTypeAt(0, 2, EncounterNodeType.ancientShrine);
      session.phase = SessionPhase.restArea;

      session.dispatch(const AdvanceToNextBattle());
      expect(session.phase, equals(SessionPhase.shrine));

      // Make Abyssal Pact
      final pactEvents = session.dispatch(
        const CommuneWithShrine(ShrineChoice.abyssalPact),
      );
      expect(pactEvents.whereType<ShrineCommuned>(), isNotEmpty);
      expect(pactEvents.whereType<ItemAcquired>(), isNotEmpty);
      expect(session.ship!.currentHp, lessThan(startHp));
      expect(session.ship!.cargo.length, equals(cargoCount + 1));
      expect(session.hasCommunedAtCurrentShrine, isTrue);
    });

    test('Ancient Sea Shrine: Consult Ancient Runes pierces fog across next soundings', () {
      final session = GameSession(rng: SeededGameRng(404));
      session.dispatch(const NameCaptain('Drake'));
      session.dispatch(const ChooseShip(ShipClass.freighter));

      // Enter shrine on Row 0
      session.seaChart.currentRow = 0;
      session.seaChart.currentCol = 3;
      session.seaChart.setNodeTypeAt(0, 4, EncounterNodeType.ancientShrine);
      session.phase = SessionPhase.restArea;

      session.dispatch(const AdvanceToNextBattle());
      expect(session.phase, equals(SessionPhase.shrine));

      // Row 1 is currently obscured in fog
      expect(session.seaChart.isRevealed(1, 0), isFalse);
      expect(session.seaChart.isRevealed(1, 1), isFalse);
      expect(session.seaChart.isRevealed(1, 2), isFalse);

      // Consult ancient runes
      final runeEvents = session.dispatch(
        const CommuneWithShrine(ShrineChoice.ancientRunes),
      );
      expect(runeEvents.whereType<ShrineCommuned>(), isNotEmpty);
      expect(session.gunneryAccuracyBoon, equals(10));

      // Fog is lifted across all columns of Row 1!
      expect(session.seaChart.isRevealed(1, 0), isTrue);
      expect(session.seaChart.isRevealed(1, 1), isTrue);
      expect(session.seaChart.isRevealed(1, 2), isTrue);
      expect(session.seaChart.isRevealed(1, 3), isTrue);
      expect(session.seaChart.isRevealed(1, 4), isTrue);

      // But Row 2 remains obscured in fog
      expect(session.seaChart.isRevealed(2, 0), isFalse);
    });
  });
}
