import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';
import 'package:test/test.dart';

class _ItemRollRng extends SeededGameRng {
  _ItemRollRng() : super(1);
  @override
  int nextInt(int maxExclusive) => maxExclusive == 10 ? 8 : 0;
}

void main() {
  for (final bot in <BotStrategy>[
    const RecklessBot(),
    const GreedyBot(),
    const CautiousBot(),
    RandomBot(rng: _ItemRollRng()),
  ]) {
    test(
      '${bot.name} skips depleted legacy bottles and consumes the next item once',
      () {
        final session = GameSession(rng: SeededGameRng(47))
          ..dispatch(const NameCaptain('Bottle Keeper'))
          ..dispatch(const ChooseShip(ShipClass.standard))
          ..dispatch(const VentureOutToSea());
        session.ship!.currentHp = (session.ship!.maxHp * 0.5).round();
        final empty = generateConsumable(
          ConsumableType.unstableTincture,
          RarityLevel.epic,
        )..usesLeft = 0;
        final item = generateConsumable(
          ConsumableType.hullPatchKit,
          RarityLevel.legendary,
        );
        session.ship!.cargo
          ..clear()
          ..addAll([empty, item]);
        final action = bot.decideNextAction(session);
        expect(action, isA<UseConsumableItem>());
        expect((action as UseConsumableItem).cargoIndex, 1);
        session.dispatch(action);
        expect(session.ship!.cargo, [empty]);
        expect(item.isDepleted, isTrue);
      },
    );
  }
}
