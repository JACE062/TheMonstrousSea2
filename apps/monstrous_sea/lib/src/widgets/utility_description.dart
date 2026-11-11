import 'package:monstrous_core/monstrous_core.dart';

/// Shared battle/inspection wording; the amount still comes from the fitting.
String ironPlatesDescription(ShipState ship) {
  return '2-turn cooldown. Adds +${ship.fortifyDamageReductionGain} damage reduction '
      'for this battle. Anchors the ship this round.';
}

/// Shared inspection/tooltip copy derived from the actual rigging effect.
String evasiveRiggingDescription(ShipState ship) =>
    '2-turn cooldown. Adds +${ship.evasiveRiggingBonus}% evasion until the next successful dodge. '
    'Moves one range band away.';

String spotterFlareDescription({
  double multiplier = 1,
  bool detailed = false,
}) =>
    '2-turn cooldown. Illuminates the beast for 2 turns.'
    '${detailed ? ' Clears enemy Obscurity, suppresses dodge, grants +${(15 * multiplier).round()}% accuracy and increases Blast damage taken by ${(25 * multiplier).round()}%.' : ''}';

/// Shared action copy; inspection and combat use the same displayed fitting.
String utilityDescription(ShipState ship) {
  return switch (ship.resolvedBlueprintId) {
    BlueprintId.ironclad => ironPlatesDescription(ship),
    BlueprintId.clipper => evasiveRiggingDescription(ship),
    BlueprintId.corsair =>
      '2-turn cooldown. Launches a trap one band ahead. It drifts toward the beast and detonates for ${ship.tetherTrapDamage} Slicing damage, applying Pinned for 1 turn.',
    BlueprintId.bombardier => spotterFlareDescription(),
    BlueprintId.standard =>
      '2-turn cooldown. Reduces incoming damage by 20% this round. Your next volley gains +15% accuracy and +${(ship.bracedVolleyDamageBonus * 100).round()}% damage.',
  };
}
