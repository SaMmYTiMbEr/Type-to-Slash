import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/game_events.dart';
import '../../domain/game_session.dart';

/// Exposes session state to the widget layer as listenable values, so screens
/// never read the session directly.
class GameViewModel {
  GameViewModel(this._session) {
    _subscription = _session.events.listen(_onEvent);
  }

  final GameSession _session;
  late final StreamSubscription<GameEvent> _subscription;

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> health = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(0);
  final ValueNotifier<int> multiplier = ValueNotifier(1);
  final ValueNotifier<int> strikesRemaining = ValueNotifier(0);
  final ValueNotifier<bool> isGameOver = ValueNotifier(false);

  int get maxHealth => _session.rules.maxHealth;

  int get maxStrikes => _session.rules.maxStrikes;

  /// Returns true when the input triggered a slash, so the caller can clear
  /// the field without the player pressing a submit key.
  bool submit(String input) =>
      _session.handleInput(input) == SlashOutcome.slashed;

  void _onEvent(GameEvent event) {
    score.value = _session.score;
    health.value = _session.health;
    combo.value = _session.combo;
    multiplier.value = _session.multiplier;
    strikesRemaining.value = _session.strikesRemaining;

    if (event is GameOver) {
      isGameOver.value = true;
    }
  }

  void dispose() {
    _subscription.cancel();
    score.dispose();
    health.dispose();
    combo.dispose();
    multiplier.dispose();
    strikesRemaining.dispose();
    isGameOver.dispose();
  }
}
