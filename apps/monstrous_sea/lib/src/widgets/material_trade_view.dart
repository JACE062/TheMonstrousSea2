import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'parchment_card.dart';

class MaterialTradeView extends StatelessWidget {
  const MaterialTradeView({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final session = controller.session;
      final stock = session.currentMaterialShipment;
      if (stock == null) return const SizedBox.shrink();
      final inventory = session.profile.metaInventory;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ParchmentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PERMANENT MATERIALS', style: InkTheme.titleMedium),
              Text(
                'One finite shipment. Stored with your lineage; no belt slot required. Purchases compete with repairs and refits.',
                style: InkTheme.caption,
              ),
              for (final material in TradeMaterial.values)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${material.displayName}\n${stock.quantity(material)} remaining · ${session.materialUnitPrice(material)}g each\nOwned: ${material == TradeMaterial.seaGlass ? inventory.seaGlass : inventory.depthWroughtIron}',
                        style: InkTheme.body,
                      ),
                      InkButton(
                        key: ValueKey('buy-material-${material.name}'),
                        label: stock.quantity(material) == 0
                            ? 'SOLD OUT'
                            : 'BUY 1 · ${session.materialUnitPrice(material)}g',
                        semanticLabel: 'Buy one ${material.displayName}',
                        onPressed:
                            stock.quantity(material) > 0 &&
                                (session.ship?.gold ?? 0) >=
                                    session.materialUnitPrice(material) &&
                                !controller.isPlayingEvents
                            ? () => controller.dispatch(
                                BuyMerchantMaterial(stock.id, material),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
