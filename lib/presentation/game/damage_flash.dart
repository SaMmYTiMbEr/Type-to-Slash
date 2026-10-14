import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

/// Full-screen red pulse shown when an enemy slips through.
class DamageFlash extends PositionComponent {
  DamageFlash({required this.area}) : super(priority: 10) {
    size = area;
  }

  final Vector2 area;

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
    final alpha = (1 - Curves.easeOutCubic.transform(progress)) * 0.45;

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, area.x, area.y),
      ui.Paint()..color = const Color(0xFFFF1744).withValues(alpha: alpha),
    );
  }
}
