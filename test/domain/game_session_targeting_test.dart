import 'package:flutter_test/flutter_test.dart';
import 'package:type_to_slash/data/upgrades/upgrade_catalog.dart';
import 'package:type_to_slash/data/word_sources/random_word_source.dart';
import 'package:type_to_slash/domain/entities/enemy_kind.dart';
import 'package:type_to_slash/domain/entities/enemy_spec.dart';
import 'package:type_to_slash/domain/entities/upgrade.dart';
import 'package:type_to_slash/domain/game_events.dart';
import 'package:type_to_slash/domain/game_rules.dart';
import 'package:type_to_slash/domain/game_session.dart';

void main() {
  group('GameSession targeting', () {
    test('hits the most urgent enemy when several match', () {
      final session = GameSession(
        words: ScriptedEnemySource(const [
          EnemySpec(word: 'fire'),
          EnemySpec(word: 'fire'),
        ]),
        baseRules: const GameRules(baseSpeed: 20),
      );
      session.resize(width: 800, height: 600);

      session.update(1);
      session.update(3);
      final closest = session.enemies.first;
      final farther = session.enemies.last;

      expect(session.handleInput('fire'), SlashOutcome.slashed);
      expect(session.enemies.single.id, farther.id);
      expect(closest.id, isNot(farther.id));
    });

    test('a prefix highlights the target without slashing', () {
      final session = GameSession(
        words: ScriptedEnemySource(const [EnemySpec(word: 'fire')]),
      );
      session.resize(width: 800, height: 600);
      session.update(1);
      final enemy = session.enemies.single;

      expect(session.handleInput('fi'), SlashOutcome.typed);
      expect(session.targetEnemyId, enemy.id);
      expect(session.targetFor('fi'), enemy.id);
      expect(session.enemies, hasLength(1));
    });

    test('no target when the input matches nothing', () {
      final session = GameSession(
        words: ScriptedEnemySource(const [EnemySpec(word: 'fire')]),
      );
      session.resize(width: 800, height: 600);
      session.update(1);

      session.handleInput('zz');

      expect(session.targetEnemyId, isNull);
      expect(session.targetFor('zz'), isNull);
    });
  });

  group('GameRules.forLoadout', () {
    test('an empty loadout keeps the base rules', () {
      final rules = GameRules.forLoadout(const Loadout());

      expect(rules.maxHealth, 3);
      expect(rules.scorePerSlash, 10);
      expect(rules.comboWindow, 3);
      expect(rules.maxStrikes, 4);
    });

    test(
      'thickSkin adds a life, doubleOrNothing trades one for double points',
      () {
        final rules = GameRules.forLoadout(
          const Loadout({UpgradeId.thickSkin, UpgradeId.doubleOrNothing}),
        );

        expect(rules.maxHealth, 3);
        expect(rules.scorePerSlash, 20);
      },
    );

    test('keenEyes slows enemies and wideLanes widens the lanes', () {
      final rules = GameRules.forLoadout(
        const Loadout({UpgradeId.keenEyes, UpgradeId.wideLanes}),
      );

      expect(rules.baseSpeed, lessThan(const GameRules().baseSpeed));
      expect(rules.laneSpacing, greaterThan(const GameRules().laneSpacing));
      expect(rules.laneCount(600), lessThan(const GameRules().laneCount(600)));
    });

    test('endlessCombo never expires and forgiving adds strikes', () {
      final rules = GameRules.forLoadout(
        const Loadout({UpgradeId.endlessCombo, UpgradeId.forgiving}),
      );

      expect(rules.comboWindow, double.infinity);
      expect(rules.maxStrikes, 6);
    });

    test('lives never drop below one', () {
      final rules = GameRules.forLoadout(
        const Loadout({UpgradeId.doubleOrNothing}),
        base: const GameRules(maxHealth: 1),
      );

      expect(rules.maxHealth, 1);
    });
  });

  group('GameSession with a loadout', () {
    test('the session starts with the loadout lives', () {
      final session = GameSession(
        words: ScriptedWordSource(const ['fire']),
        loadout: const Loadout({UpgradeId.thickSkin}),
      );

      expect(session.health, 4);
      expect(session.rules.maxHealth, 4);
    });

    test('endlessCombo keeps the combo alive past the base window', () {
      final session = GameSession(
        words: ScriptedEnemySource(const [
          EnemySpec(word: 'fire'),
          EnemySpec(word: 'ice'),
        ]),
        baseRules: const GameRules(baseSpeed: 1),
        loadout: const Loadout({UpgradeId.endlessCombo}),
      );
      session.resize(width: 100000, height: 600);

      session.update(1);
      session.handleInput('fire');
      session.update(60);
      session.handleInput('ice');

      expect(session.combo, 2);
    });
  });

  group('UpgradeCatalog', () {
    test('offers upgrades the player does not own', () {
      final catalog = UpgradeCatalog();
      final offers = catalog.offer(const Loadout({UpgradeId.thickSkin}));

      expect(offers, hasLength(3));
      expect(
        offers.any((upgrade) => upgrade.id == UpgradeId.thickSkin),
        isFalse,
      );
    });

    test('never offers more than it has', () {
      final catalog = UpgradeCatalog();
      final everything = Loadout(
        UpgradeCatalog.all.map((upgrade) => upgrade.id).toSet(),
      );

      expect(catalog.offer(everything), isEmpty);
      expect(catalog.hasOptionsFor(everything), isFalse);
    });

    test('every upgrade is described and resolvable', () {
      final catalog = UpgradeCatalog();

      for (final upgrade in UpgradeCatalog.all) {
        expect(upgrade.title, isNotEmpty);
        expect(upgrade.description, isNotEmpty);
        expect(catalog.byId(upgrade.id)?.title, upgrade.title);
      }
    });
  });

  test('Loadout is immutable and comparable', () {
    const empty = Loadout();
    final withOne = empty.select(UpgradeId.keenEyes);

    expect(empty.isEmpty, isTrue);
    expect(withOne.upgrades, {UpgradeId.keenEyes});
    expect(withOne, const Loadout({UpgradeId.keenEyes}));
    expect(withOne.has(UpgradeId.keenEyes), isTrue);
  });

  test('a golden enemy that expires does not end the run', () {
    final session = GameSession(
      words: ScriptedEnemySource(const [
        EnemySpec(word: 'gold', kind: EnemyKind.golden),
      ]),
      baseRules: const GameRules(goldenLifetime: 1, baseSpeed: 1),
    );
    final events = <GameEvent>[];
    session.events.listen(events.add);
    session.resize(width: 4000, height: 600);

    session.update(2);

    expect(events.whereType<EnemyExpired>(), hasLength(1));
    expect(session.isGameOver, isFalse);
    expect(session.health, 3);
  });
}
