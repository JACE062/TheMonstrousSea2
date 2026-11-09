import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';

/// Present approved catalog edits for stored items without mutating their saves.
String currentItemDescription(Item item) => switch (item) {
  Consumable(type: ConsumableType.hullPatchKit) =>
    WeaponLore.consumables[ConsumableType.hullPatchKit]!.description,
  ShipWeapon(weaponType: ShipWeaponType.chainShotBroadside) =>
    WeaponLore.ship[ShipWeaponType.chainShotBroadside]!.description,
  _ => item.description,
};

/// Context belongs to the displayed actor, or the prospective shrine choice.
/// It never mutates the build or reads a future encounter.
class MechanicContext {
  const MechanicContext({
    this.ship,
    this.monster,
    this.blessing,
    this.regionIndex = 0,
    this.utilityMultiplier,
  });
  final ShipState? ship;
  final MonsterState? monster;
  final HardpointBlessing? blessing;
  final int regionIndex;
  final double? utilityMultiplier;

  MechanicContext withBlessing(HardpointBlessing value) => MechanicContext(
    ship: ship,
    monster: monster,
    blessing: value,
    regionIndex: regionIndex,
    utilityMultiplier: utilityMultiplier,
  );

  MechanicContext withMonster(MonsterState value) => MechanicContext(
    ship: ship,
    monster: value,
    blessing: blessing,
    regionIndex: regionIndex,
    utilityMultiplier: utilityMultiplier,
  );

  int get _burningDamage {
    var damage = magmaBurnDamage(tier(OceanPower.magmaVentLord), regionIndex);
    final utility = blessing?.slot == HardpointType.utility
        ? blessing
        : ship?.blessings[HardpointType.utility];
    if (utility?.power == OceanPower.magmaVentLord &&
        utility?.tier == 3 &&
        (blessing == utility || (ship?.boilingWakeTurns ?? 0) > 0)) {
      damage = (damage * 1.5).round();
    }
    return ship != null && monster != null
        ? amplifyMonsterDamage(ship!, monster!, damage)
        : damage;
  }

  int tier(OceanPower power) => math
      .max(
        ship?.highestBlessingTier(power) ?? 0,
        blessing?.power == power ? blessing!.tier : 0,
      )
      .clamp(1, 3);

  int get _shakenPenalty {
    final prospective =
        blessing?.power == OceanPower.earthshakerTitan &&
        blessing?.slot == HardpointType.broadside;
    if (!prospective && (monster?.tremorAccPenalty ?? 0) > 0) {
      return monster!.tremorAccPenalty;
    }
    final broadside = prospective
        ? blessing
        : ship?.blessings[HardpointType.broadside];
    final mark = broadside?.power == OceanPower.earthshakerTitan
        ? broadside!.tier
        : 1;
    return [10, 15, 20][mark - 1];
  }

