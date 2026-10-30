import 'package:monstrous_core/monstrous_core.dart';

/// Shared inspection/tooltip copy derived from the actual rigging effect.
String evasiveRiggingDescription(ShipState ship) =>
    '2-turn cooldown. Sets evasion to ${ship.evasiveRiggingEvasion}% '
    '(+${ship.evasiveRiggingBonus}% above base) until the next successful dodge. '
    'Captain and blessing bonuses apply separately, up to 95% dodge. '
    'Moves one range band away unless grappled.';
