import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../theme/ink_theme.dart';

/// 2D naval combat scene driven by Flame, providing animated rolling swells,
/// combatant bobbing, cannon smoke, damage numbers, and ink cloud overlays.
class MonstrousSeaBattleGame extends FlameGame {
  MonstrousSeaBattleGame({
    required this.ship,
    required this.monster,
  });

  final ShipState ship;
  final MonsterState monster;

  late _RollingWavesComponent _waves;
  late _ShipBattleComponent _shipVisual;
  late _MonsterBattleComponent _monsterVisual;
  _InkCloudOverlayComponent? _inkOverlay;

  @override
  Color backgroundColor() => InkTheme.parchmentBackground;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Rolling oceanic waves
    _waves = _RollingWavesComponent();
    add(_waves);

    // Ship on left side
    _shipVisual = _ShipBattleComponent(ship: ship);
    add(_shipVisual);

    // Monster on right side
    _monsterVisual = _MonsterBattleComponent(monster: monster);
    add(_monsterVisual);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _shipVisual.position = Vector2(size.x * 0.25, size.y * 0.55);
      _monsterVisual.position = Vector2(size.x * 0.72, size.y * 0.52);
      if (_inkOverlay != null) {
        _inkOverlay!.position = _monsterVisual.position;
      }
    }
  }

  /// Triggers visual playback for domain [events].
  Future<void> playEvents(List<GameEvent> events, VoidCallback onComplete) async {
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
  double _time = 0;

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
  _ShipBattleComponent({required this.ship});

  final ShipState ship;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    // Nautical pitch and roll
    angle = sin(_time * 1.8) * 0.05;
  }

  @override
  void render(Canvas canvas) {
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
  _MonsterBattleComponent({required this.monster});

  final MonsterState monster;
  double _time = 0;
  int displayedTentacles = 8;

  @override
  void onLoad() {
    super.onLoad();
    displayedTentacles = monster.numberOfTentacles.clamp(0, 12);
  }

  void updateTentacles(int count) {
    displayedTentacles = count.clamp(0, 12);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    angle = sin(_time * 1.2) * 0.04;
  }

  @override
  void render(Canvas canvas) {
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
