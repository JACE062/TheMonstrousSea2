import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  test('home has no merchant or direct trading backdoor', () {
    final s = GameSession(rng: SeededGameRng(4))
      ..dispatch(const NameCaptain('Home trade'))
      ..dispatch(const ChooseShip(ShipClass.standard));
    s.ship!.gold = 100;
    s.ship!.cargo.add(
      generateConsumable(ConsumableType.blastPack, RarityLevel.common),
    );
    expect(() => s.dispatch(const VisitMerchant()), throwsStateError);
    expect(() => s.dispatch(const BuyMerchantItem(0)), throwsStateError);
    expect(() => s.dispatch(const SellCargoItem(0)), throwsStateError);
    expect(() => s.dispatch(const SellAllTreasure()), throwsStateError);
    expect(s.ship!.gold, 100);
    expect(s.ship!.cargo, hasLength(1));
  });
  test('a pre-existing home-shop checkpoint cannot trade but can leave', () {
    final s = GameSession(rng: SeededGameRng(4))
      ..dispatch(const NameCaptain('Old home shop'))
      ..dispatch(const ChooseShip(ShipClass.standard));
    s.phase = SessionPhase.merchant;
    s.merchantReturnPhase = SessionPhase.port;
    s.merchantMaterials = MaterialShipment(id: 'old-home', seaGlass: 1);
    expect(s.canTradeAtCurrentMerchant, isFalse);
    expect(() => s.dispatch(const BuyMerchantItem(0)), throwsStateError);
    expect(
      () => s.dispatch(
        const BuyMerchantMaterial('old-home', TradeMaterial.seaGlass),
      ),
      throwsStateError,
    );
    s.dispatch(const LeaveMerchant());
    expect(s.phase, SessionPhase.port);
  });
  test(
    'stronghold trading remains available and returns to the same berth',
    () {
      final s = GameSession(rng: SeededGameRng(4))
        ..dispatch(const BeginFirstVoyage('Voyage shop'));
      s.phase = SessionPhase.stronghold;
      s.refreshMerchantStock(1, true);
      s.ship!.gold = 100;
      s.dispatch(const VisitMerchant());
      s.dispatch(const BuyMerchantItem(0));
      expect(s.ship!.cargo, hasLength(1));
      s.dispatch(const LeaveMerchant());
      expect(s.phase, SessionPhase.stronghold);
    },
  );
}
