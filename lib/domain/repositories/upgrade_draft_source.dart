import '../entities/upgrade.dart';

/// Port supplying upgrade cards for the between-runs draft.
abstract interface class UpgradeDraftSource {
  List<Upgrade> offer(Loadout loadout, {int count});

  /// The card for an owned upgrade, for display.
  Upgrade? byId(UpgradeId id);
}
