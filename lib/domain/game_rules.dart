/// Tuning values for a play session. All gameplay numbers live here so the
/// balance of the game can be changed in one place.
class GameRules {
  const GameRules({
    this.maxHealth = 3,
    this.scorePerSlash = 10,
    this.baseSpeed = 40,
    this.speedPerPoint = 1.5,
    this.maxSpeed = 240,
    this.laneSpacing = 62,
    this.topPadding = 90,
    this.bottomPadding = 140,
    this.baseSpawnInterval = 2.2,
    this.minSpawnInterval = 0.8,
    this.spawnIntervalPerPoint = 0.02,
    this.slashGraceInterval = 0.6,
    this.comboWindow = 3.0,
    this.maxStrikes = 4,
    this.comboTiers = const [3, 6, 10],
    this.defenseLineX = 8,
  });

  final int maxHealth;
  final int scorePerSlash;
  final double baseSpeed;
  final double speedPerPoint;
  final double maxSpeed;
  final double laneSpacing;
  final double topPadding;
  final double bottomPadding;
  final double baseSpawnInterval;
  final double minSpawnInterval;
  final double spawnIntervalPerPoint;
  final double slashGraceInterval;
  final double comboWindow;
  final int maxStrikes;
  final List<int> comboTiers;
  final double defenseLineX;

  /// Score multiplier for the current streak length.
  int multiplierFor(int combo) {
    var multiplier = 1;
    for (var i = 0; i < comboTiers.length; i++) {
      if (combo >= comboTiers[i]) multiplier = i + 2;
    }
    return multiplier;
  }

  double speedFor(int score) {
    final speed = baseSpeed + score * speedPerPoint;
    return speed > maxSpeed ? maxSpeed : speed;
  }

  double spawnIntervalFor(int score) {
    final interval = baseSpawnInterval - score * spawnIntervalPerPoint;
    return interval < minSpawnInterval ? minSpawnInterval : interval;
  }

  int laneCount(double arenaHeight) {
    final usable = arenaHeight - topPadding - bottomPadding;
    if (usable <= 0) return 0;
    return (usable / laneSpacing).floor() + 1;
  }

  double laneY(int laneIndex, double arenaHeight) {
    final count = laneCount(arenaHeight);
    if (count <= 1) return topPadding + laneSpacing / 2;
    final usable = arenaHeight - topPadding - bottomPadding - laneSpacing;
    final step = usable / (count - 1);
    return topPadding + step * laneIndex;
  }
}
