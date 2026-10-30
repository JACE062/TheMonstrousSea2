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
      description: 'Broadside and Signature hits deal +25% damage to Carapace.',
    ),
    BloodlineTraitId.stormSeer: BloodlineTraitLoreEntry(
      name: 'Storm-Seer',
      flavor: 'Reads whitecaps and pressure drops like lines in an open book.',
      description: 'Redraw navigation headings once per region at Set Course.',
    ),
    BloodlineTraitId.ironConstitution: BloodlineTraitLoreEntry(
      name: 'Iron Constitution',
      flavor: 'A constitution weathered by bilge water and foul rations.',
      description: 'Burn and Poison deal 50% less damage to your ship.',
    ),
    BloodlineTraitId.smugglersKin: BloodlineTraitLoreEntry(
      name: "Smuggler's Kin",
      flavor: 'Raised among corsairs, cutthroats, and moonlight brokers.',
      description: 'Choose one free consumable per smuggler encounter. Smuggler hull repairs cost 25% less.',
    ),
    BloodlineTraitId.drillmaster: BloodlineTraitLoreEntry(
      name: 'Drillmaster',
      flavor: 'Demands relentless powder drills and quarterdeck discipline.',
      description: 'Use up to two consumable belt items per turn instead of one.',
    ),
    BloodlineTraitId.preciseCommander: BloodlineTraitLoreEntry(
      name: 'Precise Commander',
      flavor: 'Calls measured firing solutions through the smoke and spray.',
      description: '+5% shot accuracy for Broadside and Signature attacks.',
    ),
    BloodlineTraitId.skilledCarpenter: BloodlineTraitLoreEntry(
      name: 'Skilled Carpenter',
      flavor: 'Knows where sound timber and a patient crew can save a vessel.',
      description: 'All healing is 20% better at restoring hull. Healing modifiers multiply together.',
    ),
    BloodlineTraitId.quartermaster: BloodlineTraitLoreEntry(
      name: 'Quartermaster',
      flavor: 'Keeps every crate lashed tight and every useful supply within reach.',
      description: 'Gain one additional consumable belt slot for this voyage.',
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
      description: '+10% evasion in every battle. Refuses Dead Ahead when other headings exist.',
    ),
    BloodlineTraitId.superstitious: BloodlineTraitLoreEntry(
      name: 'Superstitious',
      flavor: 'Seeks the wardens wherever the omens lead, yet fears their warnings.',
      description: 'Find Shrines more often, but an omen forbids one of two manifested powers.',
    ),
    BloodlineTraitId.exactingShipwright: BloodlineTraitLoreEntry(
      name: 'Exacting Shipwright',
      flavor: 'Demands flawless joinery; even the smallest repair must meet exacting standards.',
      description: 'Take 10% less damage from incoming attacks, but all healing is 25% less effective.',
    ),
    BloodlineTraitId.overzealousGunner: BloodlineTraitLoreEntry(
      name: 'Overzealous Gunner',
      flavor: 'Demands more powder and faster fire, leaving little time to aim.',
      description: 'Broadside and Signature attacks deal +20% weapon damage with -10% shot accuracy.',
    ),
    BloodlineTraitId.daredevil: BloodlineTraitLoreEntry(
      name: 'Daredevil',
      flavor: 'Commands the fiercest attacks when the hull is barely holding together.',
      description: 'Broadside and Signature attacks deal +30% weapon damage while at or below 50% hull.',
    ),
    BloodlineTraitId.impatient: BloodlineTraitLoreEntry(
      name: 'Impatient',
      flavor: 'Demands action now, leaving the crew scrambling to recover.',
      description: 'Push the crew to use Utility then one weapon action before the enemy responds. On the next turn, only helm, belt and Wait & Reload remain usable.',
    ),
    BloodlineTraitId.skirmisher: BloodlineTraitLoreEntry(
      name: 'Skirmisher',
      flavor: 'Strikes from position, then slips away before the answering blow.',
      description: 'Your helm maneuver always resolves after your main action, before the enemy responds.',
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
