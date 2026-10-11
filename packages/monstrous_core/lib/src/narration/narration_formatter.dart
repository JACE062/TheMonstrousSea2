import '../session/events.dart';

/// Formats structured [GameEvent] instances into flavorful, dramatic text log entries.
///
/// Preserves the atmospheric, vintage prose from the original game.
class NarrationFormatter {
  const NarrationFormatter();

  /// Converts [event] into a readable log string.
  String format(GameEvent event) {
    return switch (event) {
      BattleStarted(:final monsterName, :final difficulty, :final isBoss) =>
        isBoss
            ? 'Colossal tentacles shoot out of the water, too many to count, as $monsterName itself has risen from the depths to face you!'
            : 'A $monsterName rears out of the water! (Difficulty: $difficulty)',
      AttackAttempted(:final attackerName, :final weaponName) =>
        'The $attackerName attacks with ${weaponName}s.',
      AttackHit(:final targetName, :final damage, :final damageType) =>
        'The $targetName takes $damage $damageType damage.',
      AttackMissed(:final targetName) =>
        'The attack misses The $targetName.',
      AttackEvaded(:final shipName, :final wasManeuver) => wasManeuver
          ? 'In the nick of time, The $shipName jukes hard to port, expertly dodging the strike, before settling back into its normal heading.'
          : 'The $shipName narrowly dodges the attack.',
      DamageReduced(:final shipName, :final nullifiedAmount) =>
        'The iron armor plating of $shipName nullifies $nullifiedAmount incoming damage.',
      TentaclesSevered(:final countSevered, :final remainingTentacles) =>
        'Slicing blades sever $countSevered tentacles! ($remainingTentacles remaining).',
      InkCloudDeployed(:final monsterName) =>
        'The $monsterName jets out pitch black ink into the water, obscuring itself from view.',
      StatusEffectTicked(
        :final targetName,
        :final effectName,
        :final damage,
        :final woreOff
      ) =>
        'The $targetName takes $damage $effectName damage${woreOff ? ', and the $effectName wears off.' : ' and is still affected.'}',
      CombatantDefeated(:final name, :final flavorMessage) =>
        'The $name $flavorMessage!',
      MonsterHesitated(:final monsterName) =>
        monsterName.isNotEmpty
            ? 'The $monsterName circles cautiously, weapons cooling.'
            : 'The sea beast circles warily in the waves.',
      FledToPort(:final shipName) =>
        'The $shipName high tails its way back to port, the crew reeling from a narrow scrape with fate.',
      LootDropped(:final items) =>
        'The creature sinks, leaving ${items.length} spoils floating in the waves.',
      ItemAcquired(:final item) =>
        'Stowed ${item.name} (${item.value}g) into the cargo hold.',
      ItemSold(:final item, :final goldEarned) =>
        'Sold ${item.name} to the merchant for ${goldEarned}g.',
      AllTreasureSold(:final totalGold, :final itemsSold) =>
        'Sold $itemsSold treasures at port for a total of ${totalGold}g.',
      ShipRepaired(:final repairedHp, :final goldCost, :final newHp) =>
        'Repaired $repairedHp Hull for ${goldCost}g. Hull is now at $newHp.',
      CaptainLost(:final captainName, :final monstersDefeated) =>
        'Captain $captainName has met a watery end after defeating $monstersDefeated sea monsters. The Sea has claimed another soul...',
      NarrationEvent(:final message) => message,
      PhaseChanged(:final newPhase) => 'Entering $newPhase.',
    };
  }
}
