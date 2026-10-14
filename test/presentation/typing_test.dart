import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/presentation/screens/game_screen.dart';

import '../support/test_harness.dart';

void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  Future<void> startGame(WidgetTester tester) async {
    await tester.pumpWidget(harness.menuApp());
    await tester.tap(find.text('Start Game'));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('the input is focused as soon as the game starts', (
    tester,
  ) async {
    await tester.pumpWidget(harness.gameApp());
    await tester.pump();

    expect(
      tester
          .state<EditableTextState>(find.byType(EditableText))
          .widget
          .focusNode
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('keeps focus in the input after submitting a word', (
    tester,
  ) async {
    await startGame(tester);

    await tester.enterText(find.byType(TextField), 'fire');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
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
    await startGame(tester);

    for (final typed in ['f', 'fi', 'fir', 'fire']) {
      await tester.enterText(find.byType(TextField), typed);
      await tester.pump();
    }

    expect(find.text('Score: 10'), findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('a typo clears the input and spends a strike', (tester) async {
    await startGame(tester);

    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();

    expect(find.byIcon(Icons.error_outline), findsNWidgets(4));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('a partial match keeps the typed text', (tester) async {
    await startGame(tester);

    await tester.enterText(find.byType(TextField), 'fir');
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'fir',
    );
  });
}
