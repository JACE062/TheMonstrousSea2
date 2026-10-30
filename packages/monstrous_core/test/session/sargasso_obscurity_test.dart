import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Rolls extends SeededGameRng {
  _Rolls() : super(42);
  final rolls = <int>[];
  @override
  int d100() => rolls.isEmpty ? 100 : rolls.removeAt(0);
}

GameSession _voyage(_Rolls rng, {BlueprintId hull = BlueprintId.standard}) {
  final session = GameSession(rng: rng)
    ..dispatch(const BeginFirstVoyage('Haze Tester'));
  session.ship = createFlagshipFromBlueprint(hull, rng: rng);
  return session;
}

// Install a public serialized offer, then use normal navigation/startup. The
// chosen course writes its species and Apex identity into the destination cell.
List<GameEvent> _enter(
  GameSession session,
  MonsterSpecies species, {
  bool apex = false,
  int region = 1,
}) {
  final chart = session.seaChart.toJson()
    ..['currentRow'] = 0
    ..['currentCol'] = 0
    ..['currentLeg'] = 0
    ..['timesCompleted'] = region
    ..['courseOptions'] = [
      {
        'bearing': NavigationalBearing.deadAhead.name,
        'nodeType': EncounterNodeType.beastCombat.name,
        'difficultyLevel': 1 + 4 * region,
        'lookoutCall': 'A beast ahead.',
        'monsterSpecies': species.name,
        'isIdentified': true,
        'isApex': apex,
        'isNemesis': false,
      },
    ];
  session.seaChart.restoreFromJson(chart);
  session.phase = SessionPhase.helm;
  return session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
}

