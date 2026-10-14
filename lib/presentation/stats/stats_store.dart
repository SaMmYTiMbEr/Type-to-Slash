import 'package:flutter/foundation.dart';

import '../../domain/entities/run_stats.dart';
import '../../domain/repositories/stats_repository.dart';

/// Shared, screen-agnostic access to the best score, so the menu and the game
/// screen agree on it without talking to each other.
class StatsStore {
  StatsStore(this._repository, int initialBestScore)
    : bestScore = ValueNotifier(initialBestScore);

  final StatsRepository _repository;

  final ValueNotifier<int> bestScore;

  /// Records a finished run. Returns true when it beat the previous best.
  Future<bool> record(RunStats stats) async {
    final isBest = stats.score > bestScore.value;
    await _repository.saveRun(stats);
    if (isBest) bestScore.value = stats.score;
    return isBest;
  }

  void dispose() => bestScore.dispose();
}
