import 'dart:math';

import '../content/monsters.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../model/nemesis.dart';
import '../rng/game_rng.dart';

/// Represents a prospective navigational course option offered to the captain at the helm.
class CourseOption {
  const CourseOption({
    required this.bearing,
    required this.nodeType,
    required this.difficultyLevel,
    required this.lookoutCall,
    this.seaConditions = '',
    this.monsterSpecies,
    this.isIdentified = false,
    this.isApex = false,
    this.apexTitle,
    this.isNemesis = false,
  });

  final NavigationalBearing bearing;
  final EncounterNodeType nodeType;
  final int difficultyLevel;
  final String lookoutCall;
  final String seaConditions;
  final MonsterSpecies? monsterSpecies;
  final bool isIdentified;
  final bool isApex;
  final String? apexTitle;
  final bool isNemesis;

  CourseOption copyWith({
    bool? isIdentified,
    bool? isApex,
    String? apexTitle,
    bool? isNemesis,
  }) => CourseOption(
    bearing: bearing,
    nodeType: nodeType,
    difficultyLevel: difficultyLevel,
    lookoutCall: lookoutCall,
    seaConditions: seaConditions,
    monsterSpecies: monsterSpecies,
    isIdentified: isIdentified ?? this.isIdentified,
    isApex: isApex ?? this.isApex,
    apexTitle: apexTitle ?? this.apexTitle,
    isNemesis: isNemesis ?? this.isNemesis,
  );
}

/// A permanent dead-reckoning record of an expedition leg completed during the voyage.
class VoyageLegRecord {
  const VoyageLegRecord({
    required this.leg,
    required this.bearing,
    required this.nodeType,
    required this.lookoutCall,
    required this.chartRow,
    required this.chartCol,
    this.monsterSpecies,
    this.isApex = false,
    this.isNemesis = false,
  });

  final int leg;
  final NavigationalBearing bearing;
  final EncounterNodeType nodeType;
  final String lookoutCall;
  final int chartRow;
  final int chartCol;
  final MonsterSpecies? monsterSpecies;
  final bool isApex;
  final bool isNemesis;
}

/// Manages the dead-reckoning sea chart, expedition legs, and course options.
///
/// Encapsulates encounter progression across the naval soundings,
/// with procedural course generation at the helm, a guaranteed midpoint
/// Respite Island Haven, and the climactic Regional Titan at cell [3][4].
class SeaChart {
  SeaChart({
    this.currentRow = 0,
    this.currentCol = 0,
    this.currentLeg = 0,
    this.timesCompleted = 0,
    int? maxRowReached,
    List<List<MonsterSpecies>>? gridSpecies,
    GameRng? rng,
  }) : maxRowReached = max(maxRowReached ?? 0, currentRow) {
    if (gridSpecies != null) {
      _gridSpecies = gridSpecies;
      _generateNodeTypes(rng);
    } else {
      generateGrid(rng);
    }
  }

  static const int totalRows = 4;
  static const int totalCols = 5;
  static const int bossRow = 3;
  static const int bossCol = 4;
  static const int totalRegions = 3;

  /// Returns the total expedition legs for region [regionIndex] (10 in R1, 12 in R2, 14 in R3).
  static int totalLegsForRegion(int regionIndex) => switch (regionIndex) {
    0 => 10,
    1 => 12,
    2 => 14,
    _ => 14,
  };

  /// Returns the guaranteed midpoint haven leg for region [regionIndex] (5 in R1, 6 in R2, 7 in R3).
  static int midpointHavenLegForRegion(int regionIndex) =>
      switch (regionIndex) {
        0 => 5,
        1 => 6,
        2 => 7,
        _ => 7,
      };

  /// Total expedition legs in current region.
  int get totalLegs => totalLegsForRegion(currentRegionIndex);

  /// Guaranteed midpoint haven leg in current region.
  int get midpointHavenLeg => midpointHavenLegForRegion(currentRegionIndex);

  /// Climax titan encounter leg in current region.
  int get regionTitanLeg => totalLegs;

  int currentRow;
  int currentCol;
  int currentLeg;
  int timesCompleted;
  int maxRowReached;
  bool currentIsApex = false;
  bool currentIsNemesis = false;
  bool hasEncounteredNemesisThisVoyage = false;

  final List<VoyageLegRecord> _voyageLog = <VoyageLegRecord>[];
  List<VoyageLegRecord> get voyageLog => List.unmodifiable(_voyageLog);

  /// Begins a fresh voyage at its first actual encounter, recording Leg 1.
  void beginVoyage({int startingRow = 0}) {
    resetCoordinates();
    currentRow = startingRow.clamp(0, totalRows - 1);
    currentLeg = 1;
    _gridNodeTypes[currentRow][currentCol] = EncounterNodeType.beastCombat;
    _voyageLog.add(
      VoyageLegRecord(
        leg: currentLeg,
        bearing: NavigationalBearing.deadAhead,
        nodeType: currentNodeType,
        lookoutCall: 'The flagship clears the harbor and enters open water.',
        chartRow: currentRow,
        chartCol: currentCol,
        monsterSpecies: currentNodeType == EncounterNodeType.beastCombat
            ? speciesAt(currentRow, currentCol)
            : null,
      ),
    );
  }

