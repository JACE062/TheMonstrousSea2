/// Centralized lexicon for Flagship Blueprints and Hardpoint text.
///
/// Edit this file to modify blueprint names, historical lore descriptions,
/// subtitles, and tactical summaries.
class BlueprintLoreEntry {
  const BlueprintLoreEntry({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.tacticalRole,
  });

  final String name;
  final String subtitle;
  final String description;
  final String tacticalRole;
}

class BlueprintLore {
  const BlueprintLore._();

  static const standard = BlueprintLoreEntry(
    name: 'Blueprint: Standard',
    subtitle: 'The Bloodbound Keel',
    description:
        'The plain, unadorned war-barque. Balanced and dependable, waiting to be shaped by the bloodline.',
    tacticalRole:
        'Balanced baseline hull with cannon batteries and built-in hull and gun-deck braces, set by the crew to take impact and steady the next volley.',
  );

  static const ironclad = BlueprintLoreEntry(
    name: 'Blueprint: Ironclad',
    subtitle: 'The Armored Bulwark',
    description:
        'Bolts thick charcoal-smelted iron plates onto the hull and fits a reinforced ram to the prow.',
    tacticalRole:
        'Absorbs damage with strike-resistant plating; crushes flesh and carapace with its high-impact ram.',
  );

  static const clipper = BlueprintLoreEntry(
    name: 'Blueprint: Clipper',
    subtitle: 'The Evasive Skiff',
    description:
        'Tosses excess deadweight, installing a streamlined entry, cloud of canvas, and precision outrigger culverin.',
    tacticalRole:
        'Evades heavy blows with superior speed; culverin critical hits strike at the seams of a monster\'s Carapace.',
  );

  static const bombardier = BlueprintLoreEntry(
    name: 'Blueprint: Bombardier',
    subtitle: 'The Siege Artillery Barque',
    description:
        'Heavily reinforces deck joists to support a high-trajectory naval mortar and expanded powder magazine.',
    tacticalRole:
        'Shatters carapace with explosive mortar blasts; concussive impact staggers enemy windups.',
  );

  static const corsair = BlueprintLoreEntry(
    name: 'Blueprint: Corsair',
    subtitle: 'The Tactical Scrapper',
    description:
        'Outfits the vessel with heavy rigging winches, tethering cables, and expanded cargo stowage for deckhand contraptions.',
    tacticalRole:
        'Harpoon winches pin beast charges and rip off limbs; deploys floating contact mines and harvests extra spoils.',
  );
}
