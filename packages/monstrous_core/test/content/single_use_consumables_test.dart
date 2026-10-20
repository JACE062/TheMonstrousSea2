import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _HitRng extends SeededGameRng {
  _HitRng() : super(1);
  @override
  int d100() => 1;
}

void main() {
  for (final type in ConsumableType.values) {
    test('${type.name} has one use and no rarity-based potency or price', () {
      for (final rarity in RarityLevel.values) {
        final item = generateConsumable(type, rarity);
        expect(item.maxUses, 1);
        expect(item.usesLeft, 1);
        expect(item.rarity, RarityLevel.common);
        expect(item.value, 25);
        final common = generateConsumable(type, RarityLevel.common);
        expect(
          resolveConsumableEffect(item, _HitRng()).damage,
          resolveConsumableEffect(common, _HitRng()).damage,
        );
      }
    });

    test('${type.name} is removed after its single combat use', () {
      final session = GameSession(rng: _HitRng())
        ..dispatch(const NameCaptain('One Bottle'))
        ..dispatch(const ChooseShip(ShipClass.standard))
        ..dispatch(const VentureOutToSea());
      session.currentMonster!.maxHp = 10000;
      session.currentMonster!.currentHp = 10000;
      final item = generateConsumable(type, RarityLevel.legendary);
      session.ship!.cargo
        ..clear()
        ..add(item);
      session.dispatch(const UseConsumableItem(0));
      expect(item.isDepleted, isTrue);
      expect(session.ship!.cargo, isEmpty);
      expect(session.battleRound, 1);
    });

    test('${type.name} legacy charges migrate without preserving rarity', () {
      final legacy = generateConsumable(type, RarityLevel.common).toJson()
        ..['name'] = 'Legendary ${type.displayName}'
        ..['rarity'] = 'legendary'
        ..['value'] = 100
        ..['maxUses'] = 4
        ..['usesLeft'] = 3;
      final migrated = Item.fromJson(legacy) as Consumable;
      expect(migrated.name, type.displayName);
      expect(migrated.type, type);
      expect(migrated.rarity, RarityLevel.common);
      expect(migrated.value, 25);
      expect(migrated.maxUses, 1);
      expect(migrated.usesLeft, 1);
      expect(Consumable.fromJson(migrated.toJson()).usesLeft, 1);
      legacy['usesLeft'] = 0;
      expect(Consumable.fromJson(legacy).isDepleted, isTrue);
      legacy.remove('usesLeft');
      expect(Consumable.fromJson(legacy).usesLeft, 1);
      legacy.remove('maxUses');
      expect(Consumable.fromJson(legacy).usesLeft, 1);
    });
  }

  test(
    'Merchant and tactical loot do not vary potency or price by difficulty',
    () {
      for (final level in [1, 3, 8]) {
        final items = [
          ...generateMerchantStock(level, SeededGameRng(17)),
          ...generateTacticalVictoryLoot(level, SeededGameRng(31), 2, 2, true),
        ];
        for (final item in items.cast<Consumable>()) {
          expect(item.maxUses, 1);
          expect(item.usesLeft, 1);
          expect(item.value, 25);
          expect(item.rarity, RarityLevel.common);
        }
      }
    },
  );

  test('Single-use items can still be tossed from cargo', () {
    final session = GameSession(rng: _HitRng())
      ..dispatch(const NameCaptain('Lighten the Hold'))
      ..dispatch(const ChooseShip(ShipClass.standard));
    session.ship!.cargo
      ..clear()
      ..add(
        generateConsumable(ConsumableType.alchemicalPitch, RarityLevel.epic),
      );
    session.dispatch(const DropCargoItem(0));
    expect(session.ship!.cargo, isEmpty);
  });
}
