import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

GameSession _session() => GameSession(rng: SeededGameRng(42))
  ..dispatch(const BeginFirstVoyage('Patch regression'))
  ..phase = SessionPhase.helm
  ..ship!.maxHp = 91
  ..ship!.currentHp = 1;

Consumable _kit(String id) =>
    generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common, id: id);

void main() {
  final captains = [
    (null, null, 27),
    (BloodlineTrait.skilledCarpenter, null, 33),
    (null, BloodlineTrait.exactingShipwright, 20),
    (BloodlineTrait.skilledCarpenter, BloodlineTrait.exactingShipwright, 25),
  ];
  for (var c = 0; c < captains.length; c++) {
    test(
      'captain $c carried/pending kits heal once with exact fractional modifiers',
      () {
        for (final pending in [false, true]) {
          final session = _session()
            ..activeBoon = captains[c].$1
            ..activeQuirk = captains[c].$2
            ..phase = SessionPhase.loot;
          final kit = _kit('kit-$c-$pending');
          for (var i = 0; i < session.ship!.maxCargo - (pending ? 0 : 1); i++) {
            session.ship!.addCargo(
              generateConsumable(ConsumableType.blastPack, RarityLevel.common),
            );
          }
          if (pending) {
            session.pendingLoot = [kit];
          } else {
            session.ship!.addCargo(kit);
            session.pendingLoot = [
              generateConsumable(ConsumableType.chakram, RarityLevel.common),
            ];
          }
          final belt = session.ship!.cargo.map((item) => item.id).toList();
          final gold = session.ship!.gold;
          final events = session.dispatch(
            UseHullPatchKit(kit.id, fromPendingLoot: pending),
          );
          final applied = events.whereType<HullPatchApplied>().single;
          expect(applied.restoredHp, captains[c].$3);
          expect(applied.itemId, kit.id);
          expect(applied.fromPendingLoot, pending);
          expect(session.ship!.currentHp, 1 + captains[c].$3);
          expect(session.ship!.gold, gold);
          expect(session.usedQuickConsumableThisTurn, isFalse);
          if (pending) {
            expect(session.ship!.cargo.map((item) => item.id).toList(), belt);
            expect(session.pendingLoot, isEmpty);
            expect(session.phase, SessionPhase.restArea);
          } else {
            expect(session.ship!.cargo, hasLength(belt.length - 1));
            expect(session.pendingLoot, hasLength(1));
            expect(session.phase, SessionPhase.loot);
          }
          final hp = session.ship!.currentHp;
          expect(
            () => session.dispatch(
              UseHullPatchKit(kit.id, fromPendingLoot: pending),
            ),
            throwsStateError,
          );
          expect(session.ship!.currentHp, hp);
        }
      },
    );
  }

  for (final phase in [
    SessionPhase.port,
    SessionPhase.stronghold,
    SessionPhase.merchant,
    SessionPhase.helm,
    SessionPhase.loot,
    SessionPhase.respiteIsland,
    SessionPhase.shipwreck,
    SessionPhase.smuggler,
  ]) {
    test(
      'carried kit is legal at $phase without changing phase or other items',
      () {
        final session = _session()..phase = phase;
        final kit = _kit('carried');
        final other = generateConsumable(
          ConsumableType.krakenInkBomb,
          RarityLevel.common,
        );
        session.ship!.cargo.addAll([kit, other]);
        session.dispatch(UseHullPatchKit(kit.id));
        expect(session.phase, phase);
        expect(session.ship!.cargo, [other]);
      },
    );
  }

  for (final phase in [
    SessionPhase.battle,
    SessionPhase.shrine,
    SessionPhase.captainCreation,
    SessionPhase.restArea,
    SessionPhase.death,
    SessionPhase.ended,
    SessionPhase.expeditionVictory,
  ]) {
    test('$phase rejects outside-battle kit command', () {
      final session = _session()..phase = phase;
      final kit = _kit('blocked');
      session.ship!.cargo.add(kit);
      expect(() => session.dispatch(UseHullPatchKit(kit.id)), throwsStateError);
      expect(session.ship!.cargo, [kit]);
      expect(session.ship!.currentHp, 1);
    });
  }

  test(
    'full hull preserves the exact kit and leaves pending routing unchanged',
    () {
      final session = _session()..phase = SessionPhase.loot;
      session.ship!.currentHp = 91;
      final kit = _kit('full');
      session.pendingLoot = [kit];
      final events = session.dispatch(
        UseHullPatchKit(kit.id, fromPendingLoot: true),
      );
      expect(events.whereType<HullPatchApplied>(), isEmpty);
      expect(
        events.whereType<NarrationEvent>().single.message,
        contains('full'),
      );
      expect(session.pendingLoot.single, same(kit));
      expect(kit.usesLeft, 1);
      expect(session.phase, SessionPhase.loot);
    },
  );

  test('direct use consumes only the selected pending kit, retaining another pending kit', () {
    final session = _session()..phase = SessionPhase.loot;
    session.pendingLoot = [_kit('first'), _kit('second')];
    session.dispatch(const UseHullPatchKit('second', fromPendingLoot: true));
    expect(session.pendingLoot.single.id, 'first');
    expect(session.phase, SessionPhase.loot);
    final hp = session.ship!.currentHp;
    expect(
      () => session.dispatch(
        const UseHullPatchKit('second', fromPendingLoot: true),
      ),
      throwsStateError,
    );
    expect(session.ship!.currentHp, hp);
  });

  test('only kits have this role, and shop stock is not pending loot', () {
    final session = _session()..phase = SessionPhase.merchant;
    final stock = _kit('stock');
    session.merchantStock = [stock];
    session.pendingLoot = [
      stock,
    ]; // Even a malformed fixture cannot buy-and-use for free.
    expect(
      () => session.dispatch(
        const UseHullPatchKit('stock', fromPendingLoot: true),
      ),
      throwsStateError,
    );
    expect(
      () => session.dispatch(const UseHullPatchKit('stock')),
      throwsStateError,
    );
    expect(session.merchantStock.single, same(stock));
    session.phase = SessionPhase.loot;
    final other = generateConsumable(
      ConsumableType.unstableTincture,
      RarityLevel.common,
      id: 'other',
    );
    session.pendingLoot = [other];
    expect(
      () => session.dispatch(
        const UseHullPatchKit('other', fromPendingLoot: true),
      ),
      throwsStateError,
    );
    expect(session.pendingLoot.single, same(other));
    expect(session.ship!.currentHp, 1);
  });

  test('pending-last kit returns to cleared wreck before any cargo claim', () {
    final session = _session()..phase = SessionPhase.loot;
    session.currentWreck = WreckEncounter(
      id: 'cleared',
      sighting: const WreckSighting(
        seed: 7,
        condition: WreckCondition.fresh,
        clearClue: true,
      ),
      stage: WreckStage.recovery,
      threatCleared: true,
      cargo: const WreckCargo(seaGlass: 3, iron: 1, gold: 20, supplies: []),
    );
    session.pendingLoot = [_kit('last')];
    session.dispatch(const UseHullPatchKit('last', fromPendingLoot: true));
    expect(session.phase, SessionPhase.shipwreck);
    expect(session.currentWreck!.stage, WreckStage.recovery);
    expect(session.profile.metaInventory.seaGlass, 0);
  });
}
