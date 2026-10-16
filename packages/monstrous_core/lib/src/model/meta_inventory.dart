/// Represents persistent meta-currencies collected across voyages.
///
/// Currencies are organized in a dual-source matrix:
/// - Materials (exploration, soundings, salvage, shrines)
/// - Organics (combat drops, monster remains, apex harvesting)
class MetaInventory {
  MetaInventory({
    this.seaGlass = 0,
    this.monsterBone = 0,
    this.depthWroughtIron = 0,
    this.abyssalBarnacles = 0,
    this.krakenBeak = 0,
    this.serpentScale = 0,
    this.leviathanCore = 0,
    this.primordialCinders = 0,
  });

  factory MetaInventory.fromJson(Map<String, dynamic> json) {
    return MetaInventory(
      seaGlass: json['seaGlass'] as int? ?? 0,
      monsterBone: json['monsterBone'] as int? ?? 0,
      depthWroughtIron: json['depthWroughtIron'] as int? ?? 0,
      abyssalBarnacles: json['abyssalBarnacles'] as int? ?? 0,
      krakenBeak: json['krakenBeak'] as int? ?? 0,
      serpentScale: json['serpentScale'] as int? ?? 0,
      leviathanCore: json['leviathanCore'] as int? ?? 0,
      primordialCinders: json['primordialCinders'] as int? ?? 0,
    );
  }

  /// Common Material: Gathered from shipwrecks, calm soundings, and events.
  int seaGlass;

  /// Common Organic: Harvested from slain sea beasts and shark jaws.
  int monsterBone;

  /// Rare Material: Gathered from sunken galleons and deep soundings.
  int depthWroughtIron;

  /// Rare Organic: Harvested from apex predators and deep sea horrors.
  int abyssalBarnacles;

  /// Titan Trophy: Slaying The Kraken in Region 1.
  int krakenBeak;

  /// Titan Trophy: Slaying The World Serpent in Region 2.
  int serpentScale;

  /// Primordial Core: Slaying The Ancient Leviathan in Region 3.
  int leviathanCore;

  /// Corrupted Essence: Harvested under high Covenant Heat.
  int primordialCinders;

  bool get isEmpty =>
      seaGlass == 0 &&
      monsterBone == 0 &&
      depthWroughtIron == 0 &&
      abyssalBarnacles == 0 &&
      krakenBeak == 0 &&
      serpentScale == 0 &&
      leviathanCore == 0 &&
      primordialCinders == 0;

  void add({
    int seaGlass = 0,
    int monsterBone = 0,
    int depthWroughtIron = 0,
    int abyssalBarnacles = 0,
    int krakenBeak = 0,
    int serpentScale = 0,
    int leviathanCore = 0,
    int primordialCinders = 0,
  }) {
    this.seaGlass += seaGlass;
    this.monsterBone += monsterBone;
    this.depthWroughtIron += depthWroughtIron;
    this.abyssalBarnacles += abyssalBarnacles;
    this.krakenBeak += krakenBeak;
    this.serpentScale += serpentScale;
    this.leviathanCore += leviathanCore;
    this.primordialCinders += primordialCinders;
  }

  void addAll(MetaInventory other) {
    add(
      seaGlass: other.seaGlass,
      monsterBone: other.monsterBone,
      depthWroughtIron: other.depthWroughtIron,
      abyssalBarnacles: other.abyssalBarnacles,
      krakenBeak: other.krakenBeak,
      serpentScale: other.serpentScale,
      leviathanCore: other.leviathanCore,
      primordialCinders: other.primordialCinders,
    );
  }

  bool canAfford({
    int seaGlass = 0,
    int monsterBone = 0,
    int depthWroughtIron = 0,
    int abyssalBarnacles = 0,
    int krakenBeak = 0,
    int serpentScale = 0,
    int leviathanCore = 0,
    int primordialCinders = 0,
  }) {
    return this.seaGlass >= seaGlass &&
        this.monsterBone >= monsterBone &&
        this.depthWroughtIron >= depthWroughtIron &&
        this.abyssalBarnacles >= abyssalBarnacles &&
        this.krakenBeak >= krakenBeak &&
        this.serpentScale >= serpentScale &&
        this.leviathanCore >= leviathanCore &&
        this.primordialCinders >= primordialCinders;
  }

