import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Nemesis Record & Beast Mutation Tests', () {
    test('NemesisRecord.createFromDefeat generates valid infamy moniker and scaled bounties', () {
      final rng = SeededGameRng(777);
      final killerShark = createShark(level: 3, rng: rng);

      final record = NemesisRecord.createFromDefeat(
        killer: killerShark,
        captainName: 'Barnaby',
        regionIndex: 1,
        rng: rng,
      );

      expect(record.species, MonsterSpecies.shark);
      expect(record.predecessorCaptain, 'Barnaby');
      expect(record.regionIndex, 1);
      expect(record.level, 3);
      expect(record.moniker.contains('Barnaby'), isTrue);
      expect(record.bonusHp > 0, isTrue);
      expect(record.bonusCarapace > 0, isTrue);
      expect(record.bountyGold, 250); // 100 + (3 * 50)
      expect(record.bountySeaGlass, 11); // 5 + (3 * 2)
      expect(record.bountyMonsterBone, 15); // 6 + (3 * 3)
      expect(record.bountyBarnacles, 5); // 2 + 3
    });

    test('instantiateMonster creates empowered Apex beast matching moniker and boosted stats', () {
      final rng = SeededGameRng(42);
      final killerSerpent = createSerpent(level: 2, rng: rng);

      final record = NemesisRecord.createFromDefeat(
        killer: killerSerpent,
        captainName: 'Morrigan',
        regionIndex: 0,
        rng: rng,
      );

      final monster = record.instantiateMonster(rng);

      expect(monster.species, MonsterSpecies.serpent);
      expect(monster.name, record.moniker);
      expect(monster.isApex, isTrue);
      expect(monster.apexTitle, 'Nemesis of the Bloodline');
      expect(monster.maxHp, greaterThan(killerSerpent.maxHp));
      expect(monster.carapacePlating, greaterThanOrEqualTo(record.bonusCarapace));
    });

    test('NemesisRecord JSON serialization preserves complete record', () {
      const record = NemesisRecord(
        species: MonsterSpecies.crustacean,
        baseName: 'Hulking Razorclaw',
        moniker: 'Hulking Razorclaw — The Crusher of Captain Cordelia\'s Keel',
        predecessorCaptain: 'Cordelia',
        regionIndex: 2,
        level: 4,
        bonusHp: 65,
        bonusCarapace: 45,
        bountyGold: 300,
        bountySeaGlass: 13,
        bountyMonsterBone: 18,
        bountyBarnacles: 6,
      );

      final json = record.toJson();
      final restored = NemesisRecord.fromJson(json);

      expect(restored.species, record.species);
      expect(restored.baseName, record.baseName);
      expect(restored.moniker, record.moniker);
      expect(restored.predecessorCaptain, record.predecessorCaptain);
      expect(restored.regionIndex, record.regionIndex);
      expect(restored.level, record.level);
      expect(restored.bonusHp, record.bonusHp);
      expect(restored.bonusCarapace, record.bonusCarapace);
      expect(restored.bountyGold, record.bountyGold);
      expect(restored.bountySeaGlass, record.bountySeaGlass);
      expect(restored.bountyMonsterBone, record.bountyMonsterBone);
      expect(restored.bountyBarnacles, record.bountyBarnacles);
    });
  });
}
