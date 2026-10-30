/// Centralized chronicle strings and narrative prose for in-game event logs.
///
/// Modifying this file customizes the narrator's voice, captain logs, and battle shouts.
class ChronicleStrings {
  const ChronicleStrings._();

  static String battleStarted({
    required String monsterName,
    required int difficulty,
    required bool isBoss,
    required bool isApex,
  }) {
    if (isBoss) {
      return 'Colossal tentacles shoot out of the water, too many to count, as $monsterName itself has risen from the depths to face you!';
    }
    if (isApex) {
      return 'APEX PREDATOR SURFACES: An elite $monsterName rears fiercely from the deep! (Danger: $difficulty)';
    }
    return 'A $monsterName rears out of the water! (Difficulty: $difficulty)';
  }

  static String thermalScald({
    required String shipName,
    required int damage,
    required int remainingHp,
  }) =>
      'The boiling caldera erupts! Scalding brine washes over $shipName dealing $damage thermal damage ($remainingHp HP remaining)!';

  static String attackAttempted({
    required String attackerName,
    required String weaponName,
  }) =>
      'The $attackerName attacks with ${weaponName}s.';

  static String attackHit({
    required String targetName,
    required int damage,
    required String damageType,
  }) =>
      'The $targetName takes $damage $damageType damage.';

  static String attackMissed(String targetName) =>
      'The attack misses The $targetName.';

  static String attackEvaded({
    required String shipName,
    required bool wasManeuver,
  }) =>
      wasManeuver
          ? 'In the nick of time, The $shipName jukes hard to port, expertly dodging the strike, before settling back into its normal heading.'
          : 'The $shipName narrowly dodges the attack.';

  static String damageReduced({
    required String shipName,
    required int nullifiedAmount,
  }) =>
      'The iron armor plating of $shipName nullifies $nullifiedAmount incoming damage.';

  static String tentaclesSevered({
    required int countSevered,
    required int remainingTentacles,
  }) =>
      'Slicing blades sever $countSevered tentacles! ($remainingTentacles remaining).';

  static String inkCloudDeployed(String monsterName, int accuracyPenalty) =>
      '$monsterName spewed a dense ink cloud! Shot accuracy reduced by $accuracyPenalty%. Hit the monster repeatedly to disperse!';

  static String carapaceAbsorbed({
    required String monsterName,
    required int absorbedAmount,
  }) =>
      'The thick carapace of $monsterName absorbs $absorbedAmount damage!';

  static String carapaceDamaged({
    required String monsterName,
    required int damageDealt,
    required int remainingCarapace,
    required bool wasShattered,
  }) =>
      wasShattered
          ? 'A massive hit shatters the carapace of $monsterName! The beast is exposed!'
          : 'The strike breaks away $damageDealt carapace plating from $monsterName ($remainingCarapace remaining).';

  static String sharkFrenzyRoared({
    required String monsterName,
    required int stacks,
  }) =>
      'The $monsterName lets out a terrifying roar, boosting its angered frenzy! (Frenzy x$stacks)';

  static String sharkFrenzyDisrupted(String monsterName) =>
      'The electrical shock rattles $monsterName, completely disrupting its frenzy!';

  static String serpentSlithered(String monsterName) =>
      'The $monsterName undulates through the water in evasive coils, preparing to dodge incoming fire!';

  static String statusTicked({
    required String targetName,
    required String effectName,
    required int damage,
    required bool woreOff,
  }) =>
      'The $targetName takes $damage $effectName damage${woreOff ? ', and the $effectName wears off.' : ' and is still affected.'}';

  static String combatantDefeated({
    required String name,
    required String flavorMessage,
  }) =>
      'The $name $flavorMessage!';

  static String monsterHesitated(String monsterName) => monsterName.isNotEmpty
      ? 'The $monsterName circles cautiously, hesitating in its attacks.'
      : 'The sea beast circles warily in the waves.';

  static String tacticalRangeShift({
    required String rangeName,
    required String reason,
  }) =>
      'TACTICAL RANGE: Bearing shifted to $rangeName. $reason';

  static String mortarBackfire({
    required String shipName,
    required int damage,
    required int remainingHp,
  }) =>
      'POINT-BLANK BACKFIRE! Mortar blast splashes The $shipName for $damage damage! ($remainingHp HP remaining).';

  static String monsterIntentTelegraphed({
    required String monsterName,
    required String intentName,
    required String telegraphLog,
  }) {
    final subject = monsterName.startsWith('The ')
        ? monsterName
        : 'The $monsterName';
    return 'BEAST INTENT [$intentName]: $subject $telegraphLog';
  }

  static String monsterAttackOutOfRange({
    required String monsterName,
    required String intentName,
    required String shipName,
    required String currentRangeName,
  }) =>
      'STRIKE EVADED! The $monsterName unleashes $intentName, but The $shipName maneuvers safely out of reach at $currentRangeName!';

  static String headOnCollision({
    required String monsterName,
    required String shipName,
    required String intentName,
  }) =>
      'HEAD-ON COLLISION! The $shipName steered straight into The $monsterName\'s $intentName (+30% Momentum Impact)!';

  static String monsterIntentDisrupted({
    required String monsterName,
    required String intentName,
    required String reason,
  }) =>
      'INTENT DISRUPTED! $reason — The $monsterName\'s $intentName is shattered!';

  static String shipGrappled({
    required String monsterName,
    required String shipName,
  }) =>
      'GRAPPLED! The $monsterName latches onto The $shipName\'s hull, locking the ship in place for the next round!';
}
