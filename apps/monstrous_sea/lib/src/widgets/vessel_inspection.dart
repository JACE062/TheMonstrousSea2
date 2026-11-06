import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'armory_view.dart';
import 'hull_gauge.dart';
import 'ink_button.dart';
import 'parchment_card.dart';
import 'pilot_art.dart';
import 'svg_asset_view.dart';
import 'voyage_log_view.dart';

/// The same named, illustrated inspection action at helm and shore stops.
class InspectVesselButton extends StatelessWidget {
  const InspectVesselButton({
    super.key,
    required this.controller,
    this.buttonKey,
  });
  final GameController controller;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => InkButton(
    key: buttonKey,
    label: 'INSPECT VESSEL',
    compact: true,
    isPrimary: true,
    icon: const SvgAssetView(
      assetPath: PilotArt.standard,
      width: 30,
      height: 26,
    ),
    onPressed: () => showVoyagePanel(
      context,
      closeLabel: 'CLOSE INSPECTION',
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VesselSummary(controller: controller),
            const SizedBox(height: 12),
            ArmoryView(controller: controller),
          ],
        ),
      ),
    ),
  );
}

class VesselSummary extends StatelessWidget {
  const VesselSummary({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    if (ship == null) return const SizedBox.shrink();
    return ParchmentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ship.name, style: InkTheme.titleMedium),
          Text('Captain ${controller.captainName}', style: InkTheme.body),
          const SizedBox(height: 8),
          HullGauge(currentHp: ship.currentHp, maxHp: ship.maxHp),
        ],
      ),
    );
  }
}
