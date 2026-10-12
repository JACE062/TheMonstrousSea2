import 'dart:math';

import '../config/balance_config.dart';
import '../content/consumables.dart';
import '../content/ship_weapons.dart';
import '../content/ships.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';
import '../rules/combat.dart';
import '../rules/economy.dart';
import '../rules/lineage.dart';
import '../rules/loot.dart';
import '../rules/monster_ai.dart';
import '../rules/sea_chart.dart';
import '../traits/trait.dart';
import 'commands.dart';
import 'events.dart';
import 'session_phase.dart';

/// Central state machine and session orchestrator for The Monstrous Sea.
///
/// Drives the complete game loop from captain creation, naval combat,
/// spoils distribution, port economy, and multi-generational lineage.
class GameSession {
  GameSession({
    GameRng? rng,
    this.config = BalanceConfig.standard,
  })  : rng = rng ?? SeededGameRng(),
        seaChart = SeaChart(),
        lineage = LineageTracker();

  final GameRng rng;
  final BalanceConfig config;
  final SeaChart seaChart;
  final LineageTracker lineage;

  SessionPhase phase = SessionPhase.captainCreation;
  String captainName = '';
  ShipState? ship;
  MonsterState? currentMonster;
  List<Item> pendingLoot = <Item>[];
  List<Item> merchantStock = <Item>[];
  int? onSaleMerchantIndex;

  int monstersDefeatedThisLife = 0;
  int highestDifficultyThisLife = 0;
  int battleRound = 0;

  /// Returns the current asking price for the item at [stockIndex] in the shop.
  int getMerchantAskingPrice(int stockIndex) {
    if (stockIndex < 0 || stockIndex >= merchantStock.length) return 0;
    return getMerchantBuyPrice(
      merchantStock[stockIndex],
      isOnSale: stockIndex == onSaleMerchantIndex,
    );
  }

  /// Refreshes the merchant's wares and randomly designates one item as on-sale.
  void refreshMerchantStock([int? difficulty]) {
    final diff = difficulty ?? highestDifficultyThisLife;
    merchantStock = generateMerchantStock(max(1, diff), rng);
    onSaleMerchantIndex =
        merchantStock.isNotEmpty ? rng.nextInt(merchantStock.length) : null;
  }

  final List<CombatTrait> traits = const <CombatTrait>[
    FortifyTrait(),
    EvasionTrait(),
    InkCloudTrait(),
    TentacleTrait(),
  ];

  /// Dispatches [command] to update session state and returns resulting events.
  List<GameEvent> dispatch(Command command) {
    return switch (command) {
      NameCaptain(:final name) => _handleNameCaptain(name),
      ChooseShip(:final shipClass, :final customName) =>
        _handleChooseShip(shipClass, customName),
      VentureOutToSea() => _handleVentureOutToSea(),
      FireWeaponVolley(:final weaponType) =>
        _handleFireWeaponVolley(weaponType),
      UseConsumableItem(:final cargoIndex) =>
        _handleUseConsumable(cargoIndex),
      FleeEncounter() => _handleFleeEncounter(),
      ExecuteShipSpecialAction() => _handleShipSpecialAction(),
      TakeLootItem(:final lootIndex) => _handleTakeLootItem(lootIndex),
      TakeAllLoot() => _handleTakeAllLoot(),
      LeaveRemainingLoot() => _handleLeaveRemainingLoot(),
      DropCargoItem(:final cargoIndex) => _handleDropCargo(cargoIndex),
      EquipCargoWeapon(:final cargoIndex) => _handleEquipCargoWeapon(cargoIndex),
      UnequipShipWeapon(:final equippedIndex) =>
        _handleUnequipShipWeapon(equippedIndex),
      AdvanceToNextBattle() => _handleAdvanceToNextBattle(),
      ReturnToPort() => _handleReturnToPort(),
      VisitMerchant() => _handleVisitMerchant(),
      LeaveMerchant() => _handleLeaveMerchant(),
      BuyMerchantItem(:final stockIndex) => _handleBuyMerchantItem(stockIndex),
      SellCargoItem(:final cargoIndex) => _handleSellCargoItem(cargoIndex),
      SellAllTreasure() => _handleSellAllTreasure(),
      RepairShip(:final percentage) => _handleRepairShip(percentage),
      ContinueLineage(:final heirName, :final chosenClass) =>
        _handleContinueLineage(heirName, chosenClass),
      AbandonHunt() => _handleAbandonHunt(),
    };
  }

