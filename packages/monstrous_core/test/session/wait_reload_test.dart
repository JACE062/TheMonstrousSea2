import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _HitRng extends SeededGameRng {
  _HitRng() : super(42);

  @override
  int d100() => 1;
}

GameSession _battle() {
  final session = GameSession(rng: _HitRng())
    ..dispatch(const BeginFirstVoyage('Waiting Test'));
  session.currentMonster =
      createMonster(MonsterSpecies.shark, level: 1, rng: session.rng)
        ..maxHp = 10000
        ..currentHp = 10000;
  session.ship!
    ..maxHp = 10000
    ..currentHp = 5000;
  return session;
}

void main() {
  for (final evasion in [0, 25, 50, 95]) {
    test('repeated waiting preserves $evasion evasion without stacking', () {
      final session = _battle();
      final ship = session.ship!..currentEvasion = evasion;
      final round = session.battleRound;
      for (var i = 0; i < 3; i++) {
        // Deny the response so normal dodge consumption cannot mask a bonus.
        session.currentMonster!.addStatus(StatusEffect.stun);
        final events = session.dispatch(const BraceForImpact());
        expect(ship.currentEvasion, evasion);
        expect(ship.currentHp, 5000);
        expect(session.battleRound, round + i + 1);
        expect(
          events.whereType<CombatEffectsChanged>().where(
            (e) => e.target == CombatSide.ship,
          ),
          everyElement(
            isA<CombatEffectsChanged>().having(
              (e) => e.state.currentEvasion,
              'displayed evasion',
              evasion,
            ),
          ),
        );
        expect(
          events.whereType<NarrationEvent>().map((e) => e.message).join(),
          isNot(contains('+10%')),
        );
      }
    });
  }

  test('waiting advances every cooling fitting and resolves late helm', () {
    final session = _battle()..activeQuirk = BloodlineTrait.skirmisher;
    final ship = session.ship!;
    for (final weapon in ship.equippedWeapons) {
      weapon.chargeCountdown = 2;
    }
    ship.utilityCooldown = 2;
    session.combatRange = CombatRange.medium;
    session.currentMonster!.addStatus(StatusEffect.stun);
    session.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
    expect(session.combatRange, CombatRange.medium);

    final events = session.dispatch(const BraceForImpact());
    expect(session.combatRange, CombatRange.long);
    expect(ship.utilityCooldown, 1);
    expect(ship.equippedWeapons.map((w) => w.chargeCountdown), everyElement(1));
    expect(events.whereType<CombatRangeChanged>(), hasLength(1));
  });

  test('waiting grants no dodge against an incoming hit', () {
    final session = _battle();
    final ship = session.ship!
      ..baseEvasion = 0
      ..currentEvasion = 0;
    final hp = ship.currentHp;
    final events = session.dispatch(const BraceForImpact());
    expect(ship.currentHp, lessThan(hp));
    expect(ship.currentEvasion, 0);
    expect(
      events.whereType<AttackHit>().where((e) => e.targetName == ship.name),
      isNotEmpty,
    );
  });
}
