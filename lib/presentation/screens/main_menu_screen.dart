import '../../domain/entities/upgrade.dart';

import 'package:flutter/material.dart';

import '../stats/loadout_store.dart';
import '../stats/stats_store.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    super.key,
    required this.statsStore,
    required this.loadoutStore,
    required this.onStart,
  });

  final StatsStore statsStore;
  final LoadoutStore loadoutStore;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1055), Color(0xFF0B0716)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TYPE & SLASH',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Type the words to slash the enemies',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: statsStore.bestScore,
                  builder: (context, best, _) => Text(
                    best == 0 ? 'No runs yet' : 'Best score: $best',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<Loadout>(
                  valueListenable: loadoutStore,
                  builder: (context, loadout, _) => SizedBox(
                    height: 64,
                    child: loadout.isEmpty
                        ? const Text(
                            'No upgrades yet - finish a run to draft one',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          )
                        : Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final upgrade in loadoutStore.ownedUpgrades)
                                Chip(
                                  label: Text(
                                    upgrade.title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF3A1D6E),
                                  side: const BorderSide(
                                    color: Color(0xFFFFC107),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'Start Game',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 42,
                      vertical: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
