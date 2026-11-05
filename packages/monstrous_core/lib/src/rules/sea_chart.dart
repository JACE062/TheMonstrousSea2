import 'dart:math';

import '../config/navigation_tuning.dart';
import '../content/monsters.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../model/nemesis.dart';
import '../model/wreck_encounter.dart';
import '../rng/game_rng.dart';
import 'wrecks.dart';

/// Service identity is independent of the illustration/node category.
enum CourseDestination {
  ordinary,
  midpointHaven,
  repairRefit,
  specialistMerchant,
  titan,
}

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
    this.destination = CourseDestination.ordinary,
    this.clearLookoutCall,
    this.wreckSighting,
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
  final CourseDestination destination;
  final String? clearLookoutCall;
  final WreckSighting? wreckSighting;

  CourseOption copyWith({
    bool? isIdentified,
    bool? isApex,
    String? apexTitle,
    bool? isNemesis,
    NavigationalBearing? bearing,
    int? difficultyLevel,
    String? lookoutCall,
  }) => CourseOption(
    bearing: bearing ?? this.bearing,
    nodeType: nodeType,
    difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    lookoutCall: lookoutCall ?? this.lookoutCall,
    seaConditions: seaConditions,
    monsterSpecies: monsterSpecies,
    isIdentified: isIdentified ?? this.isIdentified,
    isApex: isApex ?? this.isApex,
    apexTitle: apexTitle ?? this.apexTitle,
    isNemesis: isNemesis ?? this.isNemesis,
    destination: destination,
    clearLookoutCall: clearLookoutCall,
    wreckSighting: wreckSighting,
  );

  Map<String, dynamic> toJson() => {
    'bearing': bearing.name,
    'nodeType': nodeType.name,
    'difficultyLevel': difficultyLevel,
    'lookoutCall': lookoutCall,
    'seaConditions': seaConditions,
    'monsterSpecies': monsterSpecies?.name,
    'isIdentified': isIdentified,
    'isApex': isApex,
    'apexTitle': apexTitle,
    'isNemesis': isNemesis,
    'destination': destination.name,
    'clearLookoutCall': clearLookoutCall,
    'wreckSighting': wreckSighting?.toJson(),
  };

  factory CourseOption.fromJson(Map<String, dynamic> json) => CourseOption(
    bearing: NavigationalBearing.values.byName(json['bearing'] as String),
    nodeType: EncounterNodeType.values.byName(json['nodeType'] as String),
    difficultyLevel: json['difficultyLevel'] as int,
    lookoutCall: json['lookoutCall'] as String,
    seaConditions: json['seaConditions'] as String? ?? '',
    monsterSpecies: json['monsterSpecies'] == null
        ? null
        : MonsterSpecies.values.byName(json['monsterSpecies'] as String),
    isIdentified: json['isIdentified'] as bool? ?? false,
    isApex: json['isApex'] as bool? ?? false,
    apexTitle: json['apexTitle'] as String?,
    isNemesis: json['isNemesis'] as bool? ?? false,
    destination: CourseDestination.values.byName(
      json['destination'] as String? ?? 'ordinary',
    ),
    clearLookoutCall: json['clearLookoutCall'] as String?,
    wreckSighting: json['wreckSighting'] == null
        ? null
        : WreckSighting.fromJson(
            Map<String, dynamic>.from(json['wreckSighting'] as Map),
          ),
  );
}

/// A committed journey leg with explicit recorded outcomes; arrival is not victory.
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
    this.difficultyLevel = 1,
    this.destination = CourseDestination.ordinary,
    this.regionIndex = 0,
    this.combatWon = false,
    this.wreckPassed = false,
    this.wreckRecovered = false,
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
  final int difficultyLevel;
  final CourseDestination destination;
  final int regionIndex;
  final bool combatWon, wreckPassed, wreckRecovered;

  VoyageLegRecord withOutcome({bool? combatWon, bool? wreckPassed, bool? wreckRecovered,
    MonsterSpecies? species, bool? apex}) => VoyageLegRecord(
    leg: leg, bearing: bearing, nodeType: nodeType, lookoutCall: lookoutCall,
    chartRow: chartRow, chartCol: chartCol, monsterSpecies: species ?? monsterSpecies,
    isApex: apex ?? isApex, isNemesis: isNemesis, difficultyLevel: difficultyLevel,
    destination: destination, regionIndex: regionIndex,
    combatWon: combatWon ?? this.combatWon, wreckPassed: wreckPassed ?? this.wreckPassed,
    wreckRecovered: wreckRecovered ?? this.wreckRecovered,
  );
}

