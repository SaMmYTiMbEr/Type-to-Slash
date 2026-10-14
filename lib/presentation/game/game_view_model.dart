import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/run_stats.dart';
import '../../domain/game_events.dart';
import '../../domain/game_session.dart';
import '../stats/stats_store.dart';

/// Exposes session state to the widget layer as listenable values, so screens
/// never read the session directly.
class GameViewModel {
  GameViewModel(this._session, {required this._statsStore}) {
    _subscription = _session.events.listen(_onEvent);
  }

  final GameSession _session;
  final StatsStore _statsStore;
  late final StreamSubscription<GameEvent> _subscription;

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> health = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(0);
  final ValueNotifier<int> multiplier = ValueNotifier(1);
  final ValueNotifier<int> strikesRemaining = ValueNotifier(0);
  final ValueNotifier<bool> isGameOver = ValueNotifier(false);
  final ValueNotifier<int> wave = ValueNotifier(1);
  final ValueNotifier<int?> targetEnemy = ValueNotifier(null);
  final ValueNotifier<RunStats?> runStats = ValueNotifier(null);
  final ValueNotifier<bool> isNewHighScore = ValueNotifier(false);

  int get maxHealth => _session.rules.maxHealth;

  int get maxStrikes => _session.rules.maxStrikes;

  /// Returns what the input did, so the caller can clear the field after a
  /// slash or after a typo, without the player pressing a submit key.
  SlashOutcome submit(String input) => _session.handleInput(input);

  void _onEvent(GameEvent event) {
    score.value = _session.score;
    health.value = _session.health;
    combo.value = _session.combo;
    multiplier.value = _session.multiplier;
    strikesRemaining.value = _session.strikesRemaining;
    wave.value = _session.wave;
    targetEnemy.value = _session.targetEnemyId;

    if (event is GameOver) {
      runStats.value = event.stats;
      isGameOver.value = true;
      unawaited(_recordRun(event.stats));
    }
  }

  Future<void> _recordRun(RunStats stats) async {
    isNewHighScore.value = await _statsStore.record(stats);
  }

  void dispose() {
    _subscription.cancel();
    score.dispose();
    health.dispose();
    combo.dispose();
    multiplier.dispose();
    strikesRemaining.dispose();
    isGameOver.dispose();
    runStats.dispose();
    isNewHighScore.dispose();
    wave.dispose();
    targetEnemy.dispose();
  }
}
