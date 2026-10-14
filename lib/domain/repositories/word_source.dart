import '../entities/enemy_spec.dart';

/// Port supplying the enemies the player has to type.
abstract interface class WordSource {
  EnemySpec nextEnemy();
}
