import '../model/covenant_of_the_deep.dart';

/// Centralized lexicon for Eldritch endgame content: Covenant Pacts, Relic Weapons,
/// Harbor Monuments, and Caldera Climax narrative choices.
class CovenantPactLoreEntry {
  const CovenantPactLoreEntry({
    required this.name,
    required this.flavor,
    required this.effectDescription,
  });

  final String name;
  final String flavor;
  final String effectDescription;
}

class EldritchRelicLoreEntry {
  const EldritchRelicLoreEntry({
    required this.name,
    required this.description,
    required this.effectSummary,
  });

  final String name;
  final String description;
  final String effectSummary;
}

class HarborMonumentLoreEntry {
  const HarborMonumentLoreEntry({
    required this.name,
    required this.subtitle,
    required this.bonusPerRankDescription,
  });

  final String name;
  final String subtitle;
  final String bonusPerRankDescription;
}

class CalderaClimaxLoreEntry {
  const CalderaClimaxLoreEntry({
    required this.displayName,
    required this.promptTitle,
    required this.narrativeOutcome,
  });

  final String displayName;
  final String promptTitle;
  final String narrativeOutcome;
}

class EldritchLore {
  const EldritchLore._();

  // --- Caldera Climax Choices ---

  static const calderaClimax = <CalderaClimaxChoice, CalderaClimaxLoreEntry>{
    CalderaClimaxChoice.shatterCore: CalderaClimaxLoreEntry(
      displayName: 'Shatter the Core',
      promptTitle: 'Break the Leviathan Core within the Abyssal Font',
      narrativeOutcome:
          'With a deafening detonation, you cast the Leviathan Core into the incandescent rift. '
          'The primordial birthplace of leviathans collapses in fire and steam, curing the generational '
          'salt-sickness and bringing peace to the bloodline at last.',
    ),
    CalderaClimaxChoice.claimCore: CalderaClimaxLoreEntry(
      displayName: 'Claim the Core',
      promptTitle: 'Bind the Leviathan Core into the flagship’s living keel',
      narrativeOutcome:
          'Deep-sea madness whispers sweet promises in your mind. You hoist the throbbing, bioluminescent '
          'organ and bolt it to the keel timbers. The flagship hums with dark power. Returning to port, '
          'the ancient covenant altar awakens—welcoming you into the endless abyss.',
    ),
  };

  // --- Covenant Pacts ---

  static const pacts = <CovenantPactId, CovenantPactLoreEntry>{
    CovenantPactId.abyssalVigor: CovenantPactLoreEntry(
      name: 'Abyssal Vigor',
      flavor: 'Beasts gorge upon hydrothermal nutrients rising from the rift.',
      effectDescription: 'All sea monsters have +25% Max HP.',
    ),
    CovenantPactId.calcifiedCarapace: CovenantPactLoreEntry(
      name: 'Calcified Carapace',
      flavor: 'Mineral-rich vents encrust every creature in stone-hard plates.',
      effectDescription: 'All sea monsters gain +10 Carapace plating.',
    ),
    CovenantPactId.feedingFrenzy: CovenantPactLoreEntry(
      name: 'Feeding Frenzy',
      flavor: 'The scent of ancestral blood drives the deep into a rabid fury.',
      effectDescription:
          'Monsters deal +15% attack damage; Shark frenzy triggers at 60% HP instead of 40%.',
    ),
    CovenantPactId.chokingFog: CovenantPactLoreEntry(
      name: 'Choking Fog',
      flavor: 'Thick bioluminescent vapor blankets the shipping lanes.',
      effectDescription:
          'Lookout calls on dead-reckoning headings are muffled and obscured by fog.',
    ),
    CovenantPactId.brittleOak: CovenantPactLoreEntry(
      name: 'Brittle Oak',
      flavor: 'Corrosive abyssal brine seeps into the flagship’s planking.',
      effectDescription:
          'Careening and resting restore 25% less HP; Port repairs cost +30% more gold.',
    ),
    CovenantPactId.volatileEnvirons: CovenantPactLoreEntry(
      name: 'Volatile Environs',
      flavor: 'The ocean itself rebels against the bloodbound keel.',
      effectDescription:
          'Sargasso kelp drag doubles (-20% evasion); Boiling Reach scald deals 15 damage every 2 rounds.',
    ),
    CovenantPactId.apexEmergence: CovenantPactLoreEntry(
      name: 'Apex Emergence',
      flavor: 'Ancient terrors abandon the trenches to stalk the surface.',
      effectDescription:
          'Non-boss encounters have double the chance (50%) to spawn as Apex beasts.',
    ),
  };

  // --- Post-Loop Eldritch Relics ---

  static const relics = <EldritchRelicId, EldritchRelicLoreEntry>{
    EldritchRelicId.siphonRam: EldritchRelicLoreEntry(
      name: 'Abyssal Siphon Ram',
      description:
          'A jagged prow forged from hollow leviathan bone that drinks the lifeblood of rammed beasts.',
      effectSummary:
          'Shatters Carapace and heals the flagship for 30% of hull damage dealt.',
    ),
    EldritchRelicId.ghostwakeCulverin: EldritchRelicLoreEntry(
      name: 'Ghostwake Rail-Culverin',
      description:
          'Rifled in cold phosphor bronze, its projectiles phase through mist and arc with abyssal static.',
      effectSummary:
          'Ignores monster Obscurity; critical hits deal +8 bonus Shock damage.',
    ),
    EldritchRelicId.brimstoneMortar: EldritchRelicLoreEntry(
      name: 'Caldera Brimstone Mortar',
      description:
          'Fires hollow shells packed with pressurized hydrothermal sulfur from the world’s rim.',
      effectSummary:
          '2.0x Blast vs Carapace, disrupts frenzy, and inflicts Burn on every hit.',
    ),
    EldritchRelicId.sinewWinch: EldritchRelicLoreEntry(
      name: 'Kraken-Sinew Drag Winch',
      description:
          'Spun from living abyssal tendon that writhes and constricts around its quarry.',
      effectSummary:
          'Severs tentacles and inflicts virulent Poison on the tethered beast.',
    ),
  };

  // --- Harbor Monuments ---

  static const monuments = <HarborMonumentId, HarborMonumentLoreEntry>{
    HarborMonumentId.obsidianObelisk: HarborMonumentLoreEntry(
      name: 'Obsidian Tide-Obelisk',
      subtitle: 'Hums with the endurance of sunken monoliths',
      bonusPerRankDescription: '+5 Max Hull HP per rank',
    ),
    HarborMonumentId.serpentEffigy: HarborMonumentLoreEntry(
      name: 'Idol of the Coiled Deep',
      subtitle: 'Gilded scales glint beneath the harbor lanterns',
      bonusPerRankDescription: '+10% Monster Bounty Gold per rank',
    ),
    HarborMonumentId.calderaBrazier: HarborMonumentLoreEntry(
      name: 'Brazier of the Eternal Rim',
      subtitle: 'Burns with undying hydrothermal cinders',
      bonusPerRankDescription: '+5% Weapon Damage per rank',
    ),
  };
}
