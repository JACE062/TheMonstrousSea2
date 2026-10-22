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

  void _showBlueprintsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final profile = controller.profile;
          final meta = profile.metaInventory;
          return AlertDialog(
            backgroundColor: InkTheme.parchmentSurface,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SHIPWRIGHT'S DRAFTING TABLE",
                  style: InkTheme.titleMedium,
                ),
                Text(
                  'Active: ${controller.ship?.blueprintId.toUpperCase() ?? 'NONE'}',
                  style: InkTheme.caption.copyWith(fontSize: 14),
                ),
              ],
            ),
            content: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Unlock ancestral blueprints with materials recovered at sea. These permanent refits are separate from the hardpoint marks earned during a voyage.',
                      style: InkTheme.body.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _metaChip('Sea Glass', meta.seaGlass, Icons.lens_blur),
                        _metaChip(
                          'Monster Bone',
                          meta.monsterBone,
                          Icons.architecture,
                        ),
                        _metaChip(
                          'Depth Iron',
                          meta.depthWroughtIron,
                          Icons.shield,
                        ),
                        _metaChip(
                          'Barnacles',
                          meta.abyssalBarnacles,
                          Icons.pets,
                        ),
                        if (meta.krakenBeak > 0)
                          _metaChip(
                            'Kraken Beak',
                            meta.krakenBeak,
                            Icons.military_tech,
                          ),
                        if (meta.serpentScale > 0)
                          _metaChip(
                            'Serpent Scale',
                            meta.serpentScale,
                            Icons.star,
                          ),
                        if (meta.leviathanCore > 0)
                          _metaChip(
                            'Leviathan Core',
                            meta.leviathanCore,
                            Icons.circle,
                          ),
                        if (meta.primordialCinders > 0)
                          _metaChip(
                            'Cinders',
                            meta.primordialCinders,
                            Icons.local_fire_department,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final bpId in BlueprintId.values)
                      Builder(
                        builder: (context) {
                          final bp = FlagshipBlueprint.catalog[bpId]!;
                          final isUnlocked = profile.isBlueprintUnlocked(bpId);
                          final isActive =
                              controller.ship?.blueprintId == bpId.name;
                          final canAfford = profile.canUnlockBlueprint(bpId);
                          final tier = profile.armamentTierFor(bpId);
                          final nextCost =
                              BlueprintArmamentProgression.costForNextTier(
                                tier,
                              );
                          final canUpgrade = profile
                              .canUpgradeBlueprintArmament(bpId);
                          final multiplier =
                              BlueprintArmamentProgression.damageMultiplierForTier(
                                tier,
                              );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ParchmentCard(
                              borderColor: isActive
                                  ? InkTheme.goldAccent
                                  : InkTheme.inkMuted,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    bp.name.toUpperCase(),
                                    style: InkTheme.titleMedium.copyWith(
                                      fontSize: 21,
                                    ),
                                  ),
                                  Text(
                                    bp.subtitle,
                                    style: InkTheme.caption.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    bp.description,
                                    style: InkTheme.body.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final slot in bp.hardpoints)
                                    Text(
                                      '${slot.type.displayName}: ${slot.name}',
                                      style: InkTheme.body.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  if (isActive)
                                    Text(
                                      'ACTIVE HULL',
                                      style: InkTheme.statLabel.copyWith(
                                        fontSize: 14,
                                      ),
                                    )
                                  else if (isUnlocked)
                                    InkButton(
                                      label: 'COMMISSION',
                                      semanticLabel: 'Commission ${bp.name}',
                                      onPressed: () {
                                        controller.dispatch(
                                          CommissionBlueprint(bpId),
                                        );
                                        setState(() {});
                                        Navigator.pop(ctx);
                                      },
                                    )
                                  else ...[
                                    Text(
                                      'Unlock Requirements: ${_formatUnlockCost(bp.unlockCost)}',
                                      style: InkTheme.body.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkButton(
                                      label: canAfford
                                          ? 'UNLOCK'
                                          : 'LACKS MATERIALS',
                                      semanticLabel: 'Unlock ${bp.name}',
                                      onPressed: canAfford
                                          ? () {
                                              controller.dispatch(
                                                UnlockBlueprint(bpId),
                                              );
                                              setDialogState(() {});
                                              setState(() {});
                                            }
                                          : null,
                                    ),
                                  ],
                                  if (isUnlocked) ...[
                                    const Divider(height: 20),
                                    Text(
                                      'SIGNATURE ARMAMENT: TIER $tier',
                                      style: InkTheme.statLabel.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${multiplier.toStringAsFixed(2)}x DMG',
                                      style: InkTheme.statValue.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (nextCost != null) ...[
                                      Text(
                                        'Permanent refit: ${_formatUnlockCost(nextCost)}',
                                        style: InkTheme.body.copyWith(
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkButton(
                                        label: canUpgrade
                                            ? 'UPGRADE TIER ${tier + 1}'
                                            : 'LACKS MATERIALS',
                                        semanticLabel:
                                            'Upgrade ${bp.name} signature armament to Tier ${tier + 1}',
                                        onPressed: canUpgrade
                                            ? () {
                                                controller.dispatch(
                                                  UpgradeBlueprintArmament(
                                                    bpId,
                                                  ),
                                                );
                                                setDialogState(() {});
                                                setState(() {});
                                              }
                                            : null,
                                      ),
                                    ] else
                                      Text(
                                        'MAX TIER',
                                        style: InkTheme.statLabel.copyWith(
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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
        Flexible(
          child: Text(
            '$amount $label',
            style: InkTheme.caption.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatUnlockCost(MetaCost cost) {
    final parts = <String>[];
    if (cost.seaGlass > 0) parts.add('${cost.seaGlass} Sea Glass');
    if (cost.monsterBone > 0) parts.add('${cost.monsterBone} Monster Bone');
    if (cost.depthWroughtIron > 0) {
      parts.add('${cost.depthWroughtIron} Depth Iron');
    }
    if (cost.abyssalBarnacles > 0) {
      parts.add('${cost.abyssalBarnacles} Barnacles');
    }
    if (cost.krakenBeak > 0) parts.add('${cost.krakenBeak} Kraken Beak');
    if (cost.serpentScale > 0) parts.add('${cost.serpentScale} Serpent Scale');
    if (cost.leviathanCore > 0) {
      parts.add('${cost.leviathanCore} Leviathan Core');
    }
    if (cost.primordialCinders > 0) {
      parts.add('${cost.primordialCinders} Primordial Cinders');
    }
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
                    const Icon(
                      Icons.nights_stay,
                      color: InkTheme.crimsonAccent,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ABYSSAL COVENANT ALTAR',
                      style: InkTheme.titleMedium.copyWith(
                        color: InkTheme.crimsonAccent,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                          _metaChip(
                            'Cinders',
                            meta.primordialCinders,
                            Icons.local_fire_department,
                          ),
                          _metaChip(
                            'Leviathan Core',
                            meta.leviathanCore,
                            Icons.circle,
                          ),
                          _metaChip(
                            'Kraken Beak',
                            meta.krakenBeak,
                            Icons.military_tech,
                          ),
                          _metaChip(
                            'Serpent Scale',
                            meta.serpentScale,
                            Icons.star,
                          ),
                          _metaChip(
                            'Depth Iron',
                            meta.depthWroughtIron,
                            Icons.shield,
                          ),
                          _metaChip(
                            'Bone',
                            meta.monsterBone,
                            Icons.architecture,
                          ),
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
                            onTap: () =>
                                setDialogState(() => _covenantTabIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _covenantTabButton(
                            label: 'ELDRITCH RELICS',
                            icon: Icons.whatshot,
                            isSelected: _covenantTabIndex == 1,
                            onTap: () =>
                                setDialogState(() => _covenantTabIndex = 1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _covenantTabButton(
                            label: 'CURSED MONUMENTS',
                            icon: Icons.account_balance,
                            isSelected: _covenantTabIndex == 2,
                            onTap: () =>
                                setDialogState(() => _covenantTabIndex = 2),
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
                          border: Border.all(
                            color: InkTheme.goldAccent.withValues(alpha: 0.6),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: InkTheme.goldAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ratify bloodline Pacts to increase Pact Burden. Primordial Cinders drop exclusively from Region Titans defeated under active Pact Burden (> 0)!',
                                style: InkTheme.caption.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
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
                              color: isActive
                                  ? InkTheme.crimsonAccent
                                  : InkTheme.inkMuted,
                              width: isActive ? 1.6 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
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
                                      color: isActive
                                          ? InkTheme.crimsonAccent
                                          : InkTheme.inkPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? InkTheme.crimsonAccent
                                          : InkTheme.inkMuted,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '+${pact.burden} BURDEN',
                                      style: InkTheme.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                                        fontSize: 12,
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
                        final isUnlocked = profile.isEldritchRelicUnlocked(
                          relicId,
                        );
                        final canUnlock = profile.canUnlockEldritchRelic(
                          relicId,
                        );
                        final bpUnlocked = profile.isBlueprintUnlocked(
                          def.blueprintId,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? InkTheme.parchmentHighlight
                                : InkTheme.parchmentSurface,
                            border: Border.all(
                              color: isUnlocked
                                  ? InkTheme.goldAccent
                                  : InkTheme.inkMuted,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                def.name.toUpperCase(),
                                                style: InkTheme.titleMedium
                                                    .copyWith(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isUnlocked
                                                          ? InkTheme
                                                                .crimsonAccent
                                                          : InkTheme.inkPrimary,
                                                    ),
                                              ),
                                            ),
                                            if (isUnlocked) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: InkTheme.goldAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  'FORGED',
                                                  style: InkTheme.caption
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                        fontSize: 12,
                                      ),
                                    )
                                  else
                                    InkButton(
                                      label: canUnlock
                                          ? 'FORGE RELIC'
                                          : 'LACKS MATERIALS',
                                      semanticLabel: 'Forge ${def.name}',
                                      semanticHint: _formatUnlockCost(
                                        def.unlockCost,
                                      ),
                                      onPressed: canUnlock
                                          ? () {
                                              controller.dispatch(
                                                UnlockEldritchRelic(relicId),
                                              );
                                              setDialogState(() {});
                                              setState(() {});
                                            }
                                          : null,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                def.description,
                                style: InkTheme.body.copyWith(fontSize: 12.5),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: InkTheme.parchmentDark.withValues(
                                    alpha: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'Eldritch Trait: ${def.effectSummary}',
                                  style: InkTheme.caption.copyWith(
                                    color: InkTheme.crimsonAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (!isUnlocked && bpUnlocked) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Forge Cost: ${_formatUnlockCost(def.unlockCost)}',
                                  style: InkTheme.caption.copyWith(
                                    color: canUnlock
                                        ? InkTheme.goldAccent
                                        : InkTheme.crimsonAccent,
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
                        final canUpgrade = profile.canUpgradeMonument(
                          monumentId,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: currentRank > 0
                                ? InkTheme.parchmentHighlight
                                : InkTheme.parchmentSurface,
                            border: Border.all(
                              color: currentRank > 0
                                  ? InkTheme.goldAccent
                                  : InkTheme.inkMuted,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                def.name.toUpperCase(),
                                                style: InkTheme.titleMedium
                                                    .copyWith(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: currentRank > 0
                                                    ? InkTheme.goldAccent
                                                    : InkTheme.inkMuted,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                'RANK $currentRank',
                                                style: InkTheme.caption
                                                    .copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
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
                                    label: canUpgrade
                                        ? 'UPGRADE (Rank $nextRank)'
                                        : 'LACKS MATERIALS',
                                    semanticLabel:
                                        'Upgrade ${def.name} to Rank $nextRank',
                                    semanticHint: _formatUnlockCost(nextCost),
                                    onPressed: canUpgrade
                                        ? () {
                                            controller.dispatch(
                                              UpgradeHarborMonument(monumentId),
                                            );
                                            setDialogState(() {});
                                            setState(() {});
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                def.subtitle,
                                style: InkTheme.body.copyWith(fontSize: 12.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Next Rank ($nextRank) Cost: ${_formatUnlockCost(nextCost)}',
                                style: InkTheme.caption.copyWith(
                                  color: canUpgrade
                                      ? InkTheme.goldAccent
                                      : InkTheme.crimsonAccent,
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
          color: isSelected
              ? InkTheme.crimsonAccent
              : InkTheme.parchmentHighlight,
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
                fontSize: 12,
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
                            controller.session.seaChart.currentPortName
                                .toUpperCase(),
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
                          icon: const Icon(
                            Icons.settings,
                            color: InkTheme.inkPrimary,
                          ),
                          tooltip: 'Settings & Accessibility',
                          onPressed: () => SettingsDialog.show(context),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: InkTheme.parchmentHighlight,
                            border: Border.all(
                              color: InkTheme.goldAccent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const SvgAssetView(
                                assetPath: PilotArt.treasure,
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${ship?.gold ?? 0}g',
                                style: InkTheme.statValue.copyWith(
                                  fontSize: 18,
                                  color: InkTheme.goldAccent,
                                ),
                              ),
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
                                  Text(
                                    ship.name,
                                    style: InkTheme.titleMedium.copyWith(
                                      fontSize: 24,
                                    ),
                                  ),
                                  Text(
                                    'Captain ${controller.captainName} • Level ${ship.level} ${ship.shipClass.name.toUpperCase()}',
                                    style: InkTheme.caption.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  HullGauge(
                                    currentHp: ship.currentHp,
                                    maxHp: ship.maxHp,
                                  ),
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
                                'FORTIFY DEF',
                                '-${ship.currentDmgReduction} Dmg',
                              ),
                              ShipClass.corvette ||
                              ShipClass.clipper => _vesselStat(
                                'EVASION',
                                '${ship.currentEvasion}% Eva',
                              ),
                              ShipClass.freighter => _vesselStat(
                                'HEIR STASH',
                                '5% Gold & Provisions',
                              ),
                              ShipClass.corsair => _vesselStat(
                                'TACTICAL RIG',
                                'Harpoon Winch',
                              ),
                              ShipClass.standard => _vesselStat(
                                'DEFENSE',
                                'Reinforced',
                              ),
                              ShipClass.bombardier => _vesselStat(
                                'SIEGE MORTAR',
                                'Heavy Blast',
                              ),
                            },
                            _vesselStat(
                              'TACTICAL BELT',
                              '${ship.cargo.length} / ${ship.maxCargo} Slots',
                            ),
                            _vesselStat(
                              'HARDPOINTS',
                              '3 Mounts (${ship.markLabelForHardpoint(HardpointType.broadside)}/${ship.markLabelForHardpoint(HardpointType.signature)}/${ship.markLabelForHardpoint(HardpointType.utility)})',
                            ),
                            _vesselStat(
                              'MONSTERS SLAIN',
                              '${controller.session.monstersDefeatedThisLife}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                // Inspect fixed hardpoints and manage the tactical belt
                ArmoryView(controller: controller),

                const SizedBox(height: 18),

                // Covenant Altar of the Deep (Unlocked upon claiming Leviathan Core)
                if (profile.hasUnlockedCovenant) ...[
                  ParchmentCard(
                    borderColor: InkTheme.crimsonAccent,
                    backgroundColor: InkTheme.crimsonAccent.withValues(
                      alpha: 0.05,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Placeholder; replace with curated Covenant art (BACKLOG art pass).
                        const Icon(
                          Icons.local_fire_department,
                          color: InkTheme.crimsonAccent,
                          size: 28,
                        ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: InkTheme.crimsonAccent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'BURDEN: ${profile.totalPactBurden}',
                                      style: InkTheme.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                                'The altar hums in the captain’s quarters. Enact Pacts for Primordial Cinders, forge Eldritch Relics, or consecrate Harbor Monuments.',
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

                // Port actions wrap to retain readable labels on narrow screens.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth < 550
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 8) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InkButton(
                          width: width,
                          label: 'MERCHANT',
                          onPressed: () =>
                              controller.dispatch(const VisitMerchant()),
                        ),
                        InkButton(
                          width: width,
                          label: 'BLUEPRINTS',
                          onPressed: () => _showBlueprintsDialog(context),
                        ),
                        InkButton(
                          width: width,
                          label: 'SEA CHART',
                          onPressed: onOpenChart,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                // Expedition Departure Route Selector (Charted Waypoints)
                // Main Expedition Departure Button
                InkButton(
                  label: controller.session.seaChart.currentRegionIndex == 0
                      ? 'VENTURE OUT TO SEA'
                      : 'SET SAIL FOR ${controller.session.seaChart.currentRegionName.toUpperCase()}',
                  isPrimary: true,
                  onPressed: () => controller.dispatch(const VentureOutToSea()),
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
