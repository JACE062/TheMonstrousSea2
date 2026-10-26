import 'package:monstrous_core/monstrous_core.dart';

/// Base interface defining automated bot decision logic.
abstract class BotStrategy {
  /// Unique identifier of the bot strategy.
  String get name;

  /// Decides and returns the next [Command] to dispatch given [session].
  Command decideNextAction(GameSession session);
}

/// Shared legal decisions for captain-specific turn stages and forced courses.
/// Ordinary strategy decisions remain unchanged when these rules do not apply.
Command? captainTraitAction(GameSession session) {
  if (session.phase == SessionPhase.battle) {
    if (session.isImpatientRecovering) return const BraceForImpact();
    if (session.isImpatientCombinationPending) {
      final ready = session.ship!.equippedWeapons.where((weapon) =>
          weapon.isReady && isWeaponTypeUsableAtRange(weapon.weaponType, session.combatRange)).toList()
        ..sort((a, b) => b.damage.compareTo(a.damage));
      if (ready.isEmpty) throw StateError('Committed combination has no legal weapon action');
      return FireWeaponVolley(ready.first.weaponType);
    }
    if (session.canStartImpatientCombination) {
      return const ExecuteShipSpecialAction(borrowNextAction: true);
    }
  }
  if (session.phase == SessionPhase.helm) {
    final offers = session.seaChart.currentCourseOptions;
    final legal = offers.where((offer) => session.courseRestriction(offer.bearing) == null).toList();
    if (legal.isNotEmpty && legal.length < offers.length) {
      return SteerCourse(legal.first.bearing);
    }
    if (session.canRedrawStormSeerCourses &&
        offers.every((offer) => offer.nodeType == EncounterNodeType.beastCombat)) {
      return const RedrawStormSeerCourses();
    }
  }
  if (session.phase == SessionPhase.smuggler && session.canClaimSmugglerGift &&
      session.smugglerStock.isNotEmpty) return const ClaimSmugglerGift(0);
  return null;
}
