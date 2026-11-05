/// Provisional recovery/economy starting values, not approved final balance.
class ShoreServiceTuning {
  const ShoreServiceTuning({
    this.havenPaidFraction = 0.25,
    this.refitPaidFraction = 0.40,
    this.ketchPaidFraction = 0.20,
    this.havenCareenFraction = 0.30,
    this.coveCareenFraction = 0.20,
    this.havenForageMin = 8,
    this.havenForageMax = 14,
    this.coveForageMin = 5,
    this.coveForageMax = 10,
    this.drillAccuracy = 10,
    this.goldPerWork = 1,
    this.ketchGoldPerWork = 1.5,
  }) : assert(goldPerWork > 0 && ketchGoldPerWork > 0),
       assert(havenForageMin >= 0 && havenForageMax >= havenForageMin),
       assert(coveForageMin >= 0 && coveForageMax >= coveForageMin);
  static const provisional = ShoreServiceTuning();
  final double havenPaidFraction,
      refitPaidFraction,
      ketchPaidFraction,
      havenCareenFraction,
      coveCareenFraction,
      goldPerWork,
      ketchGoldPerWork;
  final int havenForageMin,
      havenForageMax,
      coveForageMin,
      coveForageMax,
      drillAccuracy;
}
