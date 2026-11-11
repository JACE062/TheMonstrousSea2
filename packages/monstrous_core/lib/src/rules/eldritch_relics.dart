import '../model/covenant_of_the_deep.dart';
import '../model/enums.dart';

/// Added signature effects shared by combat and home-port forge previews.
class EldritchRelicEffects {
  const EldritchRelicEffects({
    this.fleshHealingFraction = 0,
    this.ignoresObscurity = false,
    this.shockDamage = 0,
    this.inflictedStatus,
  });

  final double fleshHealingFraction;
  final bool ignoresObscurity;
  final int shockDamage;
  final StatusEffect? inflictedStatus;

  static const siphonRam = EldritchRelicEffects(fleshHealingFraction: 0.30);
  static const ghostwakeCulverin = EldritchRelicEffects(
    ignoresObscurity: true,
    shockDamage: 8,
  );
  static const brimstoneMortar = EldritchRelicEffects(
    inflictedStatus: StatusEffect.burn,
  );
  static const sinewWinch = EldritchRelicEffects(
    inflictedStatus: StatusEffect.poison,
  );

  static EldritchRelicEffects forRelic(EldritchRelicId id) => switch (id) {
    EldritchRelicId.siphonRam => siphonRam,
    EldritchRelicId.ghostwakeCulverin => ghostwakeCulverin,
    EldritchRelicId.brimstoneMortar => brimstoneMortar,
    EldritchRelicId.sinewWinch => sinewWinch,
  };
}
