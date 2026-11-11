import 'package:monstrous_core/monstrous_core.dart';

/// Permanent tier changes, plus exact damage only for an existing active mount.
class AncestralArmamentPreview {
  AncestralArmamentPreview(
    ProfileData profile,
    this.blueprint, {
    ShipState? activeShip,
  }) : currentTier = profile.armamentTierFor(blueprint) {
    nextTier = currentTier < BlueprintArmamentProgression.maxTier
        ? currentTier + 1
        : null;
    cost = BlueprintArmamentProgression.costForNextTier(currentTier);
    currentMultiplier = BlueprintArmamentProgression.damageMultiplierForTier(
      currentTier,
    );
    nextMultiplier = nextTier == null
        ? null
        : BlueprintArmamentProgression.damageMultiplierForTier(nextTier!);
    mountedDamage = List.unmodifiable([
      if (activeShip?.blueprintId == blueprint.name)
        for (final weapon in activeShip!.equippedWeapons.where(
          (w) => w.isSignature,
        ))
          AncestralDamagePreview(
            name: weapon.weaponType.displayName,
            current: weapon.damage,
            next: nextTier == null
                ? null
                : BlueprintArmamentProgression.damageAfterUpgrade(
                    weapon.damage,
                    currentTier,
                  ),
          ),
    ]);
  }

  final BlueprintId blueprint;
  final int currentTier;
  late final int? nextTier;
  late final MetaCost? cost;
  late final double currentMultiplier;
  late final double? nextMultiplier;
  late final List<AncestralDamagePreview> mountedDamage;
  String get name => blueprint.signatureWeaponType.displayName;
  bool get isMaximum => nextTier == null;
  String get currentMultiplierText =>
      '${currentMultiplier.toStringAsFixed(2)}x';
  String? get nextMultiplierText =>
      nextMultiplier == null ? null : '${nextMultiplier!.toStringAsFixed(2)}x';
}

class AncestralDamagePreview {
  const AncestralDamagePreview({
    required this.name,
    required this.current,
    required this.next,
  });
  final String name;
  final int current;
  final int? next;
}
