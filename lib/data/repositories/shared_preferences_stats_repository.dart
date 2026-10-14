import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/run_stats.dart';
import '../../domain/repositories/stats_repository.dart';

/// Keeps the best score and a short history of recent runs on the device.
class SharedPreferencesStatsRepository implements StatsRepository {
  SharedPreferencesStatsRepository(this._preferences);

  static const String bestScoreKey = 'stats.bestScore';
  static const String runsKey = 'stats.recentRuns';
  static const int historyLimit = 5;

  final SharedPreferences _preferences;

  @override
  Future<int> loadBestScore() async => _preferences.getInt(bestScoreKey) ?? 0;

  @override
  Future<void> saveRun(RunStats stats) async {
    final best = await loadBestScore();
    if (stats.score > best) {
      await _preferences.setInt(bestScoreKey, stats.score);
    }

    final history = _readHistory()..insert(0, stats);
    if (history.length > historyLimit) {
      history.removeRange(historyLimit, history.length);
    }
    await _preferences.setStringList(
      runsKey,
      history.map(_encode).toList(growable: false),
    );
  }

  List<RunStats> loadHistory() => _readHistory();

  List<RunStats> _readHistory() {
    final stored = _preferences.getStringList(runsKey) ?? const [];
    return [for (final run in stored) _decode(run)];
  }

  String _encode(RunStats stats) => [
    stats.score,
    stats.wordsSlashed,
    stats.typos,
    stats.bestCombo,
    stats.duration.inMilliseconds,
  ].join(',');

  RunStats _decode(String run) {
    final parts = run.split(',').map(int.parse).toList(growable: false);
    return RunStats(
      score: parts[0],
      wordsSlashed: parts[1],
      typos: parts[2],
      bestCombo: parts[3],
      duration: Duration(milliseconds: parts[4]),
    );
  }
}
