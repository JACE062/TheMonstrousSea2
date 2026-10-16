import '../model/enums.dart';

/// Lore and descriptive entries for ship armaments, monster weapons, and consumables.
///
/// Modifying this file changes all player-facing weapon descriptions, flavor quotes,
/// and tactical guidance without altering combat math.
class ShipWeaponLoreEntry {
  const ShipWeaponLoreEntry({
    required this.name,
    required this.description,
    required this.flavorQuote,
    required this.tacticalTip,
  });

  final String name;
  final String description;
  final String flavorQuote;
  final String tacticalTip;
}

class MonsterWeaponLoreEntry {
  const MonsterWeaponLoreEntry({
    required this.name,
    required this.description,
    required this.telegraphWarning,
  });

  final String name;
  final String description;
  final String telegraphWarning;
}

class ConsumableLoreEntry {
  const ConsumableLoreEntry({
    required this.name,
    required this.description,
    required this.flavorUse,
  });

  final String name;
  final String description;
  final String flavorUse;
}

class WeaponLore {
  const WeaponLore._();

  // --- Ship Armaments ---

  static const ship = <ShipWeaponType, ShipWeaponLoreEntry>{
    ShipWeaponType.cannon: ShipWeaponLoreEntry(
      name: 'Standard Broadside Cannon',
      description:
          'A reliable cast-iron smoothbore cannon firing lead-alloy solid shot.',
      flavorQuote: 'The steady heartbeat of naval warfare. Loud, smoky, and honest.',
      tacticalTip:
          'Universal workhorse. Suffer -15% accuracy at Long Range; best deployed at Medium or Short.',
    ),
    ShipWeaponType.prowRam: ShipWeaponLoreEntry(
      name: 'Reinforced Prow Ram',
      description:
          'A massive forged-iron battering beak bolted directly to the ship’s keel.',
      flavorQuote: 'When all powder is spent, the ship itself becomes the cannonball.',
      tacticalTip:
          'Cannot attack from Long Range. Surges forward on impact, dealing +30% collision damage at Short Range.',
    ),
    ShipWeaponType.precisionCulverin: ShipWeaponLoreEntry(
      name: 'Precision Culverin',
      description:
          'A slender, rifled long gun designed for pinpoint accuracy at extreme range.',
      flavorQuote: 'A needle through sea mist, finding the soft tendon beneath the plate.',
      tacticalTip:
          'Deals +25% bonus damage at Long Range. Bypasses 50% of monster Carapace plating.',
    ),
    ShipWeaponType.heavyMortar: ShipWeaponLoreEntry(
      name: 'Heavy Siege Mortar',
      description:
          'A stubby, high-angle naval bombard that lofts explosive hollow shells over waves.',
      flavorQuote: 'A thunderous arc that falls like a dying star.',
      tacticalTip:
          'Deals +25% damage at Long Range and shatters Carapace (+50%). Beware: point-blank fire at Short Range risks 20% self-splash backfire.',
    ),
    ShipWeaponType.harpoonWinch: ShipWeaponLoreEntry(
      name: 'Harpoon Winch',
      description:
          'Steam-assisted pneumatic winch launching heavy barbed steel tethers.',
      flavorQuote: 'Drive the barb deep and let the steam engine haul the titan in.',
      tacticalTip:
          'Fires from Long or Medium Range. Reels the quarry 1 range band closer upon impact and pins monster charges.',
    ),
    ShipWeaponType.torpedoLauncher: ShipWeaponLoreEntry(
      name: 'Sub-Surface Torpedo Launcher',
      description:
          'Pneumatic keel tubes launching compressed-air explosive torpedoes beneath the waterline.',
      flavorQuote: 'A trailing bubble wake, then an underwater upheaval.',
      tacticalTip:
          'High blast damage that cracks carapace plates and breaches submerged hulls.',
    ),
    ShipWeaponType.bladeLauncher: ShipWeaponLoreEntry(
      name: 'Whirling Blade Launcher',
      description:
          'Spring-loaded rotary dispenser hurling spinning tempered steel circular sawblades.',
      flavorQuote: 'Hissing razor discs that shear flesh and sever grasping limbs.',
      tacticalTip:
          'Slicing damage severs kraken and squid tentacles, permanently diminishing enemy attack batteries.',
    ),
    ShipWeaponType.lightningRailgun: ShipWeaponLoreEntry(
      name: 'Lightning Railgun',
      description:
          'Twin phosphor-electrified rails that discharge arcs of galvanic current through seawater.',
      flavorQuote: 'A blinding crack of blue thunder that seizes nerve and muscle.',
      tacticalTip:
          'Shock damage completely disrupts shark feeding frenzies and inflicts Stun.',
    ),
    ShipWeaponType.flamethrower: ShipWeaponLoreEntry(
      name: 'Greek Fire Siphon',
      description:
          'Pressurized brass siphon projecting inextinguishable naphtha flames across the waves.',
      flavorQuote: 'Fuel, ignition, and an inferno that even seawater cannot quench.',
      tacticalTip:
          'Deals continuous Burn damage that bypasses carapace armor and cooks monsters over time.',
    ),
  };

