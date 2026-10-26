import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../battle/monstrous_sea_battle_game.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/combat_log_view.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/ocean_power_badges.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pause_menu.dart';

/// Battle-facing effect copy; shared by the compact buttons and their help.
extension on ConsumableType {
  ({String summary, String details}) get beltEffect => switch (this) {
    ConsumableType.hullPatchKit => (
      summary: 'Repair 30% hull',
      details: 'Restore 30% of maximum hull, subject to healing restrictions.',
    ),
    ConsumableType.krakenInkBomb => (
      summary: '+25% evasion',
      details: 'Shroud the ship in smoke, granting +25% evasion.',
    ),
    ConsumableType.alchemicalPitch => (
      summary: '+25% volley + Burn',
      details: 'Boost the next volley damage by 25%; hits apply Burn.',
    ),
    ConsumableType.unstableTincture => (
      summary: 'Random Burn, Poison or Stun',
      details: 'Inflict a random Burn, Poison or Stun with no initial damage.',
    ),
    ConsumableType.blastPack => (
      summary: '5 Blast · 75% hit',
      details:
          '75% hit chance for 5 base Blast damage; double damage to Carapace.',
    ),
    ConsumableType.chakram => (
      summary: '5 Slicing · 75% hit',
      details: '75% hit chance for 5 base Slicing damage.',
    ),
  };
}

