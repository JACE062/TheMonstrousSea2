import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

const _titans = [
  MonsterSpecies.kraken,
  MonsterSpecies.worldSerpent,
  MonsterSpecies.ancientLeviathan,
];
const _beasts = [
  MonsterSpecies.shark,
  MonsterSpecies.serpent,
  MonsterSpecies.jellyfish,
  MonsterSpecies.squid,
  MonsterSpecies.crustacean,
];

// Raw records remain readable so old saves can be migrated at the profile edge.
NemesisRecord _legacyRecord(MonsterSpecies species) => NemesisRecord(
  species: species,
  baseName: species.displayName,
  moniker: 'Legacy ${species.name} Nemesis',
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

bool _hasBloodOath(Iterable<HeirCandidate> heirs) =>
    heirs.any((heir) => heir.quirk.id == BloodlineTraitId.bloodOath);

GameSession _newVoyage({ProfileData? profile, int seed = 42}) =>
    GameSession(rng: SeededGameRng(seed), profile: profile)
      ..dispatch(const BeginFirstVoyage('Founder Vane'));

List<Map<String, dynamic>> _heirsJson(GameSession session) =>
    session.pendingHeirCandidates.map((heir) => heir.toJson()).toList();

void main() {
  for (final titan in _titans) {
    test('${titan.name} rejects Nemesis creation', () {
      expect(titan.isRegionTitan, isTrue);
      final rng = SeededGameRng(51);
      expect(
        () => NemesisRecord.createFromDefeat(
          killer: createMonster(titan, level: 2, rng: rng),
          captainName: 'Founder',
          regionIndex: _titans.indexOf(titan),
          rng: rng,
        ),
        throwsArgumentError,
      );
      expect(
        () => _legacyRecord(titan).instantiateMonster(rng),
        throwsStateError,
      );
    });

    test(
      '${titan.name} death clears old vengeance and records one captain',
      () {
        final session = _newVoyage(
          profile: ProfileData(
            activeNemesis: _legacyRecord(MonsterSpecies.shark),
          ),
        );
        // Enter the actual regional Titan through its convergent heading.
        session.phase = SessionPhase.restArea;
        session.seaChart.timesCompleted = _titans.indexOf(titan);
        session.seaChart.currentLeg = session.seaChart.totalLegs - 1;
        session.dispatch(const TakeHelm());
        session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
        expect(session.currentMonster!.species, titan);
        session.ship!.applyDamage(session.ship!.maxHp);
        final events = session.dispatch(const ExecuteShipSpecialAction());

        expect(session.phase, SessionPhase.death);
        expect(session.profile.activeNemesis, isNull);
        expect(events.whereType<NemesisSpawned>(), isEmpty);
        expect(events.whereType<CaptainLost>(), hasLength(1));
        expect(session.lineage.captainsLost, 1);
        expect(session.lineage.history, hasLength(1));
        expect(session.lineage.history.single.captainName, 'Founder Vane');
        expect(
          session.lineage.history.single.causeOfDeath,
          session.currentMonster!.name,
        );
        expect(session.pendingHeirCandidates, hasLength(3));
        expect(_hasBloodOath(session.pendingHeirCandidates), isFalse);
        final offered = _heirsJson(session);
        expect(
          () => session.dispatch(
            ContinueLineage(
              'Invalid Vendetta',
              ShipClass.standard,
              quirk: BloodlineTrait.bloodOath,
            ),
          ),
          throwsStateError,
        );
        expect(session.phase, SessionPhase.death);
        expect(_heirsJson(session), offered);
        expect(session.captainName, 'Founder Vane');
        final heir = session.pendingHeirCandidates.first;
        session.dispatch(
          ContinueLineage(
            heir.defaultName,
            ShipClass.standard,
            boon: heir.boon,
            quirk: heir.quirk,
          ),
        );
        expect(session.phase, SessionPhase.port);
        expect(session.activeQuirk!.id, isNot(BloodlineTraitId.bloodOath));
      },
    );

    test('${titan.name} legacy profile discards only active Nemesis', () {
      final original = _newVoyage();
      original.ship!.applyDamage(original.ship!.maxHp);
      original.dispatch(const ExecuteShipSpecialAction());
      final json = original.profile.toJson();
      json['activeNemesis'] = _legacyRecord(titan).toJson();

      expect(
        ProfileData(activeNemesis: _legacyRecord(titan)).activeNemesis,
        isNull,
      );
      final loaded = ProfileData.fromJson(json);
      expect(loaded.activeNemesis, isNull);
      final expected = Map<String, dynamic>.from(json)
        ..['activeNemesis'] = null;
      expect(loaded.toJson(), expected);
      loaded.activeNemesis = _legacyRecord(titan);
      expect(loaded.activeNemesis, isNull);
      // Decoding the historical record itself is still supported.
      expect(
        NemesisRecord.fromJson(_legacyRecord(titan).toJson()).species,
        titan,
      );
    });
  }

  for (final beast in _beasts) {
    for (final isApex in [false, true]) {
      test(
        '${beast.name} Apex=$isApex death retains vengeance eligibility',
        () {
          expect(beast.isRegionTitan, isFalse);
          final session = _newVoyage();
          session.currentMonster = createMonster(
            beast,
            level: 2,
            rng: session.rng,
            isApex: isApex,
          );
          session.ship!.applyDamage(session.ship!.maxHp);
          final events = session.dispatch(const ExecuteShipSpecialAction());
          expect(session.profile.activeNemesis!.species, beast);
          expect(events.whereType<NemesisSpawned>(), hasLength(1));
          expect(session.pendingHeirCandidates, hasLength(3));
          expect(_hasBloodOath(session.pendingHeirCandidates), isTrue);
          expect(session.lineage.history, hasLength(1));
          final loaded = ProfileData.fromJson(session.profile.toJson());
          expect(
            loaded.activeNemesis!.toJson(),
            session.profile.activeNemesis!.toJson(),
          );
          final vendetta = session.pendingHeirCandidates.firstWhere(
            (heir) => heir.quirk.id == BloodlineTraitId.bloodOath,
          );
          session.dispatch(
            ContinueLineage(
              vendetta.defaultName,
              ShipClass.standard,
              boon: vendetta.boon,
              quirk: vendetta.quirk,
            ),
          );
          expect(session.activeQuirk!.id, BloodlineTraitId.bloodOath);
        },
      );
    }
  }

  test(
    'repeated heir rolls exclude Blood Oath without an eligible Nemesis',
    () {
      for (final species in <MonsterSpecies?>[null, ..._titans]) {
        for (var seed = 0; seed < 100; seed++) {
          final heirs = generateHeirCandidates(
            rng: SeededGameRng(seed),
            previousCaptainName: 'Founder Vane',
            nemesisSpecies: species,
          );
          expect(heirs, hasLength(3));
          expect(_hasBloodOath(heirs), isFalse, reason: '$species seed $seed');
        }
      }
      for (final species in _beasts) {
        final heirs = generateHeirCandidates(
          rng: SeededGameRng(7),
          previousCaptainName: 'Founder Vane',
          nemesisSpecies: species,
        );
        expect(_hasBloodOath(heirs), isTrue, reason: species.name);
      }
    },
  );

  for (final species in <MonsterSpecies?>[
    null,
    ..._titans,
    MonsterSpecies.shark,
  ]) {
    test(
      'pending heir reload repairs only unsupported Blood Oath: $species',
      () {
        final source = _newVoyage();
        source.phase = SessionPhase.death;
        source.pendingHeirCandidates = [
          HeirCandidate(
            defaultName: 'Chosen Name Vane',
            boon: BloodlineTrait.veteranCannoneer,
            quirk: BloodlineTrait.bloodOath,
          ),
          HeirCandidate(
            defaultName: 'Second Vane',
            boon: BloodlineTrait.drillmaster,
            quirk: BloodlineTrait.recklessHelmsman,
          ),
          HeirCandidate(
            defaultName: 'Third Vane',
            boon: BloodlineTrait.stormSeer,
            quirk: BloodlineTrait.saltAddict,
          ),
        ];
        final before = _heirsJson(source);
        final save = VoyageSaveData.fromJson(
          VoyageSaveData.fromSession(source).toJson(),
        );
        GameSession restore(int seed) {
          final profileJson = source.profile.toJson();
          profileJson['activeNemesis'] = species == null
              ? null
              : _legacyRecord(species).toJson();
          final restored = GameSession(
            rng: SeededGameRng(seed),
            profile: ProfileData.fromJson(profileJson),
          );
          save.restoreToSession(restored);
          return restored;
        }

        final restored = restore(91);
        final repaired = _heirsJson(restored);
        expect(restored.pendingHeirCandidates, hasLength(3));
        expect(repaired[0]['defaultName'], before[0]['defaultName']);
        expect(repaired[0]['boon'], before[0]['boon']);
        expect(repaired.skip(1), before.skip(1));
        expect(
          _hasBloodOath(restored.pendingHeirCandidates),
          species == MonsterSpecies.shark,
        );
        expect(_heirsJson(restore(912)), repaired);
        final again = GameSession(
          rng: SeededGameRng(1001),
          profile: restored.profile,
        );
        VoyageSaveData.fromJson(VoyageSaveData.fromSession(restored).toJson())
            .restoreToSession(again);
        expect(_heirsJson(again), repaired);
        if (species == MonsterSpecies.shark) expect(repaired, before);
      },
    );
  }

  for (final species in [..._titans, MonsterSpecies.shark]) {
    test(
      'helm reload removes only invalid Titan Nemesis courses: $species',
      () {
        final source = _newVoyage(
          profile: ProfileData(
            activeNemesis: _legacyRecord(MonsterSpecies.shark),
          ),
        );
        source.phase = SessionPhase.restArea;
        source.seaChart.currentLeg = source.seaChart.midpointHavenLeg;
        source.dispatch(const TakeHelm());
        final chartJson = source.seaChart.toJson();
        final options = chartJson['courseOptions'] as List;
        final nemesisOption = options.cast<Map<String, dynamic>>().singleWhere(
          (option) => option['isNemesis'] == true,
        );
        nemesisOption['monsterSpecies'] = species.name;
        nemesisOption['apexTitle'] = _legacyRecord(species).moniker;
        chartJson['currentIsNemesis'] = species.isRegionTitan;
        final voyageJson = VoyageSaveData.fromSession(source).toJson();
        voyageJson['seaChartState'] = chartJson;
        final profileJson = source.profile.toJson();
        profileJson['activeNemesis'] = _legacyRecord(species).toJson();
        final restored = GameSession(
          rng: SeededGameRng(912),
          profile: ProfileData.fromJson(profileJson),
        );
        VoyageSaveData.fromJson(voyageJson).restoreToSession(restored);

        if (species.isRegionTitan) {
          expect(restored.seaChart.currentIsNemesis, isFalse);
          // The traveled route is historical evidence, not an active offer.
          expect(
            restored.seaChart.toJson()['voyageLog'],
            chartJson['voyageLog'],
          );
          expect(restored.seaChart.currentLeg, source.seaChart.currentLeg);
          final regenerated = restored.seaChart.currentCourseOptions;
          expect(regenerated, hasLength(3));
          expect(regenerated.any((course) => course.isNemesis), isFalse);
          expect(regenerated.any((course) =>
              course.monsterSpecies?.isRegionTitan == true), isFalse);
        } else {
          expect(restored.seaChart.toJson(), chartJson);
          expect(restored.profile.activeNemesis!.species, MonsterSpecies.shark);
        }
      },
    );
  }
}
