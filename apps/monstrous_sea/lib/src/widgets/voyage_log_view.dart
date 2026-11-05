import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'nautical_chart.dart';
import 'parchment_card.dart';

/// One history presentation for the helm's logbook and charts at other stops.
class VoyageLogView extends StatelessWidget {
  const VoyageLogView({super.key, required this.chart});
  final SeaChart chart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('DEAD-RECKONING VOYAGE LOG', style: InkTheme.titleMedium),
      if (chart.voyageLog.isEmpty)
        Text('No travelled soundings recorded.', style: InkTheme.body),
      for (final entry in chart.voyageLog.reversed)
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
                Text(voyageOutcomeLabel(entry), style: InkTheme.bodyBold),
                Text(voyageDestinationLabel(entry), style: InkTheme.body),
                if (entry.isNemesis)
                  Text(
                    'NEMESIS',
                    style: InkTheme.statLabel.copyWith(
                      color: InkTheme.crimsonAccent,
                    ),
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
    ],
  );
}

Future<void> showVoyagePanel(
  BuildContext context, {
  required String closeLabel,
  required Widget child,
}) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    backgroundColor: InkTheme.parchmentSurface,
    insetPadding: const EdgeInsets.all(18),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: InkTheme.inkMuted, width: 1.5),
      borderRadius: BorderRadius.circular(4),
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 760,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(child: SingleChildScrollView(child: child)),
            const SizedBox(height: 12),
            InkButton(
              label: closeLabel,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  ),
);
