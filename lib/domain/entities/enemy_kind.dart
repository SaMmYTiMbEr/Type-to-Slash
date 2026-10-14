/// The enemy types the player can meet. The multipliers live here so the
/// domain decides how each kind behaves; data decides how often it spawns.
enum EnemyKind {
  standard(speedMultiplier: 1, pointsMultiplier: 1),
  runner(speedMultiplier: 1.9, pointsMultiplier: 0.5),
  bruiser(speedMultiplier: 0.6, pointsMultiplier: 3),
  golden(speedMultiplier: 1.1, pointsMultiplier: 5);

  const EnemyKind({
    required this.speedMultiplier,
    required this.pointsMultiplier,
  });

  final double speedMultiplier;
  final double pointsMultiplier;

  /// Golden enemies vanish after their lifetime instead of costing a life.
  bool get hasTimeLimit => this == EnemyKind.golden;
}
