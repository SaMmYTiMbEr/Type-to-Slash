import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../../domain/entities/enemy_kind.dart';
import '../../domain/game_events.dart';
import '../../domain/game_session.dart';
import 'background_component.dart';
import 'damage_flash.dart';
import 'enemy_component.dart';
import 'floating_score_text.dart';
import 'slash_effect.dart';
import 'wave_banner.dart';

/// Rendering adapter: feeds a [GameSession] from the Flame loop and mirrors
/// its state onto components. It holds no game rules of its own.
class TypeAndSlashGame extends FlameGame {
  TypeAndSlashGame({required this.session, this.enemyFontSize = 28});

  final GameSession session;
  final double enemyFontSize;

  final Map<int, EnemyComponent> _enemyViews = {};
  late final BackgroundComponent _background = BackgroundComponent(
    session.rules,
  );
  StreamSubscription<GameEvent>? _events;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_background);
    _events = session.events.listen(_onEvent);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    session.resize(width: size.x, height: size.y);
    _background.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    session.update(dt);
    _syncEnemyViews();
  }

  @override
  void onRemove() {
    _events?.cancel();
    super.onRemove();
  }

  void _syncEnemyViews() {
    final aliveIds = {for (final enemy in session.enemies) enemy.id};
    final targetId = session.targetEnemyId;

    _enemyViews.removeWhere((id, view) {
      if (aliveIds.contains(id)) return false;
      view.removeFromParent();
      return true;
    });

    for (final enemy in session.enemies) {
      final view = _enemyViews[enemy.id];
      if (view == null) {
        final created = EnemyComponent(
          enemy: enemy,
          baseFontSize: enemyFontSize,
        );
        _enemyViews[enemy.id] = created;
        add(created);
      } else {
        view.setTargeted(enemy.id == targetId);
      }
    }
  }

  void _onEvent(GameEvent event) {
    switch (event) {
      case EnemySlashed():
        add(SlashEffect(Vector2(event.x, event.y)));
        add(
          FloatingScoreText(
            label: '+${event.points}',
            color: _pointsColor(event.kind),
          )..position = Vector2(event.x, event.y),
        );
      case EnemyExpired():
        add(
          FloatingScoreText(label: 'missed', color: const Color(0xFF78909C))
            ..position = Vector2(event.x, event.y),
        );
      case EnemyEscaped():
      case PlayerDamaged():
        add(
          DamageFlash(area: Vector2(session.arena.width, session.arena.height)),
        );
      case WaveStarted():
        _background.setWave(event.wave);
        add(
          WaveBanner(event.wave)
            ..position = Vector2(session.arena.width / 2, 180),
        );
      case ComboChanged():
      case TypoRegistered():
      case GameOver():
        break;
    }
  }

  Color _pointsColor(EnemyKind kind) => switch (kind) {
    EnemyKind.standard => const Color(0xFFFFD54F),
    EnemyKind.runner => const Color(0xFFFF9800),
    EnemyKind.bruiser => const Color(0xFFB388FF),
    EnemyKind.golden => const Color(0xFFFFD54F),
  };
}
