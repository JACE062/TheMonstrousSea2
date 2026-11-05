import 'enums.dart';
import 'item.dart';

enum WreckCondition { pickedClean, uncertain, fresh }

enum WreckStage { assessment, fighting, recovery, receipt, passed, lost }

enum WreckRecoveryChoice {
  passBy,
  quickSalvage,
  deeperRecovery,
  recoverClearedCargo,
  depart,
}

/// A private, persisted sighting seed fixes risk/cargo substreams independently
/// of rendering, reopening and the unsupported mid-battle checkpoint boundary.
class WreckSighting {
  const WreckSighting({
    required this.seed,
    required this.condition,
    required this.clearClue,
  });
  final int seed;
  final WreckCondition condition;
  final bool clearClue;

  String get clue => !clearClue
      ? 'A derelict rides the swell; mist hides the state of its holds.'
      : switch (condition) {
          WreckCondition.pickedClean =>
            'A weathered hull, stripped rigging and open, picked-clean holds.',
          WreckCondition.uncertain =>
            'A battered wreck with accessible flotsam and sealed lower holds.',
          WreckCondition.fresh =>
            'A freshly broken merchant hull with cargo still lashed below.',
        };

  Map<String, dynamic> toJson() => {
    'seed': seed,
    'condition': condition.name,
    'clearClue': clearClue,
  };
  factory WreckSighting.fromJson(Map<String, dynamic> json) => WreckSighting(
    seed: json['seed'] as int,
    condition: WreckCondition.values.byName(json['condition'] as String),
    clearClue: json['clearClue'] as bool,
  );
}

class WreckCargo {
  const WreckCargo({
    required this.seaGlass,
    required this.iron,
    required this.gold,
    required this.supplies,
  });
  final int seaGlass;
  final int iron;
  final int gold;
  final List<Consumable> supplies;
  Map<String, dynamic> toJson() => {
    'seaGlass': seaGlass,
    'iron': iron,
    'gold': gold,
    'supplies': supplies.map((item) => item.toJson()).toList(),
  };
  factory WreckCargo.fromJson(Map<String, dynamic> json) => WreckCargo(
    seaGlass: json['seaGlass'] as int,
    iron: json['iron'] as int,
    gold: json['gold'] as int,
    supplies: (json['supplies'] as List)
        .map(
          (item) =>
              Item.fromJson(Map<String, dynamic>.from(item as Map))
                  as Consumable,
        )
        .toList(),
  );
}

class WreckThreat {
  const WreckThreat({
    required this.species,
    required this.level,
    required this.isApex,
    required this.seed,
  });
  final MonsterSpecies species;
  final int level;
  final bool isApex;
  final int seed;
  Map<String, dynamic> toJson() => {
    'species': species.name,
    'level': level,
    'isApex': isApex,
    'seed': seed,
  };
  factory WreckThreat.fromJson(Map<String, dynamic> json) => WreckThreat(
    species: MonsterSpecies.values.byName(json['species'] as String),
    level: json['level'] as int,
    isApex: json['isApex'] as bool,
    seed: json['seed'] as int,
  );
}

/// Core-owned lifecycle. Permanent resources move only at recovery -> receipt;
/// ordinary creature loot belongs to the battle and never substitutes for cargo.
class WreckEncounter {
  WreckEncounter({
    required this.id,
    required this.sighting,
    this.stage = WreckStage.assessment,
    this.approachAmbush = false,
    this.committed = false,
    this.threatCleared = false,
    this.cargo,
    this.threat,
  });
  final String id;
  final WreckSighting sighting;
  WreckStage stage;
  bool approachAmbush;
  bool committed;
  bool threatCleared;
  WreckCargo? cargo;
  WreckThreat? threat;
  WreckCondition get condition => sighting.condition;
  bool get isSettled =>
      stage == WreckStage.receipt || stage == WreckStage.passed;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sighting': sighting.toJson(),
    'stage': stage.name,
    'approachAmbush': approachAmbush,
    'committed': committed,
    'threatCleared': threatCleared,
    'cargo': cargo?.toJson(),
    'threat': threat?.toJson(),
  };
  factory WreckEncounter.fromJson(Map<String, dynamic> json) => WreckEncounter(
    id: json['id'] as String,
    sighting: WreckSighting.fromJson(
      Map<String, dynamic>.from(json['sighting'] as Map),
    ),
    stage: WreckStage.values.byName(json['stage'] as String),
    approachAmbush: json['approachAmbush'] as bool,
    committed: json['committed'] as bool,
    threatCleared: json['threatCleared'] as bool,
    cargo: json['cargo'] == null
        ? null
        : WreckCargo.fromJson(Map<String, dynamic>.from(json['cargo'] as Map)),
    threat: json['threat'] == null
        ? null
        : WreckThreat.fromJson(
            Map<String, dynamic>.from(json['threat'] as Map),
          ),
  );
}