  // --- Monster Weaponry ---

  static const monster = <MonsterWeaponType, MonsterWeaponLoreEntry>{
    MonsterWeaponType.ram: MonsterWeaponLoreEntry(
      name: 'Colossal Body Slam',
      description:
          'The beast lowers its massive mass, surging through the waves to ram the flagship.',
      telegraphWarning:
          'The beast lowers its bulk, churning whitecaps as it readies a massive headlong charge!',
    ),
    MonsterWeaponType.tail: MonsterWeaponLoreEntry(
      name: 'Sweeping Tail Thrash',
      description:
          'A muscular muscular tail whip capable of shattering gunwales and throwing crew.',
      telegraphWarning:
          'A titan fin coils beneath the stern, coiling for a crushing lateral sweep!',
    ),
    MonsterWeaponType.jaws: MonsterWeaponLoreEntry(
      name: 'Crushing Leviathan Jaws',
      description:
          'Concentric rows of serrated fossil teeth snapping shut with hydraulic force.',
      telegraphWarning:
          'The abyssal maw unhinges beneath the keel, revealing rows of glistening, jagged fangs!',
    ),
    MonsterWeaponType.claw: MonsterWeaponLoreEntry(
      name: 'Pincer Cleaver',
      description:
          'Enormous chitinous pincers capable of severing oak masts and shearing anchor chains.',
      telegraphWarning:
          'Heavy calcified claws snap open above the surf, seeking to scissor through timber!',
    ),
    MonsterWeaponType.tentacle: MonsterWeaponLoreEntry(
      name: 'Grasping Tentacle Lash',
      description:
          'A barbed sucker-lined tentacle slamming onto the deck to drag sailors into the deep.',
      telegraphWarning:
          'Muscular tendrils break the foam, twisting to ensnare the mainmast and drag the hull down!',
    ),
    MonsterWeaponType.stingingTendrils: MonsterWeaponLoreEntry(
      name: 'Volcanic Stinging Tendrils',
      description:
          'Translucent venom-filled filaments discharging caustic toxins and bio-electric shocks.',
      telegraphWarning:
          'Bioluminescent filaments drift under the keel, glowing with searing paralytic current!',
    ),
  };

  // --- Combat Consumables ---

  static const consumables = <ConsumableType, ConsumableLoreEntry>{
    ConsumableType.unstableTincture: ConsumableLoreEntry(
      name: 'Unstable Tincture',
      description:
          'An iridescent glass vial of volatile abyssal brine that boils violently when exposed to air.',
      flavorUse:
          'Shatters against the beast’s flank, releasing unpredictable corrosive fumes (Burn, Poison, or Stun).',
    ),
    ConsumableType.blastPack: ConsumableLoreEntry(
      name: 'Demolition Blast Pack',
      description:
          'A waterproof bundle of black powder and sulfur strapped to an iron grapple hook.',
      flavorUse:
          'Hurled onto the creature’s carapace, detonating with concussive force to blow away armor plating.',
    ),
    ConsumableType.chakram: ConsumableLoreEntry(
      name: 'Razor Chakram',
      description:
          'A balanced disc of razor-honed tempered steel notched to catch on flesh and sinew.',
      flavorUse:
          'Flung with deadly precision across the deck, slicing cleanly through grasping limbs and tentacles.',
    ),
  };
}
