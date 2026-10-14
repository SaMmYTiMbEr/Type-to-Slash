import 'package:flutter/material.dart';

import '../../domain/entities/run_stats.dart';
import '../game/game_view_model.dart';

/// End-of-run summary: score, accuracy, best combo and a new-record badge.
class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.viewModel,
    required this.onRestart,
    required this.onMainMenu,
    this.onDraftUpgrade,
  });

  final GameViewModel viewModel;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final VoidCallback? onDraftUpgrade;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Game Over'),
      content: ValueListenableBuilder<RunStats?>(
        valueListenable: viewModel.runStats,
        builder: (context, stats, _) {
          if (stats == null) {
            return const SizedBox(height: 80);
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: viewModel.isNewHighScore,
                builder: (context, isBest, _) => isBest
                    ? const Text(
                        'NEW HIGH SCORE',
                        style: TextStyle(
                          color: Color(0xFFFFC107),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              _row('Score', '${stats.score}'),
              _row('Words slashed', '${stats.wordsSlashed}'),
              _row('Typos', '${stats.typos}'),
              _row('Best combo', 'x${stats.bestCombo}'),
              _row('Accuracy', '${(stats.accuracy * 100).round()}%'),
              _row('Survived', _formatDuration(stats.duration)),
            ],
          );
        },
      ),
      actions: [
        if (onDraftUpgrade != null)
          TextButton(onPressed: onDraftUpgrade, child: const Text('Upgrade')),
        TextButton(onPressed: onRestart, child: const Text('Restart')),
        FilledButton(onPressed: onMainMenu, child: const Text('Main Menu')),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
  }
}