  List<GameEvent> _handleNameCaptain(String name) {
    if (phase != SessionPhase.captainCreation &&
        phase != SessionPhase.death) {
      throw StateError('Cannot name captain in phase $phase');
    }
    captainName = name;

    // Davy Jones Easter Egg
    if (name.equalsIgnoreCase('Davy Jones')) {
      final events = <GameEvent>[];
      ship = createFlyingDutchman();
      seaChart.currentRow = 3;
      seaChart.currentCol = 4;
      currentMonster = seaChart.currentMonster(rng);
      battleRound = 1;
      final prevPhase = phase.displayName;
      phase = SessionPhase.battle;

      events.add(PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ));
      events.add(BattleStarted(
        monsterName: currentMonster!.name,
        difficulty: seaChart.currentDifficulty,
        isBoss: true,
        monsterHp: currentMonster!.maxHp,
        monsterAc: currentMonster!.armorClass,
      ));
      return events;
    }

    return const <GameEvent>[];
  }

  List<GameEvent> _handleChooseShip(ShipClass shipClass, String? customName) {
    if (phase != SessionPhase.captainCreation) {
      throw StateError('Cannot choose starting ship in phase $phase');
    }
    ship = createShip(shipClass, level: 1, rng: rng);
    if (customName != null && customName.isNotEmpty) {
      ship!.name = customName;
    }
    // Starting armaments: 2 Common Cannons equipped
    final cannon1 = generateShipWeapon(
      ShipWeaponType.cannon,
      1,
      RarityLevel.common,
      rng,
    );
    final cannon2 = generateShipWeapon(
      ShipWeaponType.cannon,
      1,
      RarityLevel.common,
      rng,
    );
    ship!.addCargo(cannon1);
    ship!.addCargo(cannon2);
    ship!.equipWeapon(cannon1);
    ship!.equipWeapon(cannon2);
    ship!.gold = 25;

    refreshMerchantStock(1);
    final prevPhase = phase.displayName;
    phase = SessionPhase.port;

    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleVentureOutToSea() {
    if (phase != SessionPhase.port) {
      throw StateError('Cannot venture out to sea from $phase');
    }
    seaChart.reset();
    return _startEncounter();
  }

  List<GameEvent> _handleAdvanceToNextBattle() {
    if (phase != SessionPhase.restArea) {
      throw StateError('Cannot advance to next battle from $phase');
    }
    seaChart.advance();
    return _startEncounter();
  }

  List<GameEvent> _startEncounter() {
    if (ship == null || !ship!.isAlive) {
      return _resolvePlayerDeath();
    }
    final events = <GameEvent>[];
    currentMonster = seaChart.currentMonster(rng);
    battleRound = 1;

    final prevPhase = phase.displayName;
    phase = SessionPhase.battle;

    events.add(PhaseChanged(
      previousPhase: prevPhase,
      newPhase: phase.displayName,
    ));
    events.add(BattleStarted(
      monsterName: currentMonster!.name,
      difficulty: seaChart.currentDifficulty,
      isBoss: seaChart.isKrakenBoss,
      monsterHp: currentMonster!.maxHp,
      monsterAc: currentMonster!.armorClass,
    ));
    return events;
  }

  List<GameEvent> _handleFireWeaponVolley(ShipWeaponType weaponType) {
    if (phase != SessionPhase.battle || ship == null || currentMonster == null) {
      throw StateError('Cannot fire weapons outside of battle');
    }
    final events = <GameEvent>[];

    // Player volley
    events.addAll(executeShipWeaponVolley(
      ship!,
      weaponType,
      currentMonster!,
      rng,
      traits,
    ));

    // Check if monster defeated
    if (!currentMonster!.isAlive) {
      events.addAll(_resolveMonsterDefeat());
      return events;
    }

    // Monster response turn
    events.addAll(_resolveMonsterTurn());
    return events;
  }

  List<GameEvent> _handleUseConsumable(int cargoIndex) {
    if (phase != SessionPhase.battle || ship == null || currentMonster == null) {
      throw StateError('Cannot use consumable outside of battle');
    }
    if (cargoIndex < 0 || cargoIndex >= ship!.cargo.length) {
      throw RangeError('Invalid cargo index: $cargoIndex');
    }
    final item = ship!.cargo[cargoIndex];
    if (item is! Consumable) {
      throw ArgumentError('Item at index $cargoIndex is not a consumable');
    }

    final events = <GameEvent>[];
    item.usesLeft--;
    final result = resolveConsumableEffect(item, rng);
    if (result.didHit) {
      if (result.damage > 0) {
        currentMonster!.applyDamage(result.damage);
        events.add(AttackHit(
          targetName: currentMonster!.name,
          damage: result.damage,
          damageType: result.damageType.displayName,
          remainingHp: currentMonster!.currentHp,
        ));
      }
      if (result.statusEffect != null) {
        currentMonster!.addStatus(result.statusEffect!);
        events.add(NarrationEvent(
          result.description.isNotEmpty
              ? result.description
              : '${item.name} inflicts ${result.statusEffect!.displayName}!',
        ));
      }
    } else {
      events.add(AttackMissed(targetName: currentMonster!.name));
    }

    if (item.isDepleted) {
      ship!.cargo.removeAt(cargoIndex);
    }

    // Check if monster defeated
    if (!currentMonster!.isAlive) {
      events.addAll(_resolveMonsterDefeat());
      return events;
    }

    // Monster turn
    events.addAll(_resolveMonsterTurn());
    return events;
  }

  List<GameEvent> _handleFleeEncounter() {
    if (phase != SessionPhase.battle || ship == null) {
      throw StateError('Cannot flee outside of battle');
    }
    final events = <GameEvent>[];

    // Bug B3 flee probability
    final threshold = min(
      config.hardcodedFleeFloorThreshold,
      config.baseFleeThresholdLevel1 + config.fleePenaltyPerLevel * (ship!.level - 1),
    );
    final fled = rng.d100() > threshold;

    if (fled) {
      ship!.resetCombatBoosts();
      events.add(FledToPort(shipName: ship!.name));
      seaChart.reset();
      refreshMerchantStock();
      final prevPhase = phase.displayName;
      phase = SessionPhase.port;
      events.add(PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ));
      return events;
    }

    events.add(FleeFailed(shipName: ship!.name));
    events.add(NarrationEvent('${ship!.name} was unable to flee the encounter!'));
    // Failed flee: Monster attacks!
    events.addAll(_resolveMonsterTurn());
    return events;
  }

  List<GameEvent> _handleShipSpecialAction() {
    if (phase != SessionPhase.battle || ship == null) {
      throw StateError('Cannot use special action outside of battle');
    }
    final events = <GameEvent>[];

    // Fortify or Evasive Maneuvers
    for (final trait in traits) {
      final msg = trait.executeSpecialAction(ship!, currentMonster!, rng);
      if (msg.isNotEmpty) {
        events.add(NarrationEvent(msg));
        break;
      }
    }

    // Monster response turn
    events.addAll(_resolveMonsterTurn());
    return events;
  }

  List<GameEvent> _resolveMonsterTurn() {
    final events = <GameEvent>[];

    // Status effect tick on monster
    final monsterStatus = updateStatusEffects(
      currentMonster!,
      seaChart.currentDifficulty,
      rng,
      config,
    );
    events.addAll(monsterStatus.events);
    if (!currentMonster!.isAlive) {
      events.addAll(_resolveMonsterDefeat());
      return events;
    }

    // Monster attacks if can act
    if (monsterStatus.canAct) {
      events.addAll(takeMonsterTurn(
        currentMonster!,
        ship!,
        rng,
        config,
        traits,
      ));
    }

    // Check if player died
    if (!ship!.isAlive) {
      events.addAll(_resolvePlayerDeath());
      return events;
    }

    // End of round: decrement ship weapon charges
    ship!.decrementChargeTimeOnWeapons();
    battleRound++;

    // Status effect tick on ship
    final shipStatus = updateStatusEffects(
      ship!,
      seaChart.currentDifficulty,
      rng,
      config,
    );
    events.addAll(shipStatus.events);
    if (!ship!.isAlive) {
      events.addAll(_resolvePlayerDeath());
    }

    return events;
  }

  List<GameEvent> _resolveMonsterDefeat() {
    final events = <GameEvent>[];
    monstersDefeatedThisLife++;
    highestDifficultyThisLife = max(
      highestDifficultyThisLife,
      seaChart.currentDifficulty,
    );

    pendingLoot = generateVictoryLoot(seaChart.currentDifficulty, rng, config);
    ship!.decrementChargeTimeOnWeapons();
    ship!.resetCombatBoosts();

    final prevPhase = phase.displayName;
    phase = SessionPhase.loot;

    events.add(PhaseChanged(
      previousPhase: prevPhase,
      newPhase: phase.displayName,
    ));
    events.add(LootDropped(items: List<Item>.from(pendingLoot)));
    return events;
  }

  List<GameEvent> _resolvePlayerDeath() {
    final events = <GameEvent>[];
    lineage.recordDeath(CaptainRecord(
      captainName: captainName,
      shipName: ship!.name,
      shipClass: ship!.shipClass,
      monstersDefeated: monstersDefeatedThisLife,
      highestDifficultyReached: highestDifficultyThisLife,
      causeOfDeath: currentMonster?.name ?? 'The Undying Sea',
    ));

    final prevPhase = phase.displayName;
    phase = SessionPhase.death;

    events.add(PhaseChanged(
      previousPhase: prevPhase,
      newPhase: phase.displayName,
    ));
    events.add(CaptainLost(
      captainName: captainName,
      monstersDefeated: monstersDefeatedThisLife,
      highestDifficulty: highestDifficultyThisLife,
    ));
    return events;
  }

  List<GameEvent> _handleTakeLootItem(int lootIndex) {
    if (phase != SessionPhase.loot || ship == null) {
      throw StateError('Cannot take loot outside of loot phase');
    }
    if (lootIndex < 0 || lootIndex >= pendingLoot.length) {
      throw RangeError('Invalid loot index: $lootIndex');
    }
    final item = pendingLoot[lootIndex];
    if (ship!.addCargo(item)) {
      pendingLoot.removeAt(lootIndex);
      final events = <GameEvent>[ItemAcquired(item: item)];
      if (pendingLoot.isEmpty) {
        final prevPhase = phase.displayName;
        phase = SessionPhase.restArea;
        events.add(PhaseChanged(
          previousPhase: prevPhase,
          newPhase: phase.displayName,
        ));
      }
      return events;
    }
    return <GameEvent>[
      NarrationEvent('Cargo Hold is full! Cannot take ${item.name}'),
    ];
  }

  List<GameEvent> _handleTakeAllLoot() {
    if (phase != SessionPhase.loot || ship == null) {
      throw StateError('Cannot take loot outside of loot phase');
    }
    final events = <GameEvent>[];
    final itemsToKeep = <Item>[];

    for (final item in pendingLoot) {
      if (ship!.addCargo(item)) {
        events.add(ItemAcquired(item: item));
      } else {
        itemsToKeep.add(item);
      }
    }
    pendingLoot = itemsToKeep;
    if (pendingLoot.isEmpty) {
      final prevPhase = phase.displayName;
      phase = SessionPhase.restArea;
      events.add(PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ));
    }
    return events;
  }

  List<GameEvent> _handleLeaveRemainingLoot() {
    if (phase != SessionPhase.loot) {
      throw StateError('Cannot leave loot outside of loot phase');
    }
    pendingLoot.clear();
    final prevPhase = phase.displayName;
    phase = SessionPhase.restArea;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleDropCargo(int cargoIndex) {
    if (ship == null || cargoIndex < 0 || cargoIndex >= ship!.cargo.length) {
      throw RangeError('Invalid cargo index: $cargoIndex');
    }
    final dropped = ship!.cargo.removeAt(cargoIndex);
    return <GameEvent>[
      NarrationEvent('${dropped.name} jettisoned into the sea.'),
    ];
  }

  List<GameEvent> _handleEquipCargoWeapon(int cargoIndex) {
    if (ship == null || cargoIndex < 0 || cargoIndex >= ship!.cargo.length) {
      throw RangeError('Invalid cargo index: $cargoIndex');
    }
    final item = ship!.cargo[cargoIndex];
    if (item is! ShipWeapon) {
      throw ArgumentError('Item at index $cargoIndex is not a ship weapon');
    }
    if (ship!.equipWeapon(item)) {
      return <GameEvent>[
        NarrationEvent('${item.name} equipped.'),
      ];
    }
    return <GameEvent>[
      NarrationEvent('Cannot equip ${item.name}: exceeds weapon weight capacity.'),
    ];
  }

  List<GameEvent> _handleUnequipShipWeapon(int equippedIndex) {
    if (ship == null ||
        equippedIndex < 0 ||
        equippedIndex >= ship!.equippedWeapons.length) {
      throw RangeError('Invalid equipped index: $equippedIndex');
    }
    final weapon = ship!.equippedWeapons[equippedIndex];
    if (ship!.unequipWeapon(weapon)) {
      return <GameEvent>[
        NarrationEvent('${weapon.name} unequipped to cargo hold.'),
      ];
    }
    return <GameEvent>[
      NarrationEvent('No cargo hold space available to unequip ${weapon.name}.'),
    ];
  }

  List<GameEvent> _handleReturnToPort() {
    if (phase != SessionPhase.restArea) {
      throw StateError('Cannot return to port from $phase');
    }
    seaChart.reset();
    refreshMerchantStock();
    final prevPhase = phase.displayName;
    phase = SessionPhase.port;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleVisitMerchant() {
    if (phase != SessionPhase.port) {
      throw StateError('Cannot visit merchant from $phase');
    }
    final prevPhase = phase.displayName;
    phase = SessionPhase.merchant;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleLeaveMerchant() {
    if (phase != SessionPhase.merchant) {
      throw StateError('Cannot leave merchant from $phase');
    }
    final prevPhase = phase.displayName;
    phase = SessionPhase.port;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleBuyMerchantItem(int stockIndex) {
    if (phase != SessionPhase.merchant || ship == null) {
      throw StateError('Cannot buy items outside of merchant shop');
    }
    if (stockIndex < 0 || stockIndex >= merchantStock.length) {
      throw RangeError('Invalid stock index: $stockIndex');
    }
    final item = merchantStock[stockIndex];
    final cost = getMerchantAskingPrice(stockIndex);
    if (buyItem(ship!, item, price: cost)) {
      merchantStock.removeAt(stockIndex);
      if (onSaleMerchantIndex != null) {
        if (stockIndex == onSaleMerchantIndex) {
          onSaleMerchantIndex = null;
        } else if (stockIndex < onSaleMerchantIndex!) {
          onSaleMerchantIndex = onSaleMerchantIndex! - 1;
        }
      }
      return <GameEvent>[ItemAcquired(item: item)];
    }
    return <GameEvent>[
      NarrationEvent('Cannot purchase ${item.name}: insufficient gold or cargo.'),
    ];
  }

  List<GameEvent> _handleSellCargoItem(int cargoIndex) {
    if (phase != SessionPhase.merchant || ship == null) {
      throw StateError('Cannot sell items outside of merchant shop');
    }
    if (cargoIndex < 0 || cargoIndex >= ship!.cargo.length) {
      throw RangeError('Invalid cargo index: $cargoIndex');
    }
    final item = ship!.cargo[cargoIndex];
    final goldEarned = item.value;
    if (sellItem(ship!, item)) {
      return <GameEvent>[ItemSold(item: item, goldEarned: goldEarned)];
    }
    return const <GameEvent>[];
  }

  List<GameEvent> _handleSellAllTreasure() {
    if (ship == null) throw StateError('No ship available');
    final (totalGold, itemsSold) = sellAllTreasure(ship!);
    return <GameEvent>[
      AllTreasureSold(totalGold: totalGold, itemsSold: itemsSold),
    ];
  }

  List<GameEvent> _handleRepairShip(double percentage) {
    if (ship == null) throw StateError('No ship available');
    final cost = calculateRepairCost(ship!, percentage);
    if (cost <= 0) {
      return <GameEvent>[
        NarrationEvent('${ship!.name} needs no repairs!'),
      ];
    }
    if (repairShip(ship!, percentage)) {
      return <GameEvent>[
        ShipRepaired(repairedHp: cost, goldCost: cost, newHp: ship!.currentHp),
      ];
    }
    return <GameEvent>[
      NarrationEvent('Insufficient gold to repair ${ship!.name}.'),
    ];
  }

  List<GameEvent> _handleContinueLineage(String heirName, ShipClass chosenClass) {
    if (phase != SessionPhase.death || ship == null) {
      throw StateError('Cannot continue lineage outside of death phase');
    }
    captainName = heirName;
    ship = lineage.createHeirShip(
      heirName: heirName,
      chosenClass: chosenClass,
      previousShip: ship!,
      rng: rng,
    );
    monstersDefeatedThisLife = 0;
    highestDifficultyThisLife = 0;
    seaChart.reset();
    refreshMerchantStock(1);

    final prevPhase = phase.displayName;
    phase = SessionPhase.port;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
    ];
  }

  List<GameEvent> _handleAbandonHunt() {
    if (phase != SessionPhase.death) {
      throw StateError('Cannot abandon hunt outside of death phase');
    }
    final prevPhase = phase.displayName;
    phase = SessionPhase.ended;
    return <GameEvent>[
      PhaseChanged(
        previousPhase: prevPhase,
        newPhase: phase.displayName,
      ),
      NarrationEvent(
        'The Undying Sea has prevailed, but no longer shall the Hunt consume your lineage...',
      ),
    ];
  }
}

extension _StringCaseExtension on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}
