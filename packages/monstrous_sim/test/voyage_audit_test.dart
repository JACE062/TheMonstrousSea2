import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';
import 'package:test/test.dart';

void main() {
  for (final mode in AuditMode.values) {
    for (final policy in VoyagePolicy.values) {
      test(
        '$mode/$policy uses legal core commands and reconciles voyage gold',
        () {
          final run = const VoyageAuditRunner().run(
            seed: 20261105,
            policy: policy,
            build: AuditBuild.fresh,
            mode: mode,
          );
          final totals = run['totals'] as Map;
          expect(run['error'], isNull);
          expect(run['stepLimited'], isFalse);
          expect(
            (run['final'] as Map)['gold'],
            25 + (totals['goldEarned'] ?? 0) - (totals['goldSpent'] ?? 0),
          );
          expect(run['mode'], mode.name);
          if (mode != AuditMode.live) {
            expect(run['complete'], isTrue);
            expect(totals['scriptedDamage'], greaterThan(0));
            expect(
              (run['milestones'] as List).where(
                (m) => m['kind'] == 'titanArrival',
              ),
              hasLength(3),
            );
            expect(totals['spentUpgrades'], greaterThan(0));
            expect(totals['paidRepairHp'], greaterThan(0));
          } else {
            expect(totals['scriptedDamage'], isNull);
          }
        },
      );
    }
  }
  test('same monster and action RNG preserve complete ordinary rewards before cargo', () {
    for (final condition in WreckCondition.values) {
      final row = auditMatchedEncounter(
        seed: 20261105,
        region: 0,
        capped: true,
        condition: condition,
        combinedHealing: true,
      );
      expect(row['won'], isTrue);
      expect(row['bountyEach'], inInclusiveRange(40, 50));
      expect((row['extraCargo'] as Map)['seaGlass'], greaterThan(0));
      expect((row['organicEach'] as Map)['monsterBone'], greaterThan(0));
    }
  });
}
