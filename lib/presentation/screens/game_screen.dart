import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../domain/game_session.dart';
import '../game/game_view_model.dart';
import '../game/type_and_slash_game.dart';
import '../stats/loadout_store.dart';
import '../stats/stats_store.dart';
import 'game_over_dialog.dart';
import 'upgrade_draft_screen.dart';

/// Hosts the Flame canvas and overlays the HUD and typing field.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.createSession,
    required this.statsStore,
    required this.loadoutStore,
  });

  final GameSession Function() createSession;
  final StatsStore statsStore;
  final LoadoutStore loadoutStore;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameSession _session;
  late final GameViewModel _viewModel;
  late final TypeAndSlashGame _game;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = widget.createSession();
    _viewModel = GameViewModel(_session, statsStore: widget.statsStore);
    _game = TypeAndSlashGame(session: _session);
    _viewModel.isGameOver.addListener(_showGameOverDialog);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.isGameOver.removeListener(_showGameOverDialog);
    _focusNode.dispose();
    _controller.dispose();
    _game.dispose();
    _viewModel.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_viewModel.isGameOver.value) return;
        _game.resumeEngine();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _focusNode.requestFocus(),
        );
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _game.pauseEngine();
    }
  }

  void _showGameOverDialog() {
    if (!mounted) return;
    _focusNode.unfocus();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameOverDialog(
        viewModel: _viewModel,
        onDraftUpgrade: widget.loadoutStore.hasOptions
            ? () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        UpgradeDraftScreen(loadoutStore: widget.loadoutStore),
                  ),
                );
              }
            : null,
        onRestart: () {
          Navigator.of(dialogContext).pop();
          _restart();
        },
        onMainMenu: () =>
            Navigator.of(dialogContext).popUntil((route) => route.isFirst),
      ),
    );
  }

  void _restart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          createSession: widget.createSession,
          statsStore: widget.statsStore,
          loadoutStore: widget.loadoutStore,
        ),
      ),
    );
  }

  void _onChanged(String value) {
    final outcome = _viewModel.submit(value);
    if (outcome == SlashOutcome.slashed || outcome == SlashOutcome.typo) {
      _clearField();
    }
  }

  void _onSubmitted(String value) {
    _viewModel.submit(value);
    _clearField();
  }

  void _clearField() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isGameOver = _viewModel.isGameOver.value;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GameWidget<TypeAndSlashGame>(game: _game),
          Positioned(
            top: 36,
            left: 20,
            right: 20,
            child: _Hud(viewModel: _viewModel),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !isGameOver,
              style: const TextStyle(fontSize: 20),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Type a word to slash...',
                filled: true,
                fillColor: const Color(0xD9FFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.viewModel});

  final GameViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: viewModel.score,
              builder: (context, score, _) => Text(
                'Score: $score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: viewModel.multiplier,
              builder: (context, multiplier, _) => AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: multiplier > 1 ? 1 : 0,
                child: ValueListenableBuilder<int>(
                  valueListenable: viewModel.combo,
                  builder: (context, combo, _) => Text(
                    'Combo x$multiplier  ($combo)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: viewModel.wave,
              builder: (context, wave, _) => Text(
                'Wave $wave',
                style: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: viewModel.health,
              builder: (context, health, _) => Row(
                children: [
                  for (var i = 0; i < viewModel.maxHealth; i++)
                    Icon(
                      Icons.favorite,
                      size: 22,
                      color: i < health
                          ? const Color(0xFFFF5252)
                          : const Color(0x33FFFFFF),
                    ),
                ],
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: viewModel.strikesRemaining,
              builder: (context, remaining, _) => Row(
                children: [
                  for (var i = 0; i < viewModel.maxStrikes; i++)
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: i < remaining
                          ? const Color(0xFFFFC107)
                          : const Color(0x33FFFFFF),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
