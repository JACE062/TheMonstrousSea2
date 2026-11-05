import 'dart:math';

import '../model/combatant.dart';

/// One service visit. Quotes do not latch capacity; successful paid work does.
/// Actual restoration and gold are retained separately for receipts/auditing.
class PaidRepairWork {
  PaidRepairWork({
    this.maximumHullBasis,
    this.totalWork,
    this.spentWork = 0,
    this.restoredHp = 0,
    this.goldSpent = 0,
  });
  int? maximumHullBasis;
  int? totalWork;
  int spentWork, restoredHp, goldSpent;
  bool get isLatched => maximumHullBasis != null;
  Map<String, dynamic> toJson() => {
    'maximumHullBasis': maximumHullBasis,
    'totalWork': totalWork,
    'spentWork': spentWork,
    'restoredHp': restoredHp,
    'goldSpent': goldSpent,
  };
  factory PaidRepairWork.fromJson(Map<String, dynamic> json) => PaidRepairWork(
    maximumHullBasis: json['maximumHullBasis'] as int?,
    totalWork: json['totalWork'] as int?,
    spentWork: json['spentWork'] as int,
    restoredHp: json['restoredHp'] as int,
    goldSpent: json['goldSpent'] as int,
  );
}

class PaidRepairQuote {
  const PaidRepairQuote({
    required this.maximumHullBasis,
    required this.totalWork,
    required this.remainingWork,
    required this.startingWork,
    required this.startingHp,
    required this.startingMaximumHp,
    this.normalWork = 0,
    this.restoredHp = 0,
    this.goldCost = 0,
  });
  final int maximumHullBasis;

  /// Null means uncapped stronghold work, not an uninitialized capped pool.
  final int? totalWork, remainingWork;
  final int normalWork, restoredHp, goldCost;
  final int startingWork, startingHp, startingMaximumHp;
}

PaidRepairQuote quotePaidRepair(
  ShipState ship,
  PaidRepairWork state, {
  required double percentage,
  required double? allowanceFraction,
  required double goldPerWork,
  int? requestedWork,
}) {
  final basis = state.maximumHullBasis ?? ship.maxHp;
  final total = state.isLatched
      ? state.totalWork
      : allowanceFraction == null
      ? null
      : (basis * allowanceFraction).floor();
  final remaining = total == null ? null : max(0, total - state.spentWork);
  PaidRepairQuote empty() => PaidRepairQuote(
    maximumHullBasis: basis,
    totalWork: total,
    remainingWork: remaining,
    startingWork: state.spentWork,
    startingHp: ship.currentHp,
    startingMaximumHp: ship.maxHp,
  );
  if (!percentage.isFinite || percentage <= 0 || ship.currentHp >= ship.maxHp) {
    return empty();
  }
  final requested =
      requestedWork?.clamp(0, ship.maxHp) ??
      (ship.maxHp * min(percentage, 1.0)).floor();
  final work = min(requested, remaining ?? requested);
  if (work <= 0) return empty();
  final before = ship.modifiedHealing(state.spentWork);
  int restoration(int additionalWork) =>
      ship.modifiedHealing(state.spentWork + additionalWork) - before;
  final actual = min(ship.maxHp - ship.currentHp, restoration(work));
  if (actual <= 0) return empty();
  // Charge the smallest integer work giving the quoted missing-hull-limited
  // restoration. Cumulative rounding makes splitting unable to mint healing.
  var low = 1;
  var high = work;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (restoration(middle) >= actual) {
      high = middle;
    } else {
      low = middle + 1;
    }
  }
  int cost(int normalWork) => (normalWork * goldPerWork - 1e-9).ceil();
  return PaidRepairQuote(
    maximumHullBasis: basis,
    totalWork: total,
    remainingWork: remaining == null ? null : remaining - low,
    startingWork: state.spentWork,
    startingHp: ship.currentHp,
    startingMaximumHp: ship.maxHp,
    normalWork: low,
    restoredHp: actual,
    goldCost: cost(state.spentWork + low) - cost(state.spentWork),
  );
}

bool applyPaidRepair(
  ShipState ship,
  PaidRepairWork state,
  PaidRepairQuote quote,
) {
  if (quote.normalWork <= 0 ||
      quote.restoredHp <= 0 ||
      ship.gold < quote.goldCost) {
    return false;
  }
  if (state.spentWork != quote.startingWork ||
      ship.currentHp != quote.startingHp ||
      ship.maxHp != quote.startingMaximumHp ||
      quote.restoredHp > ship.maxHp - ship.currentHp) {
    return false;
  }
  if (!state.isLatched) {
    state.maximumHullBasis = quote.maximumHullBasis;
    state.totalWork = quote.totalWork;
  }
  state.spentWork += quote.normalWork;
  state.restoredHp += quote.restoredHp;
  state.goldSpent += quote.goldCost;
  ship.gold -= quote.goldCost;
  // The quote already applied captain modifiers and cumulative rounding once.
  ship.currentHp += quote.restoredHp;
  return true;
}
