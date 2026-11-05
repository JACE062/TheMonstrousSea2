import 'wreck_tuning.dart';
import 'shore_service_tuning.dart';
import 'voyage_economy_tuning.dart';

/// Provisional starting values, distinct from the accepted navigation structure.
/// See docs/design/voyage-economy.md#provisional-implementation-parameters.
/// Inject a different bundle for deterministic comparisons without UI/bot rules.
class NavigationTuning {
  const NavigationTuning({
    this.huntWeight = 68,
    this.wreckWeight = 20,
    this.coveWeight = 3,
    this.ketchWeight = 6,
    this.shrineWeight = 3,
    this.superstitiousExtraShrineWeight = 3,
    this.wrecks = WreckTuning.provisional,
    this.services = ShoreServiceTuning.provisional,
    this.economy = VoyageEconomyTuning.provisional,
  }) : assert(huntWeight >= superstitiousExtraShrineWeight),
       assert(
         wreckWeight >= 0 &&
             coveWeight >= 0 &&
             ketchWeight >= 0 &&
             shrineWeight >= 0,
       ),
       assert(
         huntWeight + wreckWeight + coveWeight + ketchWeight + shrineWeight ==
             100,
       );

  static const provisional = NavigationTuning();

  final int huntWeight;
  final int wreckWeight;
  final int coveWeight;
  final int ketchWeight;
  final int shrineWeight;
  final int superstitiousExtraShrineWeight;
  final WreckTuning wrecks;
  final ShoreServiceTuning services;
  final VoyageEconomyTuning economy;
}
