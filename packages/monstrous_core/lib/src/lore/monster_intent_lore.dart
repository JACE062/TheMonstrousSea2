/// Centralized lore, descriptions, and tactical tips for telegraphed monster intents.
///
/// Edit this file to customize how monster intentions, warnings, and boss
/// wind-ups are described to the player in the combat UI and chronicle log.
class MonsterIntentLoreEntry {
  const MonsterIntentLoreEntry({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.tacticalTip,
    required this.telegraphLog,
  });

  final String name;
  final String subtitle;
  final String description;
  final String tacticalTip;
  final String telegraphLog;
}

abstract final class MonsterIntentLore {
  static const normalStrike = MonsterIntentLoreEntry(
    name: 'Staggered Strike',
    subtitle: 'Windup Broken • Normal Attack',
    description: 'Its catastrophic windup broken, the beast lashes out with an ordinary strike.',
    tacticalTip:
        'The lethal windup has been canceled. Brace against a normal attack.',
    telegraphLog:
        'reels from the broken windup and prepares an ordinary strike!',
  );

  // ── SHARK INTENTS ──────────────────────────────────────────────────────────

  static const sharkRiptideWake = MonsterIntentLoreEntry(
    name: 'Riptide Wake',
    subtitle: 'Advances 1 Band • Hits Med & Long',
    description: 'The shark slices forward through the swells, throwing a violent pressure wave across distant water.',
    tacticalTip: 'Advances 1 band before striking Medium and Long Range. Fouls gunnery aim (-10% accuracy) on hit.',
    telegraphLog: 'cuts a knifing dorsal wake, preparing to surge forward with a Riptide Wake!',
  );

  static const sharkBreachingLunge = MonsterIntentLoreEntry(
    name: 'Breaching Lunge',
    subtitle: 'Charges 1 Band • Hits Short & Med',
    description: 'The predator coils its tail to launch a high-speed lunging bite that tracks retreating hulls.',
    tacticalTip: 'Closes 1 band before striking Short and Medium Range. Pin with a Harpoon or stun with a Mortar to halt its charge!',
    telegraphLog: 'drops beneath the whitecaps, coiling for a relentless Breaching Lunge!',
  );

  static const sharkFrenziedJaws = MonsterIntentLoreEntry(
    name: 'Frenzied Jaws',
    subtitle: '+1 Frenzy Stack • Hits Short Range',
    description: 'Whipped into a blood frenzy, the shark snaps its serrated jaws at point-blank hulls.',
    tacticalTip: 'Gains +1 Frenzy stack before striking Short Range. Fall back to Medium Range to evade the bite!',
    telegraphLog: 'rolls its eyes back in bloodlust, jaws gaping for a point-blank Frenzied Jaws strike!',
  );

  // ── CRUSTACEAN INTENTS ─────────────────────────────────────────────────────

  static const crustaceanCalcifyCarapace = MonsterIntentLoreEntry(
    name: 'Calcify Carapace',
    subtitle: 'Self-Buff • Restores 35% Carapace',
    description: 'The armored colossus secretes rapid-hardening abyssal lime to seal fractures in its shell.',
    tacticalTip: 'No attack this turn. Restores 35% of maximum Carapace plating and cleanses surface status effects.',
    telegraphLog: 'draws its limbs inward as mineral foam bubbles across its shell to Calcify Carapace!',
  );

  static const crustaceanBrineJet = MonsterIntentLoreEntry(
    name: 'Pressurized Brine Jet',
    subtitle: 'Stationary • Hits Med & Long (Safe at Short)',
    description: 'Fires a scalding, high-pressure stream of corrosive trench brine in a high arc.',
    tacticalTip: 'Hits Medium and Long Range (inflicts Poison/Acid). Advance into Short Range to slip underneath the stream!',
    telegraphLog: 'vents a hissing siphon, aiming a Pressurized Brine Jet across Medium and Long Range!',
  );

  static const crustaceanTremorSlam = MonsterIntentLoreEntry(
    name: 'Tremor Shell-Slam',
    subtitle: 'Stationary • Hits Short & Med',
    description: 'Raises its entire armored bulk and crashes down, sending a concussive shockwave through nearby water.',
    tacticalTip: 'Sweeps both Short and Medium Range, rattling rigging (-15% Evasion). Fall back to Long Range or Fortify!',
    telegraphLog: 'rears its massiveplated bulk above the waterline for a wide Tremor Shell-Slam!',
  );

  static const crustaceanHydraulicGuillotine = MonsterIntentLoreEntry(
    name: 'Hydraulic Guillotine',
    subtitle: 'Stationary • Hits Short Range',
    description: 'Cocks its colossal crushing claw to snap timber and iron plating in half at collision distance.',
    tacticalTip: 'Devastating point-blank damage at Short Range only. Fall back to Medium Range to avoid the pincer!',
    telegraphLog: 'ratchets open its colossal crushing claw for a point-blank Hydraulic Guillotine!',
  );

