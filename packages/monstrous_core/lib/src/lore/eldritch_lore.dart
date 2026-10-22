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
    required this.consequence,
    required this.narrativeOutcome,
  });

  final String displayName;
  final String promptTitle;
  final String consequence;
  final String narrativeOutcome;
}

class EldritchLore {
  const EldritchLore._();

  static const calderaTitle = 'THE PRIMORDIAL CALDERA';
  static const calderaIntroduction =
      'The Ancient Leviathan sinks beneath the boiling waters. Beyond it, the '
      'Abyssal Font still churns. With the Leviathan Core in your hands, the '
      'fate of your bloodline rests on one final choice.';
  static const claimLedgerCause =
      'Claimed the Leviathan Core; the flagship returned alone';
  static const claimSuccessionTitle = 'THE SHIP RETURNS ALONE';
  static const claimSuccessionSubtitle =
      'The captain claimed the Core. The Bloodbound Ship has returned for an heir, '
      'with a whispering altar in the captain’s quarters.';
  static const huntEndedTitle = 'THE HUNT IS ENDED';
  static const huntEndedMessage =
      'The sea is quiet. The Bloodbound Ship will not return, and your family '
      'is free to remain upon the shore. The curse is broken.';

  // --- Caldera Climax Choices ---

  static const calderaClimax = <CalderaClimaxChoice, CalderaClimaxLoreEntry>{
    CalderaClimaxChoice.shatterCore: CalderaClimaxLoreEntry(
      displayName: 'Shatter the Core',
      promptTitle: 'Use the Leviathan Core to destroy the Abyssal Font',
      consequence:
          'Destroy the Font and break the curse. Captain and flagship will be '
          'lost, but the bloodline’s hunt will end.',
      narrativeOutcome:
          'With a steeled determination, you push forward and cast the Core into the incandescent rift. '
          'The primordial birthplace of leviathans shatters in a deafening detonation, the wailing of an '
          'ancient eldritch being resounding in your head before it abruptly ceases. '
          '\nAs your splintered ship plummets its way into the depths, you feel the curse lifting from you, '
          'the noise of the Sea-Madness finally gone from your mind. '
          'The ship will not return to port this time, but it gives you a sense of relief, '
          'knowing your bloodline, and the Sea, will know peace at last...',
    ),
    CalderaClimaxChoice.claimCore: CalderaClimaxLoreEntry(
      displayName: 'Claim the Core',
      promptTitle: 'Bind the Leviathan Core to the Bloodbound Ship',
      consequence:
          'Preserve the Font and bind its power to the ship. The flagship will '
          'return for another heir, awakening the Covenant of the Deep.',
      narrativeOutcome:
          'The Sea-Madness whispers sweet promises in your mind you cannot ignore. '
          'You hoist the humming, glowing core over your head, before slamming it into the deck. '
          'It fuses to the splintered timbers with a horrible sound, but it integrates perfectly, '
          'the orb looking, strangely, like it was always meant to be there. '
          '\nAs you feel the thrum of dark power from the hull of the flagship, the voice in your head cackles with delight '
          'at what you’ve done, growing louder than ever before... '
          '\n\n'
          'The Bloodbound Ship slowly drifts into port once more, the keel as bare as always, '
          'save for the orb-like altar fused into the wall of the captain’s quarters, humming invitingly...',
    ),
  };

  // --- Covenant Pacts ---

  static const pacts = <CovenantPactId, CovenantPactLoreEntry>{
    CovenantPactId.abyssalVigor: CovenantPactLoreEntry(
      name: 'Abyssal Vigor',
      flavor: 'Beasts gorge upon ancient energies pulsing out from the rift.',
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
      flavor: 'Dark, strange mists blanket the seas.',
      effectDescription:
          'Lookout calls on navigation headings are muffled and obscured by fog.',
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
          'Sargasso kelp drag doubles; Boiling Reach scald deals greater damage, more often.',
    ),
    CovenantPactId.apexEmergence: CovenantPactLoreEntry(
      name: 'Apex Emergence',
      flavor: 'Dark power drives ancient terrors from deep trenches to stalk the surface.',
      effectDescription:
          'Non-boss encounters have double the chance to spawn as Apex beasts.',
    ),
  };

  // --- Post-Loop Eldritch Relics ---

  static const relics = <EldritchRelicId, EldritchRelicLoreEntry>{
    EldritchRelicId.siphonRam: EldritchRelicLoreEntry(
      name: 'Abyssal Siphon Ram',
      description:
          'A jagged prow forged from hollow leviathan bone that drinks lifeblood and dark power from rammed beasts.',
      effectSummary:
          'Shatters Carapace and heals the flagship for 30% of damage dealt to flesh.',
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
          'Fires hollow shells packed with pressurized sulfur from the world’s boiling rim.',
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
      subtitle: 'Burns with sulfurous, undying cinders',
      bonusPerRankDescription: '+5% Weapon Damage per rank',
    ),
  };
}
