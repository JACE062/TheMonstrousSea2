import '../model/bloodline_trait.dart';
import '../model/combatant.dart';
import '../model/covenant_of_the_deep.dart';
import '../model/enums.dart';
import '../model/flagship_blueprint.dart';
import '../model/item.dart';
import '../model/meta_inventory.dart';
import '../model/monster_intent.dart';
import '../model/nemesis.dart';
import '../rules/sea_chart.dart';

/// Base sealed class for all events emitted by the game engine.
///
/// The UI, audio layer, and combat logger react to these events
/// without needing to inspect low-level game calculations.
sealed class GameEvent {
  const GameEvent();
}

/// The session transitioned to a new game phase.
final class PhaseChanged extends GameEvent {
  const PhaseChanged({required this.previousPhase, required this.newPhase});
  final String previousPhase;
  final String newPhase;
}

/// A battle encounter has begun.
final class BattleStarted extends GameEvent {
  const BattleStarted({
    required this.monsterName,
    required this.difficulty,
    required this.isBoss,
    required this.monsterHp,
    required this.monsterAc,
    this.isApex = false,
    this.apexTitle,
  });

  final String monsterName;
  final int difficulty;
  final bool isBoss;
  final int monsterHp;
  final int monsterAc;
  final bool isApex;
  final String? apexTitle;
}

/// The vessel took thermal scald damage from the boiling caldera sea.
final class ThermalScaldOccurred extends GameEvent {
  const ThermalScaldOccurred({
    required this.shipName,
    required this.damage,
    required this.remainingHp,
  });

  final String shipName;
  final int damage;
  final int remainingHp;
}

/// An attack was attempted.
final class AttackAttempted extends GameEvent {
  const AttackAttempted({
    required this.attackerName,
    required this.weaponName,
    required this.roll,
    required this.targetAc,
  });

  final String attackerName;
  final String weaponName;
  final int roll;
  final int targetAc;
}

/// An attack hit and dealt damage.
final class AttackHit extends GameEvent {
  const AttackHit({
    required this.targetName,
    required this.damage,
    required this.damageType,
    required this.remainingHp,
  });

  final String targetName;
  final int damage;
  final String damageType;
  final int remainingHp;
}

/// An attack missed.
final class AttackMissed extends GameEvent {
  const AttackMissed({required this.targetName});
  final String targetName;
}

/// An attack was evaded (Corvette trait).
final class AttackEvaded extends GameEvent {
  const AttackEvaded({required this.shipName, required this.wasManeuver});
  final String shipName;
  final bool wasManeuver;
}

/// Damage was reduced (Ironclad armor trait).
final class DamageReduced extends GameEvent {
  const DamageReduced({required this.shipName, required this.nullifiedAmount});
  final String shipName;
  final int nullifiedAmount;
}

/// The tactical engagement distance between ship and beast shifted.
final class CombatRangeChanged extends GameEvent {
  const CombatRangeChanged({
    required this.previousRange,
    required this.newRange,
    required this.reason,
  });

  final CombatRange previousRange;
  final CombatRange newRange;
  final String reason;
}

/// A siege mortar weapon suffered a point-blank backfire into the ship's own hull.
final class MortarBackfireOccurred extends GameEvent {
  const MortarBackfireOccurred({
    required this.shipName,
    required this.damage,
    required this.remainingHp,
  });

  final String shipName;
  final int damage;
  final int remainingHp;
}


/// Tentacles were severed from a Squid.
final class TentaclesSevered extends GameEvent {
  const TentaclesSevered({required this.countSevered, required this.remainingTentacles});
  final int countSevered;
  final int remainingTentacles;
}

/// An Ink cloud was deployed obscuring the monster.
final class InkCloudDeployed extends GameEvent {
  const InkCloudDeployed({required this.monsterName, required this.acBonus});
  final String monsterName;
  final int acBonus;
}

/// Crustacean carapace absorbed incoming damage.
final class CarapaceAbsorbed extends GameEvent {
  const CarapaceAbsorbed({
    required this.monsterName,
    required this.absorbedAmount,
    required this.penetratingDamage,
  });

  final String monsterName;
  final int absorbedAmount;
  final int penetratingDamage;
}

