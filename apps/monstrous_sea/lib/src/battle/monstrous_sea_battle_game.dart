import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../theme/ink_theme.dart';
import '../widgets/pilot_art.dart';
import 'battle_presentation.dart';

/// Inspectable rendered feedback for timed playback checks and captures.
abstract interface class BattleFeedback {
  String get text;
  double get opacity;
  Rect get bounds;
}

/// 2D naval combat scene driven by Flame, providing animated rolling swells,
/// combatant bobbing, cannon smoke, damage numbers, and ink cloud overlays.
class MonstrousSeaBattleGame extends FlameGame {
  MonstrousSeaBattleGame({
    required ShipState ship,
    required MonsterState monster,
    CombatRange initialRange = CombatRange.medium,
    Future<void> Function(Duration)? playbackDelay,
    AssetBundle? assetBundle,
  }) : presentation = BattlePresentation(ship, monster, initialRange),
       _playbackDelay = playbackDelay ?? Future<void>.delayed {
    // A local cache owns the scene's full asset paths and decoded images.
    images = Images(prefix: '', bundle: assetBundle ?? rootBundle);
  }

  final BattlePresentation presentation;
  ShipState get ship => presentation.ship;
  MonsterState get monster => presentation.monster;
  final Future<void> Function(Duration) _playbackDelay;
  bool reducedMotion = false;
  double _feedbackTextScale = 1.15;
  double get feedbackTextScale => _feedbackTextScale;
  set feedbackTextScale(double value) {
    if (value == _feedbackTextScale) return;
    _feedbackTextScale = value;
    if (_combatantsReady) _layoutCombatants();
  }

  String? _feedbackFontFamily;
  String? get feedbackFontFamily => _feedbackFontFamily;
  set feedbackFontFamily(String? value) {
    if (value == _feedbackFontFamily) return;
    _feedbackFontFamily = value;
    if (_combatantsReady) _layoutCombatants();
  }

  bool _barragePlayback = false;
  int _barrageStrike = 0;
  Duration _readingHold = Duration.zero;
  final Map<CombatSide, List<_FeedbackComponent>> _feedback = {};
  final ValueNotifier<int> artworkRevision = ValueNotifier(0);
  final Set<String> _unavailableArtwork = {};
  bool isRetryingArtwork = false;
  bool _removed = false;
  bool get isShipArtUnavailable =>
      _unavailableArtwork.contains(PilotArt.forShip(ship));
  bool get isMonsterArtUnavailable =>
      _unavailableArtwork.contains(PilotArt.forMonster(monster));

  late _RollingWavesComponent _waves;
  late _ShipBattleComponent _shipVisual;
  late _MonsterBattleComponent _monsterVisual;
  _InkCloudOverlayComponent? _inkOverlay;
  bool _combatantsReady = false;
  double _arenaTopInset = 140;
  double _arenaBottomInset = 160;

  @override
  Color backgroundColor() => InkTheme.parchmentBackground;

  @override
  void onRemove() {
    _removed = true;
    for (final label in _feedback.values.expand((labels) => labels).toList()) {
      label.dismiss();
    }
    _feedback.clear();
    presentation.dispose();
    artworkRevision.dispose();
    if (_combatantsReady) {
      _shipVisual.pictureInfo?.picture.dispose();
      _monsterVisual.pictureInfo?.picture.dispose();
    }
    images.clearCache();
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Rolling oceanic waves
    _waves = _RollingWavesComponent();
    add(_waves);

    final shipPath = PilotArt.forShip(ship);
    final monsterPath = PilotArt.forMonster(monster);

    final (shipSprite, shipPicture) = await _loadArtwork(shipPath);
    final (monsterSprite, monsterPicture) = await _loadArtwork(monsterPath);
    if (_removed) {
      shipPicture?.picture.dispose();
      monsterPicture?.picture.dispose();
      images.clearCache();
      return;
    }

    // Ship on left side
    _shipVisual = _ShipBattleComponent(
      ship: ship,
      sprite: shipSprite,
      pictureInfo: shipPicture,
    );
    add(_shipVisual);

    // Monster on right side
    _monsterVisual = _MonsterBattleComponent(
      monster: monster,
      sprite: monsterSprite,
      pictureInfo: monsterPicture,
    );
    add(_monsterVisual);
    _combatantsReady = true;
    _layoutCombatants();
    if (!_removed) artworkRevision.value++;
  }

