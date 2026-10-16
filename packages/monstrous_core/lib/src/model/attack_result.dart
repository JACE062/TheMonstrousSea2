import 'enums.dart';

/// Data object capturing the granular outcome of an individual attack roll.
class AttackResult {
  AttackResult({
    required this.didHit,
    required this.damage,
    required this.damageType,
    this.shipWeaponType,
    this.statusEffect,
    this.description = '',
    this.nullifiedDamage = 0,
    this.wasEvaded = false,
    this.tentaclesSevered = 0,
    this.carapaceDamaged = 0,
    this.carapaceAbsorbed = 0,
    this.wasCarapaceShattered = false,
    this.disruptedFrenzy = false,
    this.combatRange = CombatRange.medium,
  });

  final bool didHit;
  final int damage;
  final DamageType damageType;
  final ShipWeaponType? shipWeaponType;
  final StatusEffect? statusEffect;
  final CombatRange combatRange;
  String description;
  int nullifiedDamage;
  bool wasEvaded;
  int tentaclesSevered;
  int carapaceDamaged;
  int carapaceAbsorbed;
  bool wasCarapaceShattered;
  bool disruptedFrenzy;

  bool get inflictsStatus => statusEffect != null && didHit;
}
