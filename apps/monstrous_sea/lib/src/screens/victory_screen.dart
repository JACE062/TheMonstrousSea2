import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pilot_art.dart';
import '../widgets/svg_asset_view.dart';

/// Screen rendered upon vanquishing the Ancient Leviathan at Region 3,
/// celebrating the captain's triumphant conquest of The Monstrous Sea.
class VictoryScreen extends StatelessWidget {
  const VictoryScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final ship = controller.ship;
    final captainName = controller.captainName;
    final monstersDefeated = controller.session.monstersDefeatedThisLife;
    final goldAmassed = ship?.gold ?? 0;

    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Laurel / Victory Icon
                Center(
                  child: SvgAssetView(
                    assetPath: PilotArt.portHaven,
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'EXPEDITION CONQUERED',
                  style: InkTheme.titleLarge.copyWith(
                    fontSize: 34,
                    color: InkTheme.goldAccent,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The Ancient Leviathan thrashes in final agony and plunges into the boiling caldera abyss. The three regions are charted, the horrors vanquished, and the sea is tamed.',
                  style: InkTheme.subtitle.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Grand Chronicle Plaque
                ParchmentCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'ADMIRALTY CHRONICLE OF HONOR',
                        style: InkTheme.statLabel.copyWith(
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: InkTheme.inkMuted, height: 1),
                      const SizedBox(height: 16),

                      _buildStatRow('EXPEDITION COMMANDER', 'Captain $captainName'),
                      const SizedBox(height: 10),
                      if (ship != null) ...[
                        _buildStatRow('FLAGSHIP', '${ship.name} (Tier ${ship.level} ${ship.shipClass.displayName})'),
                        const SizedBox(height: 10),
                      ],
                      _buildStatRow('COLOSSAL BEASTS VANQUISHED', '$monstersDefeated Monsters'),
                      const SizedBox(height: 10),
                      _buildStatRow('ROYAL GOLD BOUNTY AMASSED', '${goldAmassed}g Doubloons'),
                      const SizedBox(height: 10),
                      _buildStatRow('REGIONS EXPLORED & CLEARED', 'All 3 Reaches (Siren Shoals, Sargasso, Boiling Caldera)'),
                      const SizedBox(height: 16),
                      const Divider(color: InkTheme.inkMuted, height: 1),
                      const SizedBox(height: 16),
                      Text(
                        '“Songs of this voyage shall echo through maritime taverns and royal harbors for generations to come.”',
                        style: InkTheme.body.copyWith(
                          fontStyle: FontStyle.italic,
                          color: InkTheme.goldAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // The Caldera Dilemma Plaque
                ParchmentCard(
                  borderColor: InkTheme.crimsonAccent,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.whatshot, color: InkTheme.crimsonAccent, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'THE CALDERA DILEMMA',
                            style: InkTheme.titleMedium.copyWith(
                              color: InkTheme.crimsonAccent,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Before you churns the Abyssal Font—the hydrothermal birthplace of all monsters. In your hands pulses the radiant Primordial Leviathan Core. You stand at the crossroads of your bloodline’s destiny:',
                        style: InkTheme.body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Choice 1 Card: Shatter the Core
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: InkTheme.parchmentSurface,
                          border: Border.all(color: InkTheme.goldAccent, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_fix_high, color: InkTheme.goldAccent, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'SHATTER THE CORE — BREAK THE CYCLE',
                                    style: InkTheme.statLabel.copyWith(
                                      color: InkTheme.goldAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Detonate the Leviathan Core inside the fissure. The Abyssal Font will implode forever, quenching the birthplace of leviathans, curing the generational salt-sickness, and concluding your bloodline\'s hunt as mortal legend.',
                              style: InkTheme.caption.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 14),
                            InkButton(
                              label: 'SHATTER THE CORE (CONCLUDE QUEST)',
                              semanticLabel: 'Shatter the Core to destroy the Font and end the hunt',
                              isPrimary: true,
                              onPressed: () => controller.dispatch(
                                const ResolveCalderaClimax(CalderaClimaxChoice.shatterCore),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Choice 2 Card: Claim the Core
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: InkTheme.parchmentDark.withValues(alpha: 0.15),
                          border: Border.all(color: InkTheme.crimsonAccent, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.whatshot, color: InkTheme.crimsonAccent, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'CLAIM THE CORE — ASCEND INTO THE COVENANT',
                                    style: InkTheme.statLabel.copyWith(
                                      color: InkTheme.crimsonAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Surrender to primordial deep-sea power! The captain ascends as Warden of the Caldera. The flagship returns alone to harbor with the Core fused into its keel, awakening the Covenant of the Deep (Pact Burden, Primordial Cinders, Eldritch Relics & Harbor Monuments) for your heirs to continue the loop.',
                              style: InkTheme.caption.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 14),
                            InkButton(
                              label: 'CLAIM THE CORE (ASCEND & LOOP)',
                              semanticLabel: 'Claim the Core to unlock the Covenant of the Deep and loop to heir succession',
                              onPressed: () => controller.dispatch(
                                const ResolveCalderaClimax(CalderaClimaxChoice.claimCore),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: InkTheme.statLabel.copyWith(fontSize: 12)),
        Flexible(
          child: Text(
            value,
            style: InkTheme.statValue.copyWith(fontSize: 14),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