  Future<(Sprite?, PictureInfo?)> _loadArtwork(String path) async {
    try {
      Sprite? sprite;
      PictureInfo? picture;
      if (path.toLowerCase().endsWith('.svg')) {
        picture = await vg.loadPicture(SvgAssetLoader(path), null);
      } else if (images.containsKey(path)) {
        sprite = Sprite(await images.load(path));
      } else {
        // Flame 1.38's failed-load cache forks an unhandled error future even
        // when its caller catches the original. Decode first; cache successes
        // only, so a missing illustration is recoverable rather than fatal.
        final data = await images.bundle.load(path);
        final decoded = await decodeImageFromList(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        if (_removed) {
          decoded.dispose();
          return (null, null);
        }
        images.add(path, decoded);
        sprite = Sprite(decoded);
      }
      if (_removed) {
        picture?.picture.dispose();
        images.clearCache();
        return (null, null);
      }
      _unavailableArtwork.remove(path);
      return (sprite, picture);
    } catch (error) {
      _unavailableArtwork.add(path);
      debugPrint('Battle illustration unavailable ($path): $error');
      return (null, null);
    }
  }

  /// Illustration failure must not prevent the combat scene/event queue loading.
  /// Only failed assets are retried; successfully decoded images stay cached.
  Future<void> retryArtwork() async {
    if (_removed || !_combatantsReady || isRetryingArtwork) return;
    isRetryingArtwork = true;
    artworkRevision.value++;
    try {
      for (final path in List<String>.of(_unavailableArtwork)) {
        images.clear(path);
        images.bundle.evict(path);
        final (sprite, picture) = await _loadArtwork(path);
        if (_removed) {
          picture?.picture.dispose();
          images.clear(path);
          continue;
        }
        if (path == PilotArt.forShip(ship)) {
          _shipVisual.sprite = sprite;
          _shipVisual.pictureInfo = picture;
        } else {
          _monsterVisual.sprite = sprite;
          _monsterVisual.pictureInfo = picture;
        }
      }
    } finally {
      if (!_removed) {
        isRetryingArtwork = false;
        _layoutCombatants();
        artworkRevision.value++;
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_combatantsReady) _layoutCombatants();
  }

  void _layoutCombatants() {
    if (!_combatantsReady || size.x <= 0 || size.y <= 0) return;
    final arenaHeight = max(40.0, size.y - _arenaTopInset - _arenaBottomInset);
    // Stable room for local feedback keeps arriving labels clear of the HUD.
    final feedbackRoom = min(
      160 * feedbackTextScale,
      max(0, arenaHeight - 180),
    );
    final artHeight = max(24.0, arenaHeight - feedbackRoom);
    final centreY = _arenaTopInset + feedbackRoom + artHeight / 2;

    // Anchor combatants symmetrically around center with clamped spread
    final centerX = size.x / 2;
    const maxHalfSpread = 320.0;
    final halfSpread = min(
      size.x * 0.25,
      maxHalfSpread,
    ).clamp(110.0, maxHalfSpread);
    _shipVisual.position = Vector2(centerX - halfSpread, centreY);
    _monsterVisual.position = Vector2(centerX + halfSpread, centreY);

    final shipAspect = _shipVisual.sprite != null
        ? _shipVisual.sprite!.srcSize.x / _shipVisual.sprite!.srcSize.y
        : _shipVisual.pictureInfo != null
        ? _shipVisual.pictureInfo!.size.width /
              _shipVisual.pictureInfo!.size.height
        : 1.25;
    // Sensible ship sizing capped at 220px and arenaHeight to prevent vertical overflow
    final maxShipWidth = min(
      size.x * 0.32,
      min(220.0, artHeight * 0.85 * shipAspect),
    );
    final shipWidth = max(40.0, maxShipWidth);
    _shipVisual.size = Vector2(shipWidth, shipWidth / shipAspect);

    final isBoss = PilotArt.isKraken(monster);
    final monsterAspect = _monsterVisual.sprite != null
        ? _monsterVisual.sprite!.srcSize.x / _monsterVisual.sprite!.srcSize.y
        : _monsterVisual.pictureInfo != null
        ? _monsterVisual.pictureInfo!.size.width /
              _monsterVisual.pictureInfo!.size.height
        : 1.0;
    // Sensible monster sizing capped at 200px (regular) / 280px (boss) and arenaHeight
    final maxMonsterWidth = min(
      size.x * (isBoss ? 0.38 : 0.28),
      min(
        isBoss ? 280.0 : 200.0,
        artHeight * (isBoss ? 0.92 : 0.68) * monsterAspect,
      ),
    );
    final monsterWidth = max(40.0, maxMonsterWidth);
    _monsterVisual.size = Vector2(monsterWidth, monsterWidth / monsterAspect);
    if (_inkOverlay != null) {
      _inkOverlay!.position = _monsterVisual.position;
    }
    _layoutFeedback();
  }

  void _layoutFeedback() {
    for (final entry in _feedback.entries) {
      final visual = entry.key == CombatSide.ship
          ? _shipVisual
          : _monsterVisual;
      final labels = entry.value;
      for (final label in labels) {
        label.measure(
          feedbackTextScale,
          feedbackFontFamily,
          min(300, size.x * 0.43) - 14,
        );
      }
      final top = _arenaTopInset + 4;
      final bottom = max(top, visual.position.y - visual.size.y / 2 - 10);
      double stackHeight() =>
          labels.fold<double>(0, (sum, label) => sum + label.height + 6) - 6;
      // Narrow arenas can retain fewer than three large, wrapped cues.
      while (labels.length > 1 && stackHeight() > bottom - top) {
        final oldest = labels.removeAt(0);
        oldest.dismiss();
      }
      var y = max(top, bottom - max(0, stackHeight()));
      for (final label in labels) {
        label.position.setValues(
          visual.position.x.clamp(
            label.width / 2 + 4,
            max(label.width / 2 + 4, size.x - label.width / 2 - 4),
          ),
          y,
        );
        y += label.height + 6;
      }
    }
  }

  /// Keep complete sprites inside the space left by the current HUD and dock.
  void setArenaInsets({required double top, required double bottom}) {
    if (top == _arenaTopInset && bottom == _arenaBottomInset) return;
    _arenaTopInset = top;
    _arenaBottomInset = bottom;
    if (_combatantsReady) _layoutCombatants();
  }

  /// Triggers visual playback for domain [events].
  Future<void> playEvents(
    List<GameEvent> events,
    VoidCallback onComplete,
  ) async {
    await loaded;
    if (_removed) return;
    _layoutCombatants();
    _barragePlayback = false;
    _barrageStrike = 0;
    _readingHold = Duration.zero;
    final monsterStrikes = events
        .whereType<AttackAttempted>()
        .where((event) => event.attacker == CombatSide.monster)
        .length;
    var monsterStrike = 0;
    CombatSide? attackSource;

    for (final event in events) {
      if (_removed) return;
      if (event is AttackAttempted) {
        attackSource =
            event.attacker ??
            (event.attackerName == ship.name
                ? CombatSide.ship
                : CombatSide.monster);
      }
      final isIncomingImpact =
          event is DamageReduced ||
          (event is AttackHit &&
              presentation.targetFor(event.target, event.targetName) ==
                  CombatSide.ship);
      if (isIncomingImpact && attackSource != CombatSide.monster) {
        // Guaranteed releases have no accuracy attempt event. Their already
        // displayed intent identifies the source before defenses/hull resolve.
        _showFeedback(
          _FloatingTextComponent(
            text: monster.currentIntent?.name ?? 'Monster strike',
            position: _monsterVisual.position,
          ),
        );
        attackSource = CombatSide.monster;
        await _wait(const Duration(milliseconds: 100), honorReadingHold: false);
        if (_removed) return;
      }
      final previousCarapace = monster.carapacePlating;
      final before = event is CombatEffectsChanged
          ? BattlePresentation.effectReadouts(
              presentation.combatant(event.target),
            )
          : const <String, String>{};
      presentation.apply(event);
      switch (event) {
        case AttackAttempted(
          :final attacker,
          :final attackerName,
          :final weaponName,
        ):
          final side =
              attacker ??
              (attackerName == ship.name
                  ? CombatSide.ship
                  : CombatSide.monster);
          final pos = side == CombatSide.ship
              ? _shipVisual.position
              : _monsterVisual.position;
          if (side == CombatSide.monster && monsterStrikes > 1) {
            _barragePlayback = true;
            monsterStrike++;
            _barrageStrike = monsterStrike;
          }
          _showFeedback(
            _FloatingTextComponent(
              text: side == CombatSide.monster && monsterStrikes > 1
                  ? '$weaponName · $monsterStrike/$monsterStrikes'
                  : weaponName,
              position: pos - Vector2(0, 65),
              reducedMotion: reducedMotion,
            ),
          );
          await _wait(
            Duration(milliseconds: _barragePlayback ? 180 : 100),
            honorReadingHold: _barragePlayback,
          );

        case AttackHit(
          :final target,
          :final targetName,
          :final damage,
          :final source,
        ):
          final isMonster =
              presentation.targetFor(target, targetName) == CombatSide.monster;
          final pos = isMonster
              ? _monsterVisual.position
              : _shipVisual.position;
          if (source != null) {
            _showFeedback(
              _FloatingTextComponent(
                text: damage > 0 ? '$source −$damage' : '$source · ABSORBED',
                color: damage > 0
                    ? InkTheme.crimsonAccent
                    : InkTheme.goldAccent,
                position: pos,
              ),
            );
          } else if (damage > 0) {
            _showFeedback(
              _DamageNumberComponent(
                damage: damage,
                position: pos - Vector2(0, 40),
                reducedMotion: reducedMotion,
              ),
            );
          }
          if (damage > 0) _triggerScreenShake();
          await _wait(const Duration(milliseconds: 320));

        case AttackMissed(:final target, :final targetName):
          final isMonster =
              presentation.targetFor(target, targetName) == CombatSide.monster;
          final pos = isMonster
              ? _monsterVisual.position
              : _shipVisual.position;
          _showFeedback(
            _FloatingTextComponent(
              text: 'MISS',
              position: pos - Vector2(0, 40),
            ),
          );
          await _wait(const Duration(milliseconds: 260));

        case AttackEvaded(:final target, :final shipName):
          _showFeedback(
            _FloatingTextComponent(
              text: 'DODGED!',
              color: InkTheme.verdigrisGreen,
              position:
                  (presentation.targetFor(target, shipName) == CombatSide.ship
                      ? _shipVisual.position
                      : _monsterVisual.position) -
                  Vector2(0, 40),
            ),
          );
          await _wait(const Duration(milliseconds: 260));

        case DamageReduced(:final nullifiedAmount, :final defense):
          _showFeedback(
            _FloatingTextComponent(
              text:
                  '${defense == DefenseKind.barrier ? 'BARRIER' : 'DEFENSE'} $nullifiedAmount',
              color: InkTheme.goldAccent,
              position: _shipVisual.position - Vector2(0, 40),
            ),
          );
          _shipVisual.flashFortify();
          await _wait(const Duration(milliseconds: 260));

        case CarapaceDamaged(:final damageDealt, :final wasShattered):
          _showFeedback(
            _FloatingTextComponent(
              text: 'SHELL −$damageDealt${wasShattered ? ' · BROKEN' : ''}',
              color: InkTheme.goldAccent,
              position: _monsterVisual.position - Vector2(0, 40),
              reducedMotion: reducedMotion,
            ),
          );
          await _wait(const Duration(milliseconds: 260));

        case CarapaceRestored(:final restoredAmount):
          if (restoredAmount == 0) break;
          _showFeedback(
            _FloatingTextComponent(
              text: 'SHELL +$restoredAmount',
              color: InkTheme.goldAccent,
              position: _monsterVisual.position - Vector2(0, 40),
              reducedMotion: reducedMotion,
            ),
          );
          await _wait(const Duration(milliseconds: 260));

        case CarapaceAbsorbed(:final absorbedAmount):
          if (monster.carapacePlating != previousCarapace) {
            _showFeedback(
              _FloatingTextComponent(
                text: 'SHELL ABSORBED $absorbedAmount',
                color: InkTheme.goldAccent,
                position: _monsterVisual.position - Vector2(0, 40),
              ),
            );
            await _wait(const Duration(milliseconds: 260));
          }

        case CombatHealthChanged(
          :final target,
          :final amount,
          :final source,
          :final isHealing,
        ):
          if (amount > 0) {
            _showFeedback(
              _FloatingTextComponent(
                text: '$source ${isHealing ? '+' : '−'}$amount',
                color: isHealing
                    ? InkTheme.verdigrisGreen
                    : InkTheme.crimsonAccent,
                position:
                    (target == CombatSide.ship
                        ? _shipVisual.position
                        : _monsterVisual.position) -
                    Vector2(0, 40),
                reducedMotion: reducedMotion,
              ),
            );
            await _wait(const Duration(milliseconds: 320));
          }

        case StatusEffectTicked(
          :final target,
          :final targetName,
          :final effectName,
          :final damage,
          :final woreOff,
        ):
          _showFeedback(
            _FloatingTextComponent(
              text:
                  (damage > 0
                      ? '$effectName −$damage'
                      : '$effectName · ACTION LOST') +
                  (woreOff ? ' · CLEARED' : ''),
              color: InkTheme.crimsonAccent,
              position:
                  (presentation.targetFor(target, targetName) == CombatSide.ship
                      ? _shipVisual.position
                      : _monsterVisual.position) -
                  Vector2(0, 40),
              reducedMotion: reducedMotion,
            ),
          );
          await _wait(const Duration(milliseconds: 320));

        case CombatEffectsChanged(:final target):
          final after = BattlePresentation.effectReadouts(
            presentation.combatant(target),
          );
          final changes = [
            for (final entry in after.entries)
              if (before[entry.key] != entry.value) entry.value,
            for (final key in before.keys)
              if (!after.containsKey(key)) '$key CLEARED',
          ];
          final pos = target == CombatSide.ship
              ? _shipVisual.position
              : _monsterVisual.position;
          if (changes.isNotEmpty) {
            _showFeedback(
              _FloatingTextComponent(
                text: changes.join(' · '),
                color: InkTheme.goldAccent,
                position: pos - Vector2(0, 60),
                reducedMotion: reducedMotion,
              ),
            );
          }
          if (!monster.isObscured && _inkOverlay != null) {
            _inkOverlay!.removeFromParent();
            _inkOverlay = null;
          }
          if (changes.isNotEmpty) {
            await _wait(Duration(milliseconds: 280 + 100 * changes.length));
          }

        case ThermalScaldOccurred(:final damage):
          _showFeedback(
            _FloatingTextComponent(
              text: 'SCALD −$damage',
              color: InkTheme.crimsonAccent,
              position: _shipVisual.position - Vector2(0, 40),
              reducedMotion: reducedMotion,
            ),
          );
          await _wait(const Duration(milliseconds: 320));

        case TentaclesSevered(:final remainingTentacles):
          _monsterVisual.updateTentacles(remainingTentacles);
          _showFeedback(
            _FloatingTextComponent(
              text: 'TENTACLE SEVERED!',
              color: InkTheme.crimsonAccent,
              position: _monsterVisual.position - Vector2(0, 60),
            ),
          );
          await _wait(const Duration(milliseconds: 300));

        case InkCloudDeployed():
          _showFeedback(
            _FloatingTextComponent(
              text: 'OBSCURED',
              position: _monsterVisual.position,
            ),
          );
          if (_inkOverlay == null) {
            _inkOverlay = _InkCloudOverlayComponent(
              position: _monsterVisual.position,
            );
            add(_inkOverlay!);
          }
          await _wait(const Duration(milliseconds: 300));

        case MonsterIntentTelegraphed(:final intent)
            when intent.isBossCatastropheStrike:
          _showFeedback(
            _FloatingTextComponent(
              text: 'WINDUP COMPLETE · RELEASE READY',
              color: InkTheme.crimsonAccent,
              position: _monsterVisual.position,
            ),
          );
          await _wait(const Duration(milliseconds: 400));

        case SharkFrenzyRoared(:final stacks):
          _showFeedback(
            _FloatingTextComponent(
              text: 'FRENZY ×$stacks',
              color: InkTheme.crimsonAccent,
              position: _monsterVisual.position,
            ),
          );
          await _wait(const Duration(milliseconds: 300));

        case MonsterHesitated():
          _showFeedback(
            _FloatingTextComponent(
              text: 'NO STRIKE',
              position: _monsterVisual.position,
            ),
          );
          await _wait(const Duration(milliseconds: 260));

        case CombatRangeChanged():
          final cue = BattlePresentation.rangeCue(event);
          if (cue.anchor == null) {
            presentation.announce('Engagement: ${cue.text}');
            break;
          }
          _showFeedback(
            _FloatingTextComponent(
              text: cue.text,
              color: InkTheme.goldAccent,
              position: cue.anchor == CombatSide.ship
                  ? _shipVisual.position
                  : _monsterVisual.position,
            ),
          );
          await _wait(const Duration(milliseconds: 260));

        case MortarBackfireOccurred(:final damage):
          _showFeedback(
            _FloatingTextComponent(
              text: 'BACKFIRE! -$damage',
              color: InkTheme.crimsonAccent,
              position: _shipVisual.position - Vector2(0, 40),
            ),
          );
          _triggerScreenShake();
          await _wait(const Duration(milliseconds: 320));

        case MonsterAttackOutOfRange():
          _showFeedback(
            _FloatingTextComponent(
              text: 'EVADED BY RANGE!',
              color: InkTheme.verdigrisGreen,
              position: _shipVisual.position - Vector2(0, 40),
            ),
          );
          await _wait(const Duration(milliseconds: 280));

        case HeadOnCollisionOccurred(:final bonusDamagePercent):
          _showFeedback(
            _FloatingTextComponent(
              text: 'HEAD-ON COLLISION! +$bonusDamagePercent%',
              color: InkTheme.crimsonAccent,
              position: _shipVisual.position - Vector2(0, 40),
            ),
          );
          _triggerScreenShake();
          await _wait(const Duration(milliseconds: 300));

        case MonsterIntentDisrupted():
          _showFeedback(
            _FloatingTextComponent(
              text: 'INTENT DISRUPTED!',
              color: InkTheme.goldAccent,
              position: _monsterVisual.position - Vector2(0, 50),
            ),
          );
          _triggerScreenShake();
          await _wait(const Duration(milliseconds: 300));

        case ShipGrappled():
          _showFeedback(
            _FloatingTextComponent(
              text: 'HELM GRAPPLED!',
              color: InkTheme.crimsonAccent,
              position: _shipVisual.position - Vector2(0, 40),
            ),
          );
          await _wait(const Duration(milliseconds: 280));

        default:
          break;
      }
    }

    _barragePlayback = false;
    if (!_removed) onComplete();
  }

  Future<void> _wait(Duration duration, {bool honorReadingHold = true}) {
    final Duration hold;
    if (_barragePlayback && _barrageStrike > 1) {
      // Only the opener gets normal reading pauses. New damage/defense/status
      // types later in a sweep must not restart the slow introduction.
      hold = Duration(microseconds: min(duration.inMicroseconds ~/ 2, 200000));
    } else if (_barragePlayback &&
        honorReadingHold &&
        _readingHold > duration) {
      hold = _readingHold;
    } else {
      // Labels live independently; ordinary outcomes never wait for their fade.
      hold = duration.inMilliseconds == 100
          ? duration
          : Duration(milliseconds: duration.inMilliseconds.clamp(400, 500));
    }
    _readingHold = Duration.zero;
    return _playbackDelay(hold);
  }

  /// Bounded local history lets new consequences arrive before older cues fade.
  void _showFeedback(_FeedbackComponent component) {
    final side = component.position.x < size.x / 2
        ? CombatSide.ship
        : CombatSide.monster;
    final labels = _feedback.putIfAbsent(side, () => []);
    labels.add(component);
    while (labels.length > 3) {
      final oldest = labels.removeAt(0);
      oldest.dismiss();
    }
    component.onDismiss = () {
      if (labels.remove(component) && !_removed) _layoutFeedback();
    };
    final text = switch (component) {
      _FloatingTextComponent(:final text) => text,
      _DamageNumberComponent(:final damage) => 'Hull damage $damage',
      _ => '',
    };
    final words = text.split(RegExp(r'\s+')).length;
    final hold = Duration(
      milliseconds: component is _DamageNumberComponent
          ? 800
          : (1400 + max(0, words - 2) * 200).clamp(1400, 3400),
    );
    if (_barragePlayback && _barrageStrike == 1 && hold > _readingHold) {
      _readingHold = hold;
    }
    if (!_barragePlayback && component is _FloatingTextComponent) {
      // Label visibility is independent of the short attack-name/impact gap.
      component.solidSeconds = (hold.inMilliseconds + 400) / 2000;
      component.fadeSeconds = (hold.inMilliseconds + 400) / 2000;
    }
    if (!_barragePlayback && component is _DamageNumberComponent) {
      component.solidSeconds = 0.85;
      component.fadeSeconds = 0.85;
    }
    presentation.announce(
      '${side == CombatSide.ship ? ship.name : monster.name}: $text',
    );
    _layoutFeedback();
    add(component);
  }

  void _triggerScreenShake() {
    if (reducedMotion) return;
    final originalCamera = camera.viewfinder.position.clone();
    var elapsed = 0.0;
    const duration = 0.15;

    late final TimerComponent shakeTimer;
    shakeTimer = TimerComponent(
      period: 0.02,
      repeat: true,
      onTick: () {
        elapsed += 0.02;
        if (elapsed >= duration) {
          camera.viewfinder.position = originalCamera;
          shakeTimer.removeFromParent();
        } else {
          final offset = Vector2(
            (Random().nextDouble() - 0.5) * 8,
            (Random().nextDouble() - 0.5) * 8,
          );
          camera.viewfinder.position = originalCamera + offset;
        }
      },
    );
    camera.viewfinder.add(shakeTimer);
  }
}

class _RollingWavesComponent extends PositionComponent
    with HasGameReference<MonstrousSeaBattleGame> {
  double _time = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.reducedMotion) _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final width = game.size.x;
    final height = game.size.y;

    final wavePaint = Paint()
      ..color = InkTheme.inkMuted.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var tier = 0; tier < 4; tier++) {
      final yBase = height * (0.45 + tier * 0.15);
      final amplitude = 6.0 + tier * 2;
      final frequency = 0.015;
      final phase = _time * 1.5 + tier * 1.2;

      final path = Path();
      var first = true;
      for (var x = 0.0; x <= width; x += 6.0) {
        final y = yBase + sin(x * frequency + phase) * amplitude;
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wavePaint);
    }
  }
}

