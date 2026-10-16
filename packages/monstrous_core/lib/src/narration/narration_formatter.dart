import '../lore/chronicle_strings.dart';
import '../session/events.dart';

/// Formats structured [GameEvent] instances into flavorful, dramatic text log entries.
///
/// Preserves the atmospheric, vintage prose from the original game.
class NarrationFormatter {
  const NarrationFormatter();

  /// Converts [event] into a readable log string.
  String format(GameEvent event) {
    return switch (event) {
      BattleStarted(:final monsterName, :final difficulty, :final isBoss, :final isApex) =>
        ChronicleStrings.battleStarted(
          monsterName: monsterName,
          difficulty: difficulty,
          isBoss: isBoss,
          isApex: isApex,
        ),
      ThermalScaldOccurred(:final shipName, :final damage, :final remainingHp) =>
        ChronicleStrings.thermalScald(
          shipName: shipName,
          damage: damage,
          remainingHp: remainingHp,
        ),
      AttackAttempted(:final attackerName, :final weaponName) =>
        ChronicleStrings.attackAttempted(
          attackerName: attackerName,
          weaponName: weaponName,
        ),
      AttackHit(:final targetName, :final damage, :final damageType) =>
        ChronicleStrings.attackHit(
          targetName: targetName,
          damage: damage,
          damageType: damageType,
        ),
      AttackMissed(:final targetName) =>
        ChronicleStrings.attackMissed(targetName),
      AttackEvaded(:final shipName, :final wasManeuver) =>
        ChronicleStrings.attackEvaded(
          shipName: shipName,
          wasManeuver: wasManeuver,
        ),
      DamageReduced(:final shipName, :final nullifiedAmount) =>
        ChronicleStrings.damageReduced(
          shipName: shipName,
          nullifiedAmount: nullifiedAmount,
        ),
      TentaclesSevered(:final countSevered, :final remainingTentacles) =>
        ChronicleStrings.tentaclesSevered(
          countSevered: countSevered,
          remainingTentacles: remainingTentacles,
        ),
      InkCloudDeployed(:final monsterName) =>
        ChronicleStrings.inkCloudDeployed(monsterName),
      CarapaceAbsorbed(:final monsterName, :final absorbedAmount) =>
        ChronicleStrings.carapaceAbsorbed(
          monsterName: monsterName,
          absorbedAmount: absorbedAmount,
        ),
      CarapaceDamaged(:final monsterName, :final damageDealt, :final remainingCarapace, :final wasShattered) =>
        ChronicleStrings.carapaceDamaged(
          monsterName: monsterName,
          damageDealt: damageDealt,
          remainingCarapace: remainingCarapace,
          wasShattered: wasShattered,
        ),
      SharkFrenzyRoared(:final monsterName, :final stacks) =>
        ChronicleStrings.sharkFrenzyRoared(
          monsterName: monsterName,
          stacks: stacks,
        ),
      SharkFrenzyDisrupted(:final monsterName) =>
        ChronicleStrings.sharkFrenzyDisrupted(monsterName),
      SerpentSlithered(:final monsterName) =>
        ChronicleStrings.serpentSlithered(monsterName),
      StatusEffectTicked(
        :final targetName,
        :final effectName,
        :final damage,
        :final woreOff
      ) =>
        ChronicleStrings.statusTicked(
          targetName: targetName,
          effectName: effectName,
          damage: damage,
          woreOff: woreOff,
        ),
      CombatantDefeated(:final name, :final flavorMessage) =>
        ChronicleStrings.combatantDefeated(
          name: name,
          flavorMessage: flavorMessage,
        ),
      MonsterHesitated(:final monsterName) =>
        ChronicleStrings.monsterHesitated(monsterName),
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
      ShipUpgraded(:final ship, :final newLevel, :final goldCost) =>
        'The ${ship.name} has been refitted at Drydock to Level $newLevel for ${goldCost}g! Max Hull: ${ship.maxHp}, Gun Deck: ${ship.maxHardpointSlots} Mounts.',
      CaptainLost(:final captainName, :final monstersDefeated) =>
        'Captain $captainName has met a watery end after defeating $monstersDefeated sea monsters. The Sea has claimed another soul...',
      NarrationEvent(:final message) => message,
      PhaseChanged(:final newPhase) => 'Entering $newPhase.',
      CombatRangeChanged(:final newRange, :final reason) =>
        ChronicleStrings.tacticalRangeShift(
          rangeName: newRange.displayName,
          reason: reason,
        ),
      MortarBackfireOccurred(:final shipName, :final damage, :final remainingHp) =>
        ChronicleStrings.mortarBackfire(
          shipName: shipName,
          damage: damage,
          remainingHp: remainingHp,
        ),
      RespiteIslandReached(:final islandName, :final description) =>
        'Anchored at $islandName. $description',
      HullCareened(:final repairedHp, :final newHp) =>
        'Careened and caulked hull timbers (+$repairedHp HP). Hull vitality is now $newHp.',
      GunnersDrilled(:final bonusHitChance) =>
        'Gun crews drilled target patterns (+$bonusHitChance% accuracy on next battle).',
      IslandForaged(:final goldFound) =>
        'Foraged island shoals and gathered $goldFound gold doubloons.',
      ShipwreckDiscovered(:final shipwreckName, :final description) =>
        'Spotted $shipwreckName. $description',
      ShipwreckSalvaged(:final flavorMessage) => flavorMessage,
      RegionTransitioned(:final newRegion, :final narrative) =>
        'VOYAGE ADVANCES: Entering $newRegion! $narrative',
      ExpeditionWon(:final captainName, :final monstersDefeated, :final goldAmassed) =>
        'VICTORY! Captain $captainName conquered The Monstrous Sea ($monstersDefeated beasts vanquished, ${goldAmassed}g amassed)!',
      SmugglerEncountered(:final smugglerName, :final description) =>
        'Spotted $smugglerName anchored in the mist. $description',
      ShrineDiscovered(:final shrineName, :final loreInscription) =>
        'Beheld $shrineName rising from the deep! $loreInscription',
      ShrineCommuned(:final outcomeNarrative) => outcomeNarrative,
      HelmApproached(:final currentLeg, :final totalLegs, :final regionName) =>
        'At the Helm: Assessing courses for Leg ${currentLeg + 1} of $totalLegs in $regionName.',
      CourseSteered(:final bearing, :final leg, :final lookoutCall) =>
        'Steered ${bearing.shortName} (Leg $leg). Lookout: "$lookoutCall"',
      MetaCurrenciesAwarded(
        :final seaGlass,
        :final monsterBone,
        :final depthWroughtIron,
        :final abyssalBarnacles,
        :final krakenBeak,
        :final serpentScale,
        :final leviathanCore,
        :final primordialCinders,
        :final reason,
      ) =>
        'Harvested spoils ($reason): ${[
          if (seaGlass > 0) '$seaGlass Sea Glass',
          if (monsterBone > 0) '$monsterBone Monster Bone',
          if (depthWroughtIron > 0) '$depthWroughtIron Depth-Wrought Iron',
          if (abyssalBarnacles > 0) '$abyssalBarnacles Abyssal Barnacles',
          if (krakenBeak > 0) '$krakenBeak Kraken Beak',
          if (serpentScale > 0) '$serpentScale Serpent Scale',
          if (leviathanCore > 0) '$leviathanCore Leviathan Core',
          if (primordialCinders > 0) '$primordialCinders Primordial Cinders',
        ].join(', ')}',
      NemesisSpawned(:final nemesis) =>
        'NEMESIS RISES: ${nemesis.moniker} emerges to terrorize the bloodline once more!',
      NemesisSlain(:final nemesis) =>
        'VENGEANCE CLAIMED! Avenged predecessor ${nemesis.predecessorCaptain} by slaying ${nemesis.moniker}!',
      HeirSelected(:final heirName, :final chosenClass, :final boon, :final quirk) =>
        '$heirName takes command as ${chosenClass.name.toUpperCase()} (Boon: ${boon?.name ?? 'None'}, Quirk: ${quirk?.name ?? 'None'}).',
      BlueprintUnlocked(:final blueprintName) =>
        'BLUEPRINT UNLOCKED: Naval architects draft specifications for $blueprintName!',
      BlueprintCommissioned(:final blueprintName, :final ship) =>
        'FLAGSHIP COMMISSIONED: ${ship.name} reconfigured under $blueprintName specifications.',
      CalderaClimaxResolved(:final choice, :final narrative) =>
        'CALDERA CLIMAX (${choice.displayName.toUpperCase()}): $narrative',
      CovenantPactToggled(:final pactId, :final isActive, :final totalPactBurden) =>
        'COVENANT PACT: ${pactId.name} ${isActive ? 'ratified' : 'rescinded'} (Total Pact Burden: $totalPactBurden).',
      BlueprintArmamentUpgraded(:final blueprintId, :final newTier) =>
        'ARMAMENT UPGRADED: ${blueprintId.name.toUpperCase()} signature weapon upgraded to Tier $newTier!',
      AuxiliaryExpansionUnlocked() =>
        'DRYDOCK EXPANSION: Unlocked Reserve Auxiliary Hardpoint!',
      EldritchRelicUnlocked(:final relicName) =>
        'ELDRITCH RELIC FORGED: $relicName unlocked at the Covenant Altar!',
      HarborMonumentUpgraded(:final monumentId, :final newRank) =>
        'HARBOR MONUMENT: ${monumentId.name} consecrated to Rank $newRank!',
    };
  }
}
