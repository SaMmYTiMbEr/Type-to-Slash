/// An incoming enemy: the word the player must type, where it is and how far
/// the player has typed it.
class GameEnemy {
  GameEnemy({
    required this.id,
    required this.word,
    required this.lane,
    required this.laneY,
    required double x,
  }) {
    _x = x;
  }

  final int id;
  final String word;
  final int lane;
  final double laneY;

  double _x = 0;
  int _typedCharacters = 0;

  double get x => _x;

  int get typedCharacters => _typedCharacters;

  bool get isFullyTyped => _typedCharacters == word.length;

  void move(double dx) {
    _x += dx;
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