class _ShipBattleComponent extends PositionComponent
    with HasGameReference<MonstrousSeaBattleGame> {
  _ShipBattleComponent({required this.ship, this.sprite, this.pictureInfo})
    : super(anchor: Anchor.center);

  final ShipState ship;
  Sprite? sprite;
  PictureInfo? pictureInfo;
  double _time = 0;
  double _fortifyFlash = 0;

  void flashFortify() {
    _fortifyFlash = 0.5;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.reducedMotion) _time += dt;
    _fortifyFlash = max(0, _fortifyFlash - dt);
    // Nautical pitch and roll
    angle = sin(_time * 1.8) * 0.05;
  }

  @override
  void render(Canvas canvas) {
    final pic = pictureInfo;
    if (pic != null) {
      canvas.save();
      // Anchor.center already offsets the component; local art starts at (0, 0).
      final scaleX = size.x / pic.size.width;
      final scaleY = size.y / pic.size.height;
      canvas.scale(scaleX, scaleY);
      canvas.drawPicture(pic.picture);
      if (_fortifyFlash > 0) {
        final shieldPaint = Paint()
          ..color = InkTheme.goldAccent.withValues(
            alpha: (_fortifyFlash / 0.5) * 0.45,
          )
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, pic.size.width, pic.size.height),
          shieldPaint,
        );
      }
      canvas.restore();
      return;
    }
    final art = sprite;
    if (art != null) {
      art.renderRect(
        canvas,
        Rect.fromLTWH(0, 0, size.x, size.y),
        overridePaint: Paint()..filterQuality = FilterQuality.medium,
      );
      if (_fortifyFlash > 0) {
        final shieldPaint = Paint()
          ..color = InkTheme.goldAccent.withValues(
            alpha: (_fortifyFlash / 0.5) * 0.45,
          )
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), shieldPaint);
      }
      return;
    }
    _renderArtPlaceholder(canvas, size, 'VESSEL');
  }
}