  /// Full navigation snapshot: the current leg, actual trail, and offered courses
  /// must resume together rather than inferring progress from old grid cells.
  Map<String, dynamic> toJson() => {
    'currentRow': currentRow,
    'currentCol': currentCol,
    'currentLeg': currentLeg,
    'timesCompleted': timesCompleted,
    'maxRowReached': maxRowReached,
    'currentIsApex': currentIsApex,
    'currentIsNemesis': currentIsNemesis,
    'hasEncounteredNemesisThisVoyage': hasEncounteredNemesisThisVoyage,
    'revealedRows': _revealedRows.toList(),
    'gridSpecies': _gridSpecies
        .map((row) => row.map((s) => s.name).toList())
        .toList(),
    'gridNodeTypes': _gridNodeTypes
        .map((row) => row.map((n) => n.name).toList())
        .toList(),
    'voyageLog': _voyageLog
        .map(
          (entry) => {
            'leg': entry.leg,
            'bearing': entry.bearing.name,
            'nodeType': entry.nodeType.name,
            'lookoutCall': entry.lookoutCall,
            'chartRow': entry.chartRow,
            'chartCol': entry.chartCol,
            'monsterSpecies': entry.monsterSpecies?.name,
            'isApex': entry.isApex,
            'isNemesis': entry.isNemesis,
          },
        )
        .toList(),
    'courseOptions': _currentCourseOptions
        .map(
          (option) => {
            'bearing': option.bearing.name,
            'nodeType': option.nodeType.name,
            'difficultyLevel': option.difficultyLevel,
            'lookoutCall': option.lookoutCall,
            'seaConditions': option.seaConditions,
            'monsterSpecies': option.monsterSpecies?.name,
            'isIdentified': option.isIdentified,
            'isApex': option.isApex,
            'apexTitle': option.apexTitle,
            'isNemesis': option.isNemesis,
          },
        )
        .toList(),
  };

  void restoreFromJson(Map<String, dynamic> json) {
    currentRow = json['currentRow'] as int;
    currentCol = json['currentCol'] as int;
    currentLeg = json['currentLeg'] as int;
    timesCompleted = json['timesCompleted'] as int;
    maxRowReached = json['maxRowReached'] as int? ?? currentRow;
    currentIsApex = json['currentIsApex'] as bool? ?? false;
    currentIsNemesis = json['currentIsNemesis'] as bool? ?? false;
    hasEncounteredNemesisThisVoyage =
        json['hasEncounteredNemesisThisVoyage'] as bool? ?? false;
    _revealedRows
      ..clear()
      ..addAll((json['revealedRows'] as List? ?? []).cast<int>());
    _overriddenNodeTypes.clear();
    _gridSpecies = (json['gridSpecies'] as List)
        .map(
          (row) => (row as List)
              .map((name) => MonsterSpecies.values.byName(name as String))
              .toList(),
        )
        .toList();
    _gridNodeTypes = (json['gridNodeTypes'] as List)
        .map(
          (row) => (row as List)
              .map((name) => EncounterNodeType.values.byName(name as String))
              .toList(),
        )
        .toList();
    _voyageLog
      ..clear()
      ..addAll(
        (json['voyageLog'] as List).map(
          (entry) => VoyageLegRecord(
            leg: entry['leg'] as int,
            bearing: NavigationalBearing.values.byName(
              entry['bearing'] as String,
            ),
            nodeType: EncounterNodeType.values.byName(
              entry['nodeType'] as String,
            ),
            lookoutCall: entry['lookoutCall'] as String,
            chartRow: entry['chartRow'] as int,
            chartCol: entry['chartCol'] as int,
            monsterSpecies: entry['monsterSpecies'] == null
                ? null
                : MonsterSpecies.values.byName(
                    entry['monsterSpecies'] as String,
                  ),
            isApex: entry['isApex'] as bool? ?? false,
            isNemesis: entry['isNemesis'] as bool? ?? false,
          ),
        ),
      );
    _currentCourseOptions = (json['courseOptions'] as List)
        .map(
          (option) => CourseOption(
            bearing: NavigationalBearing.values.byName(
              option['bearing'] as String,
            ),
            nodeType: EncounterNodeType.values.byName(
              option['nodeType'] as String,
            ),
            difficultyLevel: option['difficultyLevel'] as int,
            lookoutCall: option['lookoutCall'] as String,
            seaConditions: option['seaConditions'] as String? ?? '',
            monsterSpecies: option['monsterSpecies'] == null
                ? null
                : MonsterSpecies.values.byName(
                    option['monsterSpecies'] as String,
                  ),
            isIdentified: option['isIdentified'] as bool? ?? false,
            isApex: option['isApex'] as bool? ?? false,
            apexTitle: option['apexTitle'] as String?,
            isNemesis: option['isNemesis'] as bool? ?? false,
          ),
        )
        .toList();
    _discardTitanNemesisCourses();
  }

