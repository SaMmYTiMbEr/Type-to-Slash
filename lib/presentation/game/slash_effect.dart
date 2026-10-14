import 'dart:math';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

class _Shard extends PositionComponent {
  _Shard({required this.color, required Random random})
    : super(anchor: Anchor.center) {
    size = Vector2.all(8);
    final angle = random.nextDouble() * math.pi * 2;
    _direction = Vector2(math.cos(angle), math.sin(angle));
    _speed = 70 + random.nextDouble() * 160;
  }

  final Color color;

  late final Vector2 _direction;
  late final double _speed;

  double _age = 0;
  static const double _lifetime = 0.55;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _lifetime) {
      removeFromParent();
      return;
    }
    position += _direction * (_speed * dt);
    position.y += 220 * dt * dt;
    scale = Vector2.all(1 - _age / _lifetime);
  }

  @override
  void render(ui.Canvas canvas) {
    final fade = 1 - (_age / _lifetime);
    canvas.drawLine(
      Offset(size.x / 2, size.y / 2),
      Offset(size.x / 2 + 10 * fade, size.y / 2 - 10 * fade),
      ui.Paint()
        ..color = color.withValues(alpha: fade)
        ..strokeWidth = 3 * fade
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// Slash burst: a widening ring, a diagonal streak and flying shards.
class SlashEffect extends PositionComponent {
  SlashEffect(Vector2 position, {Random? random})
    : super(position: position, anchor: Anchor.center) {
    final rng = random ?? Random();
    for (var i = 0; i < 14; i++) {
      add(
        _Shard(
          color: i.isEven ? const Color(0xFFFF5252) : const Color(0xFFFFC107),
          random: rng,
        ),
      );
    }
  }

  static const double _duration = 0.45;
  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    final progress = (_age / _duration).clamp(0.0, 1.0);
    final fade = 1 - progress;

    canvas.drawCircle(
      Offset.zero,
      10 + 46 * Curves.easeOutCubic.transform(progress),
      ui.Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * fade
        ..color = const Color(0xFFFF5252).withValues(alpha: fade * 0.8),
    );

    final streak = Curves.easeOutCubic.transform(progress);
    canvas.drawLine(
      Offset(-40 * (1 - streak), 26 * (1 - streak)),
      Offset(40 * (1 - streak), -26 * (1 - streak)),
      ui.Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: fade)
        ..strokeWidth = 6 * fade
        ..strokeCap = StrokeCap.round,
    );
  }
}
