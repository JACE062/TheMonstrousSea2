import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

GameSession _shop({int seed = 1}) {
  final s = GameSession(rng: SeededGameRng(seed))
    ..dispatch(const BeginFirstVoyage('Trade'));
  s.ship!
    ..gold = 500
    ..currentHp = 1;
  s.phase = SessionPhase.stronghold;
  s.refreshMerchantStock(1, true);
  s.dispatch(const VisitMerchant());
  return s;
}

GameSession _reload(GameSession s) {
  final restored = GameSession(
    rng: SeededGameRng(999),
    profile: ProfileData.fromJson(s.profile.toJson()),
  );
  VoyageSaveData.fromJson(VoyageSaveData.fromSession(s).toJson())
      .restoreToSession(restored);
  return restored;
}

void main() {
  test('materials do not consume consumable rolls or belt slots, persist and deplete once', () {
    var s = _shop();
    final stock = s.merchantMaterials!;
    final supplies = s.merchantStock.map((i) => i.toJson()).toList();
    for (var i = 0; i < s.ship!.maxCargo; i++) {
      s.ship!.cargo.add(
        generateConsumable(ConsumableType.blastPack, RarityLevel.common),
      );
    }
    final qty = stock.seaGlass;
    final before = s.ship!.gold;
    final events = s.dispatch(
      BuyMerchantMaterial(stock.id, TradeMaterial.seaGlass, quantity: qty),
    );
    expect(events.whereType<MaterialPurchased>().single.goldCost, qty * 15);
    expect(s.ship!.gold, before - qty * 15);
    expect(s.profile.metaInventory.seaGlass, qty);
    expect(s.merchantStock.map((i) => i.toJson()).toList(), supplies);
    expect(s.ship!.cargo, hasLength(s.ship!.maxCargo));
    s = _reload(s);
    expect(s.merchantMaterials!.seaGlass, 0);
    s.dispatch(const LeaveMerchant());
    s.dispatch(const VisitMerchant());
    s.dispatch(BuyMerchantMaterial(stock.id, TradeMaterial.seaGlass));
    expect(s.profile.metaInventory.seaGlass, qty);
    expect(s.ship!.gold, before - qty * 15);
    expect(s.merchantMaterials!.depthWroughtIron, stock.depthWroughtIron);
  });

  test(
    'failed, stale, negative and off-site purchases do not mutate anything',
    () {
      final s = _shop();
      final stock = s.merchantMaterials!;
      final original = stock.toJson();
      s.ship!.gold = 0;
      s.dispatch(BuyMerchantMaterial(stock.id, TradeMaterial.depthWroughtIron));
      expect(stock.toJson(), original);
      expect(s.profile.metaInventory.isEmpty, isTrue);
      expect(
        () => s.dispatch(
          BuyMerchantMaterial(stock.id, TradeMaterial.seaGlass, quantity: 0),
        ),
        throwsArgumentError,
      );
      expect(
        () => s.dispatch(
          const BuyMerchantMaterial('stale', TradeMaterial.seaGlass),
        ),
        throwsStateError,
      );
      s.phase = SessionPhase.stronghold;
      expect(
        () => s.dispatch(BuyMerchantMaterial(stock.id, TradeMaterial.seaGlass)),
        throwsStateError,
      );
    },
  );

  test('independent shipments, same regional distributions, absent ketch result stays empty', () {
    for (var seed = 0; seed < 100; seed++) {
      final a = generateMaterialShipment(
        'a',
        SeededGameRng(seed),
        ketch: false,
      );
      final b = generateMaterialShipment(
        'b',
        SeededGameRng(seed),
        ketch: false,
      );
      expect(a.seaGlass, inInclusiveRange(2, 4));
      expect(a.depthWroughtIron, inInclusiveRange(1, 2));
      expect(a.seaGlass, b.seaGlass);
      expect(a.depthWroughtIron, b.depthWroughtIron);
      a.remove(TradeMaterial.seaGlass, a.seaGlass);
      expect(b.seaGlass, greaterThan(0));
    }
    final empty = generateMaterialShipment('empty', _HighRoll(), ketch: true);
    expect(empty.seaGlass + empty.depthWroughtIron, 0);
    final s = _shop()
      ..smugglerMaterials = empty
      ..phase = SessionPhase.smuggler;
    final restored = _reload(s);
    expect(restored.smugglerMaterials!.toJson(), empty.toJson());
    restored.dispatch(
      const BuyMerchantMaterial('empty', TradeMaterial.seaGlass),
    );
    expect(restored.smugglerMaterials!.seaGlass, 0);
  });

  test('home has no material shop, Kin gift never grants materials or discounts iron', () {
    final s = _shop();
    s.refreshMerchantStock(1);
    expect(s.merchantMaterials, isNull);
    s.phase = SessionPhase.smuggler;
    s.activeBoon = BloodlineTrait.smugglersKin;
    s.smugglerStock = [
      generateConsumable(ConsumableType.blastPack, RarityLevel.common),
    ];
    s.smugglerMaterials = MaterialShipment(
      id: 'kin',
      seaGlass: 2,
      depthWroughtIron: 1,
    );
    expect(s.materialUnitPrice(TradeMaterial.depthWroughtIron), 50);
    s.dispatch(const ClaimSmugglerGift(0));
    expect(s.profile.metaInventory.isEmpty, isTrue);
    final before = s.ship!.gold;
    s.dispatch(
      const BuyMerchantMaterial('kin', TradeMaterial.depthWroughtIron),
    );
    expect(s.ship!.gold, before - 50);
    expect(s.profile.metaInventory.depthWroughtIron, 1);
  });

  for (final (level, titan, low, high) in [
    (1, false, 40, 50),
    (4, false, 40, 50),
    (5, false, 55, 70),
    (8, false, 55, 70),
    (9, false, 70, 90),
    (12, false, 70, 90),
    (5, true, 80, 100),
    (9, true, 110, 140),
    (13, true, 140, 180),
  ]) {
    test(
      'level $level titan=$titan uses bounded regional income without stacked Apex',
      () {
        for (var seed = 0; seed < 40; seed++) {
          final normal = calculateVoyageVictoryGold(
            level,
            SeededGameRng(seed),
            isTitan: titan,
          );
          final apex = calculateVoyageVictoryGold(
            level,
            SeededGameRng(seed),
            isTitan: titan,
            isApex: true,
          );
          expect(normal, inInclusiveRange(low, high));
          expect(apex, titan ? normal : (normal * 1.5).round());
        }
      },
    );
  }
}

class _HighRoll extends SeededGameRng {
  @override
  int d100() => 100;
}