  /// Only invalid legacy offer sets need regeneration. Valid already-offered
  /// courses and the completed voyage log remain exactly as saved.
  void _discardTitanNemesisCourses() {
    if (_currentCourseOptions.any(
      (option) => option.isNemesis && option.monsterSpecies?.isRegionTitan == true,
    )) {
      currentIsNemesis = false;
      clearPendingCourses();
    }
  }

  List<CourseOption> _currentCourseOptions = <CourseOption>[];
  List<CourseOption> get currentCourseOptions =>
      List.unmodifiable(_currentCourseOptions);

  /// Discards unoffered courses so the helm can generate them with voyage context.
  void clearPendingCourses() => _currentCourseOptions.clear();

  /// The active region index (0: The Siren Shoals, 1: The Sargasso Drift, 2: The Boiling Reach).
  int get currentRegionIndex => timesCompleted.clamp(0, totalRegions - 1);

  /// Returns the grand nautical title for region [regionIndex].
  static String regionName(int regionIndex) => switch (regionIndex) {
    0 => 'The Siren Shoals',
    1 => 'The Sargasso Drift',
    2 => 'The Boiling Reach',
    _ => 'Uncharted Swell (Loop ${regionIndex + 1})',
  };

  /// Current region title.
  String get currentRegionName => regionName(currentRegionIndex);

  /// Returns atmospheric narrative subtitle for region [regionIndex].
  static String regionSubtitle(int regionIndex) => switch (regionIndex) {
    0 => 'Coastal reefs and foggy soundings echoing with deadly siren songs.',
    1 => 'Tangled doldrum weeds and derelict ghost ships adrift in phosphorescent haze.',
    2 => 'Boiling thermal calderas, rising steam plumes, and volcanic obsidian spires.',
    _ => 'Endless uncharted brine stretching past the rim of the world.',
  };

  /// Current region subtitle.
  String get currentRegionSubtitle => regionSubtitle(currentRegionIndex);

  /// Returns the fortified stronghold / harbor name for [regionIndex].
  static String strongholdName(int regionIndex) => switch (regionIndex) {
    0 => "Hunter's Respite",
    1 => 'Fort Krakenwatch',
    2 => 'The Iron Bastion',
    _ => 'Outpost ${regionIndex + 1}',
  };

  /// Returns descriptive subtitle for the stronghold at [regionIndex].
  static String strongholdSubtitle(int regionIndex) => switch (regionIndex) {
    0 => 'Sanctuary Harbor & Fortified Haven',
    1 => 'Naval Bastion at the Edge of the Sargasso Drift',
    2 => 'Volcanic Citadel at the Threshold of The Boiling Reach',
    _ => 'Forward Expedition Outpost',
  };

  /// The active stronghold/harbor name based on current region.
  String get currentPortName => strongholdName(currentRegionIndex);

  /// The active stronghold/harbor subtitle based on current region.
  String get currentPortSubtitle => strongholdSubtitle(currentRegionIndex);

  late List<List<MonsterSpecies>> _gridSpecies;
  late List<List<EncounterNodeType>> _gridNodeTypes;

  List<List<MonsterSpecies>> get gridSpecies => _gridSpecies;

  void _generateNodeTypes([GameRng? rng]) {
    if (rng == null) {
      // Deterministic fallback for test suites without RNG
      _gridNodeTypes = List.generate(totalRows, (row) {
        return List.generate(totalCols, (col) {
          if (row == bossRow && col == bossCol) {
            return EncounterNodeType.regionTitan;
          }
          if ((row == 1 && col == 3) || (row == 2 && col == 3)) {
            return EncounterNodeType.respiteIsland;
          }
          if (row == 2 && col == 1) {
            return EncounterNodeType.shipwreckSalvage;
          }
          if (row == 1 && col == 1) {
            return EncounterNodeType.smugglerTrader;
          }
          if (row == 2 && col == 2) {
            return EncounterNodeType.ancientShrine;
          }
          return EncounterNodeType.beastCombat;
        });
      });
      return;
    }

    final halfwayIndex = 8 + rng.nextInt(4);
    final halfwayRow = halfwayIndex ~/ totalCols;
    final halfwayCol = halfwayIndex % totalCols;

    _gridNodeTypes = List.generate(totalRows, (row) {
      return List.generate(totalCols, (col) {
        if (row == bossRow && col == bossCol) {
          return EncounterNodeType.regionTitan;
        }
        if (row == halfwayRow && col == halfwayCol) {
          return EncounterNodeType.respiteIsland;
        }
        if (row == 0 && col == 0) {
          return EncounterNodeType.beastCombat;
        }

        final roll = rng.nextInt(100);
        if (roll < 55) {
          return EncounterNodeType.beastCombat;
        } else if (roll < 70) {
          return EncounterNodeType.shipwreckSalvage;
        } else if (roll < 80) {
          return EncounterNodeType.respiteIsland;
        } else if (roll < 90) {
          return EncounterNodeType.smugglerTrader;
        } else {
          return EncounterNodeType.ancientShrine;
        }
      });
    });
  }

