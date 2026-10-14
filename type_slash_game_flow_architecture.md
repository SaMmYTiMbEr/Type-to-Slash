# Type & Slash: Complete Game Flow & Architecture

This document describes the game flow, the architecture and the visual
rendering pipeline of "Type & Slash", built with Flutter and the Flame engine.

---

## 1. Game Flow Overview

The whole game is driven by a single `GameSession` and three screens:

1. **Start / Main Menu Screen**
   * The first screen shown when the app launches.
   * Pressing "Start Game" creates a fresh session and pushes the game screen.

2. **Game Play Loop (Active State)**
   * **Spawner system:** enemies appear on the right edge in the least crowded
     lane and drift left, each carrying a word above it.
   * **Player input (typing):** the player types into a Flutter `TextField` at
     the bottom of the screen. Every keystroke is fed straight into the
     session, so an enemy is slashed the instant the typed text completes its
     word - no submit key needed.
   * **Match check:** the typed prefix is compared against every live enemy.
     * **Match:** the enemy is destroyed (slash effect, shard burst, floating
       `+points`), the combo counter grows and the score increases.
     * **Partial match:** the typed prefix is highlighted in green.
     * **Mismatch:** a strike is registered, the combo resets, and four strikes
       cost a life.
   * **Pressure:** an enemy that crosses the defense line costs one life. When
     the last life is gone the session stops and reports `GameOver`.

3. **Game Over Screen (dialog)**
   * Shown when the player loses their last life.
   * Displays the final score and offers "Restart" or "Main Menu".

Bonus systems that run alongside the loop:

- **Combo multiplier** - consecutive slashes within the combo window multiply
  the score (x2, x3, x4).
- **Typo strikes** - four wrong inputs cost a life; a successful slash clears
  them.
- **Difficulty ramp** - enemy speed and spawn rate increase with the score.
- **Pause on blur** - the game loop pauses when the app is not in the
  foreground.

---

## 2. Technical Architecture & Components

The code is split into three layers with a single dependency rule:
`presentation -> domain <- data`. The domain layer is pure Dart and contains
every rule, so it can be tested without Flutter.

### Domain (`lib/domain`, pure Dart)

- **`GameSession`** - the game loop. Handles spawning, movement, input
  matching, scoring, combos, strikes and lives. Publishes `GameEvent`s on a
  stream and holds no rendering or widget state.
- **`GameEnemy`** - a single enemy: word, lane, position, typed prefix.
- **`GameRules`** - every balance number (lives, score, speed curve, spawn
  interval, combo tiers, strike limit) and the lane geometry.
- **`GameArena`** - the size of the play field.
- **`WordSource`** - a port (interface) supplying words to type.
- **`GameEvent`** - sealed events: `EnemySlashed`, `EnemyEscaped`,
  `PlayerDamaged`, `ComboChanged`, `TypoRegistered`, `GameOver`.

### Data (`lib/data`)

- **`RandomWordSource`** - random pick from the word pool.
- **`ScriptedWordSource`** - fixed sequence, used by tests for determinism.

### Presentation (`lib/presentation`)

- **`TypeAndSlashGame` (FlameGame)** - a thin adapter. It drives
  `session.update(dt)` from the Flame loop, mirrors the session's enemies onto
  components, and turns domain events into visual effects. It contains no game
  rules.
- **`GameViewModel`** - converts session events into listenable values
  (`score`, `health`, `combo`, `multiplier`, `strikesRemaining`,
  `isGameOver`) so widgets never read the session directly.
- **`EnemyComponent`** - renders one enemy: red word, green typed prefix,
  scale-in on spawn, idle bob, glow pulse while typing.
- **`SlashEffect` / `FloatingScoreText` / `DamageFlash`** - the feedback
  effects triggered by `EnemySlashed` and `PlayerDamaged`.
- **`BackgroundComponent`** - arena backdrop: gradient sky, drifting starfield,
  scrolling grid, vignette, defense line.
- **`MainMenuScreen` / `GameScreen`** - the UI. `GameScreen` stacks the
  `GameWidget`, the HUD (score, combo, hearts, strike pips) and the `TextField`
  with a `Stack`, and pauses the engine on lifecycle changes.

### Composition root

`lib/main.dart` is the only place that knows the concrete classes; it wires the
word source into the session and the session into the screens.

---

## 3. Code Implementation

### The game loop (domain)

```dart
class GameSession {
  SlashOutcome handleInput(String rawInput) {
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

    return hasProgress ? SlashOutcome.typed : _registerTypo();
  }

  void _slash(GameEnemy enemy) {
    _remove(enemy);
    _combo++;
    _comboTimer = rules.comboWindow;
    _strikes = 0;
    _score += rules.scorePerSlash * multiplier;
    _publish(EnemySlashed(enemyId: enemy.id, word: enemy.word, x: enemy.x, y: enemy.laneY, points: rules.scorePerSlash * multiplier));
    _publish(ComboChanged(combo: _combo, multiplier: multiplier));
  }
}
```

### The Flame adapter (presentation)

```dart
class TypeAndSlashGame extends FlameGame {
  TypeAndSlashGame({required this.session});

  final GameSession session;

  @override
  void update(double dt) {
    super.update(dt);
    session.update(dt);
    _syncEnemyViews();
  }

  void _onEvent(GameEvent event) {
    switch (event) {
      case EnemySlashed():
        add(SlashEffect(Vector2(event.x, event.y)));
        add(FloatingScoreText(label: '+${event.points}')
          ..position = Vector2(event.x, event.y));
      case EnemyEscaped():
      case PlayerDamaged():
        add(DamageFlash(area: Vector2(session.arena.width, session.arena.height)));
      case ComboChanged():
      case TypoRegistered():
      case GameOver():
        break;
    }
  }
}
```

### The UI (presentation)

```dart
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.createSession});

  final GameSession Function() createSession;
}

// Inside the widget tree:
GameWidget<TypeAndSlashGame>(game: _game),   // the Flame canvas
_Hud(viewModel: _viewModel),                  // score, combo, hearts, strikes
TextField(onChanged: _onChanged),             // live typing input
```

---

## 4. Visual Rendering Pipeline

How visuals and animations are handled:

- **Flame game loop:** every frame (`update(double dt)`) advances the session,
  and each component recomputes its own position and animation state.
- **Component animations:** spawn scale-in, idle vertical bob, typing glow,
  expanding slash ring, shard particles, rising score popups and the damage
  flash are all driven by per-component timers in `update`.
- **Flutter overlays:** the score, combo, health hearts, strike pips and the
  text input are native Flutter widgets layered on top of the canvas with a
  `Stack`, which keeps them crisp and accessible.

### Layer order

```
BackgroundComponent   sky, stars, grid, vignette, defense line
EnemyComponent        one per live enemy
SlashEffect           slash ring, streak, shards
FloatingScoreText     "+20" rising popup
DamageFlash           red screen pulse on damage (high priority)
Flutter overlay       HUD + TextField
```

### Performance notes

- Text painters are cached per word and rebuilt only when the typed prefix
  changes.
- Shards are lightweight `PositionComponent`s that remove themselves after
  ~0.55s, and effects are removed when their animation ends.
- The gradient and vignette shaders are rebuilt only when the arena is resized.