/// Interactive naval combat screen displaying the Flame battle scene,
/// ship and monster vitality gauges, weapon volley triggers, and combat chronicle.
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.controller, this.game});

  final GameController controller;
  final MonstrousSeaBattleGame? game;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late MonstrousSeaBattleGame _battleGame;
  bool _isActionLocked = false;
  bool _showLog = true;
  HelmOrder _selectedHelmOrder = HelmOrder.holdLine;
  final GlobalKey _statusKey = GlobalKey();
  final GlobalKey _dockKey = GlobalKey();

  void _syncArenaInsets() {
    if (!mounted) return;
    final status = _statusKey.currentContext?.findRenderObject() as RenderBox?;
    final dock = _dockKey.currentContext?.findRenderObject() as RenderBox?;
    if (status == null || dock == null || !status.hasSize || !dock.hasSize) {
      return;
    }
    _battleGame.setArenaInsets(
      top: 16 + status.size.height + 9,
      bottom: 16 + dock.size.height + 9,
    );
  }

  @override
  void initState() {
    super.initState();
    _battleGame =
        widget.game ??
        MonstrousSeaBattleGame(
          ship: widget.controller.ship!,
          monster: widget.controller.currentMonster!,
        );
    _battleGame.artworkRevision.addListener(_onArtworkChanged);
  }

  void _onArtworkChanged() {
    if (mounted) setState(() {});
  }

  String? _beltRestriction(Consumable item, int used, int limit) {
    if (item.isDepleted) return 'This item has already been spent.';
    if (_isActionLocked) return 'Wait for the current action to finish.';
    if (used >= limit) {
      return 'Quick-item limit reached this round ($used/$limit used). '
          'Use a hardpoint action to finish the round.';
    }
    return null;
  }

  void _showBeltHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final limit =
              widget.controller.session.activeBoon?.id ==
                  BloodlineTraitId.drillmaster
              ? 2
              : 1;
          final used = widget.controller.session.quickConsumablesUsedThisTurn;
          final items = widget.controller.ship!.cargo.whereType<Consumable>();
          return AlertDialog(
            backgroundColor: InkTheme.parchmentSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: InkTheme.inkPrimary, width: 2),
            ),
            title: Text('TACTICAL BELT', style: InkTheme.titleMedium),
            scrollable: true,
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Each item is single-use and does not end your turn '
                    '(0 turn cost). You can still give a helm order and use a hardpoint.',
                    style: InkTheme.body,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use one quick item per round, or two with Drillmaster. '
                    'A hardpoint action or Brace & Reload (when available) '
                    'finishes the round and refreshes this limit.',
                    style: InkTheme.body,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Used this round: $used/$limit',
                    style: InkTheme.statLabel,
                  ),
                  for (final item in items) ...[
                    const Divider(color: InkTheme.inkMuted),
                    Text(item.name, style: InkTheme.titleMedium),
                    Text(item.type == ConsumableType.hullPatchKit
                        ? 'Restore ${widget.controller.hullPatchHealingHp} hull HP.'
                        : item.type.beltEffect.details, style: InkTheme.body),
                    if (item.isDepleted)
                      Text('Already spent.', style: InkTheme.caption),
                  ],
                ],
              ),
            ),
            actions: [
              InkButton(
                label: 'CLOSE',
                compact: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _artRecoveryNotice() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Illustration unavailable. Battle actions remain ready.', style: InkTheme.caption),
      TextButton(
        onPressed: _battleGame.isRetryingArtwork ? null : _battleGame.retryArtwork,
        child: Text(_battleGame.isRetryingArtwork ? 'LOADING ART...' : 'RETRY ART'),
      ),
    ],
  );

  @override
  void dispose() {
    _battleGame.artworkRevision.removeListener(_onArtworkChanged);
    super.dispose();
  }

  String _utilityLabel(ShipState ship) {
    final slot = ship.hardpoints
        .where((h) => h.type.canonical == HardpointType.utility)
        .firstOrNull;
    if (slot != null) return slot.name;
    return switch (ship.shipClass) {
      ShipClass.ironclad => 'Fortify Iron Plates',
      ShipClass.corvette || ShipClass.clipper => 'Evasive Rigging',
      ShipClass.corsair || ShipClass.freighter => 'Drifting Tether-Trap',
      ShipClass.bombardier => 'Phosphor Spotter Flare',
      ShipClass.standard => 'Gunnery Drill',
    };
  }

  String _utilityTooltip(ShipState ship, CombatRange previewRange) {
    final bpId = BlueprintId.values
        .where((b) => b.name == ship.blueprintId)
        .firstOrNull;
    final mult = ship.multiplierForHardpointMark(HardpointType.utility);
    return switch (bpId) {
      BlueprintId.ironclad =>
        'Fortify Iron Plates (2T CD): Permanently adds +${(ship.dmgReductionMod * mult).round()} Damage Reduction for this battle and anchors your hull against forced push/pull this round.',
      BlueprintId.clipper => 'Evasive Rigging (2T CD): Doubles current Evasion until next dodge and shifts 1 range band away from the monster.',
      BlueprintId.corsair =>
        'Drifting Tether-Trap (2T CD): Launches a floating tether-mine 1 band ahead (${previewRange == CombatRange.short
            ? 'Instant detonation at Short!'
            : previewRange == CombatRange.medium
            ? 'Sets at distance 1'
            : 'Sets at distance 2'}). Detonates for ${(16 + 5 * (ship.level - 1) * mult).round()} Slicing damage and Pins the beast (1T).',
      BlueprintId.bombardier => 'Phosphor Spotter Flare (2T CD): Illuminates the monster for 2 turns — clears Obscured, suppresses monster Evasion to 0%, grants +15% Accuracy, and increases Blast damage taken by +25%.',
      _ =>
        'Gunnery Drill (2T CD): Reduces incoming damage by ${(20 * mult).round()}% this round and empowers your next offensive volley with +15% Accuracy and +${(20 * mult).round()}% Damage.',
    };
  }

  void _dispatchCombatAction(Command command) {
    if (_isActionLocked) return;

    setState(() {
      _isActionLocked = true;
    });

    final isTurnEndingAction =
        command is FireWeaponVolley ||
        command is ExecuteShipSpecialAction ||
        command is BraceForImpact;
    final isCombatAction = isTurnEndingAction || command is UseConsumableItem;

    if (isCombatAction) {
      widget.controller.setIsPlayingEvents(true);
    }

    final events = <GameEvent>[];

    // If an advance or fall back order was selected, execute helm order before turn-ending actions
    final currentRange = widget.controller.combatRange;
    final isGrappled = widget.controller.ship?.isGrappled ?? false;
    final activeOrder =
        (!isGrappled &&
            currentRange.availableHelmOrders.contains(_selectedHelmOrder))
        ? _selectedHelmOrder
        : HelmOrder.holdLine;

    if (activeOrder != HelmOrder.holdLine && isTurnEndingAction &&
        !widget.controller.isImpatientCombinationPending) {
      events.addAll(
        widget.controller.dispatch(
          IssueHelmOrder(activeOrder),
          deferNotification: true,
        ),
      );
    }

    events.addAll(
      widget.controller.dispatch(command, deferNotification: isCombatAction),
    );

    if (isTurnEndingAction) {
      // Reset selected helm order to holdLine for subsequent round
      _selectedHelmOrder = HelmOrder.holdLine;
    }

    _battleGame.playEvents(events, () async {
      final isBattleEnding = widget.controller.phase != SessionPhase.battle;
      if (isBattleEnding) {
        // Allow damage numbers, animations, and fatal blow to settle before transitioning
        await Future.delayed(const Duration(milliseconds: 1400));
      }
      if (mounted) {
        setState(() {
          _isActionLocked = false;
        });
        if (isCombatAction) {
          widget.controller.setIsPlayingEvents(false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Register dependency on MediaQuery so window resizing re-triggers build and insets sync
    final _ = MediaQuery.of(context).size;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncArenaInsets());
    final ship = widget.controller.ship;
    final monster = widget.controller.currentMonster;
    if (ship == null || monster == null) {
      return const ParchmentScaffold(
        showPauseButton: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentRange = widget.controller.combatRange;
    final activeHelmOrder =
        (!ship.isGrappled &&
            currentRange.availableHelmOrders.contains(_selectedHelmOrder))
        ? _selectedHelmOrder
        : HelmOrder.holdLine;
    final enemyPreviewRange = currentRange.rangeAfterHelmOrder(activeHelmOrder);
    final previewRange = widget.controller.usesLateHelm ? currentRange : enemyPreviewRange;
    final canFireAnyWeapon = ship.equippedWeaponTypes.any((type) {
      final ready = ship.equippedWeapons
          .where((w) => w.weaponType == type)
          .any((w) => w.isReady);
      final usable = isWeaponTypeUsableAtRange(type, previewRange);
      return ready && usable;
    });

    final maxQuickBeltUses =
        widget.controller.activeBoon?.id == BloodlineTraitId.drillmaster
        ? 2
        : 1;
    final quickUsed = widget.controller.session.quickConsumablesUsedThisTurn;
    // Quick items and helm orders cannot end the turn. Keep an emergency pass
    // only when every offensive and utility hardpoint is unavailable.
    final needsEmergencyPass = !widget.controller.isImpatientCombinationPending &&
        (widget.controller.isImpatientRecovering || widget.controller.usesLateHelm ||
        (!canFireAnyWeapon && !ship.isUtilityReady));

    return ParchmentScaffold(
      showBorder: false,
      showPauseButton: false,
      body: Stack(
        children: [
          // 1. Flame 2D Battle Arena
          // The arena only renders events. Flame otherwise captures Tab before
          // Flutter can move focus between the actual battle controls.
          Positioned.fill(
            child: ExcludeFocus(
              child: GameWidget(game: _battleGame, autofocus: false),
            ),
          ),

          // 2. Top HUD: Combatant Vitality & Stats
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              key: _statusKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ship Status Panel (Left)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: InkTheme.parchmentSurface.withValues(alpha: 0.9),
                      border: Border.all(
                        color: InkTheme.inkPrimary,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ship.name,
                          style: InkTheme.titleMedium.copyWith(fontSize: 20),
                        ),
                        Text(
                          'Level ${ship.level} ${ship.shipClass.name.toUpperCase()}'
                          '${ship.currentDmgReduction > 0 ? ' • Fortified: -${ship.currentDmgReduction} Dmg' : ''}'
                          '${ship.currentEvasion + ship.captainEvasionBonus > 0 ? ' • Evade: ${ship.currentEvasion + ship.captainEvasionBonus}%' : ''}'
                          '${ship.isAnchoredThisTurn ? ' • Anchored' : ''}'
                          '${ship.gunneryDrillBuffActive ? ' • Drill Ready (+15% Accuracy/+20% Damage)' : ''}'
                          '${ship.pitchCoatingActive ? ' • Pitch Coated (+25% Fire/Burn)' : ''}',
                          style: InkTheme.caption,
                        ),
                        const SizedBox(height: 8),
                        HullGauge(currentHp: ship.currentHp, maxHp: ship.maxHp),
                        ShipPowerStatusBadges(ship: ship),
                        if (_battleGame.isShipArtUnavailable) _artRecoveryNotice(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Monster Status Panel (Right)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: InkTheme.parchmentSurface.withValues(alpha: 0.9),
                      border: Border.all(
                        color:
                            (monster.isApex || monster.name.contains('Kraken'))
                            ? InkTheme.crimsonAccent
                            : InkTheme.inkPrimary,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                monster.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: InkTheme.titleMedium.copyWith(
                                  fontSize: 20,
                                  color:
                                      (monster.isApex ||
                                          monster.name.contains('Kraken'))
                                      ? InkTheme.crimsonAccent
                                      : InkTheme.inkPrimary,
                                ),
                              ),
                            ),
                            if (monster.isApex)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: InkTheme.crimsonAccent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  'APEX',
                                  style: InkTheme.caption.copyWith(
                                    color: InkTheme.parchmentHighlight,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Tooltip(
                          message: monster.obscurityAccuracyPenalty > 0
                              ? 'Obscurity lowers shot accuracy by ${monster.obscurityAccuracyPenalty}%, separately from dodge. Successful hits have a 25% chance to disperse it; Spotter Flare clears it. There is no fixed turn duration.'
                              : '',
                          child: Text(
                            'Danger Level ${monster.level}'
                            '${monster.numberOfTentacles > 0 ? ' • ${monster.numberOfTentacles} Tentacles' : ''}'
                            '${monster.frenzyStacks > 0 ? ' • Frenzy: +${monster.frenzyStacks * 25}%' : ''}'
                            '${monster.evasion > 0 ? ' • Dodge: ${monster.effectiveEvasion}%' : ''}'
                            '${monster.obscurityAccuracyPenalty > 0 ? ' • Obscurity: -${monster.obscurityAccuracyPenalty}% shot accuracy' : ''}'
                            '${monster.isPinnedThisTurn ? ' • Pinned' : ''}'
                            '${monster.spotterFlareTurns > 0 ? ' • ☀️ Illuminated (${monster.spotterFlareTurns}T)' : ''}'
                            '${ship.activeTetherTrapDistance != null ? ' • 🪤 Trap: ${ship.activeTetherTrapDistance} Band${ship.activeTetherTrapDistance == 1 ? '' : 's'}' : ''}',
                            style: InkTheme.caption,
                          ),
                        ),
                        const SizedBox(height: 8),
                        HullGauge(
                          currentHp: monster.currentHp,
                          maxHp: monster.maxHp,
                          label: 'BEAST INTEGRITY',
                        ),
                        if (_battleGame.isMonsterArtUnavailable) _artRecoveryNotice(),
                        MonsterPowerStatusBadges(monster: monster),
                        if (monster.species == MonsterSpecies.crustacean ||
                            monster.maxCarapace > 0) ...[
                          const SizedBox(height: 8),
                          if (monster.carapacePlating > 0) ...[
                            Semantics(
                              label: 'Carapace Armor Plating',
                              value:
                                  '${monster.carapacePlating} of ${monster.maxCarapace} plating intact. Deflects non-blast attacks.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'CARAPACE ARMOR',
                                          style: InkTheme.statLabel.copyWith(
                                            color: const Color(0xFF6B4226),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${monster.carapacePlating}/${monster.maxCarapace} PLATES',
                                        style: InkTheme.statValue.copyWith(
                                          color: const Color(0xFF6B4226),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Stack(
                                    children: [
                                      Container(
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: InkTheme.parchmentDark,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF6B4226),
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: monster.maxCarapace > 0
                                            ? (monster.carapacePlating /
                                                      monster.maxCarapace)
                                                  .clamp(0.0, 1.0)
                                            : 0.0,
                                        child: Container(
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5A2B),
                                            borderRadius: BorderRadius.circular(
                                              1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Deflects standard shots. Shatter with Blast/Culverin!',
                                    style: InkTheme.caption.copyWith(
                                      fontSize: 10.5,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFF6B4226),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: InkTheme.crimsonAccent.withValues(
                                  alpha: 0.12,
                                ),
                                border: Border.all(
                                  color: InkTheme.crimsonAccent,
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 14,
                                    color: InkTheme.crimsonAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'CARAPACE SHATTERED (Vulnerable)',
                                      style: InkTheme.caption.copyWith(
                                        color: InkTheme.crimsonAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Action Dock
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              key: _dockKey,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: InkTheme.parchmentSurface.withValues(alpha: 0.95),
                border: Border.all(color: InkTheme.inkPrimary, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dedicated prominent Chronicle Log above weapon selection
                  if (_showLog) ...[
                    Builder(
                      builder: (ctx) {
                        final screenHeight = MediaQuery.of(ctx).size.height;
                        final logHeight =
                            (screenHeight * (screenHeight <= 650 ? 0.08 : 0.16))
                                .clamp(48.0, 200.0);
                        return Container(
                          height: logHeight,
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: InkTheme.parchmentDark.withValues(
                              alpha: 0.25,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: InkTheme.inkMuted,
                              width: 1,
                            ),
                          ),
                          child: CombatLogView(
                            entries: widget.controller.structuredCombatLog,
                          ),
                        );
                      },
                    ),
                  ],
                  // Tactical Bearing & Bounded Helm Order Bar
                  _buildTacticalBearingBar(
                    currentRange,
                    enemyPreviewRange,
                    activeHelmOrder,
                    ship,
                    monster,
                  ),

                  // Primary 3-Hardpoint Action Row (1. Broadside, 2. Signature, 3. Utility)
                  Row(
                    children: [
                      ...ship.equippedWeaponTypes.map((type) {
                        final weaponsOfType = ship.equippedWeapons
                            .where((w) => w.weaponType == type)
                            .toList();
                        final readyCount = weaponsOfType
                            .where((w) => w.isReady)
                            .length;
                        final isReady = readyCount > 0;
                        final maxCd = weaponsOfType.fold<int>(
                          0,
                          (prev, w) => w.chargeCountdown > prev
                              ? w.chargeCountdown
                              : prev,
                        );
                        final isUsableAtRange = isWeaponTypeUsableAtRange(
                          type,
                          previewRange,
                        );
                        final canFire =
                            isReady && isUsableAtRange && !_isActionLocked &&
                            !widget.controller.isImpatientRecovering;
                        final badgeInfo = _getTacticalWeaponBadge(
                          type,
                          previewRange,
                        );
                        final slot =
                            type == ship.resolvedBlueprintId.signatureWeaponType
                            ? HardpointType.signature
                            : type ==
                                  ship.resolvedBlueprintId.broadsideWeaponType
                            ? HardpointType.broadside
                            : null;
                        final blessing = ship.blessings[slot];
                        final ignoresObscurity =
                            type == ShipWeaponType.precisionCulverin &&
                            widget.controller.profile.isEldritchRelicActive(
                              EldritchRelicId.ghostwakeCulverin,
                            );
                        final shotAccuracy = calculateHitChance(
                          ship,
                          weaponsOfType.first,
                          monster,
                          accuracyBonus: widget.controller.gunneryAccuracyBoon +
                              widget.controller.captainWeaponAccuracyModifier +
                              (ship.gunneryDrillBuffActive ? 15 : 0),
                          range: previewRange,
                          ignoreObscurity: ignoresObscurity,
                        );
                        final accuracyTip =
                            'Opening shot accuracy: $shotAccuracy% before ${monster.effectiveEvasion}% target dodge.'
                            '${ignoresObscurity ? ' Ghostwake ignores obscurity.' : monster.obscurityAccuracyPenalty > 0 ? ' Obscurity subtracts ${monster.obscurityAccuracyPenalty}% from accuracy.' : ''}';

                        final labelText = weaponsOfType.length == 1
                            ? (isReady
                                  ? type.displayName
                                  : '${type.displayName} (${maxCd}T CD)')
                            : '${type.displayName} ($readyCount/${weaponsOfType.length})';

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (blessing != null)
                                  BlessingBadge(blessing: blessing),
                                Tooltip(
                                  message: '${badgeInfo?.tip ?? ''} $accuracyTip\n${_responseForecast(activeHelmOrder, weaponType: type)}',
                                  child: InkButton(
                                    label: labelText,
                                    subtitle: isReady
                                        ? badgeInfo?.badge
                                        : 'RELOADING (${maxCd}T)',
                                    subtitleColor:
                                        !isReady || badgeInfo?.isWarning == true
                                        ? InkTheme.crimsonAccent
                                        : InkTheme.goldAccent,
                                    semanticLabel: !isUsableAtRange
                                        ? '${type.displayName} volley out of range at ${previewRange.displayName}. Advance to strike!'
                                        : isReady
                                        ? 'Fire ${type.displayName} volley at ${previewRange.displayName}. $readyCount of ${weaponsOfType.length} ready.${badgeInfo != null ? ' ${badgeInfo.badge}.' : ''}'
                                        : '${type.displayName} volley reloading ($maxCd turns remaining).',
                                    isPrimary: canFire,
                                    onPressed: canFire
                                        ? () => _dispatchCombatAction(
                                            FireWeaponVolley(type),
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      // 3. Utility Hardpoint Button (2T Cooldown across all ships)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: Builder(
                            builder: (context) {
                              final utilName = _utilityLabel(ship);
                              final utilMark = ship.markLabelForHardpoint(
                                HardpointType.utility,
                              );
                              final utilReady = ship.isUtilityReady;
                              final blessing =
                                  ship.blessings[HardpointType.utility];
                              final canUseUtil = utilReady && !_isActionLocked &&
                                  !widget.controller.isImpatientCombinationPending &&
                                  !widget.controller.isImpatientRecovering;
                              final utilSubtitle = utilReady
                                  ? 'UTILITY ($utilMark • 2T CD)'
                                  : 'COOLDOWN (${ship.utilityCooldown}T)';

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (blessing != null)
                                    BlessingBadge(blessing: blessing),
                                  Tooltip(
                                    message: '${_utilityTooltip(ship, previewRange)}\n${_responseForecast(activeHelmOrder, utility: true)}',
                                    child: InkButton(
                                      label: utilName,
                                      subtitle: utilSubtitle,
                                      subtitleColor: utilReady
                                          ? InkTheme.goldAccent
                                          : InkTheme.crimsonAccent,
                                      semanticLabel: utilReady
                                          ? 'Activate $utilName utility hardpoint ($utilMark)'
                                          : '$utilName utility hardpoint cooling down (${ship.utilityCooldown} turns remaining)',
                                      isPrimary: false,
                                      onPressed: canUseUtil
                                          ? () => _dispatchCombatAction(
                                              const ExecuteShipSpecialAction(),
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (widget.controller.canStartImpatientCombination)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const ValueKey('impatient-combination'),
                        onPressed: _isActionLocked ? null : () => _dispatchCombatAction(
                          const ExecuteShipSpecialAction(borrowNextAction: true),
                        ),
                        child: const Text('IMPATIENT · UTILITY + WEAPON'),
                      ),
                    ),
                  if (widget.controller.isImpatientCombinationPending ||
                      widget.controller.isImpatientRecovering)
                    Text(
                      widget.controller.isImpatientCombinationPending
                          ? 'IMPATIENT · Fire one weapon next. Belt available; helm already committed.'
                          : 'RECOVERY · Hardpoints unavailable. Maneuver, use belt, or Brace & Reload.',
                      key: const ValueKey('impatient-status'),
                      style: InkTheme.caption,
                    ),

                  // Secondary Row: Tactical Consumable Belt (0T Quick Actions), Brace for Impact & Log Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Emergency action for future cooldown/range constraints.
                            if (needsEmergencyPass)
                              InkButton(
                                key: const ValueKey('emergency-pass'),
                                label: 'BRACE & RELOAD',
                                isPrimary: true,
                                semanticLabel: 'Brace for 10% temporary evasion, finish the turn and reload.',
                                onPressed: !_isActionLocked
                                    ? () => _dispatchCombatAction(
                                        const BraceForImpact(),
                                      )
                                    : null,
                              ),

                            // Tactical Belt Consumables (0T Quick Action)
                            if (ship.cargo.whereType<Consumable>().isNotEmpty)
                              IconButton(
                                key: const ValueKey('belt-help'),
                                icon: const Icon(
                                  Icons.help_outline,
                                  size: 20,
                                  color: InkTheme.inkSecondary,
                                ),
                                tooltip: 'Belt help',
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: const EdgeInsets.all(6),
                                onPressed: _showBeltHelp,
                              ),
                            for (var i = 0; i < ship.cargo.length; i++)
                              if (ship.cargo[i] is Consumable)
                                Builder(
                                  builder: (context) {
                                    final cons = ship.cargo[i] as Consumable;
                                    final effect = cons.type == ConsumableType.hullPatchKit
                                        ? (summary: 'Repair ${widget.controller.hullPatchHealingHp} HP',
                                           details: 'Restore ${widget.controller.hullPatchHealingHp} hull HP.')
                                        : cons.type.beltEffect;
                                    final restriction = _beltRestriction(
                                      cons,
                                      quickUsed,
                                      maxQuickBeltUses,
                                    );
                                    final details = restriction == null
                                        ? effect.details
                                        : '${effect.details}\n$restriction';
                                    return Tooltip(
                                      message: details,
                                      child: InkButton(
                                        label: cons.name,
                                        subtitle: effect.summary,
                                        subtitleColor: InkTheme.inkSecondary,
                                        compact: true,
                                        semanticLabel: cons.name,
                                        semanticHint: details,
                                        onPressed: restriction == null
                                            ? () => _dispatchCombatAction(
                                                UseConsumableItem(i),
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),

                      // Bottom-right Utility Controls: Settings & Chronicle Log
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PauseMenuButton(),
                          IconButton(
                            icon: Icon(
                              _showLog ? Icons.menu_book : Icons.book,
                              color: InkTheme.inkPrimary,
                            ),
                            tooltip: 'Chronicle Log',
                            onPressed: () =>
                                setState(() => _showLog = !_showLog),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _responseForecast(HelmOrder order, {ShipWeaponType? weaponType, bool utility = false}) {
    final movesRange = weaponType == ShipWeaponType.prowRam ||
        weaponType == ShipWeaponType.harpoonWinch ||
        (utility && widget.controller.ship?.resolvedBlueprintId.utilityHardpoint == UtilityHardpointId.evasiveRigging);
    if (!movesRange) return '';
    final responseRange = widget.controller.previewResponseRange(
      helmOrder: order, weaponType: weaponType, utility: utility,
    );
    final monster = widget.controller.currentMonster;
    final outcome = monster?.currentIntent?.evaluatePreview(
      currentRange: responseRange,
      selectedHelmOrder: HelmOrder.holdLine,
      isMonsterPinned: monster.isPinnedThisTurn,
      tentacleCount: monster.numberOfTentacles,
      damagePerTentacle: monster.usableWeapons
          .where((w) => w.monsterWeaponType == MonsterWeaponType.tentacle)
          .firstOrNull?.damage,
    );
    return 'After action: ${responseRange.displayName}'
        '${outcome == null ? '' : ' · ${outcome.summaryBadge}'}';
  }

  Widget _buildTacticalBearingBar(
    CombatRange currentRange,
    CombatRange previewRange,
    HelmOrder activeHelmOrder,
    ShipState ship,
    MonsterState monster,
  ) {
    final intent = monster.currentIntent;
    final conditional = ship.equippedWeaponTypes.any((type) =>
        type == ShipWeaponType.prowRam || type == ShipWeaponType.harpoonWinch) ||
        ship.resolvedBlueprintId.utilityHardpoint == UtilityHardpointId.evasiveRigging;
    final previewOutcome = intent?.evaluatePreview(
      currentRange: currentRange,
      selectedHelmOrder: activeHelmOrder,
      isMonsterPinned: monster.isPinnedThisTurn,
      tentacleCount: monster.numberOfTentacles,
      damagePerTentacle: monster.usableWeapons
          .where((w) => w.monsterWeaponType == MonsterWeaponType.tentacle)
          .firstOrNull?.damage,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: InkTheme.parchmentDark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: InkTheme.inkMuted, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.controller.activeQuirk?.id == BloodlineTraitId.daredevil)
            Text(
              widget.controller.isDaredevilActive
                  ? 'DAREDEVIL · +30% weapon damage · at/below 50% hull'
                  : 'DAREDEVIL · Bonus activates at 50% hull or less',
              key: const ValueKey('daredevil-status'), style: InkTheme.caption,
            ),
          if (widget.controller.usesLateHelm)
            Text('SKIRMISHER · Act at ${currentRange.displayName}, then maneuver before the response.',
                key: const ValueKey('late-helm-hint'), style: InkTheme.caption),
          if (intent != null && previewOutcome != null) ...[
            if (conditional)
              Text('Actions may change this helm forecast.',
                  key: const ValueKey('conditional-range-forecast'), style: InkTheme.caption),
            _buildMonsterIntentReadout(intent, previewOutcome, monster, conditional: conditional),
            const SizedBox(height: 3),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;

              final bearingTrack = Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  Text(
                    'BEARING:',
                    style: InkTheme.statLabel.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: InkTheme.inkSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  for (final r in [
                    CombatRange.long,
                    CombatRange.medium,
                    CombatRange.short,
                  ]) ...[
                    _buildRangeTrackChip(
                      r,
                      currentRange,
                      previewRange,
                      isThreatened:
                          intent?.threatenedRanges.contains(r) ?? false,
                    ),
                    if (r != CombatRange.short)
                      Text(
                        '—',
                        style: TextStyle(
                          color: InkTheme.inkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ],
              );

              final helmOrders = Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  Text(
                    'HELM:',
                    style: InkTheme.statLabel.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: InkTheme.inkSecondary,
                    ),
                  ),
                  if (ship.isGrappled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: InkTheme.crimsonAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: InkTheme.crimsonAccent,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        'GRAPPLED',
                        style: InkTheme.caption.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: InkTheme.crimsonAccent,
                        ),
                      ),
                    ),
                  const SizedBox(width: 2),
                  for (final order in [
                    HelmOrder.fallBack,
                    HelmOrder.holdLine,
                    HelmOrder.advance,
                  ]) ...[
                    _buildHelmOrderPill(
                      order,
                      currentRange,
                      activeHelmOrder,
                      isGrappled: ship.isGrappled,
                    ),
                  ],
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    bearingTrack,
                    const SizedBox(height: 6),
                    helmOrders,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: bearingTrack),
                  const SizedBox(width: 12),
                  helmOrders,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterIntentReadout(
    MonsterIntent intent,
    IntentPreviewOutcome preview,
    MonsterState monster, {
    bool conditional = false,
  }) {
    final isSafe = preview.isSafe && !conditional;
    final isSevere =
        preview.status == IntentPreviewStatus.headOnCollisionDanger ||
        preview.status == IntentPreviewStatus.bossCatastropheImminent;

    final outcomeColor = conditional
        ? InkTheme.inkMuted
        : isSafe
        ? InkTheme.verdigrisGreen
        : isSevere
        ? InkTheme.crimsonAccent
        : const Color(0xFF9A6700);

    return Tooltip(
      message: '${intent.description}\nCounterplay: ${intent.tacticalTip}',
      child: Semantics(
        label:
            'Monster Intent: ${intent.name}. Threatens ${intent.threatenedRangesLabel}. ${conditional ? 'Helm-only forecast: ' : ''}${preview.summaryBadge}',
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 3,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              runSpacing: 2,
              children: [
                Text(
                  'INTENT: ${intent.name.toUpperCase()}',
                  style: InkTheme.statLabel.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                    color:
                        (intent.isBossWindup || intent.isBossCatastropheStrike)
                        ? InkTheme.crimsonAccent
                        : InkTheme.inkPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: InkTheme.crimsonAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: InkTheme.crimsonAccent.withValues(alpha: 0.6),
                      width: 0.9,
                    ),
                  ),
                  child: Text(
                    'HITS: ${intent.threatenedRangesLabel}',
                    style: InkTheme.caption.copyWith(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: InkTheme.crimsonAccent,
                    ),
                  ),
                ),
                if (intent.moveDelta != IntentMoveDelta.stationary)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: intent.moveTiming == IntentMoveTiming.beforeAttack
                          ? InkTheme.goldAccent.withValues(alpha: 0.18)
                          : InkTheme.parchmentSurface,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color:
                            intent.moveTiming == IntentMoveTiming.beforeAttack
                            ? InkTheme.goldAccent
                            : InkTheme.inkMuted,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      intent.moveLabel,
                      style: InkTheme.caption.copyWith(
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                        color:
                            intent.moveTiming == IntentMoveTiming.beforeAttack
                            ? InkTheme.inkPrimary
                            : InkTheme.inkSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: outcomeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: outcomeColor, width: 1.0),
              ),
              child: Text(
                '${conditional ? 'HELM ONLY · ' : ''}${preview.summaryBadge}',
                style: InkTheme.caption.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: outcomeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeTrackChip(
    CombatRange band,
    CombatRange currentRange,
    CombatRange previewRange, {
    bool isThreatened = false,
  }) {
    final isTargetDestination =
        band == previewRange && previewRange != currentRange;
    final isCurrentStation =
        band == currentRange && previewRange == currentRange;
    final isDepartingStation =
        band == currentRange && previewRange != currentRange;

    Color bgColor = Colors.transparent;
    Color borderColor = isThreatened
        ? InkTheme.crimsonAccent.withValues(alpha: 0.65)
        : InkTheme.inkMuted.withValues(alpha: 0.35);
    Color textColor = isThreatened ? InkTheme.crimsonAccent : InkTheme.inkMuted;
    FontWeight fontWeight = FontWeight.normal;
    String prefix = '';
    String suffix = '';

    if (isCurrentStation) {
      bgColor = InkTheme.inkPrimary;
      borderColor = isThreatened ? InkTheme.crimsonAccent : InkTheme.inkPrimary;
      textColor = InkTheme.parchmentHighlight;
      fontWeight = FontWeight.bold;
      prefix = '';
    } else if (isTargetDestination) {
      bgColor = InkTheme.goldAccent.withValues(alpha: 0.25);
      borderColor = InkTheme.goldAccent;
      textColor = InkTheme.inkPrimary;
      fontWeight = FontWeight.bold;
      suffix = ' ➔';
    } else if (isDepartingStation) {
      bgColor = InkTheme.parchmentDark.withValues(alpha: 0.2);
      borderColor = InkTheme.inkFaint;
      textColor = InkTheme.inkFaint;
    }

    final label = '$prefix${band.name.toUpperCase()}$suffix';

    return Semantics(
      label: isCurrentStation
          ? 'Current engagement distance: ${band.displayName}${isThreatened ? ' (Threatened by monster intent)' : ''}'
          : isTargetDestination
          ? 'Pending tactical bearing: ${band.displayName}${isThreatened ? ' (Threatened by monster intent)' : ' (Safe blind spot)'}'
          : '${band.displayName}${isThreatened ? ' (Threatened)' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Text(
          label,
          style: InkTheme.caption.copyWith(
            fontSize: 9.5,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHelmOrderPill(
    HelmOrder order,
    CombatRange currentRange,
    HelmOrder activeHelmOrder, {
    bool isGrappled = false,
  }) {
    final isAvailable =
        (!isGrappled || order == HelmOrder.holdLine) &&
        currentRange.availableHelmOrders.contains(order);
    final isSelected = activeHelmOrder == order;

    final IconData icon = switch (order) {
      HelmOrder.fallBack => Icons.arrow_back,
      HelmOrder.holdLine => Icons.anchor,
      HelmOrder.advance => Icons.arrow_forward,
    };

    final tooltip = switch (order) {
      _ when isGrappled && order != HelmOrder.holdLine =>
        'Ship is grappled! Helm is locked to Hold Line this round.',
      HelmOrder.fallBack when !isAvailable =>
        'Cannot fall back beyond Long Range',
      HelmOrder.fallBack =>
        'Order helm to fall back to ${currentRange.rangeAfterHelmOrder(order).displayName}',
      HelmOrder.holdLine =>
        'Hold current station at ${currentRange.displayName}',
      HelmOrder.advance when !isAvailable =>
        'Cannot advance closer than Short Range',
      HelmOrder.advance =>
        'Order helm to advance to ${currentRange.rangeAfterHelmOrder(order).displayName}',
    };

    final Color bgColor = isSelected
        ? InkTheme.inkPrimary
        : isAvailable
        ? InkTheme.parchmentSurface
        : InkTheme.parchmentDark.withValues(alpha: 0.25);

    final Color contentColor = isSelected
        ? InkTheme.parchmentHighlight
        : isAvailable
        ? InkTheme.inkPrimary
        : InkTheme.inkFaint;

    final Color borderColor = isSelected
        ? InkTheme.inkPrimary
        : isAvailable
        ? InkTheme.inkSecondary
        : InkTheme.inkFaint;

    final canPress = isAvailable && !_isActionLocked &&
        !widget.controller.isImpatientCombinationPending;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: canPress,
        selected: isSelected,
        label: 'Helm Order: ${order.displayName}. $tooltip',
        child: InkWell(
          onTap: canPress
              ? () => setState(() => _selectedHelmOrder = order)
              : null,
          borderRadius: BorderRadius.circular(3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: contentColor),
                const SizedBox(width: 3),
                Text(
                  order.displayName,
                  style: InkTheme.caption.copyWith(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: contentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _TacticalBadgeInfo? _getTacticalWeaponBadge(
    ShipWeaponType type,
    CombatRange targetRange,
  ) {
    final pct = (weaponRangeDamageMultiplier(type, targetRange) * 100).round();
    switch (type) {
      case ShipWeaponType.prowRam:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: 'OUT OF RANGE',
            tip: 'Cannot fire Prow Ram from Long Range. Advance to engage!',
            isWarning: true,
          );
        } else if (targetRange == CombatRange.medium) {
          return const _TacticalBadgeInfo(
            badge: '125% CHARGE',
            tip: 'Kinetic ram charge from Medium to Short Range (+25% bonus kinetic damage, 1.5x vs Carapace).',
          );
        }
        return const _TacticalBadgeInfo(
          badge: '100% RAM IMPACT',
          tip: 'Point-blank Prow Ram strike (100% damage, 1.5x vs Carapace).',
        );
      case ShipWeaponType.heavyMortar:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: '100% HIGH ARC',
            tip: 'Heavy Siege Mortar optimal Long Range (100% damage, 2.0x vs Carapace).',
          );
        } else if (targetRange == CombatRange.short) {
          return const _TacticalBadgeInfo(
            badge: '70% • 25% SPLASH',
            tip: 'Point-blank mortar fire at Short Range deals 70% damage and splashes 25% backfire onto your hull!',
            isWarning: true,
          );
        }
        return _TacticalBadgeInfo(
          badge: '$pct% CARAPACE BREAKER',
          tip: 'Heavy Siege Mortar at Medium Range (85% damage, 2.0x vs Carapace).',
        );
      case ShipWeaponType.precisionCulverin:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: '100% SNIPER',
            tip: 'Precision Culverin optimal Long Range (100% damage, pierces 50% Carapace).',
          );
        } else if (targetRange == CombatRange.short) {
          return const _TacticalBadgeInfo(
            badge: '40% CRAMPED',
            tip: 'Long-barrel culverin suffers severe damage falloff (40%) at Short Range.',
            isWarning: true,
          );
        }
        return _TacticalBadgeInfo(
          badge: '$pct% ARMOR PIERCER',
          tip: 'Precision Culverin at Medium Range (85% damage, pierces 50% Carapace).',
        );
      case ShipWeaponType.twinChasers:
        return _TacticalBadgeInfo(
          badge: pct == 100 ? '100% OPTIMAL' : '$pct% DMG',
          tip:
              'Twin Chaser Cannons ($pct% damage at ${targetRange.displayName}).',
        );
      case ShipWeaponType.cannon:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: '65% • -15% ACCURACY',
            tip: 'Standard broadside cannons deal 65% damage and suffer -15% accuracy at Long Range.',
            isWarning: true,
          );
        }
        return _TacticalBadgeInfo(
          badge: pct == 100 ? '100% OPTIMAL' : '$pct% POINT BLANK',
          tip:
              'Naval Cannon Battery ($pct% damage at ${targetRange.displayName}).',
        );
      case ShipWeaponType.heavyCarronade:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: '35% FALLOFF',
            tip: 'Short-barrel Heavy Carronades deal only 35% damage at Long Range.',
            isWarning: true,
          );
        }
        return _TacticalBadgeInfo(
          badge: pct == 100 ? '100% BRAWLER' : '$pct% DMG',
          tip: 'Heavy Carronades ($pct% damage at ${targetRange.displayName}).',
        );
      case ShipWeaponType.swivelGun:
        return _TacticalBadgeInfo(
          badge: pct == 100 ? '100% SKIRMISH' : '$pct% DMG',
          tip:
              'Long-Barrel Swivel Guns ($pct% damage at ${targetRange.displayName}).',
        );
      case ShipWeaponType.chainShotBroadside:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: '45% FALLOFF',
            tip: 'Chain-Shot Broadside deals 45% damage at Long Range (+20% vs Pinned targets).',
            isWarning: true,
          );
        }
        return _TacticalBadgeInfo(
          badge: pct == 100 ? '100% (+20% VS PIN)' : '$pct% (+20% VS PIN)',
          tip:
              'Chain-Shot Broadside ($pct% Slicing damage at ${targetRange.displayName}, +20% vs Pinned).',
        );
      case ShipWeaponType.shrapnelHowitzer:
        return _TacticalBadgeInfo(
          badge: pct == 100 ? '100% SLICING' : '$pct% SLICING',
          tip:
              'Shrapnel Howitzers ($pct% Slicing damage at ${targetRange.displayName}).',
        );
      case ShipWeaponType.harpoonWinch:
        if (targetRange != CombatRange.short) {
          return _TacticalBadgeInfo(
            badge: '$pct% • PULLS & PINS',
            tip:
                'Harpoon Winch deals $pct% damage, reels the monster 1 range band closer, and Pins it (1T).',
          );
        }
        return _TacticalBadgeInfo(
          badge: '$pct% • PINS BEAST',
          tip:
              'Harpoon Winch deals $pct% damage and Pins the monster at Short Range (1T).',
        );
      case ShipWeaponType.torpedoLauncher:
        return const _TacticalBadgeInfo(
          badge: 'BLAST BREACH',
          tip: 'Cracks carapace plates and breaches submerged hulls.',
        );
      case ShipWeaponType.bladeLauncher:
        return const _TacticalBadgeInfo(
          badge: 'SLICING SHARDS',
          tip: 'Whirling steel discs designed to sever tentacles and appendages.',
        );
      case ShipWeaponType.lightningRailgun:
        return const _TacticalBadgeInfo(
          badge: 'STUN DISCHARGE',
          tip: 'Galvanic rail discharge that can shock and stun beasts.',
        );
      case ShipWeaponType.flamethrower:
        return const _TacticalBadgeInfo(
          badge: 'BURNING JET',
          tip: 'Alchemical fire causing lingering burn damage over time.',
        );
    }
  }
}

class _TacticalBadgeInfo {
  const _TacticalBadgeInfo({
    required this.badge,
    required this.tip,
    this.isWarning = false,
  });

  final String badge;
  final String tip;
  final bool isWarning;
}
