/// Provisional cargo/risk values from the implementation starting registry.
class WreckCargoProfile {
  const WreckCargoProfile({
    required this.glassMin,
    required this.glassMax,
    required this.ironChance,
    this.ironMax = 1,
    required this.supplyChance,
    required this.goldChance,
    required this.goldMin,
    required this.goldMax,
  });
  final int glassMin,
      glassMax,
      ironChance,
      ironMax,
      supplyChance,
      goldChance,
      goldMin,
      goldMax;
}

class WreckTuning {
  const WreckTuning({
    this.pickedCleanWeight = 35,
    this.uncertainWeight = 40,
    this.clearClueChance = 80,
    this.approachAmbushChance = 10,
    this.uncertainFightChance = 80,
    this.freshFightChance = 90,
    this.shoalsApexChance = 20,
    this.driftApexChance = 35,
    this.reachApexChance = 50,
    this.small = const WreckCargoProfile(
      glassMin: 1,
      glassMax: 2,
      ironChance: 5,
      supplyChance: 35,
      goldChance: 25,
      goldMin: 5,
      goldMax: 12,
    ),
    this.deeper = const WreckCargoProfile(
      glassMin: 2,
      glassMax: 3,
      ironChance: 40,
      supplyChance: 75,
      goldChance: 35,
      goldMin: 10,
      goldMax: 20,
    ),
    this.fresh = const WreckCargoProfile(
      glassMin: 2,
      glassMax: 4,
      ironChance: 55,
      ironMax: 2,
      supplyChance: 90,
      goldChance: 40,
      goldMin: 12,
      goldMax: 25,
    ),
  }) : assert(
         pickedCleanWeight >= 0 &&
             uncertainWeight >= 0 &&
             pickedCleanWeight + uncertainWeight <= 100,
       );
  static const provisional = WreckTuning();
  final int pickedCleanWeight,
      uncertainWeight,
      clearClueChance,
      approachAmbushChance,
      uncertainFightChance,
      freshFightChance;
  final WreckCargoProfile small, deeper, fresh;
  final int shoalsApexChance, driftApexChance, reachApexChance;
  int apexChanceForRegion(int region) => switch (region) {
    0 => shoalsApexChance, 1 => driftApexChance, _ => reachApexChance,
  };
}