  /// Returns the node type at [row], [col].
  EncounterNodeType nodeTypeAt(int row, int col) {
    if (row < 0 || row >= totalRows || col < 0 || col >= totalCols) {
      return EncounterNodeType.beastCombat;
    }
    return _gridNodeTypes[row][col];
  }

  final Map<(int, int), EncounterNodeType> _overriddenNodeTypes = {};

  /// Sets the node type at [row], [col] (primarily for testing scenarios).
  void setNodeTypeAt(int row, int col, EncounterNodeType type) {
    if (row >= 0 && row < totalRows && col >= 0 && col < totalCols) {
      _gridNodeTypes[row][col] = type;
      _overriddenNodeTypes[(row, col)] = type;
      _currentCourseOptions.clear();
    }
  }

  /// The encounter node type of the ship's current coordinates.
  EncounterNodeType get currentNodeType => nodeTypeAt(currentRow, currentCol);

  /// Returns true if current cell is a Respite Island.
  bool get isRespiteIsland =>
      currentNodeType == EncounterNodeType.respiteIsland;

  /// Returns true if current cell is a Shipwreck Salvage cache.
  bool get isShipwreck => currentNodeType == EncounterNodeType.shipwreckSalvage;

  /// Returns true if current cell is a Smuggler's Ketch encounter.
  bool get isSmugglerTrader =>
      currentNodeType == EncounterNodeType.smugglerTrader;

  /// Returns true if current cell is an Ancient Sea Shrine.
  bool get isAncientShrine =>
      currentNodeType == EncounterNodeType.ancientShrine;

  /// Returns true if current cell is a Region Titan encounter.
  bool get isRegionTitan =>
      currentNodeType == EncounterNodeType.regionTitan ||
      (currentLeg >= totalLegs && currentLeg > 0) ||
      (currentLeg == 0 && currentRow == bossRow && currentCol == bossCol);

  /// Returns true if facing the final titan of the entire 3-region campaign.
  bool get isFinalTitan =>
      isRegionTitan && currentRegionIndex == totalRegions - 1;

  /// Returns a descriptive nautical name for depth stratum [row].
  static String depthName(int row) => switch (row) {
    0 => 'Coastal Waters',
    1 => 'The Open Ocean',
    2 => 'Abyssal Trenches',
    3 => 'The Leviathan Trench',
    _ => 'Depth ${row + 1}',
  };

  /// Returns region-specific sounding name for stratum [row].
  static String regionDepthName(int regionIndex, int row) {
    if (regionIndex == 0) {
      return switch (row) {
        0 => 'Shore Soundings',
        1 => 'Outer Barrier Reefs',
        2 => 'Fogbound Shallows',
        3 => "The Kraken's Lair",
        _ => 'Sounding ${row + 1}',
      };
    } else if (regionIndex == 1) {
      return switch (row) {
        0 => 'Doldrum Shallows',
        1 => 'The Weedy Flats',
        2 => 'Phosphorescent Fog',
        3 => "The Serpent's Swell",
        _ => 'Reach ${row + 1}',
      };
    } else if (regionIndex == 2) {
      return switch (row) {
        0 => 'Thermal Steam Vents',
        1 => 'Ash-Choked Shoals',
        2 => 'Boiling Caldera',
        3 => "The Leviathan's Caldera",
        _ => 'Caldera ${row + 1}',
      };
    }
    return depthName(row);
  }

  /// Current depth stratum name styled for active region.
  String get currentDepthName =>
      regionDepthName(currentRegionIndex, currentRow);

  final Set<int> _revealedRows = <int>{};

  /// Explicitly reveals all nodes in [row] (e.g. via ancient rune divination).
  void revealRow(int row) {
    if (row >= 0 && row < totalRows) {
      _revealedRows.add(row);
    }
    _currentCourseOptions = _currentCourseOptions
        .map((opt) => opt.copyWith(isIdentified: true))
        .toList();
  }

  /// Returns true if the cell at [row], [col] has been revealed on the chart.
  bool isRevealed(int row, int col) =>
      row <= max(currentRow, maxRowReached) ||
      (row == bossRow && col == bossCol) ||
      _revealedRows.contains(row);

  /// Returns true if circling seabirds or island silhouettes are spotted on the horizon.
  bool isHorizonSpotted(int row, int col) =>
      nodeTypeAt(row, col) == EncounterNodeType.respiteIsland;

