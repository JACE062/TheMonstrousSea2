import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import 'ink_button.dart';

/// Intent essentials for the detached, currently displayed battle state.
///
/// This reads the core preview only. Intrinsic action movement and hit-dependent
/// interruption belong to action forecasts, so a helm forecast can be conditional.
class BattleLookout extends StatelessWidget {
  const BattleLookout({
    super.key,
    required this.monster,
    required this.currentRange,
    required this.selectedHelmOrder,
    required this.conditional,
    required this.isResolving,
    this.helmAlreadyApplied = false,
    this.compact = false,
    this.actionNotes = const [],
  });

  final MonsterState monster;
  final CombatRange currentRange;
  final HelmOrder selectedHelmOrder;
  final bool conditional;
  final bool isResolving;
  final bool helmAlreadyApplied;
  final bool compact;
  final List<String> actionNotes;

  IntentPreviewOutcome _preview(MonsterIntent intent) => intent.evaluatePreview(
    currentRange: currentRange,
    selectedHelmOrder: selectedHelmOrder,
    helmAlreadyApplied: helmAlreadyApplied,
    isMonsterPinned: monster.isPinnedThisTurn,
    tentacleCount: monster.numberOfTentacles,
    damagePerTentacle: monster.usableWeapons
        .where(
          (weapon) => weapon.monsterWeaponType == MonsterWeaponType.tentacle,
        )
        .firstOrNull
        ?.damage,
  );

  String _timing(MonsterIntent intent) {
    if (intent.isBossWindup) return 'Windup 1/2 · no strike this turn';
    if (intent.isBossCatastropheStrike) {
      return 'Release 2/2 · strikes this turn';
    }
    if (intent.moveDelta == IntentMoveDelta.stationary) {
      return intent.threatenedRanges.isEmpty
          ? 'Fortifies this turn'
          : 'Strikes without moving';
    }
    if (monster.isPinnedThisTurn) return 'Pinned · movement prevented';
    final movement = switch (intent.moveDelta) {
      IntentMoveDelta.closer1 => 'Closes one band',
      IntentMoveDelta.farther1 => 'Recoils one band',
      IntentMoveDelta.pullShipCloser1 => 'Pulls ship closer if in range',
      IntentMoveDelta.ambushToShort => 'Ambushes at Short',
      IntentMoveDelta.stationary => '',
    };
    final timing = intent.moveTiming == IntentMoveTiming.beforeAttack
        ? 'before attack'
        : 'after attack';
    return '$movement $timing';
  }

  String _assessment(IntentPreviewOutcome preview) => switch (preview.status) {
    IntentPreviewStatus.evadedByPosition =>
      'Outside threat at ${preview.rangeAtStrike.displayName}',
    IntentPreviewStatus.inThreatZone =>
      'Threatened at ${preview.rangeAtStrike.displayName}',
    IntentPreviewStatus.headOnCollisionDanger => 'Head-on collision danger',
    IntentPreviewStatus.bossWindupSafeThisTurn => 'No strike this turn',
    IntentPreviewStatus.bossCatastropheImminent =>
      'Release threatens all ranges',
    IntentPreviewStatus.nonAttackBuff => 'No direct attack',
  };

