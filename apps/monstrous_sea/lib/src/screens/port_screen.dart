import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/svg_asset_view.dart';

/// Hub screen at Hunter's Respite Port for repairs, trade, and chart planning.
class PortScreen extends StatelessWidget {
  const PortScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });

  final GameController controller;
  final VoidCallback onOpenChart;

  void _showRepairDialog(BuildContext context) {
    final ship = controller.ship;
    if (ship == null) return;

    final cost100 = calculateRepairCost(ship, 1.0);
    final cost50 = calculateRepairCost(ship, 0.5);
    final cost25 = calculateRepairCost(ship, 0.25);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: InkTheme.parchmentSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: InkTheme.inkPrimary, width: 2),
        ),
        title: Text('DRYDOCK REPAIRS', style: InkTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipwright: "Your vessel sits at ${ship.currentHp}/${ship.maxHp} HP. Gold on hand: ${ship.gold}g."',
              style: InkTheme.body,
            ),
            const SizedBox(height: 16),
            if (cost100 == 0)
              Text('The ${ship.name} needs no repairs! Fully shipshape.', style: InkTheme.bodyBold)
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Repair 100% Hull (Restore to ${ship.maxHp} HP)', style: InkTheme.statLabel),
                subtitle: Text('Cost: ${cost100}g', style: InkTheme.caption),
                trailing: InkButton(
                  label: 'Repair',
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
                subtitle: Text('Cost: ${cost50}g', style: InkTheme.caption),
                trailing: InkButton(
                  label: 'Repair',
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
                subtitle: Text('Cost: ${cost25}g', style: InkTheme.caption),
                trailing: InkButton(
                  label: 'Repair',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: InkTheme.statLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;

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
                          Text('HUNTER\'S RESPITE', style: InkTheme.titleLarge.copyWith(fontSize: 32)),
                          Text('Sanctuary Harbor & Fortified Haven', style: InkTheme.subtitle),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: InkTheme.parchmentHighlight,
                        border: Border.all(color: InkTheme.goldAccent, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          SvgAssetView(assetPath: 'assets/art/icon_treasure.svg', width: 24, height: 24),
                          const SizedBox(width: 8),
                          Text('${ship?.gold ?? 0}g', style: InkTheme.statValue.copyWith(fontSize: 18, color: InkTheme.goldAccent)),
                        ],
                      ),
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
                              assetPath: SvgAssetView.pathForShip(ship.shipClass, isDavyJones: ship.name == 'Flying Dutchman'),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _vesselStat('ARMOR CLASS', '${ship.armorClass} AC'),
                            _vesselStat('CARGO HOLD', '${ship.cargo.length} / ${ship.maxCargo}'),
                            _vesselStat('GUN WEIGHT', '${ship.currentWeaponWeight} / ${ship.maxWeaponWeight} Wt'),
                            _vesselStat('MONSTERS SLAIN', '${controller.session.monstersDefeatedThisLife}'),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Port Action Grid
                Row(
                  children: [
                    Expanded(
                      child: InkButton(
                        label: 'VISIT MERCHANT',
                        icon: SvgAssetView(assetPath: 'assets/art/icon_helm.svg', width: 22, height: 22),
                        onPressed: () => controller.dispatch(const VisitMerchant()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkButton(
                        label: 'REPAIR SHIP',
                        icon: SvgAssetView(assetPath: 'assets/art/icon_anchor.svg', width: 22, height: 22),
                        onPressed: () => _showRepairDialog(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkButton(
                        label: 'SEA CHART',
                        icon: SvgAssetView(assetPath: 'assets/art/icon_cannons.svg', width: 22, height: 22),
                        onPressed: onOpenChart,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Main Sail Button
                InkButton(
                  label: 'VENTURE OUT TO SEA',
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
        Text(label, style: InkTheme.statLabel.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: InkTheme.statValue.copyWith(fontSize: 15)),
      ],
    );
  }
}
