import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/armory_view.dart';
import '../widgets/nautical_chart.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/voyage_log_view.dart';

/// The chart and current lookout reports form one navigation surface.
class HelmScreen extends StatefulWidget {
  const HelmScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<HelmScreen> createState() => _HelmScreenState();
}

class _HelmScreenState extends State<HelmScreen> {
  bool _departing = false;
  Widget? _lastHelmView;
  final _reportsScroll = ScrollController();

  @override
  void dispose() {
    _reportsScroll.dispose();
    super.dispose();
  }

  void _redrawCourses() {
    final controller = widget.controller;
    if (_departing ||
        controller.phase != SessionPhase.helm ||
        !controller.canRedrawStormSeerCourses) {
      return;
    }
    controller.dispatch(const RedrawStormSeerCourses());
  }

  void _steer(NavigationalBearing bearing) {
    if (_departing || widget.controller.phase != SessionPhase.helm) return;
    setState(() => _departing = true);
    try {
      widget.controller.dispatch(SteerCourse(bearing));
    } catch (_) {
      if (mounted) setState(() => _departing = false);
      rethrow;
    }
  }

  Widget _reports() {
    final controller = widget.controller;
    final options = controller.currentCourseOptions;
    final ship = controller.ship;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          options.length == 1
              ? 'LOOKOUT OBSERVATION • CONVERGENT APPROACH'
              : 'LOOKOUT OBSERVATIONS & COURSES',
          style: InkTheme.statLabel.copyWith(
            color: InkTheme.inkSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        if (controller.canEmergencyRepairAtSea) ...[
          ParchmentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('EMERGENCY HULL TRIAGE', style: InkTheme.statValue),
                Text(
                  'Patch the hull to 25% integrity before choosing a heading.',
                  style: InkTheme.body,
                ),
                InkButton(
                  label: 'PATCH TO 25% · ${controller.emergencyRepairCost}g',
                  onPressed:
                      ship != null &&
                          ship.gold >= controller.emergencyRepairCost
                      ? () => controller.dispatch(const RepairShip(0.25))
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (controller.activeBoon?.id == BloodlineTraitId.stormSeer) ...[
          ParchmentCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('STORM-SEER', style: InkTheme.statLabel),
                const SizedBox(height: 4),
                Text(
                  'Read the winds once per region to redraw ordinary headings. Haven, Titan and Nemesis courses hold fast.',
                  style: InkTheme.caption,
                ),
                const SizedBox(height: 8),
                InkButton(
                  key: const ValueKey('storm-seer-redraw'),
                  label: 'READ THE WINDS',
                  compact: true,
                  semanticHint: controller.stormSeerRedrawRestriction,
                  onPressed: controller.canRedrawStormSeerCourses
                      ? _redrawCourses
                      : null,
                ),
                if (controller.stormSeerRedrawRestriction
                    case final restriction?) ...[
                  const SizedBox(height: 6),
                  Text(restriction, style: InkTheme.caption),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (options.isEmpty)
          ParchmentCard(
            child: Text(
              'Awaiting the navigator to verify current soundings...',
              style: InkTheme.body,
            ),
          ),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CourseOptionCard(
              option: option,
              restriction: controller.session.courseRestriction(option.bearing),
              onSteer: () => _steer(option.bearing),
            ),
          ),
      ],
    );
  }

  Widget _header(BuildContext context, bool compact) {
    final controller = widget.controller;
    final ship = controller.ship;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NAUTICAL SEA CHART',
          style: InkTheme.titleLarge.copyWith(fontSize: compact ? 26 : 32),
        ),
        Text(
          '${controller.seaChart.currentRegionName} · Region ${controller.seaChart.currentRegionIndex + 1} of 3 · ${controller.currentLeg >= controller.totalLegs ? 'Titan approach' : 'Leg ${controller.currentLeg + 1} of ${controller.totalLegs}'}',
          style: InkTheme.subtitle.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 3),
        Text(
          compact
              ? 'FRESH WESTERLIES · ONWARD'
              : 'FRESH WESTERLIES · EVERY HEADING PRESSES ONWARD',
          style: InkTheme.caption.copyWith(fontSize: 11),
        ),
      ],
    );
    final status = ship == null
        ? const SizedBox.shrink()
        : Text(
            'HULL ${ship.currentHp}/${ship.maxHp} · PURSE ${ship.gold}g',
            style: InkTheme.statLabel.copyWith(fontSize: 12),
          );
    void openLog() => showVoyagePanel(
      context,
      closeLabel: 'CLOSE LOGBOOK',
      child: VoyageLogView(chart: controller.seaChart),
    );
    void inspect() => showVoyagePanel(
      context,
      closeLabel: 'CLOSE INSPECTION',
      child: ArmoryView(controller: controller),
    );
    final log = compact
        ? IconButton(
            key: const ValueKey('helm-voyage-log'),
            tooltip: 'Voyage log',
            icon: const Icon(Icons.menu_book),
            onPressed: openLog,
          )
        : TextButton.icon(
            key: const ValueKey('helm-voyage-log'),
            icon: const Icon(Icons.menu_book, size: 20),
            label: Text(
              'VOYAGE LOG',
              style: InkTheme.statLabel.copyWith(fontSize: 12),
            ),
            onPressed: openLog,
          );
    final inspection = compact
        ? IconButton(
            key: const ValueKey('helm-inspect-vessel'),
            tooltip: 'Inspect vessel',
            icon: const Icon(Icons.sailing),
            onPressed: inspect,
          )
        : TextButton.icon(
            key: const ValueKey('helm-inspect-vessel'),
            icon: const Icon(Icons.sailing, size: 20),
            label: Text(
              'INSPECT VESSEL',
              style: InkTheme.statLabel.copyWith(fontSize: 12),
            ),
            onPressed: inspect,
          );
    final tools = compact
        ? Row(
            children: [
              Expanded(child: status),
              log,
              inspection,
            ],
          )
        : Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [status, log, inspection],
          );
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 8), tools],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              Flexible(
                child: Align(alignment: Alignment.centerRight, child: tools),
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      // Preserve the outgoing offers during the orchestrator's fade.
      if (_departing || controller.phase != SessionPhase.helm) {
        return IgnorePointer(
          child: ExcludeFocus(child: _lastHelmView ?? const SizedBox.shrink()),
        );
      }
      // Capture these widgets while still at the helm. LayoutBuilder can run
      // again after departure, when the session already owns the next encounter.
      final header = _header(context, MediaQuery.sizeOf(context).width < 752);
      final reports = _reports();
      return _lastHelmView = ParchmentScaffold(
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final overlay =
                  constraints.maxWidth >= 1000 && constraints.maxHeight >= 500;
              if (overlay) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 8),
                    Expanded(
                      child: NauticalChart(
                        chart: controller.seaChart,
                        ship: controller.ship,
                        takeMotion: controller.takeNavigationMotion,
                        expandViewport: true,
                        coursePanel: RawScrollbar(
                          controller: _reportsScroll,
                          thumbVisibility: true,
                          thumbColor: InkTheme.inkMuted.withValues(alpha: .55),
                          thickness: 4,
                          radius: const Radius.circular(2),
                          child: SingleChildScrollView(
                            key: const ValueKey('helm-courses-scroll'),
                            controller: _reportsScroll,
                            padding: const EdgeInsets.only(right: 10),
                            child: reports,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return SingleChildScrollView(
                key: const ValueKey('helm-page-scroll'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 12),
                    NauticalChart(
                      chart: controller.seaChart,
                      ship: controller.ship,
                      takeMotion: controller.takeNavigationMotion,
                      viewportHeight: (constraints.maxHeight * .5).clamp(
                        260,
                        440,
                      ),
                    ),
                    const SizedBox(height: 16),
                    reports,
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _CourseOptionCard extends StatelessWidget {
  const _CourseOptionCard({
    required this.option,
    required this.onSteer,
    this.restriction,
  });

  final CourseOption option;
  final VoidCallback? onSteer;
  final String? restriction;

  @override
  Widget build(BuildContext context) {
    final bearingTitle = switch (option.bearing) {
      NavigationalBearing.larboardTack =>
        'BEARING EAST-NORTHEAST • LARBOARD TACK',
      NavigationalBearing.deadAhead => 'BEARING DUE EAST • DEAD AHEAD',
      NavigationalBearing.starboardTack =>
        'BEARING EAST-SOUTHEAST • STARBOARD TACK',
    };

    final directionIcon = switch (option.bearing) {
      NavigationalBearing.larboardTack => Icons.north_east,
      NavigationalBearing.deadAhead => Icons.east,
      NavigationalBearing.starboardTack => Icons.south_east,
    };

    final accent = option.isNemesis
        ? InkTheme.crimsonAccent
        : InkTheme.goldAccent;
    return ParchmentCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with bearing and tag
          Row(
            children: [
              Icon(directionIcon, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bearingTitle,
                  style: InkTheme.statValue.copyWith(
                    fontSize: 14,
                    color: InkTheme.inkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (option.isIdentified || option.isNemesis)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withAlpha(40),
                  border: Border.all(color: accent),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  option.isNemesis
                      ? 'NEMESIS'
                      : switch (option.destination) {
                          CourseDestination.midpointHaven => 'MIDPOINT HAVEN',
                          CourseDestination.repairRefit => 'REPAIR / REFIT',
                          CourseDestination.specialistMerchant =>
                            'SPECIALIST MERCHANT',
                          CourseDestination.titan => 'REGIONAL TITAN',
                          CourseDestination.ordinary =>
                            option.nodeType.displayName.toUpperCase(),
                        },
                  style: InkTheme.caption.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Lookout's Quote
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: InkTheme.parchmentDark.withAlpha(60),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: InkTheme.inkFaint),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“ ',
                  style: InkTheme.body.copyWith(
                    fontSize: 22,
                    color: accent,
                    height: 0.8,
                  ),
                ),
                Expanded(
                  child: Text(
                    option.lookoutCall,
                    style: InkTheme.body.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Steer Button
          if (restriction != null) ...[
            Text(
              restriction!,
              style: InkTheme.body.copyWith(color: InkTheme.crimsonAccent),
            ),
            const SizedBox(height: 8),
          ],
          Tooltip(
            message: restriction ?? 'Steer ${option.bearing.displayName}',
            child: InkButton(
              compact: true,
              label: restriction != null
                  ? 'HEADING UNAVAILABLE'
                  : 'STEER THIS HEADING',
              isPrimary: option.bearing == NavigationalBearing.deadAhead,
              semanticLabel: 'Steer ship heading ${option.bearing.displayName}',
              semanticHint: restriction,
              onPressed: restriction != null ? null : onSteer,
            ),
          ),
        ],
      ),
    );
  }
}
