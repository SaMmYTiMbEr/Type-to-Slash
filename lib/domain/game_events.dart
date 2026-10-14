sealed class GameEvent {
  const GameEvent();
}

class EnemySlashed extends GameEvent {
  const EnemySlashed({
    required this.enemyId,
    required this.word,
    required this.x,
    required this.y,
    required this.points,
  });

  final int enemyId;
  final String word;
  final double x;
  final double y;
  final int points;
}

class EnemyEscaped extends GameEvent {
  const EnemyEscaped({required this.enemyId, required this.x, required this.y});

  final int enemyId;
  final double x;
  final double y;
}

class PlayerDamaged extends GameEvent {
  const PlayerDamaged(this.remainingHealth);

  final int remainingHealth;
}

class ComboChanged extends GameEvent {
  const ComboChanged({required this.combo, required this.multiplier});

  final int combo;
  final int multiplier;
}

class TypoRegistered extends GameEvent {
  const TypoRegistered({required this.strikes, required this.strikesRemaining});

  final int strikes;
  final int strikesRemaining;
}

class GameOver extends GameEvent {
  const GameOver(this.finalScore);

  final int finalScore;
}
