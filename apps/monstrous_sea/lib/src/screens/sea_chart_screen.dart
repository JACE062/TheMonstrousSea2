import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/svg_asset_view.dart';

/// Interactive 4x5 nautical chart grid revealing route progression toward The Kraken,
/// including the Hunter's Respite port anchorage and defeated beast skull markers.
class SeaChartScreen extends StatelessWidget {
  const SeaChartScreen({
    super.key,
    required this.seaChart,
    required this.onClose,
    this.isInPort = false,
  });

  final SeaChart seaChart;
  final VoidCallback onClose;
  final bool isInPort;

  static const List<String> _rowTitles = [
    'I. COASTAL SHALLOWS',
    'II. OUTER REEF SHOALS',
    'III. DEEP PELAGIC TRENCH',
    'IV. ABYSSAL REALM',
  ];

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'NAUTICAL SEA CHART',
                  style: InkTheme.titleLarge.copyWith(fontSize: 30),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Chart of the 20 Naval Sectors • Loop ${seaChart.timesCompleted}',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Harbor Anchorage / Port Haven spot
                Semantics(
                  label: isInPort
                      ? 'Harbor Haven: Hunter\'s Respite. Your ship is currently moored in port.'
                      : 'Harbor Haven: Hunter\'s Respite. Vessel has departed into open water.',
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isInPort
                          ? InkTheme.parchmentHighlight
                          : InkTheme.parchmentSurface,
                      border: Border.all(
                        color: isInPort ? InkTheme.goldAccent : InkTheme.inkMuted,
                        width: isInPort ? 2.0 : 1.2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        // Port Spot Anchorage icon box
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: InkTheme.parchmentDark.withValues(alpha: 0.35),
                            border: Border.all(
                              color: isInPort ? InkTheme.goldAccent : InkTheme.inkPrimary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.anchor, size: 28, color: InkTheme.inkPrimary),
                              if (isInPort)
                                Positioned(
                                  bottom: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: InkTheme.goldAccent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      'VESSEL',
                                      style: InkTheme.statLabel.copyWith(
                                        fontSize: 8,
                                        color: InkTheme.inkPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    "PORT OF DEPARTURE: HUNTER'S RESPITE",
                                    style: InkTheme.titleMedium.copyWith(fontSize: 15),
                                  ),
                                  if (isInPort)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: InkTheme.verdigrisGreen.withValues(alpha: 0.2),
                                        border: Border.all(color: InkTheme.verdigrisGreen),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        'ANCHORED IN PORT',
                                        style: InkTheme.caption.copyWith(
                                          color: InkTheme.verdigrisGreen,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isInPort
                                    ? 'Your ship is moored safely in harbor. Set sail from Hunter\'s Respite to enter Naval Sector I-1.'
                                    : 'Vessel is currently deployed on the open sea. Harbor is behind you.',
                                style: InkTheme.caption.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4x5 Chart Grid
                ...List.generate(4, (row) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_rowTitles[row]} (Danger Level ${row + 1 + seaChart.timesCompleted * 4})',
                          style: InkTheme.statLabel.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (col) {
                            // If in port, the vessel is at the harbor anchorage, not on the grid
                            final isCurrent = !isInPort &&
                                seaChart.currentRow == row &&
                                seaChart.currentCol == col;
                            final isCompleted = (row < seaChart.currentRow) ||
                                (row == seaChart.currentRow && col < seaChart.currentCol);
                            final isBoss = row == 3 && col == 4;
                            final isRevealed = seaChart.isRevealed(row, col);
                            final species = seaChart.speciesAt(row, col);

                            return Expanded(
                              child: Semantics(
                                label: 'Sector Row ${row + 1}, Column ${col + 1}. '
                                    'Danger level ${row + 1 + seaChart.timesCompleted * 4}. '
                                    '${isCurrent ? "Current ship location. " : ""}'
                                    '${isBoss ? "Final Boss sector. " : ""}'
                                    '${!isRevealed ? "Unexplored fog of war." : isCompleted ? "Defeated beast sector. Slain: ${species.name}." : "Encounter: ${species.name}."}',
                                excludeSemantics: true,
                                child: Container(
                                  height: 74,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? InkTheme.parchmentHighlight
                                        : isCompleted
                                            ? InkTheme.parchmentDark.withValues(alpha: 0.4)
                                            : !isRevealed
                                                ? InkTheme.parchmentDark.withValues(alpha: 0.65)
                                                : InkTheme.parchmentSurface,
                                    border: Border.all(
                                      color: isCurrent
                                          ? InkTheme.goldAccent
                                          : isBoss
                                              ? InkTheme.crimsonAccent
                                              : !isRevealed
                                                  ? InkTheme.inkFaint
                                                  : InkTheme.inkMuted,
                                      width: isCurrent || isBoss ? 2.0 : 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (!isRevealed)
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.cloud_queue, size: 20, color: InkTheme.inkFaint),
                                            const SizedBox(height: 2),
                                            Text(
                                              '░ FOG ░',
                                              style: InkTheme.caption.copyWith(
                                                color: InkTheme.inkFaint,
                                                fontSize: 9,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                          ],
                                        )
                                      else if (isCompleted)
                                        // Skull and crossbones denoting defeated monster
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '☠',
                                              style: TextStyle(
                                                fontSize: 26,
                                                color: InkTheme.crimsonAccent,
                                                height: 1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'DEFEATED',
                                              style: InkTheme.caption.copyWith(
                                                color: InkTheme.crimsonAccent,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SvgAssetView(
                                              assetPath: SvgAssetView.pathForSpecies(species),
                                              width: isBoss ? 42 : 34,
                                              height: isBoss ? 42 : 34,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              species.name.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: InkTheme.caption.copyWith(
                                                fontSize: 9,
                                                color: isBoss ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),

                                      // Current ship marker overlay
                                      if (isCurrent)
                                        Positioned(
                                          bottom: 3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: InkTheme.goldAccent,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              'VESSEL',
                                              style: InkTheme.statLabel.copyWith(
                                                fontSize: 8,
                                                color: InkTheme.inkPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),
                InkButton(
                  label: 'CLOSE SEA CHART',
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
