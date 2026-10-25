import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pause_menu.dart';
import '../widgets/svg_asset_view.dart';
import '../widgets/pilot_art.dart';

/// Interactive dead-reckoning sea chart revealing the 10-leg expedition progression toward The Regional Titan,
/// including the Harbor Haven anchorage, Midpoint Respite Haven, and defeated beast markers.
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
  final bool isCurrentDefeated;

  /// The active expedition leg (0 when in port, 1..totalLegs underway).
  int get effectiveLeg {
    if (isInPort) return 0;
    if (seaChart.currentLeg > 0) return seaChart.currentLeg;
    // Fallback if initialized via legacy coordinates (currentRow, currentCol)
    return (seaChart.currentRow * SeaChart.totalCols + seaChart.currentCol + 1)
        .clamp(1, seaChart.totalLegs);
  }

  int difficultyForLeg(int leg) {
    if (leg == seaChart.regionTitanLeg) {
      return SeaChart.bossRow + 2 + seaChart.timesCompleted * 4;
    }
    return ((leg + 1) ~/ 2).clamp(1, 4) + seaChart.timesCompleted * 4;
  }

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      showPauseButton: false,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PauseMenuButton(),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'NAUTICAL SEA CHART',
                            style: InkTheme.titleLarge.copyWith(fontSize: 25),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'EXPEDITION: ${seaChart.currentRegionName.toUpperCase()} • Region ${seaChart.currentRegionIndex + 1} of ${SeaChart.totalRegions}',
                            style: InkTheme.subtitle.copyWith(
                              color: InkTheme.goldAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            seaChart.currentRegionSubtitle,
                            style: InkTheme.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: InkTheme.inkPrimary),
                      tooltip: 'Close Sea Chart',
                      onPressed: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Harbor Anchorage / Expedition Stronghold Haven
                Semantics(
                  label: isInPort
                      ? 'Harbor Haven: ${seaChart.currentPortName}. Your vessel is currently moored in port.'
                      : 'Harbor Haven: ${seaChart.currentPortName}. Vessel has set sail into open soundings.',
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isInPort
                          ? InkTheme.parchmentHighlight
                          : InkTheme.parchmentSurface,
                      border: Border.all(
                        color: isInPort
                            ? InkTheme.goldAccent
                            : InkTheme.inkMuted,
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
                            color: InkTheme.parchmentDark.withValues(
                              alpha: 0.35,
                            ),
                            border: Border.all(
                              color: isInPort
                                  ? InkTheme.goldAccent
                                  : InkTheme.inkPrimary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const SvgAssetView(
                                assetPath: PilotArt.portHaven,
                                width: 48,
                                height: 48,
                              ),
                              if (isInPort)
                                Positioned(
                                  bottom: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: InkTheme.goldAccent,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: InkTheme.inkPrimary,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      'VESSEL',
                                      style: InkTheme.statLabel.copyWith(
                                        fontSize: 9.5,
                                        color: InkTheme.inkPrimary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
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
                                    seaChart.currentRegionIndex == 0
                                        ? "PORT OF DEPARTURE: ${seaChart.currentPortName.toUpperCase()}"
                                        : "EXPEDITION STRONGHOLD: ${seaChart.currentPortName.toUpperCase()}",
                                    style: InkTheme.titleMedium.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isInPort)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: InkTheme.verdigrisGreen
                                            .withValues(alpha: 0.2),
                                        border: Border.all(
                                          color: InkTheme.verdigrisGreen,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        'ANCHORED IN PORT',
                                        style: InkTheme.caption.copyWith(
                                          color: InkTheme.verdigrisGreen,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isInPort
                                    ? "Your vessel is moored safely in harbor at ${seaChart.currentPortName}. Take the helm to steer out into Soundings I."
                                    : "Vessel has set sail from ${seaChart.currentPortName}. Harbor is left in your wake as you press outward to sea.",
                                style: InkTheme.caption.copyWith(
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Soundings I • Inshore Waters (Legs 1 to midpointHavenLeg)
                _buildSoundingsTrack(
                  trackTitle: 'SOUNDINGS I • INSHORE WATERS',
                  subtitle:
                      'Inshore soundings leading to the Midpoint Respite Haven',
                  startLeg: 1,
                  endLeg: seaChart.midpointHavenLeg,
                ),
                const SizedBox(height: 16),

                // Soundings II • Abyssal Passage (Legs midpointHavenLeg + 1 to totalLegs)
                _buildSoundingsTrack(
                  trackTitle: 'SOUNDINGS II • ABYSSAL PASSAGE',
                  subtitle: 'Deepwater soundings leading to the Regional Titan\'s Lair',
                  startLeg: seaChart.midpointHavenLeg + 1,
                  endLeg: seaChart.totalLegs,
                ),
                const SizedBox(height: 20),

                // Dead-Reckoning Voyage Log (Chronicle)
                _buildVoyageLog(),

                const SizedBox(height: 24),
                InkButton(label: 'CLOSE SEA CHART', onPressed: onClose),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoundingsTrack({
    required String trackTitle,
    required String subtitle,
    required int startLeg,
    required int endLeg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 2,
          children: [
            Text(
              trackTitle,
              style: InkTheme.statLabel.copyWith(
                fontSize: 13.5,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Legs $startLeg – $endLeg',
              style: InkTheme.caption.copyWith(
                color: InkTheme.inkMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(subtitle, style: InkTheme.caption.copyWith(fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(endLeg - startLeg + 1, (index) {
            final leg = startLeg + index;
            return Expanded(child: _buildWaypointCard(leg));
          }),
        ),
      ],
    );
  }

  Widget _buildWaypointCard(int leg) {
    final activeLeg = effectiveLeg;
    final isCurrent = !isInPort && leg == activeLeg;
    final isCompleted = (leg < activeLeg) || (isCurrent && isCurrentDefeated);
    final isHaven = leg == seaChart.midpointHavenLeg;
    final isBoss = leg == seaChart.regionTitanLeg;

    // Revealed if completed, current, guaranteed landmarks (haven/boss)
    final isRevealed = isCompleted || isCurrent || isHaven || isBoss;

    // Look up voyage record if logged
    final VoyageLegRecord? record = (leg <= seaChart.voyageLog.length)
        ? seaChart.voyageLog[leg - 1]
        : null;

    // Determine node type and species
    final EncounterNodeType nodeType =
        record?.nodeType ??
        (isHaven
            ? EncounterNodeType.respiteIsland
            : isBoss
            ? EncounterNodeType.regionTitan
            : isCurrent
            ? seaChart.currentNodeType
            : EncounterNodeType.beastCombat);

    final MonsterSpecies? species =
        record?.monsterSpecies ??
        (isCurrent
            ? seaChart.speciesAt(seaChart.currentRow, seaChart.currentCol)
            : null);

    final nodeLabel = switch (nodeType) {
      EncounterNodeType.respiteIsland => 'Respite Haven',
      EncounterNodeType.shipwreckSalvage => 'Shipwreck derelict',
      EncounterNodeType.smugglerTrader => 'Smuggler trader',
      EncounterNodeType.ancientShrine => 'Ancient Sea Shrine',
      EncounterNodeType.regionTitan => 'Region Titan lair',
      EncounterNodeType.beastCombat =>
        species != null ? species.name : 'Sea beast',
    };

    final semanticsLabel =
        'Expedition Leg $leg. '
        'Danger level ${difficultyForLeg(leg)}. '
        '${isCurrent ? "Current ship location. " : ""}'
        '${isBoss ? "Final Titan sector. " : ""}'
        '${isHaven ? "Midpoint Haven. " : ""}'
        '${!isRevealed
            ? "Unexplored fog of war."
            : isCompleted
            ? "Completed sector: $nodeLabel."
            : nodeLabel}';

    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        height: 80,
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
                : isHaven
                ? InkTheme.goldAccent
                : !isRevealed
                ? InkTheme.inkFaint
                : InkTheme.inkMuted,
            width: isCurrent || isBoss || isHaven ? 2.0 : 1.0,
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
                  const SvgAssetView(
                    assetPath: PilotArt.fog,
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '░ FOG ░',
                    style: InkTheme.caption.copyWith(
                      color: InkTheme.inkFaint,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              )
            else if (isCompleted)
              Padding(
                padding: EdgeInsets.only(top: isCurrent ? 8 : 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SvgAssetView(
                      assetPath: PilotArt.defeatedMonster,
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DEFEATED',
                      style: InkTheme.caption.copyWith(
                        color: InkTheme.crimsonAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(top: isCurrent ? 8 : 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgAssetView(
                      assetPath: isHaven
                          ? PilotArt.anchor
                          : isBoss
                          ? PilotArt.kraken
                          : nodeType == EncounterNodeType.shipwreckSalvage
                          ? PilotArt.treasure
                          : nodeType == EncounterNodeType.smugglerTrader
                          ? PilotArt.helm
                          : nodeType == EncounterNodeType.ancientShrine
                          ? PilotArt.portHaven
                          : species != null
                          ? SvgAssetView.pathForSpecies(species)
                          : PilotArt.kraken,
                      width: isBoss ? 38 : 30,
                      height: isBoss ? 38 : 30,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHaven
                          ? 'HAVEN'
                          : isBoss
                          ? 'TITAN'
                          : nodeType == EncounterNodeType.shipwreckSalvage
                          ? 'WRECK'
                          : nodeType == EncounterNodeType.smugglerTrader
                          ? 'SMUGGLER'
                          : nodeType == EncounterNodeType.ancientShrine
                          ? 'SHRINE'
                          : species != null
                          ? species.name.toUpperCase()
                          : 'BEAST',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: InkTheme.caption.copyWith(
                        fontSize: 10.5,
                        color: isBoss
                            ? InkTheme.crimsonAccent
                            : isHaven
                            ? InkTheme.goldAccent
                            : InkTheme.inkPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Pinned VESSEL marker on current leg at top
            if (isCurrent)
              Positioned(
                top: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: InkTheme.goldAccent,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: InkTheme.inkPrimary, width: 0.8),
                  ),
                  child: Text(
                    'VESSEL',
                    style: InkTheme.statLabel.copyWith(
                      fontSize: 9.5,
                      color: InkTheme.inkPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoyageLog() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InkTheme.parchmentSurface,
        border: Border.all(color: InkTheme.inkMuted),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                'DEAD-RECKONING VOYAGE LOG',
                style: InkTheme.statValue.copyWith(
                  fontSize: 13,
                  letterSpacing: 1.0,
                  color: InkTheme.goldAccent,
                ),
              ),
              Text(
                'Leg $effectiveLeg of ${seaChart.totalLegs}',
                style: InkTheme.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (seaChart.voyageLog.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No bearings steered yet. As you take the helm and choose your headings, each nautical leg, bearing tack, and lookout sighting will be permanently charted here.',
                style: InkTheme.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 12.5,
                ),
              ),
            )
          else
            Column(
              children: seaChart.voyageLog.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: InkTheme.parchmentDark.withValues(alpha: 0.35),
                    border: Border.all(color: InkTheme.inkFaint),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: InkTheme.goldAccent.withValues(alpha: 0.2),
                          border: Border.all(
                            color: InkTheme.goldAccent,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'LEG ${entry.leg}: ${entry.bearing.shortName}',
                          style: InkTheme.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: InkTheme.goldAccent,
                          ),
                        ),
                      ),
                      if (entry.isApex) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: InkTheme.crimsonAccent.withValues(
                              alpha: 0.2,
                            ),
                            border: Border.all(
                              color: InkTheme.crimsonAccent,
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'APEX',
                            style: InkTheme.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: InkTheme.crimsonAccent,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.bearing.displayName} • ${entry.nodeType.displayName}',
                              style: InkTheme.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: InkTheme.inkPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '"${entry.lookoutCall}"',
                              style: InkTheme.caption.copyWith(
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
