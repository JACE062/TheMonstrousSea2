import '../content/monsters.dart';
import '../model/combatant.dart';
import '../rng/game_rng.dart';

/// Manages the 4x5 naval navigation chart and encounter progression.
///
/// Encapsulates encounter progression, loop scaling upon completing the map,
/// and the climactic boss encounter against The Kraken at cell [3][4].
class SeaChart {
  SeaChart({
    this.currentRow = 0,
    this.currentCol = 0,
    this.timesCompleted = 0,
  });

  static const int totalRows = 4;
  static const int totalCols = 5;
  static const int bossRow = 3;
  static const int bossCol = 4;

  int currentRow;
  int currentCol;
  int timesCompleted;

  /// Returns true if currently at the very beginning of the sea chart.
  bool get isAtStart => currentRow == 0 && currentCol == 0;

  /// Returns true if currently facing The Kraken on loop 0 at cell [3][4].
  bool get isKrakenBoss =>
      currentRow == bossRow &&
      currentCol == bossCol &&
      timesCompleted == 0;

  /// Calculates the encounter difficulty level for cell [row], [col].
  ///
  /// Standard cells: `row + 1 + timesCompleted * 4`
  /// Boss cell [3][4]: `row + 2 + timesCompleted * 4`
  int difficultyAt(int row, int col) {
    if (row == bossRow && col == bossCol) {
      return row + 2 + timesCompleted * 4;
    }
    return row + 1 + timesCompleted * 4;
  }

  /// The difficulty level of the current chart coordinate.
  int get currentDifficulty => difficultyAt(currentRow, currentCol);

  /// Generates the monster encounter for the current coordinate.
  ///
  /// On loop 0 at cell [3][4], spawns The Kraken.
  /// Otherwise, generates a random monster scaled to [currentDifficulty].
  MonsterState currentMonster(GameRng rng) {
    if (isKrakenBoss) {
      return createKraken(rng: rng);
    }
    return randomMonster(level: currentDifficulty, rng: rng);
  }

  /// Advances to the next encounter cell on the chart.
  ///
  /// If completing the final cell [3][4], increments [timesCompleted]
  /// and loops back to [0][0] with increased difficulty scaling.
  void advance() {
    if (currentCol == totalCols - 1) {
      currentCol = 0;
      currentRow++;
    } else {
      currentCol++;
    }

    if (currentRow >= totalRows) {
      timesCompleted++;
      currentRow = 0;
      currentCol = 0;
    }
  }

  /// Resets position and completion count back to the initial harbor.
  void reset() {
    currentRow = 0;
    currentCol = 0;
    timesCompleted = 0;
  }
}
