import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';
import 'package:test/test.dart';

void main() {
  for (final bot in <BotStrategy>[const CautiousBot(), const GreedyBot(), const RecklessBot(), RandomBot()]) {
    test('${bot.name} uses legal stronghold actions and continues the same voyage', () {
      final session = GameSession(rng: SeededGameRng(42))
        ..dispatch(const NameCaptain('Reed'))
        ..dispatch(const ChooseShip(ShipClass.standard));
      session.ship!.gold = 1500;
      expect(bot.decideNextAction(session), isNot(isA<UpgradeShip>()));
      session.seaChart.timesCompleted = 1;
      session.phase = SessionPhase.stronghold;
      for (var step = 0; step < 40 && session.phase != SessionPhase.helm; step++) {
        session.dispatch(bot.decideNextAction(session));
      }
      expect(session.phase, SessionPhase.helm);
      expect(session.seaChart.currentRegionIndex, 1);
      expect(session.captainName, 'Reed');
    });
  }
}