class _MonsterBattleComponent extends PositionComponent
    with HasGameReference<MonstrousSeaBattleGame> {
  _MonsterBattleComponent({
    required this.monster,
    this.sprite,
    this.pictureInfo,
  }) : super(anchor: Anchor.center);

  final MonsterState monster;
  Sprite? sprite;
  PictureInfo? pictureInfo;
  double _time = 0;
  int displayedTentacles = 8;
  double _severFlash = 0;

  @override
  void onLoad() {
    super.onLoad();
    displayedTentacles = monster.numberOfTentacles.clamp(0, 12);
  }

  void updateTentacles(int count) {
    displayedTentacles = count.clamp(0, 12);
    _severFlash = 0.45;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.reducedMotion) _time += dt;
    _severFlash = max(0, _severFlash - dt);
    angle = sin(_time * 1.2) * 0.04;
  }

  @override
  void render(Canvas canvas) {
    final pic = pictureInfo;
    if (pic != null) {
      canvas.save();
      // The component transform applies the centre anchor exactly once.
      final scaleX = size.x / pic.size.width;
      final scaleY = size.y / pic.size.height;
      canvas.scale(scaleX, scaleY);
      if (monster.isObscured) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, pic.size.width, pic.size.height),
          Paint()..color = Colors.white.withValues(alpha: 0.45),
        );
      }
      canvas.drawPicture(pic.picture);
      if (monster.isObscured) {
        canvas.restore();
      }
      if (_severFlash > 0) {
        final severPaint = Paint()
          ..color = InkTheme.crimsonAccent.withValues(
            alpha: (_severFlash / 0.45) * 0.45,
          )
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, pic.size.width, pic.size.height),
          severPaint,
        );
      }
      canvas.restore();
      return;
    }
    final art = sprite;
    if (art != null) {
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: monster.isObscured ? 0.5 : 1);
      if (_severFlash > 0) {
        paint.colorFilter = ColorFilter.mode(
          InkTheme.crimsonAccent.withValues(alpha: _severFlash / 0.45 * 0.4),
          BlendMode.srcATop,
        );
      }
      art.renderRect(
        canvas,
        Rect.fromLTWH(0, 0, size.x, size.y),
        overridePaint: paint,
      );
      return;
    }
    _renderArtPlaceholder(canvas, size, 'BEAST');
  }
}

