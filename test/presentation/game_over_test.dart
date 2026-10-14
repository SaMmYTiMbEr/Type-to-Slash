import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/presentation/screens/game_screen.dart';
import 'package:type_to_slash/presentation/screens/main_menu_screen.dart';

import '../support/test_harness.dart';

void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  Future<void> advance(WidgetTester tester, int frames) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> playUntilGameOver(WidgetTester tester) async {
    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await advance(tester, 5);

    for (var i = 0; i < 400 && find.text('Game Over').evaluate().isEmpty; i++) {
      await advance(tester, 1);
    }
  }

  testWidgets('menu starts a game with HUD and input', (tester) async {
    await tester.pumpWidget(harness.menuApp());

    expect(find.text('TYPE & SLASH'), findsOneWidget);
    expect(find.text('No runs yet'), findsOneWidget);
    expect(
      find.text('No upgrades yet - finish a run to draft one'),
      findsOneWidget,
    );

    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await advance(tester, 5);

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Score:'), findsOneWidget);
    expect(find.text('Wave 1'), findsOneWidget);
  });

  testWidgets('game over dialog returns to the main menu', (tester) async {
    await tester.pumpWidget(harness.menuApp());
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
    await tester.pumpWidget(harness.menuApp());
    await playUntilGameOver(tester);

    await tester.tap(find.text('Restart'));
    await tester.pump();
    await advance(tester, 5);

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Game Over'), findsNothing);
    expect(find.text('Score: 0'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('dialog reports the run stats', (tester) async {
    await tester.pumpWidget(harness.menuApp());
    await playUntilGameOver(tester);
    await tester.pump();

    expect(find.text('Words slashed'), findsOneWidget);
    expect(find.text('Typos'), findsOneWidget);
    expect(find.text('Best combo'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('Survived'), findsOneWidget);
  });

  testWidgets('a finished run sets a new high score on the menu', (
    tester,
  ) async {
    await tester.pumpWidget(harness.menuApp());

    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await advance(tester, 10);

    await tester.enterText(find.byType(TextField), 'fire');
    await tester.pump();
    expect(find.text('Score: 10'), findsOneWidget);

    for (var i = 0; i < 400 && find.text('Game Over').evaluate().isEmpty; i++) {
      await advance(tester, 1);
    }
    await tester.pump();

    expect(find.text('NEW HIGH SCORE'), findsOneWidget);

    await tester.tap(find.text('Main Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Best score: 10'), findsOneWidget);
    expect(harness.statsStore.bestScore.value, 10);
  });

  testWidgets('drafting an upgrade records it on the menu', (tester) async {
    await tester.pumpWidget(harness.menuApp());
    await playUntilGameOver(tester);

    await tester.tap(find.text('Upgrade'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Choose an upgrade'), findsOneWidget);

    await tester.tap(find.text('Thick Skin').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(harness.loadoutStore.value.upgrades, isNotEmpty);
    expect(find.byType(MainMenuScreen), findsOneWidget);
    expect(find.text('Thick Skin'), findsWidgets);
  });
}
