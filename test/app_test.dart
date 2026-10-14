import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/main.dart';
import 'package:type_to_slash/presentation/screens/game_screen.dart';

void main() {
  testWidgets('app boots into the menu and starts a game', (tester) async {
    await tester.pumpWidget(const TypeAndSlashApp());

    expect(find.text('TYPE & SLASH'), findsOneWidget);

    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
