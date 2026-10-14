import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/shared_preferences_stats_repository.dart';
import 'data/upgrades/upgrade_catalog.dart';
import 'data/word_sources/random_word_source.dart';
import 'domain/game_session.dart';
import 'domain/value_objects/game_arena.dart';
import 'presentation/screens/game_screen.dart';
import 'presentation/screens/main_menu_screen.dart';
import 'presentation/stats/loadout_store.dart';
import 'presentation/stats/stats_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final statsRepository = SharedPreferencesStatsRepository(preferences);

  runApp(
    TypeAndSlashApp(
      statsStore: StatsStore(
        statsRepository,
        await statsRepository.loadBestScore(),
      ),
      loadoutStore: LoadoutStore(UpgradeCatalog()),
    ),
  );
}

/// Composition root: the only place that knows how concrete pieces fit
/// together.
class TypeAndSlashApp extends StatelessWidget {
  const TypeAndSlashApp({
    super.key,
    required this.statsStore,
    required this.loadoutStore,
  });

  final StatsStore statsStore;
  final LoadoutStore loadoutStore;

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
          statsStore: statsStore,
          loadoutStore: loadoutStore,
          onStart: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GameScreen(
                createSession: () => GameSession(
                  words: RandomWordSource(),
                  arena: GameArena.empty,
                  loadout: loadoutStore.value,
                ),
                statsStore: statsStore,
                loadoutStore: loadoutStore,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
