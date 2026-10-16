import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('SeaChart Progression & Navigation', () {
    test('initializes at [0][0] with timesCompleted 0', () {
      final chart = SeaChart();
      expect(chart.currentRow, 0);
      expect(chart.currentCol, 0);
      expect(chart.timesCompleted, 0);
      expect(chart.isAtStart, isTrue);
      expect(chart.isKrakenBoss, isFalse);
      expect(chart.currentDifficulty, 1);
    });

    test('advances across 4 rows and 5 columns sequentially to [3][4]', () {
      final chart = SeaChart();
      final visitedCoordinates = <(int, int)>[];

      for (var i = 0; i < 20; i++) {
        visitedCoordinates.add((chart.currentRow, chart.currentCol));
        if (i < 19) {
          chart.advance();
        }
      }

      // Check all 20 cells in order
      var expectedIdx = 0;
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 5; c++) {
          expect(visitedCoordinates[expectedIdx], (r, c));
          expectedIdx++;
        }
      }

      expect(chart.currentRow, 3);
      expect(chart.currentCol, 4);
    });
  });

  group('The Kraken Boss Encounter', () {
    test('identifies Kraken boss at [3][4] on loop 0 with difficulty 5', () {
      final chart = SeaChart(currentRow: 3, currentCol: 4, timesCompleted: 0);

      expect(chart.isKrakenBoss, isTrue);
      expect(chart.currentDifficulty, 5);

      final rng = SeededGameRng(42);
      final monster = chart.currentMonster(rng);

      expect(monster.name, 'The Kraken');
      expect(monster.species, MonsterSpecies.kraken);
      expect(monster.level, 5);
      expect(monster.maxHp, 300);
      expect(monster.armorClass, 18);
      expect(monster.numberOfTentacles, 25);
    });

    test('non-boss cells on loop 0 spawn random monsters matching row difficulty', () {
      final chart = SeaChart();
      final rng = SeededGameRng(101);

      // Row 0 cells have difficulty 1
      final mRow0 = chart.currentMonster(rng);
      expect(mRow0.level, 1);

      // Row 2 cells have difficulty 3
      chart.currentRow = 2;
      chart.currentCol = 2;
      expect(chart.currentDifficulty, 3);
      final mRow2 = chart.currentMonster(rng);
      expect(mRow2.level, 3);
    });
  });

  group('Map Loop Scaling', () {
    test('advancing past [3][4] increments timesCompleted and scales cell difficulties', () {
      final chart = SeaChart(currentRow: 3, currentCol: 4, timesCompleted: 0);

      // Complete loop 0
      chart.advance();

      expect(chart.timesCompleted, 1);
      expect(chart.currentRow, 0);
      expect(chart.currentCol, 0);
      expect(chart.isAtStart, isTrue);
      expect(chart.isKrakenBoss, isFalse);

      // Loop 1 difficulty: row + 1 + 1*4
      // Row 0: 0 + 1 + 4 = 5
      expect(chart.currentDifficulty, 5);
      expect(chart.difficultyAt(0, 0), 5);
      expect(chart.difficultyAt(0, 4), 5);

      // Row 1: 1 + 1 + 4 = 6
      expect(chart.difficultyAt(1, 0), 6);

      // Row 2: 2 + 1 + 4 = 7
      expect(chart.difficultyAt(2, 0), 7);

      // Row 3 (standard): 3 + 1 + 4 = 8
      expect(chart.difficultyAt(3, 0), 8);
      expect(chart.difficultyAt(3, 3), 8);

      // Boss cell [3][4] on loop 1: 3 + 2 + 1*4 = 9
      expect(chart.difficultyAt(3, 4), 9);
    });

    test('cell [3][4] on loop 1 spawns random difficulty 9 monster, not Kraken', () {
      final chart = SeaChart(currentRow: 3, currentCol: 4, timesCompleted: 1);

      expect(chart.isKrakenBoss, isFalse);
      expect(chart.currentDifficulty, 9);

      final rng = SeededGameRng(42);
      final monster = chart.currentMonster(rng);

      expect(monster.level, 9);
      expect(monster.name, isNot('The Kraken'));
    });

    test('loop 2 further scales difficulties by 8', () {
      final chart = SeaChart(currentRow: 0, currentCol: 0, timesCompleted: 2);

      // Row 0: 0 + 1 + 2*4 = 9
      expect(chart.difficultyAt(0, 0), 9);
      // Row 3 col 3: 3 + 1 + 2*4 = 12
      expect(chart.difficultyAt(3, 3), 12);
      // Boss cell [3][4]: 3 + 2 + 2*4 = 13
      expect(chart.difficultyAt(3, 4), 13);
    });
  });

  group('SeaChart Reset & Departure Waypoints', () {
    test('reset() restores position to [0][0] while preserving maxRowReached', () {
      final chart = SeaChart(currentRow: 2, currentCol: 3, timesCompleted: 4);
      expect(chart.maxRowReached, 2);

      chart.reset();

      expect(chart.currentRow, 0);
      expect(chart.currentCol, 0);
      expect(chart.timesCompleted, 0);
      expect(chart.maxRowReached, 2); // Preserved for departure waypoints!
      expect(chart.isAtStart, isTrue);
      expect(chart.currentDifficulty, 1);
    });

    test('reset(resetMaxRow: true) completely clears maxRowReached', () {
      final chart = SeaChart(currentRow: 3, currentCol: 2);
      expect(chart.maxRowReached, 3);

      chart.reset(resetMaxRow: true);
      expect(chart.currentRow, 0);
      expect(chart.maxRowReached, 0);
    });

    test('advancing past column 4 increases maxRowReached', () {
      final chart = SeaChart();
      expect(chart.maxRowReached, 0);

      // Advance through row 0
      for (var i = 0; i < 5; i++) {
        chart.advance();
      }
      expect(chart.currentRow, 1);
      expect(chart.maxRowReached, 1);
    });

    test('depthName returns canonical nautical names', () {
      expect(SeaChart.depthName(0), 'Coastal Waters');
      expect(SeaChart.depthName(1), 'The Open Ocean');
      expect(SeaChart.depthName(2), 'Abyssal Trenches');
      expect(SeaChart.depthName(3), 'The Leviathan Trench');
    });
  });

  group('SeaChart Fog of War & Grid Generation', () {
    test('reveals current row and previous rows, obscures lower rows', () {
      final chart = SeaChart();
      expect(chart.isRevealed(0, 0), isTrue);
      expect(chart.isRevealed(0, 4), isTrue);
      expect(chart.isRevealed(1, 0), isFalse);
      expect(chart.isRevealed(2, 0), isFalse);
      // Kraken at [3][4] is always known
      expect(chart.isRevealed(3, 4), isTrue);

      chart.currentRow = 1;
      expect(chart.isRevealed(0, 2), isTrue);
      expect(chart.isRevealed(1, 4), isTrue);
      expect(chart.isRevealed(2, 0), isFalse);

      expect(chart.speciesAt(3, 4), MonsterSpecies.kraken);
    });
  });

  group('Three Regions Campaign Structure & Regional Bosses', () {
    test('canonical region titles and atmospheric subtitles', () {
      expect(SeaChart.regionName(0), 'The Siren Shoals');
      expect(SeaChart.regionName(1), 'The Sargasso Drift');
      expect(SeaChart.regionName(2), 'The Boiling Reach');

      final chart = SeaChart();
      expect(chart.currentRegionName, 'The Siren Shoals');
      expect(chart.currentRegionSubtitle, contains('siren'));

      chart.timesCompleted = 1;
      expect(chart.currentRegionName, 'The Sargasso Drift');
      expect(chart.currentRegionSubtitle, contains('ghost ship'));

      chart.timesCompleted = 2;
      expect(chart.currentRegionName, 'The Boiling Reach');
      expect(chart.currentRegionSubtitle, contains('volcanic'));
    });

    test('region-specific depth stratum soundings', () {
      expect(SeaChart.regionDepthName(0, 0), 'Shore Soundings');
      expect(SeaChart.regionDepthName(0, 3), "The Kraken's Lair");

      expect(SeaChart.regionDepthName(1, 0), 'Doldrum Shallows');
      expect(SeaChart.regionDepthName(1, 3), "The Serpent's Swell");

      expect(SeaChart.regionDepthName(2, 0), 'Thermal Steam Vents');
      expect(SeaChart.regionDepthName(2, 3), "The Leviathan's Caldera");
    });

    test('boss spawning progression across the 3 regions at [3][4]', () {
      final rng = SeededGameRng(777);

      // Region 0: The Kraken
      final chart0 = SeaChart(currentRow: 3, currentCol: 4, timesCompleted: 0);
      expect(chart0.isKrakenBoss, isTrue);
      expect(chart0.isRegionTitan, isTrue);
      expect(chart0.isFinalTitan, isFalse);
      final boss0 = chart0.currentMonster(rng);
      expect(boss0.species, MonsterSpecies.kraken);

      // Region 1: The World Serpent
      final chart1 = SeaChart(currentRow: 3, currentCol: 4, timesCompleted: 1);
      expect(chart1.isKrakenBoss, isFalse);
      expect(chart1.isRegionTitan, isTrue);
      expect(chart1.isFinalTitan, isFalse);
      final boss1 = chart1.currentMonster(rng);
      expect(boss1.species, MonsterSpecies.worldSerpent);
      expect(boss1.name, 'The World Serpent');

      // Region 2: The Ancient Leviathan (Final Titan)
      final chart2 = SeaChart(currentRow: 3, currentCol: 4, timesCompleted: 2);
      expect(chart2.isKrakenBoss, isFalse);
      expect(chart2.isRegionTitan, isTrue);
      expect(chart2.isFinalTitan, isTrue);
      final boss2 = chart2.currentMonster(rng);
      expect(boss2.species, MonsterSpecies.ancientLeviathan);
      expect(boss2.name, 'The Ancient Leviathan');
    });
  });

  group('Encounter Node Types & Horizon Sighting', () {
    test('grid contains guaranteed Respite Islands and Shipwreck Salvage', () {
      final chart = SeaChart();

      expect(chart.nodeTypeAt(1, 3), EncounterNodeType.respiteIsland);
      expect(chart.nodeTypeAt(2, 3), EncounterNodeType.respiteIsland);
      expect(chart.nodeTypeAt(2, 1), EncounterNodeType.shipwreckSalvage);
      expect(chart.nodeTypeAt(3, 4), EncounterNodeType.regionTitan);

      // Standard node is beast combat
      expect(chart.nodeTypeAt(0, 0), EncounterNodeType.beastCombat);
      expect(chart.nodeTypeAt(0, 1), EncounterNodeType.beastCombat);
      expect(chart.nodeTypeAt(1, 2), EncounterNodeType.beastCombat);
    });

    test('respite islands are spotted by circling seabirds even in uncharted waters', () {
      final chart = SeaChart(); // At [0][0]

      // Row 1 node [1][0] is obscured in fog
      expect(chart.isRevealed(1, 0), isFalse);

      // But Respite Island at [1][3] is spotted on the horizon!
      expect(chart.isHorizonSpotted(1, 3), isTrue);
      // And Respite Island at [2][3] is also spotted on the horizon!
      expect(chart.isHorizonSpotted(2, 3), isTrue);
    });
  });

  group('Procedural Expedition Grids & Strongholds', () {
    test('procedural generation produces varied grids with guaranteed waypoints', () {
      final chartA = SeaChart(rng: SeededGameRng(111));
      final chartB = SeaChart(rng: SeededGameRng(222));

      // Both guarantee Titan at [3][4]
      expect(chartA.nodeTypeAt(3, 4), EncounterNodeType.regionTitan);
      expect(chartB.nodeTypeAt(3, 4), EncounterNodeType.regionTitan);

      // Both guarantee Beast Combat at [0][0]
      expect(chartA.nodeTypeAt(0, 0), EncounterNodeType.beastCombat);
      expect(chartB.nodeTypeAt(0, 0), EncounterNodeType.beastCombat);

      // Both guarantee a halfway island in sectors 8..11
      bool hasMidpointIsland(SeaChart chart) {
        for (var sector = 8; sector <= 11; sector++) {
          final r = sector ~/ SeaChart.totalCols;
          final c = sector % SeaChart.totalCols;
          if (chart.nodeTypeAt(r, c) == EncounterNodeType.respiteIsland) {
            return true;
          }
        }
        return false;
      }

      expect(hasMidpointIsland(chartA), isTrue);
      expect(hasMidpointIsland(chartB), isTrue);

      // Different seeds produce different layout signatures
      var differences = 0;
      for (var r = 0; r < SeaChart.totalRows; r++) {
        for (var c = 0; c < SeaChart.totalCols; c++) {
          if (chartA.nodeTypeAt(r, c) != chartB.nodeTypeAt(r, c)) {
            differences++;
          }
        }
      }
      expect(differences, greaterThan(0));
    });

    test('after-region strongholds provide fortified ports of call between regions', () {
      final chart = SeaChart();
      expect(chart.currentPortName, 'Hunter\'s Respite');
      expect(chart.currentPortSubtitle, contains('Sanctuary Harbor'));

      chart.timesCompleted = 1;
      expect(chart.currentPortName, 'Fort Krakenwatch');
      expect(chart.currentPortSubtitle, contains('Bastion'));

      chart.timesCompleted = 2;
      expect(chart.currentPortName, 'The Iron Bastion');
      expect(chart.currentPortSubtitle, contains('Volcanic Citadel'));
    });
  });
}