/// Crustacean carapace was damaged or shattered by blast attacks.
final class CarapaceDamaged extends GameEvent {
  const CarapaceDamaged({
    required this.monsterName,
    required this.damageDealt,
    required this.remainingCarapace,
    required this.wasShattered,
  });

  final String monsterName;
  final int damageDealt;
  final int remainingCarapace;
  final bool wasShattered;
}

/// Shark roared, ramping up frenzy attack bonus.
final class SharkFrenzyRoared extends GameEvent {
  const SharkFrenzyRoared({
    required this.monsterName,
    required this.stacks,
  });

  final String monsterName;
  final int stacks;
}

/// Shark frenzy was disrupted by shock or stun.
final class SharkFrenzyDisrupted extends GameEvent {
  const SharkFrenzyDisrupted({
    required this.monsterName,
    required this.reason,
  });

  final String monsterName;
  final String reason;
}

/// Serpent coiled and slithered, boosting evasion.
final class SerpentSlithered extends GameEvent {
  const SerpentSlithered({
    required this.monsterName,
    required this.evasionBonus,
  });

  final String monsterName;
  final int evasionBonus;
}

/// A status effect ticked (e.g. Burn, Poison).
final class StatusEffectTicked extends GameEvent {
  const StatusEffectTicked({
    required this.targetName,
    required this.effectName,
    required this.damage,
    required this.woreOff,
  });

  final String targetName;
  final String effectName;
  final int damage;
  final bool woreOff;
}

/// A combatant was defeated.
final class CombatantDefeated extends GameEvent {
  const CombatantDefeated({required this.name, required this.flavorMessage});
  final String name;
  final String flavorMessage;
}

/// A monster hesitated or had no available weapons on its turn.
final class MonsterHesitated extends GameEvent {
  const MonsterHesitated([this.monsterName = '']);
  final String monsterName;
}

/// Victory loot dropped following monster defeat.
final class LootDropped extends GameEvent {
  const LootDropped({required this.items, this.goldSalvaged = 0});
  final List<Item> items;
  final int goldSalvaged;
}

/// Item picked up into cargo.
final class ItemAcquired extends GameEvent {
  const ItemAcquired({required this.item});
  final Item item;
}

/// Item sold to merchant.
final class ItemSold extends GameEvent {
  const ItemSold({required this.item, required this.goldEarned});
  final Item item;
  final int goldEarned;
}

/// All treasure sold at port.
final class AllTreasureSold extends GameEvent {
  const AllTreasureSold({required this.totalGold, required this.itemsSold});
  final int totalGold;
  final int itemsSold;
}

/// Ship hull was repaired at port.
final class ShipRepaired extends GameEvent {
  const ShipRepaired({required this.repairedHp, required this.goldCost, required this.newHp});
  final int repairedHp;
  final int goldCost;
  final int newHp;
}

/// Ship vessel refitted and upgraded to the next tier at port drydock.
final class ShipUpgraded extends GameEvent {
  const ShipUpgraded({
    required this.ship,
    required this.newLevel,
    required this.goldCost,
  });
  final ShipState ship;
  final int newLevel;
  final int goldCost;
}

/// Captain died, ending the voyage.
final class CaptainLost extends GameEvent {
  const CaptainLost({
    required this.captainName,
    required this.monstersDefeated,
    required this.highestDifficulty,
  });

  final String captainName;
  final int monstersDefeated;
  final int highestDifficulty;
}

/// A general narration or flavor message.
final class NarrationEvent extends GameEvent {
  const NarrationEvent(this.message);
  final String message;
}

/// Arrived at a safe Respite Island haven.
final class RespiteIslandReached extends GameEvent {
  const RespiteIslandReached({
    required this.islandName,
    required this.description,
  });
  final String islandName;
  final String description;
}

/// Hull careened and caulked at island haven.
final class HullCareened extends GameEvent {
  const HullCareened({required this.repairedHp, required this.newHp});
  final int repairedHp;
  final int newHp;
}

/// Gunners drilled, granting accuracy boon.
final class GunnersDrilled extends GameEvent {
  const GunnersDrilled({required this.bonusHitChance});
  final int bonusHitChance;
}

/// Foraged island shoals and gathered doubloons.
final class IslandForaged extends GameEvent {
  const IslandForaged({required this.goldFound});
  final int goldFound;
}

