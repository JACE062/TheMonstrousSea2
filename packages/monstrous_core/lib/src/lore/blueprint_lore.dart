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
    subtitle: 'The Returning Keel',
    description:
        'The plain, unadorned war-barque. Balanced and dependable, waiting to be shaped by the bloodline.',
    tacticalRole:
        'Balanced baseline hull equipped with dual broadside batteries and an auxiliary weapon mount.',
  );

  static const ironclad = BlueprintLoreEntry(
    name: 'Blueprint: Ironclad',
    subtitle: 'The Armored Bulwark',
    description:
        'Bolts thick charcoal-smelted iron plates onto the hull and fits a reinforced ram to the prow.',
    tacticalRole:
        'Absorbs multi-hit strikes with damage thresholding; crushes carapace with momentum-driven kinetic prow strikes.',
  );

  static const clipper = BlueprintLoreEntry(
    name: 'Blueprint: Clipper',
    subtitle: 'The Razor Skiff',
    description:
        'Strikes away excess deadweight, installing a streamlined entry, cloud of canvas, and precision outrigger culverin.',
    tacticalRole:
        'Evades heavy blows with superior speed; surgical critical strikes bypass 50% of monster Carapace plating.',
  );

  static const bombardier = BlueprintLoreEntry(
    name: 'Blueprint: Bombardier',
    subtitle: 'The Siege Artillery Barque',
    description:
        'Heavily reinforces deck joists to support a high-trajectory naval mortar and expanded powder magazine.',
    tacticalRole:
        'Shatters thick armor with explosive mortar blasts (+50% vs Carapace); concussive impact staggers enemy windups.',
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
