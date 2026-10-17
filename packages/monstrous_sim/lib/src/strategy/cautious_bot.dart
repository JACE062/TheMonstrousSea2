import 'package:monstrous_core/monstrous_core.dart';
import 'bot_strategy.dart';

/// Defensive bot that prioritizes survivability, frequent hull repairs,
/// and tactical retreats when hull integrity drops below critical thresholds.
class CautiousBot implements BotStrategy {
  const CautiousBot();

  @override
  String get name => 'Cautious';

  @override
  Command decideNextAction(GameSession session) {
    switch (session.phase) {
      case SessionPhase.captainCreation:
        if (session.captainName.isEmpty) {
          return const NameCaptain('Captain Cautious');
        }
        return const ChooseShip(ShipClass.ironclad);

      case SessionPhase.port:
        final ship = session.ship;
        final hasTreasure = ship?.cargo.any((item) => item is Treasure) ?? false;
        if (hasTreasure) {
          return const VisitMerchant();
        }
        if (ship != null && ship.currentHp < ship.maxHp) {
          if (ship.gold >= calculateRepairCost(ship, 1.0)) {
            return const RepairShip(1.0);
          } else if (ship.gold >= calculateRepairCost(ship, 0.5)) {
            return const RepairShip(0.5);
          } else if (ship.gold >= calculateRepairCost(ship, 0.25)) {
            return const RepairShip(0.25);
          } else if (ship.gold >= calculateRepairCost(ship, 0.1)) {
            return const RepairShip(0.1);
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
        final hpRatio = ship.currentHp / ship.maxHp;
        final intent = session.currentMonster?.currentIntent;

        // If not grappled and haven't shifted helm this turn, check if a helm order can evade the telegraphed intent
        if (!ship.isGrappled &&
            session.lastHelmOrderThisTurn == HelmOrder.holdLine &&
            intent != null) {
          for (final order in session.combatRange.availableHelmOrders) {
            if (order == HelmOrder.holdLine) continue;
            final preview = intent.evaluatePreview(
              currentRange: session.combatRange,
              selectedHelmOrder: order,
              isMonsterPinned:
                  session.currentMonster?.isPinnedThisTurn ?? false,
            );
            if (preview.status == IntentPreviewStatus.evadedByPosition) {
              final targetRange = session.combatRange.rangeAfterHelmOrder(order);
              if (targetRange != session.combatRange) {
                return ChangeCombatRange(targetRange);
              }
            }
          }
        }

        // Fall back to longer range if critical health (< 20%) to gain evasion
        if (!ship.isGrappled &&
            hpRatio < 0.20 &&
            session.combatRange != CombatRange.long) {
          return ChangeCombatRange(session.combatRange.farther);
        }

        // Fire ready weapons
        final readyWeapons = ship.equippedWeapons
            .where((w) =>
                w.isReady &&
                isWeaponTypeUsableAtRange(w.weaponType, session.combatRange))
            .toList();
        if (readyWeapons.isNotEmpty) {
          // If haven't fortified yet and under 50% HP, fortify once
          if (hpRatio < 0.50 &&
              ship.currentDmgReduction == ship.baseDmgReduction &&
              ship.shipClass == ShipClass.ironclad) {
            return const ExecuteShipSpecialAction();
          }

          readyWeapons.sort((a, b) => b.damage.compareTo(a.damage));
          return FireWeaponVolley(readyWeapons.first.weaponType);
        }

        // If ready weapons exist but are out of range (e.g. Prow Ram at Long range), close in
        final outOfRangeReadyWeapons =
            ship.equippedWeapons.where((w) => w.isReady).toList();
        if (!ship.isGrappled &&
            outOfRangeReadyWeapons.isNotEmpty &&
            session.combatRange != CombatRange.short) {
          return ChangeCombatRange(session.combatRange.closer);
        }

        // Check for consumable
        final consumableIndex =
            ship.cargo.indexWhere((item) => item is Consumable);
        if (consumableIndex >= 0) {
          return UseConsumableItem(consumableIndex);
        }

        if (ship.shipClass == ShipClass.ironclad ||
            ship.shipClass == ShipClass.corvette) {
          return const ExecuteShipSpecialAction();
        }

        final anyUsable = ship.equippedWeaponTypes
            .where((type) => isWeaponTypeUsableAtRange(type, session.combatRange))
            .toList();
        if (anyUsable.isNotEmpty) {
          return FireWeaponVolley(anyUsable.first);
        }

        return (!ship.isGrappled && session.combatRange != CombatRange.short)
            ? ChangeCombatRange(session.combatRange.closer)
            : const ExecuteShipSpecialAction();

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
        final hpRatio = ship != null ? ship.currentHp / ship.maxHp : 1.0;

        // Emergency retreat to port to repair and upgrade when damaged
        if (hpRatio < 0.45) {
          return const ReturnToPort();
        }
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
        final ship = session.ship;
        if (!session.hasChosenIslandDuty) {
          if (ship != null && ship.currentHp < ship.maxHp * 0.85) {
            return const CareenHullAtIsland();
          }
          return const DrillGunnersAtIsland();
        }
        return const DepartIsland();

      case SessionPhase.shipwreck:
        final ship = session.ship;
        final hpRatio = ship != null ? ship.currentHp / ship.maxHp : 1.0;
        if (hpRatio < 0.6) {
          return const SalvageShipwreck(ShipwreckChoice.timbers);
        }
        return const SalvageShipwreck(ShipwreckChoice.strongbox);

      case SessionPhase.smuggler:
        final ship = session.ship;
        if (ship != null && ship.currentHp < ship.maxHp * 0.75 && ship.gold >= 30) {
          return const RepairShip(0.25);
        }
        final hasTreasure = ship?.cargo.any((item) => item is Treasure) ?? false;
        if (hasTreasure) {
          return const SellAllTreasure();
        }
        return const DepartSmuggler();

      case SessionPhase.shrine:
        if (!session.hasCommunedAtCurrentShrine) {
          final ship = session.ship;
          if (ship != null && ship.gold >= 30) {
            return const CommuneWithShrine(ShrineChoice.tribute);
          }
          return const CommuneWithShrine(ShrineChoice.ancientRunes);
        }
        return const DepartShrine();

      case SessionPhase.helm:
        final ship = session.ship;
        final options = session.seaChart.currentCourseOptions;
        if (ship != null && ship.currentHp < ship.maxHp * 0.65) {
          final haven = options
              .where((c) => c.nodeType == EncounterNodeType.respiteIsland)
              .firstOrNull;
          if (haven != null) return SteerCourse(haven.bearing);
          final smuggler = options
              .where((c) => c.nodeType == EncounterNodeType.smugglerTrader)
              .firstOrNull;
          if (smuggler != null && ship.gold >= 40) return SteerCourse(smuggler.bearing);
        }
        final shrine = options
            .where((c) => c.nodeType == EncounterNodeType.ancientShrine)
            .firstOrNull;
        if (shrine != null) return SteerCourse(shrine.bearing);
        return const SteerCourse(NavigationalBearing.deadAhead);

      case SessionPhase.expeditionVictory:
        return const ClaimExpeditionVictory();

      case SessionPhase.merchant:
        final ship = session.ship;
        final hasTreasure = ship?.cargo.any((item) => item is Treasure) ?? false;
        if (hasTreasure) {
          return const SellAllTreasure();
        }
        if (ship != null && ship.cargo.length >= ship.maxCargo && ship.cargo.isNotEmpty) {
          return const SellCargoItem(0);
        }
        return const LeaveMerchant();

      case SessionPhase.death:
        return const AbandonHunt();

      case SessionPhase.ended:
        throw StateError('Simulation session already ended');
    }
  }
}
