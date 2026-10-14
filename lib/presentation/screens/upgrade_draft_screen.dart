import 'package:flutter/material.dart';

import '../../domain/entities/upgrade.dart';
import '../stats/loadout_store.dart';

/// Between-runs draft: pick one of three upgrades that carry into the next
/// run.
class UpgradeDraftScreen extends StatelessWidget {
  const UpgradeDraftScreen({super.key, required this.loadoutStore});

  final LoadoutStore loadoutStore;

  @override
  Widget build(BuildContext context) {
    final offers = loadoutStore.offer();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose an upgrade')),
      body: offers.isEmpty
          ? const Center(child: Text('You already have every upgrade.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'This one carries into your next run.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                for (final upgrade in offers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UpgradeCard(
                      upgrade: upgrade,
                      onTap: () {
                        loadoutStore.select(upgrade);
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _UpgradeCard extends StatefulWidget {
  const _UpgradeCard({required this.upgrade, required this.onTap});

  final Upgrade upgrade;
  final VoidCallback onTap;

  @override
  State<_UpgradeCard> createState() => _UpgradeCardState();
}

class _UpgradeCardState extends State<_UpgradeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1055), Color(0xFF170A2E)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFFFFC107)
                  : const Color(0x33FFFFFF),
              width: _hovered ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFFC107),
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.upgrade.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.upgrade.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