  /// Returns the pre-determined species at [row], [col].
  MonsterSpecies speciesAt(int row, int col) {
    if (row < 0 || row >= totalRows || col < 0 || col >= totalCols) {
      return MonsterSpecies.shark;
    }
    return _gridSpecies[row][col];
  }

  /// Populates the encounter grid with monster species and encounter types.
  void generateGrid([GameRng? rng]) {
    _generateNodeTypes(rng);
    final effectiveRng = rng ?? SeededGameRng(42 + timesCompleted);
    _gridSpecies = List.generate(totalRows, (row) {
      final diff = row + 1 + timesCompleted * 4;
      return List.generate(totalCols, (col) {
        if (row == bossRow && col == bossCol) {
          if (timesCompleted == 0) return MonsterSpecies.kraken;
          if (timesCompleted == 1) return MonsterSpecies.worldSerpent;
          return MonsterSpecies.ancientLeviathan;
        }
        final available = diff == 1
            ? const [
                MonsterSpecies.shark,
                MonsterSpecies.serpent,
                MonsterSpecies.jellyfish,
                MonsterSpecies.squid,
              ]
            : const [
                MonsterSpecies.shark,
                MonsterSpecies.serpent,
                MonsterSpecies.jellyfish,
                MonsterSpecies.squid,
                MonsterSpecies.crustacean,
              ];
        return available[effectiveRng.nextInt(available.length)];
      });
    });
  }

  /// Returns true if currently at the very beginning of the sea chart.
  bool get isAtStart => currentLeg == 0 && currentRow == 0 && currentCol == 0;

  /// Returns true if currently facing The Kraken on loop 0.
  bool get isKrakenBoss => isRegionTitan && currentRegionIndex == 0;

  /// Calculates the encounter difficulty level for cell [row], [col].
  int difficultyAt(int row, int col) {
    if (isRegionTitan || (row == bossRow && col == bossCol)) {
      return bossRow + 2 + timesCompleted * 4;
    }
    return row + 1 + timesCompleted * 4;
  }

  /// The difficulty level of the current chart coordinate.
  int get currentDifficulty => difficultyAt(currentRow, currentCol);

  /// Generates the monster encounter for the current coordinate.
  MonsterState currentMonster(GameRng rng) {
    if (isRegionTitan) {
      if (currentRegionIndex == 0) {
        return createKraken(rng: rng);
      } else if (currentRegionIndex == 1) {
        return createWorldSerpent(level: currentDifficulty, rng: rng);
      } else {
        return createAncientLeviathan(level: currentDifficulty, rng: rng);
      }
    }
    final species = speciesAt(currentRow, currentCol);
    return createMonster(
      species,
      level: currentDifficulty,
      rng: rng,
      isApex: currentIsApex,
    );
  }

  /// Ensures course options exist for the next leg, generating them if empty.
  List<CourseOption> ensureCourseOptions([
    GameRng? rng,
    NemesisRecord? activeNemesis,
    bool chokingFog = false,
    bool apexEmergence = false,
  ]) {
    _discardTitanNemesisCourses();
    if (_currentCourseOptions.isEmpty) {
      _currentCourseOptions = generateCourseOptions(
        rng,
        activeNemesis,
        chokingFog,
        apexEmergence,
      );
    }
    return currentCourseOptions;
  }

