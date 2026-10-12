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
  String? _fleeBanner;
  final ScrollController _logScrollController = ScrollController();
  final GlobalKey _statusKey = GlobalKey();
  final GlobalKey _dockKey = GlobalKey();

  void _syncArenaInsets() {
    if (!mounted) return;
    final status = _statusKey.currentContext?.findRenderObject() as RenderBox?;
    final dock = _dockKey.currentContext?.findRenderObject() as RenderBox?;
    if (status == null || dock == null || !status.hasSize || !dock.hasSize) return;
    _battleGame.setArenaInsets(
      top: 16 + status.size.height + 12,
      bottom: 16 + dock.size.height + 12,
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
        command is UseConsumableItem ||
        command is FleeEncounter;

    final events = widget.controller.dispatch(command, deferNotification: isCombatAction);

    if (events.any((e) => e is FleeFailed)) {
      setState(() {
        _fleeBanner = 'ESCAPE INTERCEPTED! The beast blocks all retreat!';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _fleeBanner = null);
      });
    }

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
                    padding: const EdgeInsets.all(12),
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
                          'Level ${ship.level} ${ship.shipClass.name.toUpperCase()} • ${ship.armorClass} AC'
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: InkTheme.parchmentSurface.withValues(alpha: 0.9),
                      border: Border.all(
                        color: monster.name.contains('Kraken') ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
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
                                  color: monster.name.contains('Kraken') ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
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
                                child: Text('OBSCURED', style: InkTheme.caption.copyWith(color: InkTheme.parchmentHighlight, fontSize: 10)),
                              ),
                          ],
                        ),
                        Text(
                          'Danger Level ${monster.level} • ${monster.effectiveArmorClass} AC${monster.numberOfTentacles > 0 ? ' • ${monster.numberOfTentacles} Tentacles' : ''}',
                          style: InkTheme.caption,
                        ),
                        const SizedBox(height: 8),
                        HullGauge(
                          currentHp: monster.currentHp,
                          maxHp: monster.maxHp,
                          label: 'BEAST INTEGRITY',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Flee Intercepted Banner
          if (_fleeBanner != null)
            Positioned(
              top: 115,
              left: 24,
              right: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: InkTheme.parchmentSurface,
                    border: Border.all(color: InkTheme.crimsonAccent, width: 2),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: InkTheme.crimsonAccent.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    _fleeBanner!,
                    style: InkTheme.titleMedium.copyWith(
                      color: InkTheme.crimsonAccent,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),

          // 4. Bottom Action Dock
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              key: _dockKey,
              padding: const EdgeInsets.all(12),
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
                    Container(
                      height: 100,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: InkTheme.parchmentDark.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: InkTheme.inkMuted, width: 1),
                      ),
                      child: CombatLogView(
                        entries: widget.controller.combatLog,
                        scrollController: _logScrollController,
                      ),
                    ),
                  ],
                  // Weapon Volleys
                  Row(
                    children: [
                      ...ship.equippedWeaponTypes.map((type) {
                        final weaponsOfType = ship.equippedWeapons.where((w) => w.weaponType == type).toList();
                        final readyCount = weaponsOfType.where((w) => w.isReady).length;
                        final isReady = readyCount > 0;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkButton(
                              label: '${type.displayName} ($readyCount/${weaponsOfType.length})',
                              isPrimary: isReady,
                              onPressed: isReady && !_isActionLocked
                                  ? () => _dispatchCombatAction(FireWeaponVolley(type))
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Special Action, Consumable, Flee & Log Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Special Action button if Ironclad or Corvette
                      if (ship.shipClass == ShipClass.ironclad)
                        InkButton(
                          label: 'Fortify Plating',
                          onPressed: !_isActionLocked
                              ? () => _dispatchCombatAction(const ExecuteShipSpecialAction())
                              : null,
                        )
                      else if (ship.shipClass == ShipClass.corvette)
                        InkButton(
                          label: 'Evasive Maneuver',
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

                      // Flee
                      InkButton(
                        label: 'Flee Encounter',
                        isDanger: true,
                        onPressed: !_isActionLocked
                            ? () => _dispatchCombatAction(const FleeEncounter())
                            : null,
                      ),

                      // Log Drawer Toggle
                      IconButton(
                        icon: Icon(_showLog ? Icons.menu_book : Icons.book, color: InkTheme.inkPrimary),
                        tooltip: 'Chronicle Log',
                        onPressed: () => setState(() => _showLog = !_showLog),
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
}
