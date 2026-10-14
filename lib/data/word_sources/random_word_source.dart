import 'dart:math';

import '../../domain/entities/enemy_kind.dart';
import '../../domain/entities/enemy_spec.dart';
import '../../domain/repositories/word_source.dart';

/// Random spawner: picks an enemy kind by weight, then a word from that kind's
/// pool.
class RandomWordSource implements WordSource {
  RandomWordSource({Map<EnemyKind, List<String>>? pools, Random? random})
    : _pools = pools ?? defaultPools,
      _random = random ?? Random();

  static const Map<EnemyKind, double> defaultWeights = {
    EnemyKind.standard: 0.62,
    EnemyKind.runner: 0.22,
    EnemyKind.bruiser: 0.11,
    EnemyKind.golden: 0.05,
  };

  static const Map<EnemyKind, List<String>> defaultPools = {
    EnemyKind.standard: [
      'fire',
      'ice',
      'storm',
      'slash',
      'blade',
      'wind',
      'shadow',
      'ember',
    ],
    EnemyKind.runner: ['dart', 'dash', 'rush', 'bolt', 'zip', 'punch', 'snap'],
    EnemyKind.bruiser: [
      'thunderstorm',
      'nightfall',
      'blizzard',
      'cataclysm',
      'aftermath',
    ],
    EnemyKind.golden: ['gold', 'star', 'coin', 'luck', 'gem'],
  };

  final Map<EnemyKind, List<String>> _pools;
  final Random _random;

  @override
  EnemySpec nextEnemy() {
    final kind = _pickKind();
    final pool = _pools[kind] ?? const <String>[];
    return EnemySpec(word: pool[_random.nextInt(pool.length)], kind: kind);
  }

  EnemyKind _pickKind() {
    final roll = _random.nextDouble();
    var cumulative = 0.0;
    for (final entry in defaultWeights.entries) {
      cumulative += entry.value;
      if (roll < cumulative) return entry.key;
    }
    return EnemyKind.standard;
  }
}

/// Cycles through a fixed word list, useful for deterministic runs and tests.
class ScriptedWordSource implements WordSource {
  ScriptedWordSource(this._words);

  final List<String> _words;
  int _index = 0;

  @override
  EnemySpec nextEnemy() {
    final word = _words[_index % _words.length];
    _index++;
    return EnemySpec(word: word);
  }
}

/// Cycles through fully specified enemies, for tests that need exact kinds.
class ScriptedEnemySource implements WordSource {
  ScriptedEnemySource(this._specs);

  final List<EnemySpec> _specs;
  int _index = 0;

  @override
  EnemySpec nextEnemy() {
    final spec = _specs[_index % _specs.length];
    _index++;
    return spec;
  }
}
