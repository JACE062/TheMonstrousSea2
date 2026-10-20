import '../model/bloodline_trait.dart';
import '../model/combatant.dart';
import '../model/item.dart';
import '../session/game_session.dart';
import '../session/session_phase.dart';

/// Captures transient mid-voyage session state so that players can pause
/// and resume a run across application launches.
///
/// This file is strictly auto-deleted upon captain demise or returning to port,
/// preventing save-scumming.
class VoyageSaveData {
  VoyageSaveData({
    required this.captainName,
    required this.ship,
    required this.regionIndex,
    required this.currentRow,
    required this.currentCol,
    required this.timesCompleted,
    this.activeBoonId,
    this.activeQuirkId,
    required this.phase,
    this.battleRound = 1,
    this.monstersDefeatedThisLife = 0,
    this.highestDifficultyThisLife = 1,
    List<Item>? pendingLoot,
    List<Item>? merchantStock,
    this.onSaleMerchantIndex,
    this.gunneryAccuracyBoon = 0,
    this.runicGuidanceBoon = 0,
  })  : pendingLoot = pendingLoot ?? <Item>[],
        merchantStock = merchantStock ?? <Item>[];

  factory VoyageSaveData.fromJson(Map<String, dynamic> json) {
    final shipJson = json['ship'] as Map<String, dynamic>;
    final phaseName = json['phase'] as String;
    final phase = SessionPhase.values.firstWhere(
      (e) => e.name == phaseName,
      orElse: () => SessionPhase.port,
    );

    final boonName = json['activeBoonId'] as String?;
    final boonId = boonName != null
        ? BloodlineTraitId.values.firstWhere((e) => e.name == boonName)
        : null;

    final quirkName = json['activeQuirkId'] as String?;
    final quirkId = quirkName != null
        ? BloodlineTraitId.values.firstWhere((e) => e.name == quirkName)
        : null;

    final lootList = (json['pendingLoot'] as List<dynamic>?)
        ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList();

    final stockList = (json['merchantStock'] as List<dynamic>?)
        ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList();

    return VoyageSaveData(
      captainName: json['captainName'] as String? ?? 'Captain',
      ship: ShipState.fromJson(shipJson),
      regionIndex: json['regionIndex'] as int? ?? 0,
      currentRow: json['currentRow'] as int? ?? 0,
      currentCol: json['currentCol'] as int? ?? 0,
      timesCompleted: json['timesCompleted'] as int? ?? 0,
      activeBoonId: boonId,
      activeQuirkId: quirkId,
      phase: phase,
      battleRound: json['battleRound'] as int? ?? 1,
      monstersDefeatedThisLife: json['monstersDefeatedThisLife'] as int? ?? 0,
      highestDifficultyThisLife: json['highestDifficultyThisLife'] as int? ?? 1,
      pendingLoot: lootList,
      merchantStock: stockList,
      onSaleMerchantIndex: json['onSaleMerchantIndex'] as int?,
      gunneryAccuracyBoon: json['gunneryAccuracyBoon'] as int? ?? 0,
      runicGuidanceBoon: json['runicGuidanceBoon'] as int? ?? 0,
    );
  }

  final String captainName;
  final ShipState ship;
  final int regionIndex;
  final int currentRow;
  final int currentCol;
  final int timesCompleted;
  final BloodlineTraitId? activeBoonId;
  final BloodlineTraitId? activeQuirkId;
  final SessionPhase phase;
  final int battleRound;
  final int monstersDefeatedThisLife;
  final int highestDifficultyThisLife;
  final List<Item> pendingLoot;
  final List<Item> merchantStock;
  final int? onSaleMerchantIndex;
  final int gunneryAccuracyBoon;
  final int runicGuidanceBoon;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'captainName': captainName,
        'ship': ship.toJson(),
        'regionIndex': regionIndex,
        'currentRow': currentRow,
        'currentCol': currentCol,
        'timesCompleted': timesCompleted,
        'activeBoonId': activeBoonId?.name,
        'activeQuirkId': activeQuirkId?.name,
        'phase': phase.name,
        'battleRound': battleRound,
        'monstersDefeatedThisLife': monstersDefeatedThisLife,
        'highestDifficultyThisLife': highestDifficultyThisLife,
        'pendingLoot': pendingLoot.map((e) => e.toJson()).toList(),
        'merchantStock': merchantStock.map((e) => e.toJson()).toList(),
        'onSaleMerchantIndex': onSaleMerchantIndex,
        'gunneryAccuracyBoon': gunneryAccuracyBoon,
        'runicGuidanceBoon': runicGuidanceBoon,
      };

  /// Constructs a [VoyageSaveData] snapshot from an active [GameSession].
  factory VoyageSaveData.fromSession(GameSession session) {
    if (session.ship == null) {
      throw StateError('Cannot create voyage save without an active ship');
    }
    return VoyageSaveData(
      captainName: session.captainName,
      ship: session.ship!,
      regionIndex: session.seaChart.currentRegionIndex,
      currentRow: session.seaChart.currentRow,
      currentCol: session.seaChart.currentCol,
      timesCompleted: session.seaChart.timesCompleted,
      activeBoonId: session.activeBoon?.id,
      activeQuirkId: session.activeQuirk?.id,
      phase: session.phase,
      battleRound: session.battleRound,
      monstersDefeatedThisLife: session.monstersDefeatedThisLife,
      highestDifficultyThisLife: session.highestDifficultyThisLife,
      pendingLoot: List<Item>.from(session.pendingLoot),
      merchantStock: List<Item>.from(session.merchantStock),
      onSaleMerchantIndex: session.onSaleMerchantIndex,
      gunneryAccuracyBoon: session.gunneryAccuracyBoon,
      runicGuidanceBoon: session.runicGuidanceBoon,
    );
  }

  /// Restores session state from this saved voyage.
  void restoreToSession(GameSession session) {
    session.captainName = captainName;
    session.ship = ship;
    session.seaChart.timesCompleted = timesCompleted;
    session.seaChart.currentRow = currentRow;
    session.seaChart.currentCol = currentCol;
    session.phase = phase;
    session.battleRound = battleRound;
    session.monstersDefeatedThisLife = monstersDefeatedThisLife;
    session.highestDifficultyThisLife = highestDifficultyThisLife;
    session.pendingLoot = List<Item>.from(pendingLoot);
    session.merchantStock = List<Item>.from(merchantStock);
    session.onSaleMerchantIndex = onSaleMerchantIndex;
    session.gunneryAccuracyBoon = gunneryAccuracyBoon;
    session.runicGuidanceBoon = runicGuidanceBoon;
    if (activeBoonId != null) {
      session.activeBoon = BloodlineTrait.allBoons
          .where((b) => b.id == activeBoonId)
          .firstOrNull;
    }
    if (activeQuirkId != null) {
      session.activeQuirk = BloodlineTrait.allQuirks
          .where((q) => q.id == activeQuirkId)
          .firstOrNull;
    }
  }
}
