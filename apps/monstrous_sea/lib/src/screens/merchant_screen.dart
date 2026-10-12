import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/pilot_art.dart';
import '../widgets/weapon_stats_view.dart';

/// Screen for trading with the Harpoon & Helm Merchant at Hunter's Respite.
class MerchantScreen extends StatelessWidget {
  const MerchantScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    final stock = controller.merchantStock;
    final cargo = ship?.cargo ?? const <Item>[];
    final hasTreasures = cargo.any((item) => item is Treasure);

    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HARPOON & HELM CHANDLERY', style: InkTheme.titleLarge.copyWith(fontSize: 28)),
                          Text('Purveyor of Fine Naval Arms & Rare Supplies', style: InkTheme.subtitle),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: InkTheme.parchmentHighlight,
                        border: Border.all(color: InkTheme.goldAccent, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          SvgAssetView(assetPath: PilotArt.treasure, width: 22, height: 22),
                          const SizedBox(width: 8),
                          Text('${ship?.gold ?? 0}g', style: InkTheme.statValue.copyWith(color: InkTheme.goldAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Sell All Treasure Bar
                if (hasTreasures)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: InkTheme.parchmentHighlight,
                      border: Border.all(color: InkTheme.goldAccent, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'You are carrying salvaged treasures suitable for exchange!',
                          style: InkTheme.bodyBold,
                        ),
                        InkButton(
                          label: 'SELL ALL TREASURE',
                          isPrimary: true,
                          onPressed: () => controller.dispatch(const SellAllTreasure()),
                        ),
                      ],
                    ),
                  ),

                // Wares & Cargo in two columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Merchant Wares
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('MERCHANT WARES FOR SALE', style: InkTheme.statLabel),
                          const SizedBox(height: 8),
                          if (stock.isEmpty)
                            ParchmentCard(
                              child: Text('The merchant has been cleaned out of stock!', style: InkTheme.caption),
                            )
                          else
                            ...List.generate(stock.length, (index) {
                              final item = stock[index];
                              final askingPrice = controller.session.getMerchantAskingPrice(index);
                              final isOnSale = controller.session.onSaleMerchantIndex == index;
                              final canAfford = (ship?.gold ?? 0) >= askingPrice;
                              final hasRoom = (ship?.cargo.length ?? 0) < (ship?.maxCargo ?? 0);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ParchmentCard(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SvgAssetView(
                                        assetPath: SvgAssetView.pathForItem(item),
                                        width: 36,
                                        height: 36,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    style: InkTheme.statValue.copyWith(
                                                      color: InkTheme.rarityColor(item.rarity),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                if (isOnSale)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: InkTheme.goldAccent,
                                                      borderRadius: BorderRadius.circular(3),
                                                    ),
                                                    child: Text(
                                                      'SALE (-25%)',
                                                      style: InkTheme.caption.copyWith(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: InkTheme.inkPrimary,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            Text(item.description, style: InkTheme.caption.copyWith(fontSize: 12)),
                                            const SizedBox(height: 3),
                                            WeaponStatsView(item: item, compact: true),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Cost: ${askingPrice}g'
                                              '${isOnSale ? ' (was ${(item.value * 1.35).round()}g)' : ''}',
                                              style: InkTheme.statLabel.copyWith(
                                                color: canAfford ? InkTheme.goldAccent : InkTheme.crimsonAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkButton(
                                        label: !canAfford
                                            ? 'Lacks Gold'
                                            : !hasRoom
                                                ? 'Hold Full'
                                                : 'Buy',
                                        isPrimary: canAfford && hasRoom,
                                        onPressed: canAfford && hasRoom
                                            ? () => controller.dispatch(BuyMerchantItem(index))
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Player Cargo Hold
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('SHIP CARGO HOLD (${cargo.length}/${ship?.maxCargo ?? 0})', style: InkTheme.statLabel),
                          const SizedBox(height: 8),
                          if (cargo.isEmpty)
                            ParchmentCard(
                              child: Text('Your cargo hold is empty.', style: InkTheme.caption),
                            )
                          else
                            ...List.generate(cargo.length, (index) {
                              final item = cargo[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ParchmentCard(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SvgAssetView(
                                        assetPath: SvgAssetView.pathForItem(item),
                                        width: 36,
                                        height: 36,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: InkTheme.statValue.copyWith(
                                                color: InkTheme.rarityColor(item.rarity),
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(item.description, style: InkTheme.caption.copyWith(fontSize: 12)),
                                            const SizedBox(height: 3),
                                            WeaponStatsView(item: item, compact: true),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Sell: ${item.value}g',
                                              style: InkTheme.statLabel.copyWith(
                                                color: InkTheme.goldAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkButton(
                                        label: 'Sell',
                                        onPressed: () => controller.dispatch(SellCargoItem(index)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Return Button
                InkButton(
                  label: 'LEAVE CHANDLERY & RETURN TO PORT',
                  onPressed: () => controller.dispatch(const LeaveMerchant()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
