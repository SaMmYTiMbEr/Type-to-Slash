import 'dart:math' as math;

import 'entities/enemy_kind.dart';
import 'entities/upgrade.dart';

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
    this.waveScoreStep = 100,
    this.goldenLifetime = 4.0,
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
  final int waveScoreStep;
  final double goldenLifetime;
  final double defenseLineX;

  /// Derives the effective rules for a run from the base rules and the
  /// upgrades the player collected.
  factory GameRules.forLoadout(
    Loadout loadout, {
    GameRules base = const GameRules(),
  }) {
    final risky = loadout.has(UpgradeId.doubleOrNothing);
    final lives =
        base.maxHealth +
        (loadout.has(UpgradeId.thickSkin) ? 1 : 0) -
        (risky ? 1 : 0);

    return GameRules(
      maxHealth: math.max(1, lives),
      scorePerSlash: risky ? base.scorePerSlash * 2 : base.scorePerSlash,
      baseSpeed: loadout.has(UpgradeId.keenEyes)
          ? base.baseSpeed * 0.85
          : base.baseSpeed,
      speedPerPoint: base.speedPerPoint,
      maxSpeed: base.maxSpeed,
      laneSpacing: loadout.has(UpgradeId.wideLanes)
          ? base.laneSpacing * 1.4
          : base.laneSpacing,
      topPadding: base.topPadding,
      bottomPadding: base.bottomPadding,
      baseSpawnInterval: base.baseSpawnInterval,
      minSpawnInterval: base.minSpawnInterval,
      spawnIntervalPerPoint: base.spawnIntervalPerPoint,
      slashGraceInterval: base.slashGraceInterval,
      comboWindow: loadout.has(UpgradeId.endlessCombo)
          ? double.infinity
          : base.comboWindow,
      maxStrikes: loadout.has(UpgradeId.forgiving)
          ? base.maxStrikes + 2
          : base.maxStrikes,
      comboTiers: base.comboTiers,
      waveScoreStep: base.waveScoreStep,
      goldenLifetime: base.goldenLifetime,
      defenseLineX: base.defenseLineX,
    );
  }

  /// Score multiplier for the current streak length.
  int multiplierFor(int combo) {
    var multiplier = 1;
    for (var i = 0; i < comboTiers.length; i++) {
      if (combo >= comboTiers[i]) multiplier = i + 2;
    }
    return multiplier;
  }

  int waveFor(int score) => 1 + score ~/ waveScoreStep;

  double spawnIntervalFor(int score) {
    final interval = baseSpawnInterval - score * spawnIntervalPerPoint;
    return interval < minSpawnInterval ? minSpawnInterval : interval;
  }

  double speedFor(int score, EnemyKind kind) {
    final ramped = baseSpeed + score * speedPerPoint;
    final capped = ramped > maxSpeed ? maxSpeed : ramped;
    return capped * kind.speedMultiplier;
  }

  int pointsFor(EnemyKind kind, int combo) =>
      (scorePerSlash * kind.pointsMultiplier * multiplierFor(combo)).round();

  double? lifetimeFor(EnemyKind kind) =>
      kind.hasTimeLimit ? goldenLifetime : null;

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
