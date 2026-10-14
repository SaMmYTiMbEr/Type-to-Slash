# Type & Slash

Typing game built with Flutter + Flame. Enemies scroll in from the right; type
the word on top of one to slash it before it reaches your defense line.

## Architecture

Dependencies point inwards: `presentation -> domain <- data`. The domain layer is
pure Dart (no Flutter, no Flame) and holds every rule, so it is testable without
a widget tester.

```
lib/
  domain/                     pure Dart, zero framework imports
    entities/game_enemy.dart  one enemy: word, lane, position, typed prefix
    value_objects/            GameArena (play field size)
    repositories/             WordSource port
    game_rules.dart           all balance numbers + lane geometry
    game_events.dart          EnemySlashed / EnemyEscaped / PlayerDamaged / GameOver
    game_session.dart         the game loop, input handling, scoring, lives
  data/
    word_sources/             RandomWordSource, ScriptedWordSource (port impls)
  presentation/
    game/                     TypeAndSlashGame (Flame adapter), components, GameViewModel
    screens/                  MainMenuScreen, GameScreen
  main.dart                   composition root
```

Flow: `GameScreen` owns a `GameSession`, hands it to `TypeAndSlashGame` (which
drives `update(dt)` and renders components) and to `GameViewModel` (which turns
domain events into listenable HUD values). Nothing in `presentation` contains
game rules.

## Commands

```
flutter run
flutter test
flutter analyze
```

## Tests

- `test/domain/game_session_test.dart` — rules: matching, scoring, damage, game over
- `test/presentation/game_screen_test.dart` — menu, HUD, typing a word scores
