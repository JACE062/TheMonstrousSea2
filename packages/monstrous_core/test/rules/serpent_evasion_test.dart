import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Rolls extends SeededGameRng {
  _Rolls(this.hit, this.dodge) : super(42);
  final int hit;
  final int dodge;
  int calls = 0;

  @override
  int d100() => calls++ == 0 ? hit : dodge;
}

MonsterState _serpent(MonsterSpecies species, bool apex) =>
    createMonster(species, level: 1, rng: SeededGameRng(42), isApex: apex);

void main() {
  for (final (species, apex, innate) in [
    (MonsterSpecies.serpent, false, 20),
    (MonsterSpecies.serpent, true, 30),
    (MonsterSpecies.worldSerpent, false, 30),
  ]) {
    final label = '${species.name}, apex=$apex';
    test('$label repeated recoils preserve innate dodge and retreat', () {
      final monster = _serpent(species, apex);
      final ship = createFlagshipFromBlueprint(
        BlueprintId.standard,
        rng: SeededGameRng(42),
      );
      ship.maxHp = ship.currentHp = 100000;
      expect(monster.evasion, innate);
      for (var turn = 0; turn < 12; turn++) {
        monster.currentIntent = MonsterIntent.fromId(
          turn.isEven
              ? MonsterIntentId.serpentVenomSpitRecoil
              : MonsterIntentId.serpentFangedWhipRecoil,
        );
        final (range, events) = executeMonsterIntent(
          monster,
          ship,
          _Rolls(100, 100),
          CombatRange.medium,
        );
        expect(range, CombatRange.long);
        expect(monster.evasion, innate);
        expect(events.whereType<SerpentSlithered>(), isEmpty);
      }
      monster.isPinnedThisTurn = true;
      expect(monster.effectiveEvasion, innate ~/ 2);
      monster.currentIntent = MonsterIntent.fromId(
        MonsterIntentId.serpentVenomSpitRecoil,
      );
      final (range, _) = executeMonsterIntent(
        monster,
        ship,
        _Rolls(100, 100),
        CombatRange.medium,
      );
      expect(range, CombatRange.medium);
      // Pin expires after blocking this monster turn's recoil.
      expect(monster.effectiveEvasion, innate);
      monster.isPinnedThisTurn = true;
      monster.spotterFlareTurns = 1;
      expect(monster.effectiveEvasion, 0);
      monster.tickSpotterFlare();
      expect(monster.effectiveEvasion, innate ~/ 2);
      monster.isPinnedThisTurn = false;
      expect(monster.effectiveEvasion, innate);

      // Old callers cannot rebuild evasion through the former special action.
      const SerpentSlitherTrait().executeSpecialAction(
        monster,
        ship,
        SeededGameRng(42),
      );
      expect(monster.evasion, innate);
    });

    for (final (pinned, flare, expected) in [
      (false, false, innate == 20 ? 6800 : 5950),
      (true, false, innate == 20 ? 7650 : 7225),
      (false, true, 9500),
    ]) {
      test('$label actual connection odds: pin=$pinned flare=$flare', () {
        final ship = createFlagshipFromBlueprint(
          BlueprintId.standard,
          rng: SeededGameRng(42),
        );
        final cannon = ship.equippedWeapons.firstWhere((w) => !w.isSignature);
        final monster = _serpent(species, apex)
          ..isPinnedThisTurn = pinned
          ..spotterFlareTurns = flare ? 2 : 0;
        var connected = 0;
        // Enumerate both independent d100 rolls through real attack resolution.
        for (var hit = 1; hit <= 100; hit++) {
          for (var dodge = 1; dodge <= 100; dodge++) {
            monster.currentHp = monster.maxHp;
            final (result, _) = calculateAttack(
              ship,
              cannon,
              monster,
              _Rolls(hit, dodge),
            );
            if (result.didHit && !result.wasEvaded) connected++;
          }
        }
        expect(connected, expected);
      });
    }
  }
}
