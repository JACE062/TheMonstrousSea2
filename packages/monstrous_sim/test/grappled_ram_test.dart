import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';
import 'package:test/test.dart';

void main() {
  for (final bot in <BotStrategy>[
    const CautiousBot(),
    const RecklessBot(),
    const GreedyBot(),
    RandomBot(rng: SeededGameRng(47)),
  ]) {
    for (final range in [CombatRange.short, CombatRange.medium]) {
      test('${bot.name} respects Grappled Ram reach at $range', () {
        final s = GameSession(rng: SeededGameRng(12));
        s.profile.unlockedBlueprints.add(BlueprintId.ironclad.name);
        s.dispatch(const NameCaptain('Grappled witness'));
        s.dispatch(const ChooseShip(ShipClass.ironclad));
        s.dispatch(const VentureOutToSea());
        s.combatRange = range;
        s.ship!
          ..isGrappled = true
          ..utilityCooldown = 2;
        s.ship!.cargo.clear();
        for (final weapon in s.ship!.equippedWeapons) {
          weapon.chargeCountdown = weapon.weaponType == ShipWeaponType.prowRam
              ? 0
              : 2;
        }
        final action = bot.decideNextAction(s);
        if (range == CombatRange.short) {
          expect(action, isA<FireWeaponVolley>());
          expect(
            (action as FireWeaponVolley).weaponType,
            ShipWeaponType.prowRam,
          );
        } else {
          expect(action, isA<BraceForImpact>());
        }
        expect(() => s.dispatch(action), returnsNormally);
      });
    }
  }
}
