import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/data/repositories/shared_preferences_stats_repository.dart';
import 'package:type_to_slash/domain/entities/run_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

RunStats statsWith({int score = 50, int typos = 2, int bestCombo = 3}) =>
    RunStats(
      score: score,
      wordsSlashed: 10,
      typos: typos,
      bestCombo: bestCombo,
      duration: const Duration(seconds: 42),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesStatsRepository', () {
    late SharedPreferencesStatsRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = SharedPreferencesStatsRepository(
        await SharedPreferences.getInstance(),
      );
    });

    test('starts with a zero best score', () async {
      expect(await repository.loadBestScore(), 0);
    });

    test('keeps the highest score across runs', () async {
      await repository.saveRun(statsWith(score: 120));
      expect(await repository.loadBestScore(), 120);

      await repository.saveRun(statsWith(score: 40));
      expect(await repository.loadBestScore(), 120);
    });

    test('stores the most recent runs first', () async {
      await repository.saveRun(statsWith(score: 10));
      await repository.saveRun(statsWith(score: 20));

      final history = repository.loadHistory();
      expect(history.map((run) => run.score), [20, 10]);
      expect(history.first.wordsSlashed, 10);
      expect(history.first.duration, const Duration(seconds: 42));
    });

    test('history is capped', () async {
      for (var i = 1; i <= 8; i++) {
        await repository.saveRun(statsWith(score: i));
      }

      final history = repository.loadHistory();
      expect(history.length, SharedPreferencesStatsRepository.historyLimit);
      expect(history.first.score, 8);
    });
  });

  group('RunStats', () {
    test('accuracy is share of slashed words', () {
      expect(statsWith(typos: 0).accuracy, 1);
      expect(statsWith(typos: 10).accuracy, closeTo(0.5, 0.001));
    });

    test('accuracy of an empty run is a full one', () {
      const empty = RunStats(
        score: 0,
        wordsSlashed: 0,
        typos: 0,
        bestCombo: 0,
        duration: Duration.zero,
      );

      expect(empty.accuracy, 1);
      expect(empty.attempts, 0);
    });
  });
}
