import 'package:monstrous_core/monstrous_core.dart';
import 'bot_strategy.dart';
import 'shrine_strategy.dart';

/// Aggressive bot prioritizing maximum raw damage output and rapid battle advancement.
/// Never retreats or flees from naval combat.
class RecklessBot implements BotStrategy {
  const RecklessBot();

  @override
  String get name => 'Reckless';

  @override
  Command decideNextAction(GameSession session) {
    final captainAction = captainTraitAction(session);
    if (captainAction != null) return captainAction;
    switch (session.phase) {
      case SessionPhase.captainCreation:
        if (session.captainName.isEmpty) {
          return const NameCaptain('Captain Reckless');
        }
        return ChooseShip(session.profile.isBlueprintUnlocked(BlueprintId.ironclad)
            ? BlueprintId.ironclad.shipClass : ShipClass.standard);

      case SessionPhase.port:
      case SessionPhase.stronghold:
        final ship = session.ship;
        if (ship != null && ship.currentHp < ship.maxHp) {
          if (ship.gold >= session.repairCostFor(1.0)) {
            return const RepairShip(1.0);
          } else if (ship.gold >= session.repairCostFor(0.5)) {
            return const RepairShip(0.5);
          }
        }
        if (session.phase == SessionPhase.stronghold && ship != null && ship.level < 4) {
          final cost = calculateShipUpgradeCost(ship.level);
          if (cost > 0 && ship.gold >= cost) {
            return const UpgradeShip();
          }
        }
        if (ship != null) {
          for (var i = 0; i < ship.cargo.length; i++) {
            final item = ship.cargo[i];
            if (item is ShipWeapon && ship.canEquipWeapon(item)) {
              return EquipCargoWeapon(i);
            }
          }
        }
        return session.phase == SessionPhase.stronghold
            ? const TakeHelm() : const VentureOutToSea();

      case SessionPhase.battle:
        final ship = session.ship!;
        final consumableIndex = ship.cargo.indexWhere((item) => item is Consumable && !item.isDepleted);
        if (!session.usedQuickConsumableThisTurn && consumableIndex >= 0) {
          return UseConsumableItem(consumableIndex);
        }

        final readyWeapons = ship.equippedWeapons
            .where((w) => w.isReady && isWeaponTypeUsableAtRange(w.weaponType, session.combatRange))
            .toList();

        if (readyWeapons.isNotEmpty) {
          readyWeapons.sort((a, b) => b.damage.compareTo(a.damage));
          return FireWeaponVolley(readyWeapons.first.weaponType);
        }

        final outOfRangeReadyWeapons = ship.equippedWeapons.where((w) => w.isReady).toList();
        if (!ship.isGrappled &&
            session.lastHelmOrderThisTurn == HelmOrder.holdLine &&
            outOfRangeReadyWeapons.isNotEmpty &&
            session.combatRange != CombatRange.short) {
          return ChangeCombatRange(session.combatRange.closer);
        }

        if (ship.isUtilityReady) {
          return const ExecuteShipSpecialAction();
        }

        return const BraceForImpact();

      case SessionPhase.loot:
        if (session.pendingLoot.isNotEmpty) {
          final ship = session.ship;
          if (ship != null && ship.cargo.length < ship.maxCargo) {
            return const TakeAllLoot();
          }
          return const LeaveRemainingLoot();
        }
        return const LeaveRemainingLoot();

      case SessionPhase.restArea:
        final isBossDefeated = ((session.seaChart.currentRow == SeaChart.bossRow &&
                    session.seaChart.currentCol == SeaChart.bossCol) ||
                session.seaChart.currentLeg >= session.seaChart.totalLegs) &&
            session.currentMonster != null &&
            !session.currentMonster!.isAlive;
        if (isBossDefeated) {
          return const AdvanceToNextBattle();
        }

        final ship = session.ship;
        if (ship != null) {
          for (var i = 0; i < ship.cargo.length; i++) {
            final item = ship.cargo[i];
            if (item is ShipWeapon && ship.canEquipWeapon(item)) {
              return EquipCargoWeapon(i);
            }
          }
        }
        return const TakeHelm();

      case SessionPhase.respiteIsland:
        if (!session.hasChosenIslandDuty) {
          return const DrillGunnersAtIsland();
        }
        return const DepartIsland();

      case SessionPhase.shipwreck:
        if (!session.hasSalvagedCurrentWreck) {
          return const SalvageShipwreck(ShipwreckChoice.munitions);
        }
        if (session.pendingLoot.isNotEmpty) return const LeaveRemainingLoot();
        return const TakeHelm();

      case SessionPhase.smuggler:
        return const DepartSmuggler();

      case SessionPhase.shrine:
        return chooseShrineBlessing(session, preferredPowers: const [OceanPower.magmaVentLord, OceanPower.earthshakerTitan], preferredSlots: const [HardpointType.signature, HardpointType.broadside, HardpointType.utility]);

      case SessionPhase.helm:
        final options = session.seaChart.currentCourseOptions;
        if (options.isEmpty) {
          return const SteerCourse(NavigationalBearing.deadAhead);
        }
        final titanCourse = options
            .where((c) => c.nodeType == EncounterNodeType.regionTitan)
            .firstOrNull;
        if (titanCourse != null) {
          return SteerCourse(titanCourse.bearing);
        }
        final combatCourse = options
            .where((c) => c.nodeType == EncounterNodeType.beastCombat)
            .firstOrNull;
        if (combatCourse != null) {
          return SteerCourse(combatCourse.bearing);
        }
        final ahead = options
            .where((c) => c.bearing == NavigationalBearing.deadAhead)
            .firstOrNull;
        if (ahead != null) {
          return SteerCourse(ahead.bearing);
        }
        return SteerCourse(options.first.bearing);

      case SessionPhase.expeditionVictory:
        return const ClaimExpeditionVictory();

      case SessionPhase.merchant:
        final hasTreasure = session.ship?.cargo.any((item) => item is Treasure) ?? false;
        if (hasTreasure) {
          return const SellAllTreasure();
        }
        return const LeaveMerchant();

      case SessionPhase.death:
        return const AbandonHunt();

      case SessionPhase.ended:
        throw StateError('Simulation session already ended');
    }
  }
}