  /// Generates 3 navigational course options for the upcoming expedition leg.
  List<CourseOption> generateCourseOptions([
    GameRng? rng,
    NemesisRecord? activeNemesis,
    bool chokingFog = false,
    bool apexEmergence = false,
  ]) {
    final effectiveRng =
        rng ?? SeededGameRng(42 + currentLeg * 19 + timesCompleted * 101);
    final targetLeg = currentLeg + 1;
    final isDivined =
        _revealedRows.contains(targetLeg) ||
        _revealedRows.contains(currentRow + 1);

    if (targetLeg == midpointHavenLeg) {
      return [
        CourseOption(
          bearing: NavigationalBearing.deadAhead,
          nodeType: EncounterNodeType.respiteIsland,
          difficultyLevel: currentDifficulty,
          lookoutCall: 'Landfall dead ahead! High verdant cliffs and a sheltered lagoon of the Midpoint Haven sighted through the ocean haze! Cormorants circling the haven canopy, Captain!',
          isIdentified: true,
        ),
      ];
    }

    if (targetLeg >= totalLegs) {
      final titanCall = switch (currentRegionIndex) {
        0 => 'Great God above... The Kraken rises! Massive suckered arms shattering the churning foam dead ahead!',
        1 => 'Twin yellow eyes piercing through the phosphor haze! The Abyssal Wyrm rears its crested head dead ahead!',
        _ => 'Boiling steam geysers erupting across the caldera! The Leviathan Prime surfaces dead ahead, blocking all passage!',
      };

      final bossDiff = bossRow + 2 + timesCompleted * 4;
      return [
        CourseOption(
          bearing: NavigationalBearing.deadAhead,
          nodeType: EncounterNodeType.regionTitan,
          difficultyLevel: bossDiff,
          lookoutCall: titanCall,
          isIdentified: true,
        ),
      ];
    }

    // Standard procedural legs
    final targetDifficulty =
        ((targetLeg + 1) ~/ 2).clamp(1, 4) + timesCompleted * 4;
    final options = <CourseOption>[];
    final bearings = [
      NavigationalBearing.larboardTack,
      NavigationalBearing.deadAhead,
      NavigationalBearing.starboardTack,
    ];

    final shouldSpawnNemesis =
        activeNemesis != null &&
        !activeNemesis.species.isRegionTitan &&
        !hasEncounteredNemesisThisVoyage &&
        currentRegionIndex == activeNemesis.regionIndex &&
        targetLeg > midpointHavenLeg &&
        targetLeg < totalLegs;
    // A side heading stays reachable even for a Reckless Helmsman. The other
    // two headings remain alternatives unless Blood Oath compels engagement.
    final nemesisBearingIndex = shouldSpawnNemesis
        ? (effectiveRng.nextInt(2) == 0 ? 0 : 2)
        : -1;

    for (var i = 0; i < bearings.length; i++) {
      final bearing = bearings[i];
      final targetRow = switch (bearing) {
        NavigationalBearing.larboardTack => max(0, currentRow - 1),
        NavigationalBearing.deadAhead =>
          currentCol == totalCols - 1
              ? min(totalRows - 1, currentRow + 1)
              : currentRow,
        NavigationalBearing.starboardTack => min(totalRows - 1, currentRow + 1),
      };
      final targetCol = (currentCol + 1) % totalCols;

      EncounterNodeType type;
      MonsterSpecies? species;
      bool isNemesis = false;

      if (shouldSpawnNemesis && i == nemesisBearingIndex) {
        type = EncounterNodeType.beastCombat;
        species = activeNemesis.species;
        isNemesis = true;
      } else if (_overriddenNodeTypes.containsKey((targetRow, targetCol))) {
        type = _overriddenNodeTypes[(targetRow, targetCol)]!;
      } else if (targetLeg == 1 && i == 1) {
        type = EncounterNodeType.beastCombat;
      } else {
        final isDepartingIsland =
            currentNodeType == EncounterNodeType.respiteIsland;
        final roll = effectiveRng.nextInt(100);
        if (roll < 55) {
          type = EncounterNodeType.beastCombat;
        } else if (roll < 70) {
          type = EncounterNodeType.shipwreckSalvage;
        } else if (roll < 85) {
          // 15% chance of procedural secluded cove; strictly 0% if currently departing an island
          type = isDepartingIsland
              ? EncounterNodeType.beastCombat
              : EncounterNodeType.respiteIsland;
        } else if (roll < 93) {
          type = EncounterNodeType.smugglerTrader;
        } else {
          type = EncounterNodeType.ancientShrine;
        }
      }

      bool isApex = isNemesis;
      String? apexTitle = isNemesis ? activeNemesis!.moniker : null;

      if (type == EncounterNodeType.beastCombat && !isNemesis) {
        final speciesList = currentRegionIndex == 0
            ? const [
                MonsterSpecies.shark,
                MonsterSpecies.serpent,
                MonsterSpecies.jellyfish,
                MonsterSpecies.squid,
              ]
            : MonsterSpecies.values
                  .where(
                    (s) =>
                        s != MonsterSpecies.kraken &&
                        s != MonsterSpecies.worldSerpent &&
                        s != MonsterSpecies.ancientLeviathan,
                  )
                  .toList();
        species = speciesList[effectiveRng.nextInt(speciesList.length)];

        // Apex predator chance scales by region: 20% in R1, 35% in R2, 50% in R3
        // Doubled when Apex Emergence pact is active.
        final apexRoll = effectiveRng.nextInt(100);
        final baseApexThreshold = switch (currentRegionIndex) {
          0 => 20,
          1 => 35,
          _ => 50,
        };
        final apexThreshold = apexEmergence
            ? (baseApexThreshold * 2).clamp(0, 100)
            : baseApexThreshold;
        if (targetLeg > 1 && apexRoll < apexThreshold) {
          isApex = true;
          apexTitle = switch (species) {
            MonsterSpecies.shark => 'Apex Megalodon',
            MonsterSpecies.serpent => 'Apex Sea Wyrm',
            MonsterSpecies.jellyfish => 'Apex Shock-Bell',
            MonsterSpecies.squid => 'Apex Abyssal Squid',
            MonsterSpecies.crustacean => 'Apex Obsidian Drake',
            _ => 'Apex Predator',
          };
        }
      }

      final direction = switch (bearing) {
        NavigationalBearing.larboardTack => 'off the larboard bow',
        NavigationalBearing.deadAhead => 'dead ahead',
        NavigationalBearing.starboardTack => 'off the starboard quarter',
      };

      final baseLookout = isNemesis
          ? 'Dark dread chills the salt air... The lookout spots ${activeNemesis!.moniker} $direction!'
          : _generateLookoutCall(
              type,
              species,
              bearing,
              effectiveRng,
              isApex: isApex,
            );

      final lookout = (chokingFog && !isDivined && !isNemesis)
          ? 'Dense phosphor fog muffles the lookout; waters $direction are completely obscured!'
          : baseLookout;

      options.add(
        CourseOption(
          bearing: bearing,
          nodeType: type,
          monsterSpecies: species,
          difficultyLevel: targetDifficulty,
          lookoutCall: lookout,
          isIdentified: isDivined,
          isApex: isApex,
          apexTitle: apexTitle,
          isNemesis: isNemesis,
        ),
      );
    }

    return options;
  }