/// Discovered a floating shipwreck derelict.
final class ShipwreckDiscovered extends GameEvent {
  const ShipwreckDiscovered({
    required this.shipwreckName,
    required this.description,
  });
  final String shipwreckName;
  final String description;
}

/// Shipwreck was salvaged.
final class ShipwreckSalvaged extends GameEvent {
  const ShipwreckSalvaged({
    required this.flavorMessage,
    required this.choice,
  });
  final String flavorMessage;
  final ShipwreckChoice choice;
}

/// Cleared the passage to the next region.
final class RegionTransitioned extends GameEvent {
  const RegionTransitioned({
    required this.previousRegion,
    required this.newRegion,
    required this.narrative,
  });
  final String previousRegion;
  final String newRegion;
  final String narrative;
}

/// The expedition has vanquished the ancient leviathan and achieved grand victory!
final class ExpeditionWon extends GameEvent {
  const ExpeditionWon({
    required this.captainName,
    required this.shipName,
    required this.monstersDefeated,
    required this.goldAmassed,
  });
  final String captainName;
  final String shipName;
  final int monstersDefeated;
  final int goldAmassed;
}

/// Discovered a wandering smuggler ketch anchored in the fog.
final class SmugglerEncountered extends GameEvent {
  const SmugglerEncountered({
    required this.smugglerName,
    required this.description,
  });
  final String smugglerName;
  final String description;
}

/// Discovered an ancient sea shrine rising from the depths.
final class ShrineDiscovered extends GameEvent {
  const ShrineDiscovered({
    required this.shrineName,
    required this.loreInscription,
  });
  final String shrineName;
  final String loreInscription;
}

/// Communed at an ancient sea shrine.
final class ShrineCommuned extends GameEvent {
  const ShrineCommuned({
    required this.shrineName,
    required this.choice,
    required this.outcomeNarrative,
  });
  final String shrineName;
  final ShrineChoice choice;
  final String outcomeNarrative;
}

/// The captain took the helm to evaluate navigational courses.
final class HelmApproached extends GameEvent {
  const HelmApproached({
    required this.currentLeg,
    required this.totalLegs,
    required this.regionName,
    required this.availableCourses,
  });

  final int currentLeg;
  final int totalLegs;
  final String regionName;
  final List<CourseOption> availableCourses;
}

/// A navigational course was selected and steered.
final class CourseSteered extends GameEvent {
  const CourseSteered({
    required this.bearing,
    required this.nodeType,
    required this.leg,
    required this.lookoutCall,
  });

  final NavigationalBearing bearing;
  final EncounterNodeType nodeType;
  final int leg;
  final String lookoutCall;
}

/// Persistent meta-currencies were harvested and awarded to the player's profile.
final class MetaCurrenciesAwarded extends GameEvent {
  const MetaCurrenciesAwarded({
    this.seaGlass = 0,
    this.monsterBone = 0,
    this.depthWroughtIron = 0,
    this.abyssalBarnacles = 0,
    this.krakenBeak = 0,
    this.serpentScale = 0,
    this.leviathanCore = 0,
    this.primordialCinders = 0,
    required this.reason,
  });

  final int seaGlass;
  final int monsterBone;
  final int depthWroughtIron;
  final int abyssalBarnacles;
  final int krakenBeak;
  final int serpentScale;
  final int leviathanCore;
  final int primordialCinders;
  final String reason;
}

/// The family bloodline's Nemesis was encountered upon a navigational heading.
final class NemesisSpawned extends GameEvent {
  const NemesisSpawned({required this.nemesis});
  final NemesisRecord nemesis;
}

/// The family bloodline's Nemesis was slain, avenging the predecessor and claiming epic bounty.
final class NemesisSlain extends GameEvent {
  const NemesisSlain({required this.nemesis});
  final NemesisRecord nemesis;
}

/// An heir has been chosen along with their bloodline boons and quirks.
final class HeirSelected extends GameEvent {
  const HeirSelected({
    required this.heirName,
    required this.chosenClass,
    this.boon,
    this.quirk,
  });

  final String heirName;
  final ShipClass chosenClass;
  final BloodlineTrait? boon;
  final BloodlineTrait? quirk;
}

