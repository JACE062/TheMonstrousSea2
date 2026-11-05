/// Provisional voyage income and finite trade parameters; not final balance.
class VoyageEconomyTuning {
  const VoyageEconomyTuning({
    this.shoalsGoldMin = 40,
    this.shoalsGoldMax = 50,
    this.driftGoldMin = 55,
    this.driftGoldMax = 70,
    this.reachGoldMin = 70,
    this.reachGoldMax = 90,
    this.apexMultiplier = 1.5,
    this.titanMultiplier = 2,
    this.glassPrice = 15,
    this.ironPrice = 50,
    this.reliableGlassMin = 2,
    this.reliableGlassMax = 4,
    this.reliableIronMin = 1,
    this.reliableIronMax = 2,
    this.ketchGlassChance = 60,
    this.ketchGlassMin = 1,
    this.ketchGlassMax = 3,
    this.ketchIronChance = 25,
  }) : assert(glassPrice > 0 && ironPrice > 0),
       assert(reliableGlassMin > 0 && reliableIronMin > 0),
       assert(
         reliableGlassMax >= reliableGlassMin &&
             reliableIronMax >= reliableIronMin,
       ),
       assert(
         shoalsGoldMax >= shoalsGoldMin &&
             driftGoldMax >= driftGoldMin &&
             reachGoldMax >= reachGoldMin,
       );

  static const provisional = VoyageEconomyTuning();
  final int shoalsGoldMin,
      shoalsGoldMax,
      driftGoldMin,
      driftGoldMax,
      reachGoldMin,
      reachGoldMax;
  final double apexMultiplier, titanMultiplier;
  final int glassPrice,
      ironPrice,
      reliableGlassMin,
      reliableGlassMax,
      reliableIronMin,
      reliableIronMax,
      ketchGlassChance,
      ketchGlassMin,
      ketchGlassMax,
      ketchIronChance;
}
