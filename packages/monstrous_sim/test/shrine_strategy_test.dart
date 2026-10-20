import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';
import 'package:test/test.dart';

void main() {
  for (final bot in <BotStrategy>[
    const CautiousBot(),
    const RecklessBot(),
    const GreedyBot(),
    RandomBot(rng: SeededGameRng(22)),
  ]) {
    group('${bot.name} shrine choices', () {
      late GameSession session;
      setUp(() {
        session = GameSession(rng: SeededGameRng(13))
          ..dispatch(const NameCaptain('Shrine Scout'))
          ..dispatch(const ChooseShip(ShipClass.standard))
          ..phase = SessionPhase.shrine
          ..shrineManifestedPowers = [
            OceanPower.magmaVentLord,
            OceanPower.brinemother,
          ];
      });

      test('Blesses open slots and departs after one commitment', () {
        final command = bot.decideNextAction(session);
        expect(command, isA<AcceptShrineBlessing>());
        session.dispatch(command);
        expect(session.ship!.blessings.length, 1);
        expect(bot.decideNextAction(session), isA<DepartShrine>());
      });

      test('Prioritizes an existing dedication upgrade over an open slot', () {
        session.ship!.blessings[HardpointType.utility] =
            const HardpointBlessing(
              power: OceanPower.brinemother,
              slot: HardpointType.utility,
              tier: 2,
            );
        final command = bot.decideNextAction(session) as AcceptShrineBlessing;
        expect(command.power, OceanPower.brinemother);
        expect(command.slot, HardpointType.utility);
        session.dispatch(command);
        expect(session.ship!.blessings[HardpointType.utility]!.tier, 3);
      });

      test('Falls back to runes with no available blessing', () {
        for (final slot in blessingHardpoints) {
          session.ship!.blessings[slot] = HardpointBlessing(
            power: OceanPower.brinemother,
            slot: slot,
            tier: 3,
          );
        }
        session.shrineManifestedPowers = [];
        final command = bot.decideNextAction(session) as CommuneWithShrine;
        expect(command.choice, ShrineChoice.ancientRunes);
        session.dispatch(command);
        expect(session.runicGuidanceBoon, 10);
      });
    });
  }
}
