import 'package:flutter/material.dart';
import 'package:type_to_slash/data/word_sources/random_word_source.dart';
import 'package:type_to_slash/domain/game_session.dart';
import 'package:type_to_slash/presentation/screens/game_screen.dart';
import 'package:type_to_slash/presentation/screens/main_menu_screen.dart';
import 'package:type_to_slash/presentation/stats/loadout_store.dart';
import 'package:type_to_slash/presentation/stats/stats_store.dart';

import 'fake_stats_repository.dart';
import 'fake_upgrade_source.dart';

/// Wires the real screens with test doubles for storage.
class TestHarness {
  TestHarness()
    : statsStore = createStatsStore(),
      loadoutStore = LoadoutStore(FakeUpgradeDraftSource());

  final StatsStore statsStore;
  final LoadoutStore loadoutStore;

  static GameSession scriptedSession([List<String> words = const ['fire']]) =>
      GameSession(words: ScriptedWordSource(words));

  Widget menuApp() => MaterialApp(
    home: Builder(
      builder: (context) => MainMenuScreen(
        statsStore: statsStore,
        loadoutStore: loadoutStore,
        onStart: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => gameScreen(sessionFactory: scriptedSession),
          ),
        ),
      ),
    ),
  );

  Widget gameApp({GameSession Function()? sessionFactory}) => MaterialApp(
    home: gameScreen(sessionFactory: sessionFactory ?? scriptedSession),
  );

  Widget gameScreen({GameSession Function()? sessionFactory}) => GameScreen(
    createSession: sessionFactory ?? scriptedSession,
    statsStore: statsStore,
    loadoutStore: loadoutStore,
  );

  void dispose() {
    statsStore.dispose();
    loadoutStore.dispose();
  }
}
