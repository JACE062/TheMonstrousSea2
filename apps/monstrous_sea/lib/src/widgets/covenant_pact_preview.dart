import 'package:monstrous_core/monstrous_core.dart';

/// The selected toggle's effects, burden and changed rewards, without ratifying it.
class CovenantPactPreview {
  CovenantPactPreview(ProfileData profile, this.pact) {
    isActive = profile.isPactActive(pact);
    canToggle = profile.hasUnlockedCovenant;
    currentBurden = profile.totalPactBurden;
    final after = ProfileData.fromJson(profile.toJson())..togglePact(pact);
    nextBurden = after.totalPactBurden;
    final targetActive = !isActive;
    stats = List.unmodifiable([
      switch (pact) {
        CovenantPactId.abyssalVigor => _stat(
          'hp',
          'Monster maximum HP bonus',
          _bonus(isActive, CovenantPactEffects.monsterHpMultiplier),
          _bonus(targetActive, CovenantPactEffects.monsterHpMultiplier),
        ),
        CovenantPactId.calcifiedCarapace => _stat(
          'carapace',
          'Added monster Carapace',
          '${isActive ? CovenantPactEffects.extraCarapace : 0}',
          '${targetActive ? CovenantPactEffects.extraCarapace : 0}',
        ),
        CovenantPactId.chokingFog => _stat(
          'lookout',
          'Unrevealed lookout calls',
          isActive ? 'Obscured' : 'Clear',
          targetActive ? 'Obscured' : 'Clear',
        ),
        CovenantPactId.apexEmergence => _stat(
          'apex',
          'Eligible Apex chance multiplier',
          '${CovenantPactEffects.apexChanceMultiplier(isActive)}.00x',
          '${CovenantPactEffects.apexChanceMultiplier(targetActive)}.00x',
        ),
        CovenantPactId.feedingFrenzy => _stat(
          'attack',
          'Monster attack damage bonus',
          _bonus(isActive, CovenantPactEffects.monsterAttackMultiplier),
          _bonus(targetActive, CovenantPactEffects.monsterAttackMultiplier),
        ),
        CovenantPactId.brittleOak => _stat(
          'healing',
          'Careening / timber healing',
          _percentage(
            isActive ? CovenantPactEffects.shoreHealingMultiplier : 1,
          ),
          _percentage(
            targetActive ? CovenantPactEffects.shoreHealingMultiplier : 1,
          ),
        ),
        CovenantPactId.volatileEnvirons => _stat(
          'kelp',
          'Sargasso kelp evasion penalty',
          '-${CovenantPactEffects.kelpEvasionPenalty(isActive)}%',
          '-${CovenantPactEffects.kelpEvasionPenalty(targetActive)}%',
        ),
      },
      if (pact == CovenantPactId.feedingFrenzy)
        _stat(
          'frenzy',
          'Automatic Shark Frenzy',
          isActive
              ? '${_percentage(CovenantPactEffects.automaticSharkFrenzyThreshold)} HP or less'
              : 'Off',
          targetActive
              ? '${_percentage(CovenantPactEffects.automaticSharkFrenzyThreshold)} HP or less'
              : 'Off',
        ),
      if (pact == CovenantPactId.brittleOak)
        _stat(
          'repairs',
          'Shipwright repair surcharge',
          _bonus(isActive, CovenantPactEffects.shipwrightRepairPriceMultiplier),
          _bonus(
            targetActive,
            CovenantPactEffects.shipwrightRepairPriceMultiplier,
          ),
        ),
      if (pact == CovenantPactId.volatileEnvirons) ...[
        _stat(
          'scald-damage',
          'Boiling Reach scald damage',
          '${CovenantPactEffects.scaldDamage(isActive)} HP',
          '${CovenantPactEffects.scaldDamage(targetActive)} HP',
        ),
        _stat(
          'scald-interval',
          'Scald interval',
          '${CovenantPactEffects.scaldInterval(isActive)} turns',
          '${CovenantPactEffects.scaldInterval(targetActive)} turns',
        ),
      ],
      _stat('burden', 'Total Pact Burden', '$currentBurden', '$nextBurden'),
      for (final titan in [
        MonsterSpecies.kraken,
        MonsterSpecies.worldSerpent,
        MonsterSpecies.ancientLeviathan,
      ])
        if (CovenantPactEffects.titanCinders(titan, currentBurden) !=
            CovenantPactEffects.titanCinders(titan, nextBurden))
          _stat(
            'cinders-${titan.name}',
            switch (titan) {
              MonsterSpecies.kraken => 'Kraken Cinders',
              MonsterSpecies.worldSerpent => 'World Serpent Cinders',
              _ => 'Leviathan Cinders',
            },
            '${CovenantPactEffects.titanCinders(titan, currentBurden)}',
            '${CovenantPactEffects.titanCinders(titan, nextBurden)}',
          ),
    ]);
  }

  final CovenantPactId pact;
  late final bool isActive;
  late final bool canToggle;
  late final int currentBurden;
  late final int nextBurden;
  late final List<PactEffectComparison> stats;
  CovenantPact get definition => CovenantPact.catalog[pact]!;

  static String _percentage(num value) => '${(value * 100).round()}%';
  static String _bonus(bool active, double multiplier) =>
      '+${active ? ((multiplier - 1) * 100).round() : 0}%';
  static PactEffectComparison _stat(
    String id,
    String label,
    String current,
    String next,
  ) => PactEffectComparison(id: id, label: label, current: current, next: next);
}

class PactEffectComparison {
  const PactEffectComparison({
    required this.id,
    required this.label,
    required this.current,
    required this.next,
  });
  final String id;
  final String label;
  final String current;
  final String next;
}