  @override
  Widget build(BuildContext context) {
    final intent = monster.currentIntent;
    final preview = intent == null || isResolving ? null : _preview(intent);
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: InkTheme.parchmentHighlight,
          border: Border.all(color: InkTheme.inkMuted),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('LOOKOUT', style: InkTheme.caption),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    intent?.name ?? 'Awaiting the beast',
                    style: InkTheme.bodyBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (intent != null)
                  IconButton(
                    tooltip: 'Inspect monster intent',
                    icon: const Icon(Icons.info_outline, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _inspect(context, intent, preview),
                  ),
              ],
            ),
            if (intent != null)
              Text(
                'Threatens: ${intent.threatenedRangesLabel} · ${_timing(intent)}',
                style: InkTheme.caption,
              ),
            if (isResolving)
              Text('Orders resolving…', style: InkTheme.caption)
            else if (preview != null)
              Text(
                '${selectedHelmOrder.displayName}${conditional ? ' only' : ''}: ${_assessment(preview)}',
                style: InkTheme.caption,
              ),
            if (conditional && !isResolving)
              Text(
                'Action movement may change this forecast.',
                key: const ValueKey('conditional-range-forecast'),
                style: InkTheme.caption,
              ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: InkTheme.parchmentHighlight.withValues(alpha: 0.95),
        border: Border.all(color: InkTheme.inkMuted),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('LOOKOUT', style: InkTheme.statLabel),
              if (intent != null)
                Tooltip(
                  message: 'Inspect monster intent',
                  child: InkButton(
                    label: 'Inspect',
                    compact: true,
                    semanticLabel: 'Inspect monster intent',
                    onPressed: () => _inspect(context, intent, preview),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(intent?.name ?? 'Watching the beast', style: InkTheme.bodyBold),
          if (intent != null) ...[
            const SizedBox(height: 3),
            Text(
              'Threatens: ${intent.threatenedRangesLabel}',
              style: InkTheme.caption.copyWith(color: InkTheme.crimsonAccent),
            ),
            const SizedBox(height: 3),
            Text(_timing(intent), style: InkTheme.caption),
          ],
          if (isResolving) ...[
            const SizedBox(height: 5),
            Text('Orders resolving…', style: InkTheme.caption),
          ] else if (preview != null) ...[
            const SizedBox(height: 5),
            Text(
              '${selectedHelmOrder.displayName}${conditional ? ' only' : ''}: '
              '${_assessment(preview)}',
              style: InkTheme.caption.copyWith(color: InkTheme.inkPrimary),
            ),
            if (conditional)
              Text(
                'Action movement may change this forecast.',
                key: const ValueKey('conditional-range-forecast'),
                style: InkTheme.caption,
              ),
          ],
        ],
      ),
    );
  }

  void _inspect(
    BuildContext context,
    MonsterIntent intent,
    IntentPreviewOutcome? preview,
  ) {
    // A range-avoided sweep still needs its live limb/damage explanation when
    // deliberately inspected. Ask the core for the in-range attack mechanics;
    // keep it distinct from the selected helm's actual spatial forecast.
    final sweepMechanics =
        !isResolving &&
            intent.id == MonsterIntentId.squidSweepingTentacles &&
            preview?.status == IntentPreviewStatus.evadedByPosition
        ? intent.evaluatePreview(
            currentRange: CombatRange.short,
            selectedHelmOrder: HelmOrder.holdLine,
            tentacleCount: monster.numberOfTentacles,
            damagePerTentacle: monster.usableWeapons
                .where(
                  (weapon) =>
                      weapon.monsterWeaponType == MonsterWeaponType.tentacle,
                )
                .firstOrNull
                ?.damage,
          )
        : null;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: InkTheme.parchmentSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: InkTheme.inkPrimary, width: 2),
        ),
        title: Text(intent.name, style: InkTheme.titleMedium),
        scrollable: true,
        content: SizedBox(
          width: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(intent.description, style: InkTheme.body),
              const SizedBox(height: 12),
              Text(
                'Threatens: ${intent.threatenedRangesLabel}',
                style: InkTheme.bodyBold,
              ),
              Text(_timing(intent), style: InkTheme.body),
              if (preview != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${selectedHelmOrder.displayName} · helm forecast',
                  style: InkTheme.bodyBold,
                ),
                Text(
                  'After helm: ${preview.playerPostHelmRange.displayName}\n'
                  'At strike: ${preview.rangeAtStrike.displayName}\n'
                  'After response: ${preview.projectedEndOfRoundRange.displayName}',
                  style: InkTheme.body,
                ),
                const SizedBox(height: 8),
                Text(preview.summaryBadge, style: InkTheme.body),
                if (sweepMechanics != null) ...[
                  const SizedBox(height: 8),
                  Text('Sweep when in range', style: InkTheme.bodyBold),
                  Text(sweepMechanics.summaryBadge, style: InkTheme.body),
                ],
                if (preview.estimatedDamage > 0 ||
                    (sweepMechanics?.estimatedDamage ?? 0) > 0)
                  Text(
                    'Damage estimates precede applicable weakening, armor, bracing '
                    'and barriers; avoidance checks are separate.'
                    '${intent.id == MonsterIntentId.squidSweepingTentacles ? ' Sweep defenses apply to each strike.' : ''}',
                    style: InkTheme.caption,
                  ),
                if (conditional && actionNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final note in actionNotes)
                    Text(note, style: InkTheme.body),
                ],
              ] else if (isResolving) ...[
                const SizedBox(height: 12),
                Text(
                  'Orders resolving… Forecasts return after playback.',
                  style: InkTheme.body,
                ),
              ],
              const SizedBox(height: 12),
              Text('Counterplay', style: InkTheme.bodyBold),
              Text(intent.tacticalTip, style: InkTheme.body),
            ],
          ),
        ),
        actions: [
          InkButton(
            label: 'Close',
            compact: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
