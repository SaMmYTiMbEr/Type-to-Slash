import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/data/word_sources/random_word_source.dart';
import 'package:type_to_slash/domain/game_session.dart';
import 'package:type_to_slash/presentation/screens/game_screen.dart';

void main() {
  testWidgets('keeps focus in the input after submitting a word', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          createSession: () =>
              GameSession(words: ScriptedWordSource(const ['fire'])),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), 'fire');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(
      tester
          .state<EditableTextState>(find.byType(EditableText))
          .widget
          .focusNode
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('slashes as soon as the word is typed, without a submit key', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          createSession: () =>
              GameSession(words: ScriptedWordSource(const ['fire'])),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    for (final typed in ['f', 'fi', 'fir', 'fire']) {
      await tester.enterText(find.byType(TextField), typed);
      await tester.pump();
    }

    expect(find.text('Score: 10'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('a typo spends a strike', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          createSession: () =>
              GameSession(words: ScriptedWordSource(const ['fire'])),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();

    expect(find.byIcon(Icons.error_outline), findsNWidgets(4));
  });
}
