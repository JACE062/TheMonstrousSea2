import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'missed charge keeps danger in preview but emits no collision outcome',
    () {
      final intent = MonsterIntent.fromId(MonsterIntentId.jellyfishArcPulse);
      final monster = createJellyfish(level: 1, rng: SeededGameRng(1))
        ..currentIntent = intent;
      final ship = createFlagshipFromBlueprint(
        BlueprintId.standard,
        rng: SeededGameRng(2),
      );
      expect(
        intent
            .evaluatePreview(
              currentRange: CombatRange.medium,
              selectedHelmOrder: HelmOrder.advance,
            )
            .status,
        IntentPreviewStatus.headOnCollisionDanger,
      );
      final (_, events) = executeMonsterIntent(
        monster,
        ship,
        _MissRng(),
        CombatRange.short,
        BalanceConfig.standard,
        const [],
        HelmOrder.advance,
      );
      expect(ship.currentHp, ship.maxHp);
      expect(events.whereType<HeadOnCollisionOccurred>(), isEmpty);
      expect(events.whereType<MonsterAttackOutOfRange>(), isEmpty);
    },
  );

  for (final id in [
    MonsterIntentId.jellyfishArcPulse,
    MonsterIntentId.jellyfishNematocystCurtain,
  ]) {
    for (final range in CombatRange.values) {
      for (final order in range.availableHelmOrders) {
        test(
          '$id from $range with $order: forecast matches positional strike/collision',
          () {
            final intent = MonsterIntent.fromId(id);
            final preview = intent.evaluatePreview(
              currentRange: range,
              selectedHelmOrder: order,
            );
            final monster = createJellyfish(level: 1, rng: SeededGameRng(1))
              ..currentIntent = intent;
            final ship = createFlagshipFromBlueprint(
              BlueprintId.standard,
              rng: SeededGameRng(2),
            );
            final (end, events) = executeMonsterIntent(
              monster,
              ship,
              SeededGameRng(3),
              range.rangeAfterHelmOrder(order),
              BalanceConfig.standard,
              const [],
              order,
            );
            expect(end, preview.projectedEndOfRoundRange);
            expect(
              events.whereType<MonsterAttackOutOfRange>().isNotEmpty,
              preview.isSafe,
            );
            expect(
              events.whereType<HeadOnCollisionOccurred>().isNotEmpty,
              preview.status == IntentPreviewStatus.headOnCollisionDanger,
            );
          },
        );
      }
    }
  }
  test('lunge punishes holding/advancing from Medium and allows retreat', () {
    final lunge = MonsterIntent.fromId(MonsterIntentId.jellyfishArcPulse);
    expect(lunge.threatenedRanges, {CombatRange.short});
    expect(
      lunge
          .evaluatePreview(
            currentRange: CombatRange.medium,
            selectedHelmOrder: HelmOrder.holdLine,
          )
          .isSafe,
      isFalse,
    );
    expect(
      lunge
          .evaluatePreview(
            currentRange: CombatRange.medium,
            selectedHelmOrder: HelmOrder.advance,
          )
          .status,
      IntentPreviewStatus.headOnCollisionDanger,
    );
    expect(
      lunge
          .evaluatePreview(
            currentRange: CombatRange.medium,
            selectedHelmOrder: HelmOrder.fallBack,
          )
          .isSafe,
      isTrue,
    );
  });
  test(
    'Jellyfish threatens Long and alternates complementary attacks at Medium',
    () {
      final monster = createJellyfish(level: 1, rng: SeededGameRng(1));
      final ranged = selectNextMonsterIntent(
        monster,
        CombatRange.long,
        SeededGameRng(2),
      );
      expect(ranged.id, MonsterIntentId.jellyfishNematocystCurtain);
      expect(ranged.threatenedRanges, {CombatRange.medium, CombatRange.long});
      expect(ranged.moveTiming, IntentMoveTiming.none);
      monster.lastExecutedIntentId = MonsterIntentId.jellyfishArcPulse;
      expect(
        selectNextMonsterIntent(
          monster,
          CombatRange.medium,
          SeededGameRng(2),
        ).id,
        ranged.id,
      );
      monster.lastExecutedIntentId = ranged.id;
      expect(
        selectNextMonsterIntent(
          monster,
          CombatRange.medium,
          SeededGameRng(2),
        ).id,
        MonsterIntentId.jellyfishArcPulse,
      );
    },
  );
  test(
    'a charge that finishes outside its strike zone emits no collision bonus',
    () {
      final monster = createJellyfish(level: 1, rng: SeededGameRng(1))
        ..currentIntent = const MonsterIntent(
          id: MonsterIntentId.jellyfishArcPulse,
          threatenedRanges: {CombatRange.medium, CombatRange.long},
          moveDelta: IntentMoveDelta.closer1,
          moveTiming: IntentMoveTiming.beforeAttack,
          estimatedDamage: 14,
        );
      final ship = createFlagshipFromBlueprint(
        BlueprintId.standard,
        rng: SeededGameRng(2),
      );
      final (_, events) = executeMonsterIntent(
        monster,
        ship,
        SeededGameRng(3),
        CombatRange.short,
        BalanceConfig.standard,
        const [],
        HelmOrder.advance,
      );
      expect(events.whereType<MonsterAttackOutOfRange>(), hasLength(1));
      expect(events.whereType<HeadOnCollisionOccurred>(), isEmpty);
      expect(ship.currentHp, ship.maxHp);
    },
  );
}

class _MissRng extends SeededGameRng {
  @override
  int d100() => 100;
}
