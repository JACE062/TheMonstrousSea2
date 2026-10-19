import 'package:monstrous_core/monstrous_core.dart';
import 'bot_strategy.dart';

/// Aggressive bot prioritizing maximum raw damage output and rapid battle advancement.
/// Never retreats or flees from naval combat.
class RecklessBot implements BotStrategy {
  const RecklessBot();

  @override
  String get name => 'Reckless';

  @override
  Command decideNextAction(GameSession session) {
    switch (session.phase) {
      case SessionPhase.captainCreation:
        if (session.captainName.isEmpty) {
          return const NameCaptain('Captain Reckless');
        }
        return const ChooseShip(ShipClass.ironclad);

      case SessionPhase.port:
        final ship = session.ship;
        if (ship != null && ship.currentHp < ship.maxHp) {
          if (ship.gold >= calculateRepairCost(ship, 1.0)) {
            return const RepairShip(1.0);
          } else if (ship.gold >= calculateRepairCost(ship, 0.5)) {
            return const RepairShip(0.5);
          }
        }
        if (ship != null && ship.level < 4) {
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
        return const VentureOutToSea();

      case SessionPhase.battle:
        final ship = session.ship!;
        final consumableIndex = ship.cargo.indexWhere((item) => item is Consumable);
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
        final ship = session.ship;
        if (ship != null) {
          for (var i = 0; i < ship.cargo.length; i++) {
            final item = ship.cargo[i];
            if (item is ShipWeapon && ship.canEquipWeapon(item)) {
              return EquipCargoWeapon(i);
            }
          }
        }
        return const AdvanceToNextBattle();

      case SessionPhase.respiteIsland:
        if (!session.hasChosenIslandDuty) {
          return const DrillGunnersAtIsland();
        }
        return const DepartIsland();

      case SessionPhase.shipwreck:
        return const SalvageShipwreck(ShipwreckChoice.munitions);

      case SessionPhase.smuggler:
        return const DepartSmuggler();

      case SessionPhase.shrine:
        if (!session.hasCommunedAtCurrentShrine) {
          return const CommuneWithShrine(ShrineChoice.abyssalPact);
        }
        return const DepartShrine();

      case SessionPhase.helm:
        final combatCourse = session.seaChart.currentCourseOptions
            .where((c) => c.nodeType == EncounterNodeType.beastCombat)
            .firstOrNull;
        if (combatCourse != null) {
          return SteerCourse(combatCourse.bearing);
        }
        return const SteerCourse(NavigationalBearing.deadAhead);

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
