import 'dart:async';
import 'dart:math';

import 'entities/game_enemy.dart';
import 'game_events.dart';
import 'game_rules.dart';
import 'repositories/word_source.dart';
import 'value_objects/game_arena.dart';

enum SlashOutcome { ignored, typed, slashed, typo }

/// The heart of the game: all rules live here, with no knowledge of Flame or
/// Flutter. It advances with [update] and reacts to player input through
/// [handleInput], publishing results as [GameEvent]s.
class GameSession {
  GameSession({
    required this.words,
    GameArena arena = GameArena.empty,
    this.rules = const GameRules(),
    Random? random,
  }) : _random = random ?? Random(),
       _health = rules.maxHealth,
       _spawnCooldown = rules.slashGraceInterval {
    _arena = arena;
    _events = StreamController<GameEvent>.broadcast(sync: true);
  }

  final WordSource words;
  final GameRules rules;
  final Random _random;

  final List<GameEnemy> _enemies = [];

  GameArena _arena = GameArena.empty;
  late final StreamController<GameEvent> _events;
  int _score = 0;
  int _health;
  int _lastEnemyId = 0;
  int _combo = 0;
  int _strikes = 0;
  double _comboTimer = 0;
  double _spawnCooldown;
  bool _isGameOver = false;

  Stream<GameEvent> get events => _events.stream;

  int get score => _score;

  int get health => _health;

  int get combo => _combo;

  int get multiplier => rules.multiplierFor(_combo);

  int get strikes => _strikes;

  int get strikesRemaining => rules.maxStrikes - _strikes;

  bool get isGameOver => _isGameOver;

  GameArena get arena => _arena;

  List<GameEnemy> get enemies => List.unmodifiable(_enemies);

  void resize({required double width, required double height}) {
    _arena = GameArena(width: width, height: height);
  }

  /// Feeds the player's current input. A slash happens the instant the typed
  /// text completes an enemy word, so no submit key is required.
  SlashOutcome handleInput(String rawInput) {
    if (_isGameOver) return SlashOutcome.ignored;

    final input = rawInput.trim().toLowerCase();
    if (input.isEmpty) return SlashOutcome.ignored;

    GameEnemy? fullyTyped;
    var hasProgress = false;
    for (final enemy in _enemies) {
      if (!enemy.type(input)) continue;
      hasProgress = true;
      if (enemy.isFullyTyped && fullyTyped == null) fullyTyped = enemy;
    }

    if (fullyTyped != null) {
      _slash(fullyTyped);
      return SlashOutcome.slashed;
    }

    if (hasProgress) return SlashOutcome.typed;
    return _registerTypo();
  }

  SlashOutcome _registerTypo() {
    _resetCombo();
    _strikes++;
    _publish(
      TypoRegistered(strikes: _strikes, strikesRemaining: strikesRemaining),
    );
    if (_strikes >= rules.maxStrikes) {
      _strikes = 0;
      _damage();
    }
    return SlashOutcome.typo;
  }

  void _slash(GameEnemy enemy) {
    _remove(enemy);
    _combo++;
    _comboTimer = rules.comboWindow;
    _strikes = 0;
    _score += rules.scorePerSlash * multiplier;
    _spawnCooldown = rules.slashGraceInterval;
    _publish(
      EnemySlashed(
        enemyId: enemy.id,
        word: enemy.word,
        x: enemy.x,
        y: enemy.laneY,
        points: rules.scorePerSlash * multiplier,
      ),
    );
    _publish(ComboChanged(combo: _combo, multiplier: multiplier));
  }

  void _resetCombo() {
    if (_combo == 0) return;
    _combo = 0;
    _comboTimer = 0;
    _publish(const ComboChanged(combo: 0, multiplier: 1));
  }

  void update(double dt) {
    if (_isGameOver) return;

    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) _resetCombo();
    }

    _spawnCooldown -= dt;
    if (_spawnCooldown <= 0) {
      _spawn();
      _spawnCooldown = rules.spawnIntervalFor(_score);
    }

    final speed = rules.speedFor(_score);
    final escaped = <GameEnemy>[];
    for (final enemy in _enemies) {
      enemy.move(-speed * dt);
      if (enemy.hasReached(rules.defenseLineX)) escaped.add(enemy);
    }

    for (final enemy in escaped) {
      _remove(enemy);
      _publish(EnemyEscaped(enemyId: enemy.id, x: enemy.x, y: enemy.laneY));
      _damage();
      if (_isGameOver) return;
    }
  }

  void dispose() {
    _events.close();
  }

  void _spawn() {
    if (!_arena.hasArea) return;
    final lanes = rules.laneCount(_arena.height);
    if (lanes == 0) return;

    final lane = _pickLane(lanes);
    final enemy = GameEnemy(
      id: ++_lastEnemyId,
      word: words.nextWord(),
      lane: lane,
      laneY: rules.laneY(lane, _arena.height),
      x: _arena.width,
    );
    _enemies.add(enemy);
  }

  /// Chooses a lane with the fewest enemies so words never overlap.
  int _pickLane(int laneCount) {
    final occupancy = List<int>.filled(laneCount, 0);
    for (final enemy in _enemies) {
      if (enemy.lane < laneCount) occupancy[enemy.lane]++;
    }

    var fewest = occupancy.first;
    for (final count in occupancy) {
      if (count < fewest) fewest = count;
    }

    final free = <int>[
      for (var lane = 0; lane < laneCount; lane++)
        if (occupancy[lane] == fewest) lane,
    ];
    return free[_random.nextInt(free.length)];
  }

  void _remove(GameEnemy enemy) => _enemies.remove(enemy);

  void _damage() {
    _health -= 1;
    _publish(PlayerDamaged(_health));
    if (_health > 0) return;

    _health = 0;
    _isGameOver = true;
    _publish(GameOver(_score));
  }

  void _publish(GameEvent event) => _events.add(event);
}
