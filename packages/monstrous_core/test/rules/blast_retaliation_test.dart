import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

import 'combat_test.dart'
    show
        QueueGameRng,
        createTestShip,
        createTestMonster,
        createTestMonsterWeapon;

void main() {
  for (final tier in [1, 2, 3]) {
    for (final flare in [0.0, .25, .30, .35]) {
      for (final shell in [0, 1000]) {
        test(
          'tier $tier shockwave is Blast with Flare $flare / shell $shell',
          () {
            final ship = createTestShip()
              ..basaltBarrierHp = 35
              ..basaltAegisTurns = 2
              ..blessings[HardpointType.utility] = HardpointBlessing(
                power: OceanPower.earthshakerTitan,
                slot: HardpointType.utility,
                tier: tier,
              );
            final monster = createTestMonster(maxHp: 1000)
              ..carapacePlating = shell
              ..spotterFlareTurns = flare > 0 ? 2 : 0
              ..spotterFlareBlastBonus = flare;
            final (_, events) = calculateAttack(
              monster,
              createTestMonsterWeapon(damage: 1),
              ship,
              QueueGameRng(),
              const [],
              0,
              1,
              CombatRange.medium,
              true,
            );
            final damage = ([12, 20, 30][tier - 1] * (1 + flare)).round();
            final hit = events.whereType<AttackHit>().singleWhere(
              (e) => e.source == 'Tidal Shockwave',
            );
            expect(hit.damageType, 'Blast');
            expect(hit.damage, shell == 0 ? damage : 0);
            expect(monster.currentHp, shell == 0 ? 1000 - damage : 1000);
            expect(
              monster.carapacePlating,
              shell == 0 ? 0 : 1000 - (damage * 1.5).round(),
            );
            expect(ship.currentHp, 100);
          },
        );
      }
    }
  }
}
