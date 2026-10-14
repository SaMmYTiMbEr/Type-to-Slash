import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Score popup that rises and fades where an enemy was slain.
class FloatingScoreText extends PositionComponent {
  FloatingScoreText({required this.label, this.color = const Color(0xFFFFD54F)})
    : super(anchor: Anchor.center) {
    _painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 8)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    size = Vector2(_painter.width, _painter.height);
  }

  final String label;
  final Color color;

  late final TextPainter _painter;

  static const double _duration = 0.9;
  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _duration) {
      removeFromParent();
      return;
    }
    final progress = (_age / _duration).clamp(0.0, 1.0);
    position.y -= 45 * dt;
    scale = Vector2.all(1 + 0.2 * Curves.easeOutCubic.transform(progress));
  }

  @override
  void render(ui.Canvas canvas) {
    final fade =
        1 - Curves.easeInCubic.transform((_age / _duration).clamp(0.0, 1.0));
    canvas.saveLayer(
      null,
      ui.Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: fade),
    );
    _painter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
