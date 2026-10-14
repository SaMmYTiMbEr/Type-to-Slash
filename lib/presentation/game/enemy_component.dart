import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../domain/entities/enemy_kind.dart';
import '../../domain/entities/game_enemy.dart';

/// Renders a [GameEnemy]: the word in the kind's colour, with the typed prefix
/// in green.
///
/// Animations: scale-in on spawn, a slow vertical bob while alive, a glow
/// pulse every time the player types another matching character, and a
/// heartbeat for golden enemies racing their timer.
class EnemyComponent extends PositionComponent {
  EnemyComponent({required this.enemy, required this.baseFontSize})
    : _fullPainter = _painterFor(
        enemy.word,
        _colorOf(enemy.kind),
        _fontSizeOf(baseFontSize, enemy.kind),
        _weightOf(enemy.kind),
      ) {
    size = Vector2(_fullPainter.width, _fullPainter.height);
    _syncTransform();
  }

  final GameEnemy enemy;
  final double baseFontSize;
  final TextPainter _fullPainter;

  bool _targeted = false;

  /// Marks the enemy the current typing would hit.
  void setTargeted(bool value) => _targeted = value;

  TextPainter? _typedPainter;
  int _typedPainterFor = -1;

  double _time = 0;
  double _spawnProgress = 0;
  double _glow = 0;
  int _glowTarget = 0;

  static const double _spawnDuration = 0.45;

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
    final urgency = enemy.kind.hasTimeLimit ? math.sin(_time * 8) * 1.5 : 0.0;

    position.x = enemy.x + (1 - _spawnProgress) * 40;
    position.y = enemy.laneY + bob + urgency;
    scale = Vector2.all(0.5 + 0.5 * spawn);
  }

  @override
  void render(ui.Canvas canvas) {
    if (_glow > 0) _renderGlow(canvas);
    if (enemy.kind.hasTimeLimit) _renderHeartbeat(canvas);
    if (_targeted) _renderTargetMark(canvas);

    _fullPainter.paint(canvas, Offset.zero);

    final typed = enemy.typedCharacters;
    if (typed <= 0 || enemy.isFullyTyped) return;

    if (_typedPainterFor != typed) {
      _typedPainterFor = typed;
      _typedPainter = _painterFor(
        enemy.word.substring(0, typed),
        const Color(0xFF69F0AE),
        _fontSizeOf(baseFontSize, enemy.kind),
        _weightOf(enemy.kind),
      );
    }
    _typedPainter?.paint(canvas, Offset.zero);
  }

  void _renderTargetMark(ui.Canvas canvas) {
    final pulse = 0.5 + 0.5 * math.sin(_time * 7);
    final y = size.y + 6;
    final half = size.x / 2;

    canvas.drawLine(
      Offset(-half, y),
      Offset(half, y),
      ui.Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.5 + 0.4 * pulse)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(half + 10, y - 6 + 6 * (1 - pulse)),
      Offset(half + 18, y),
      ui.Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.5 + 0.4 * pulse)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(half + 18, y),
      Offset(half + 10, y + 6 - 6 * (1 - pulse)),
      ui.Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.5 + 0.4 * pulse)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _renderGlow(ui.Canvas canvas) {
    final radius = size.x * 0.75 + _glow * 10;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      radius,
      ui.Paint()
        ..color = const Color(0xFF69F0AE).withValues(alpha: 0.25 * _glow)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
    );
  }

  void _renderHeartbeat(ui.Canvas canvas) {
    final pulse = 0.5 + 0.5 * math.sin(_time * 8);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x * 0.7 + pulse * 6,
      ui.Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _colorOf(enemy.kind).withValues(alpha: 0.25 + 0.35 * pulse),
    );
  }

  static Color _colorOf(EnemyKind kind) => switch (kind) {
    EnemyKind.standard => const Color(0xFFFF5252),
    EnemyKind.runner => const Color(0xFFFF9800),
    EnemyKind.bruiser => const Color(0xFFB388FF),
    EnemyKind.golden => const Color(0xFFFFD54F),
  };

  static double _fontSizeOf(double base, EnemyKind kind) => switch (kind) {
    EnemyKind.standard => base,
    EnemyKind.runner => base * 0.9,
    EnemyKind.bruiser => base * 1.2,
    EnemyKind.golden => base * 0.95,
  };

  static FontWeight _weightOf(EnemyKind kind) => switch (kind) {
    EnemyKind.bruiser => FontWeight.w900,
    EnemyKind.golden => FontWeight.w800,
    _ => FontWeight.bold,
  };

  static TextPainter _painterFor(
    String text,
    Color color,
    double fontSize,
    FontWeight weight,
  ) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          shadows: const [Shadow(color: Color(0xDD000000), blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}
