# Type & Slash

Typing game built with Flutter + Flame. Enemies scroll in from the right; type
the word on top of one to slash it before it reaches your defense line.

## Enemy types

| Kind | Speed | Points | Behaviour |
| --- | --- | --- | --- |
| Standard | 1x | 10 | The baseline enemy |
| Runner | 1.9x | 5 | Sprints in, punishes slow typing |
| Bruiser | 0.6x | 30 | Long words, big payout |
| Golden | 1.1x | 50 | Heartbeat glow, vanishes after 4s (no life lost) |

Every 100 points starts a new wave: a banner flashes and the background
palette shifts.

## Targeting

When several enemies share a typed prefix, the most urgent one (closest to the
defense line) is hit, and the enemy you are about to hit is marked with a pulsing
underline.

## Upgrades (roguelite draft)

After a run you draft one of three upgrades, which carry into later runs in the
same session and show as chips on the menu:

| Upgrade | Effect |
| --- | --- |
| Thick Skin | +1 life |
| Double or Nothing | Double points, one less life |
| Wide Lanes | Fewer, wider lanes |
| Endless Combo | Combo never times out |
| Forgiving | Two extra typo strikes |
| Keen Eyes | Enemies move 15% slower |

## Architecture

Dependencies point inwards: `presentation -> domain <- data`. The domain layer is
pure Dart (no Flutter, no Flame) and holds every rule, so it is testable without
a widget tester.

```
lib/
  domain/                     pure Dart, zero framework imports
    entities/game_enemy.dart  one enemy: word, lane, position, typed prefix
    entities/run_stats.dart   finished-run summary (score, accuracy, combo)
    value_objects/            GameArena (play field size)
    repositories/             WordSource, StatsRepository ports
    game_rules.dart           all balance numbers + lane geometry
    game_events.dart          EnemySlashed / EnemyEscaped / PlayerDamaged /
                              ComboChanged / TypoRegistered / GameOver
    game_session.dart         the game loop, input handling, scoring, lives
  data/
    word_sources/             RandomWordSource, ScriptedWordSource
    repositories/             SharedPreferencesStatsRepository
  presentation/
    game/                     TypeAndSlashGame (Flame adapter), components, GameViewModel
    stats/                    StatsStore (shared best score)
    screens/                  MainMenuScreen, GameScreen, GameOverDialog
  main.dart                   composition root
```

Flow: `GameScreen` owns a `GameSession`, hands it to `TypeAndSlashGame` (which
drives `update(dt)` and renders components) and to `GameViewModel` (which turns
domain events into listenable HUD values). On game over the view model records
the run through `StatsStore`, which persists it via the `StatsRepository` port
and updates the best score shown on the menu. Nothing in `presentation` contains
game rules.

## Commands

```
flutter run
flutter test
flutter analyze
```

## Tests

- `test/domain/game_session_test.dart` — rules: matching, scoring, damage, combo, typos, lanes, run stats
- `test/data/stats_repository_test.dart` — best score, run history, accuracy
- `test/presentation/` — menu, HUD, typing, game over stats, high score flow
