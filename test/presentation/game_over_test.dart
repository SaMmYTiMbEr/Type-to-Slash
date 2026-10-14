import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/data/word_sources/random_word_source.dart';
import 'package:type_to_slash/domain/game_session.dart';
import 'package:type_to_slash/presentation/screens/game_screen.dart';
import 'package:type_to_slash/presentation/screens/main_menu_screen.dart';

Widget buildApp() => MaterialApp(
  home: Builder(
    builder: (context) => MainMenuScreen(
      onStart: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            createSession: () =>
                GameSession(words: ScriptedWordSource(const ['fire'])),
          ),
        ),
      ),
    ),
  ),
);

Future<void> playUntilGameOver(WidgetTester tester) async {
  await tester.tap(find.text('Start Game'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  for (var i = 0; i < 12 && find.text('Game Over').evaluate().isEmpty; i++) {
    await tester.pump(const Duration(seconds: 5));
  }
}

void main() {
  testWidgets('game over dialog returns to the main menu', (tester) async {
    await tester.pumpWidget(buildApp());
    await playUntilGameOver(tester);

    expect(find.text('Game Over'), findsOneWidget);

    await tester.tap(find.text('Main Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Game Over'), findsNothing);
    expect(find.byType(MainMenuScreen), findsOneWidget);
    expect(find.text('TYPE & SLASH'), findsOneWidget);
  });

  testWidgets('restart starts a fresh session', (tester) async {
    await tester.pumpWidget(buildApp());
    await playUntilGameOver(tester);

    await tester.tap(find.text('Restart'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Game Over'), findsNothing);
    expect(find.text('Score: 0'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
}
