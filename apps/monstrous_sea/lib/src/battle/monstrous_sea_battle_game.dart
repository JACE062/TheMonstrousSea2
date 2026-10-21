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

/// 2D naval combat scene driven by Flame, providing animated rolling swells,
/// combatant bobbing, cannon smoke, damage numbers, and ink cloud overlays.
class MonstrousSeaBattleGame extends FlameGame {
  MonstrousSeaBattleGame({
    required this.ship,
    required this.monster,
    AssetBundle? assetBundle,
  }) {
    // A local cache owns the scene's full asset paths and decoded images.
    images = Images(prefix: '', bundle: assetBundle ?? rootBundle);
  }

  final ShipState ship;
  final MonsterState monster;
  final ValueNotifier<int> artworkRevision = ValueNotifier(0);
  final Set<String> _unavailableArtwork = {};
  bool isRetryingArtwork = false;
  bool _removed = false;
  bool get isShipArtUnavailable => _unavailableArtwork.contains(PilotArt.forShip(ship));
  bool get isMonsterArtUnavailable => _unavailableArtwork.contains(PilotArt.forMonster(monster));

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
    final centreY = _arenaTopInset + arenaHeight / 2;

    // Anchor combatants symmetrically around center with clamped spread
    final centerX = size.x / 2;
    const maxHalfSpread = 320.0;
    final halfSpread = min(size.x * 0.25, maxHalfSpread).clamp(110.0, maxHalfSpread);
    _shipVisual.position = Vector2(centerX - halfSpread, centreY);
    _monsterVisual.position = Vector2(centerX + halfSpread, centreY);

    final shipAspect = _shipVisual.sprite != null
        ? _shipVisual.sprite!.srcSize.x / _shipVisual.sprite!.srcSize.y
        : _shipVisual.pictureInfo != null
            ? _shipVisual.pictureInfo!.size.width / _shipVisual.pictureInfo!.size.height
            : 1.25;
    // Sensible ship sizing capped at 220px and arenaHeight to prevent vertical overflow
    final maxShipWidth = min(
      size.x * 0.32,
      min(220.0, arenaHeight * 0.85 * shipAspect),
    );
    final shipWidth = max(40.0, maxShipWidth);
    _shipVisual.size = Vector2(shipWidth, shipWidth / shipAspect);

