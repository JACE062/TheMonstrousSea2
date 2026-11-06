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
import '../widgets/pilot_art.dart';
import '../widgets/svg_asset_view.dart';

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
            padding: const EdgeInsets.only(bottom: 10),
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
    final hullFraction = ship == null || ship.maxHp == 0
        ? 1.0
        : ship.currentHp / ship.maxHp;
    final hullColor = hullFraction < .25
        ? InkTheme.crimsonAccent
        : hullFraction < .5
        ? InkTheme.goldAccent
        : InkTheme.verdigrisGreen;
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
    final status = Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        if (ship != null) ...[
          _HelmStatusBadge(
            label: 'HULL',
            value: '${ship.currentHp}/${ship.maxHp}',
            color: hullColor,
            icon: Icons.shield_outlined,
          ),
          _HelmStatusBadge(
            label: 'PURSE',
            value: '${ship.gold}g',
            color: InkTheme.goldAccent,
            icon: Icons.toll,
          ),
        ],
      ],
    );
    final log = InkButton(
      key: const ValueKey('helm-voyage-log'),
      label: 'VOYAGE LOG',
      compact: true,
      icon: const Icon(Icons.menu_book, size: 21, color: InkTheme.inkMuted),
      onPressed: openLog,
    );
    final inspection = InkButton(
      key: const ValueKey('helm-inspect-vessel'),
      label: 'INSPECT VESSEL',
      compact: true,
      isPrimary: true,
      icon: const SvgAssetView(
        assetPath: PilotArt.standard,
        width: 30,
        height: 26,
      ),
      onPressed: inspect,
    );
    final tools = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              status,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: log),
                  const SizedBox(width: 10),
                  Expanded(child: inspection),
                ],
              ),
            ],
          )
        : Wrap(
            spacing: 12,
            runSpacing: 8,
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
              Expanded(flex: 4, child: title),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
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
      final options = List<CourseOption>.of(controller.currentCourseOptions);
      final restrictions = {
        for (final option in options)
          option.bearing: controller.session.courseRestriction(option.bearing),
      };
      final extraHeight =
          (controller.canEmergencyRepairAtSea ? 260.0 : 0.0) +
          (controller.activeBoon?.id == BloodlineTraitId.stormSeer
              ? 340.0
              : 0.0);
      return _lastHelmView = ParchmentScaffold(
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final panelWidth = nauticalCoursePanelWidth(
                      constraints.maxWidth,
                    );
                    final reportsHeight =
                        32 +
                        extraHeight +
                        options.fold(
                          0.0,
                          (height, option) =>
                              height +
                              _CourseOptionCard.estimatedHeight(
                                context,
                                option,
                                panelWidth,
                                restriction: restrictions[option.bearing],
                              ) +
                              10,
                        );
                    final overlay =
                        constraints.maxWidth >= 1000 &&
                        reportsHeight <= constraints.maxHeight - 76;
                    if (overlay) {
                      return NauticalChart(
                        chart: controller.seaChart,
                        ship: controller.ship,
                        takeMotion: controller.takeNavigationMotion,
                        expandViewport: true,
                        coursePanelWidth: panelWidth,
                        coursePanel: reports,
                      );
                    }
                    // Large text and short windows use one ordinary page scroll. Never
                    // clip a bearing or introduce a second scrolling lookout panel.
                    return SingleChildScrollView(
                      key: const ValueKey('helm-page-scroll'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          NauticalChart(
                            chart: controller.seaChart,
                            ship: controller.ship,
                            takeMotion: controller.takeNavigationMotion,
                            viewportHeight: (constraints.maxHeight * .58).clamp(
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
            ],
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

  static String heading(CourseOption option) => switch (option.bearing) {
    NavigationalBearing.larboardTack => 'LARBOARD TACK',
    NavigationalBearing.deadAhead => 'DEAD AHEAD',
    NavigationalBearing.starboardTack => 'STARBOARD TACK',
  };
  static TextStyle get quoteStyle =>
      InkTheme.body.copyWith(fontStyle: FontStyle.italic, height: 1.35);
  static TextStyle get headingStyle =>
      InkTheme.statValue.copyWith(fontSize: 16);

  // A conservative text measurement selects the non-scrolling desktop overlay.
  // The rendered controls are checked for visibility at real fonts/text scales.
  static double estimatedHeight(
    BuildContext context,
    CourseOption option,
    double width, {
    String? restriction,
  }) {
    Size measure(String text, TextStyle style, double available) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: available);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final available = width - 24;
    final headingHeight = measure(
      heading(option),
      headingStyle,
      width - 60,
    ).height.clamp(24.0, double.infinity);
    final button = measure(
      restriction == null ? 'STEER THIS HEADING' : 'HEADING UNAVAILABLE',
      InkTheme.titleMedium.copyWith(fontSize: 16),
      available - 16,
    );
    final buttonHeight = (button.height + 8).clamp(36.0, double.infinity);
    final tagSize = measure(
      tagLabel(option),
      InkTheme.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
      available - 12,
    );
    final tagHeight = tagSize.height + 6;
    final wraps =
        (option.isIdentified || option.isNemesis) &&
        tagSize.width + 12 + button.width + 16 + 12 > available;
    final footer = wraps
        ? tagHeight + 8 + buttonHeight
        : buttonHeight.clamp(tagHeight, double.infinity);
    return 28 +
        headingHeight +
        8 +
        measure(option.displayLookoutCall, quoteStyle, available).height +
        (restriction == null
            ? 0
            : measure(restriction, InkTheme.body, available).height + 8) +
        8 +
        footer;
  }

  static String tagLabel(CourseOption option) => option.isNemesis
      ? 'NEMESIS'
      : switch (option.destination) {
          CourseDestination.midpointHaven => 'MIDPOINT HAVEN',
          CourseDestination.repairRefit => 'REPAIR / REFIT',
          CourseDestination.specialistMerchant => 'SPECIALIST MERCHANT',
          CourseDestination.titan => 'REGIONAL TITAN',
          CourseDestination.ordinary =>
            option.nodeType.displayName.toUpperCase(),
        };

  @override
  Widget build(BuildContext context) {
    final accent = option.isNemesis
        ? InkTheme.crimsonAccent
        : InkTheme.goldAccent;
    final directionIcon = switch (option.bearing) {
      NavigationalBearing.larboardTack => Icons.north_east,
      NavigationalBearing.deadAhead => Icons.east,
      NavigationalBearing.starboardTack => Icons.south_east,
    };
    final tag = tagLabel(option);
    return ParchmentCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(directionIcon, color: accent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: option.bearing.displayName,
                  child: Text(heading(option), style: headingStyle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(option.displayLookoutCall, style: quoteStyle),
          if (restriction != null) ...[
            const SizedBox(height: 8),
            Text(
              restriction!,
              style: InkTheme.body.copyWith(color: InkTheme.crimsonAccent),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            alignment: option.isIdentified || option.isNemesis
                ? WrapAlignment.spaceBetween
                : WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (option.isIdentified || option.isNemesis)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(30),
                    border: Border.all(color: accent),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    tag,
                    style: InkTheme.caption.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              Tooltip(
                message: restriction ?? 'Steer ${option.bearing.displayName}',
                child: InkButton(
                  compact: true,
                  label: restriction != null
                      ? 'HEADING UNAVAILABLE'
                      : 'STEER THIS HEADING',
                  isPrimary: option.bearing == NavigationalBearing.deadAhead,
                  semanticLabel:
                      'Steer ship heading ${option.bearing.displayName}',
                  semanticHint: restriction,
                  onPressed: restriction != null ? null : onSteer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelmStatusBadge extends StatelessWidget {
  const _HelmStatusBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label, value;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: InkTheme.parchmentSurface,
      border: Border.all(color: color.withValues(alpha: .7)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: InkTheme.statLabel.copyWith(fontSize: 12)),
            Text(
              value,
              style: InkTheme.statValue.copyWith(fontSize: 18, color: color),
            ),
          ],
        ),
      ],
    ),
  );
}
