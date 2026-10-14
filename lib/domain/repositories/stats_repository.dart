import '../entities/run_stats.dart';

/// Port for persisting run results between sessions.
abstract interface class StatsRepository {
  Future<int> loadBestScore();

  /// Stores a run and keeps the best score seen so far.
  Future<void> saveRun(RunStats stats);
}
