import '../model/bloodline_trait.dart';
import '../model/covenant_of_the_deep.dart';
import '../model/enums.dart';
import '../model/flagship_blueprint.dart';
import '../model/ocean_power.dart';

/// Base sealed class for all user or bot intents sent into the game engine.
sealed class Command {
  const Command();
}

/// Acknowledges the ending prose without applying its consequences again.
final class AcknowledgeCalderaOutcome extends Command {
  const AcknowledgeCalderaOutcome();
}

/// Sets the initial captain name or heir name.
final class NameCaptain extends Command {
  const NameCaptain(this.name);
  final String name;
}

/// Chooses a starting ship by class.
final class ChooseShip extends Command {
  const ChooseShip(this.shipClass, {this.customName});
  final ShipClass shipClass;
  final String? customName;
}

/// Names the first captain, commissions the Standard flagship, and sails at once.
final class BeginFirstVoyage extends Command {
  const BeginFirstVoyage(this.captainName, {this.customShipName});
  final String captainName;
  final String? customShipName;
}

/// Fires all weapons of the specified type in a coordinated volley.
final class FireWeaponVolley extends Command {
  const FireWeaponVolley(this.weaponType);
  final ShipWeaponType weaponType;
}

/// Issues a tactical helm order (Advance, Hold Line, Fall Back) to reposition the vessel.
final class IssueHelmOrder extends Command {
  const IssueHelmOrder(this.order);
  final HelmOrder order;
}

/// Changes the vessel's combat range band directly.
final class ChangeCombatRange extends Command {
  const ChangeCombatRange(this.targetRange);
  final CombatRange targetRange;
}

/// Uses a consumable item from cargo by index.
final class UseConsumableItem extends Command {
  const UseConsumableItem(this.cargoIndex);
  final int cargoIndex;
}

/// Executes the ship's active class action (Fortify, Evasive Maneuvers).
final class ExecuteShipSpecialAction extends Command {
  const ExecuteShipSpecialAction({this.borrowNextAction = false});
  final bool borrowNextAction;
}

/// Braces the crew behind the gunwales and passes the attack phase, allowing helm maneuvers to resolve and weapons to reload.
final class BraceForImpact extends Command {
  const BraceForImpact();
}

/// Takes a single loot item by index from pending victory loot.
final class TakeLootItem extends Command {
  const TakeLootItem(this.lootIndex);
  final int lootIndex;
}

/// Takes all pending victory loot items that fit into cargo.
final class TakeAllLoot extends Command {
  const TakeAllLoot();
}

/// Leaves all remaining pending victory loot behind.
final class LeaveRemainingLoot extends Command {
  const LeaveRemainingLoot();
}

/// Jettisons an item from cargo to make room.
final class DropCargoItem extends Command {
  const DropCargoItem(this.cargoIndex);
  final int cargoIndex;
}

/// Equips a weapon from cargo.
final class EquipCargoWeapon extends Command {
  const EquipCargoWeapon(this.cargoIndex);
  final int cargoIndex;
}

/// Unequips an equipped weapon back into cargo hold.
final class UnequipShipWeapon extends Command {
  const UnequipShipWeapon(this.equippedIndex);
  final int equippedIndex;
}

/// Advances from rest area or port into the next battle.
final class AdvanceToNextBattle extends Command {
  const AdvanceToNextBattle();
}

/// Leaves port to venture out onto the open sea, optionally departing at [startingRow].
final class VentureOutToSea extends Command {
  const VentureOutToSea({this.startingRow = 0});
  final int startingRow;
}

/// Enters the merchant shop in port.
final class VisitMerchant extends Command {
  const VisitMerchant();
}

/// Leaves the merchant shop back to port hub.
final class LeaveMerchant extends Command {
  const LeaveMerchant();
}

/// Purchases an item from the merchant by index in merchant stock.
final class BuyMerchantItem extends Command {
  const BuyMerchantItem(this.stockIndex);
  final int stockIndex;
}

/// Sells a cargo item to the merchant by index in cargo hold.
final class SellCargoItem extends Command {
  const SellCargoItem(this.cargoIndex);
  final int cargoIndex;
}

/// Sells all treasure in cargo for gold.
final class SellAllTreasure extends Command {
  const SellAllTreasure();
}

/// Repairs hull at port.
final class RepairShip extends Command {
  const RepairShip(this.percentage);
  final double percentage;
}

/// Refits the player's vessel level at a voyage's midpoint Haven shipwright.
final class UpgradeShip extends Command {
  const UpgradeShip();
}

/// Tempers a specific ship hardpoint (Broadside, Signature, or Utility) to the next Mark (Mk I -> Mk II -> Mk III).
final class TemperHardpoint extends Command {
  const TemperHardpoint(this.slot);
  final HardpointType slot;
}