  String explanation(String term) => switch (term) {
    'Burning' =>
      blessing?.power == OceanPower.magmaVentLord ||
              (monster?.burnTurns ?? 0) > 0
          ? 'Takes $_burningDamage Fire damage per turn. Magma ignition lasts 3 turns.'
          : 'Takes Fire damage when its status effects resolve. Non-Magma fire has a 25% chance to clear after each surviving tick.',
    'Illuminated' =>
      'Clears enemy Obscurity and prevents dodge. Grants +${monster?.isIlluminatedByFlare == true ? monster!.spotterFlareAccuracyBonus : (15 * _flareMultiplier).round()}% shot accuracy and +${monster?.isIlluminatedByFlare == true ? (monster!.spotterFlareBlastBonus * 100).round() : (25 * _flareMultiplier).round()}% Blast damage taken. Lasts 2 turns.',
    'Static Charge' =>
      'At 3 stacks, triggers Arc Discharge and consumes the stacks.',
    'Arc Discharge' =>
      'Deals ${arcDischargeDamage(tier(OceanPower.tempestSovereign))} Shock damage before damage modifiers and clears Frenzy. Interrupts a lethal windup with Stun; otherwise applies Electro-Jolt.',
    'Corroded' =>
      'Each stack increases incoming damage by ${tier(OceanPower.brinemother) == 3 ? 12 : 8}% and reduces attack damage by 5%. Up to 3 stacks; lasts 3 turns and refreshes when reapplied.',
    'Pinned' => 'Prevents movement and halves dodge this turn.',
    'Carapace' => 'Absorbs damage before flesh. Blast deals 1.5× damage to Carapace; Fire bypasses it. Other damage is absorbed point for point unless an attack specifies otherwise.',
    'Critical Hits' => 'Deal 1.5× damage. The listed Critical Hit chance is the chance for an eligible hit to become critical.',
    'Shaken' =>
      'Reduces enemy shot accuracy by $_shakenPenalty% for its next action.',
    'Obscurity' =>
      'Reduces shot accuracy${(monster?.obscurityAccuracyPenalty ?? 0) > 0 ? ' by ${monster!.obscurityAccuracyPenalty}%' : ''}. Successful hits have a 25% chance to clear it, lasts until cleared.',
    'Anchored' => 'Prevents forced movement this round.',
    'Grappled' => 'The ship cannot move this round.',
    'Stun' => 'Prevents the next action and its movement, then clears.',
    'Poison' => 'Deals venom damage when status effects resolve, with a 25% chance to clear after each surviving tick.',
    'Frenzy' => 'Each stack increases the beast’s attack damage by 25%.',
    'Electro-Jolt' => 'Reduces enemy accuracy by 30% and attack damage by 25% for its next action.',
    'Thermal Detonation' => 'An extra Blast hit triggered by the named blessing against Burning targets. It does not consume Burning.',
    _ => '',
  };

  double get _flareMultiplier =>
      utilityMultiplier ??
      (ship?.resolvedBlueprintId == BlueprintId.bombardier
          ? ship!.hardpointMarkMultiplier(HardpointType.utility)
          : 1);
}

class MechanicScope extends InheritedWidget {
  const MechanicScope({super.key, required this.data, required super.child});
  final MechanicContext data;
  static MechanicContext of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MechanicScope>()?.data ??
      const MechanicContext();
  @override
  bool updateShouldNotify(MechanicScope old) => old.data != data;
}

const _terms = <String, String>{
  'Critical Hits': 'Critical Hits',
  'Critical Hit': 'Critical Hits',
  'Static Charge': 'Static Charge',
  'Arc Discharge': 'Arc Discharge',
  'Thermal Detonation': 'Thermal Detonation',
  'Electro-Jolt': 'Electro-Jolt',
  'Illuminated': 'Illuminated',
  'Illuminates': 'Illuminated',
  'Burning': 'Burning',
  'Ignites': 'Burning',
  'Ignite': 'Burning',
  'Corroded': 'Corroded',
  'Pinned': 'Pinned',
  'Pins': 'Pinned',
  'Pin': 'Pinned',
  'Carapace': 'Carapace',
  'Shaken': 'Shaken',
  'Obscurity': 'Obscurity',
  'Anchored': 'Anchored',
  'Anchors': 'Anchored',
  'Grappled': 'Grappled',
  'Stun': 'Stun',
  'Stuns': 'Stun',
  'Poison': 'Poison',
  'Frenzy': 'Frenzy',
};
final _pattern = RegExp(
  '\\b(${(_terms.keys.toList()..sort((a, b) => b.length.compareTo(a.length))).map(RegExp.escape).join('|')})\\b',
  caseSensitive: false,
);

