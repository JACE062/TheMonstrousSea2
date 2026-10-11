import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/svg_asset_view.dart';

/// Screen allowing captain to rest upon the open swell, inspect vessel, and choose next move.
class RestScreen extends StatelessWidget {
  const RestScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });

  final GameController controller;
  final VoidCallback onOpenChart;

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    final seaChart = controller.seaChart;

    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'RESPITE ON THE OPEN SEA',
                  style: InkTheme.titleLarge.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'The waves lap gently against the timbers as the crew catches breath.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                if (ship != null)
                  ParchmentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgAssetView(
                              assetPath: SvgAssetView.pathForShip(ship.shipClass, isDavyJones: ship.name == 'Flying Dutchman'),
                              width: 80,
                              height: 80,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ship.name, style: InkTheme.titleMedium),
                                  Text(
                                    'Position: Sector [${seaChart.currentRow}, ${seaChart.currentCol}] • Loop ${seaChart.timesCompleted}',
                                    style: InkTheme.caption,
                                  ),
                                  const SizedBox(height: 8),
                                  HullGauge(currentHp: ship.currentHp, maxHp: ship.maxHp),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statColumn('GOLD CARRIED', '${ship.gold}g'),
                            _statColumn('CARGO STOWED', '${ship.cargo.length} / ${ship.maxCargo}'),
                            _statColumn('GUNS READIED', '${ship.equippedWeapons.length} Mounted'),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Chart button
                InkButton(
                  label: 'CONSULT SEA CHART',
                  icon: SvgAssetView(assetPath: 'assets/art/icon_cannons.svg', width: 22, height: 22),
                  onPressed: onOpenChart,
                ),
                const SizedBox(height: 20),

                // Primary Next Move Choices
                Row(
                  children: [
                    Expanded(
                      child: InkButton(
                        label: 'ADVANCE TO NEXT WATERS',
                        isPrimary: true,
                        onPressed: () => controller.dispatch(const AdvanceToNextBattle()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkButton(
                        label: 'RETURN TO PORT',
                        onPressed: () => controller.dispatch(const ReturnToPort()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: InkTheme.statLabel.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: InkTheme.statValue.copyWith(fontSize: 14)),
      ],
    );
  }
}
