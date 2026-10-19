import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/armory_view.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/pilot_art.dart';

/// Hub screen at Hunter's Respite Port for repairs, trade, and chart planning.
class PortScreen extends StatefulWidget {
  const PortScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });

  final GameController controller;
  final VoidCallback onOpenChart;

  @override
  State<PortScreen> createState() => _PortScreenState();
}

class _PortScreenState extends State<PortScreen> {
  GameController get controller => widget.controller;
  VoidCallback get onOpenChart => widget.onOpenChart;

  int _covenantTabIndex = 0;

  String _upgradeBenefits(ShipClass sClass, int nextLevel) => switch (sClass) {
        ShipClass.standard => '+50 Max HP • +25% Hardpoint Damage',
        ShipClass.freighter || ShipClass.corsair =>
          '+45 Max HP • +3% Evasion • +25% Hardpoint Damage',
        ShipClass.ironclad =>
          '+75 Max HP • -${3 * nextLevel} Dmg Reduction • +25% Hardpoint Damage',
        ShipClass.corvette || ShipClass.clipper =>
          '+40 Max HP • +5% Evasion • +25% Hardpoint Damage',
        ShipClass.bombardier =>
          '+45 Max HP • +25% Hardpoint Damage',
      };

  void _showDrydockDialog(BuildContext context) {
    final ship = controller.ship;
    if (ship == null) return;

    final cost100 = calculateRepairCost(ship, 1.0);
    final cost50 = calculateRepairCost(ship, 0.5);
    final cost25 = calculateRepairCost(ship, 0.25);
    final upgradeCost = calculateShipUpgradeCost(ship.level);
    final canUpgrade = ship.level < 4 && upgradeCost > 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: InkTheme.parchmentSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: InkTheme.inkPrimary, width: 2),
        ),
        title: Text('DRYDOCK & SHIPWRIGHT', style: InkTheme.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shipwright: "Your vessel sits at ${ship.currentHp}/${ship.maxHp} HP (Tier ${ship.level}). Gold on hand: ${ship.gold}g."',
                style: InkTheme.body,
              ),
              const SizedBox(height: 14),
              // REFIT / UPGRADE SECTION
              Text('HULL REFIT & UPGRADE', style: InkTheme.statLabel.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (canUpgrade) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Refit to Tier ${ship.level + 1} (${ship.shipClass.name.toUpperCase()})',
                    style: InkTheme.statLabel,
                  ),
                  subtitle: Text(
                    '${_upgradeBenefits(ship.shipClass, ship.level + 1)}\n${ship.gold >= upgradeCost ? 'Cost: ${upgradeCost}g' : 'Cost: ${upgradeCost}g (Lacks ${upgradeCost - ship.gold}g)'}',
                    style: InkTheme.caption.copyWith(
                      color: ship.gold >= upgradeCost
                          ? InkTheme.inkMuted
                          : InkTheme.crimsonAccent,
                    ),
                  ),
                  trailing: InkButton(
                    label: ship.gold >= upgradeCost ? 'Refit' : 'Lacks Gold',
                    semanticLabel: 'Refit vessel to Level ${ship.level + 1}',
                    semanticHint: ship.gold >= upgradeCost
                        ? 'Costs $upgradeCost gold'
                        : 'Lacks ${upgradeCost - ship.gold} gold',
                    onPressed: ship.gold >= upgradeCost
                        ? () {
                            controller.dispatch(const UpgradeShip());
                            Navigator.pop(ctx);
                          }
                        : null,
                  ),
                ),
              ] else ...[
                Text(
                  'The ${ship.name} has attained maximum naval refit (Tier ${ship.level}).',
                  style: InkTheme.caption.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              const Divider(height: 20),
              Text(
                'HARDPOINT TEMPERING (MK I -> MK II -> MK III)',
                style: InkTheme.statLabel.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...[
                HardpointType.broadside,
                HardpointType.signature,
                HardpointType.utility,
              ].map((slot) {
                final mark = ship.markForHardpoint(slot);
                final markLabel = ship.markLabelForHardpoint(slot);
                final temperCost = calculateHardpointTemperCost(mark);
                final canTemper = mark < 3;
                final canAfford = canTemper && ship.gold >= temperCost;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    '${slot.displayName} Hardpoint ($markLabel)',
                    style: InkTheme.statLabel,
                  ),
                  subtitle: Text(
                    canTemper
                        ? 'Temper to Mk ${mark + 1} (+20% base potency) • Cost: ${temperCost}g'
                        : 'Maximum temper achieved (Mk III • 1.40x potency)',
                    style: InkTheme.caption.copyWith(
                      color: !canTemper
                          ? InkTheme.goldAccent
                          : (canAfford
                              ? InkTheme.inkMuted
                              : InkTheme.crimsonAccent),
                    ),
                  ),
                  trailing: canTemper
                      ? InkButton(
                          label: canAfford ? 'Temper (${temperCost}g)' : 'Lacks Gold',
                          semanticLabel:
                              'Temper ${slot.displayName} hardpoint to Mk ${mark + 1}',
                          onPressed: canAfford
                              ? () {
                                  controller.dispatch(TemperHardpoint(slot));
                                  Navigator.pop(ctx);
                                }
                              : null,
                        )
                      : Text(
                          'MAX',
                          style: InkTheme.caption.copyWith(
                            color: InkTheme.goldAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              }),
              const Divider(height: 20),
              Text('HULL REPAIRS', style: InkTheme.statLabel.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (cost100 == 0)
                Text('The ${ship.name} needs no repairs! Fully shipshape.',
                    style: InkTheme.bodyBold)
              else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Repair 100% Hull (Restore to ${ship.maxHp} HP)',
                      style: InkTheme.statLabel),
                  subtitle: Text(
                    ship.gold >= cost100
                        ? 'Cost: ${cost100}g'
                        : 'Cost: ${cost100}g (Lacks ${cost100 - ship.gold}g)',
                    style: InkTheme.caption.copyWith(
                      color: ship.gold >= cost100
                          ? InkTheme.inkMuted
                          : InkTheme.crimsonAccent,
                    ),
                  ),
                  trailing: InkButton(
                    label: ship.gold >= cost100 ? 'Repair' : 'Lacks Gold',
                    semanticLabel: 'Repair 100% hull',
                    semanticHint: ship.gold >= cost100
                        ? 'Costs $cost100 gold'
                        : 'Lacks ${cost100 - ship.gold} gold (costs ${cost100}g, have ${ship.gold}g)',
                    onPressed: ship.gold >= cost100
                        ? () {
                            controller.dispatch(const RepairShip(1.0));
                            Navigator.pop(ctx);
                          }
                        : null,
                  ),
                ),
                const Divider(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Repair 50% Hull', style: InkTheme.statLabel),
                  subtitle: Text(
                    ship.gold >= cost50
                        ? 'Cost: ${cost50}g'
                        : 'Cost: ${cost50}g (Lacks ${cost50 - ship.gold}g)',
                    style: InkTheme.caption.copyWith(
                      color: ship.gold >= cost50
                          ? InkTheme.inkMuted
                          : InkTheme.crimsonAccent,
                    ),
                  ),
                  trailing: InkButton(
                    label: ship.gold >= cost50 ? 'Repair' : 'Lacks Gold',
                    semanticLabel: 'Repair 50% hull',
                    semanticHint: ship.gold >= cost50
                        ? 'Costs $cost50 gold'
                        : 'Lacks ${cost50 - ship.gold} gold (costs ${cost50}g, have ${ship.gold}g)',
                    onPressed: ship.gold >= cost50
                        ? () {
                            controller.dispatch(const RepairShip(0.5));
                            Navigator.pop(ctx);
                          }
                        : null,
                  ),
                ),
                const Divider(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Repair 25% Hull', style: InkTheme.statLabel),
                  subtitle: Text(
                    ship.gold >= cost25
                        ? 'Cost: ${cost25}g'
                        : 'Cost: ${cost25}g (Lacks ${cost25 - ship.gold}g)',
                    style: InkTheme.caption.copyWith(
                      color: ship.gold >= cost25
                          ? InkTheme.inkMuted
                          : InkTheme.crimsonAccent,
                    ),
                  ),
                  trailing: InkButton(
                    label: ship.gold >= cost25 ? 'Repair' : 'Lacks Gold',
                    semanticLabel: 'Repair 25% hull',
                    semanticHint: ship.gold >= cost25
                        ? 'Costs $cost25 gold'
                        : 'Lacks ${cost25 - ship.gold} gold (costs ${cost25}g, have ${ship.gold}g)',
                    onPressed: ship.gold >= cost25
                        ? () {
                            controller.dispatch(const RepairShip(0.25));
                            Navigator.pop(ctx);
                          }
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: InkTheme.statLabel),
          ),
        ],
      ),
    );
  }

  void _showBlueprintsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final profile = controller.session.profile;
          final currentShip = controller.ship;
          final meta = profile.metaInventory;

          return AlertDialog(
            backgroundColor: InkTheme.parchmentSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: InkTheme.inkPrimary, width: 2),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('SHIPWRIGHT\'S DRAFTING TABLE', style: InkTheme.titleMedium),
                ),
                Text(
                  'Active: ${currentShip?.blueprintId.toUpperCase() ?? 'NONE'}',
                  style: InkTheme.caption.copyWith(color: InkTheme.crimsonAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Meta-Currency Ledger Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: InkTheme.parchmentHighlight,
                        border: Border.all(color: InkTheme.inkMuted),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _metaChip('Sea Glass', meta.seaGlass, Icons.lens_blur),
                          _metaChip('Monster Bone', meta.monsterBone, Icons.architecture),
                          _metaChip('Depth Iron', meta.depthWroughtIron, Icons.shield),
                          _metaChip('Barnacles', meta.abyssalBarnacles, Icons.pets),
                          if (meta.krakenBeak > 0)
                            _metaChip('Kraken Beak', meta.krakenBeak, Icons.military_tech),
                          if (meta.serpentScale > 0)
                            _metaChip('Serpent Scale', meta.serpentScale, Icons.star),
                          if (meta.leviathanCore > 0)
                            _metaChip('Leviathan Core', meta.leviathanCore, Icons.circle),
                          if (meta.primordialCinders > 0 || profile.hasUnlockedCovenant)
                            _metaChip('Cinders', meta.primordialCinders, Icons.local_fire_department),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Commission a specialized ancestral refit upon the returning keel. Each blueprint modifies hull characteristics and unlocks dedicated deck hardpoints.',
                      style: InkTheme.caption.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    // Reserve Auxiliary Hardpoint Expansion Card
                    Builder(builder: (context) {
                      final hasAux = profile.hasExpandedAuxiliarySlot;
                      final canUnlockAux = profile.canUnlockAuxiliaryExpansion();
                      final auxCost = BlueprintArmamentProgression.auxiliaryExpansionCost;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasAux
                              ? InkTheme.parchmentHighlight
                              : InkTheme.parchmentSurface,
                          border: Border.all(
                            color: hasAux ? InkTheme.goldAccent : InkTheme.inkMuted,
                            width: hasAux ? 1.8 : 1.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.extension,
                              size: 26,
                              color: hasAux ? InkTheme.goldAccent : InkTheme.inkPrimary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RESERVE AUXILIARY HARDPOINT EXPANSION',
                                    style: InkTheme.statLabel.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: hasAux ? InkTheme.goldAccent : InkTheme.inkPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasAux
                                        ? 'Flagship gun deck reinforced: +1 Reserve Aux Mount active across all hulls.'
                                        : 'Reinforce the ancestral flagship deck to mount +1 Reserve Auxiliary Hardpoint across all hulls. Cost: ${_formatUnlockCost(auxCost)}.',
                                    style: InkTheme.caption.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (hasAux)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: InkTheme.goldAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: InkTheme.goldAccent),
                                ),
                                child: Text(
                                  'REINFORCED',
                                  style: InkTheme.caption.copyWith(
                                    color: InkTheme.goldAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            else
                              InkButton(
                                label: canUnlockAux ? 'REINFORCE DECK' : 'LACKS MATERIALS',
                                semanticLabel: 'Unlock Reserve Auxiliary Hardpoint Expansion',
                                semanticHint: _formatUnlockCost(auxCost),
                                onPressed: canUnlockAux
                                    ? () {
                                        controller.dispatch(const UnlockAuxiliaryExpansion());
                                        setDialogState(() {});
                                        setState(() {});
                                      }
                                    : null,
                              ),
                          ],
                        ),
                      );
                    }),

                    // List of 5 Ancestral Blueprints
                    ...BlueprintId.values.map((bpId) {
                      final bp = FlagshipBlueprint.catalog[bpId]!;
                      final isUnlocked = profile.isBlueprintUnlocked(bpId);
                      final isActive = currentShip?.blueprintId == bpId.name;
                      final canAfford = profile.canUnlockBlueprint(bpId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive
                                ? InkTheme.parchmentHighlight
                                : (isUnlocked
                                    ? InkTheme.parchmentSurface
                                    : InkTheme.parchmentDark.withValues(alpha: 0.3)),
                            border: Border.all(
                              color: isActive
                                  ? InkTheme.goldAccent
                                  : (isUnlocked ? InkTheme.inkPrimary : InkTheme.inkMuted),
                              width: isActive ? 2.0 : 1.2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              bp.name.toUpperCase(),
                                              style: InkTheme.titleMedium.copyWith(
                                                fontSize: 18,
                                                color: isActive
                                                    ? InkTheme.crimsonAccent
                                                    : InkTheme.inkPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isActive) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: InkTheme.goldAccent,
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  'COMMISSIONED',
                                                  style: InkTheme.caption.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(bp.subtitle, style: InkTheme.caption.copyWith(fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ),
                                  // Action Button: Commission or Unlock
                                  if (isActive)
                                    Text('ACTIVE HULL', style: InkTheme.statLabel.copyWith(color: InkTheme.goldAccent, fontWeight: FontWeight.bold))
                                  else if (isUnlocked)
                                    InkButton(
                                      label: 'COMMISSION',
                                      semanticLabel: 'Commission ${bp.name}',
                                      onPressed: () {
                                        controller.dispatch(CommissionBlueprint(bpId));
                                        setState(() {});
                                        Navigator.pop(ctx);
                                      },
                                    )
                                  else
                                    InkButton(
                                      label: canAfford ? 'UNLOCK' : 'LACKS MATERIALS',
                                      semanticLabel: 'Unlock ${bp.name}',
                                      semanticHint: _formatUnlockCost(bp.unlockCost),
                                      onPressed: canAfford
                                          ? () {
                                              controller.dispatch(UnlockBlueprint(bpId));
                                              setDialogState(() {});
                                              setState(() {});
                                            }
                                          : null,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(bp.description, style: InkTheme.body.copyWith(fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(
                                'Tactical Doctrine: ${bp.tacticalRole}',
                                style: InkTheme.caption.copyWith(
                                  color: InkTheme.inkPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Hardpoint slot layout
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: bp.hardpoints.map((slot) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: slot.isSignature
                                          ? InkTheme.crimsonAccent.withValues(alpha: 0.15)
                                          : InkTheme.parchmentHighlight,
                                      border: Border.all(
                                        color: slot.isSignature
                                            ? InkTheme.crimsonAccent
                                            : InkTheme.inkMuted,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          slot.isSignature ? Icons.auto_awesome : Icons.shield_outlined,
                                          size: 13,
                                          color: slot.isSignature ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${slot.name} (${slot.type.displayName})',
                                          style: InkTheme.caption.copyWith(
                                            fontSize: 11,
                                            fontWeight: slot.isSignature ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (!isUnlocked) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Unlock Requirements: ${_formatUnlockCost(bp.unlockCost)}',
                                  style: InkTheme.caption.copyWith(
                                    color: canAfford ? InkTheme.goldAccent : InkTheme.crimsonAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else ...[
                                const Divider(height: 16),
                                Builder(
                                  builder: (context) {
                                    final tier = profile.armamentTierFor(bpId);
                                    final nextCost = BlueprintArmamentProgression.costForNextTier(tier);
                                    final canUpgrade = profile.canUpgradeBlueprintArmament(bpId);
                                    final multiplier = BlueprintArmamentProgression.damageMultiplierForTier(tier);
                                    final nextMultiplier = nextCost != null
                                        ? BlueprintArmamentProgression.damageMultiplierForTier(tier + 1)
                                        : null;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.shield, size: 14, color: InkTheme.goldAccent),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'SIGNATURE ARMAMENT: TIER $tier',
                                                  style: InkTheme.caption.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: InkTheme.inkPrimary,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: InkTheme.goldAccent,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                  child: Text(
                                                    '${multiplier.toStringAsFixed(2)}x DMG',
                                                    style: InkTheme.caption.copyWith(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (nextCost != null)
                                              InkButton(
                                                label: canUpgrade ? 'UPGRADE TIER ${tier + 1}' : 'LACKS MATERIALS',
                                                semanticLabel: 'Upgrade ${bp.name} signature armament to Tier ${tier + 1}',
                                                semanticHint: _formatUnlockCost(nextCost),
                                                onPressed: canUpgrade
                                                    ? () {
                                                        controller.dispatch(UpgradeBlueprintArmament(bpId));
                                                        setDialogState(() {});
                                                        setState(() {});
                                                      }
                                                    : null,
                                              )
                                            else
                                              Text(
                                                'MAX TIER',
                                                style: InkTheme.caption.copyWith(
                                                  color: InkTheme.goldAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (nextCost != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Upgrade to Tier ${tier + 1} (${nextMultiplier!.toStringAsFixed(2)}x dmg): ${_formatUnlockCost(nextCost)}',
                                            style: InkTheme.caption.copyWith(
                                              color: canUpgrade ? InkTheme.goldAccent : InkTheme.crimsonAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: InkTheme.statLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _metaChip(String label, int amount, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: InkTheme.goldAccent),
        const SizedBox(width: 4),
        Text('$amount $label', style: InkTheme.caption.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  static String _formatUnlockCost(MetaCost cost) {
    final parts = <String>[];
    if (cost.seaGlass > 0) parts.add('${cost.seaGlass} Sea Glass');
    if (cost.monsterBone > 0) parts.add('${cost.monsterBone} Monster Bone');
    if (cost.depthWroughtIron > 0) parts.add('${cost.depthWroughtIron} Depth Iron');
    if (cost.abyssalBarnacles > 0) parts.add('${cost.abyssalBarnacles} Barnacles');
    if (cost.krakenBeak > 0) parts.add('${cost.krakenBeak} Kraken Beak');
    if (cost.serpentScale > 0) parts.add('${cost.serpentScale} Serpent Scale');
    if (cost.leviathanCore > 0) parts.add('${cost.leviathanCore} Leviathan Core');
    if (cost.primordialCinders > 0) parts.add('${cost.primordialCinders} Primordial Cinders');
    return parts.isEmpty ? 'Free' : parts.join(', ');
  }

  void _showCovenantDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final profile = controller.session.profile;
          final meta = profile.metaInventory;
          final totalBurden = profile.totalPactBurden;

          return AlertDialog(
            backgroundColor: InkTheme.parchmentSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: InkTheme.crimsonAccent, width: 2),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.nights_stay, color: InkTheme.crimsonAccent, size: 26),
                    const SizedBox(width: 8),
                    Text('ABYSSAL COVENANT ALTAR', style: InkTheme.titleMedium.copyWith(color: InkTheme.crimsonAccent, fontSize: 20)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: InkTheme.crimsonAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+$totalBurden PACT BURDEN',
                    style: InkTheme.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 720,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Meta-Currency Ledger Banner (Trophies & Cinders Focus)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: InkTheme.parchmentHighlight,
                        border: Border.all(color: InkTheme.inkMuted),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _metaChip('Cinders', meta.primordialCinders, Icons.local_fire_department),
                          _metaChip('Leviathan Core', meta.leviathanCore, Icons.circle),
                          _metaChip('Kraken Beak', meta.krakenBeak, Icons.military_tech),
                          _metaChip('Serpent Scale', meta.serpentScale, Icons.star),
                          _metaChip('Depth Iron', meta.depthWroughtIron, Icons.shield),
                          _metaChip('Bone', meta.monsterBone, Icons.architecture),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Navigation Tabs: PACTS | RELICS | MONUMENTS
                    Row(
                      children: [
                        Expanded(
                          child: _covenantTabButton(
                            label: 'COVENANT PACTS',
                            icon: Icons.gavel,
                            isSelected: _covenantTabIndex == 0,
                            onTap: () => setDialogState(() => _covenantTabIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _covenantTabButton(
                            label: 'ELDRITCH RELICS',
                            icon: Icons.whatshot,
                            isSelected: _covenantTabIndex == 1,
                            onTap: () => setDialogState(() => _covenantTabIndex = 1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _covenantTabButton(
                            label: 'CURSED MONUMENTS',
                            icon: Icons.account_balance,
                            isSelected: _covenantTabIndex == 2,
                            onTap: () => setDialogState(() => _covenantTabIndex = 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // TAB CONTENT
                    if (_covenantTabIndex == 0) ...[
                      // TAB 1: COVENANT PACTS
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: InkTheme.parchmentHighlight,
                          border: Border.all(color: InkTheme.goldAccent.withValues(alpha: 0.6)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: InkTheme.goldAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ratify bloodline Pacts to increase Pact Burden. Primordial Cinders drop exclusively from Region Titans defeated under active Pact Burden (> 0)!',
                                style: InkTheme.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...CovenantPactId.values.map((pactId) {
                        final pact = CovenantPact.catalog[pactId]!;
                        final isActive = profile.isPactActive(pactId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? InkTheme.crimsonAccent.withValues(alpha: 0.08)
                                : InkTheme.parchmentSurface,
                            border: Border.all(
                              color: isActive ? InkTheme.crimsonAccent : InkTheme.inkMuted,
                              width: isActive ? 1.6 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              activeColor: InkTheme.crimsonAccent,
                              checkColor: Colors.white,
                              value: isActive,
                              onChanged: (_) {
                                controller.dispatch(ToggleCovenantPact(pactId));
                                setDialogState(() {});
                                setState(() {});
                              },
                              title: Row(
                                children: [
                                  Text(
                                    pact.name.toUpperCase(),
                                    style: InkTheme.statLabel.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isActive ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? InkTheme.crimsonAccent : InkTheme.inkMuted,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '+${pact.burden} BURDEN',
                                      style: InkTheme.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pact.flavor,
                                      style: InkTheme.caption.copyWith(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pact.effectDescription,
                                      style: InkTheme.body.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? InkTheme.crimsonAccent
                                            : InkTheme.inkPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ] else if (_covenantTabIndex == 1) ...[
                      // TAB 2: ELDRITCH RELIC WEAPONS
                      Text(
                        'Forge eldritch weapons from Titan Trophies and Primordial Cinders at the Covenant Altar. Once forged, a relic weapon is permanently mounted on its corresponding ancestral hull.',
                        style: InkTheme.caption.copyWith(fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),
                      ...EldritchRelicId.values.map((relicId) {
                        final def = EldritchRelicDef.catalog[relicId]!;
                        final isUnlocked = profile.isEldritchRelicUnlocked(relicId);
                        final canUnlock = profile.canUnlockEldritchRelic(relicId);
                        final bpUnlocked = profile.isBlueprintUnlocked(def.blueprintId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? InkTheme.parchmentHighlight
                                : InkTheme.parchmentSurface,
                            border: Border.all(
                              color: isUnlocked ? InkTheme.goldAccent : InkTheme.inkMuted,
                              width: isUnlocked ? 1.8 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                def.name.toUpperCase(),
                                                style: InkTheme.titleMedium.copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isUnlocked ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
                                                ),
                                              ),
                                            ),
                                            if (isUnlocked) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: InkTheme.goldAccent,
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  'FORGED',
                                                  style: InkTheme.caption.copyWith(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          'Mounts on: ${def.blueprintId.displayName} (${def.weaponType.displayName})',
                                          style: InkTheme.caption.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: InkTheme.inkSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isUnlocked)
                                    Text(
                                      'ACTIVE ON HULL',
                                      style: InkTheme.statLabel.copyWith(
                                        color: InkTheme.goldAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    )
                                  else if (!bpUnlocked)
                                    Text(
                                      'REQUIRES ${def.blueprintId.displayName.toUpperCase()}',
                                      style: InkTheme.caption.copyWith(
                                        color: InkTheme.crimsonAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    )
                                  else
                                    InkButton(
                                      label: canUnlock ? 'FORGE RELIC' : 'LACKS MATERIALS',
                                      semanticLabel: 'Forge ${def.name}',
                                      semanticHint: _formatUnlockCost(def.unlockCost),
                                      onPressed: canUnlock
                                          ? () {
                                              controller.dispatch(UnlockEldritchRelic(relicId));
                                              setDialogState(() {});
                                              setState(() {});
                                            }
                                          : null,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(def.description, style: InkTheme.body.copyWith(fontSize: 12.5)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: InkTheme.parchmentDark.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'Eldritch Trait: ${def.effectSummary}',
                                  style: InkTheme.caption.copyWith(
                                    color: InkTheme.crimsonAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              if (!isUnlocked && bpUnlocked) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Forge Cost: ${_formatUnlockCost(def.unlockCost)}',
                                  style: InkTheme.caption.copyWith(
                                    color: canUnlock ? InkTheme.goldAccent : InkTheme.crimsonAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      // TAB 3: CURSED HARBOR MONUMENTS
                      Text(
                        'Consecrate permanent cursed monuments around Hunter\'s Respite using surplus Titan Trophies and Primordial Cinders. These monuments grant generational boons across all future voyages.',
                        style: InkTheme.caption.copyWith(fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),
                      ...HarborMonumentId.values.map((monumentId) {
                        final def = HarborMonumentDef.catalog[monumentId]!;
                        final currentRank = profile.monumentRank(monumentId);
                        final nextRank = currentRank + 1;
                        final nextCost = def.costForRank(nextRank);
                        final canUpgrade = profile.canUpgradeMonument(monumentId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: currentRank > 0
                                ? InkTheme.parchmentHighlight
                                : InkTheme.parchmentSurface,
                            border: Border.all(
                              color: currentRank > 0 ? InkTheme.goldAccent : InkTheme.inkMuted,
                              width: currentRank > 0 ? 1.8 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                def.name.toUpperCase(),
                                                style: InkTheme.titleMedium.copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: currentRank > 0 ? InkTheme.goldAccent : InkTheme.inkMuted,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                'RANK $currentRank',
                                                style: InkTheme.caption.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Generational Blessing: ${def.bonusPerRankDescription}',
                                          style: InkTheme.caption.copyWith(
                                            color: InkTheme.goldAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkButton(
                                    label: canUpgrade ? 'UPGRADE (Rank $nextRank)' : 'LACKS MATERIALS',
                                    semanticLabel: 'Upgrade ${def.name} to Rank $nextRank',
                                    semanticHint: _formatUnlockCost(nextCost),
                                    onPressed: canUpgrade
                                        ? () {
                                            controller.dispatch(UpgradeHarborMonument(monumentId));
                                            setDialogState(() {});
                                            setState(() {});
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(def.subtitle, style: InkTheme.body.copyWith(fontSize: 12.5)),
                              const SizedBox(height: 8),
                              Text(
                                'Next Rank ($nextRank) Cost: ${_formatUnlockCost(nextCost)}',
                                style: InkTheme.caption.copyWith(
                                  color: canUpgrade ? InkTheme.goldAccent : InkTheme.crimsonAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: InkTheme.statLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _covenantTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? InkTheme.crimsonAccent : InkTheme.parchmentHighlight,
          border: Border.all(
            color: isSelected ? InkTheme.crimsonAccent : InkTheme.inkMuted,
            width: isSelected ? 1.8 : 1.0,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : InkTheme.inkPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: InkTheme.caption.copyWith(
                color: isSelected ? Colors.white : InkTheme.inkPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    final profile = controller.session.profile;

    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Port Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.session.seaChart.currentPortName.toUpperCase(),
                            style: InkTheme.titleLarge.copyWith(fontSize: 32),
                          ),
                          Text(
                            controller.session.seaChart.currentPortSubtitle,
                            style: InkTheme.subtitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings, color: InkTheme.inkPrimary),
                          tooltip: 'Settings & Accessibility',
                          onPressed: () => SettingsDialog.show(context),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: InkTheme.parchmentHighlight,
                            border: Border.all(color: InkTheme.goldAccent, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const SvgAssetView(assetPath: PilotArt.treasure, width: 24, height: 24),
                              const SizedBox(width: 8),
                              Text('${ship?.gold ?? 0}g', style: InkTheme.statValue.copyWith(fontSize: 18, color: InkTheme.goldAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Vessel Card
                if (ship != null)
                  ParchmentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgAssetView(
                              assetPath: PilotArt.forShip(ship),
                              width: 100,
                              height: 100,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ship.name, style: InkTheme.titleMedium.copyWith(fontSize: 24)),
                                  Text('Captain ${controller.captainName} • Level ${ship.level} ${ship.shipClass.name.toUpperCase()}', style: InkTheme.caption.copyWith(fontSize: 14)),
                                  const SizedBox(height: 12),
                                  HullGauge(currentHp: ship.currentHp, maxHp: ship.maxHp),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceAround,
                          children: [
                            switch (ship.shipClass) {
                              ShipClass.ironclad => _vesselStat(
                                  'FORTIFY DEF', '-${ship.currentDmgReduction} Dmg'),
                              ShipClass.corvette || ShipClass.clipper =>
                                _vesselStat('EVASION', '${ship.currentEvasion}% Eva'),
                              ShipClass.freighter =>
                                _vesselStat('HEIR STASH', '5% Gold/Cargo'),
                              ShipClass.corsair =>
                                _vesselStat('TACTICAL RIG', 'Harpoon Winch'),
                              ShipClass.standard =>
                                _vesselStat('DEFENSE', 'Reinforced'),
                              ShipClass.bombardier =>
                                _vesselStat('SIEGE MORTAR', 'Heavy Blast'),
                            },
                            _vesselStat('TACTICAL BELT', '${ship.cargo.length} / ${ship.maxCargo} Slots'),
                            _vesselStat(
                              'HARDPOINTS',
                              '3 Mounts (${ship.markLabelForHardpoint(HardpointType.broadside)}/${ship.markLabelForHardpoint(HardpointType.signature)}/${ship.markLabelForHardpoint(HardpointType.utility)})',
                            ),
                            _vesselStat('MONSTERS SLAIN', '${controller.session.monstersDefeatedThisLife}'),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                // Armory & Weapon Batteries (Mount / stow weapons at port)
                ArmoryView(controller: controller),

                const SizedBox(height: 18),

                // Covenant Altar of the Deep (Unlocked upon claiming Leviathan Core)
                if (profile.hasUnlockedCovenant) ...[
                  ParchmentCard(
                    borderColor: InkTheme.crimsonAccent,
                    backgroundColor: InkTheme.crimsonAccent.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: InkTheme.crimsonAccent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'COVENANT ALTAR OF THE DEEP',
                                    style: InkTheme.statLabel.copyWith(
                                      color: InkTheme.crimsonAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: InkTheme.crimsonAccent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'BURDEN: ${profile.totalPactBurden}',
                                      style: InkTheme.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  if (profile.ascensionLoopCount > 0)
                                    Text(
                                      '• Loop ${profile.ascensionLoopCount}',
                                      style: InkTheme.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: InkTheme.inkMuted,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'The Leviathan Core hums in the keel. Enact Pacts for Primordial Cinders, forge Eldritch Relics, or consecrate Harbor Monuments.',
                                style: InkTheme.caption.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkButton(
                          label: 'COMMUNE',
                          semanticLabel: 'Commune with the Covenant Altar',
                          onPressed: () => _showCovenantDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Port Action Grid
                Row(
                  children: [
                    Expanded(
                      child: InkButton(
                        label: 'MERCHANT',
                        icon: SvgAssetView(assetPath: PilotArt.helm, width: 20, height: 20),
                        onPressed: () => controller.dispatch(const VisitMerchant()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkButton(
                        label: 'DRYDOCK',
                        icon: SvgAssetView(assetPath: PilotArt.anchor, width: 20, height: 20),
                        onPressed: () => _showDrydockDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkButton(
                        label: 'BLUEPRINTS',
                        icon: const Icon(Icons.architecture, color: InkTheme.inkPrimary, size: 20),
                        onPressed: () => _showBlueprintsDialog(context),
                      ),
                    ),
                    if (profile.hasUnlockedCovenant) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkButton(
                          label: 'COVENANT',
                          icon: const Icon(Icons.local_fire_department, color: InkTheme.crimsonAccent, size: 20),
                          onPressed: () => _showCovenantDialog(context),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkButton(
                        label: 'SEA CHART',
                        icon: SvgAssetView(assetPath: PilotArt.cannons, width: 20, height: 20),
                        onPressed: onOpenChart,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Expedition Departure Route Selector (Charted Waypoints)
                // Main Expedition Departure Button
                InkButton(
                  label: controller.session.seaChart.currentRegionIndex == 0
                      ? 'VENTURE OUT TO SEA'
                      : 'SET SAIL FOR ${controller.session.seaChart.currentRegionName.toUpperCase()}',
                  isPrimary: true,
                  onPressed: () => controller.dispatch(
                    const VentureOutToSea(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vesselStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: InkTheme.statLabel.copyWith(fontSize: 12.5)),
        const SizedBox(height: 2),
        Text(value, style: InkTheme.statValue.copyWith(fontSize: 16)),
      ],
    );
  }
}