  String _generateLookoutCall(
    EncounterNodeType type,
    MonsterSpecies? species,
    NavigationalBearing bearing,
    GameRng rng, {
    bool isApex = false,
  }) {
    final direction = switch (bearing) {
      NavigationalBearing.larboardTack => 'off the larboard bow',
      NavigationalBearing.deadAhead => 'dead ahead',
      NavigationalBearing.starboardTack => 'off the starboard quarter',
    };

    switch (type) {
      case EncounterNodeType.respiteIsland:
        const calls = [
          'Flock of shearwaters wheeling low over the spray — secluded cove sighted {dir}!',
          'White surf breaking against a tranquil coral atoll {dir}!',
          'Distant palm silhouettes and a sheltered lagoon visible {dir}!',
        ];
        return calls[rng.nextInt(calls.length)].replaceAll('{dir}', direction);

      case EncounterNodeType.shipwreckSalvage:
        const calls = [
          'Broken spars and waterlogged casks drifting on the swell {dir}!',
          'A shattered hull caught upon reefs, cargo floating free {dir}!',
          'Drifting timbers and rigging from an ill-fated merchant vessel {dir}!',
        ];
        return calls[rng.nextInt(calls.length)].replaceAll('{dir}', direction);

      case EncounterNodeType.smugglerTrader:
        const calls = [
          'A black-hulled ketch riding the swell with masked lanterns {dir}!',
          'Two-masted trader hailing through the fogbank, flying no naval ensign {dir}!',
          'Illicit lantern flashes through the mist — contraband traders {dir}!',
        ];
        return calls[rng.nextInt(calls.length)].replaceAll('{dir}', direction);

      case EncounterNodeType.ancientShrine:
        const calls = [
          'Barnacled basalt pillars rising from the sea, glowing with faint phosphor {dir}!',
          'A low, reverberating drone echoing off ancient carved rune-stones {dir}!',
          'Weathered stone monoliths piercing the foam, etched with titan-glyphs {dir}!',
        ];
        return calls[rng.nextInt(calls.length)].replaceAll('{dir}', direction);

      case EncounterNodeType.beastCombat:
        if (isApex) {
          return switch (species) {
            MonsterSpecies.shark =>
              'Colossal blood-red dorsal fin tearing through the foam! An Apex Megalodon $direction!',
            MonsterSpecies.serpent =>
              'Phosphorescent emerald coils spanning three ship lengths! An Apex Sea Wyrm $direction!',
            MonsterSpecies.jellyfish =>
              'Violent lightning discharges illuminating the abyss! An Apex Shock-Bell $direction!',
            MonsterSpecies.squid =>
              'Water violently boiling with massive spiked tentacles! An Apex Abyssal Squid $direction!',
            MonsterSpecies.crustacean =>
              'Black obsidian carapace smashing through the breakers! An Apex Armored Drake $direction!',
            _ =>
              'Massive predator breaching the surface froth! An Apex Sea Beast $direction!',
          };
        }
        return switch (species) {
          MonsterSpecies.shark =>
            'Triangular dorsal fins slicing swift through bloody foam $direction!',
          MonsterSpecies.serpent =>
            'Sinewy emerald coils undulating gracefully through the ocean swell $direction!',
          MonsterSpecies.jellyfish =>
            'Translucent, stinging bells pulsating with electric light in the water $direction!',
          MonsterSpecies.squid =>
            'A massive dark shadow and writhing tentacles drifting beneath the waves $direction!',
          MonsterSpecies.crustacean =>
            'An armored carapace clacking violently amongst the submerged shoals $direction!',
          _ =>
            'Violent breaches and dark shapes thrashing beneath the churned froth $direction!',
        };

      case EncounterNodeType.regionTitan:
        return 'Colossal oceanic disturbance! The regional titan stirs $direction!';
    }
  }

