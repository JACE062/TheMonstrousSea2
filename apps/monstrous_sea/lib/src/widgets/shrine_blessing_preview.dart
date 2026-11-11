import 'package:monstrous_core/monstrous_core.dart';

/// Uses the existing dedication rule and a detached build for prospective help.
class ShrineBlessingPreview {
  ShrineBlessingPreview(
    ShipState ship,
    this.power,
    this.slot, {
    this.regionIndex = 0,
  }) {
    current = ship.blessings[slot];
    next = previewShrineBlessing(ship, power, slot);
    prospectiveShip = ShipState.fromJson(ship.toJson())
      ..captainBoonId = ship.captainBoonId
      ..captainQuirkId = ship.captainQuirkId;
    if (next != null) prospectiveShip.blessings[slot] = next!;
    stats = List.unmodifiable(_comparisons(ship));
  }

  final OceanPower power;
  final HardpointType slot;
  final int regionIndex;
  late final HardpointBlessing? current;
  late final HardpointBlessing? next;
  late final ShipState prospectiveShip;
  late final List<BlessingEffectComparison> stats;
  HardpointBlessing get displayed => next ?? current!;
  bool get isLocked => next == null;
  String? get restriction => !isLocked
      ? null
      : current!.power != power
      ? 'Dedicated to ${current!.power.displayName}'
      : 'Max Sovereign Tier Reached';

  String get summary => switch ((displayed.power, slot)) {
    (OceanPower.magmaVentLord, HardpointType.broadside) =>
      'Hits apply Burning.',
    (OceanPower.magmaVentLord, HardpointType.signature) =>
      displayed.appliesBurning
          ? 'Hits apply Burning, then trigger Thermal Detonation.'
          : 'Against Burning targets, triggers Thermal Detonation.',
    (OceanPower.magmaVentLord, _) =>
      'On utility use: applies Burning. Monster movement deals Fire damage.',
    (OceanPower.tempestSovereign, HardpointType.broadside) =>
      'Hits apply Static Charge.',
    (OceanPower.tempestSovereign, HardpointType.signature) =>
      'Hits apply Static Charge and can deal Critical Hits.',
    (OceanPower.tempestSovereign, _) => 'On utility use: applies Static Charge. Enemy attacks trigger Shock damage and Static Charge.',
    (OceanPower.brinemother, HardpointType.broadside) =>
      'Hits melt Carapace and apply Corroded.',
    (OceanPower.brinemother, HardpointType.signature) => 'Hits damage flesh through Carapace while stripping it, and apply Corroded.',
    (OceanPower.brinemother, _) => 'On utility use: clears enemy Obscurity, melts Carapace and applies Corroded.',
    (OceanPower.earthshakerTitan, HardpointType.broadside) =>
      'Hits damage Carapace and apply Shaken.',
    (OceanPower.earthshakerTitan, HardpointType.signature) =>
      displayed.windupStunActions > 0
          ? 'Hits break lethal windups and Stun the beast.'
          : 'Hits break lethal windups.',
    (OceanPower.earthshakerTitan, _) => 'On utility use: raises a barrier and evasion. Hits against the barrier trigger Blast retaliation.',
  };

