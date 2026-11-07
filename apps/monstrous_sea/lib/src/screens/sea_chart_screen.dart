import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/nautical_chart.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/voyage_log_view.dart';

/// Read-only travelled history. Hidden plans and unchosen branches stay hidden.
class SeaChartScreen extends StatelessWidget {
  const SeaChartScreen({
    super.key,
    required this.seaChart,
    required this.onClose,
    this.ship,
    this.isInPort = false,
    this.isCurrentDefeated = false,
  });
  final SeaChart seaChart;
  final ShipState? ship;
  final VoidCallback onClose;
  final bool isInPort;
  // Retained adapter argument; actual victories come from committed outcomes.
  final bool isCurrentDefeated;
  int get effectiveLeg => isInPort ? 0 : seaChart.currentLeg;
  int difficultyForLeg(int leg) => seaChart.difficultyForLeg(leg);

  @override
  Widget build(BuildContext context) => ParchmentScaffold(
    body: Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NAUTICAL SEA CHART', style: InkTheme.titleLarge),
              Text(
                seaChart.currentRegionName,
                style: InkTheme.subtitle,
              ),
              if (isInPort)
                Text('ANCHORED IN PORT', style: InkTheme.statLabel),
            ],
          );
          final actions = Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              InkButton(
                label: 'VOYAGE LOG',
                compact: true,
                icon: const Icon(Icons.menu_book, size: 21),
                onPressed: () => showVoyagePanel(
                  context,
                  closeLabel: 'CLOSE LOGBOOK',
                  child: VoyageLogView(chart: seaChart),
                ),
              ),
              InkButton(
                label: 'CLOSE SEA CHART',
                compact: true,
                onPressed: onClose,
              ),
            ],
          );
          final header = bounds.maxWidth >= 1000
              ? Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 16),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [title, const SizedBox(height: 12), actions],
                );
          Widget chart() => NauticalChart(
            chart: seaChart,
            ship: ship,
            isInPort: isInPort,
            expandViewport: true,
          );
          if (bounds.maxHeight < 600) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 12),
                  SizedBox(height: 400, child: chart()),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 12),
              Expanded(child: chart()),
            ],
          );
        },
      ),
    ),
  );
}
