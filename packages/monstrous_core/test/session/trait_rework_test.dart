import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

// Keep navigation sampling deterministic without depending on Random's sequence.
class _ControlledRng extends SeededGameRng {
  _ControlledRng() : super(91);
  int navigationRoll = 30;
  int percentile = 1;
  @override
  int nextInt(int maxExclusive) => navigationRoll % maxExclusive;
  @override
  int d100() => percentile;
  @override
  double nextDouble() => 0.5;
}

GameSession _voyage({_ControlledRng? rng, ProfileData? profile}) =>
    GameSession(rng: rng ?? _ControlledRng(), profile: profile)
      ..dispatch(const BeginFirstVoyage('Founder Vane'));

void _helm(GameSession session, {int? leg}) {
  session.phase = SessionPhase.restArea;
  if (leg != null) session.seaChart.currentLeg = leg;
  session.dispatch(const TakeHelm());
}

GameSession _storm({_ControlledRng? rng, ProfileData? profile, int? leg}) {
  final session = _voyage(rng: rng, profile: profile);
  session.activeBoon = BloodlineTrait.stormSeer;
  _helm(session, leg: leg);
  return session;
}

Object? _offers(GameSession session) =>
    session.seaChart.toJson()['courseOptions'];

GameSession _restore(GameSession session, {Map<String, dynamic>? json}) {
  final restored = GameSession(
    rng: _ControlledRng(),
    profile: ProfileData.fromJson(session.profile.toJson()),
  );
  VoyageSaveData.fromJson(json ?? VoyageSaveData.fromSession(session).toJson())
      .restoreToSession(restored);
  return restored;
}

NemesisRecord _nemesis() => const NemesisRecord(
  species: MonsterSpecies.shark,
  baseName: 'Shark',
  moniker: 'The Old Grudge',
  predecessorCaptain: 'Ancestor',
  regionIndex: 0,
  level: 2,
  bonusHp: 100,
  bonusCarapace: 35,
  bountyGold: 200,
  bountySeaGlass: 9,
  bountyMonsterBone: 12,
  bountyBarnacles: 4,
);

GameSession _gunner({bool overzealous = true, _ControlledRng? rng}) {
  final session = _voyage(rng: rng);
  if (overzealous) session.activeQuirk = BloodlineTrait.overzealousGunner;
  final monster = createMonster(
    MonsterSpecies.shark,
    level: 1,
    rng: session.rng,
  );
  monster.maxHp = 10000;
  monster.currentHp = 10000;
  monster.evasion = 0;
  monster.carapacePlating = 0;
  monster.isPinnedThisTurn = true;
  session.currentMonster = monster;
  for (final weapon in session.ship!.equippedWeapons) {
    weapon.damage = 100;
    weapon.damageType = DamageType.piercing;
    weapon.statusEffect = null;
    weapon.hitModifier = 85;
  }
  return session;
}

List<AttackAttempted> _shots(GameSession session, ShipWeaponType type) =>
    session
        .dispatch(FireWeaponVolley(type))
        .whereType<AttackAttempted>()
        .where((event) => event.attackerName == session.ship!.name)
        .toList();

