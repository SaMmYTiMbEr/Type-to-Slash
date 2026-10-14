import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Big "WAVE 3" callout shown when the difficulty steps up.
class WaveBanner extends PositionComponent {
  WaveBanner(this.wave) : super(anchor: Anchor.center, priority: 5) {
    _painter = TextPainter(
      text: TextSpan(
        text: 'WAVE $wave',
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 12)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    size = Vector2(_painter.width, _painter.height);
  }

  final int wave;

  late final TextPainter _painter;

  static const double _duration = 1.8;
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
    final entrance = Curves.easeOutBack.transform(
      (progress / 0.25).clamp(0.0, 1.0),
    );
    scale = Vector2.all(0.6 + 0.4 * entrance);
  }

  @override
  void render(ui.Canvas canvas) {
    final progress = (_age / _duration).clamp(0.0, 1.0);
    final fade = progress < 0.6
        ? 1.0
        : 1 - Curves.easeInCubic.transform((progress - 0.6) / 0.4);

    canvas.saveLayer(
      null,
      ui.Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: fade),
    );
    _painter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
