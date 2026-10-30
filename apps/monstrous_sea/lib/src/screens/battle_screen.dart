import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../battle/monstrous_sea_battle_game.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/combat_log_view.dart';
import '../widgets/battle_chronicle_dialog.dart';
import '../widgets/battle_lookout.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/ocean_power_badges.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pause_menu.dart';
import '../widgets/utility_description.dart';

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
  late ({
    int quickUsed,
    bool combinationPending,
    bool recovering,
    bool canStartCombination,
    int hullPatchHp,
    int gunneryBoon,
  })
  _decisions;

  void _captureDecisions() {
    final controller = widget.controller;
    _decisions = (
      quickUsed: controller.session.quickConsumablesUsedThisTurn,
      combinationPending: controller.isImpatientCombinationPending,
      recovering: controller.isImpatientRecovering,
      canStartCombination: controller.canStartImpatientCombination,
      hullPatchHp: controller.hullPatchHealingHp,
      gunneryBoon: controller.gunneryAccuracyBoon,
    );
  }

  late MonstrousSeaBattleGame _battleGame;
  bool _isActionLocked = false;
  final _chronicleScroll = CombatLogScrollState();
  final _commandScroll = ScrollController();
  final _beltScroll = ScrollController();
  double _hudBottom = 160;
  double _dockHeight = 250;

  bool get _sideLookout {
    final viewport = MediaQuery.sizeOf(context);
    return viewport.width >= 1100 && viewport.height >= 700;
  }

  double get _lookoutWidth =>
      (MediaQuery.sizeOf(context).width * 0.22).clamp(240.0, 290.0);
  double get _commandHeightBudget {
    final height = MediaQuery.sizeOf(context).height;
    return (height - _hudBottom - 200).clamp(240.0, height * 0.65);
  }

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
    final top = 16 + status.size.height + 9;
    _battleGame.setArenaInsets(
      top: top,
      bottom: 16 + dock.size.height + 9,
      right: _sideLookout ? _lookoutWidth + 32 : 0,
    );
    if ((top - _hudBottom).abs() > 0.5 ||
        (dock.size.height - _dockHeight).abs() > 0.5) {
      setState(() {
        _hudBottom = top;
        _dockHeight = dock.size.height;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _captureDecisions();
    _battleGame =
        widget.game ??
        MonstrousSeaBattleGame(
          ship: widget.controller.ship!,
          monster: widget.controller.currentMonster!,
          initialRange: widget.controller.combatRange,
        );
    _battleGame.artworkRevision.addListener(_onArtworkChanged);
    _battleGame.presentation.addListener(_onArtworkChanged);
  }

  void _onArtworkChanged() {
    if (mounted) setState(() {});
  }

  String? _beltRestriction(Consumable item, int used, int limit) {
    if (item.isDepleted) return 'This item has already been spent.';
    if (_isActionLocked) return 'Wait for the current action to finish.';
    if (used >= limit) {
      return 'Quick-item limit reached this round ($used/$limit used). '
          'Use a fitting action to finish the round.';
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
          final used = _decisions.quickUsed;
          final items = _battleGame.ship.cargo.whereType<Consumable>();
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
                    '(0 turn cost). You can still give a helm order and use a fitting.',
                    style: InkTheme.body,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use one quick item per round, or two with Drillmaster. '
                    'A fitting action or Wait & Reload (when available) '
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
                    Text(
                      item.type == ConsumableType.hullPatchKit
                          ? 'Restore ${_decisions.hullPatchHp} hull HP.'
                          : item.type.beltEffect.details,
                      style: InkTheme.body,
                    ),
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
      Text(
        'Illustration unavailable. Battle actions remain ready.',
        style: InkTheme.caption,
      ),
      TextButton(
        onPressed: _battleGame.isRetryingArtwork
            ? null
            : _battleGame.retryArtwork,
        child: Text(
          _battleGame.isRetryingArtwork ? 'LOADING ART...' : 'RETRY ART',
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _commandScroll.dispose();
    _beltScroll.dispose();
    _battleGame.artworkRevision.removeListener(_onArtworkChanged);
    _battleGame.presentation.removeListener(_onArtworkChanged);
    super.dispose();
  }

  String _utilityLabel(ShipState ship) {
    final slot = ship.hardpoints
        .where((h) => h.type.canonical == HardpointType.utility)
        .firstOrNull;
    if (slot != null) return slot.displayName;
    return switch (ship.shipClass) {
      ShipClass.ironclad => 'Fortify Iron Plates',
      ShipClass.corvette || ShipClass.clipper => 'Evasive Rigging',
      ShipClass.corsair || ShipClass.freighter => 'Drifting Tether-Trap',
      ShipClass.bombardier => 'Phosphor Spotter Flare',
      ShipClass.standard => 'Gun-Deck Bracing',
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
      BlueprintId.clipper =>
        'Evasive Rigging: ${evasiveRiggingDescription(ship)}',
      BlueprintId.corsair =>
        'Drifting Tether-Trap (2T CD): Launches a floating tether-mine 1 band ahead (${previewRange == CombatRange.short
            ? 'Instant detonation at Short!'
            : previewRange == CombatRange.medium
            ? 'Sets at distance 1'
            : 'Sets at distance 2'}). Detonates for ${(16 + 5 * (ship.level - 1) * mult).round()} Slicing damage and Pins the beast (1T).',
      BlueprintId.bombardier => 'Phosphor Spotter Flare (2T CD): Illuminates the monster for 2 turns — clears Obscured, suppresses monster Evasion to 0%, grants +15% Accuracy, and increases Blast damage taken by +25%.',
      _ =>
        'Gun-Deck Bracing (2T CD): Set the hull and gun-deck braces to reduce incoming damage by ${(20 * mult).round()}% this round and steady your next offensive volley for +15% Accuracy and +${(20 * mult).round()}% Damage.',
    };
  }

  Future<void> _dispatchCombatAction(Command command) async {
    if (_isActionLocked) return;
    _captureDecisions();

    _battleGame.presentation.synchronizeIdle(
      widget.controller.ship!,
      widget.controller.currentMonster!,
      widget.controller.combatRange,
    );

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

    try {
      final events = <GameEvent>[];

      // If an advance or fall back order was selected, execute helm order before turn-ending actions
      final currentRange = widget.controller.combatRange;
      final isGrappled = widget.controller.ship?.isGrappled ?? false;
      final activeOrder =
          (!isGrappled &&
              currentRange.availableHelmOrders.contains(_selectedHelmOrder))
          ? _selectedHelmOrder
          : HelmOrder.holdLine;

      if (activeOrder != HelmOrder.holdLine &&
          isTurnEndingAction &&
          !_decisions.combinationPending) {
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

      await _battleGame.playEvents(events, () {});
      assert(
        _battleGame.ship.currentHp == widget.controller.ship!.currentHp &&
            _battleGame.monster.currentHp ==
                widget.controller.currentMonster!.currentHp &&
            _battleGame.monster.carapacePlating ==
                widget.controller.currentMonster!.carapacePlating &&
            _battleGame.monster.numberOfTentacles ==
                widget.controller.currentMonster!.numberOfTentacles,
        'Combat playback is missing a resolved outcome',
      );
      final isBattleEnding = widget.controller.phase != SessionPhase.battle;
      if (isBattleEnding) {
        // Allow damage numbers, animations, and fatal blow to settle before transitioning
        await Future.delayed(const Duration(milliseconds: 1400));
      }
    } finally {
      if (mounted) {
        _battleGame.presentation.finishControls(widget.controller.ship!);
        setState(() {
          _isActionLocked = false;
        });
        if (isCombatAction) {
          widget.controller.setIsPlayingEvents(false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Register dependency on MediaQuery so window resizing re-triggers build and insets sync
    final _ = MediaQuery.of(context).size;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncArenaInsets());
    final liveShip = widget.controller.ship;
    final liveMonster = widget.controller.currentMonster;
    if (liveShip == null || liveMonster == null) {
      return const ParchmentScaffold(
        showPauseButton: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isActionLocked && !widget.controller.isPlayingEvents) {
      _captureDecisions();
      _battleGame.presentation.synchronizeIdle(
        liveShip,
        liveMonster,
        widget.controller.combatRange,
      );
    }
    _battleGame.reducedMotion = MediaQuery.disableAnimationsOf(context);
    _battleGame.feedbackTextScale = MediaQuery.textScalerOf(context).scale(1);
    final ship = _battleGame.presentation.ship;
    final monster = _battleGame.presentation.monster;
    final currentRange = _battleGame.presentation.range;
    final activeHelmOrder =
        (!ship.isGrappled &&
            currentRange.availableHelmOrders.contains(_selectedHelmOrder))
        ? _selectedHelmOrder
        : HelmOrder.holdLine;
    final enemyPreviewRange = currentRange.rangeAfterHelmOrder(activeHelmOrder);
    final previewRange = widget.controller.usesLateHelm
        ? currentRange
        : enemyPreviewRange;
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
    final quickUsed = _decisions.quickUsed;
    // Recovery blocks all fittings. Otherwise, offer a pass only when no
    // offensive or utility fitting can end the turn; helm/belt cannot do so.
    final needsEmergencyPass =
        !_decisions.combinationPending &&
        (_decisions.recovering || (!canFireAnyWeapon && !ship.isUtilityReady));

    return ParchmentScaffold(
      showBorder: false,
      showPauseButton: false,
      body: Stack(
        children: [
          Semantics(
            liveRegion: true,
            label: _battleGame.presentation.announcement,
            child: const SizedBox.shrink(),
          ),
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
                        Tooltip(
                          message: 'Current dodge chance after captain, regional and active-effect modifiers, capped at 95%. Unavoidable attacks bypass dodge.',
                          child: Text(
                            key: const ValueKey('ship-combat-stats'),
                            'Level ${ship.level} ${ship.shipClass.name.toUpperCase()}'
                            '${ship.currentDmgReduction > 0 ? ' • Fortified: -${ship.currentDmgReduction} Dmg' : ''}'
                            ' • Evade: ${ship.effectiveEvasion}%'
                            '${ship.isAnchoredThisTurn ? ' • Anchored' : ''}'
                            '${ship.gunneryDrillBuffActive ? ' • Braced Volley (+15% Accuracy/+20% Damage)' : ''}'
                            '${ship.pitchCoatingActive ? ' • Pitch Coated (+25% Fire/Burn)' : ''}',
                            style: InkTheme.caption,
                          ),
                        ),
                        const SizedBox(height: 8),
                        HullGauge(
                          currentHp: ship.currentHp,
                          maxHp: ship.maxHp,
                          animationDuration: const Duration(milliseconds: 140),
                        ),
                        ShipPowerStatusBadges(ship: ship),
                        if (_battleGame.isShipArtUnavailable)
                          _artRecoveryNotice(),
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
                          message:
                              'Current dodge chance after Pin and Spotter Flare. Attack accuracy is a separate roll.'
                              '${monster.obscurityAccuracyPenalty > 0 ? ' Obscurity lowers shot accuracy by ${monster.obscurityAccuracyPenalty}%, separately from dodge. Successful hits have a 25% chance to disperse it; Spotter Flare clears it. There is no fixed turn duration.' : ''}',
                          child: Text(
                            key: const ValueKey('monster-combat-stats'),
                            'Danger Level ${monster.level}'
                            '${monster.numberOfTentacles > 0 ? ' • ${monster.numberOfTentacles} Tentacles' : ''}'
                            '${monster.frenzyStacks > 0 ? ' • Frenzy: +${monster.frenzyStacks * 25}%' : ''}'
                            ' • Dodge: ${monster.effectiveEvasion}%'
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
                          animationDuration: const Duration(milliseconds: 140),
                        ),
                        if (_battleGame.isMonsterArtUnavailable)
                          _artRecoveryNotice(),
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
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final label = Text(
                                        'CARAPACE ARMOR',
                                        style: InkTheme.statLabel.copyWith(
                                          color: const Color(0xFF6B4226),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                      final value = Text(
                                        '${monster.carapacePlating}/${monster.maxCarapace} PLATES',
                                        style: InkTheme.statValue.copyWith(
                                          color: const Color(0xFF6B4226),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                      if (constraints.maxWidth <
                                          240 *
                                              MediaQuery.textScalerOf(context)
                                                  .scale(1)) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            label,
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: value,
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(child: label),
                                          const SizedBox(width: 8),
                                          value,
                                        ],
                                      );
                                    },
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

          if (_sideLookout)
            Positioned(
              key: const ValueKey('lookout-side'),
              top: _hudBottom,
              right: 16,
              width: _lookoutWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      (MediaQuery.sizeOf(context).height -
                              _hudBottom -
                              _dockHeight -
                              42)
                          .clamp(80.0, 900.0),
                ),
                child: SingleChildScrollView(
                  child: _lookout(currentRange, activeHelmOrder, ship, monster),
                ),
              ),
            ),
          // A bounded dock keeps compact windows usable through deliberate scroll.
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              key: _dockKey,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: InkTheme.parchmentSurface.withValues(alpha: 0.97),
                border: Border.all(color: InkTheme.inkPrimary, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: _commandHeightBudget),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_sideLookout) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              (_commandHeightBudget *
                                      (MediaQuery.sizeOf(context).height < 700
                                          ? 0.3
                                          : 0.4))
                                  .clamp(
                                    60.0,
                                    MediaQuery.sizeOf(context).height * 0.18,
                                  ),
                        ),
                        child: SingleChildScrollView(
                          child: _lookout(
                            currentRange,
                            activeHelmOrder,
                            ship,
                            monster,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Flexible(
                      fit: FlexFit.loose,
                      child: Scrollbar(
                        controller: _commandScroll,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _commandScroll,
                          key: const ValueKey('command-station-scroll'),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final helm = _buildHelmPanel(
                                currentRange,
                                enemyPreviewRange,
                                activeHelmOrder,
                                ship,
                                monster,
                              );
                              final actions = _buildHardpoints(
                                ship,
                                monster,
                                previewRange,
                                activeHelmOrder,
                                needsEmergencyPass,
                              );
                              if (constraints.maxWidth < 640) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    helm,
                                    const SizedBox(height: 10),
                                    actions,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 4, child: helm),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 6, child: actions),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FocusTraversalGroup(
                      // The belt's LayoutBuilder builds after the icons.
                      // Explicit order keeps keyboard traversal in visual order.
                      policy: OrderedTraversalPolicy(),
                      child: Row(
                        key: const ValueKey('battle-dock-footer'),
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: FocusTraversalOrder(
                              order: const NumericFocusOrder(1),
                              child: _buildBelt(
                                ship,
                                quickUsed,
                                maxQuickBeltUses,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const FocusTraversalOrder(
                            order: NumericFocusOrder(2),
                            child: PauseMenuButton(),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(3),
                            child: IconButton(
                              icon: const Icon(
                                Icons.menu_book_outlined,
                                color: InkTheme.inkPrimary,
                              ),
                              tooltip: 'Chronicle Log',
                              onPressed: () => showBattleChronicle(
                                context,
                                widget.controller,
                                scrollState: _chronicleScroll,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _responseForecast(
    HelmOrder order, {
    ShipWeaponType? weaponType,
    bool utility = false,
  }) {
    if (_isActionLocked) return '';
    final movesRange =
        weaponType == ShipWeaponType.prowRam ||
        weaponType == ShipWeaponType.harpoonWinch ||
        (utility &&
            widget.controller.ship?.resolvedBlueprintId.utilityHardpoint ==
                UtilityHardpointId.evasiveRigging);
    if (!movesRange) return '';
    final responseRange = widget.controller.previewResponseRange(
      helmOrder: order,
      weaponType: weaponType,
      utility: utility,
    );
    final monster = widget.controller.currentMonster;
    final outcome = monster?.currentIntent?.evaluatePreview(
      currentRange: responseRange,
      selectedHelmOrder: _decisions.combinationPending
          ? widget.controller.session.lastHelmOrderThisTurn
          : order,
      helmAlreadyApplied: true,
      isMonsterPinned: monster.isPinnedThisTurn,
      tentacleCount: monster.numberOfTentacles,
      damagePerTentacle: monster.usableWeapons
          .where((w) => w.monsterWeaponType == MonsterWeaponType.tentacle)
          .firstOrNull
          ?.damage,
    );
    return 'After action: ${responseRange.displayName}'
        '${outcome == null ? '' : ' · ${outcome.summaryBadge}'}';
  }

  Widget _lookout(
    CombatRange range,
    HelmOrder order,
    ShipState ship,
    MonsterState monster,
  ) => BattleLookout(
    monster: monster,
    currentRange: range,
    selectedHelmOrder: _decisions.combinationPending
        ? widget.controller.session.lastHelmOrderThisTurn
        : order,
    helmAlreadyApplied: _decisions.combinationPending,
    compact: !_sideLookout,
    conditional:
        ship.equippedWeaponTypes.any(
          (type) =>
              type == ShipWeaponType.prowRam ||
              type == ShipWeaponType.harpoonWinch,
        ) ||
        ship.resolvedBlueprintId.utilityHardpoint ==
            UtilityHardpointId.evasiveRigging,
    actionNotes: [
      if (ship.equippedWeaponTypes.contains(ShipWeaponType.prowRam)) 'Prow Ram closes to Short before impact. Charging from Medium retains its damage bonus.',
      if (ship.equippedWeaponTypes.contains(ShipWeaponType.harpoonWinch)) 'Harpoon Winch attacks at its launch range, then pulls one band closer. Pin requires a hit.',
      if (ship.resolvedBlueprintId.utilityHardpoint ==
          UtilityHardpointId.evasiveRigging)
        'Evasive Rigging opens range by up to one band unless grappled.',
      if (widget.controller.usesLateHelm) 'Skirmisher applies your helm order after the main action and its movement.',
    ],
    isResolving: _isActionLocked,
  );

  Widget _buildHelmPanel(
    CombatRange currentRange,
    CombatRange previewRange,
    HelmOrder activeOrder,
    ShipState ship,
    MonsterState monster,
  ) => Column(
    key: const ValueKey('helm-panel'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(
            Icons.explore_outlined,
            size: 22,
            color: InkTheme.inkSecondary,
          ),
          const SizedBox(width: 8),
          Flexible(child: Text('HELM & BEARING', style: InkTheme.statLabel)),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final band in [
            CombatRange.long,
            CombatRange.medium,
            CombatRange.short,
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _buildRangeTrackChip(
                  band,
                  currentRange,
                  previewRange,
                  isThreatened:
                      monster.currentIntent?.threatenedRanges.contains(band) ??
                      false,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final order in [
              HelmOrder.fallBack,
              HelmOrder.holdLine,
              HelmOrder.advance,
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildHelmOrderPill(
                    order,
                    currentRange,
                    activeOrder,
                    isGrappled: ship.isGrappled,
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        _decisions.combinationPending
            ? 'Helm committed: ${widget.controller.session.lastHelmOrderThisTurn.displayName}'
            : ship.isGrappled
            ? 'GRAPPLED · Hold Line only this round'
            : widget.controller.usesLateHelm
            ? 'Order resolves after your main action.'
            : 'Order resolves when you use a fitting.',
        style: InkTheme.caption,
      ),
      if (widget.controller.usesLateHelm)
        Text(
          'SKIRMISHER · Act at ${currentRange.displayName}, then maneuver before the response.',
          key: const ValueKey('late-helm-hint'),
          style: InkTheme.caption,
        ),
      if (widget.controller.activeQuirk?.id == BloodlineTraitId.daredevil)
        Text(
          ship.currentHp * 2 <= ship.maxHp
              ? 'DAREDEVIL · +30% weapon damage · at/below 50% hull'
              : 'DAREDEVIL · Bonus activates at 50% hull or less',
          key: const ValueKey('daredevil-status'),
          style: InkTheme.caption,
        ),
    ],
  );

  Widget _buildHardpoints(
    ShipState ship,
    MonsterState monster,
    CombatRange range,
    HelmOrder order,
    bool needsEmergencyPass,
  ) => Column(
    key: const ValueKey('hardpoint-panel'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('SHIP FITTINGS', style: InkTheme.statLabel),
      const SizedBox(height: 6),
      IntrinsicHeight(
        child: Row(
          key: const ValueKey('weapon-cards'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final type in ship.equippedWeaponTypes)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildWeaponCard(type, ship, monster, range, order),
                ),
              ),
          ],
        ),
      ),
      if (ship.equippedWeaponTypes.any(
        (type) => ship.blessings[_weaponSlot(ship, type)] != null,
      ))
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final type in ship.equippedWeaponTypes)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: switch (ship.blessings[_weaponSlot(ship, type)]) {
                    final blessing? => BlessingBadge(blessing: blessing),
                    null => const SizedBox.shrink(),
                  },
                ),
              ),
          ],
        ),
      const SizedBox(height: 8),
      _buildUtilityRow(ship, range, order),
      if (_decisions.canStartCombination)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const ValueKey('impatient-combination'),
            onPressed: _isActionLocked
                ? null
                : () => _dispatchCombatAction(
                    const ExecuteShipSpecialAction(borrowNextAction: true),
                  ),
            child: Text(
              'IMPATIENT · UTILITY + WEAPON',
              style: InkTheme.caption,
            ),
          ),
        ),
      if (_decisions.combinationPending || _decisions.recovering)
        Text(
          _decisions.combinationPending
              ? 'IMPATIENT · Fire one weapon next. Belt available; helm already committed.'
              : 'RECOVERY · Fittings unavailable. Maneuver, use belt, then Wait & Reload.',
          key: const ValueKey('impatient-status'),
          style: InkTheme.caption,
        ),
      if (needsEmergencyPass) ...[
        const SizedBox(height: 6),
        Tooltip(
          message: 'Finish the turn and advance fitting cooldowns. No evasion bonus.',
          child: InkButton(
            key: const ValueKey('emergency-pass'),
            label: 'WAIT & RELOAD',
            isPrimary: true,
            semanticLabel: 'Wait and reload. Finish the turn and advance fitting cooldowns.',
            onPressed: _isActionLocked
                ? null
                : () => _dispatchCombatAction(const BraceForImpact()),
          ),
        ),
      ],
    ],
  );

  Widget _buildBelt(ShipState ship, int quickUsed, int maxQuickUses) {
    if (ship.cargo.whereType<Consumable>().isEmpty) {
      return const SizedBox.shrink();
    }
    final items = <Widget>[
      IconButton(
        key: const ValueKey('belt-help'),
        icon: const Icon(
          Icons.help_outline,
          size: 20,
          color: InkTheme.inkSecondary,
        ),
        tooltip: 'Belt help',
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: const EdgeInsets.all(6),
        onPressed: _showBeltHelp,
      ),
      for (var index = 0; index < ship.cargo.length; index++)
        if (ship.cargo[index] is Consumable)
          _buildBeltItem(
            ship.cargo[index] as Consumable,
            index,
            quickUsed,
            maxQuickUses,
          ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < 640 || MediaQuery.sizeOf(context).height < 800
          ? Scrollbar(
              key: const ValueKey('tactical-belt'),
              controller: _beltScroll,
              thumbVisibility: true,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  controller: _beltScroll,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: item,
                        ),
                    ],
                  ),
                ),
              ),
            )
          : Wrap(
              key: const ValueKey('tactical-belt'),
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: items,
            ),
    );
  }

  HardpointType _weaponSlot(ShipState ship, ShipWeaponType type) =>
      type == ship.resolvedBlueprintId.signatureWeaponType
      ? HardpointType.signature
      : HardpointType.broadside;

  Widget _buildWeaponCard(
    ShipWeaponType type,
    ShipState ship,
    MonsterState monster,
    CombatRange range,
    HelmOrder order,
  ) {
    final weapons = ship.equippedWeapons
        .where((weapon) => weapon.weaponType == type)
        .toList();
    final readyCount = weapons.where((weapon) => weapon.isReady).length;
    final isReady = readyCount > 0;
    final cooldown = weapons
        .map((weapon) => weapon.chargeCountdown)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final usable = isWeaponTypeUsableAtRange(type, range);
    final canFire =
        isReady && usable && !_isActionLocked && !_decisions.recovering;
    final badge = _getTacticalWeaponBadge(type, range);
    final slot = _weaponSlot(ship, type);
    final ignoresObscurity =
        type == ShipWeaponType.precisionCulverin &&
        widget.controller.profile.isEldritchRelicActive(
          EldritchRelicId.ghostwakeCulverin,
        );
    final accuracy = calculateHitChance(
      ship,
      weapons.first,
      monster,
      accuracyBonus:
          _decisions.gunneryBoon +
          widget.controller.captainWeaponAccuracyModifier +
          (ship.gunneryDrillBuffActive ? 15 : 0),
      range: range,
      ignoreObscurity: ignoresObscurity,
    );
    final accuracyTip =
        'Opening shot accuracy: $accuracy% before ${monster.effectiveEvasion}% target dodge.'
        '${ignoresObscurity
            ? ' Ghostwake ignores obscurity.'
            : monster.obscurityAccuracyPenalty > 0
            ? ' Obscurity subtracts ${monster.obscurityAccuracyPenalty}% from accuracy.'
            : ''}';
    final name = weapons.length == 1
        ? (isReady ? type.displayName : '${type.displayName} (${cooldown}T CD)')
        : '${type.displayName} ($readyCount/${weapons.length})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          slot == HardpointType.broadside ? 'BROADSIDE' : 'SIGNATURE',
          style: InkTheme.caption,
        ),
        Expanded(
          child: Tooltip(
            message:
                '${badge?.tip ?? ''} $accuracyTip\n${_responseForecast(order, weaponType: type)}',
            child: InkButton(
              key: ValueKey('hardpoint-${slot.name}'),
              label: name,
              subtitle: !isReady
                  ? 'RELOADING (${cooldown}T)'
                  : !usable
                  ? 'OUT OF RANGE'
                  : '$accuracy% accuracy · ${(weaponRangeDamageMultiplier(type, range) * 100).round()}% range damage',
              subtitleColor: !isReady || badge?.isWarning == true
                  ? InkTheme.crimsonAccent
                  : InkTheme.goldAccent,
              semanticLabel: !usable
                  ? '${type.displayName} volley out of range at ${range.displayName}. Advance to strike!'
                  : isReady
                  ? 'Fire ${type.displayName} volley at ${range.displayName}. $accuracyTip ${badge?.badge ?? ''}'
                  : '${type.displayName} volley reloading ($cooldown turns remaining).',
              isPrimary: canFire,
              onPressed: canFire
                  ? () => _dispatchCombatAction(FireWeaponVolley(type))
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUtilityRow(ShipState ship, CombatRange range, HelmOrder order) {
    final name = _utilityLabel(ship);
    final mark = ship.markLabelForHardpoint(HardpointType.utility);
    final ready = ship.isUtilityReady;
    final blessing = ship.blessings[HardpointType.utility];
    final canUse =
        ready &&
        !_isActionLocked &&
        !_decisions.combinationPending &&
        !_decisions.recovering;
    return Column(
      key: const ValueKey('utility-row'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('UTILITY', style: InkTheme.caption),
        Tooltip(
          message:
              '${_utilityTooltip(ship, range)}\n${_responseForecast(order, utility: true)}',
          child: InkButton(
            key: const ValueKey('hardpoint-utility'),
            label: name,
            subtitle: ready
                ? '$mark • 2T CD'
                : 'COOLDOWN (${ship.utilityCooldown}T)',
            subtitleColor: ready ? InkTheme.goldAccent : InkTheme.crimsonAccent,
            semanticLabel: ready
                ? 'Activate $name utility fitting ($mark)'
                : '$name utility fitting cooling down (${ship.utilityCooldown} turns remaining)',
            onPressed: canUse
                ? () => _dispatchCombatAction(const ExecuteShipSpecialAction())
                : null,
          ),
        ),
        if (blessing != null) BlessingBadge(blessing: blessing),
      ],
    );
  }

  Widget _buildBeltItem(Consumable item, int index, int used, int limit) {
    final effect = item.type == ConsumableType.hullPatchKit
        ? (
            summary: 'Repair ${_decisions.hullPatchHp} HP',
            details: 'Restore ${_decisions.hullPatchHp} hull HP.',
          )
        : item.type.beltEffect;
    final restriction = _beltRestriction(item, used, limit);
    final details = restriction == null
        ? effect.details
        : '${effect.details}\n$restriction';
    return Tooltip(
      message: details,
      child: InkButton(
        label: item.name,
        subtitle: effect.summary,
        subtitleColor: InkTheme.inkSecondary,
        compact: true,
        semanticLabel: item.name,
        semanticHint: details,
        onPressed: restriction == null
            ? () => _dispatchCombatAction(UseConsumableItem(index))
            : null,
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
          ? 'Pending tactical bearing: ${band.displayName}${isThreatened ? ' (Threatened by monster intent)' : ' (Outside listed threat bands)'}'
          : '${band.displayName}${isThreatened ? ' (Threatened)' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Text(
          label,
          style: InkTheme.caption.copyWith(
            fontSize: 12,
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
    final isSelected =
        (_decisions.combinationPending
            ? widget.controller.session.lastHelmOrderThisTurn
            : activeHelmOrder) ==
        order;

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

    final canPress =
        isAvailable && !_isActionLocked && !_decisions.combinationPending;

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
            key: ValueKey('helm-${order.name}'),
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: contentColor),
                const SizedBox(height: 6),
                Text(
                  order.displayName,
                  textAlign: TextAlign.center,
                  style: InkTheme.body.copyWith(
                    fontSize: 16,
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
