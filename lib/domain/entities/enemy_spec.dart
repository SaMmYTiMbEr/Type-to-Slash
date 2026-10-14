import 'enemy_kind.dart';

/// What the spawner hands to the session: the word to type and what kind of
/// enemy carries it.
class EnemySpec {
  const EnemySpec({required this.word, this.kind = EnemyKind.standard});

  final String word;
  final EnemyKind kind;
}
