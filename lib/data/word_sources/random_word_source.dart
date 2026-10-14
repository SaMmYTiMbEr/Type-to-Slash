import 'dart:math';

import '../../domain/repositories/word_source.dart';

/// Default word pool plus random selection.
class RandomWordSource implements WordSource {
  RandomWordSource({List<String>? words, Random? random})
    : _words = List.unmodifiable(words ?? defaultWords),
      _random = random ?? Random();

  static const List<String> defaultWords = [
    'fire',
    'ice',
    'storm',
    'slash',
    'blade',
    'wind',
    'thunder',
    'shadow',
    'ember',
    'frost',
  ];

  final List<String> _words;
  final Random _random;

  @override
  String nextWord() => _words[_random.nextInt(_words.length)];
}

/// Cycles through a fixed list, useful for deterministic runs and tests.
class ScriptedWordSource implements WordSource {
  ScriptedWordSource(this._words);

  final List<String> _words;
  int _index = 0;

  @override
  String nextWord() {
    final word = _words[_index % _words.length];
    _index++;
    return word;
  }
}