/// An ancestral flagship blueprint was unlocked with meta-currencies.
final class BlueprintUnlocked extends GameEvent {
  const BlueprintUnlocked({
    required this.blueprintId,
    required this.blueprintName,
    required this.remainingCurrencies,
  });

  final BlueprintId blueprintId;
  final String blueprintName;
  final MetaInventory remainingCurrencies;
}

/// An ancestral flagship blueprint was commissioned at drydock.
final class BlueprintCommissioned extends GameEvent {
  const BlueprintCommissioned({
    required this.blueprintId,
    required this.blueprintName,
    required this.ship,
  });

  final BlueprintId blueprintId;
  final String blueprintName;
  final ShipState ship;
}

/// The captain resolved the Primordial Caldera dilemma (Shatter vs. Claim the Core).
final class CalderaClimaxResolved extends GameEvent {
  const CalderaClimaxResolved({
    required this.choice,
    required this.captainName,
    required this.narrative,
  });

  final CalderaClimaxChoice choice;
  final String captainName;
  final String narrative;
}

/// A Covenant Pact was toggled at the Abyssal Covenant Altar in Port.
final class CovenantPactToggled extends GameEvent {
  const CovenantPactToggled({
    required this.pactId,
    required this.isActive,
    required this.totalPactBurden,
  });

  final CovenantPactId pactId;
  final bool isActive;
  final int totalPactBurden;
}

/// A blueprint's signature armament was upgraded to a higher tier using Titan Trophies.
final class BlueprintArmamentUpgraded extends GameEvent {
  const BlueprintArmamentUpgraded({
    required this.blueprintId,
    required this.newTier,
  });

  final BlueprintId blueprintId;
  final int newTier;
}

/// The flagship's deck was reinforced with an extra Reserve Auxiliary Hardpoint.
final class AuxiliaryExpansionUnlocked extends GameEvent {
  const AuxiliaryExpansionUnlocked();
}

/// A post-loop Eldritch Relic Weapon was unlocked at the Covenant Altar.
final class EldritchRelicUnlocked extends GameEvent {
  const EldritchRelicUnlocked({
    required this.relicId,
    required this.relicName,
  });

  final EldritchRelicId relicId;
  final String relicName;
}

/// A Cursed Harbor Monument was upgraded to a higher rank.
final class HarborMonumentUpgraded extends GameEvent {
  const HarborMonumentUpgraded({
    required this.monumentId,
    required this.newRank,
  });

  final HarborMonumentId monumentId;
  final int newRank;
}

/// The sea monster telegraphed its intended action for the current combat round.
final class MonsterIntentTelegraphed extends GameEvent {
  const MonsterIntentTelegraphed({
    required this.monsterName,
    required this.intent,
  });

  final String monsterName;
  final MonsterIntent intent;
}

/// The monster's telegraphed attack missed completely because the ship maneuvered outside its threatened range bands.
final class MonsterAttackOutOfRange extends GameEvent {
  const MonsterAttackOutOfRange({
    required this.monsterName,
    required this.intentName,
    required this.shipName,
    required this.currentRange,
  });

  final String monsterName;
  final String intentName;
  final String shipName;
  final CombatRange currentRange;
}

/// The flagship advanced directly into a charging monster at Short Range, triggering +30% collision impact.
final class HeadOnCollisionOccurred extends GameEvent {
  const HeadOnCollisionOccurred({
    required this.monsterName,
    required this.shipName,
    required this.intentName,
    this.bonusDamagePercent = 30,
  });

  final String monsterName;
  final String shipName;
  final String intentName;
  final int bonusDamagePercent;
}

/// A monster's wind-up or movement intent was disrupted by poise break, Harpoon tether, Concussive Mortar, or Stun.
final class MonsterIntentDisrupted extends GameEvent {
  const MonsterIntentDisrupted({
    required this.monsterName,
    required this.intentName,
    required this.reason,
  });

  final String monsterName;
  final String intentName;
  final String reason;
}

/// The ship was grappled by a Squid/Kraken beak at Short Range, locking its Helm Order to Hold Line for 1 round.
final class ShipGrappled extends GameEvent {
  const ShipGrappled({
    required this.monsterName,
    required this.shipName,
  });

  final String monsterName;
  final String shipName;
}
