import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../domain/game_rules.dart';

/// Arena backdrop: gradient sky, drifting starfield, scrolling grid, vignette
/// and the defense line. The palette rotates with the wave number.
class BackgroundComponent extends PositionComponent {
  BackgroundComponent(this._rules) : super(priority: -1);

  final GameRules _rules;

  static const List<List<Color>> _palettes = [
    [Color(0xFF1B1033), Color(0xFF0B0716)],
    [Color(0xFF0B2A3B), Color(0xFF061017)],
    [Color(0xFF3B0B24), Color(0xFF140610)],
    [Color(0xFF12301B), Color(0xFF06140C)],
    [Color(0xFF33260B), Color(0xFF140F05)],
  ];

  static const int _starCount = 60;
  static const double _gridSpacing = 48;

  late final List<_Star> _stars = _buildStars();
  final ui.Paint _gridPaint = ui.Paint()
    ..color = const Color(0x22FFFFFF)
    ..strokeWidth = 1;

  int _wave = 1;
  double _time = 0;
  ui.Shader? _skyShader;
  Vector2 _skySize = Vector2.zero();
  ui.Shader? _vignetteShader;
  Vector2 _vignetteSize = Vector2.zero();

  void setWave(int wave) {
    if (wave == _wave) return;
    _wave = wave;
    _skyShader = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    for (final star in _stars) {
      star.x -= star.speed * dt;
      if (star.x < -4) star.x += size.x + 8;
      if (star.x > size.x + 4) star.x -= size.x + 8;
      if (star.y > size.y) star.y -= size.y;
      if (star.y < 0) star.y += size.y;
      star.phase += dt * star.twinkleSpeed;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);

    if (_skyShader == null || _skySize != size) {
      _skySize = size.clone();
      _skyShader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        _palette,
      );
    }
    canvas.drawRect(rect, ui.Paint()..shader = _skyShader);

    _renderStars(canvas);
    _renderGrid(canvas);

    if (_vignetteShader == null || _vignetteSize != size) {
      _vignetteSize = size.clone();
      _vignetteShader = ui.Gradient.radial(
        rect.center,
        math.max(size.x, size.y) * 0.75,
        [const Color(0x00000000), const Color(0xAA000000)],
        [0.6, 1],
      );
    }
    canvas.drawRect(rect, ui.Paint()..shader = _vignetteShader);

    canvas.drawLine(
      ui.Offset(_rules.defenseLineX, 0),
      ui.Offset(_rules.defenseLineX, size.y),
      ui.Paint()
        ..color = const Color(0x99FF5E7A)
        ..strokeWidth = 3,
    );
  }

  List<Color> get _palette => _palettes[(_wave - 1) % _palettes.length];

  void _renderStars(ui.Canvas canvas) {
    for (final star in _stars) {
      final twinkle = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(star.phase));
      canvas.drawCircle(
        ui.Offset(star.x, star.y),
        star.radius,
        ui.Paint()
          ..color = star.color.withValues(alpha: star.opacity * twinkle)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, star.radius),
      );
    }
  }

  void _renderGrid(ui.Canvas canvas) {
    final offset = (_time * 14) % _gridSpacing;
    for (
      var y = offset - _gridSpacing;
      y < size.y + _gridSpacing;
      y += _gridSpacing
    ) {
      canvas.drawLine(ui.Offset(0, y), ui.Offset(size.x, y), _gridPaint);
    }
    final sway = math.sin(_time * 0.8) * 6;
    for (
      var x = sway - _gridSpacing;
      x < size.x + _gridSpacing;
      x += _gridSpacing
    ) {
      canvas.drawLine(ui.Offset(x, 0), ui.Offset(x, size.y), _gridPaint);
    }
  }

  List<_Star> _buildStars() {
    final random = math.Random(1337);
    return [
      for (var i = 0; i < _starCount; i++)
        _Star(
          x: random.nextDouble() * 1000,
          y: random.nextDouble() * 1000,
          radius: 0.6 + random.nextDouble() * 1.6,
          speed: 6 + random.nextDouble() * 18,
          opacity: 0.2 + random.nextDouble() * 0.6,
          twinkleSpeed: 0.6 + random.nextDouble() * 2,
          phase: random.nextDouble() * math.pi * 2,
          color: random.nextBool()
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF9FA8FF),
        ),
    ];
  }
}

class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.twinkleSpeed,
    required this.phase,
    required this.color,
  });

  double x;
  double y;
  double radius;
  double speed;
  double opacity;
  double twinkleSpeed;
  double phase;
  Color color;
}