    final isBoss = PilotArt.isKraken(monster);
    final monsterAspect = _monsterVisual.sprite != null
        ? _monsterVisual.sprite!.srcSize.x / _monsterVisual.sprite!.srcSize.y
        : _monsterVisual.pictureInfo != null
            ? _monsterVisual.pictureInfo!.size.width / _monsterVisual.pictureInfo!.size.height
            : 1.0;
    // Sensible monster sizing capped at 200px (regular) / 280px (boss) and arenaHeight
    final maxMonsterWidth = min(
      size.x * (isBoss ? 0.38 : 0.28),
      min(isBoss ? 280.0 : 200.0, arenaHeight * (isBoss ? 0.92 : 0.68) * monsterAspect),
    );
    final monsterWidth = max(40.0, maxMonsterWidth);
    _monsterVisual.size = Vector2(monsterWidth, monsterWidth / monsterAspect);
    if (_inkOverlay != null) {
      _inkOverlay!.position = _monsterVisual.position;
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
  Future<void> playEvents(List<GameEvent> events, VoidCallback onComplete) async {
    await loaded;
    _layoutCombatants();

    for (final event in events) {
      switch (event) {
        case AttackHit(:final targetName, :final damage):
          final isMonster = targetName == monster.name;
          final pos = isMonster ? _monsterVisual.position : _shipVisual.position;
          add(_DamageNumberComponent(damage: damage, position: pos - Vector2(0, 40)));
          _triggerScreenShake();
          await Future.delayed(const Duration(milliseconds: 320));

        case AttackMissed(:final targetName):
          final isMonster = targetName == monster.name;
          final pos = isMonster ? _monsterVisual.position : _shipVisual.position;
          add(_FloatingTextComponent(text: 'MISS', position: pos - Vector2(0, 40)));
          await Future.delayed(const Duration(milliseconds: 260));

        case AttackEvaded():
          add(_FloatingTextComponent(
            text: 'DODGED!',
            color: InkTheme.verdigrisGreen,
            position: _shipVisual.position - Vector2(0, 40),
          ));
          await Future.delayed(const Duration(milliseconds: 260));

        case DamageReduced(:final nullifiedAmount):
          add(_FloatingTextComponent(
            text: '-$nullifiedAmount ABSORB',
            color: InkTheme.goldAccent,
            position: _shipVisual.position - Vector2(0, 40),
          ));
          _shipVisual.flashFortify();
          await Future.delayed(const Duration(milliseconds: 260));

        case TentaclesSevered(:final remainingTentacles):
          _monsterVisual.updateTentacles(remainingTentacles);
          add(_FloatingTextComponent(
            text: 'TENTACLE SEVERED!',
            color: InkTheme.crimsonAccent,
            position: _monsterVisual.position - Vector2(0, 60),
          ));
          await Future.delayed(const Duration(milliseconds: 300));

        case InkCloudDeployed():
          if (_inkOverlay == null) {
            _inkOverlay = _InkCloudOverlayComponent(position: _monsterVisual.position);
            add(_inkOverlay!);
          }
          await Future.delayed(const Duration(milliseconds: 300));

        case NarrationEvent(:final message) when message.contains('fortifying'):
          add(_FloatingTextComponent(
            text: '+FORTIFIED',
            color: InkTheme.goldAccent,
            position: _shipVisual.position - Vector2(0, 40),
          ));
          _shipVisual.flashFortify();
          await Future.delayed(const Duration(milliseconds: 320));

        case CombatRangeChanged(:final newRange, :final previousRange):
          final isClosing = newRange.index > previousRange.index;
          add(_FloatingTextComponent(
            text: isClosing
                ? 'CLOSING: ${newRange.displayName.toUpperCase()}'
                : 'FALLING BACK: ${newRange.displayName.toUpperCase()}',
            color: InkTheme.goldAccent,
            position: _shipVisual.position - Vector2(0, 40),
          ));
          await Future.delayed(const Duration(milliseconds: 260));

        case MortarBackfireOccurred(:final damage):
          add(_FloatingTextComponent(
            text: 'BACKFIRE! -$damage',
            color: InkTheme.crimsonAccent,
            position: _shipVisual.position - Vector2(0, 40),
          ));
          _triggerScreenShake();
          await Future.delayed(const Duration(milliseconds: 320));

        case MonsterAttackOutOfRange():
          add(_FloatingTextComponent(
            text: 'EVADED BY RANGE!',
            color: InkTheme.verdigrisGreen,
            position: _shipVisual.position - Vector2(0, 40),
          ));
          await Future.delayed(const Duration(milliseconds: 280));

        case HeadOnCollisionOccurred(:final bonusDamagePercent):
          add(_FloatingTextComponent(
            text: 'HEAD-ON COLLISION! +$bonusDamagePercent%',
            color: InkTheme.crimsonAccent,
            position: _shipVisual.position - Vector2(0, 40),
          ));
          _triggerScreenShake();
          await Future.delayed(const Duration(milliseconds: 300));

        case MonsterIntentDisrupted():
          add(_FloatingTextComponent(
            text: 'INTENT DISRUPTED!',
            color: InkTheme.goldAccent,
            position: _monsterVisual.position - Vector2(0, 50),
          ));
          _triggerScreenShake();
          await Future.delayed(const Duration(milliseconds: 300));

        case ShipGrappled():
          add(_FloatingTextComponent(
            text: 'HELM GRAPPLED!',
            color: InkTheme.crimsonAccent,
            position: _shipVisual.position - Vector2(0, 40),
          ));
          await Future.delayed(const Duration(milliseconds: 280));

        default:
          break;
      }
    }

    onComplete();
  }

  void _triggerScreenShake() {
    final originalCamera = camera.viewfinder.position.clone();
    var elapsed = 0.0;
    const duration = 0.15;

    camera.viewfinder.add(
      TimerComponent(
        period: 0.02,
        repeat: true,
        onTick: () {
          elapsed += 0.02;
          if (elapsed >= duration) {
            camera.viewfinder.position = originalCamera;
          } else {
            final offset = Vector2(
              (Random().nextDouble() - 0.5) * 8,
              (Random().nextDouble() - 0.5) * 8,
            );
            camera.viewfinder.position = originalCamera + offset;
          }
        },
      ),
    );
  }
}

class _RollingWavesComponent extends PositionComponent with HasGameReference<MonstrousSeaBattleGame> {
  double _time = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
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

class _ShipBattleComponent extends PositionComponent with HasGameReference<MonstrousSeaBattleGame> {
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
    _time += dt;
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
          ..color = InkTheme.goldAccent.withValues(alpha: (_fortifyFlash / 0.5) * 0.45)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(0, 0, pic.size.width, pic.size.height), shieldPaint);
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
          ..color = InkTheme.goldAccent.withValues(alpha: (_fortifyFlash / 0.5) * 0.45)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), shieldPaint);
      }
      return;
    }
    _renderArtPlaceholder(canvas, size, 'VESSEL');
  }
}

class _MonsterBattleComponent extends PositionComponent with HasGameReference<MonstrousSeaBattleGame> {
  _MonsterBattleComponent({required this.monster, this.sprite, this.pictureInfo})
      : super(anchor: Anchor.center);

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
    _time += dt;
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
          ..color = InkTheme.crimsonAccent.withValues(alpha: (_severFlash / 0.45) * 0.45)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(0, 0, pic.size.width, pic.size.height), severPaint);
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
    Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(4),
  );
  canvas.drawRRect(rect, Paint()..color = InkTheme.parchmentSurface);
  canvas.drawRRect(rect, Paint()
    ..color = InkTheme.inkMuted
    ..style = PaintingStyle.stroke);
  final text = TextPainter(
    text: TextSpan(text: label, style: TextStyle(
      color: InkTheme.inkMuted, fontFamily: 'Arial', fontSize: min(16, size.x / 7),
    )),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: max(1, size.x - 4));
  text.paint(canvas, Offset((size.x - text.width) / 2, (size.y - text.height) / 2));
  text.dispose();
}

class _DamageNumberComponent extends PositionComponent {
  _DamageNumberComponent({required this.damage, required super.position});

  final int damage;
  double _life = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= dt * 35; // Floats upwards
    if (_life >= 0.8) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final span = TextSpan(
      text: '-$damage',
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: InkTheme.crimsonAccent.withValues(alpha: (1.0 - _life / 0.8).clamp(0.0, 1.0)),
      ),
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    painter.paint(canvas, Offset(-painter.width / 2, 0));
  }
}

class _FloatingTextComponent extends PositionComponent {
  _FloatingTextComponent({
    required this.text,
    this.color = InkTheme.inkPrimary,
    required super.position,
  });

  final String text;
  final Color color;
  double _life = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= dt * 25;
    if (_life >= 0.7) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color.withValues(alpha: (1.0 - _life / 0.7).clamp(0.0, 1.0)),
      ),
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    painter.paint(canvas, Offset(-painter.width / 2, 0));
  }
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
