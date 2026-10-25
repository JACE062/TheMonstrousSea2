import '../lore/trait_lore.dart';
import '../rng/game_rng.dart';
import 'enums.dart';

/// The category of a bloodline trait.
enum BloodlineTraitType {
  boon,
  quirk,
}

/// Unique identifier for each human captain trait.
enum BloodlineTraitId {
  // --- Boons ---
  veteranCannoneer,
  stormSeer,
  ironConstitution,
  smugglersKin,
  drillmaster,

  // --- Quirks ---
  bloodOath,
  recklessHelmsman,
  superstitious,
  saltAddict,
  overzealousGunner,
}

/// Represents a distinct, qualitative human trait altering gameplay rules.
class BloodlineTrait {
  const BloodlineTrait({
    required this.id,
    required this.name,
    required this.flavor,
    required this.description,
    required this.type,
  });

  factory BloodlineTrait.fromId(BloodlineTraitId id) {
    return allTraits.firstWhere(
      (t) => t.id == id,
      orElse: () => veteranCannoneer,
    );
  }

  factory BloodlineTrait.fromJson(Map<String, dynamic> json) {
    final idString = json['id'] as String;
    final id = BloodlineTraitId.values.firstWhere(
      (e) => e.name == idString,
      orElse: () => BloodlineTraitId.veteranCannoneer,
    );
    return BloodlineTrait.fromId(id);
  }

  final BloodlineTraitId id;
  final String name;
  final String flavor;
  final String description;
  final BloodlineTraitType type;

  bool get isBoon => type == BloodlineTraitType.boon;
  bool get isQuirk => type == BloodlineTraitType.quirk;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id.name,
        'name': name,
        'flavor': flavor,
        'description': description,
        'type': type.name,
      };

  @override
  String toString() => '$name ($type): $description';

  // --- Catalog of Standard Boons ---

  static final BloodlineTrait veteranCannoneer = BloodlineTrait(
    id: BloodlineTraitId.veteranCannoneer,
    name: TraitLore.boons[BloodlineTraitId.veteranCannoneer]!.name,
    flavor: TraitLore.boons[BloodlineTraitId.veteranCannoneer]!.flavor,
    description: TraitLore.boons[BloodlineTraitId.veteranCannoneer]!.description,
    type: BloodlineTraitType.boon,
  );

  static final BloodlineTrait stormSeer = BloodlineTrait(
    id: BloodlineTraitId.stormSeer,
    name: TraitLore.boons[BloodlineTraitId.stormSeer]!.name,
    flavor: TraitLore.boons[BloodlineTraitId.stormSeer]!.flavor,
    description: TraitLore.boons[BloodlineTraitId.stormSeer]!.description,
    type: BloodlineTraitType.boon,
  );

  static final BloodlineTrait ironConstitution = BloodlineTrait(
    id: BloodlineTraitId.ironConstitution,
    name: TraitLore.boons[BloodlineTraitId.ironConstitution]!.name,
    flavor: TraitLore.boons[BloodlineTraitId.ironConstitution]!.flavor,
    description: TraitLore.boons[BloodlineTraitId.ironConstitution]!.description,
    type: BloodlineTraitType.boon,
  );

  static final BloodlineTrait smugglersKin = BloodlineTrait(
    id: BloodlineTraitId.smugglersKin,
    name: TraitLore.boons[BloodlineTraitId.smugglersKin]!.name,
    flavor: TraitLore.boons[BloodlineTraitId.smugglersKin]!.flavor,
    description: TraitLore.boons[BloodlineTraitId.smugglersKin]!.description,
    type: BloodlineTraitType.boon,
  );

  static final BloodlineTrait drillmaster = BloodlineTrait(
    id: BloodlineTraitId.drillmaster,
    name: TraitLore.boons[BloodlineTraitId.drillmaster]!.name,
    flavor: TraitLore.boons[BloodlineTraitId.drillmaster]!.flavor,
    description: TraitLore.boons[BloodlineTraitId.drillmaster]!.description,
    type: BloodlineTraitType.boon,
  );

  // --- Catalog of Curious Quirks ---

  static final BloodlineTrait bloodOath = BloodlineTrait(
    id: BloodlineTraitId.bloodOath,
    name: TraitLore.quirks[BloodlineTraitId.bloodOath]!.name,
    flavor: TraitLore.quirks[BloodlineTraitId.bloodOath]!.flavor,
    description: TraitLore.quirks[BloodlineTraitId.bloodOath]!.description,
    type: BloodlineTraitType.quirk,
  );

  static final BloodlineTrait recklessHelmsman = BloodlineTrait(
    id: BloodlineTraitId.recklessHelmsman,
    name: TraitLore.quirks[BloodlineTraitId.recklessHelmsman]!.name,
    flavor: TraitLore.quirks[BloodlineTraitId.recklessHelmsman]!.flavor,
    description: TraitLore.quirks[BloodlineTraitId.recklessHelmsman]!.description,
    type: BloodlineTraitType.quirk,
  );

  static final BloodlineTrait superstitious = BloodlineTrait(
    id: BloodlineTraitId.superstitious,
    name: TraitLore.quirks[BloodlineTraitId.superstitious]!.name,
    flavor: TraitLore.quirks[BloodlineTraitId.superstitious]!.flavor,
    description: TraitLore.quirks[BloodlineTraitId.superstitious]!.description,
    type: BloodlineTraitType.quirk,
  );

  static final BloodlineTrait saltAddict = BloodlineTrait(
    id: BloodlineTraitId.saltAddict,
    name: TraitLore.quirks[BloodlineTraitId.saltAddict]!.name,
    flavor: TraitLore.quirks[BloodlineTraitId.saltAddict]!.flavor,
    description: TraitLore.quirks[BloodlineTraitId.saltAddict]!.description,
    type: BloodlineTraitType.quirk,
  );

  static final BloodlineTrait overzealousGunner = BloodlineTrait(
    id: BloodlineTraitId.overzealousGunner,
    name: TraitLore.quirks[BloodlineTraitId.overzealousGunner]!.name,
    flavor: TraitLore.quirks[BloodlineTraitId.overzealousGunner]!.flavor,
    description: TraitLore.quirks[BloodlineTraitId.overzealousGunner]!.description,
    type: BloodlineTraitType.quirk,
  );

  static final List<BloodlineTrait> allBoons = [
    veteranCannoneer,
    stormSeer,
    ironConstitution,
    smugglersKin,
    drillmaster,
  ];

  static final List<BloodlineTrait> allQuirks = [
    bloodOath,
    recklessHelmsman,
    superstitious,
    saltAddict,
    overzealousGunner,
  ];

  static final List<BloodlineTrait> allTraits = [
    ...allBoons,
    ...allQuirks,
  ];
}

