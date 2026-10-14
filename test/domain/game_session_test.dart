import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/data/word_sources/random_word_source.dart';
import 'package:type_to_slash/domain/game_events.dart';
import 'package:type_to_slash/domain/game_rules.dart';
import 'package:type_to_slash/domain/game_session.dart';

GameSession _session({
  GameRules rules = const GameRules(),
  List<String> words = const ['fire', 'ice'],
}) {
  return GameSession(words: ScriptedWordSource(words), rules: rules);
}

void main() {
  group('GameSession input', () {
    test('ignores empty input', () {
      final session = _session();
      session.resize(width: 800, height: 600);

      expect(session.handleInput('   '), SlashOutcome.ignored);
      expect(session.score, 0);
    });

    test('input that is not a prefix counts as a typo', () {
      final session = _session();
      session.resize(width: 800, height: 600);
      session.update(10);

      expect(session.handleInput('zzz'), SlashOutcome.typo);
      expect(session.strikes, 1);
      expect(session.score, 0);
    });

    test('too many typos cost a life', () {
      final session = _session(rules: const GameRules(maxStrikes: 3));
      final damaged = <PlayerDamaged>[];
      session.events.listen((event) {
        if (event is PlayerDamaged) damaged.add(event);
      });
      session.resize(width: 800, height: 600);
      session.update(10);

      session.handleInput('q');
      session.handleInput('q');
      expect(session.health, 3);
      session.handleInput('q');

      expect(session.health, 2);
      expect(session.strikes, 0);
      expect(damaged.single.remainingHealth, 2);
    });

    test('slashing clears the typo strikes', () {
      final session = _session();
      session.resize(width: 800, height: 600);
      session.update(10);

      session.handleInput('q');
      expect(session.strikes, 1);

      session.handleInput('fire');

      expect(session.strikes, 0);
    });

    test('typing a prefix reports progress without scoring', () {
      final session = _session();
      session.resize(width: 800, height: 600);
      session.update(10);

      expect(session.enemies, isNotEmpty);
      expect(session.handleInput('fi'), SlashOutcome.typed);
      expect(session.enemies.single.typedCharacters, 2);
      expect(session.score, 0);
    });

    test('completing the word slashes the enemy and scores', () {
      final session = _session();
      session.resize(width: 800, height: 600);
      session.update(10);
      final slashed = <EnemySlashed>[];
      session.events.listen((event) {
        if (event is EnemySlashed) slashed.add(event);
      });

      expect(session.handleInput('FiRe '), SlashOutcome.slashed);
      expect(session.enemies, isEmpty);
      expect(session.score, 10);
      expect(slashed.single.word, 'fire');
    });

    test('input that is not a prefix does not change progress', () {
      final session = _session();
      session.resize(width: 800, height: 600);
      session.update(10);

      expect(session.handleInput('fi'), SlashOutcome.typed);
      expect(session.handleInput('x'), SlashOutcome.typo);
      expect(session.enemies.single.typedCharacters, 2);
    });
  });

  group('GameSession combo', () {
    test('consecutive slashes raise the score multiplier', () {
      final session = _session(
        words: const ['fire', 'ice'],
        rules: const GameRules(
          comboWindow: 30,
          baseSpawnInterval: 0.1,
          minSpawnInterval: 0.1,
        ),
      );
      final combos = <ComboChanged>[];
      session.events.listen((event) {
        if (event is ComboChanged) combos.add(event);
      });
      session.resize(width: 800, height: 600);

      for (var i = 0; i < 4; i++) {
        session.update(1);
        session.handleInput(i.isEven ? 'fire' : 'ice');
      }

      expect(session.combo, 4);
      expect(session.multiplier, 2);
      expect(combos.last.multiplier, 2);
      expect(session.score, 60);
    });

    test('a typo resets the combo', () {
      final session = _session();
      session.resize(width: 800, height: 600);

      session.update(10);
      session.handleInput('fire');
      expect(session.combo, 1);

      session.handleInput('q');

      expect(session.combo, 0);
      expect(session.multiplier, 1);
    });

    test('the combo expires after the combo window', () {
      final session = _session(rules: const GameRules(comboWindow: 2));
      session.resize(width: 800, height: 600);
      session.update(10);
      session.handleInput('fire');
      expect(session.combo, 1);

      session.update(3);

      expect(session.combo, 0);
    });
  });

  group('GameSession spawning', () {
    test('enemies never share a lane while lanes are free', () {
      final session = _session(words: const ['fire', 'ice']);
      session.resize(width: 800, height: 600);

      final laneCount = const GameRules().laneCount(600);
      for (var i = 0; i < laneCount; i++) {
        session.update(3);
      }

      final lanes = session.enemies.map((enemy) => enemy.lane).toSet();
      expect(lanes.length, session.enemies.length);
      expect(lanes.length, laneCount);
    });
  });

  group('GameSession pressure', () {
    test('enemies that cross the line cost one life each', () {
      final session = _session();
      final damaged = <PlayerDamaged>[];
      session.events.listen((event) {
        if (event is PlayerDamaged) damaged.add(event);
      });
      session.resize(width: 100, height: 600);

      session.update(10);
      session.update(10);
      session.update(10);
      session.update(10);

      expect(session.health, lessThan(3));
      expect(damaged, isNotEmpty);
      expect(session.enemies, isEmpty);
    });

    test('game over is emitted once the last life is gone', () {
      final session = _session();
      final events = <GameEvent>[];
      session.events.listen(events.add);
      session.resize(width: 100, height: 600);

      for (var i = 0; i < 10; i++) {
        session.update(1);
      }

      expect(session.isGameOver, isTrue);
      expect(session.health, 0);
      expect(events.whereType<GameOver>().single.finalScore, 0);
    });

    test('no updates are applied after game over', () {
      final session = _session();
      session.resize(width: 100, height: 600);
      for (var i = 0; i < 10; i++) {
        session.update(1);
      }

      session.update(10);

      expect(session.enemies, isEmpty);
      expect(session.handleInput('fire'), SlashOutcome.ignored);
    });
  });

  group('GameRules', () {
    test('speed and spawn interval grow with score but stay bounded', () {
      const rules = GameRules();

      expect(rules.speedFor(0), rules.baseSpeed);
      expect(rules.speedFor(100000), rules.maxSpeed);
      expect(rules.spawnIntervalFor(0), rules.baseSpawnInterval);
      expect(rules.spawnIntervalFor(100000), rules.minSpawnInterval);
    });

    test('lane geometry stays inside the arena', () {
      const rules = GameRules();

      expect(rules.laneCount(100), 0);
      expect(rules.laneY(0, 600), greaterThanOrEqualTo(rules.topPadding));
      final lastLane = rules.laneCount(600) - 1;
      expect(
        rules.laneY(lastLane, 600),
        lessThanOrEqualTo(600 - rules.bottomPadding),
      );
    });
  });

  test('RandomWordSource only yields words from its pool', () {
    final source = RandomWordSource();

    for (var i = 0; i < 50; i++) {
      expect(RandomWordSource.defaultWords, contains(source.nextWord()));
    }
  });
}
