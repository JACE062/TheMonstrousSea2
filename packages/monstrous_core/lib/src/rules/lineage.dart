import 'dart:math';

import '../content/ship_weapons.dart';
import '../content/ships.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../rng/game_rng.dart';

/// Historical record of a fallen captain's career and demise.
class CaptainRecord {
  const CaptainRecord({
    required this.captainName,
    required this.shipName,
    required this.shipClass,
    required this.monstersDefeated,
    required this.highestDifficultyReached,
    required this.causeOfDeath,
  });

  final String captainName;
  final String shipName;
  final ShipClass shipClass;
  final int monstersDefeated;
  final int highestDifficultyReached;
  final String causeOfDeath;

  @override
  String toString() =>
      'Captain $captainName of The $shipName ($shipClass) - '
      'Monsters Defeated: $monstersDefeated, '
      'Highest Difficulty: $highestDifficultyReached, '
      'Fell to: $causeOfDeath';
}

/// Formats the cargo overflow warning for a new heir's vessel (Fixes Bug B5).
String formatFreighterCargoOverflowMessage(ShipState ship) =>
    'Not all of the Cargo fits onto The ${ship.name}, would you like to drop Cargo to make room?';

/// Tracks multi-generational lineage statistics, captain deaths, and heir succession.
class LineageTracker {
  LineageTracker({
    this.captainsLost = 0,
    this.totalMonstersDefeated = 0,
    this.highestDifficultyReached = 0,
    List<CaptainRecord>? history,
  }) : history = history ?? <CaptainRecord>[];

  int captainsLost;
  int totalMonstersDefeated;
  int highestDifficultyReached;
  final List<CaptainRecord> history;

  /// Records the death of a captain, updating aggregate statistics.
  void recordDeath(CaptainRecord record) {
    captainsLost++;
    totalMonstersDefeated += record.monstersDefeated;
    highestDifficultyReached =
        max(highestDifficultyReached, record.highestDifficultyReached);
    history.add(record);
  }

  /// Creates a new [ShipState] for an heir continuing the family lineage.
  ///
  /// Succession Rules:
  /// - If [previousShip] was a [ShipClass.freighter]:
  ///   - Heir inherits 5% of the previous ship's gold: `(previousShip.gold * 0.05).toInt()`.
  ///   - Heir inherits previous ship's cargo up to the new ship's [maxCargo] capacity.
  /// - Otherwise:
  ///   - Heir starts with standard 25 gold and empty cargo hold.
  /// - All heirs start with 2 Common Cannons equipped.
  ShipState createHeirShip({
    required String heirName,
    required ShipClass chosenClass,
    required ShipState previousShip,
    GameRng? rng,
    String? shipName,
  }) {
    final effectiveRng = rng ?? SeededGameRng();

    final cannon1 = generateShipWeapon(
      ShipWeaponType.cannon,
      1,
      RarityLevel.common,
      effectiveRng,
    );
    final cannon2 = generateShipWeapon(
      ShipWeaponType.cannon,
      1,
      RarityLevel.common,
      effectiveRng,
    );

    final heirShip = createShip(
      chosenClass,
      level: 1,
      rng: effectiveRng,
      name: shipName,
      equippedWeapons: [cannon1, cannon2],
    );

    if (previousShip.shipClass == ShipClass.freighter) {
      heirShip.gold = (previousShip.gold * 0.05).toInt();
      for (final item in previousShip.cargo) {
        if (heirShip.cargo.length < heirShip.maxCargo) {
          heirShip.cargo.add(item);
        } else {
          break;
        }
      }
    } else {
      heirShip.gold = 25;
      heirShip.cargo.clear();
    }

    return heirShip;
  }
}
