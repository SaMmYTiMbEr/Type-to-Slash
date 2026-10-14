import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/domain/entities/run_stats.dart';
import 'package:type_to_slash/domain/repositories/stats_repository.dart';
import 'package:type_to_slash/presentation/stats/stats_store.dart';

/// In-memory [StatsRepository] for tests.
class InMemoryStatsRepository implements StatsRepository {
  int bestScore = 0;
  final List<RunStats> runs = [];

  @override
  Future<int> loadBestScore() async => bestScore;

  @override
  Future<void> saveRun(RunStats stats) async {
    runs.add(stats);
    if (stats.score > bestScore) bestScore = stats.score;
  }
}

StatsStore createStatsStore({int bestScore = 0}) {
  final repository = InMemoryStatsRepository()..bestScore = bestScore;
  return StatsStore(repository, bestScore);
}
