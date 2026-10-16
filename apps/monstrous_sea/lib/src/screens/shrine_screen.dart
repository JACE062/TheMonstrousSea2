import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/hull_gauge.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pilot_art.dart';
import '../widgets/svg_asset_view.dart';

/// Screen rendered upon encountering an Ancient Sea Shrine rising from the depths,
/// presenting the captain with atmospheric regional lore and interactive devotions.
class ShrineScreen extends StatelessWidget {
  const ShrineScreen({
    super.key,
    required this.controller,
    required this.onOpenChart,
  });

  final GameController controller;
  final VoidCallback onOpenChart;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ship = controller.ship;
        final shrineName = controller.currentShrineName.isNotEmpty
            ? controller.currentShrineName
            : 'Shrine of the Abyssal Siren';
        final lore = controller.currentShrineLore.isNotEmpty
            ? controller.currentShrineLore
            : 'Runes carved into barnacled basalt whisper of ancient titans.';
        final hasCommuned = controller.hasCommunedAtCurrentShrine;

        final tributeCost = 30;
        final canAffordTribute = (ship?.gold ?? 0) >= tributeCost;
        final pactDamage = ship != null ? (ship.maxHp * 0.20).round() : 0;
        final canEndurePact = ship != null && ship.currentHp > pactDamage;

        return ParchmentScaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                // Top Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkButton(
                      label: 'SEA CHART',
                      semanticLabel: 'Open navigation sea chart',
                      onPressed: onOpenChart,
                    ),
                    if (ship != null)
                      Text(
                        'PURSE: ${ship.gold}g',
                        style: InkTheme.statLabel.copyWith(
                          color: InkTheme.goldAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Header
                Center(
                  child: SvgAssetView(
                    assetPath: PilotArt.portHaven,
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shrineName.toUpperCase(),
                  style: InkTheme.titleLarge.copyWith(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'A luminous monolith rises from foaming brine, inscribed with glyphs of ancient navigators.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Lore Inscription Plaque
                ParchmentCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_stories, size: 18, color: InkTheme.goldAccent),
                          const SizedBox(width: 8),
                          Text(
                            'ANCIENT RUNIC INSCRIPTION',
                            style: InkTheme.caption.copyWith(
                              color: InkTheme.goldAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lore,
                        style: InkTheme.body.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Vessel Vitality Gauge
                if (ship != null) ...[
                  ParchmentCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${ship.name} (Tier ${ship.level} ${ship.shipClass.displayName})',
                          style: InkTheme.statValue.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        HullGauge(
                          currentHp: ship.currentHp,
                          maxHp: ship.maxHp,
                          label: 'VESSEL HULL VITALITY',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Devotion Actions or Departure
                if (!hasCommuned) ...[
                  Text(
                    'CHOOSE YOUR DEVOTION',
                    style: InkTheme.statValue.copyWith(
                      color: InkTheme.goldAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 1: Offer Tribute of Gold
                  ParchmentCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OFFER TRIBUTE OF GOLD (30g)',
                                style: InkTheme.statValue.copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cast gold doubloons into the deep. Ancient spirits grant favorable wind (+15% accuracy boon on next engagement).',
                                style: InkTheme.caption.copyWith(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkButton(
                          label: 'COMMUNE',
                          isPrimary: true,
                          semanticLabel: 'Offer 30 gold tribute for accuracy boon',
                          onPressed: canAffordTribute
                              ? () => controller.dispatch(
                                    const CommuneWithShrine(ShrineChoice.tribute),
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 2: Abyssal Pact
                  ParchmentCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ABYSSAL PACT (-$pactDamage HP)',
                                style: InkTheme.statValue.copyWith(
                                  color: InkTheme.crimsonAccent,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sacrifice 20% hull integrity to the abyssal void in exchange for a powerful relic naval weapon.',
                                style: InkTheme.caption.copyWith(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkButton(
                          label: 'SACRIFICE',
                          isDanger: true,
                          semanticLabel: 'Sacrifice hull integrity for a relic weapon',
                          onPressed: canEndurePact
                              ? () => controller.dispatch(
                                    const CommuneWithShrine(ShrineChoice.abyssalPact),
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 3: Consult Ancient Runes
                  ParchmentCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CONSULT ANCIENT RUNES (FREE)',
                                style: InkTheme.statValue.copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Meditate upon navigation glyphs to pierce the fog across the soundings ahead and grant a +10% accuracy boon.',
                                style: InkTheme.caption.copyWith(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkButton(
                          label: 'MEDITATE',
                          semanticLabel: 'Consult runes to reveal next soundings',
                          onPressed: () => controller.dispatch(
                            const CommuneWithShrine(ShrineChoice.ancientRunes),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sail Past
                  Center(
                    child: TextButton(
                      onPressed: () => controller.dispatch(const DepartShrine()),
                      child: Text(
                        'SAIL PAST IN REVERENCE',
                        style: InkTheme.caption.copyWith(
                          color: InkTheme.inkMuted,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ParchmentCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'COMMUNION COMPLETE',
                          style: InkTheme.statValue.copyWith(
                            color: InkTheme.goldAccent,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The phosphorescent glow dims as the spirits withdraw. The sea ahead awaits your passage.',
                          style: InkTheme.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkButton(
                    label: 'DEPART SHRINE & SET SAIL',
                    isPrimary: true,
                    semanticLabel: 'Depart the ancient sea shrine and continue voyage',
                    onPressed: () => controller.dispatch(const DepartShrine()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
