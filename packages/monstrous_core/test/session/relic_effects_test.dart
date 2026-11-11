import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class _Rolls extends SeededGameRng {
  _Rolls(this.roll) : super(42);
  final int roll;
  @override
  int d100() => roll;
}

GameSession battle(
  EldritchRelicId id, {
  bool forged = true,
  int roll = 50,
  bool shell = false,
}) {
  final s = GameSession(rng: _Rolls(roll));
  final def = EldritchRelicDef.catalog[id]!;
  s.profile.hasUnlockedCovenant = true;
  s.profile.unlockedBlueprints.add(def.blueprintId.name);
  s.dispatch(const NameCaptain('Relic witness'));
  s.dispatch(ChooseShip(def.blueprintId.shipClass));
  s.profile.metaInventory.add(
    krakenBeak: 10,
    serpentScale: 10,
    leviathanCore: 10,
    primordialCinders: 20,
  );
  if (forged) s.dispatch(UnlockEldritchRelic(id));
  s.phase = SessionPhase.battle;
  s.combatRange = CombatRange.medium;
  s.ship!.currentHp -= 40;
  for (final w in s.ship!.equippedWeapons) {
    w.hitModifier = 100;
    w.damage = 40;
  }
  s.currentMonster = createMonster(MonsterSpecies.shark, level: 1, rng: s.rng)
    ..maxHp = 1000
    ..currentHp = 1000
    ..carapacePlating = shell ? 5000 : 0
    ..evasion = 0;
  return s;
}

void main() {
  for (final id in EldritchRelicId.values) {
    test('$id adds its advertised effect only after forging', () {
      for (final forged in [false, true]) {
        final s = battle(id, forged: forged);
        final events = s.dispatch(
          FireWeaponVolley(EldritchRelicDef.catalog[id]!.weaponType),
        );
        if (id == EldritchRelicId.siphonRam) {
          final heal = events.whereType<CombatHealthChanged>().where(
            (e) => e.source == 'Siphon Ram',
          );
          expect(heal.length, forged ? 1 : 0);
          if (forged) {
            final flesh = events
                .whereType<AttackHit>()
                .where(
                  (e) => e.target == CombatSide.monster && !e.isBlessingDamage,
                )
                .fold<int>(0, (sum, e) => sum + e.damage);
            expect(heal.single.amount, (flesh * 0.30).round());
          }
        } else if (id == EldritchRelicId.ghostwakeCulverin) {
          final shock = events.whereType<CombatHealthChanged>().where(
            (e) => e.source == 'Ghostwake',
          );
          expect(shock.length, forged ? 1 : 0);
          if (forged) expect(shock.single.amount, 8);
          expect(
            events.whereType<NarrationEvent>().any(
              (e) => e.message.contains('critical strike'),
            ),
            isFalse,
            reason: 'The approved rider applies to ordinary flesh hits too.',
          );
        } else {
          final status = id == EldritchRelicId.brimstoneMortar
              ? StatusEffect.burn
              : StatusEffect.poison;
          expect(
            events.whereType<CombatEffectsChanged>().any(
              (e) =>
                  e.target == CombatSide.monster &&
                  e.state.statusEffects.contains(status),
            ),
            forged,
          );
        }
      }
    });
    test('$id does not add an on-hit effect to a miss', () {
      final s = battle(id, roll: 100);
      final events = s.dispatch(
        FireWeaponVolley(EldritchRelicDef.catalog[id]!.weaponType),
      );
      expect(
        events.whereType<CombatHealthChanged>().where(
          (e) => e.source == 'Ghostwake' || e.source == 'Siphon Ram',
        ),
        isEmpty,
      );
      expect(
        events.whereType<CombatEffectsChanged>().any(
          (e) =>
              e.target == CombatSide.monster &&
              e.state.statusEffects.isNotEmpty,
        ),
        isFalse,
      );
    });
  }

  test('Ghostwake bypasses Obscurity without clearing the enemy condition', () {
    final s = battle(EldritchRelicId.ghostwakeCulverin);
    s.currentMonster!
      ..isObscured = true
      ..obscuredAcMod = 20;
    final expected = calculateHitChance(
      s.ship!,
      s.ship!.equippedWeapons.singleWhere((w) => w.isSignature),
      s.currentMonster!,
      range: s.combatRange,
    );
    final events = s.dispatch(
      const FireWeaponVolley(ShipWeaponType.precisionCulverin),
    );
    final attempt = events.whereType<AttackAttempted>().first;
    expect(attempt.targetAc, greaterThan(expected));
    expect(s.currentMonster!.isObscured, isTrue);
  });

  test('flesh riders do not count armor damage as additional flesh damage', () {
    for (final id in [
      EldritchRelicId.siphonRam,
      EldritchRelicId.ghostwakeCulverin,
    ]) {
      final s = battle(id, shell: true);
      final events = s.dispatch(
        FireWeaponVolley(EldritchRelicDef.catalog[id]!.weaponType),
      );
      final flesh = events
          .whereType<AttackHit>()
          .where((e) => e.target == CombatSide.monster && !e.isBlessingDamage)
          .fold<int>(0, (sum, e) => sum + e.damage);
      final rider = events
          .whereType<CombatHealthChanged>()
          .where((e) => e.source == 'Ghostwake' || e.source == 'Siphon Ram')
          .fold<int>(0, (sum, e) => sum + e.amount);
      if (id == EldritchRelicId.siphonRam) {
        expect(rider, flesh == 0 ? 0 : (flesh * 0.30).round());
      } else {
        final fleshHits = events
            .whereType<AttackHit>()
            .where((e) => e.target == CombatSide.monster && !e.isBlessingDamage)
            .length;
        expect(rider, fleshHits * 8);
      }
    }
  });
}
