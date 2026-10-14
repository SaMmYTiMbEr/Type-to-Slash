import 'dart:math';

import '../../domain/entities/upgrade.dart';
import '../../domain/repositories/upgrade_draft_source.dart';

/// The upgrades the draft can offer, with their player-facing text.
class UpgradeCatalog implements UpgradeDraftSource {
  UpgradeCatalog({this.random});

  final Random? random;
  static const List<Upgrade> all = [
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

  @override
  List<Upgrade> offer(Loadout loadout, {int count = 3}) {
    final pool = availableFor(loadout)..shuffle(random);
    return pool.take(count).toList();
  }

  /// Upgrades the player has not taken yet.
  List<Upgrade> availableFor(Loadout loadout) => [
    for (final upgrade in all)
      if (!loadout.has(upgrade.id)) upgrade,
  ];

  @override
  Upgrade? byId(UpgradeId id) {
    for (final upgrade in all) {
      if (upgrade.id == id) return upgrade;
    }
    return null;
  }

  bool hasOptionsFor(Loadout loadout) => availableFor(loadout).isNotEmpty;
}
