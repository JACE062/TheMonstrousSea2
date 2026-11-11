import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Rolls extends SeededGameRng {
  _Rolls() : super(42);
  @override
  int d100() => 50;
}

GameSession battle({
  required bool active,
  int region = 0,
  int hp = 100,
  int round = 1,
}) {
  final s = GameSession(rng: _Rolls());
  s.dispatch(const NameCaptain('Pact witness'));
  s.dispatch(const ChooseShip(ShipClass.standard));
  s.profile.hasUnlockedCovenant = true;
  if (active) s.profile.activePacts.addAll(CovenantPactId.values);
  s.phase = SessionPhase.battle;
  final chart = s.seaChart.toJson()..['timesCompleted'] = region;
  s.seaChart.restoreFromJson(chart);
  s.battleRound = round;
  s.ship!
    ..maxHp = 500
    ..currentHp = 500;
  s.currentMonster = createMonster(MonsterSpecies.shark, level: 1, rng: s.rng)
    ..maxHp = 100
    ..currentHp = hp
    ..currentIntent = MonsterIntent.fromId(MonsterIntentId.sharkBreachingLunge);
  return s;
}

void main() {
  test('pact parameters retain existing values', () {
    expect(CovenantPactEffects.monsterHpMultiplier, 1.25);
    expect(CovenantPactEffects.extraCarapace, 10);
    expect(CovenantPactEffects.monsterAttackMultiplier, 1.15);
    expect(CovenantPactEffects.automaticSharkFrenzyThreshold, 0.60);
    expect(CovenantPactEffects.shoreHealingMultiplier, 0.75);
    expect(CovenantPactEffects.shipwrightRepairPriceMultiplier, 1.30);
    expect(CovenantPactEffects.kelpEvasionPenalty(false), 10);
    expect(CovenantPactEffects.kelpEvasionPenalty(true), 20);
    expect(CovenantPactEffects.apexChanceMultiplier(false), 1);
    expect(CovenantPactEffects.apexChanceMultiplier(true), 2);
  });
  for (final active in [false, true]) {
    for (final hp in [60, 61]) {
      test('automatic Shark Frenzy active=$active HP=$hp', () {
        final s = battle(active: active, hp: hp);
        final events = s.dispatch(const ExecuteShipSpecialAction());
        expect(
          events.whereType<SharkFrenzyRoared>().isNotEmpty,
          active && hp == 60,
        );
      });
    }
    for (final round in [2, 3]) {
      test('Boiling Reach scald active=$active round=$round', () {
        final s = battle(active: active, region: 2, round: round);
        final scald = s
            .dispatch(const ExecuteShipSpecialAction())
            .whereType<ThermalScaldOccurred>();
        final expected = active ? round == 2 : round == 3;
        expect(scald.length, expected ? 1 : 0);
        if (expected) expect(scald.single.damage, active ? 15 : 10);
      });
    }
  }
  test('Titan Cinders preserve zero-burden gating and integer plateaus', () {
    for (var burden = 0; burden <= 9; burden++) {
      expect(
        CovenantPactEffects.titanCinders(MonsterSpecies.kraken, burden),
        [0, 1, 2, 2, 3, 3, 4, 4, 5, 5][burden],
      );
      expect(
        CovenantPactEffects.titanCinders(MonsterSpecies.worldSerpent, burden),
        [0, 2, 3, 3, 4, 4, 5, 5, 6, 6][burden],
      );
      expect(
        CovenantPactEffects.titanCinders(
          MonsterSpecies.ancientLeviathan,
          burden,
        ),
        [0, 4, 5, 6, 7, 8, 9, 10, 11, 12][burden],
      );
      expect(CovenantPactEffects.titanCinders(MonsterSpecies.shark, burden), 0);
      expect(CovenantPactEffects.titanCinders(null, burden), 0);
    }
  });
}
