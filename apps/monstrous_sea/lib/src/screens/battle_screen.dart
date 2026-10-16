import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../battle/monstrous_sea_battle_game.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/combat_log_view.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/settings_dialog.dart';

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
  final ScrollController _logScrollController = ScrollController();
  final GlobalKey _statusKey = GlobalKey();
  final GlobalKey _dockKey = GlobalKey();

  void _syncArenaInsets() {
    if (!mounted) return;
    final status = _statusKey.currentContext?.findRenderObject() as RenderBox?;
    final dock = _dockKey.currentContext?.findRenderObject() as RenderBox?;
    if (status == null || dock == null || !status.hasSize || !dock.hasSize) return;
    _battleGame.setArenaInsets(
      top: 16 + status.size.height + 9,
      bottom: 16 + dock.size.height + 9,
    );
  }

  @override
  void initState() {
    super.initState();
    _battleGame = widget.game ?? MonstrousSeaBattleGame(
      ship: widget.controller.ship!,
      monster: widget.controller.currentMonster!,
    );
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _logScrollController.hasClients) {
        _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
      }
    });
  }

  void _dispatchCombatAction(Command command) {
    if (_isActionLocked) return;

    setState(() {
      _isActionLocked = true;
    });

    final isCombatAction = command is FireWeaponVolley ||
        command is ExecuteShipSpecialAction ||
        command is UseConsumableItem;

    final events = <GameEvent>[];

    // If an advance or fall back order was selected, execute helm order first
    final currentRange = widget.controller.combatRange;
    final activeOrder = currentRange.availableHelmOrders.contains(_selectedHelmOrder)
        ? _selectedHelmOrder
        : HelmOrder.holdLine;

    if (activeOrder != HelmOrder.holdLine && isCombatAction) {
      events.addAll(widget.controller.dispatch(
        IssueHelmOrder(activeOrder),
        deferNotification: true,
      ));
    }

    events.addAll(widget.controller.dispatch(
      command,
      deferNotification: isCombatAction,
    ));

    // Reset selected helm order to holdLine for subsequent round
    _selectedHelmOrder = HelmOrder.holdLine;

    _scrollToBottom();

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
          widget.controller.notify();
        }
        _scrollToBottom();
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentRange = widget.controller.combatRange;
    final activeHelmOrder = currentRange.availableHelmOrders.contains(_selectedHelmOrder)
        ? _selectedHelmOrder
        : HelmOrder.holdLine;
    final previewRange = currentRange.rangeAfterHelmOrder(activeHelmOrder);


    return ParchmentScaffold(
      showBorder: false,
      body: Stack(
        children: [
          // 1. Flame 2D Battle Arena
          Positioned.fill(
            child: GameWidget(game: _battleGame),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: InkTheme.parchmentSurface.withValues(alpha: 0.9),
                      border: Border.all(color: InkTheme.inkPrimary, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ship.name, style: InkTheme.titleMedium.copyWith(fontSize: 20)),
                        Text(
                          'Level ${ship.level} ${ship.shipClass.name.toUpperCase()}'
                          '${ship.shipClass == ShipClass.ironclad ? ' • Fortified: -${ship.currentDmgReduction} Dmg' : ''}'
                          '${ship.shipClass == ShipClass.corvette ? ' • Evade: ${ship.currentEvasion}%' : ''}',
                          style: InkTheme.caption,
                        ),
                        const SizedBox(height: 8),
                        HullGauge(currentHp: ship.currentHp, maxHp: ship.maxHp),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Monster Status Panel (Right)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: InkTheme.parchmentSurface.withValues(alpha: 0.9),
                      border: Border.all(
                        color: (monster.isApex || monster.name.contains('Kraken'))
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
                                  color: (monster.isApex || monster.name.contains('Kraken'))
                                      ? InkTheme.crimsonAccent
                                      : InkTheme.inkPrimary,
                                ),
                              ),
                            ),
                            if (monster.isApex)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            if (monster.isObscured)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: InkTheme.inkPrimary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  'OBSCURED',
                                  style: InkTheme.caption.copyWith(
                                    color: InkTheme.parchmentHighlight,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          'Danger Level ${monster.level}'
                          '${monster.numberOfTentacles > 0 ? ' • ${monster.numberOfTentacles} Tentacles' : ''}'
                          '${monster.frenzyStacks > 0 ? ' • Frenzy: +${monster.frenzyStacks * 25}%' : ''}'
                          '${monster.evasion > 0 ? ' • Evade: ${monster.evasion}%' : ''}',
                          style: InkTheme.caption,
                        ),
                        const SizedBox(height: 8),
                        HullGauge(
                          currentHp: monster.currentHp,
                          maxHp: monster.maxHp,
                          label: 'BEAST INTEGRITY',
                        ),
                        if (monster.species == MonsterSpecies.crustacean || monster.maxCarapace > 0) ...[
                          const SizedBox(height: 8),
                          if (monster.carapacePlating > 0) ...[
                            Semantics(
                              label: 'Carapace Armor Plating',
                              value: '${monster.carapacePlating} of ${monster.maxCarapace} plating intact. Deflects non-blast attacks.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          borderRadius: BorderRadius.circular(2),
                                          border: Border.all(color: const Color(0xFF6B4226), width: 1.2),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: monster.maxCarapace > 0
                                            ? (monster.carapacePlating / monster.maxCarapace).clamp(0.0, 1.0)
                                            : 0.0,
                                        child: Container(
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5A2B),
                                            borderRadius: BorderRadius.circular(1.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Deflects standard shots. Shatter with Blast/Torpedoes!',
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: InkTheme.crimsonAccent.withValues(alpha: 0.12),
                                border: Border.all(color: InkTheme.crimsonAccent, width: 1.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_outlined, size: 14, color: InkTheme.crimsonAccent),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        final logHeight = (screenHeight * 0.16).clamp(80.0, 200.0);
                        return Container(
                          height: logHeight,
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: InkTheme.parchmentDark.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: InkTheme.inkMuted, width: 1),
                          ),
                          child: CombatLogView(
                            entries: widget.controller.structuredCombatLog,
                            scrollController: _logScrollController,
                          ),
                        );
                      },
                    ),
                  ],
                  // Tactical Bearing & Bounded Helm Order Bar
                  _buildTacticalBearingBar(currentRange, previewRange, activeHelmOrder),

                  // Weapon Volleys with Tactical Range Badges inside InkButton
                  Row(
                    children: [
                      ...ship.equippedWeaponTypes.map((type) {
                        final weaponsOfType = ship.equippedWeapons.where((w) => w.weaponType == type).toList();
                        final readyCount = weaponsOfType.where((w) => w.isReady).length;
                        final isReady = readyCount > 0;
                        final isUsableAtRange = isWeaponTypeUsableAtRange(type, previewRange);
                        final canFire = isReady && isUsableAtRange && !_isActionLocked;
                        final badgeInfo = _getTacticalWeaponBadge(type, previewRange);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Tooltip(
                              message: badgeInfo?.tip ?? '',
                              child: InkButton(
                                label: '${type.displayName} ($readyCount/${weaponsOfType.length})',
                                subtitle: badgeInfo?.badge,
                                subtitleColor: badgeInfo?.isWarning == true
                                    ? InkTheme.crimsonAccent
                                    : InkTheme.goldAccent,
                                semanticLabel: !isUsableAtRange
                                    ? '${type.displayName} volley out of range at ${previewRange.displayName}. Advance to strike!'
                                    : isReady
                                        ? 'Fire ${type.displayName} volley at ${previewRange.displayName}. $readyCount of ${weaponsOfType.length} cannons ready.${badgeInfo != null ? ' ${badgeInfo.badge}.' : ''}'
                                        : '${type.displayName} volley reloading. 0 of ${weaponsOfType.length} cannons ready.',
                                isPrimary: canFire,
                                onPressed: canFire
                                    ? () => _dispatchCombatAction(FireWeaponVolley(type))
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Special Action, Consumables & Combat Log
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Special Action button if Ironclad or Corvette
                      if (ship.shipClass == ShipClass.ironclad)
                        InkButton(
                          label: 'Fortify Plating',
                          semanticLabel: 'Activate Fortify Plating special action',
                          onPressed: !_isActionLocked
                              ? () => _dispatchCombatAction(const ExecuteShipSpecialAction())
                              : null,
                        )
                      else if (ship.shipClass == ShipClass.corvette)
                        InkButton(
                          label: 'Evasive Maneuver',
                          semanticLabel: 'Activate Evasive Maneuver special action',
                          onPressed: !_isActionLocked
                              ? () => _dispatchCombatAction(const ExecuteShipSpecialAction())
                              : null,
                        )
                      else
                        const SizedBox.shrink(),

                      // Quick Consumable Use
                      if (ship.cargo.any((item) => item is Consumable)) ...[
                        InkButton(
                          label: 'Use Consumable',
                          semanticLabel: 'Use first ready consumable from cargo',
                          onPressed: !_isActionLocked
                              ? () {
                                  final idx = ship.cargo.indexWhere((item) => item is Consumable);
                                  if (idx >= 0) {
                                    _dispatchCombatAction(UseConsumableItem(idx));
                                  }
                                }
                              : null,
                        ),
                      ],

                      // Bottom-right Utility Controls: Settings & Chronicle Log
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.settings, color: InkTheme.inkSecondary),
                            tooltip: 'Settings & Accessibility',
                            onPressed: () => SettingsDialog.show(context),
                          ),
                          IconButton(
                            icon: Icon(_showLog ? Icons.menu_book : Icons.book, color: InkTheme.inkPrimary),
                            tooltip: 'Chronicle Log',
                            onPressed: () => setState(() => _showLog = !_showLog),
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

  Widget _buildTacticalBearingBar(
    CombatRange currentRange,
    CombatRange previewRange,
    HelmOrder activeHelmOrder,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: InkTheme.parchmentDark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: InkTheme.inkMuted, width: 1),
      ),
      child: LayoutBuilder(
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
                _buildRangeTrackChip(r, currentRange, previewRange),
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
              const SizedBox(width: 2),
              for (final order in [
                HelmOrder.fallBack,
                HelmOrder.holdLine,
                HelmOrder.advance,
              ]) ...[
                _buildHelmOrderPill(order, currentRange, activeHelmOrder),
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
    );
  }

  Widget _buildRangeTrackChip(
    CombatRange band,
    CombatRange currentRange,
    CombatRange previewRange,
  ) {
    final isTargetDestination = band == previewRange && previewRange != currentRange;
    final isCurrentStation = band == currentRange && previewRange == currentRange;
    final isDepartingStation = band == currentRange && previewRange != currentRange;

    Color bgColor = Colors.transparent;
    Color borderColor = InkTheme.inkMuted.withValues(alpha: 0.35);
    Color textColor = InkTheme.inkMuted;
    FontWeight fontWeight = FontWeight.normal;
    String prefix = '';
    String suffix = '';

    if (isCurrentStation) {
      bgColor = InkTheme.inkPrimary;
      borderColor = InkTheme.inkPrimary;
      textColor = InkTheme.parchmentHighlight;
      fontWeight = FontWeight.bold;
      prefix = '⚓ ';
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
          ? 'Current engagement distance: ${band.displayName}'
          : isTargetDestination
              ? 'Pending tactical bearing: ${band.displayName}'
              : band.displayName,
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
    HelmOrder activeHelmOrder,
  ) {
    final isAvailable = currentRange.availableHelmOrders.contains(order);
    final isSelected = activeHelmOrder == order;

    final IconData icon = switch (order) {
      HelmOrder.fallBack => Icons.arrow_back,
      HelmOrder.holdLine => Icons.anchor,
      HelmOrder.advance => Icons.arrow_forward,
    };

    final tooltip = switch (order) {
      HelmOrder.fallBack when !isAvailable => 'Cannot fall back beyond Long Range',
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

    final canPress = isAvailable && !_isActionLocked;

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
              border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
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
    switch (type) {
      case ShipWeaponType.prowRam:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: '⚠️ OUT OF RANGE',
            tip: 'Cannot fire Prow Ram from Long Range. Advance to engage!',
            isWarning: true,
          );
        }
        return const _TacticalBadgeInfo(
          badge: '⚡ +30% COLLISION',
          tip: 'Surges forward to Short Range on impact with +30% collision damage bonus.',
        );
      case ShipWeaponType.heavyMortar:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: '⚡ +25% HIGH ARC',
            tip: 'Heavy Mortar deals +25% bonus damage at Long Range and shatters Carapace plating.',
          );
        } else if (targetRange == CombatRange.short) {
          return const _TacticalBadgeInfo(
            badge: '⚠️ 20% BACKFIRE',
            tip: 'Point-blank mortar fire at Short Range risks 20% self-splash damage to own ship hull!',
            isWarning: true,
          );
        }
        return const _TacticalBadgeInfo(
          badge: 'CARAPACE BREAKER',
          tip: 'Deals blast damage that shatters monster Carapace plating.',
        );
      case ShipWeaponType.precisionCulverin:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: '⚡ +25% SNIPER',
            tip: 'Precision Culverin deals +25% bonus damage at Long Range and pierces 50% Carapace.',
          );
        }
        return const _TacticalBadgeInfo(
          badge: 'ARMOR PIERCER',
          tip: 'Ignores 50% of monster Carapace plating.',
        );
      case ShipWeaponType.cannon:
        if (targetRange == CombatRange.long) {
          return const _TacticalBadgeInfo(
            badge: '⚠️ -15% ACCURACY',
            tip: 'Standard broadside cannons suffer -15% accuracy penalty at Long Range.',
            isWarning: true,
          );
        } else if (targetRange == CombatRange.short) {
          return const _TacticalBadgeInfo(
            badge: 'POINT BLANK',
            tip: 'Point-blank naval broadside with full accuracy.',
          );
        }
        return const _TacticalBadgeInfo(
          badge: 'OPTIMUM RANGE',
          tip: 'Standard naval broadside at Medium Range.',
        );
      case ShipWeaponType.harpoonWinch:
        if (targetRange != CombatRange.short) {
          return const _TacticalBadgeInfo(
            badge: '⚓ PULLS QUARRY',
            tip: 'Striking with Harpoon Winch reels the monster 1 range band closer.',
          );
        }
        return const _TacticalBadgeInfo(
          badge: 'PINS BEAST',
          tip: 'Tethers and pins quarry at point-blank range.',
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
