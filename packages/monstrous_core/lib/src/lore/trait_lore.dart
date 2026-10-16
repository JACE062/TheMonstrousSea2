import '../model/bloodline_trait.dart';

/// Centralized lexicon for human Captain Boons, Quirks, and Heir naming tables.
class BloodlineTraitLoreEntry {
  const BloodlineTraitLoreEntry({
    required this.name,
    required this.flavor,
    required this.description,
  });

  final String name;
  final String flavor;
  final String description;
}

class TraitLore {
  const TraitLore._();

  // --- Ancestral Boons ---

  static const boons = <BloodlineTraitId, BloodlineTraitLoreEntry>{
    BloodlineTraitId.veteranCannoneer: BloodlineTraitLoreEntry(
      name: 'Veteran Cannoneer',
      flavor: 'A seasoned eye for structural weak points and armor fissures.',
      description: 'Blast and Piercing attacks ignore 20% of monster Carapace plating.',
    ),
    BloodlineTraitId.stormSeer: BloodlineTraitLoreEntry(
      name: 'Storm-Seer',
      flavor: 'Reads whitecaps and pressure drops like lines in an open book.',
      description: 'Navigating through high gales restores +10 ship HP instead of risking drift damage.',
    ),
    BloodlineTraitId.ironConstitution: BloodlineTraitLoreEntry(
      name: 'Iron Constitution',
      flavor: 'A constitution weathered by bilge water and foul rations.',
      description: 'Poison and Burn status effects have double the wear-off chance each turn (50% vs 25%).',
    ),
    BloodlineTraitId.smugglersKin: BloodlineTraitLoreEntry(
      name: "Smuggler's Kin",
      flavor: 'Raised among corsairs, cutthroats, and moonlight brokers.',
      description: 'Smuggler Ketches offer 1 free contraband consumable, and prices are discounted by 25%.',
    ),
    BloodlineTraitId.drillmaster: BloodlineTraitLoreEntry(
      name: 'Drillmaster',
      flavor: 'Demands relentless powder drills and quarterdeck discipline.',
      description: "Using a consumable item does not end the ship's combat turn.",
    ),
  };

  // --- Curious Quirks ---

  static const quirks = <BloodlineTraitId, BloodlineTraitLoreEntry>{
    BloodlineTraitId.bloodOath: BloodlineTraitLoreEntry(
      name: 'Blood Oath (Vendetta)',
      flavor: 'A burning hatred for the beast that claimed their predecessor.',
      description: "Deals +30% damage to the parent's Nemesis. Compels the wheel: heading locks onto the Nemesis when it appears.",
    ),
    BloodlineTraitId.recklessHelmsman: BloodlineTraitLoreEntry(
      name: 'Reckless Helmsman',
      flavor: 'Despises a calm, steady course; only lives in hard turns.',
      description: '"Dead Ahead" heading is disabled at sea; steering Port or Starboard grants +10% evasion.',
    ),
    BloodlineTraitId.superstitious: BloodlineTraitLoreEntry(
      name: 'Superstitious',
      flavor: 'Refuses to tamper with blasphemous runes or dark sea gods.',
      description: 'Refuses to enter Abyssal Pacts at Shrines; completely immune to Siren charms, confusion, and fear.',
    ),
    BloodlineTraitId.saltAddict: BloodlineTraitLoreEntry(
      name: 'Pernicious Salt-Addict',
      flavor: 'Driven by the thrill of blood on brine, heedless of pain.',
      description: 'Weapon damage dealt increased by +15%; all restorative healing and careening are 25% less effective.',
    ),
    BloodlineTraitId.overzealousGunner: BloodlineTraitLoreEntry(
      name: 'Overzealous Gunner',
      flavor: 'Refuses to fire single shots; demands total devastating broadsides.',
      description: 'Single-weapon firing is disabled; only full volleys can be fired (volleys deal +15% bonus damage).',
    ),
  };

  // --- Heir Naming Lore ---

  static const firstNames = <String>[
    'Alistair',
    'Barnaby',
    'Cordelia',
    'Caspian',
    'Darius',
    'Eleanor',
    'Gideon',
    'Helena',
    'Jasper',
    'Morrigan',
    'Peregrine',
    'Rowan',
    'Silas',
    'Theodora',
    'Valerian',
  ];

  static const epithets = <String>[
    'the Salt-Bitten',
    'the Iron-Eyed',
    'the Restless',
    'the Tide-Walker',
    'the Deep-Gazer',
    'the Unbroken',
    'the Storm-Born',
    'the Vengeful',
  ];
}