/// Bold ink keywords open an adjacent explanation by hover, activation or touch.
class MechanicText extends StatelessWidget {
  const MechanicText(this.text, {super.key, this.style, this.mechanics});
  final String text;
  final TextStyle? style;
  final MechanicContext? mechanics;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? InkTheme.body;
    final data = mechanics ?? MechanicScope.of(context);
    final excluded = _HelpOwner.maybeOf(context)?.terms ?? <String>{};
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in _pattern.allMatches(text)) {
      if (match.start > offset) {
        spans.add(TextSpan(text: text.substring(offset, match.start)));
      }
      final label = match.group(0)!;
      final term = _terms.entries
          .firstWhere((e) => e.key.toLowerCase() == label.toLowerCase())
          .value;
      if (excluded.contains(term)) {
        spans.add(TextSpan(text: label));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _HelpAnchor(
              title: term,
              term: term,
              help: () => data.explanation(term),
              mechanics: data,
              isWord: true,
              child: Text(
                label,
                style: resolved.copyWith(
                  fontWeight: FontWeight.bold,
                  color: InkTheme.crimsonAccent,
                ),
              ),
            ),
          ),
        );
      }
      offset = match.end;
    }
    if (offset < text.length) spans.add(TextSpan(text: text.substring(offset)));
    return Text.rich(TextSpan(children: spans), style: resolved);
  }
}

/// Action help also supports linked terms, without intercepting the action tap.
class MechanicTooltip extends StatelessWidget {
  const MechanicTooltip({
    super.key,
    required this.message,
    required this.child,
    this.mechanics,
  });
  final String message;
  final Widget child;
  final MechanicContext? mechanics;
  @override
  Widget build(BuildContext context) => _HelpAnchor(
    title: 'Action details',
    help: () => message,
    mechanics: mechanics ?? MechanicScope.of(context),
    child: child,
  );
}

class _HelpOwner extends InheritedWidget {
  const _HelpOwner({
    required this.owner,
    required this.terms,
    required super.child,
  });
  final _HelpAnchorState owner;
  final Set<String> terms;
  static _HelpOwner? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HelpOwner>();
  @override
  bool updateShouldNotify(_HelpOwner old) => old.terms != terms;
}

class _HelpAnchor extends StatefulWidget {
  const _HelpAnchor({
    required this.title,
    required this.help,
    required this.child,
    required this.mechanics,
    this.term,
    this.isWord = false,
  });
  final String title;
  final String Function() help;
  final Widget child;
  final MechanicContext mechanics;
  final String? term;
  final bool isWord;
  @override
  State<_HelpAnchor> createState() => _HelpAnchorState();
}

