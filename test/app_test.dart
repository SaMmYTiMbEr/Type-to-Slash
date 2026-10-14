import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/main.dart';

import 'support/test_harness.dart';

void main() {
  testWidgets('app boots into the menu and starts a game', (tester) async {
    final harness = TestHarness();
    await tester.pumpWidget(
      TypeAndSlashApp(
        statsStore: harness.statsStore,
        loadoutStore: harness.loadoutStore,
      ),
    );

    expect(find.text('TYPE & SLASH'), findsOneWidget);

    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Score:'), findsOneWidget);
    expect(tester.takeException(), isNull);

    harness.dispose();
  });
}
