import 'package:monstrous_core/monstrous_core.dart';

/// Total permanent bonuses at the current and next rank, without a purchase.
class HarborMonumentPreview {
  HarborMonumentPreview(ProfileData profile, this.monument)
    : currentRank = profile.monumentRank(monument) {
    nextRank = currentRank + 1;
    cost = definition.costForRank(nextRank);
    final nextProfile = ProfileData(
      portCivicLevels: {...profile.portCivicLevels, monument.name: nextRank},
    );
    currentBonus = _bonus(profile);
    nextBonus = _bonus(nextProfile);
  }

  final HarborMonumentId monument;
  final int currentRank;
  late final int nextRank;
  late final MetaCost cost;
  late final int currentBonus;
  late final int nextBonus;

  HarborMonumentDef get definition => HarborMonumentDef.catalog[monument]!;
  String get label => switch (monument) {
    HarborMonumentId.obsidianObelisk => 'Maximum hull bonus',
    HarborMonumentId.serpentEffigy => 'Bounty gold bonus',
    HarborMonumentId.calderaBrazier => 'Weapon damage bonus',
  };
  String get currentText => _format(currentBonus);
  String get nextText => _format(nextBonus);

  int _bonus(ProfileData profile) => switch (monument) {
    HarborMonumentId.obsidianObelisk => profile.monumentBonusMaxHp,
    HarborMonumentId.serpentEffigy =>
      ((profile.monumentBountyGoldMultiplier - 1) * 100).round(),
    HarborMonumentId.calderaBrazier =>
      ((profile.monumentWeaponDamageMultiplier - 1) * 100).round(),
  };

  String _format(int bonus) =>
      monument == HarborMonumentId.obsidianObelisk ? '+$bonus HP' : '+$bonus%';
}