class _HelpAnchorState extends State<_HelpAnchor> {
  final _portal = OverlayPortalController();
  final _key = GlobalKey();
  final _helpKey = GlobalKey();
  final _focus = FocusNode();
  Timer? _closing;
  _HelpAnchorState? _parent;
  bool _overAnchor = false, _overHelp = false, _helpFocused = false;
  bool _keyboard = false;
  int _children = 0;
  bool _disposed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parent = _HelpOwner.maybeOf(context)?.owner;
  }

  void _open({bool keyboard = false}) {
    _closing?.cancel();
    if (_portal.isShowing) return;
    _keyboard = keyboard;
    _parent?._childOpened();
    _portal.show();
  }

  void _childOpened() {
    _children++;
    _closing?.cancel();
  }

  void _childClosed() {
    if (_disposed) return;
    _children--;
    _scheduleClose();
  }

  void _close({bool restoreFocus = true}) {
    _closing?.cancel();
    if (!_portal.isShowing) return;
    _portal.hide();
    _parent?._childClosed();
    if (restoreFocus && _keyboard && mounted && widget.isWord) {
      _focus.requestFocus();
    }
  }

  void _scheduleClose() {
    if (_disposed) return;
    _closing?.cancel();
    _closing = Timer(const Duration(milliseconds: 250), () {
      if (mounted &&
          !_overAnchor &&
          !_overHelp &&
          !_helpFocused &&
          _children == 0) {
        _close(restoreFocus: false);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _closing?.cancel();
    if (_portal.isShowing) _parent?._childClosed();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inherited = _HelpOwner.maybeOf(context)?.terms ?? <String>{};
    Widget target = widget.child;
    if (widget.isWord) {
      target = Semantics(
        label: '${widget.title}. Show explanation',
        button: true,
        excludeSemantics: true,
        onTap: () => _portal.isShowing ? _close() : _open(keyboard: true),
        child: InkWell(
          excludeFromSemantics: true,
          focusNode: _focus,
          onTap: () => _portal.isShowing ? _close() : _open(keyboard: true),
          child: widget.child,
        ),
      );
    }
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        final box = _key.currentContext!.findRenderObject()! as RenderBox;
        final overlay =
            Overlay.of(context).context.findRenderObject()! as RenderBox;
        final rect =
            box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
        final parentBox = _parent?._helpKey.currentContext?.findRenderObject();
        final parentRect = parentBox is RenderBox
            ? parentBox.localToGlobal(Offset.zero, ancestor: overlay) &
                  parentBox.size
            : null;
        return CustomSingleChildLayout(
          delegate: _HelpPosition(rect, parentRect: parentRect),
          child: _HelpOwner(
            owner: this,
            terms: {...inherited, if (widget.term != null) widget.term!},
            child: TapRegion(
              groupId: this,
              onTapOutside: (_) {
                if (_children == 0) _close(restoreFocus: false);
              },
              child: MouseRegion(
                onEnter: (_) {
                  _overHelp = true;
                  _closing?.cancel();
                },
                onExit: (_) {
                  _overHelp = false;
                  _scheduleClose();
                },
                child: FocusScope(
                  onFocusChange: (v) {
                    _helpFocused = v;
                    if (!v) _scheduleClose();
                  },
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.escape): _close,
                    },
                    child: Container(
                      key: _helpKey,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: InkTheme.parchmentSurface,
                        border: Border.all(color: InkTheme.inkMuted),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: InkTheme.inkPrimary.withValues(alpha: .2),
                            blurRadius: 5,
                            offset: const Offset(2, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        key: ValueKey(
                          'mechanic-help-${widget.term ?? 'action'}',
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: InkTheme.statLabel,
                                  ),
                                ),
                                IconButton(
                                  autofocus: _keyboard,
                                  tooltip: 'Close explanation',
                                  onPressed: _close,
                                  icon: const Icon(Icons.close, size: 18),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            MechanicText(
                              widget.help(),
                              mechanics: widget.mechanics,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: TapRegion(
        groupId: this,
        child: MouseRegion(
          key: _key,
          onEnter: (_) {
            _overAnchor = true;
            _open();
          },
          onExit: (_) {
            _overAnchor = false;
            _scheduleClose();
          },
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.f1) {
                _open(keyboard: true);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onLongPress: () => _open(keyboard: true),
              child: target,
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpPosition extends SingleChildLayoutDelegate {
  _HelpPosition(this.anchor, {this.parentRect});
  final Rect anchor;
  final Rect? parentRect;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.min(340, math.max(0, constraints.maxWidth - 24)),
        maxHeight: math.max(0, constraints.maxHeight - 24),
      );
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Keep the previous explanation readable when a nested card fits beside it.
    final parent = parentRect;
    final besideParent =
        parent != null &&
        (parent.right + 8 + childSize.width <= size.width - 12 ||
            parent.left - childSize.width - 8 >= 12);
    final origin = besideParent ? parent : anchor;
    final right = origin.right + 8;
    final left = origin.left - childSize.width - 8;
    final sideFits = right + childSize.width <= size.width - 12 || left >= 12;
    final x = right + childSize.width <= size.width - 12
        ? right
        : left >= 12
        ? left
        : 12.0;
    return Offset(
      x.clamp(12, math.max(12, size.width - childSize.width - 12)),
      (sideFits ? origin.top : origin.bottom + 8).clamp(
        12,
        math.max(12, size.height - childSize.height - 12),
      ),
    );
  }

  @override
  bool shouldRelayout(_HelpPosition old) =>
      old.anchor != anchor || old.parentRect != parentRect;
}
