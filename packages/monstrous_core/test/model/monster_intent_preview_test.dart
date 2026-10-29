import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  final charge = MonsterIntent.fromId(MonsterIntentId.sharkBreachingLunge);
  final sweep = MonsterIntent.fromId(MonsterIntentId.squidSweepingTentacles);

  test('applied helm retains Advance collision after Ram closes to Short', () {
    final result = charge.evaluatePreview(
      currentRange: CombatRange.short,
      selectedHelmOrder: HelmOrder.advance,
      helmAlreadyApplied: true,
    );
    expect(result.playerPostHelmRange, CombatRange.short);
    expect(result.rangeAtStrike, CombatRange.short);
    expect(result.status, IntentPreviewStatus.headOnCollisionDanger);
    expect(result.estimatedDamage, (charge.estimatedDamage * 1.3).round());
  });

  test('applied Advance at Medium collides when the charge reaches Short', () {
    final result = charge.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.advance,
      helmAlreadyApplied: true,
    );
    expect(result.playerPostHelmRange, CombatRange.medium);
    expect(result.rangeAtStrike, CombatRange.short);
    expect(result.projectedEndOfRoundRange, CombatRange.short);
    expect(result.status, IntentPreviewStatus.headOnCollisionDanger);
    expect(result.estimatedDamage, (charge.estimatedDamage * 1.3).round());
  });

  test('Long Advance collision preview agrees with real response', () {
    final session = GameSession(rng: SeededGameRng(42));
    session.dispatch(const NameCaptain('Preview parity'));
    session.dispatch(const ChooseShip(ShipClass.standard));
    session.dispatch(const VentureOutToSea());
    session.phase = SessionPhase.battle;
    session.combatRange = CombatRange.long;
    final shark = createMonster(
      MonsterSpecies.shark,
      level: 2,
      rng: SeededGameRng(1),
    )..currentIntent = charge;
    session.currentMonster = shark;

    final result = charge.evaluatePreview(
      currentRange: CombatRange.long,
      selectedHelmOrder: HelmOrder.advance,
    );
    expect(result.playerPostHelmRange, CombatRange.medium);
    expect(result.status, IntentPreviewStatus.headOnCollisionDanger);
    session.dispatch(const IssueHelmOrder(HelmOrder.advance));
    final events = session.dispatch(const ExecuteShipSpecialAction());
    expect(events.whereType<HeadOnCollisionOccurred>(), hasLength(1));
    expect(session.combatRange, result.rangeAtStrike);
  });

  test('applied Advance at Long still avoids a collision', () {
    final result = charge.evaluatePreview(
      currentRange: CombatRange.long,
      selectedHelmOrder: HelmOrder.advance,
      helmAlreadyApplied: true,
    );
    expect(result.playerPostHelmRange, CombatRange.long);
    expect(result.rangeAtStrike, CombatRange.medium);
    expect(result.status, IntentPreviewStatus.inThreatZone);
  });

  for (final range in [CombatRange.medium, CombatRange.long]) {
    test('applied Advance does not move $range a second time', () {
      final result = sweep.evaluatePreview(
        currentRange: range,
        selectedHelmOrder: HelmOrder.advance,
        helmAlreadyApplied: true,
      );
      expect(result.playerPostHelmRange, range);
      expect(result.rangeAtStrike, range);
      expect(result.projectedEndOfRoundRange, range);
      expect(
        result.status,
        range == CombatRange.long
            ? IntentPreviewStatus.evadedByPosition
            : IntentPreviewStatus.inThreatZone,
      );
    });
  }

  test('Hold Line stays equivalent when helm is already applied', () {
    final ordinary = charge.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.holdLine,
    );
    final applied = charge.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.holdLine,
      helmAlreadyApplied: true,
    );
    expect(applied.playerPostHelmRange, ordinary.playerPostHelmRange);
    expect(applied.rangeAtStrike, ordinary.rangeAtStrike);
    expect(applied.projectedEndOfRoundRange, ordinary.projectedEndOfRoundRange);
    expect(applied.status, ordinary.status);
    expect(applied.estimatedDamage, ordinary.estimatedDamage);
  });

  test('default still applies selected helm before monster movement', () {
    final result = charge.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.advance,
    );
    expect(result.playerPostHelmRange, CombatRange.short);
    expect(result.status, IntentPreviewStatus.headOnCollisionDanger);
    final retreat = sweep.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.fallBack,
    );
    expect(retreat.playerPostHelmRange, CombatRange.long);
    expect(retreat.status, IntentPreviewStatus.evadedByPosition);
  });

  test('Pin prevents charge and collision with an already applied Advance', () {
    final result = charge.evaluatePreview(
      currentRange: CombatRange.short,
      selectedHelmOrder: HelmOrder.advance,
      helmAlreadyApplied: true,
      isMonsterPinned: true,
    );
    expect(result.playerPostHelmRange, CombatRange.short);
    expect(result.rangeAtStrike, CombatRange.short);
    expect(result.status, IntentPreviewStatus.inThreatZone);
    expect(result.estimatedDamage, charge.estimatedDamage);
    final mediumResult = charge.evaluatePreview(
      currentRange: CombatRange.medium,
      selectedHelmOrder: HelmOrder.advance,
      helmAlreadyApplied: true,
      isMonsterPinned: true,
    );
    expect(mediumResult.rangeAtStrike, CombatRange.medium);
    expect(mediumResult.status, IntentPreviewStatus.inThreatZone);
    expect(mediumResult.estimatedDamage, charge.estimatedDamage);
  });
}
