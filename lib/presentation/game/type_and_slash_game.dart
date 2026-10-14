import 'dart:async';

import 'package:flame/game.dart';

import '../../domain/game_events.dart';
import '../../domain/game_session.dart';
import 'background_component.dart';
import 'damage_flash.dart';
import 'enemy_component.dart';
import 'floating_score_text.dart';
import 'slash_effect.dart';

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

    _enemyViews.removeWhere((id, view) {
      if (aliveIds.contains(id)) return false;
      view.removeFromParent();
      return true;
    });

    for (final enemy in session.enemies) {
      if (_enemyViews.containsKey(enemy.id)) continue;
      final view = EnemyComponent(enemy: enemy, fontSize: enemyFontSize);
      _enemyViews[enemy.id] = view;
      add(view);
    }
  }

  void _onEvent(GameEvent event) {
    switch (event) {
      case EnemySlashed():
        add(SlashEffect(Vector2(event.x, event.y)));
        add(
          FloatingScoreText(label: '+${event.points}')
            ..position = Vector2(event.x, event.y),
        );
      case EnemyEscaped():
      case PlayerDamaged():
        add(
          DamageFlash(area: Vector2(session.arena.width, session.arena.height)),
        );
      case ComboChanged():
      case TypoRegistered():
      case GameOver():
        break;
    }
  }
}
