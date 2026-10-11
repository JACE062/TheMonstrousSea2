import 'dart:math';

/// Abstract pseudo-random number generator interface used across the engine.
///
/// Ensures all randomness is deterministic, seedable, and isolated from global state.
abstract interface class GameRng {
  /// Returns a random integer in range [0..maxExclusive).
  int nextInt(int maxExclusive);

  /// Returns a random integer in range [minInclusive..maxInclusive].
  int nextIntRange(int minInclusive, int maxInclusive);

  /// Returns a random double in range [0.0..1.0).
  double nextDouble();

  /// Rolls an [n]-sided die (1..[n]).
  int d(int n);

  /// Rolls a standard 20-sided die (1..20).
  int d20();

  /// Rolls a standard 100-sided percentile die (1..100).
  int d100();
}

/// Seeded deterministic implementation of [GameRng].
class SeededGameRng implements GameRng {
  SeededGameRng([int? seed]) : _random = Random(seed);

  final Random _random;

  @override
  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) return 0;
    return _random.nextInt(maxExclusive);
  }

  @override
  int nextIntRange(int minInclusive, int maxInclusive) {
    if (minInclusive >= maxInclusive) return minInclusive;
    return minInclusive + _random.nextInt(maxInclusive - minInclusive + 1);
  }

  @override
  double nextDouble() => _random.nextDouble();

  @override
  int d(int n) {
    if (n <= 0) return 1;
    return _random.nextInt(n) + 1;
  }

  @override
  int d20() => d(20);

  @override
  int d100() => d(100);
}
