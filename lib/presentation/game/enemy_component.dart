import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../domain/entities/game_enemy.dart';

/// Renders a [GameEnemy]: the word in red, with the typed prefix in green.
///
/// Animations: scale-in on spawn, a slow vertical bob while alive, and a glow
/// pulse every time the player types another matching character.
class EnemyComponent extends PositionComponent {
  EnemyComponent({required this.enemy, required this.fontSize})
    : _fullPainter = _painterFor(enemy.word, _baseColor, fontSize) {
    size = Vector2(_fullPainter.width, _fullPainter.height);
    _syncTransform();
  }

  static const Color _baseColor = Color(0xFFFF5252);
  static const Color _typedColor = Color(0xFF69F0AE);
  static const double _spawnDuration = 0.45;

  final GameEnemy enemy;
  final double fontSize;
  final TextPainter _fullPainter;

  TextPainter? _typedPainter;
  int _typedPainterFor = -1;

  double _time = 0;
  double _spawnProgress = 0;
  double _glow = 0;
  int _glowTarget = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _spawnProgress = (_spawnProgress + dt / _spawnDuration).clamp(0.0, 1.0);
    if (enemy.typedCharacters != _glowTarget) {
      _glowTarget = enemy.typedCharacters;
      _glow = _glowTarget > 0 ? 1 : 0;
    }
    _glow = math.max(0, _glow - dt * 3);
    _syncTransform();
  }

  void _syncTransform() {
    final spawn = Curves.easeOutBack.transform(_spawnProgress);
    final bob = math.sin(_time * 2.6 + enemy.id) * 4;

    position.x = enemy.x + (1 - _spawnProgress) * 40;
    position.y = enemy.laneY + bob;
    scale = Vector2.all(0.5 + 0.5 * spawn);
  }

  @override
  void render(ui.Canvas canvas) {
    if (_glow > 0) {
      final radius = size.x * 0.75 + _glow * 10;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        radius,
        ui.Paint()
          ..color = _typedColor.withValues(alpha: 0.25 * _glow)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
      );
    }

    _fullPainter.paint(canvas, Offset.zero);

    final typed = enemy.typedCharacters;
    if (typed <= 0 || enemy.isFullyTyped) return;

    if (_typedPainterFor != typed) {
      _typedPainterFor = typed;
      _typedPainter = _painterFor(
        enemy.word.substring(0, typed),
        _typedColor,
        fontSize,
      );
    }
    _typedPainter?.paint(canvas, Offset.zero);
  }

  static TextPainter _painterFor(String text, Color color, double fontSize) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Color(0xDD000000), blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}
