import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Rolls extends SeededGameRng {
  _Rolls(this.rolls) : super(42);
  final List<int> rolls;
  @override
  int d100() => rolls.isEmpty ? 100 : rolls.removeAt(0);
}

void main() {
  test('legacy ink deployment is suppressed while illuminated', () {
    final monster = createKraken(rng: SeededGameRng(42))
      ..spotterFlareTurns = 2;
    final ship = createFlagshipFromBlueprint(
      BlueprintId.standard, rng: SeededGameRng(42),
    );
    final events = takeMonsterTurn(monster, ship, _Rolls([100, 100]));
    expect(events.whereType<InkCloudDeployed>(), isEmpty);
    expect(monster.isObscured, isFalse);
    const InkCloudTrait().executeSpecialAction(monster, ship, SeededGameRng(42));
    expect(monster.isObscured, isFalse);
  });
  for (final species in [MonsterSpecies.squid, MonsterSpecies.kraken]) {
    test(
      '${species.name}: obscurity changes accuracy, not dodge, and disperses on a hit',
      () {
        final ship = createFlagshipFromBlueprint(
          BlueprintId.standard,
          rng: SeededGameRng(42),
        );
        final cannon = ship.equippedWeapons.first;
        final monster = createMonster(species, level: 5, rng: SeededGameRng(42))
          ..isObscured = true;
        final penalty = species == MonsterSpecies.squid ? 20 : 25;
        expect(monster.obscurityAccuracyPenalty, penalty);
        expect(monster.effectiveEvasion, 0);
        expect(calculateHitChance(ship, cannon, monster), 85 - penalty);
        expect(
          calculateHitChance(ship, cannon, monster, ignoreObscurity: true),
          85,
        );
        final miss = calculateAttack(ship, cannon, monster, _Rolls([100])).$2;
        expect(miss.whereType<AttackMissed>(), isNotEmpty);
        expect(monster.isObscured, isTrue);
        final hit = calculateAttack(ship, cannon, monster, _Rolls([1, 25])).$2;
        expect(monster.isObscured, isFalse);
        expect(monster.obscurityAccuracyPenalty, 0);
        expect(
          hit.whereType<NarrationEvent>().any(
            (e) => e.message.contains('accuracy penalty is cleared'),
          ),
          isTrue,
        );
        expect(calculateHitChance(ship, cannon, monster), 85);
      },
    );
  }

  test(
    'ink log explains percentage points and clearing without AC language',
    () {
      const event = InkCloudDeployed(
        monsterName: 'Kraken',
        accuracyPenalty: 25,
      );
      final text = const NarrationFormatter().format(event);
      expect(text, contains('25 percentage points'));
      expect(text, contains('25% chance'));
      expect(text, contains('Spotter Flare'));
      expect(text, isNot(contains(' AC')));
      expect(
        event.acBonus,
        25,
      ); // Compatibility reader, not player terminology.
    },
  );

  test(
    'Flare suppresses obscurity and dodge without mutating innate values',
    () {
      final ship = createFlagshipFromBlueprint(
        BlueprintId.standard,
        rng: SeededGameRng(42),
      );
      final monster = createSerpent(level: 1, rng: SeededGameRng(42))
        ..isObscured = true
        ..obscuredAcMod = 20;
      expect(monster.effectiveEvasion, 20);
      expect(calculateHitChance(ship, ship.equippedWeapons.first, monster), 65);
      monster.spotterFlareTurns = 1;
      expect(monster.effectiveEvasion, 0);
      expect(monster.obscurityAccuracyPenalty, 0);
      expect(calculateHitChance(ship, ship.equippedWeapons.first, monster), 95);
      monster.tickSpotterFlare();
      expect(monster.evasion, 20);
      expect(monster.obscuredAcMod, 20);
      expect(monster.obscurityAccuracyPenalty, 20);
    },
  );
}
