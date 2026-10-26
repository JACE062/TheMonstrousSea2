import 'package:monstrous_core/monstrous_core.dart';

/// All strategies value an existing dedication's next tier before a new socket.
/// Random bots choose among equally ranked legal choices with their seeded RNG.
Command chooseShrineBlessing(
  GameSession session, {
  List<OceanPower> preferredPowers = const [],
  List<HardpointType> preferredSlots = const [
    HardpointType.broadside,
    HardpointType.signature,
    HardpointType.utility,
  ],
  GameRng? rng,
}) {
  if (session.hasCommunedAtCurrentShrine) return const DepartShrine();
  final ship = session.ship!;
  final upgrades = <AcceptShrineBlessing>[];
  final openSlots = <AcceptShrineBlessing>[];
  final powers = [...session.shrineManifestedPowers];
  int rank(OceanPower power) {
    final index = preferredPowers.indexOf(power);
    return index < 0 ? preferredPowers.length : index;
  }

  powers.sort((a, b) => rank(a).compareTo(rank(b)));
  for (final power in powers) {
    for (final slot in preferredSlots) {
      if (session.shrineBlessingRestriction(power, slot) != null) continue;
      final command = AcceptShrineBlessing(power, slot);
      (ship.blessings.containsKey(slot) ? upgrades : openSlots).add(command);
    }
  }
  final choices = upgrades.isNotEmpty ? upgrades : openSlots;
  if (choices.isEmpty)
    return const CommuneWithShrine(ShrineChoice.ancientRunes);
  return choices[rng?.nextInt(choices.length) ?? 0];
}