void main() {
  for (final species in [
    MonsterSpecies.shark,
    MonsterSpecies.serpent,
    MonsterSpecies.jellyfish,
    MonsterSpecies.squid,
    MonsterSpecies.crustacean,
  ]) {
    for (final apex in [false, true]) {
      test(
        '${species.name} Apex=$apex gets haze without stacking ink or dodge',
        () {
          final rng = _Rolls();
          final session = _voyage(rng);
          final events = _enter(session, species, apex: apex);
          final monster = session.currentMonster!;
          final intrinsic = createMonster(
            species,
            level: monster.level,
            rng: SeededGameRng(42),
            isApex: apex,
          );
          final penalty = species == MonsterSpecies.squid
              ? (apex ? 25 : 20)
              : 10;
          expect(session.phase, SessionPhase.battle);
          expect(monster.species, species);
          expect(monster.isApex, apex);
          expect(monster.isObscured, isTrue);
          expect(monster.obscurityAccuracyPenalty, penalty);
          expect(monster.evasion, intrinsic.evasion);
          expect(monster.effectiveEvasion, intrinsic.effectiveEvasion);
          expect(session.ship!.currentEvasion, 0);
          expect(
            events.whereType<NarrationEvent>().any(
              (event) =>
                  event.message.contains('-10% ship evasion') &&
                  event.message.contains('-$penalty% shot accuracy'),
            ),
            isTrue,
          );
          final snapshot = CombatantPresentation.capture(monster);
          expect(snapshot.isObscured, isTrue);
          expect(snapshot.obscuredAcMod, penalty);
        },
      );
    }
  }

  test('Sargasso Titan starts with haze and retains World Serpent dodge', () {
    final session = _voyage(_Rolls());
    session.phase = SessionPhase.restArea;
    session.seaChart
      ..timesCompleted = 1
      ..currentLeg = 11
      ..clearPendingCourses();
    session.dispatch(const TakeHelm());
    session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
    expect(session.currentMonster!.species, MonsterSpecies.worldSerpent);
    expect(session.currentMonster!.obscurityAccuracyPenalty, 10);
    expect(session.currentMonster!.effectiveEvasion, 30);
  });

  for (final species in [MonsterSpecies.shark, MonsterSpecies.squid]) {
    test('${species.name} Nemesis receives haze through normal startup', () {
      final rng = _Rolls();
      final session = _voyage(rng);
      session.profile.activeNemesis = NemesisRecord.createFromDefeat(
        killer: createMonster(species, level: 5, rng: rng),
        captainName: 'Ancestor',
        regionIndex: 1,
        rng: rng,
      );
      session.seaChart
        ..timesCompleted = 1
        ..currentLeg = 6
        ..clearPendingCourses();
      session.phase = SessionPhase.restArea;
      session.dispatch(const TakeHelm());
      final course = session.seaChart.currentCourseOptions.singleWhere(
        (c) => c.isNemesis,
      );
      session.dispatch(SteerCourse(course.bearing));
      expect(session.isNemesisBattle, isTrue);
      expect(session.currentMonster!.species, species);
      expect(session.currentMonster!.isApex, isTrue);
      expect(
        session.currentMonster!.obscurityAccuracyPenalty,
        species == MonsterSpecies.squid ? 25 : 10,
      );
    });
  }

  for (final region in [0, 2]) {
    test('region ${region + 1} does not gain Sargasso haze', () {
      final session = _voyage(_Rolls());
      _enter(session, MonsterSpecies.shark, region: region);
      expect(session.currentMonster!.isObscured, isFalse);
      expect(session.currentMonster!.obscuredAcMod, 0);
      expect(session.ship!.currentEvasion, session.ship!.baseEvasion);
    });
  }

  test(
    'Volatile Environs strengthens only kelp; repeated haze does not stack',
    () {
      final session = _voyage(_Rolls(), hull: BlueprintId.clipper);
      session.profile.activePacts.add(CovenantPactId.volatileEnvirons);
      for (var encounter = 0; encounter < 2; encounter++) {
        final events = _enter(session, MonsterSpecies.shark);
        expect(session.currentMonster!.obscurityAccuracyPenalty, 10);
        expect(session.ship!.currentEvasion, session.ship!.baseEvasion - 20);
        expect(
          events.whereType<NarrationEvent>().any(
            (event) =>
                event.message.contains('-20% ship evasion') &&
                event.message.contains('-10% shot accuracy'),
          ),
          isTrue,
        );
      }
    },
  );

  test(
    'haze uses actual 75/76 hit boundary, Long 60 and normal accuracy caps',
    () {
      final rng = _Rolls();
      final session = _voyage(rng);
      _enter(session, MonsterSpecies.shark);
      final ship = session.ship!;
      final cannon = ship.equippedWeapons.first;
      final monster = session.currentMonster!;
      expect(calculateHitChance(ship, cannon, monster), 75);
      expect(
        calculateHitChance(ship, cannon, monster, range: CombatRange.long),
        60,
      );
      expect(
        calculateHitChance(ship, cannon, monster, accuracyBonus: -100),
        25,
      );
      expect(calculateHitChance(ship, cannon, monster, accuracyBonus: 100), 95);
      rng.rolls.addAll([75, 26]);
      expect(
        calculateAttack(ship, cannon, monster, rng).$2.whereType<AttackHit>(),
        isNotEmpty,
      );
      expect(monster.isObscured, isTrue);
      rng.rolls.add(76);
      expect(
        calculateAttack(
          ship,
          cannon,
          monster,
          rng,
        ).$2.whereType<AttackMissed>(),
        isNotEmpty,
      );
      expect(monster.isObscured, isTrue);
    },
  );

  for (final dispersion in [25, 26]) {
    test('successful haze hit disperses at 25, retains at 26: $dispersion', () {
      final rng = _Rolls();
      final session = _voyage(rng);
      _enter(session, MonsterSpecies.shark);
      rng.rolls.addAll([1, dispersion]);
      final monster = session.currentMonster!;
      final events = calculateAttack(
        session.ship!,
        session.ship!.equippedWeapons.first,
        monster,
        rng,
      ).$2;
      expect(monster.isObscured, dispersion == 26);
      expect(monster.obscuredAcMod, 10);
      expect(
        calculateHitChance(
          session.ship!,
          session.ship!.equippedWeapons.first,
          monster,
        ),
        dispersion == 25 ? 85 : 75,
      );
      expect(
        events.whereType<CombatEffectsChanged>().any(
          (event) =>
              event.target == CombatSide.monster && !event.state.isObscured,
        ),
        dispersion == 25,
      );
    });
  }

  test('a dodged accuracy success cannot disperse haze', () {
    final rng = _Rolls();
    final session = _voyage(rng);
    _enter(session, MonsterSpecies.serpent);
    rng.rolls.addAll([1, 20, 1]);
    final events = calculateAttack(
      session.ship!,
      session.ship!.equippedWeapons.first,
      session.currentMonster!,
      rng,
    ).$2;
    expect(events.whereType<AttackEvaded>(), isNotEmpty);
    expect(session.currentMonster!.isObscured, isTrue);
    expect(rng.rolls, [
      1,
    ], reason: 'Dodging must not consume a dispersion roll.');
  });

  test('actual Flare clears haze and expiry does not restore it', () {
    final session = _voyage(_Rolls(), hull: BlueprintId.bombardier);
    _enter(session, MonsterSpecies.shark);
    final monster = session.currentMonster!;
    monster.addStatus(StatusEffect.stun);
    final events = session.dispatch(const ExecuteShipSpecialAction());
    expect(monster.isObscured, isFalse);
    expect(monster.spotterFlareTurns, 1);
    expect(monster.obscuredAcMod, 10);
    expect(
      events.whereType<CombatEffectsChanged>().any(
        (event) =>
            event.target == CombatSide.monster && !event.state.isObscured,
      ),
      isTrue,
    );
    monster.addStatus(StatusEffect.stun);
    session.dispatch(const BraceForImpact());
    expect(monster.spotterFlareTurns, 0);
    expect(monster.obscurityAccuracyPenalty, 0);
    expect(monster.isObscured, isFalse);
  });

  test(
    'actual Ghostwake bypasses haze while retaining its displayed state',
    () {
      final rng = _Rolls();
      final session = _voyage(rng, hull: BlueprintId.clipper);
      _enter(session, MonsterSpecies.shark);
      final monster = session.currentMonster!;
      monster.maxHp = monster.currentHp = 10000;
      monster.addStatus(StatusEffect.stun);
      session.profile.activeEldritchRelics.add(
        EldritchRelicId.ghostwakeCulverin.name,
      );
      rng.rolls.add(90); // Fails the hazy 85%; succeeds with Ghostwake's 95%.
      final events = session.dispatch(
        const FireWeaponVolley(ShipWeaponType.precisionCulverin),
      );
      expect(events.whereType<AttackAttempted>().first.targetAc, 95);
      expect(events.whereType<AttackHit>(), isNotEmpty);
      expect(monster.isObscured, isTrue);
      expect(monster.obscurityAccuracyPenalty, 10);
      expect(
        events
            .whereType<CombatEffectsChanged>()
            .where((event) => event.target == CombatSide.monster)
            .every(
              (event) =>
                  event.state.isObscured && event.state.obscuredAcMod == 10,
            ),
        isTrue,
      );
    },
  );
}
