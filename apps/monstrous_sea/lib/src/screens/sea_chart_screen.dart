import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/nautical_chart.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/parchment_card.dart';

/// Read-only travelled history. Hidden plans and unchosen branches stay hidden.
class SeaChartScreen extends StatelessWidget {
  const SeaChartScreen({
    super.key,
    required this.seaChart,
    required this.onClose,
    this.isInPort = false,
    this.isCurrentDefeated = false,
  });
  final SeaChart seaChart;
  final VoidCallback onClose;
  final bool isInPort;
  // Retained adapter argument; actual victories come from committed outcomes.
  final bool isCurrentDefeated;
  int get effectiveLeg => isInPort ? 0 : seaChart.currentLeg;
  int difficultyForLeg(int leg) => seaChart.difficultyForLeg(leg);

  @override
  Widget build(BuildContext context) => ParchmentScaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('NAUTICAL SEA CHART', style: InkTheme.titleLarge),
              Text(
                '${seaChart.currentRegionName} · Region ${seaChart.currentRegionIndex + 1} of 3',
                style: InkTheme.subtitle,
              ),
              Text(
                isInPort
                    ? 'ANCHORED IN PORT'
                    : effectiveLeg > seaChart.totalLegs
                    ? 'Titan encounter'
                    : 'Leg $effectiveLeg of ${seaChart.totalLegs}',
                style: InkTheme.statLabel,
              ),
              Text(
                'Midpoint choice ${seaChart.midpointHavenLeg} · Final preparation ${seaChart.totalLegs} · Titan afterward',
                style: InkTheme.caption,
              ),
              const SizedBox(height: 14),
              ParchmentCard(
                child: NauticalChart(
                  chart: seaChart,
                  isInPort: isInPort,
                  viewportHeight: (MediaQuery.sizeOf(context).height * .55)
                      .clamp(300, 560),
                ),
              ),
              const SizedBox(height: 16),
              Text('DEAD-RECKONING VOYAGE LOG', style: InkTheme.titleMedium),
              if (seaChart.voyageLog.isEmpty)
                Text('No travelled soundings recorded.', style: InkTheme.body),
              for (final entry in seaChart.voyageLog.reversed)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ParchmentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Region ${entry.regionIndex + 1} · Leg ${entry.leg} · ${entry.bearing.displayName}',
                          style: InkTheme.statLabel,
                        ),
                        Text(
                          voyageOutcomeLabel(entry),
                          style: InkTheme.bodyBold,
                        ),
                        Text(
                          voyageDestinationLabel(entry),
                          style: InkTheme.body,
                        ),
                        if (entry.combatWon && entry.monsterSpecies != null)
                          Text(
                            '${entry.isApex ? 'Apex ' : ''}${entry.monsterSpecies!.displayName}',
                            style: InkTheme.caption,
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              InkButton(label: 'CLOSE SEA CHART', onPressed: onClose),
            ],
          ),
        ),
      ),
    ),
  );
}
