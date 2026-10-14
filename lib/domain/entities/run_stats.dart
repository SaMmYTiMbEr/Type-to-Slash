/// Result of a finished run, used for the score board and the high score.
class RunStats {
  const RunStats({
    required this.score,
    required this.wordsSlashed,
    required this.typos,
    required this.bestCombo,
    required this.duration,
  });

  final int score;
  final int wordsSlashed;
  final int typos;
  final int bestCombo;
  final Duration duration;

  int get attempts => wordsSlashed + typos;

  double get accuracy => attempts == 0 ? 1 : wordsSlashed / attempts;
}
