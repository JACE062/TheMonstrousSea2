import 'enums.dart';

/// Data object capturing the granular outcome of an individual attack roll.
class AttackResult {
  AttackResult({
    required this.didHit,
    required this.damage,
    required this.damageType,
    this.statusEffect,
    this.description = '',
    this.nullifiedDamage = 0,
    this.wasEvaded = false,
    this.tentaclesSevered = 0,
  });

  final bool didHit;
  final int damage;
  final DamageType damageType;
  final StatusEffect? statusEffect;
  String description;
  int nullifiedDamage;
  bool wasEvaded;
  int tentaclesSevered;

  bool get inflictsStatus => statusEffect != null && didHit;
}
