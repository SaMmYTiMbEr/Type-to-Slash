import 'enemy_kind.dart';

/// An incoming enemy: the word the player must type, where it is, how far the
/// player has typed it and, for golden enemies, how long it stays alive.
class GameEnemy {
  GameEnemy({
    required this.id,
    required this.word,
    required this.kind,
    required this.lane,
    required this.laneY,
    required double x,
    this.lifetime,
  }) {
    _x = x;
  }

  final int id;
  final String word;
  final EnemyKind kind;
  final int lane;
  final double laneY;

  /// Seconds before the enemy disappears on its own, or null when it stays
  /// until it is slashed or reaches the defense line.
  final double? lifetime;

  double _x = 0;
  double _age = 0;
  int _typedCharacters = 0;

  double get x => _x;

  double get age => _age;

  int get typedCharacters => _typedCharacters;

  bool get isFullyTyped => _typedCharacters == word.length;

  bool get isExpired => lifetime != null && _age >= lifetime!;

  void advance(double dt, double speed) {
    _age += dt;
    _x -= speed * dt;
  }

  /// Applies the player's typed prefix. Returns true when it is a prefix of
  /// this enemy's word, false otherwise.
  bool type(String input) {
    if (input.isEmpty || input.length > word.length) return false;
    if (!word.startsWith(input)) return false;
    _typedCharacters = input.length;
    return true;
  }

  bool hasReached(double lineX) => _x <= lineX;
}
