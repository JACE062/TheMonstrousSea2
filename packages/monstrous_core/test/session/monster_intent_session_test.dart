import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _AlwaysHitRng implements GameRng {
  @override
  int d(int n) => 1;

  @override
  int d20() => 20;

  @override
  int d100() => 1; // Always hits, never evaded by RNG

  @override
  int nextInt(int max) => 0;

  @override
  int nextIntRange(int min, int max) => min;

  @override
  double nextDouble() => 0.0;
}

void main() {
  group('Combat Redesign Phase 2: Telegraphed Monster Intent & Spatial Dynamics', () {
    late GameSession session;

    setUp(() {
      session = GameSession(rng: _AlwaysHitRng());
      session.dispatch(const NameCaptain('Captain Vance'));
      session.dispatch(const ChooseShip(ShipClass.standard));
      session.dispatch(const VentureOutToSea());
      session.phase = SessionPhase.battle;
      session.combatRange = CombatRange.medium;
      session.ship!.baseEvasion = 0;
      session.ship!.currentEvasion = 0;
    });

    test('Shark Frenzied Jaws adds +1 Frenzy stack BEFORE attempting to hit, even if dodged by range', () {
      final shark = createMonster(MonsterSpecies.shark, level: 2, rng: _AlwaysHitRng());
      session.currentMonster = shark;
      session.combatRange = CombatRange.short;
      shark.currentIntent = selectNextMonsterIntent(
        shark,
        session.combatRange,
        _AlwaysHitRng(),
      );

      expect(shark.currentIntent!.id, MonsterIntentId.sharkFrenziedJaws);
      expect(shark.frenzyStacks, 0);

      // Player retreats from Short to Medium Range and uses Special Action
      session.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
      expect(session.combatRange, CombatRange.medium);

      final hpBefore = session.ship!.currentHp;
      final events = session.dispatch(const ExecuteShipSpecialAction());

      // Even though the ship moved out of Short Range and evaded the bite,
      // the Shark still gained +1 Frenzy stack before attempting to hit!
      expect(shark.frenzyStacks, 1);
      expect(events.whereType<SharkFrenzyRoared>(), isNotEmpty);
      expect(events.whereType<MonsterAttackOutOfRange>(), isNotEmpty);
      expect(session.ship!.currentHp, hpBefore);
    });

    test('Shark Breaching Lunge closes 1 band pre-attack and catches ships retreating from Medium to Long', () {
      final shark = createMonster(MonsterSpecies.shark, level: 2, rng: _AlwaysHitRng());
      session.currentMonster = shark;
      session.combatRange = CombatRange.medium;
      shark.currentIntent = selectNextMonsterIntent(
        shark,
        session.combatRange,
        _AlwaysHitRng(),
      );

      expect(shark.currentIntent!.id, MonsterIntentId.sharkBreachingLunge);

      // Player retreats from Medium to Long Range
      session.dispatch(const IssueHelmOrder(HelmOrder.fallBack));
      expect(session.combatRange, CombatRange.long);

      // Shark lunges 1 band closer (Long -> Medium) BEFORE attacking and hits Medium/Short
      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(session.combatRange, CombatRange.medium);
      expect(events.whereType<MonsterAttackOutOfRange>(), isEmpty);
      expect(
        events.whereType<AttackHit>().any((e) => e.targetName == session.ship!.name),
        isTrue,
      );
    });

    test('Head-On Collision (Bullfighter Gambit) triggers +30% impact damage when advancing into a closer1 charge at Short Range', () {
      final shark = createMonster(MonsterSpecies.shark, level: 2, rng: _AlwaysHitRng());
      shark.maxHp = 500;
      shark.currentHp = 500;
      session.currentMonster = shark;
      session.combatRange = CombatRange.medium;
      shark.currentIntent = MonsterIntent.fromId(MonsterIntentId.sharkBreachingLunge);

      final preview = shark.currentIntent!.evaluatePreview(
        currentRange: CombatRange.medium,
        selectedHelmOrder: HelmOrder.advance,
      );
      expect(preview.status, IntentPreviewStatus.headOnCollisionDanger);

      session.dispatch(const IssueHelmOrder(HelmOrder.advance));
      expect(session.combatRange, CombatRange.short);

      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(events.whereType<HeadOnCollisionOccurred>(), isNotEmpty);
    });

    test('Crustacean Calcify Carapace restores 35% of maxCarapace and purges Burn/Poison when below 50% plating', () {
      final crab = createMonster(MonsterSpecies.crustacean, level: 3, rng: _AlwaysHitRng());
      crab.maxCarapace = 40;
      crab.carapacePlating = 10; // < 50% of 40
      crab.addStatus(StatusEffect.burn);
      crab.addStatus(StatusEffect.poison);
      session.currentMonster = crab;

      final intent = selectNextMonsterIntent(crab, CombatRange.medium, _AlwaysHitRng());
      expect(intent.id, MonsterIntentId.crustaceanCalcifyCarapace);
      crab.currentIntent = intent;

      session.dispatch(const ExecuteShipSpecialAction());

      // 35% of 40 = 14 restored -> 10 + 14 = 24
      expect(crab.carapacePlating, 24);
      expect(crab.hasStatus(StatusEffect.burn), isFalse);
      expect(crab.hasStatus(StatusEffect.poison), isFalse);
      expect(crab.isIntentOnCooldown(MonsterIntentId.crustaceanCalcifyCarapace), isTrue);
    });

    test('Crustacean Brine Jet has a safe blind spot at Short Range, and Tremor Slam breaks the Short <-> Medium loop', () {
      final crab = createMonster(MonsterSpecies.crustacean, level: 2, rng: _AlwaysHitRng());
      crab.maxHp = 500;
      crab.currentHp = 500;
      session.currentMonster = crab;
      session.combatRange = CombatRange.medium;
      crab.currentIntent = MonsterIntent.fromId(MonsterIntentId.crustaceanBrineJet);

      // Player advances from Medium into Short Range blind spot
      session.dispatch(const IssueHelmOrder(HelmOrder.advance));
      expect(session.combatRange, CombatRange.short);

      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(events.whereType<MonsterAttackOutOfRange>(), isNotEmpty);

      // Because lastExecutedIntentId was crustaceanBrineJet and ship is now at Short Range,
      // Crustacean selects Tremor Slam ({short, medium}) to break the Short <-> Medium dodge loop!
      expect(crab.currentIntent!.id, MonsterIntentId.crustaceanTremorSlam);
    });

    test('Serpent Abyssal Under-Strike from Long Range ambushes to Short Range and hits all ranges', () {
      final serpent = createMonster(MonsterSpecies.serpent, level: 2, rng: _AlwaysHitRng());
      serpent.maxHp = 500;
      serpent.currentHp = 500;
      session.currentMonster = serpent;
      session.combatRange = CombatRange.long;
      serpent.currentIntent = selectNextMonsterIntent(
        serpent,
        CombatRange.long,
        _AlwaysHitRng(),
      );

      expect(serpent.currentIntent!.id, MonsterIntentId.serpentAbyssalUnderStrike);

      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(session.combatRange, CombatRange.short);
      expect(events.whereType<MonsterAttackOutOfRange>(), isEmpty);
      expect(
        events.whereType<AttackHit>().any((e) => e.targetName == session.ship!.name),
        isTrue,
      );
    });

    test('Squid Constricting Beak grapples the ship for 1 player turn, locking Helm Orders to Hold Line', () {
      final squid = createMonster(MonsterSpecies.squid, level: 2, rng: _AlwaysHitRng());
      squid.maxHp = 500;
      squid.currentHp = 500;
      session.currentMonster = squid;
      session.combatRange = CombatRange.short;
      squid.currentIntent = MonsterIntent.fromId(MonsterIntentId.squidConstrictingBeak);

      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(events.whereType<ShipGrappled>(), isNotEmpty);
      expect(session.ship!.isGrappled, isTrue);

      // While grappled, attempting to Fall Back throws StateError
      expect(
        () => session.dispatch(const IssueHelmOrder(HelmOrder.fallBack)),
        throwsStateError,
      );
      // Hold Line is permitted
      expect(
        () => session.dispatch(const IssueHelmOrder(HelmOrder.holdLine)),
        returnsNormally,
      );

      // After the player completes their turn, the grapple expires
      session.dispatch(const ExecuteShipSpecialAction());
      expect(session.ship!.isGrappled, isFalse);
    });

    test('Region Boss 2-turn Catastrophe Wind-up can be disrupted by Heavy Mortar or Poise damage threshold', () {
      final kraken = createMonster(MonsterSpecies.kraken, level: 4, rng: _AlwaysHitRng());
      kraken.maxHp = 1000;
      kraken.currentHp = 1000;
      session.currentMonster = kraken;
      session.battleRound = 2;

      final windup = selectNextMonsterIntent(
        kraken,
        CombatRange.medium,
        _AlwaysHitRng(),
        battleRound: 2,
      );
      expect(windup.id, MonsterIntentId.bossKrakenWindup);
      expect(windup.isBossWindup, isTrue);
      kraken.currentIntent = windup;

      // Equip a Heavy Mortar and fire it to disrupt the Boss Wind-up
      final mortar = generateShipWeapon(
        ShipWeaponType.heavyMortar,
        3,
        RarityLevel.rare,
        _AlwaysHitRng(),
      );
      session.ship!.equippedWeapons.clear();
      session.ship!.addCargo(mortar);
      session.ship!.equipWeapon(mortar);

      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.heavyMortar));
      expect(events.whereType<MonsterIntentDisrupted>(), isNotEmpty);
      expect(events.whereType<MonsterHesitated>(), isNotEmpty);
      expect(
        kraken.isIntentOnCooldown(MonsterIntentId.bossKrakenWindup),
        isTrue,
      );
    });

    test('Serpent at Medium Range alternates to Fanged Whip ({short, medium}) when Venom Spit is on cooldown, breaking the infinite dodge loop', () {
      final serpent = createMonster(MonsterSpecies.serpent, level: 2, rng: _AlwaysHitRng());
      serpent.maxHp = 500;
      serpent.currentHp = 500;
      session.currentMonster = serpent;
      session.combatRange = CombatRange.medium;

      // Turn 1: Serpent telegraphs Venom Spit ({medium, long})
      final intent1 = selectNextMonsterIntent(serpent, CombatRange.medium, _AlwaysHitRng());
      expect(intent1.id, MonsterIntentId.serpentVenomSpitRecoil);
      serpent.currentIntent = intent1;

      // Player advances to Short Range to avoid the spit
      session.dispatch(const IssueHelmOrder(HelmOrder.advance));
      expect(session.combatRange, CombatRange.short);

      final turn1Events = session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(turn1Events.whereType<MonsterAttackOutOfRange>(), isNotEmpty);

      // Serpent recoiled 1 band post-attack (Short -> Medium)
      expect(session.combatRange, CombatRange.medium);
      expect(serpent.lastExecutedIntentId, MonsterIntentId.serpentVenomSpitRecoil);
      expect(serpent.isIntentOnCooldown(MonsterIntentId.serpentVenomSpitRecoil), isTrue);

      // Turn 2: Since Venom Spit is on cooldown / was last executed, Serpent selects Fanged Whip ({short, medium})!
      expect(serpent.currentIntent!.id, MonsterIntentId.serpentFangedWhipRecoil);
      expect(serpent.currentIntent!.threatenedRanges.contains(CombatRange.short), isTrue);

      // If the player attempts to advance to Short Range again to repeat their trick:
      session.dispatch(const IssueHelmOrder(HelmOrder.advance));
      expect(session.combatRange, CombatRange.short);

      final turn2Events = session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));

      // The Fanged Whip hits the player at Short Range! The infinite loop is broken!
      expect(turn2Events.whereType<MonsterAttackOutOfRange>(), isEmpty);
      expect(
        turn2Events.whereType<AttackHit>().any((e) => e.targetName == session.ship!.name),
        isTrue,
      );
    });

    test('BraceForImpact allows captain to pass turn defensively when all weapons are on cooldown without soft-lock', () {
      final shark = createMonster(MonsterSpecies.shark, level: 2, rng: _AlwaysHitRng());
      session.currentMonster = shark;
      session.combatRange = CombatRange.medium;
      shark.currentIntent = selectNextMonsterIntent(shark, CombatRange.medium, _AlwaysHitRng());

      // Give ship a torpedo launcher with 2-turn cooldown
      final torpedo = generateShipWeapon(ShipWeaponType.torpedoLauncher, 2, RarityLevel.rare, _AlwaysHitRng());
      session.ship!.equippedWeapons.clear();
      session.ship!.addCargo(torpedo);
      session.ship!.equipWeapon(torpedo);
      expect(torpedo.isReady, isTrue);

      // Round 1: Fire Torpedo -> goes on cooldown
      session.dispatch(const FireWeaponVolley(ShipWeaponType.torpedoLauncher));
      expect(torpedo.isReady, isFalse);
      expect(torpedo.chargeCountdown > 0, isTrue);

      // Round 2: With weapon on cooldown and no other weapons ready, dispatch BraceForImpact
      final braceEvents = session.dispatch(const BraceForImpact());

      // Ship braced behind gunwales (+10% evasion) and monster turn resolved cleanly
      expect(braceEvents.whereType<NarrationEvent>().any((e) => e.message.contains('braces behind the gunwales')), isTrue);
      expect(session.battleRound, 3);
    });
  });
}
