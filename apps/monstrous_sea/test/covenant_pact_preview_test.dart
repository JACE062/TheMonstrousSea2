import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/widgets/covenant_pact_preview.dart';

void main() {
  for (final pact in CovenantPactId.values) {
    test('$pact preview matches toggles across all 128 pact combinations', () {
      for (var mask = 0; mask < 128; mask++) {
        final s = GameSession(rng: SeededGameRng(42));
        s.phase = SessionPhase.port;
        s.profile.hasUnlockedCovenant = true;
        s.profile.activePacts.addAll([
          for (final (i, id) in CovenantPactId.values.indexed)
            if ((mask & (1 << i)) != 0) id,
        ]);
        s.profile.metaInventory.add(seaGlass: 15, primordialCinders: 10);
        final before = jsonEncode({
          'profile': s.profile.toJson(),
          'chart': s.seaChart.toJson(),
        });
        final preview = CovenantPactPreview(s.profile, pact);
        expect(preview.isActive, s.profile.isPactActive(pact));
        expect(preview.currentBurden, s.profile.totalPactBurden);
        expect(preview.canToggle, isTrue);
        expect(
          jsonEncode({
            'profile': s.profile.toJson(),
            'chart': s.seaChart.toJson(),
          }),
          before,
        );
        final resources = s.profile.metaInventory.toJson();
        final events = s.dispatch(ToggleCovenantPact(pact));
        expect(
          events.whereType<CovenantPactToggled>().single.totalPactBurden,
          preview.nextBurden,
        );
        expect(s.profile.totalPactBurden, preview.nextBurden);
        expect(s.profile.isPactActive(pact), !preview.isActive);
        expect(s.profile.metaInventory.toJson(), resources);
        final reversed = CovenantPactPreview(s.profile, pact);
        expect(
          reversed.stats.map((stat) => stat.id),
          preview.stats.map((stat) => stat.id),
        );
        for (final (i, stat) in preview.stats.indexed) {
          expect(reversed.stats[i].current, stat.next);
          expect(reversed.stats[i].next, stat.current);
        }
      }
    });
  }
  test(
    'baseline comparisons show exact modifiers and only changing rewards',
    () {
      final p = ProfileData(hasUnlockedCovenant: true);
      final expected = {
        CovenantPactId.abyssalVigor: ['+0%', '+25%'],
        CovenantPactId.calcifiedCarapace: ['0', '10'],
        CovenantPactId.feedingFrenzy: ['+0%', '+15%'],
        CovenantPactId.chokingFog: ['Clear', 'Obscured'],
        CovenantPactId.brittleOak: ['100%', '75%'],
        CovenantPactId.volatileEnvirons: ['-10%', '-20%'],
        CovenantPactId.apexEmergence: ['1.00x', '2.00x'],
      };
      for (final id in CovenantPactId.values) {
        final preview = CovenantPactPreview(p, id);
        expect([
          preview.stats.first.current,
          preview.stats.first.next,
        ], expected[id]);
      }
      final feeding = CovenantPactPreview(p, CovenantPactId.feedingFrenzy);
      expect(feeding.stats[1].current, 'Off');
    expect(feeding.stats[1].next, '60% HP or less');
      p.activePacts.addAll([
        CovenantPactId.abyssalVigor,
        CovenantPactId.calcifiedCarapace,
      ]);
      final plateau = CovenantPactPreview(p, CovenantPactId.feedingFrenzy);
      expect(
        plateau.stats
            .where((stat) => stat.id.startsWith('cinders-'))
            .map((stat) => stat.id),
        ['cinders-ancientLeviathan'],
      );
    },
  );
  test(
    'preview follows the real legacy-burden reset without changing the source',
    () {
      final p = ProfileData(hasUnlockedCovenant: true, covenantHeat: 6);
      final before = jsonEncode(p.toJson());
      final preview = CovenantPactPreview(p, CovenantPactId.abyssalVigor);
      expect(preview.currentBurden, 6);
      expect(preview.nextBurden, 1);
      expect(jsonEncode(p.toJson()), before);
      p.togglePact(CovenantPactId.abyssalVigor);
      expect(p.totalPactBurden, preview.nextBurden);
    },
  );
  test('locked profile can read a preview but cannot activate a pact', () {
    final s = GameSession();
    s.phase = SessionPhase.port;
    final before = jsonEncode(s.profile.toJson());
    expect(
      CovenantPactPreview(s.profile, CovenantPactId.brittleOak).canToggle,
      isFalse,
    );
    expect(
      () => s.dispatch(const ToggleCovenantPact(CovenantPactId.brittleOak)),
      throwsStateError,
    );
    expect(jsonEncode(s.profile.toJson()), before);
  });
}