/// Manages the dead-reckoning sea chart, expedition legs, and course options.
///
/// Stages hidden regional offers, an optional midpoint Haven and final
/// preparation followed by a separate Titan. Committed offers own encounter
/// difficulty; retained grid coordinates only support chart/fixture helpers.
class SeaChart {
  SeaChart({
    this.currentRow = 0,
    this.currentCol = 0,
    this.currentLeg = 0,
    this.timesCompleted = 0,
    int? maxRowReached,
    List<List<MonsterSpecies>>? gridSpecies,
    GameRng? rng,
    this.tuning = NavigationTuning.provisional,
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
  final NavigationTuning tuning;

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

  /// Numbered slots through final preparation; the Titan follows separately.
  int get totalLegs => totalLegsForRegion(currentRegionIndex);

  /// Slot offering the optional midpoint Haven alongside two ordinary headings.
  int get midpointHavenLeg => midpointHavenLegForRegion(currentRegionIndex);

  /// Climax titan encounter leg in current region.
  int get regionTitanLeg => totalLegs + 1;

  int currentRow;
  int currentCol;
  int currentLeg;
  int timesCompleted;
  int maxRowReached;
  bool currentIsApex = false;
  bool currentIsNemesis = false;
  bool hasEncounteredNemesisThisVoyage = false;
  int? _committedDifficulty;
  CourseDestination currentDestination = CourseDestination.ordinary;
  WreckSighting? currentWreckSighting;
  final Map<int, List<CourseOption>> _regionalPlan = {};
  final Map<String, CourseOption> _conditionalCourses = {};

  final List<VoyageLegRecord> _voyageLog = <VoyageLegRecord>[];
  List<VoyageLegRecord> get voyageLog => List.unmodifiable(_voyageLog);

  /// Presentation facts only. Arrival never implies victory or reward ownership.
  void recordCurrentOutcome({bool? combatWon, bool? wreckPassed, bool? wreckRecovered,
    MonsterSpecies? species, bool? apex}) {
    final index = _voyageLog.lastIndexWhere((entry) => entry.regionIndex == currentRegionIndex && entry.leg == currentLeg);
    if (index < 0) return;
    _voyageLog[index] = _voyageLog[index].withOutcome(combatWon: combatWon,
      wreckPassed: wreckPassed, wreckRecovered: wreckRecovered, species: species, apex: apex);
  }

  /// Begins a fresh voyage at its first actual encounter, recording Leg 1.
  void beginVoyage({int startingRow = 0}) {
    resetCoordinates();
    currentRow = startingRow.clamp(0, totalRows - 1);
    currentLeg = 1;
    _committedDifficulty = 1 + timesCompleted * 4;
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
        difficultyLevel: currentDifficulty,
        regionIndex: currentRegionIndex,
      ),
    );
  }