/// A prospective heir candidate presented upon captain demise.
class HeirCandidate {
  const HeirCandidate({
    required this.defaultName,
    required this.boon,
    required this.quirk,
  });

  factory HeirCandidate.fromJson(Map<String, dynamic> json) {
    return HeirCandidate(
      defaultName: json['defaultName'] as String,
      boon: BloodlineTrait.fromJson(json['boon'] as Map<String, dynamic>),
      quirk: BloodlineTrait.fromJson(json['quirk'] as Map<String, dynamic>),
    );
  }

  final String defaultName;
  final BloodlineTrait boon;
  final BloodlineTrait quirk;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'defaultName': defaultName,
        'boon': boon.toJson(),
        'quirk': quirk.toJson(),
      };
}

/// Generates [count] distinct prospective heirs with unique trait pairings.
List<HeirCandidate> generateHeirCandidates({
  required GameRng rng,
  String? previousCaptainName,
  MonsterSpecies? nemesisSpecies,
  int count = 3,
}) {
  final candidateBoons = List<BloodlineTrait>.from(BloodlineTrait.allBoons)..shuffle();
  final hasNemesis = nemesisSpecies != null && !nemesisSpecies.isRegionTitan;
  final candidateQuirks =
      BloodlineTrait.allQuirks
          .where(
            (quirk) => hasNemesis || quirk.id != BloodlineTraitId.bloodOath,
          )
          .toList()
        ..shuffle();

  // If there's an active nemesis, ensure Blood Oath is guaranteed among the presented candidate quirks
  if (hasNemesis) {
    candidateQuirks.remove(BloodlineTrait.bloodOath);
    final insertIdx = rng.nextInt(count);
    candidateQuirks.insert(insertIdx, BloodlineTrait.bloodOath);
  }

  final firstNames = TraitLore.firstNames;
  final epithets = TraitLore.epithets;

  final prevSurname = previousCaptainName != null && previousCaptainName.contains(' ')
      ? previousCaptainName.split(' ').last
      : 'Vane';

  final candidates = <HeirCandidate>[];
  for (var i = 0; i < count; i++) {
    final firstName = firstNames[rng.nextInt(firstNames.length)];
    final epithet = epithets[rng.nextInt(epithets.length)];
    final defaultName = '$firstName $prevSurname $epithet';
    final boon = candidateBoons[i % candidateBoons.length];
    final quirk = candidateQuirks[i % candidateQuirks.length];

    candidates.add(HeirCandidate(
      defaultName: defaultName,
      boon: boon,
      quirk: quirk,
    ));
  }

  return candidates;
}