  bool spend({
    int seaGlass = 0,
    int monsterBone = 0,
    int depthWroughtIron = 0,
    int abyssalBarnacles = 0,
    int krakenBeak = 0,
    int serpentScale = 0,
    int leviathanCore = 0,
    int primordialCinders = 0,
  }) {
    if (!canAfford(
      seaGlass: seaGlass,
      monsterBone: monsterBone,
      depthWroughtIron: depthWroughtIron,
      abyssalBarnacles: abyssalBarnacles,
      krakenBeak: krakenBeak,
      serpentScale: serpentScale,
      leviathanCore: leviathanCore,
      primordialCinders: primordialCinders,
    )) {
      return false;
    }

    this.seaGlass -= seaGlass;
    this.monsterBone -= monsterBone;
    this.depthWroughtIron -= depthWroughtIron;
    this.abyssalBarnacles -= abyssalBarnacles;
    this.krakenBeak -= krakenBeak;
    this.serpentScale -= serpentScale;
    this.leviathanCore -= leviathanCore;
    this.primordialCinders -= primordialCinders;
    return true;
  }

  /// Checks whether this inventory has at least the amounts specified in [cost].
  bool canAffordCost(MetaCost cost) {
    return canAfford(
      seaGlass: cost.seaGlass,
      monsterBone: cost.monsterBone,
      depthWroughtIron: cost.depthWroughtIron,
      abyssalBarnacles: cost.abyssalBarnacles,
      krakenBeak: cost.krakenBeak,
      serpentScale: cost.serpentScale,
      leviathanCore: cost.leviathanCore,
      primordialCinders: cost.primordialCinders,
    );
  }

  /// Deducts [cost] if affordable, returning true if successful.
  bool spendCost(MetaCost cost) {
    return spend(
      seaGlass: cost.seaGlass,
      monsterBone: cost.monsterBone,
      depthWroughtIron: cost.depthWroughtIron,
      abyssalBarnacles: cost.abyssalBarnacles,
      krakenBeak: cost.krakenBeak,
      serpentScale: cost.serpentScale,
      leviathanCore: cost.leviathanCore,
      primordialCinders: cost.primordialCinders,
    );
  }

  MetaInventory copyWith({
    int? seaGlass,
    int? monsterBone,
    int? depthWroughtIron,
    int? abyssalBarnacles,
    int? krakenBeak,
    int? serpentScale,
    int? leviathanCore,
    int? primordialCinders,
  }) {
    return MetaInventory(
      seaGlass: seaGlass ?? this.seaGlass,
      monsterBone: monsterBone ?? this.monsterBone,
      depthWroughtIron: depthWroughtIron ?? this.depthWroughtIron,
      abyssalBarnacles: abyssalBarnacles ?? this.abyssalBarnacles,
      krakenBeak: krakenBeak ?? this.krakenBeak,
      serpentScale: serpentScale ?? this.serpentScale,
      leviathanCore: leviathanCore ?? this.leviathanCore,
      primordialCinders: primordialCinders ?? this.primordialCinders,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'seaGlass': seaGlass,
        'monsterBone': monsterBone,
        'depthWroughtIron': depthWroughtIron,
        'abyssalBarnacles': abyssalBarnacles,
        'krakenBeak': krakenBeak,
        'serpentScale': serpentScale,
        'leviathanCore': leviathanCore,
        'primordialCinders': primordialCinders,
      };

  @override
  String toString() =>
      'MetaInventory(SeaGlass: $seaGlass, Bone: $monsterBone, Iron: $depthWroughtIron, '
      'Barnacles: $abyssalBarnacles, Beak: $krakenBeak, Scale: $serpentScale, '
      'Core: $leviathanCore, Cinders: $primordialCinders)';
}

/// An immutable, const-constructible specification of required persistent meta-currencies.
class MetaCost {
  const MetaCost({
    this.seaGlass = 0,
    this.monsterBone = 0,
    this.depthWroughtIron = 0,
    this.abyssalBarnacles = 0,
    this.krakenBeak = 0,
    this.serpentScale = 0,
    this.leviathanCore = 0,
    this.primordialCinders = 0,
  });

  final int seaGlass;
  final int monsterBone;
  final int depthWroughtIron;
  final int abyssalBarnacles;
  final int krakenBeak;
  final int serpentScale;
  final int leviathanCore;
  final int primordialCinders;

  bool get isFree =>
      seaGlass == 0 &&
      monsterBone == 0 &&
      depthWroughtIron == 0 &&
      abyssalBarnacles == 0 &&
      krakenBeak == 0 &&
      serpentScale == 0 &&
      leviathanCore == 0 &&
      primordialCinders == 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'seaGlass': seaGlass,
        'monsterBone': monsterBone,
        'depthWroughtIron': depthWroughtIron,
        'abyssalBarnacles': abyssalBarnacles,
        'krakenBeak': krakenBeak,
        'serpentScale': serpentScale,
        'leviathanCore': leviathanCore,
        'primordialCinders': primordialCinders,
      };
}