/// Returns to home port from the rest area.
final class ReturnToPort extends Command {
  const ReturnToPort();
}

/// Continues the hunt after death with an heir and chosen traits.
final class ContinueLineage extends Command {
  const ContinueLineage(
    this.heirName,
    this.chosenClass, {
    this.boon,
    this.quirk,
  });
  final String heirName;
  final ShipClass chosenClass;
  final BloodlineTrait? boon;
  final BloodlineTrait? quirk;
}

/// Ends the hunt lineage completely.
final class AbandonHunt extends Command {
  const AbandonHunt();
}

/// Careens and patches ship hull at a Respite Island.
final class CareenHullAtIsland extends Command {
  const CareenHullAtIsland();
}

/// Drills gunners at a Respite Island to gain an accuracy combat boon.
final class DrillGunnersAtIsland extends Command {
  const DrillGunnersAtIsland();
}

/// Forages lagoon shoals and beachcombs for emergency supplies and gold.
final class ForageShoalsAtIsland extends Command {
  const ForageShoalsAtIsland();
}

/// Departs a Respite Island to continue the naval expedition.
final class DepartIsland extends Command {
  const DepartIsland();
}

/// Salvages resources from a floating Shipwreck derelict.
final class SalvageShipwreck extends Command {
  const SalvageShipwreck(this.choice);
  final ShipwreckChoice choice;
}

/// Claims victory following the defeat of the final titan.
final class ClaimExpeditionVictory extends Command {
  const ClaimExpeditionVictory();
}

/// Communes at an Ancient Sea Shrine with a chosen devotion.
final class CommuneWithShrine extends Command {
  const CommuneWithShrine(this.choice);
  final ShrineChoice choice;
}

/// Dedicates an open hardpoint or upgrades its existing Primordial blessing.
final class AcceptShrineBlessing extends Command {
  const AcceptShrineBlessing(this.power, this.slot);
  final OceanPower power;
  final HardpointType slot;
}

/// Departs an Ancient Sea Shrine to resume sailing.
final class DepartShrine extends Command {
  const DepartShrine();
}

/// Departs the Smuggler's Ketch to resume sailing.
final class DepartSmuggler extends Command {
  const DepartSmuggler();
}

/// Steers the ship along a chosen navigational compass bearing.
final class SteerCourse extends Command {
  const SteerCourse(this.bearing);
  final NavigationalBearing bearing;
}

/// Storm-Seer: redraw ordinary courses once per region without advancing a leg.
final class RedrawStormSeerCourses extends Command {
  const RedrawStormSeerCourses();
}

/// Takes the ship's helm to evaluate the lookout's observations and set course.
final class TakeHelm extends Command {
  const TakeHelm();
}

/// Unlocks an ancestral flagship blueprint using persistent meta-currencies.
final class UnlockBlueprint extends Command {
  const UnlockBlueprint(this.blueprintId);
  final BlueprintId blueprintId;
}

/// Commissions an unlocked flagship blueprint at the drydock to reconfigure the player's vessel.
final class CommissionBlueprint extends Command {
  const CommissionBlueprint(this.blueprintId);
  final BlueprintId blueprintId;
}

/// Resolves the final dilemma at the Primordial Caldera (Shatter vs. Claim the Core).
final class ResolveCalderaClimax extends Command {
  const ResolveCalderaClimax(this.choice);
  final CalderaClimaxChoice choice;
}

/// Toggles a Covenant Pact at the Abyssal Covenant Altar in Port.
final class ToggleCovenantPact extends Command {
  const ToggleCovenantPact(this.pactId);
  final CovenantPactId pactId;
}

/// Upgrades a blueprint's signature armament tier using Titan Trophies & materials.
final class UpgradeBlueprintArmament extends Command {
  const UpgradeBlueprintArmament(this.blueprintId);
  final BlueprintId blueprintId;
}

/// Unlocks the extra Reserve Auxiliary Hardpoint slot using Titan Trophies.
final class UnlockAuxiliaryExpansion extends Command {
  const UnlockAuxiliaryExpansion();
}

/// Unlocks a post-loop Eldritch Relic Weapon using Titan Trophies & Primordial Cinders.
final class UnlockEldritchRelic extends Command {
  const UnlockEldritchRelic(this.relicId);
  final EldritchRelicId relicId;
}

/// Upgrades a Cursed Harbor Monument rank using surplus Titan Trophies & Primordial Cinders.
final class UpgradeHarborMonument extends Command {
  const UpgradeHarborMonument(this.monumentId);
  final HarborMonumentId monumentId;
}

/// Claims one chosen free consumable from this encounter.
final class ClaimSmugglerGift extends Command {
  const ClaimSmugglerGift(this.stockIndex);
  final int stockIndex;
}
