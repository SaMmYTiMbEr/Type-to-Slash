import 'package:flutter/material.dart';

import 'data/word_sources/random_word_source.dart';
import 'domain/game_session.dart';
import 'domain/value_objects/game_arena.dart';
import 'presentation/screens/game_screen.dart';
import 'presentation/screens/main_menu_screen.dart';

void main() => runApp(const TypeAndSlashApp());

/// Composition root: the only place that knows how concrete pieces fit
/// together.
class TypeAndSlashApp extends StatelessWidget {
  const TypeAndSlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Type & Slash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) => MainMenuScreen(
          onStart: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GameScreen(createSession: _createSession),
            ),
          ),
        ),
      ),
    );
  }
}

GameSession _createSession() =>
    GameSession(words: RandomWordSource(), arena: GameArena.empty);