  /// Steers the ship along [bearing], advancing the voyage by one leg.
  CourseOption steerCourse(NavigationalBearing bearing, [GameRng? rng]) {
    final effectiveRng = rng ?? SeededGameRng(42 + currentLeg * 23);
    if (_currentCourseOptions.isEmpty) {
      _currentCourseOptions = generateCourseOptions(effectiveRng);
    }

    final chosen = _currentCourseOptions.firstWhere(
      (opt) => opt.bearing == bearing,
      orElse: () => _currentCourseOptions.first,
    );

    currentLeg++;
    currentIsApex = chosen.isApex;
    currentIsNemesis = chosen.isNemesis;
    if (chosen.isNemesis) {
      hasEncounteredNemesisThisVoyage = true;
    }

    if (currentCol == totalCols - 1) {
      currentCol = 0;
      switch (bearing) {
        case NavigationalBearing.larboardTack:
          currentRow = max(0, currentRow - 1);
        case NavigationalBearing.deadAhead:
          currentRow = min(totalRows - 1, currentRow + 1);
        case NavigationalBearing.starboardTack:
          currentRow = min(totalRows - 1, currentRow + 1);
      }
    } else {
      currentCol++;
      switch (bearing) {
        case NavigationalBearing.larboardTack:
          currentRow = max(0, currentRow - 1);
        case NavigationalBearing.deadAhead:
          break;
        case NavigationalBearing.starboardTack:
          currentRow = min(totalRows - 1, currentRow + 1);
      }
    }

    if (currentRow < totalRows && currentRow > maxRowReached) {
      maxRowReached = currentRow;
    }

    // Actual history is not a forced future encounter override when tracks cross.
    _gridNodeTypes[currentRow][currentCol] = chosen.nodeType;
    if (chosen.monsterSpecies != null) {
      _gridSpecies[currentRow][currentCol] = chosen.monsterSpecies!;
    }

    _voyageLog.add(
      VoyageLegRecord(
        leg: currentLeg,
        bearing: bearing,
        nodeType: chosen.nodeType,
        lookoutCall: chosen.lookoutCall,
        chartRow: currentRow,
        chartCol: currentCol,
        monsterSpecies: chosen.monsterSpecies,
        isApex: chosen.isApex,
        isNemesis: chosen.isNemesis,
      ),
    );

    // Generate the next offers on approaching the helm, where the session
    // supplies the active Nemesis and Covenant modifiers. Eager generation
    // here cached context-free choices and prevented the Nemesis from appearing.
    clearPendingCourses();
    return chosen;
  }

  /// Advances to the next encounter cell on the chart.
  void advance([GameRng? rng]) {
    if (currentCol == totalCols - 1) {
      currentCol = 0;
      currentRow++;
    } else {
      currentCol++;
    }

    currentLeg++;
    currentIsApex = false;
    currentIsNemesis = false;

    if (currentRow < totalRows && currentRow > maxRowReached) {
      maxRowReached = currentRow;
    }

    if (currentRow >= totalRows) {
      timesCompleted++;
      currentRow = 0;
      currentCol = 0;
      currentLeg = 0;
      maxRowReached = 0;
      currentIsNemesis = false;
      hasEncounteredNemesisThisVoyage = false;
      _revealedRows.clear();
      _voyageLog.clear();
      _currentCourseOptions.clear();
      generateGrid(rng ?? SeededGameRng(42 + timesCompleted));
      return;
    }

    clearPendingCourses();
  }

  /// Advances the sea chart to the next region after slaying the regional titan.
  void advanceRegion([GameRng? rng]) {
    timesCompleted++;
    currentRow = 0;
    currentCol = 0;
    currentLeg = 0;
    maxRowReached = 0;
    currentIsApex = false;
    currentIsNemesis = false;
    hasEncounteredNemesisThisVoyage = false;
    _revealedRows.clear();
    _voyageLog.clear();
    _currentCourseOptions.clear();
    generateGrid(rng ?? SeededGameRng(42 + timesCompleted));
  }

  /// Resets coordinates back to [0][0] within the current region/stronghold.
  void resetCoordinates() {
    currentRow = 0;
    currentCol = 0;
    currentLeg = 0;
    currentIsApex = false;
    currentIsNemesis = false;
    hasEncounteredNemesisThisVoyage = false;
    _voyageLog.clear();
    _currentCourseOptions.clear();
  }

  /// Resets position and completion count back to the initial harbor.
  void reset({bool resetMaxRow = false, GameRng? rng}) {
    currentRow = 0;
    currentCol = 0;
    currentLeg = 0;
    timesCompleted = 0;
    currentIsApex = false;
    currentIsNemesis = false;
    hasEncounteredNemesisThisVoyage = false;
    _revealedRows.clear();
    _voyageLog.clear();
    _currentCourseOptions.clear();
    if (resetMaxRow) {
      maxRowReached = 0;
    }
    generateGrid(rng ?? SeededGameRng(42));
  }
}
