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

  group('SeaChart Reset', () {
    test('reset() restores position to [0][0] and timesCompleted to 0', () {
      final chart = SeaChart(currentRow: 2, currentCol: 3, timesCompleted: 4);

      chart.reset();

      expect(chart.currentRow, 0);
      expect(chart.currentCol, 0);
      expect(chart.timesCompleted, 0);
      expect(chart.isAtStart, isTrue);
      expect(chart.currentDifficulty, 1);
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
}
