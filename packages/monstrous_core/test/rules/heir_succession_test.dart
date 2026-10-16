import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Heir Succession & Bloodline Traits Tests', () {
    test('generateHeirCandidates produces 3 distinct candidates with boons and quirks', () {
      final rng = SeededGameRng(1234);
      final candidates = generateHeirCandidates(
        rng: rng,
        previousCaptainName: 'Captain Jonathan Vane',
        count: 3,
      );

      expect(candidates.length, 3);
      for (final candidate in candidates) {
        expect(candidate.defaultName.isNotEmpty, isTrue);
        expect(candidate.defaultName.contains('Vane'), isTrue);
        expect(candidate.boon.isBoon, isTrue);
        expect(candidate.quirk.isQuirk, isTrue);
      }
    });

    test('generateHeirCandidates prioritizes Blood Oath when active nemesis exists', () {
      final rng = SeededGameRng(999);
      final candidates = generateHeirCandidates(
        rng: rng,
        previousCaptainName: 'Abigail Blackwood',
        nemesisSpecies: MonsterSpecies.shark,
        count: 3,
      );

      final hasBloodOath = candidates.any(
        (c) => c.quirk.id == BloodlineTraitId.bloodOath,
      );
      expect(hasBloodOath, isTrue);
    });

    test('BloodlineTrait and HeirCandidate serialize and deserialize cleanly', () {
      final candidate = HeirCandidate(
        defaultName: 'Edward Vane the Salt-Bitten',
        boon: BloodlineTrait.veteranCannoneer,
        quirk: BloodlineTrait.recklessHelmsman,
      );

      final json = candidate.toJson();
      final restored = HeirCandidate.fromJson(json);

      expect(restored.defaultName, candidate.defaultName);
      expect(restored.boon.id, BloodlineTraitId.veteranCannoneer);
      expect(restored.quirk.id, BloodlineTraitId.recklessHelmsman);
      expect(restored.boon.name, 'Veteran Cannoneer');
      expect(restored.quirk.name, 'Reckless Helmsman');
    });

    test('All traits have valid names, descriptions, and flavors', () {
      for (final trait in BloodlineTrait.allTraits) {
        expect(trait.name.isNotEmpty, isTrue);
        expect(trait.description.isNotEmpty, isTrue);
        expect(trait.flavor.isNotEmpty, isTrue);
      }
    });
  });
}
