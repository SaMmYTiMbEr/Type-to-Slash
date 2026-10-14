/// The upgrades a player can pick between runs. Ids live in the domain so the
/// rules can react to them; titles and descriptions live in the data catalog.
enum UpgradeId {
  thickSkin,
  doubleOrNothing,
  wideLanes,
  endlessCombo,
  forgiving,
  keenEyes,
}

class Upgrade {
  const Upgrade({
    required this.id,
    required this.title,
    required this.description,
  });

  final UpgradeId id;
  final String title;
  final String description;
}

/// The upgrades collected so far. Passed into every session so the rules can
/// be derived from it.
class Loadout {
  const Loadout([this.upgrades = const <UpgradeId>{}]);

  final Set<UpgradeId> upgrades;

  bool has(UpgradeId id) => upgrades.contains(id);

  bool get isEmpty => upgrades.isEmpty;

  Loadout select(UpgradeId id) => Loadout({...upgrades, id});

  @override
  bool operator ==(Object other) =>
      other is Loadout &&
      other.upgrades.length == upgrades.length &&
      other.upgrades.containsAll(upgrades);

  @override
  int get hashCode => Object.hashAllUnordered(upgrades);
}
