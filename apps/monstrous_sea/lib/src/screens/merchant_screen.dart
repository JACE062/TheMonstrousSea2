import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/mechanic_text.dart';
import '../widgets/hull_patch_kit_button.dart';
import '../widgets/material_trade_view.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/weapon_stats_view.dart';
import '../widgets/vessel_inspection.dart';
import '../widgets/pilot_art.dart';

class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> {
  int _activeTab = 0;
  GameController get controller => widget.controller;
  void _leave() {
    if (controller.phase == SessionPhase.merchant &&
        !controller.isPlayingEvents) {
      controller.dispatch(const LeaveMerchant());
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final session = controller.session;
      final ship = controller.ship;
      final stock = session.merchantStock;
      final cargo = ship?.cargo ?? <Item>[];
      final canTrade =
          session.canTradeAtCurrentMerchant && !controller.isPlayingEvents;
      final returnLabel = switch (session.merchantReturnPhase) {
        SessionPhase.stronghold => 'RETURN TO STRONGHOLD',
        SessionPhase.helm => 'TAKE THE HELM',
        _ => 'RETURN TO PORT',
      };
      final wares = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stock.isEmpty)
            ParchmentCard(
              child: Text(
                'The merchant has no supplies remaining.',
                style: InkTheme.body,
              ),
            ),
          for (var i = 0; i < stock.length; i++)
            _TradeItemCard(
              item: stock[i],
              price: session.getMerchantAskingPrice(i),
              isSale: session.onSaleMerchantIndex == i,
              buying: true,
              buttonLabel: (ship?.gold ?? 0) < session.getMerchantAskingPrice(i)
                  ? 'LACKS GOLD'
                  : cargo.length >= (ship?.maxCargo ?? 0)
                  ? 'BELT FULL'
                  : 'BUY',
              onTrade:
                  canTrade &&
                      (ship?.gold ?? 0) >= session.getMerchantAskingPrice(i) &&
                      cargo.length < (ship?.maxCargo ?? 0)
                  ? () => controller.dispatch(BuyMerchantItem(i))
                  : null,
            ),
        ],
      );
      final belt = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TACTICAL BELT (${cargo.length}/${ship?.maxCargo ?? 0})',
            style: InkTheme.statLabel,
          ),
          const SizedBox(height: 10),
          if (cargo.isEmpty)
            ParchmentCard(
              child: Text('Your Tactical Belt is empty.', style: InkTheme.body),
            ),
          for (var i = 0; i < cargo.length; i++)
            _TradeItemCard(
              item: cargo[i],
              price: cargo[i].value,
              buying: false,
              buttonLabel: 'SELL',
              onTrade: canTrade
                  ? () => controller.dispatch(SellCargoItem(i))
                  : null,
            ),
        ],
      );
      return ParchmentScaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: SvgAssetView(
                      assetPath: PilotArt.helm,
                      width: 56,
                      height: 56,
                    ),
                  ),
                  Text(
                    'HARPOON & HELM CHANDLERY',
                    style: InkTheme.titleLarge.copyWith(fontSize: 26),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'PURSE: ${ship?.gold ?? 0}g · TACTICAL BELT ${cargo.length}/${ship?.maxCargo ?? 0}',
                        style: InkTheme.statValue.copyWith(
                          color: InkTheme.goldAccent,
                        ),
                      ),
                      InkButton(
                        label: 'LEAVE CHANDLERY',
                        semanticLabel: returnLabel,
                        onPressed: _leave,
                      ),
                      InspectVesselButton(controller: controller),
                    ],
                  ),
                  const SizedBox(height: 20),
                  VesselSummary(controller: controller),
                  CarriedPatchKits(controller: controller),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, bounds) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (index, label) in [
                          (0, 'SUPPLIES'),
                          (1, 'MATERIALS'),
                          (2, 'SELL BELT'),
                        ])
                          SizedBox(
                            width: bounds.maxWidth < 540
                                ? (bounds.maxWidth - 8) / 2
                                : (bounds.maxWidth - 16) / 3,
                            child: InkButton(
                              key: ValueKey('merchant-tab-$index'),
                              label: label,
                              isPrimary: _activeTab == index,
                              onPressed: () =>
                                  setState(() => _activeTab = index),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_activeTab == 2 &&
                      cargo.any((item) => item is Treasure)) ...[
                    InkButton(
                      label: 'SELL ALL TREASURE',
                      onPressed: canTrade
                          ? () => controller.dispatch(const SellAllTreasure())
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_activeTab == 0) wares,
                  if (_activeTab == 1)
                    MaterialTradeView(controller: controller),
                  if (_activeTab == 2) belt,
                  const SizedBox(height: 20),
                  InkButton(label: returnLabel, onPressed: _leave),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Item art stays beside its details at every width; the action wraps below.
class _TradeItemCard extends StatelessWidget {
  const _TradeItemCard({
    required this.item,
    required this.price,
    required this.buying,
    required this.buttonLabel,
    required this.onTrade,
    this.isSale = false,
  });
  final Item item;
  final int price;
  final bool buying, isSale;
  final String buttonLabel;
  final VoidCallback? onTrade;
  Widget _details() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MechanicText(currentItemDescription(item), style: InkTheme.caption),
      const SizedBox(height: 8),
      WeaponStatsView(item: item, compact: true),
      const SizedBox(height: 6),
      Text(
        buying
            ? 'Price: ${price}g · Sell value: ${item.value}g'
            : 'Sell value: ${price}g',
        style: InkTheme.statLabel.copyWith(color: InkTheme.goldAccent),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ParchmentCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final compact = bounds.maxWidth < 420;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgAssetView(
                    assetPath: SvgAssetView.pathForItem(item),
                    width: 72,
                    height: 72,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: InkTheme.statValue),
                        if (isSale)
                          Text(
                            'SALE −25%',
                            style: InkTheme.statLabel.copyWith(
                              color: InkTheme.goldAccent,
                            ),
                          ),
                        if (!compact) ...[
                          const SizedBox(height: 4),
                          _details(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (compact) ...[const SizedBox(height: 10), _details()],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: InkButton(
                  label: buttonLabel,
                  semanticLabel:
                      '${buying ? 'Buy' : 'Sell'} ${item.name} for $price gold',
                  onPressed: onTrade,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
