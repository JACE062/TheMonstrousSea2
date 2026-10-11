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
  const BattleScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late MonstrousSeaBattleGame _battleGame;
  bool _isActionLocked = false;
  bool _showLog = false;
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _battleGame = MonstrousSeaBattleGame(
      ship: widget.controller.ship!,
      monster: widget.controller.currentMonster!,
    );
  }

  void _dispatchCombatAction(Command command) {
    if (_isActionLocked) return;

    setState(() {
      _isActionLocked = true;
    });

    final events = widget.controller.dispatch(command);
    _battleGame.playEvents(events, () {
      if (mounted) {
        setState(() {
          _isActionLocked = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                          'Level ${ship.level} ${ship.shipClass.name.toUpperCase()} • ${ship.armorClass} AC',
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
                            Text(
                              monster.name,
                              style: InkTheme.titleMedium.copyWith(
                                fontSize: 20,
                                color: monster.name.contains('Kraken') ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
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

          // 3. Combat Log Drawer (Collapsible)
          if (_showLog)
            Positioned(
              top: 130,
              right: 16,
              width: 380,
              height: 220,
              child: CombatLogView(
                entries: widget.controller.combatLog,
                scrollController: _logScrollController,
              ),
            ),

          // 4. Bottom Action Dock
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: InkTheme.parchmentSurface.withValues(alpha: 0.95),
                border: Border.all(color: InkTheme.inkPrimary, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
