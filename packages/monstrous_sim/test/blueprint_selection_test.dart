import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';
import 'package:test/test.dart';

void main() {
  for (final bot in <BotStrategy>[
    const CautiousBot(), const RecklessBot(), const GreedyBot(),
    RandomBot(rng: SeededGameRng(47)),
  ]) {
    test('${bot.name} starts fresh profiles with the Standard flagship', () {
      final session = GameSession(rng: SeededGameRng(12));
      session.dispatch(bot.decideNextAction(session));
      final choice = bot.decideNextAction(session) as ChooseShip;
      expect(choice.shipClass, ShipClass.standard);
      session.dispatch(choice);
      expect(session.ship!.shipClass, ShipClass.standard);
    });
  }
  test('Cautious prefers Ironclad once its blueprint is unlocked', () {
    final session = GameSession(rng: SeededGameRng(3))
      ..dispatch(const NameCaptain('Careful'));
    session.profile.unlockedBlueprints.add(BlueprintId.ironclad.name);
    expect((const CautiousBot().decideNextAction(session) as ChooseShip).shipClass,
        ShipClass.ironclad);
  });
  test('Random bot samples only unlocked canonical ships', () {
    final bot = RandomBot(rng: SeededGameRng(17));
    final session = GameSession(rng: SeededGameRng(31))
      ..dispatch(const NameCaptain('Fortuna'));
    session.profile.unlockedBlueprints.add(BlueprintId.clipper.name);
    final seen = <ShipClass>{};
    for (var i = 0; i < 30; i++) {
      seen.add((bot.decideNextAction(session) as ChooseShip).shipClass);
    }
    expect(seen, {ShipClass.standard, ShipClass.clipper});
  });
}