  // ── JELLYFISH INTENTS ──────────────────────────────────────────────────────

  static const jellyfishArcPulse = MonsterIntentLoreEntry(
    name: 'Arc-Discharge Pulse',
    subtitle: 'Advances 1 Band • Hits Med & Long (Safe at Short)',
    description: 'Pulses forward while discharging an expanding ring of bio-electric voltage across outer waters.',
    tacticalTip: 'Moves 1 band closer and shocks Medium & Long Range. Advance into Short Range to duck inside the outer electric ring!',
    telegraphLog: 'crackles with blinding violet luminescence, charging an outer Arc-Discharge Pulse!',
  );

  static const jellyfishNematocystCurtain = MonsterIntentLoreEntry(
    name: 'Nematocyst Curtain',
    subtitle: 'Stationary • Hits Short & Med',
    description: 'Fans out a forty-foot web of venomous stinging filaments across close and broadside waters.',
    tacticalTip: 'Hits Short and Medium Range (inflicts Poison). Fall back to Long Range to clear the stinging net!',
    telegraphLog: 'unfurls a wide, drifting lattice of glowing tendrils for a Nematocyst Curtain!',
  );

  static const jellyfishNeurotoxinEmbrace = MonsterIntentLoreEntry(
    name: 'Neurotoxin Embrace',
    subtitle: 'Stationary • Hits Short Range + Shocks Mount',
    description: 'Wraps point-blank hulls in high-voltage tendrils that paralyze gun crews and foul firing locks.',
    tacticalTip: 'Hits Short Range only and delays a ready weapon mount by +1 turn. Step back to Medium Range to evade!',
    telegraphLog: 'draws its inner bell tentacles tight for a point-blank Neurotoxin Embrace!',
  );

  // ── SERPENT INTENTS ────────────────────────────────────────────────────────

  static const serpentAbyssalUnderStrike = MonsterIntentLoreEntry(
    name: 'Abyssal Under-Strike',
    subtitle: 'Unavoidable Ambush • Sets Range to Short',
    description: 'Having slipped into distant waters, the serpent dives straight into the trench to erupt directly beneath your keel.',
    tacticalTip: 'UNAVOIDABLE BY HELM! Erupts at Short Range regardless of movement. Use Fortify, Evasive Veer, or Stun to survive!',
    telegraphLog: 'vanishes vertically into the black trench—preparing an unavoidable Abyssal Under-Strike from below!',
  );

  static const serpentVenomSpitRecoil = MonsterIntentLoreEntry(
    name: 'Venomous Spit-Volley',
    subtitle: 'Hits Med & Long • Retreats 1 Band After',
    description: 'Hurls globules of blinding neuro-venom across outer ranges before slithering backward into the mist.',
    tacticalTip: 'Hits Medium & Long Range (Safe at Short), then retreats 1 band farther and gains +20% Evasion. Chase or Harpoon it!',
    telegraphLog: 'flares its hood and hisses, preparing a Venomous Spit-Volley before recoiling!',
  );

  static const serpentFangedWhipRecoil = MonsterIntentLoreEntry(
    name: 'Fanged Whip-Recoil',
    subtitle: 'Hits Short & Med • Retreats 1 Band After',
    description: 'Lashes across close waters with fangs bared, using the recoil to slip one range band away.',
    tacticalTip: 'Hits Short & Medium Range, then retreats 1 band farther. Pin with a Harpoon Winch to prevent its retreat!',
    telegraphLog: 'coils like a spring, poising for a Fanged Whip-Recoil to strike and slip away!',
  );

  // ── SQUID INTENTS ──────────────────────────────────────────────────────────

  static const squidFeedingTentacleSnare = MonsterIntentLoreEntry(
    name: 'Feeding Tentacle Snare',
    subtitle: 'Hits Med & Long • Reels Ship 1 Band Closer',
    description: 'Shoots its two whip-like feeding clubs across long water to latch onto the hull and drag the ship inward.',
    tacticalTip:
        'Strikes Medium & Long Range and drags your ship 1 band closer on hit!',
    telegraphLog: 'aims its two elongated feeding clubs to whip out a Feeding Tentacle Snare!',
  );

  static const squidSweepingTentacles = MonsterIntentLoreEntry(
    name: 'Sweeping Tentacles',
    subtitle: 'Stationary • Hits Short & Med',
    description: 'Thrashes all intact arms in a violent broadside sweep that batters close and mid-range vessels.',
    tacticalTip: 'Multi-hit sweep across Short and Medium Range. Sever tentacles with Slicing weapons or retreat to Long Range!',
    telegraphLog: 'raises its writhing crown of arms for a broadside Sweeping Tentacles thrash!',
  );

