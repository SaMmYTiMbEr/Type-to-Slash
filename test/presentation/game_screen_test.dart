import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/data/word_sources/random_word_source.dart';
import 'package:type_to_slash/domain/game_session.dart';
import 'package:type_to_slash/presentation/screens/game_screen.dart';
import 'package:type_to_slash/presentation/screens/main_menu_screen.dart';

GameSession createTestSession() =>
    GameSession(words: ScriptedWordSource(const ['fire', 'ice']));

Widget buildMenu() => MaterialApp(
  home: Builder(
    builder: (context) => MainMenuScreen(
      onStart: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(createSession: createTestSession),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('main menu starts a game', (tester) async {
    await tester.pumpWidget(buildMenu());

    expect(find.text('TYPE & SLASH'), findsOneWidget);

    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Score:'), findsOneWidget);
  });

  testWidgets('typing a spawned word scores points', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(createSession: createTestSession)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), 'fire');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Score: 10'), findsOneWidget);
  });
}
