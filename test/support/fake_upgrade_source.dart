import 'dart:math';

import 'package:type_to_slash/domain/entities/upgrade.dart';
import 'package:type_to_slash/domain/repositories/upgrade_draft_source.dart';

class FakeUpgradeDraftSource implements UpgradeDraftSource {
  FakeUpgradeDraftSource({List<Upgrade>? upgrades})
    : _upgrades =
          upgrades ??
          const [
            Upgrade(
              id: UpgradeId.thickSkin,
              title: 'Thick Skin',
              description: '+1 life every run',
            ),
            Upgrade(
              id: UpgradeId.doubleOrNothing,
              title: 'Double or Nothing',
              description: 'Double points, but one less life',
            ),
            Upgrade(
              id: UpgradeId.wideLanes,
              title: 'Wide Lanes',
              description: 'Fewer, wider lanes to juggle',
            ),
            Upgrade(
              id: UpgradeId.endlessCombo,
              title: 'Endless Combo',
              description: 'Your combo never times out',
            ),
            Upgrade(
              id: UpgradeId.forgiving,
              title: 'Forgiving',
              description: 'Two extra typo strikes',
            ),
            Upgrade(
              id: UpgradeId.keenEyes,
              title: 'Keen Eyes',
              description: 'Enemies move 15% slower',
            ),
          ];

  final List<Upgrade> _upgrades;
  final Random _random = Random(7);

  @override
  List<Upgrade> offer(Loadout loadout, {int count = 3}) {
    final pool = _upgrades.where((u) => !loadout.has(u.id)).toList()
      ..shuffle(_random);
    return pool.take(count).toList();
  }

  @override
  Upgrade? byId(UpgradeId id) {
    for (final upgrade in _upgrades) {
      if (upgrade.id == id) return upgrade;
    }
    return null;
  }
}