  /// Full navigation snapshot: the current leg, actual trail, and offered courses
  /// must resume together rather than inferring progress from old grid cells.
  Map<String, dynamic> toJson() => {
    'currentRow': currentRow,
    'currentCol': currentCol,
    'currentLeg': currentLeg,
    'committedDifficulty': _committedDifficulty,
    'currentDestination': currentDestination.name,
    'currentWreckSighting': currentWreckSighting?.toJson(),
    'regionalPlan': _regionalPlan.map(
      (leg, options) =>
          MapEntry('$leg', options.map((o) => o.toJson()).toList()),
    ),
    'conditionalCourses': _conditionalCourses.map(
      (key, option) => MapEntry(key, option.toJson()),
    ),
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
            'difficultyLevel': entry.difficultyLevel,
            'destination': entry.destination.name,
            'regionIndex': entry.regionIndex,
            'combatWon': entry.combatWon,
            'wreckPassed': entry.wreckPassed,
            'wreckRecovered': entry.wreckRecovered,
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
            'destination': option.destination.name,
            'clearLookoutCall': option.clearLookoutCall,
            'wreckSighting': option.wreckSighting?.toJson(),
          },
        )
        .toList(),
  };

  void restoreFromJson(Map<String, dynamic> json) {
    currentRow = json['currentRow'] as int;
    currentCol = json['currentCol'] as int;
    currentLeg = json['currentLeg'] as int;
    currentWreckSighting = json['currentWreckSighting'] == null
        ? null
        : WreckSighting.fromJson(
            Map<String, dynamic>.from(json['currentWreckSighting'] as Map),
          );
    _committedDifficulty = json['committedDifficulty'] as int?;
    currentDestination = CourseDestination.values.byName(
      json['currentDestination'] as String? ?? 'ordinary',
    );
    _regionalPlan.clear();
    _conditionalCourses.clear();
    for (final entry
        in (json['conditionalCourses'] as Map<String, dynamic>? ?? {})
            .entries) {
      _conditionalCourses[entry.key] = CourseOption.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    for (final entry
        in (json['regionalPlan'] as Map<String, dynamic>? ?? {}).entries) {
      _regionalPlan[int.parse(entry.key)] = (entry.value as List)
          .map(
            (o) => CourseOption.fromJson(Map<String, dynamic>.from(o as Map)),
          )
          .toList();
    }
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
            difficultyLevel: entry['difficultyLevel'] as int? ?? 1,
            regionIndex: entry['regionIndex'] as int? ?? 0,
            combatWon: entry['combatWon'] as bool? ?? false,
            wreckPassed: entry['wreckPassed'] as bool? ?? false,
            wreckRecovered: entry['wreckRecovered'] as bool? ?? false,
            destination: CourseDestination.values.byName(
              entry['destination'] as String? ?? 'ordinary',
            ),
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
            // Correct old cached Titan aliases without rerolling the offer or
            // rewriting ordinary/Nemesis identities or completed voyage logs.
            lookoutCall:
                option['nodeType'] == EncounterNodeType.regionTitan.name &&
                    option['isNemesis'] != true
                ? _titanLookoutCall
                : option['lookoutCall'] as String,
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
            destination: CourseDestination.values.byName(
              option['destination'] as String? ?? 'ordinary',
            ),
            clearLookoutCall: option['clearLookoutCall'] as String?,
            wreckSighting: option['wreckSighting'] == null
                ? null
                : WreckSighting.fromJson(
                    Map<String, dynamic>.from(option['wreckSighting'] as Map),
                  ),
          ),
        )
        .toList();
    _discardTitanNemesisCourses();
  }

  /// Only invalid legacy offer sets need regeneration. Valid already-offered
  /// courses and the completed voyage log remain exactly as saved.
  void _discardTitanNemesisCourses() {
    if (_currentCourseOptions.any(
      (option) =>
          option.isNemesis && option.monsterSpecies?.isRegionTitan == true,
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
      currentDestination == CourseDestination.titan ||
      (currentLeg >= regionTitanLeg && currentLeg > 0) ||
      _overriddenNodeTypes[(currentRow, currentCol)] ==
          EncounterNodeType.regionTitan ||
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
    if (row >= 0 && row <= regionTitanLeg) {
      _revealedRows.add(row);
    }
    _currentCourseOptions = _currentCourseOptions
        .map(
          (opt) => opt.copyWith(
            isIdentified: true,
            lookoutCall: opt.clearLookoutCall,
          ),
        )
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

  /// Legacy grid helper. Runtime encounters use [currentDifficulty] instead.
  int difficultyAt(int row, int col) {
    if (isRegionTitan || (row == bossRow && col == bossCol)) {
      return bossRow + 2 + timesCompleted * 4;
    }
    return row + 1 + timesCompleted * 4;
  }

  /// The difficulty level of the current chart coordinate.
  int get currentDifficulty =>
      _committedDifficulty ??
      (isRegionTitan
          ? 5 + timesCompleted * 4
          : difficultyForLeg(max(1, currentLeg)));

  /// Generates the monster encounter for the current coordinate.
  MonsterState currentMonster(GameRng rng) {
    if (isRegionTitan) {
      if (currentRegionIndex == 0) {
        return createKraken(level: currentDifficulty, rng: rng);
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

  /// Ensures only the current group is exposed; the persisted regional plan
  /// remains private and is never regenerated by redraw or presentation.
  List<CourseOption> ensureCourseOptions([
    GameRng? rng,
    NemesisRecord? activeNemesis,
    bool chokingFog = false,
    bool apexEmergence = false,
    bool superstitious = false,
    bool vendetta = false,
  ]) {
    _discardTitanNemesisCourses();
    if (_currentCourseOptions.isEmpty) {
      _currentCourseOptions = generateCourseOptions(
        rng,
        activeNemesis,
        chokingFog,
        apexEmergence,
        superstitious,
        vendetta,
      );
    }
    return currentCourseOptions;
  }

  void redrawOrdinaryCourses(
    GameRng rng,
    NemesisRecord? activeNemesis,
    bool chokingFog,
    bool apexEmergence, [
    bool superstitious = false,
  ]) {
    if (_currentCourseOptions.length <= 1 ||
        _currentCourseOptions.any(
          (o) =>
              o.destination == CourseDestination.repairRefit ||
              o.destination == CourseDestination.specialistMerchant,
        )) {
      throw StateError('Cannot redraw a fixed course');
    }
    final leg = currentLeg + 1;
    _currentCourseOptions = [
      for (final option in _currentCourseOptions)
        if (option.isNemesis ||
            option.destination == CourseDestination.midpointHaven)
          option
        else
          _ordinaryOption(
            leg,
            option.bearing,
            rng,
            chokingFog,
            apexEmergence,
            superstitious,
            departingIsland: isRespiteIsland,
          ),
    ];
  }

  String get _titanLookoutCall => switch (currentRegionIndex) {
    0 => 'Great God above... The Kraken rises! Massive suckered arms shattering the churning foam dead ahead!',
    1 => 'Twin yellow eyes piercing through the phosphor haze! The World Serpent rears its crested head dead ahead!',
    _ => 'Boiling steam geysers erupting across the caldera! The Ancient Leviathan surfaces dead ahead, blocking all passage!',
  };

  int difficultyForLeg(int leg) => leg >= regionTitanLeg
      ? 5 + timesCompleted * 4
      : ((leg + 1) ~/ 2).clamp(1, 4) + timesCompleted * 4;

  List<CourseOption> generateCourseOptions([
    GameRng? rng,
    NemesisRecord? activeNemesis,
    bool chokingFog = false,
    bool apexEmergence = false,
    bool superstitious = false,
    bool vendetta = false,
  ]) {
    final effectiveRng =
        rng ?? SeededGameRng(42 + currentLeg * 19 + timesCompleted * 101);
    if (_regionalPlan.isEmpty) {
      _stageRegion(
        effectiveRng,
        activeNemesis,
        chokingFog,
        apexEmergence,
        superstitious,
        vendetta,
      );
    }
    final leg = currentLeg + 1;
    if (leg > regionTitanLeg) {
      throw StateError('Regional Titan must be resolved before continuing');
    }
    return [
      for (final option in _regionalPlan[leg]!)
        if (_overrideForBearing(option.bearing) case final type?)
          _fixtureOption(
            leg,
            option.bearing,
            type,
            effectiveRng,
            chokingFog,
            apexEmergence,
            superstitious,
          )
        else
          _courseForContext(option, leg, activeNemesis),
    ];
  }

  CourseOption _courseForContext(
    CourseOption original,
    int leg,
    NemesisRecord? nemesis,
  ) {
    var option = original;
    final key = '$leg:${original.bearing.name}';
    if (original.isNemesis &&
        (hasEncounteredNemesisThisVoyage || nemesis == null)) {
      option = _conditionalCourses['nemesis:$key']!;
    }
    if (isRespiteIsland &&
        option.destination == CourseDestination.ordinary &&
        option.nodeType == EncounterNodeType.respiteIsland) {
      option = _conditionalCourses['island:$key']!;
    }
    return _revealedRows.contains(leg)
        ? option.copyWith(
            isIdentified: true,
            lookoutCall: option.clearLookoutCall,
          )
        : option;
  }

  // Explicit scenario/test overrides remain a fixture API. Ordinary runtime
  // generation never treats drawn/grid coordinates as encounter authority.
  EncounterNodeType? _overrideForBearing(NavigationalBearing bearing) {
    final row = switch (bearing) {
      NavigationalBearing.larboardTack => max(0, currentRow - 1),
      NavigationalBearing.deadAhead =>
        currentCol == totalCols - 1
            ? min(totalRows - 1, currentRow + 1)
            : currentRow,
      NavigationalBearing.starboardTack => min(totalRows - 1, currentRow + 1),
    };
    return _overriddenNodeTypes[(row, (currentCol + 1) % totalCols)];
  }

  CourseOption _fixtureOption(
    int leg,
    NavigationalBearing bearing,
    EncounterNodeType type,
    GameRng rng,
    bool fog,
    bool apex,
    bool superstitious,
  ) {
    final ordinary = _ordinaryOption(
      leg,
      bearing,
      rng,
      fog,
      apex,
      superstitious,
      forcedType: type,
    );
    return CourseOption(
      bearing: bearing,
      nodeType: type,
      difficultyLevel: type == EncounterNodeType.regionTitan
          ? 5 + timesCompleted * 4
          : ordinary.difficultyLevel,
      lookoutCall: ordinary.lookoutCall,
      monsterSpecies: type == EncounterNodeType.beastCombat
          ? speciesAt(switch (bearing) {
              NavigationalBearing.larboardTack => max(0, currentRow - 1),
              NavigationalBearing.deadAhead =>
                currentCol == totalCols - 1
                    ? min(totalRows - 1, currentRow + 1)
                    : currentRow,
              NavigationalBearing.starboardTack => min(
                totalRows - 1,
                currentRow + 1,
              ),
            }, (currentCol + 1) % totalCols)
          : ordinary.monsterSpecies,
      isApex: ordinary.isApex,
      isIdentified: ordinary.isIdentified,
      wreckSighting: ordinary.wreckSighting,
      destination: type == EncounterNodeType.regionTitan
          ? CourseDestination.titan
          : type == EncounterNodeType.respiteIsland && leg == midpointHavenLeg
          ? CourseDestination.midpointHaven
          : CourseDestination.ordinary,
    );
  }

  void _stageRegion(
    GameRng rng,
    NemesisRecord? nemesis,
    bool fog,
    bool apex,
    bool superstitious,
    bool vendetta,
  ) {
    final eligibleNemesis =
        nemesis != null &&
        !nemesis.species.isRegionTitan &&
        !hasEncounteredNemesisThisVoyage &&
        currentRegionIndex == nemesis.regionIndex;
    const bearings = NavigationalBearing.values;
    for (var leg = 1; leg <= regionTitanLeg; leg++) {
      if (leg == regionTitanLeg) {
        _regionalPlan[leg] = [
          CourseOption(
            bearing: NavigationalBearing.deadAhead,
            nodeType: EncounterNodeType.regionTitan,
            difficultyLevel: difficultyForLeg(leg),
            lookoutCall: _titanLookoutCall,
            isIdentified: true,
            destination: CourseDestination.titan,
          ),
        ];
        continue;
      }
      if (leg == totalLegs) {
        _regionalPlan[leg] = [
          CourseOption(
            bearing: NavigationalBearing.larboardTack,
            nodeType: EncounterNodeType.respiteIsland,
            difficultyLevel: difficultyForLeg(leg),
            lookoutCall: 'Shipwright station to port. Paid hull repairs and voyage refits; no free shore duty.',
            isIdentified: true,
            destination: CourseDestination.repairRefit,
          ),
          CourseOption(
            bearing: NavigationalBearing.starboardTack,
            nodeType: EncounterNodeType.smugglerTrader,
            difficultyLevel: difficultyForLeg(leg),
            lookoutCall: 'Specialist merchant to starboard. Limited glass, iron and supplies; exact wares on arrival.',
            isIdentified: true,
            destination: CourseDestination.specialistMerchant,
          ),
        ];
        continue;
      }
      if (currentRegionIndex == 0 && leg == 1) {
        _regionalPlan[leg] = [
          _ordinaryOption(
            leg,
            NavigationalBearing.deadAhead,
            rng,
            fog,
            apex,
            superstitious,
            forcedType: EncounterNodeType.beastCombat,
          ),
        ];
        continue;
      }
      if (eligibleNemesis && vendetta && leg == midpointHavenLeg + 1) {
        _regionalPlan[leg] = [
          _nemesisOption(nemesis, NavigationalBearing.deadAhead),
        ];
        continue;
      }
      final havenBearing = leg == midpointHavenLeg
          ? (rng.nextInt(2) == 0
                ? NavigationalBearing.larboardTack
                : NavigationalBearing.starboardTack)
          : null;
      final nemesisBearing =
          eligibleNemesis && !vendetta && leg > midpointHavenLeg
          ? (rng.nextInt(2) == 0
                ? NavigationalBearing.larboardTack
                : NavigationalBearing.starboardTack)
          : null;
      _regionalPlan[leg] = [
        for (final bearing in bearings)
          if (bearing == havenBearing)
            CourseOption(
              bearing: bearing,
              nodeType: EncounterNodeType.respiteIsland,
              difficultyLevel: difficultyForLeg(leg),
              isIdentified: true,
              destination: CourseDestination.midpointHaven,
              lookoutCall:
                  'Midpoint Haven ${bearing == NavigationalBearing.larboardTack ? "to port" : "to starboard"}! Sheltered berths, one free shore duty, paid repairs and voyage refits.',
            )
          else if (bearing == nemesisBearing)
            _nemesisOption(nemesis!, bearing)
          else
            _ordinaryOption(leg, bearing, rng, fog, apex, superstitious),
      ];
    }
    // Structural reservations precede the floor. Keep valid natural plans and
    // extras; correct only a missing eligible shrine, without rerolling a plan.
    final eligible = <(int, int)>[];
    var hasShrine = false;
    for (final entry in _regionalPlan.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final option = entry.value[i];
        if (option.destination != CourseDestination.ordinary ||
            option.isNemesis ||
            (currentRegionIndex == 0 && entry.key == 1)) {
          continue;
        }
        eligible.add((entry.key, i));
        hasShrine |= option.nodeType == EncounterNodeType.ancientShrine;
      }
    }
    if (!hasShrine && eligible.isNotEmpty) {
      final (leg, index) = eligible[rng.nextInt(eligible.length)];
      final bearing = _regionalPlan[leg]![index].bearing;
      _regionalPlan[leg]![index] = _ordinaryOption(
        leg,
        bearing,
        rng,
        fog,
        apex,
        superstitious,
        forcedType: EncounterNodeType.ancientShrine,
      );
    }
    // Freeze conditional replacements too. A checkpoint before the next helm
    // must not change a hunt's species/tier when a cove is ineligible or a
    // Nemesis has already been encountered. These never count toward the floor.
    for (final entry in _regionalPlan.entries) {
      for (final original in entry.value) {
        final key = '${entry.key}:${original.bearing.name}';
        var ordinary = original;
        if (original.isNemesis) {
          ordinary = _ordinaryOption(
            entry.key,
            original.bearing,
            rng,
            fog,
            apex,
            superstitious,
          );
          _conditionalCourses['nemesis:$key'] = ordinary;
        }
        if (ordinary.destination == CourseDestination.ordinary &&
            ordinary.nodeType == EncounterNodeType.respiteIsland) {
          _conditionalCourses['island:$key'] = _ordinaryOption(
            entry.key,
            original.bearing,
            rng,
            fog,
            apex,
            superstitious,
            forcedType: EncounterNodeType.beastCombat,
          );
        }
      }
    }
  }

  CourseOption _nemesisOption(
    NemesisRecord nemesis,
    NavigationalBearing bearing,
  ) => CourseOption(
    bearing: bearing,
    nodeType: EncounterNodeType.beastCombat,
    monsterSpecies: nemesis.species,
    difficultyLevel: nemesis.level,
    lookoutCall:
        'Dark dread chills the salt air... ${nemesis.moniker} ${bearing.displayName}!',
    isIdentified: true,
    isApex: true,
    apexTitle: nemesis.moniker,
    isNemesis: true,
  );

  CourseOption _ordinaryOption(
    int leg,
    NavigationalBearing bearing,
    GameRng rng,
    bool fog,
    bool apexEmergence,
    bool superstitious, {
    EncounterNodeType? forcedType,
    bool departingIsland = false,
  }) {
    final roll = forcedType == null ? rng.nextInt(100) : 0;
    var type =
        forcedType ??
        (superstitious && roll < tuning.superstitiousExtraShrineWeight
            ? EncounterNodeType.ancientShrine
            : roll < tuning.huntWeight
            ? EncounterNodeType.beastCombat
            : roll < tuning.huntWeight + tuning.wreckWeight
            ? EncounterNodeType.shipwreckSalvage
            : roll < tuning.huntWeight + tuning.wreckWeight + tuning.coveWeight
            ? EncounterNodeType.respiteIsland
            : roll < 100 - tuning.shrineWeight
            ? EncounterNodeType.smugglerTrader
            : EncounterNodeType.ancientShrine);
    if (departingIsland && type == EncounterNodeType.respiteIsland) {
      type = EncounterNodeType.beastCombat;
    }
    MonsterSpecies? species;
    var isApex = false;
    if (type == EncounterNodeType.beastCombat) {
      final pool = MonsterSpecies.values
          .where(
            (s) =>
                !s.isRegionTitan &&
                (currentRegionIndex > 0 || s != MonsterSpecies.crustacean),
          )
          .toList();
      species = pool[rng.nextInt(pool.length)];
      final threshold =
          [20, 35, 50][currentRegionIndex] * (apexEmergence ? 2 : 1);
      isApex =
          !(currentRegionIndex == 0 && leg == 1) &&
          rng.nextInt(100) < threshold;
    }
    final revealed = _revealedRows.contains(leg);
    final sighting = type == EncounterNodeType.shipwreckSalvage
        ? generateWreckSighting(rng, tuning.wrecks)
        : null;
    final clearCall = sighting == null
        ? _generateLookoutCall(type, species, bearing, rng, isApex: isApex)
        : '${sighting.clue} ${bearing.displayName}. Approach may conceal a lurking creature.';
    return CourseOption(
      bearing: bearing,
      nodeType: type,
      monsterSpecies: species,
      difficultyLevel: difficultyForLeg(leg),
      isIdentified: revealed,
      isApex: isApex,
      apexTitle: isApex ? 'Apex ${species!.displayName}' : null,
      clearLookoutCall: clearCall,
      wreckSighting: sighting,
      lookoutCall: fog && !revealed
          ? 'Dense phosphor fog muffles the lookout; waters ${bearing.displayName} are completely obscured!'
          : clearCall,
    );
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
      orElse: () => throw StateError('Bearing is not offered'),
    );

    currentLeg++;
    _committedDifficulty = chosen.difficultyLevel;
    currentDestination = chosen.destination;
    currentWreckSighting = chosen.wreckSighting;
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
        difficultyLevel: chosen.difficultyLevel,
        destination: chosen.destination,
        regionIndex: currentRegionIndex,
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
    _committedDifficulty = null;
    currentDestination = CourseDestination.ordinary;
    currentWreckSighting = null;
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
      _regionalPlan.clear();
      _conditionalCourses.clear();
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
    _currentCourseOptions.clear();
    _regionalPlan.clear();
    _conditionalCourses.clear();
    _committedDifficulty = null;
    currentDestination = CourseDestination.ordinary;
    currentWreckSighting = null;
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
    _regionalPlan.clear();
    _conditionalCourses.clear();
    _committedDifficulty = null;
    currentDestination = CourseDestination.ordinary;
    currentWreckSighting = null;
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
    _regionalPlan.clear();
    _conditionalCourses.clear();
    _committedDifficulty = null;
    currentDestination = CourseDestination.ordinary;
    currentWreckSighting = null;
    if (resetMaxRow) {
      maxRowReached = 0;
    }
    generateGrid(rng ?? SeededGameRng(42));
  }
}
