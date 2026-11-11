import 'package:monstrous_core/monstrous_core.dart';

/// Added relic effects for its associated signature, independent of weapon rolls.
class EldritchRelicPreview {
  EldritchRelicPreview(ProfileData profile, this.relic) {
    isForged = profile.isEldritchRelicUnlocked(relic);
    isActive = profile.isEldritchRelicActive(relic);
    blueprintUnlocked = profile.isBlueprintUnlocked(definition.blueprintId);
    canForge = profile.canUnlockEldritchRelic(relic);
    final effects = EldritchRelicEffects.forRelic(relic);
    stats = List.unmodifiable([
      if (effects.fleshHealingFraction > 0)
        _stat(
          'healing',
          'Flesh damage restored as hull',
          '0%',
          '${(effects.fleshHealingFraction * 100).round()}%',
        ),
      if (effects.ignoresObscurity)
        _stat('obscurity', 'Ignore Obscurity', 'No', 'Yes'),
      if (effects.shockDamage > 0)
        _stat(
          'shock',
          'Base Shock per flesh hit',
          '0',
          '${effects.shockDamage}',
        ),
      if (effects.inflictedStatus != null)
        _stat(
          'status',
          '${effects.inflictedStatus!.displayName} on hit',
          'No',
          'Yes',
        ),
    ]);
  }

  final EldritchRelicId relic;
  late final bool isForged;
  late final bool isActive;
  late final bool blueprintUnlocked;
  late final bool canForge;
  late final List<RelicEffectComparison> stats;
  EldritchRelicDef get definition => EldritchRelicDef.catalog[relic]!;
  String get blueprintName => definition.blueprintId.shipClass.displayName;
  MetaCost get cost => definition.unlockCost;

  RelicEffectComparison _stat(
    String id,
    String label,
    String before,
    String after,
  ) => RelicEffectComparison(
    id: id,
    label: label,
    current: isForged ? after : before,
    next: isForged ? null : after,
  );
}

class RelicEffectComparison {
  const RelicEffectComparison({
    required this.id,
    required this.label,
    required this.current,
    required this.next,
  });
  final String id;
  final String label;
  final String current;
  final String? next;
}
