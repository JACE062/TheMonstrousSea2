import 'dart:math';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
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
  }) {
    // A local cache owns the scene's full asset paths and decoded images.
    images = Images(prefix: '');
  }

  final ShipState ship;
  final MonsterState monster;

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

    PictureInfo? shipPicture;
    Sprite? shipSprite;
    if (shipPath.toLowerCase().endsWith('.svg')) {
      shipPicture = await vg.loadPicture(SvgAssetLoader(shipPath), null);
    } else {
      shipSprite = Sprite(await images.load(shipPath));
    }

    PictureInfo? monsterPicture;
    Sprite? monsterSprite;
    if (monsterPath.toLowerCase().endsWith('.svg')) {
      monsterPicture = await vg.loadPicture(SvgAssetLoader(monsterPath), null);
    } else {
      monsterSprite = Sprite(await images.load(monsterPath));
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
  final Sprite? sprite;
  final PictureInfo? pictureInfo;
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
    final paint = Paint()
      ..color = InkTheme.inkPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fillPaint = Paint()
      ..color = InkTheme.parchmentSurface
      ..style = PaintingStyle.fill;

    // Stylized vessel silhouette on canvas
    final hull = Path()
      ..moveTo(-50, 15)
      ..lineTo(-60, 0)
      ..lineTo(55, 0)
      ..lineTo(70, -10)
      ..lineTo(60, 15)
      ..quadraticBezierTo(0, 30, -50, 15)
      ..close();

    canvas.drawPath(hull, fillPaint);
    canvas.drawPath(hull, paint);

    // Masts & sails
    canvas.drawLine(const Offset(-20, 0), const Offset(-20, -55), paint);
    canvas.drawLine(const Offset(20, 0), const Offset(20, -65), paint);

    final sailPaint = Paint()
      ..color = InkTheme.parchmentHighlight
      ..style = PaintingStyle.fill;

    final sail1 = Path()
      ..moveTo(-35, -50)
      ..quadraticBezierTo(-20, -45, -5, -50)
      ..lineTo(-20, -15)
      ..close();
    canvas.drawPath(sail1, sailPaint);
    canvas.drawPath(sail1, paint);

    final sail2 = Path()
      ..moveTo(5, -60)
      ..quadraticBezierTo(20, -55, 35, -60)
      ..lineTo(20, -20)
      ..close();
    canvas.drawPath(sail2, sailPaint);
    canvas.drawPath(sail2, paint);
  }
}

class _MonsterBattleComponent extends PositionComponent with HasGameReference<MonstrousSeaBattleGame> {
  _MonsterBattleComponent({required this.monster, this.sprite, this.pictureInfo})
      : super(anchor: Anchor.center);

  final MonsterState monster;
  final Sprite? sprite;
  final PictureInfo? pictureInfo;
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
    final strokePaint = Paint()
      ..color = InkTheme.inkPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final bodyPaint = Paint()
      ..color = monster.isObscured ? InkTheme.inkMuted : InkTheme.parchmentDark
      ..style = PaintingStyle.fill;

    // Head / Mantle
    final head = Path()
      ..moveTo(-35, 20)
      ..quadraticBezierTo(0, -65, 35, 20)
      ..close();
    canvas.drawPath(head, bodyPaint);
    canvas.drawPath(head, strokePaint);

    // Red menacing eyes
    final eyePaint = Paint()..color = InkTheme.crimsonAccent..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(-14, 5), 5, eyePaint);
    canvas.drawCircle(const Offset(14, 5), 5, eyePaint);

    // Dynamic tentacles
    final tentacleCount = displayedTentacles > 0 ? displayedTentacles : 4;
    for (var i = 0; i < tentacleCount; i++) {
      final spread = (i - (tentacleCount / 2)) * 14.0;
      final wave = sin(_time * 2.5 + i) * 8.0;
      final tentacle = Path()
        ..moveTo(spread * 0.5, 20)
        ..quadraticBezierTo(spread + wave, 50, spread * 1.2, 75);
      canvas.drawPath(tentacle, strokePaint);
    }
  }
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
