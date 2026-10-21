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
          'Optimal 100% damage at Medium Range (85% Short, 65% Long with -15% Accuracy).',
    ),
    ShipWeaponType.heavyCarronade: ShipWeaponLoreEntry(
      name: 'Heavy Carronade Battery',
      description:
          'Short-barreled, large-bore iron smashers engineered to shatter hulls at point-blank range.',
      flavorQuote: 'At fifty paces, iron plate splinters like driftwood.',
      tacticalTip:
          'Optimal 100% damage at Short Range (80% Medium, 35% Long). Pair with Prow Ram charges.',
    ),
    ShipWeaponType.swivelGun: ShipWeaponLoreEntry(
      name: 'Long-Barrel Swivel Battery',
      description:
          'Gimbal-mounted long-barrel batteries that maintain pinpoint elevation across heavy swells.',
      flavorQuote: 'Keep the wind at our quarter and never let the beast within reach.',
      tacticalTip:
          'Maintains 100% damage across both Medium and Long Range (75% at Short).',
    ),
    ShipWeaponType.chainShotBroadside: ShipWeaponLoreEntry(
      name: 'Chain-Shot Broadside',
      description:
          'Twin iron half-balls linked by tempered chain that whirl through the air to shear flesh and limbs.',
      flavorQuote: 'Listen to the chains sing before the tentacles fall.',
      tacticalTip:
          'Optimal 100% Slicing damage at Short Range (85% Medium, 45% Long). Deals +20% damage against Pinned targets.',
    ),
    ShipWeaponType.shrapnelHowitzer: ShipWeaponLoreEntry(
      name: 'Shrapnel Howitzer Battery',
      description:
          'Thick-walled naval howitzers scattering canister loads of slicing iron shrapnel.',
      flavorQuote: 'Sweep the waterline with iron and leave no beast whole.',
      tacticalTip:
          'Optimal 100% Slicing damage at Medium Range (70% Short, 75% Long).',
    ),
    ShipWeaponType.twinChasers: ShipWeaponLoreEntry(
      name: 'Twin Bow Chasers',
      description:
          'Paired long-barreled pursuit guns mounted in the foredeck for disciplined focused volleys.',
      flavorQuote: 'Two shots straight down the keel line before the smoke clears.',
      tacticalTip:
          '1T Cooldown Signature. Optimal 100% damage at Medium Range (75% Short, 90% Long).',
    ),
    ShipWeaponType.prowRam: ShipWeaponLoreEntry(
      name: 'Reinforced Prow Ram',
      description:
          'A massive forged-iron battering ram bolted directly to the ship’s keel.',
      flavorQuote: 'When all powder is spent, the ship itself becomes the cannonball.',
      tacticalTip:
          '1T Cooldown Signature. Unusable at Long Range. Deals 100% Piercing at Short, or 125% kinetic charge damage when lunging from Medium into Short.',
    ),
    ShipWeaponType.precisionCulverin: ShipWeaponLoreEntry(
      name: 'Precision Culverin',
      description:
          'A slender, rifled long gun designed for pinpoint accuracy at extreme range.',
      flavorQuote: 'A needle through sea mist, finding the soft tendon beneath the plate.',
      tacticalTip:
          '1T Cooldown Signature. Optimal 100% damage at Long Range (85% Medium, 40% Short). Pierces 50% of Carapace plating.',
    ),
    ShipWeaponType.heavyMortar: ShipWeaponLoreEntry(
      name: 'Heavy Siege Mortar',
      description:
          'A stubby, high-angle naval bombard that lofts explosive hollow shells over waves.',
      flavorQuote: 'A thunderous arc that falls like a shooting star.',
      tacticalTip:
          '1T Cooldown Signature. Optimal 100% Blast at Long Range (85% Medium) and 2.0x vs Carapace. Point-blank fire at Short Range deals 70% damage with 25% self-splash!',
    ),
    ShipWeaponType.harpoonWinch: ShipWeaponLoreEntry(
      name: 'Harpoon Winch',
      description:
          'Sturdy launcher & winch with heavy barbed steel harpoons.',
      flavorQuote: 'Drive the barbs deep and haul the titan in.',
      tacticalTip:
          '1T Cooldown Signature. Optimal 100% damage at Medium Range (85% Short/Long). Pulls the monster 1 range band closer and inflicts Pinned (1T).',
    ),
    ShipWeaponType.torpedoLauncher: ShipWeaponLoreEntry(
      name: 'Sub-Surface Torpedo Launcher',
      description:
          'Pneumatic keel tubes launching explosive torpedoes beneath the waterline.',
      flavorQuote: 'A trailing bubble wake, then an underwater upheaval.',
      tacticalTip:
          'High blast damage that cracks carapace plates and breaches submerged beasts.',
    ),
    ShipWeaponType.bladeLauncher: ShipWeaponLoreEntry(
      name: 'Whirling Blade Launcher',
      description:
          'Spring-loaded rotary dispenser hurling spinning circular sawblades.',
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
          'A muscular tail whip capable of shattering gunwales and throwing crew.',
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
    ConsumableType.hullPatchKit: ConsumableLoreEntry(
      name: 'Hull Patch Kit',
      description:
          'Pre-fitted oak shoring timbers and pitch ready for emergency combat patching.',
      flavorUse:
          'Quick Action (0T): Braces breached planking mid-battle, immediately restoring 30% of Max Hull HP.',
    ),
    ConsumableType.krakenInkBomb: ConsumableLoreEntry(
      name: 'Bottled Kraken Ink',
      description:
          'A pressurized stoneware jar filled with dense abyssal cephalopod ink and alchemical smoke powder.',
      flavorUse:
          'Quick Action (0T): Shrouds the flagship in an opaque mist, granting +25% Evasion for 1 round.',
    ),
    ConsumableType.alchemicalPitch: ConsumableLoreEntry(
      name: 'Alchemical Pitch Flask',
      description:
          'Volatile naphtha-distilled sea pitch that ignites upon contact with air and cannon flash.',
      flavorUse:
          'Quick Action (0T): Coats your next volley this turn with incendiary pitch (+25% Fire damage & inflicts Burn).',
    ),
    ConsumableType.unstableTincture: ConsumableLoreEntry(
      name: 'Unstable Tincture',
      description:
          'An iridescent glass vial of volatile abyssal brine that boils violently when exposed to air.',
      flavorUse:
          'Shatters against the beast’s flank, releasing unpredictable corrosive fumes (Burn, Poison, or Stun).',
    ),
    ConsumableType.blastPack: ConsumableLoreEntry(
      name: 'Black-Powder Charge',
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
