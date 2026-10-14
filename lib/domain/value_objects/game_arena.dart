/// Size of the play field, owned by the domain so that game rules never
/// depend on the rendering layer.
class GameArena {
  const GameArena({required this.width, required this.height});

  static const GameArena empty = GameArena(width: 0, height: 0);

  final double width;
  final double height;

  bool get hasArea => width > 0 && height > 0;
}
