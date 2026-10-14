import 'package:flutter/foundation.dart';

import '../../domain/entities/upgrade.dart';
import '../../domain/repositories/upgrade_draft_source.dart';

/// Holds the upgrades collected across runs for the current play session.
class LoadoutStore extends ValueNotifier<Loadout> {
  LoadoutStore(this._draftSource, {Loadout loadout = const Loadout()})
    : super(loadout);

  final UpgradeDraftSource _draftSource;

  bool get hasOptions => _draftSource.offer(value, count: 1).isNotEmpty;

  /// Cards for the upgrades the player already owns, for display.
  List<Upgrade> get ownedUpgrades => [
    for (final id in value.upgrades) ?_draftSource.byId(id),
  ];

  List<Upgrade> offer({int count = 3}) =>
      _draftSource.offer(value, count: count);

  void select(Upgrade upgrade) => value = value.select(upgrade.id);
}
