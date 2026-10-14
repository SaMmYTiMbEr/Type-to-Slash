import 'dart:async';
import 'dart:math';

import 'entities/game_enemy.dart';
import 'entities/run_stats.dart';
import 'entities/upgrade.dart';
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
    GameRules? baseRules,
    this.loadout = const Loadout(),
    Random? random,
  }) : _baseRules = baseRules ?? const GameRules(),
       _random = random ?? Random(),
       _wave = 1 {
    rules = GameRules.forLoadout(loadout, base: _baseRules);
    _health = rules.maxHealth;
    _spawnCooldown = rules.slashGraceInterval;
    _arena = arena;
    _events = StreamController<GameEvent>.broadcast(sync: true);
  }

  final WordSource words;
  final Loadout loadout;
  final GameRules _baseRules;
  final Random _random;

  late final GameRules rules;

  final List<GameEnemy> _enemies = [];

  GameArena _arena = GameArena.empty;
  late final StreamController<GameEvent> _events;
  int _score = 0;
  late int _health;
  int _lastEnemyId = 0;
  int _combo = 0;
  int _strikes = 0;
  int _wordsSlashed = 0;
  int _typos = 0;
  int _bestCombo = 0;
  int _wave;
  int? _targetEnemyId;
  double _elapsed = 0;
  double _comboTimer = 0;
  late double _spawnCooldown;
  bool _isGameOver = false;

  Stream<GameEvent> get events => _events.stream;

  int get score => _score;

  int get health => _health;

  int get combo => _combo;

  int get multiplier => rules.multiplierFor(_combo);

  int get strikes => _strikes;

  int get strikesRemaining => rules.maxStrikes - _strikes;

  int get wordsSlashed => _wordsSlashed;

  int get typos => _typos;

  int get bestCombo => _bestCombo;

  int get wave => _wave;

  Duration get elapsed => Duration(milliseconds: (_elapsed * 1000).round());

  RunStats get runStats => RunStats(
    score: _score,
    wordsSlashed: _wordsSlashed,
    typos: _typos,
    bestCombo: _bestCombo,
    duration: elapsed,
  );

  bool get isGameOver => _isGameOver;

  GameArena get arena => _arena;

  List<GameEnemy> get enemies => List.unmodifiable(_enemies);

  void resize({required double width, required double height}) {
    _arena = GameArena(width: width, height: height);
  }

  /// Feeds the player's current input. A slash happens the instant the typed
  /// text completes an enemy word, so no submit key is required. When several
  /// enemies match, the most urgent one (closest to the defense line) is hit.
  SlashOutcome handleInput(String rawInput) {
    if (_isGameOver) {
      _targetEnemyId = null;
      return SlashOutcome.ignored;
    }

    final input = rawInput.trim().toLowerCase();
    if (input.isEmpty) {
      _targetEnemyId = null;
      return SlashOutcome.ignored;
    }

    var hasProgress = false;
    for (final enemy in _enemies) {
      if (enemy.type(input)) hasProgress = true;
    }

    _targetEnemyId = _mostUrgent(input)?.id;

    final completed = _mostUrgent(input, requireFullWord: true);
    if (completed == null) {
      return hasProgress ? SlashOutcome.typed : _registerTypo();
    }

    _targetEnemyId = null;
    _slash(completed);
    return SlashOutcome.slashed;
  }

  /// The enemy the current input would slash: the most urgent one whose word
  /// starts with [rawInput]. Used by the UI to show what you are aiming at.
  int? targetFor(String rawInput) {
    if (_isGameOver) return null;
    final input = rawInput.trim().toLowerCase();
    if (input.isEmpty) return null;
    return _mostUrgent(input)?.id;
  }

  /// Id of the enemy currently highlighted as the target, if any.
  int? get targetEnemyId => _targetEnemyId;

  GameEnemy? _mostUrgent(String input, {bool requireFullWord = false}) {
    GameEnemy? best;
    for (final enemy in _enemies) {
      if (!enemy.word.startsWith(input)) continue;
      if (requireFullWord && enemy.word.length != input.length) continue;
      if (best == null || enemy.x < best.x) best = enemy;
    }
    return best;
  }

  SlashOutcome _registerTypo() {
    _resetCombo();
    _typos++;
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
    final points = rules.pointsFor(enemy.kind, _combo + 1);
    _remove(enemy);
    _combo++;
    _bestCombo = _combo > _bestCombo ? _combo : _bestCombo;
    _wordsSlashed++;
    _comboTimer = rules.comboWindow;
    _strikes = 0;
    _score += points;
    _spawnCooldown = rules.slashGraceInterval;
    _publish(
      EnemySlashed(
        enemyId: enemy.id,
        word: enemy.word,
        kind: enemy.kind,
        x: enemy.x,
        y: enemy.laneY,
        points: points,
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
    _elapsed += dt;

    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) _resetCombo();
    }

    _spawnCooldown -= dt;
    if (_spawnCooldown <= 0) {
      _spawn();
      _spawnCooldown = rules.spawnIntervalFor(_score);
    }

    final expired = <GameEnemy>[];
    final escaped = <GameEnemy>[];
    for (final enemy in _enemies) {
      enemy.advance(dt, rules.speedFor(_score, enemy.kind));
      if (enemy.hasReached(rules.defenseLineX)) {
        escaped.add(enemy);
      } else if (enemy.isExpired) {
        expired.add(enemy);
      }
    }

    for (final enemy in expired) {
      _remove(enemy);
      if (_targetEnemyId == enemy.id) _targetEnemyId = null;
      _publish(EnemyExpired(enemyId: enemy.id, x: enemy.x, y: enemy.laneY));
    }

    for (final enemy in escaped) {
      _remove(enemy);
      if (_targetEnemyId == enemy.id) _targetEnemyId = null;
      _publish(EnemyEscaped(enemyId: enemy.id, x: enemy.x, y: enemy.laneY));
      _damage();
      if (_isGameOver) return;
    }

    _updateWave();
  }

  void _updateWave() {
    final wave = rules.waveFor(_score);
    if (wave == _wave) return;
    _wave = wave;
    _publish(WaveStarted(wave));
  }

  void dispose() {
    _events.close();
  }

  void _spawn() {
    if (!_arena.hasArea) return;
    final lanes = rules.laneCount(_arena.height);
    if (lanes == 0) return;

    final lane = _pickLane(lanes);
    final spec = words.nextEnemy();
    final enemy = GameEnemy(
      id: ++_lastEnemyId,
      word: spec.word,
      kind: spec.kind,
      lane: lane,
      laneY: rules.laneY(lane, _arena.height),
      x: _arena.width,
      lifetime: rules.lifetimeFor(spec.kind),
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
    _publish(GameOver(runStats));
  }

  void _publish(GameEvent event) => _events.add(event);
}