void main() {
  group('Storm-Seer redraw', () {
    test(
      'redraw replaces ordinary offers without advancing or awarding anything',
      () {
        final rng = _ControlledRng();
        final session = _storm(rng: rng);
        final shipBefore = session.ship!.toJson();
        final profileBefore = session.profile.toJson();
        final saveBefore = VoyageSaveData.fromSession(session).toJson()
          ..remove('seaChartState')
          ..remove('stormSeerRedrawRegion');
        final chartBefore = session.seaChart.toJson()..remove('courseOptions');
        final oldOffers = _offers(session);
        rng.navigationRoll = 95; // Ordinary beast headings become shrines.
        expect(session.canRedrawStormSeerCourses, isTrue);
        expect(session.stormSeerRedrawRestriction, isNull);
        session.dispatch(const RedrawStormSeerCourses());
        expect(_offers(session), isNot(oldOffers));
        expect(session.seaChart.currentCourseOptions, hasLength(3));
        expect(session.seaChart.toJson()..remove('courseOptions'), chartBefore);
        expect(session.ship!.toJson(), shipBefore);
        expect(session.profile.toJson(), profileBefore);
        expect(
          VoyageSaveData.fromSession(session).toJson()
            ..remove('seaChartState')
            ..remove('stormSeerRedrawRegion'),
          saveBefore,
        );
        expect(session.stormSeerRedrawRegion, session.seaChart.timesCompleted);
        final spentOffers = _offers(session);
        expect(session.canRedrawStormSeerCourses, isFalse);
        expect(session.stormSeerRedrawRestriction, isNotNull);
        expect(
          () => session.dispatch(const RedrawStormSeerCourses()),
          throwsStateError,
        );
        expect(_offers(session), spentOffers);
      },
    );

    test('an identical random outcome still consumes the regional redraw', () {
      final session = _storm();
      final original = _offers(session);
      session.dispatch(const RedrawStormSeerCourses());
      expect(_offers(session), original);
      expect(session.canRedrawStormSeerCourses, isFalse);
    });

    test('wrong phase or boon rejects without spending or changing offers', () {
      final session = _storm();
      final original = _offers(session);
      session.phase = SessionPhase.merchant;
      expect(session.canRedrawStormSeerCourses, isFalse);
      expect(
        () => session.dispatch(const RedrawStormSeerCourses()),
        throwsStateError,
      );
      expect(session.stormSeerRedrawRegion, isNull);
      session.phase = SessionPhase.helm;
      session.activeBoon = BloodlineTrait.drillmaster;
      expect(session.canRedrawStormSeerCourses, isFalse);
      expect(
        () => session.dispatch(const RedrawStormSeerCourses()),
        throwsStateError,
      );
      expect(session.stormSeerRedrawRegion, isNull);
      expect(_offers(session), original);
      session.activeBoon = BloodlineTrait.stormSeer;
      expect(session.canRedrawStormSeerCourses, isTrue);
    });

    for (final convergence in ['Haven', 'Titan']) {
      test('$convergence convergence cannot be redrawn or consume the use', () {
        final session = _voyage()..activeBoon = BloodlineTrait.stormSeer;
        _helm(
          session,
          leg: convergence == 'Haven'
              ? session.seaChart.midpointHavenLeg - 1
              : session.seaChart.totalLegs - 1,
        );
        final original = _offers(session);
        expect(session.seaChart.currentCourseOptions, hasLength(1));
        expect(session.canRedrawStormSeerCourses, isFalse);
        expect(
          () => session.dispatch(const RedrawStormSeerCourses()),
          throwsStateError,
        );
        expect(session.stormSeerRedrawRegion, isNull);
        expect(_offers(session), original);
      });
    }

    test('preserves the exact Nemesis heading and its position', () {
      final rng = _ControlledRng();
      final session = _storm(
        rng: rng,
        profile: ProfileData(activeNemesis: _nemesis()),
        leg: 5,
      );
      final before = session.seaChart.currentCourseOptions;
      final index = before.indexWhere((option) => option.isNemesis);
      expect(index, isNonNegative);
      final nemesis = before[index];
      rng.navigationRoll = 95;
      session.dispatch(const RedrawStormSeerCourses());
      final after = session.seaChart.currentCourseOptions;
      expect(after[index], same(nemesis));
      expect(after.where((option) => option.isNemesis), hasLength(1));
      expect(session.seaChart.hasEncounteredNemesisThisVoyage, isFalse);
    });

    test('Vendetta compulsion rejects redraw without spending', () {
      final session = _storm(
        profile: ProfileData(activeNemesis: _nemesis()),
        leg: 5,
      )..activeQuirk = BloodlineTrait.bloodOath;
      final original = _offers(session);
      expect(session.canRedrawStormSeerCourses, isFalse);
      expect(
        () => session.dispatch(const RedrawStormSeerCourses()),
        throwsStateError,
      );
      expect(session.stormSeerRedrawRegion, isNull);
      expect(_offers(session), original);
      session.activeQuirk = null;
      expect(session.canRedrawStormSeerCourses, isTrue);
    });

    for (final revealed in [false, true]) {
      test(
        'redraw honors fog, Apex pact and revealed information: revealed=$revealed',
        () {
          final session = _storm(
            profile: ProfileData()
              ..activePacts.addAll([
                CovenantPactId.chokingFog,
                CovenantPactId.apexEmergence,
              ]),
          );
          if (revealed) {
            session.seaChart.revealRow(session.seaChart.currentLeg + 1);
          }
          session.dispatch(const RedrawStormSeerCourses());
          final offers = session.seaChart.currentCourseOptions;
          // Controlled apex roll 30 is above R1's ordinary 20, below doubled 40.
          expect(offers.every((option) => option.isApex), isTrue);
          expect(
            offers.every((option) => option.isIdentified == revealed),
            isTrue,
          );
          expect(
            offers.every(
              (option) => option.lookoutCall.contains('completely obscured'),
            ),
            !revealed,
          );
        },
      );
    }

    test('reload and same-region helm/merchant visits retain spent use; next region refreshes', () {
      final session = _storm()..dispatch(const RedrawStormSeerCourses());
      final restored = _restore(session);
      expect(_offers(restored), _offers(session));
      expect(restored.stormSeerRedrawRegion, 0);
      expect(restored.canRedrawStormSeerCourses, isFalse);
      restored.phase = SessionPhase.stronghold;
      restored.dispatch(const VisitMerchant());
      restored.dispatch(const LeaveMerchant());
      restored.dispatch(const TakeHelm());
      expect(restored.canRedrawStormSeerCourses, isFalse);
      _helm(restored);
      expect(restored.canRedrawStormSeerCourses, isFalse);
      restored.seaChart.advanceRegion(restored.rng);
      restored.phase = SessionPhase.stronghold;
      restored.dispatch(const TakeHelm());
      expect(restored.canRedrawStormSeerCourses, isTrue);
      restored.dispatch(const RedrawStormSeerCourses());
      expect(restored.stormSeerRedrawRegion, 1);
    });

    test('a missing saved marker defaults to an available regional redraw', () {
      final session = _storm();
      final json = VoyageSaveData.fromSession(session).toJson()
        ..remove('stormSeerRedrawRegion');
      final restored = _restore(session, json: json);
      expect(restored.stormSeerRedrawRegion, isNull);
      expect(restored.canRedrawStormSeerCourses, isTrue);
      expect(_offers(restored), _offers(session));
    });

    test('fresh home departure and succession reset the regional marker', () {
      final session = _storm()..dispatch(const RedrawStormSeerCourses());
      session.phase = SessionPhase.port;
      session.dispatch(const VentureOutToSea());
      expect(session.stormSeerRedrawRegion, isNull);
      _helm(session);
      session.dispatch(const RedrawStormSeerCourses());
      session.phase = SessionPhase.death;
      session.dispatch(
        ContinueLineage(
          'Heir Vane',
          ShipClass.standard,
          boon: BloodlineTrait.stormSeer,
          quirk: BloodlineTrait.overzealousGunner,
        ),
      );
      expect(session.stormSeerRedrawRegion, isNull);
      session.dispatch(const VentureOutToSea());
      _helm(session);
      expect(session.canRedrawStormSeerCourses, isTrue);
    });
  });

  group('Overzealous Gunner', () {
    for (final type in [ShipWeaponType.cannon, ShipWeaponType.twinChasers]) {
      test(
        '${type.name} dispatch gets exactly +20% damage and flat -10 accuracy',
        () {
          final normal = _gunner(overzealous: false);
          final reckless = _gunner();
          expect(normal.captainWeaponAccuracyModifier, 0);
          expect(reckless.captainWeaponAccuracyModifier, -10);
          final ordinaryEvents = normal.dispatch(FireWeaponVolley(type));
          final recklessEvents = reckless.dispatch(FireWeaponVolley(type));
          int damage(GameSession session, List<GameEvent> events) => events
              .whereType<AttackHit>()
              .where(
                (event) =>
                    event.targetName == session.currentMonster!.name &&
                    !event.isBlessingDamage,
              )
              .fold(0, (sum, event) => sum + event.damage);
          expect(damage(normal, ordinaryEvents), greaterThan(0));
          expect(
            damage(reckless, recklessEvents),
            (damage(normal, ordinaryEvents) * 1.20).round(),
          );
          expect(
            ordinaryEvents.whereType<AttackAttempted>().first.targetAc,
            85,
          );
          expect(
            recklessEvents.whereType<AttackAttempted>().first.targetAc,
            75,
          );
        },
      );
    }

    test('accuracy combines gunnery, ink and range before normal bounds', () {
      final session = _gunner();
      session.combatRange = CombatRange.long;
      session.gunneryAccuracyBoon = 15;
      session.currentMonster!.isObscured = true;
      session.currentMonster!.obscuredAcMod = 20;
      expect(_shots(session, ShipWeaponType.cannon).single.targetAc, 55);
      final low = _gunner();
      low.ship!.equippedWeapons
              .where((weapon) => weapon.weaponType == ShipWeaponType.cannon)
              .first
              .hitModifier =
          30;
      low.combatRange = CombatRange.long;
      low.currentMonster!.isObscured = true;
      expect(_shots(low, ShipWeaponType.cannon).single.targetAc, 25);
      final high = _gunner()..gunneryAccuracyBoon = 100;
      expect(_shots(high, ShipWeaponType.cannon).single.targetAc, 95);
    });

    test(
      'utility and belt effects keep their ordinary potency and hit gate',
      () {
        final normal = _gunner(overzealous: false);
        final reckless = _gunner();
        for (final session in [normal, reckless]) {
          session.dispatch(const ExecuteShipSpecialAction());
          expect(session.ship!.gunneryDrillBuffActive, isTrue);
          session.ship!.cargo.add(
            generateConsumable(
              ConsumableType.blastPack,
              RarityLevel.common,
              id: 'belt',
            ),
          );
          final events = session.dispatch(
            UseConsumableItem(session.ship!.cargo.length - 1),
          );
          expect(events.whereType<AttackHit>().single.damage, 5);
          final volley = session.dispatch(
            const FireWeaponVolley(ShipWeaponType.cannon),
          );
          final playerShot = volley.whereType<AttackAttempted>().first;
          final playerHit = volley.whereType<AttackHit>().firstWhere(
            (event) => event.targetName == session.currentMonster!.name,
          );
          expect(playerShot.targetAc, identical(session, normal) ? 95 : 90);
          expect(playerHit.damage, identical(session, normal) ? 120 : 144);
        }
        for (final overzealous in [false, true]) {
          final rng = _ControlledRng()..percentile = 75;
          final session = _gunner(overzealous: overzealous, rng: rng);
          session.ship!.cargo.add(
            generateConsumable(
              ConsumableType.blastPack,
              RarityLevel.common,
              id: 'gate',
            ),
          );
          expect(
            session
                .dispatch(UseConsumableItem(session.ship!.cargo.length - 1))
                .whereType<AttackHit>(),
            hasLength(1),
          );
        }
      },
    );

    test('active and pending saved traits use current catalog descriptions and stable IDs', () {
      final session = _storm()..activeQuirk = BloodlineTrait.overzealousGunner;
      session.pendingHeirCandidates = [
        HeirCandidate(
          defaultName: 'Heir Vane',
          boon: BloodlineTrait.stormSeer,
          quirk: BloodlineTrait.overzealousGunner,
        ),
      ];
      final restored = _restore(session);
      expect(restored.activeBoon!.id.name, 'stormSeer');
      expect(restored.activeQuirk!.id.name, 'overzealousGunner');
      final heir = restored.pendingHeirCandidates.single;
      expect(heir.boon.description, restored.activeBoon!.description);
      expect(heir.quirk.description, restored.activeQuirk!.description);
      expect(heir.boon.description.toLowerCase(), contains('redraw'));
      expect(heir.boon.description.toLowerCase(), isNot(contains('gale')));
      expect(heir.quirk.description, contains('20%'));
      expect(heir.quirk.description, contains('10%'));
      expect(heir.quirk.description.toLowerCase(), isNot(contains('single')));
      expect(restored.captainWeaponAccuracyModifier, -10);
    });
  });
}