  List<BlessingEffectComparison> _comparisons(ShipState ship) {
    final before = current;
    final after = displayed;
    final result = <BlessingEffectComparison>[];
    void add(
      String id,
      String label,
      String a,
      String b, {
      bool meaningful = true,
    }) {
      if (isLocked ? meaningful : a != b) {
        result.add(
          BlessingEffectComparison(
            id: id,
            label: label,
            current: isLocked ? b : a,
            next: isLocked ? null : b,
          ),
        );
      }
    }

    void amount(String id, String label, num a, num b, [String unit = '']) =>
        add(id, label, '$a$unit', '$b$unit', meaningful: b != 0);
    void flag(String id, String label, bool a, bool b) =>
        add(id, label, a ? 'Yes' : 'No', b ? 'Yes' : 'No', meaningful: b);
    String pct(double v) => '${(v * 100).round()}%';
    if (slot != HardpointType.utility) {
      add(
        'damage',
        'Weapon damage bonus',
        '+${pct(before?.damageBonus ?? 0)}',
        '+${pct(after.damageBonus)}',
      );
    }
    if (after.power == OceanPower.magmaVentLord) {
      amount(
        'burn-turns',
        slot == HardpointType.utility
            ? 'Burning turns on utility use'
            : 'Burning turns on hit',
        before?.appliesBurning == true ? before!.burningDuration : 0,
        after.appliesBurning ? after.burningDuration : 0,
        ' turns',
      );
      if (slot == HardpointType.signature) {
        add(
          'detonation',
          'Thermal Detonation bonus Blast',
          pct(before?.thermalDetonationFraction ?? 0),
          pct(after.thermalDetonationFraction),
        );
      }
      if (slot == HardpointType.utility) {
        amount(
          'wake-turns',
          'Boiling Wake duration',
          before?.utilityDuration ?? 0,
          after.utilityDuration,
          ' turns',
        );
        amount(
          'wake-fire',
          'Fire per monster range band moved',
          before?.wakeMovementDamage ?? 0,
          after.wakeMovementDamage,
        );
        add(
          'wake-burn',
          'Burning bonus while wake lasts',
          '+${pct((before?.wakeBurnMultiplier ?? 1) - 1)}',
          '+${pct(after.wakeBurnMultiplier - 1)}',
          meaningful: after.wakeBurnMultiplier > 1,
        );
      }
      int? burn(ShipState build) =>
          build.blessings.values.any((b) => b.appliesBurning)
          ? magmaBurnDamage(
              build.highestBlessingTier(OceanPower.magmaVentLord),
              regionIndex,
            )
          : null;
      final a = burn(ship), b = burn(prospectiveShip);
      add(
        'burn-fire',
        'Blessing Burning base Fire per turn',
        a?.toString() ?? 'None',
        b?.toString() ?? 'None',
        meaningful: b != null,
      );
    }
    if (after.power == OceanPower.tempestSovereign) {
      if (slot != HardpointType.utility) {
        amount(
          'static-hit',
          'Static Charge on hit',
          before?.staticChargeOnHit ?? 0,
          after.staticChargeOnHit,
        );
        amount(
          'double-static',
          'Chance for 2 Static Charge',
          before?.doubleStaticChargeChance ?? 0,
          after.doubleStaticChargeChance,
          '%',
        );
        amount(
          'crit',
          'Critical Hit chance bonus',
          before?.critChanceBonus ?? 0,
          after.critChanceBonus,
          '%',
        );
      } else {
        amount(
          'static-use',
          'Static Charge on utility use',
          before?.staticChargeOnActivation ?? 0,
          after.staticChargeOnActivation,
        );
        amount(
          'storm-turns',
          'Storm-Arc duration',
          before?.utilityDuration ?? 0,
          after.utilityDuration,
          ' turns',
        );
        amount(
          'storm-shock',
          'Base Shock per enemy attack',
          before?.stormRetaliationDamage ?? 0,
          after.stormRetaliationDamage,
        );
        amount(
          'storm-static',
          'Static Charge per enemy attack',
          before?.staticChargeOnRetaliation ?? 0,
          after.staticChargeOnRetaliation,
        );
      }
      int? arc(ShipState build) =>
          build.highestBlessingTier(OceanPower.tempestSovereign) > 0
          ? arcDischargeDamage(
              build.highestBlessingTier(OceanPower.tempestSovereign),
            )
          : null;
      final a = arc(ship), b = arc(prospectiveShip);
      add(
        'arc-shock',
        'Arc Discharge base Shock',
        a?.toString() ?? 'None',
        b?.toString() ?? 'None',
      );
    }
    if (after.power == OceanPower.brinemother) {
      amount(
        'melt',
        'Extra Carapace melt',
        before?.extraCarapaceMelt ?? 0,
        after.extraCarapaceMelt,
      );
      amount(
        'corroded-stacks',
        'Corroded stacks applied',
        before?.corrodedStacksApplied ?? 0,
        after.corrodedStacksApplied,
      );
      amount(
        'corroded-turns',
        'Corroded duration',
        before?.corrodedDuration ?? 0,
        after.corrodedDuration,
        ' turns',
      );
      if (slot == HardpointType.signature) {
        add(
          'unarmored',
          'Damage bonus against unarmored targets',
          '+${pct(before?.unarmoredDamageBonus ?? 0)}',
          '+${pct(after.unarmoredDamageBonus)}',
          meaningful: after.unarmoredDamageBonus > 0,
        );
      }
      if (slot == HardpointType.utility) {
        flag('clear-obscurity', 'Clears enemy Obscurity', before != null, true);
      }
      String corrosion(ShipState build) {
        final tier = build.highestBlessingTier(OceanPower.brinemother);
        return tier == 0
            ? 'None'
            : '+${pct(corrodedDamageBonusPerStack(tier))}';
      }

      add(
        'corroded-damage',
        'Damage taken per Corroded stack',
        corrosion(ship),
        corrosion(prospectiveShip),
      );
    }
    if (after.power == OceanPower.earthshakerTitan) {
      if (slot == HardpointType.broadside) {
        amount(
          'shaken',
          'Shaken accuracy penalty',
          before?.shakenAccuracyPenalty ?? 0,
          after.shakenAccuracyPenalty,
          '%',
        );
      } else if (slot == HardpointType.signature) {
        add(
          'windup-damage',
          'Damage bonus against lethal windups',
          '+${pct(before?.windupDamageBonus ?? 0)}',
          '+${pct(after.windupDamageBonus)}',
        );
        flag(
          'windup-break',
          'Breaks lethal windups',
          before?.breaksWindup ?? false,
          after.breaksWindup,
        );
        amount(
          'windup-stun',
          'Stun on windup break',
          before?.windupStunActions ?? 0,
          after.windupStunActions,
          ' action',
        );
      } else {
        amount(
          'barrier',
          'Barrier strength',
          before?.barrierHp ?? 0,
          after.barrierHp,
          ' HP',
        );
        amount(
          'barrier-turns',
          'Barrier duration',
          before?.utilityDuration ?? 0,
          after.utilityDuration,
          ' turns',
        );
        amount(
          'barrier-evasion',
          'Evasion bonus while barrier holds',
          before?.barrierEvasionBonus ?? 0,
          after.barrierEvasionBonus,
          '%',
        );
        amount(
          'retaliation',
          'Base Blast retaliation',
          before?.tidalShockwaveDamage ?? 0,
          after.tidalShockwaveDamage,
        );
      }
    }
    if (slot != HardpointType.utility &&
        (after.power == OceanPower.brinemother ||
            after.power == OceanPower.earthshakerTitan)) {
      final weapons = ship.equippedWeapons
          .where((w) => w.isSignature == (slot == HardpointType.signature))
          .toList();
      for (final (i, weapon) in weapons.indexed) {
        final label = weapons.length == 1
            ? ''
            : '${weapon.weaponType.displayName} ';
        String shell(HardpointBlessing? b) =>
            '${blessingCarapaceMultiplier(weapon.weaponType, weapon.damageType, b).toStringAsFixed(2)}x';
        add(
          'carapace-$i',
          '${label}Carapace damage multiplier',
          shell(before),
          shell(after),
        );
        add(
          'bypass-$i',
          '${label}Carapace bypass',
          pct(
            blessingCarapaceBypass(
              weapon.weaponType,
              weapon.damageType,
              before,
            ),
          ),
          pct(
            blessingCarapaceBypass(weapon.weaponType, weapon.damageType, after),
          ),
          meaningful:
              blessingCarapaceBypass(
                weapon.weaponType,
                weapon.damageType,
                after,
              ) >
              0,
        );
      }
    }
    return result;
  }
}

class BlessingEffectComparison {
  const BlessingEffectComparison({
    required this.id,
    required this.label,
    required this.current,
    required this.next,
  });
  final String id, label, current;
  final String? next;
}
