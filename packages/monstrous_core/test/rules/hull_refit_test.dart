import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  const hpGains = {
    ShipClass.standard: 50,
    ShipClass.freighter: 100,
    ShipClass.ironclad: 75,
    ShipClass.corvette: 40,
    ShipClass.clipper: 40,
    ShipClass.bombardier: 45,
    ShipClass.corsair: 45,
  };
  final captains = [
    (null, null),
    (BloodlineTrait.skilledCarpenter, null),
    (null, BloodlineTrait.exactingShipwright),
    (BloodlineTrait.skilledCarpenter, BloodlineTrait.exactingShipwright),
  ];

  for (final entry in hpGains.entries) {
    for (var captain = 0; captain < captains.length; captain++) {
      for (final missingHp in [0, 30]) {
        test(
          '${entry.key.name} refits preserve $missingHp damage, captain $captain',
          () {
            final session = GameSession(rng: SeededGameRng(42))
              ..captainName = 'Refit regression'
              ..activeBoon = captains[captain].$1
              ..activeQuirk = captains[captain].$2
              ..ship = createShip(entry.key, level: 1, rng: SeededGameRng(19))
              ..phase = SessionPhase.stronghold;
            final ship = session.ship!..gold = 1000;
            ship.currentHp = ship.maxHp - missingHp;
            final oldMax = ship.maxHp;
            final multiplier = ship.captainHealingMultiplier;
            final oldWeapons = ship.equippedWeapons
                .map((w) => w.damage)
                .toList();

            for (var tier = 2; tier <= 4; tier++) {
              final beforeGold = ship.gold;
              final events = session.dispatch(const UpgradeShip());
              expect(events.whereType<ShipUpgraded>(), hasLength(1));
              expect(
                ship.gold,
                beforeGold - calculateShipUpgradeCost(tier - 1),
              );
              expect(ship.level, tier);
              expect(ship.maxHp, oldMax + (tier - 1) * entry.value);
              expect(ship.maxHp - ship.currentHp, missingHp);
              expect(ship.captainHealingMultiplier, multiplier);
            }
            final finalState = ship.toJson();
            session.dispatch(const UpgradeShip());
            expect(
              ship.toJson(),
              finalState,
              reason: 'Maximum tier cannot charge or grow again',
            );
            for (var i = 0; i < oldWeapons.length; i++) {
              var expectedDamage = oldWeapons[i];
              for (var refit = 0; refit < 3; refit++) {
                expectedDamage = (expectedDamage * 1.25).round();
              }
              expect(ship.equippedWeapons[i].damage, expectedDamage);
            }

            final restored = GameSession(rng: SeededGameRng(100));
            VoyageSaveData.fromJson(
              VoyageSaveData.fromSession(session).toJson(),
            ).restoreToSession(restored);
            expect(restored.ship!.maxHp, ship.maxHp);
            expect(restored.ship!.currentHp, ship.currentHp);
            expect(restored.ship!.gold, ship.gold);
            expect(restored.ship!.level, 4);
            expect(restored.ship!.captainHealingMultiplier, multiplier);

            // Actual healing still uses captain traits after fixed growth.
            ship.currentHp = ship.maxHp - 30;
            ship.heal(20);
            expect(ship.maxHp - ship.currentHp, 30 - (20 * multiplier).round());
          },
        );
      }
    }
  }
}