/// A labeled cartouche is not replacement creature/ship art.
void _renderArtPlaceholder(Canvas canvas, Vector2 size, String label) {
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, size.x, size.y),
    const Radius.circular(4),
  );
  canvas.drawRRect(rect, Paint()..color = InkTheme.parchmentSurface);
  canvas.drawRRect(
    rect,
    Paint()
      ..color = InkTheme.inkMuted
      ..style = PaintingStyle.stroke,
  );
  final text = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: InkTheme.inkMuted,
        fontFamily: 'Arial',
        fontSize: min(16, size.x / 7),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: max(1, size.x - 4));
  text.paint(
    canvas,
    Offset((size.x - text.width) / 2, (size.y - text.height) / 2),
  );
  text.dispose();
}

/// Measured cartouches share geometry, lifetime and cleanup with their stack.
abstract class _FeedbackComponent extends PositionComponent
    with HasGameReference<MonstrousSeaBattleGame>
    implements BattleFeedback {
  _FeedbackComponent({required super.position, this.reducedMotion = false})
    : super(anchor: Anchor.topCenter);
  final bool reducedMotion;
  VoidCallback? onDismiss;
  double solidSeconds = 3.75;
  double fadeSeconds = 0.25;
  double _life = 0;
  TextPainter? _painter;
  Color get color;
  double get fontSize;
  String? _font;
  double? _scale;
  double? _maxWidth;

  void measure(double scale, String? font, double maxWidth) {
    if (_painter != null &&
        _scale == scale &&
        _font == font &&
        _maxWidth == maxWidth) {
      return;
    }
    _scale = scale;
    _font = font;
    _maxWidth = maxWidth;
    _painter?.dispose();
    _painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: font ?? InkTheme.titleMedium.fontFamily,
          fontSize: fontSize * scale,
          fontWeight: FontWeight.bold,
          color: color == InkTheme.goldAccent ? InkTheme.inkPrimary : color,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: max(1, maxWidth));
    size.setValues(_painter!.width + 14, _painter!.height + 6);
  }

  @override
  Rect get bounds =>
      Rect.fromLTWH(position.x - width / 2, position.y, width, height);

  @override
  double get opacity => game.reducedMotion || reducedMotion
      ? 1
      : (1 - max(0, _life - solidSeconds) / fadeSeconds).clamp(0.0, 1.0);

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life >= solidSeconds + fadeSeconds) {
      dismiss();
    }
  }

  void _disposeFeedback() {
    final callback = onDismiss;
    onDismiss = null;
    callback?.call();
    _painter?.dispose();
    _painter = null;
  }

  void dismiss() {
    _disposeFeedback();
    removeFromParent();
  }

  @override
  void onRemove() {
    _disposeFeedback();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final painter = _painter;
    if (painter == null) return;
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(3),
    );
    // A single layer fades the text and entire cartouche together.
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawRRect(
      box,
      Paint()..color = InkTheme.parchmentSurface.withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke,
    );
    painter.paint(canvas, const Offset(7, 3));
    canvas.restore();
  }
}

class _DamageNumberComponent extends _FeedbackComponent {
  _DamageNumberComponent({
    required this.damage,
    required super.position,
    super.reducedMotion,
  }) {
    solidSeconds = 2.25;
    fadeSeconds = 0.25;
  }
  final int damage;
  @override
  String get text => '-$damage';
  @override
  Color get color => InkTheme.crimsonAccent;
  @override
  double get fontSize => 22;
}

class _FloatingTextComponent extends _FeedbackComponent {
  _FloatingTextComponent({
    required this.text,
    this.color = InkTheme.inkPrimary,
    required super.position,
    super.reducedMotion,
  });
  @override
  final String text;
  @override
  final Color color;
  @override
  double get fontSize => 16;
}

class _InkCloudOverlayComponent extends PositionComponent {
  _InkCloudOverlayComponent({required super.position});

  final double _opacity = 0.75;

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = InkTheme.inkPrimary.withValues(alpha: _opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(Offset.zero, 65, paint);
  }
}