  static const squidConstrictingBeak = MonsterIntentLoreEntry(
    name: 'Constricting Beak',
    subtitle: 'Stationary • Hits Short + Grapples Helm',
    description: 'Latches onto the hull at point-blank range, gouging timbers with its chitinous beak and locking the rudder.',
    tacticalTip: 'Hits Short Range only. On hit, Grapples the ship for 1 round (locks Helm Order to Hold Line)!',
    telegraphLog: 'spreads its barbed arms at point-blank range to latch on with a Constricting Beak!',
  );

  static const squidInkShroudRecoil = MonsterIntentLoreEntry(
    name: 'Ink-Shroud Lash',
    subtitle: 'Hits Short & Med • Cloaks in Ink & Retreats',
    description: 'Whips the hull while jetting backward in a blinding cloud of abyssal ink.',
    tacticalTip: 'Hits Short & Medium Range, cloaks the beast in Obscuring Ink, and retreats 1 band farther.',
    telegraphLog: 'pressurizes its mantle siphon, preparing an Ink-Shroud Lash to blind and retreat!',
  );

  // ── BOSS CATASTROPHE WIND-UPS (2-TURN) ─────────────────────────────────────

  static const bossKrakenWindup = MonsterIntentLoreEntry(
    name: 'Maelstrom Crush (Wind-Up 1/2)',
    subtitle: 'Gathering Power • No Strike This Turn',
    description: 'The Kraken raises all colossal limbs forty feet above the waves as a whirlpool forms beneath the ship.',
    tacticalTip: '2-TURN BOSS WIND-UP! Strikes ALL RANGES next turn. Disrupt with Heavy Mortar, Harpoon Winch, Black-Powder Charge, or Stun!',
    telegraphLog: 'heaves its titanic bulk skyward—initiating a 2-turn wind-up for Maelstrom Crush!',
  );

  static const bossKrakenCatastrophe = MonsterIntentLoreEntry(
    name: 'Maelstrom Crush (IMMINENT 2/2)',
    subtitle: 'STRIKES ALL RANGES THIS TURN!',
    description: 'Towering tentacles descend across the entire sea lane in an inescapable cataclysm of foam and timber.',
    tacticalTip: 'HITS ALL RANGES THIS TURN! Interrupt with Heavy Mortar, Harpoon Winch, Black-Powder Charge, or brace for impact!',
    telegraphLog: 'roars from the abyss—Maelstrom Crush will strike ALL RANGES at the end of this turn!',
  );

  static const bossWorldSerpentWindup = MonsterIntentLoreEntry(
    name: 'Tidal Coil Maelstrom (Wind-Up 1/2)',
    subtitle: 'Gathering Power • No Strike This Turn',
    description: 'The World Serpent encircles the entire horizon, spinning the sea into a suffocating, corrosive funnel.',
    tacticalTip: '2-TURN BOSS WIND-UP! Strikes ALL RANGES next turn. Interrupt with Heavy Mortar, Harpoon Winch, Black-Powder Charge, or Stun!',
    telegraphLog: 'encircles the entire sea lane in mile-long coils—winding up Tidal Coil Maelstrom!',
  );

  static const bossWorldSerpentCatastrophe = MonsterIntentLoreEntry(
    name: 'Tidal Coil Maelstrom (IMMINENT 2/2)',
    subtitle: 'STRIKES ALL RANGES THIS TURN!',
    description: 'The constricting whirlpool collapses inward, crushing everything on the surface in venomous brine.',
    tacticalTip: 'HITS ALL RANGES THIS TURN! Interrupt with Heavy Mortar, Harpoon Winch, Black-Powder Charge, or brace for impact!',
    telegraphLog: 'tightens its horizon-spanning coils—Tidal Coil Maelstrom strikes ALL RANGES this turn!',
  );

  static const bossLeviathanWindup = MonsterIntentLoreEntry(
    name: 'Caldera Superheat (Wind-Up 1/2)',
    subtitle: 'Gathering Power • No Strike This Turn',
    description: 'The Ancient Leviathan inhales boiling magma from the trench floor, its dorsal plates glowing white-hot.',
    tacticalTip: '2-TURN BOSS WIND-UP! Strikes ALL RANGES next turn. Interrupt with Heavy Mortar, Harpoon Winch, Black-Powder Charge, or Stun!',
    telegraphLog: 'parts its volcanic dorsal vents, drawing in trench magma for Caldera Superheat!',
  );

  static const bossLeviathanCatastrophe = MonsterIntentLoreEntry(
    name: 'Caldera Superheat (IMMINENT 2/2)',
    subtitle: 'STRIKES ALL RANGES THIS TURN!',
    description: 'Unleashes a horizon-spanning eruption of superheated steam and molten slag across the entire reach.',
    tacticalTip: 'HITS ALL RANGES THIS TURN! Interrupt with Heavy Mortar, Harpoon Winch, Black-Powder Charge, or Fortify!',
    telegraphLog: 'glows blinding white—Caldera Superheat will scorch ALL RANGES at the end of this turn!',
  );
}
