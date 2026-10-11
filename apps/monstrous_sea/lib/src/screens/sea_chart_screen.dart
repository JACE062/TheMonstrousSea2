import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/svg_asset_view.dart';

/// Interactive 4x5 nautical chart grid revealing route progression toward The Kraken.
class SeaChartScreen extends StatelessWidget {
  const SeaChartScreen({
    super.key,
    required this.seaChart,
    required this.onClose,
  });

  final SeaChart seaChart;
  final VoidCallback onClose;

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
                const SizedBox(height: 24),

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
                            final isCurrent =
                                seaChart.currentRow == row && seaChart.currentCol == col;
                            final isCompleted = (row < seaChart.currentRow) ||
                                (row == seaChart.currentRow && col < seaChart.currentCol);
                            final isBoss = row == 3 && col == 4;

                            return Expanded(
                              child: Container(
                                height: 70,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? InkTheme.parchmentHighlight
                                      : isCompleted
                                          ? InkTheme.parchmentDark.withValues(alpha: 0.5)
                                          : InkTheme.parchmentSurface,
                                  border: Border.all(
                                    color: isCurrent
                                        ? InkTheme.goldAccent
                                        : isBoss
                                            ? InkTheme.crimsonAccent
                                            : InkTheme.inkMuted,
                                    width: isCurrent || isBoss ? 2.0 : 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isBoss)
                                      SvgAssetView(
                                        assetPath: 'assets/art/monster_kraken.svg',
                                        width: 44,
                                        height: 44,
                                      )
                                    else if (isCompleted)
                                      const Icon(Icons.check, color: InkTheme.verdigrisGreen, size: 24)
                                    else
                                      Text(
                                        '[$row,$col]',
                                        style: InkTheme.caption.copyWith(
                                          color: isCurrent ? InkTheme.inkPrimary : InkTheme.inkFaint,
                                        ),
                                      ),

                                    // Current ship marker overlay
                                    if (isCurrent)
                                      Positioned(
                                        bottom: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: InkTheme.goldAccent,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            'VESSEL',
                                            style: InkTheme.statLabel.copyWith(
                                              fontSize: 9,
                                              color: InkTheme.inkPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
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
