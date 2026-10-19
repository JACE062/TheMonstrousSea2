import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/svg_asset_view.dart';

/// Screen for naming the captain and commissioning a starting vessel.
class CaptainScreen extends StatefulWidget {
  const CaptainScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<CaptainScreen> createState() => _CaptainScreenState();
}

class _CaptainScreenState extends State<CaptainScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Eldred Thorne');
  ShipClass _selectedClass = ShipClass.standard;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCommission() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    widget.controller.dispatch(NameCaptain(name));
    // If not Davy Jones cheat easter egg (which automatically equips Dutchman), commission chosen ship
    if (widget.controller.ship == null) {
      widget.controller.dispatch(ChooseShip(_selectedClass));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'COMMISSION OF VOYAGE',
                  style: InkTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Charter your name and select the vessel for this generation\'s voyage.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Captain Name Input
                ParchmentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CAPTAIN\'S NAME & TITLE', style: InkTheme.statLabel),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: InkTheme.titleMedium.copyWith(fontSize: 22),
                        decoration: InputDecoration(
                          hintText: 'Enter Captain Name...',
                          hintStyle: InkTheme.caption.copyWith(fontSize: 18),
                          filled: true,
                          fillColor: InkTheme.parchmentHighlight,
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(color: InkTheme.inkPrimary, width: 1.5),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: InkTheme.goldAccent, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Ship Class Options
                Text('CHOOSE STARTING VESSEL', style: InkTheme.statLabel),
                const SizedBox(height: 8),
                Row(
                  children: ShipClass.values.map((shipClass) {
                    final isSelected = _selectedClass == shipClass;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Semantics(
                          button: true,
                          selected: isSelected,
                          label: '${shipClass.name.toUpperCase()} vessel',
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedClass = shipClass;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? InkTheme.parchmentHighlight : InkTheme.parchmentSurface,
                                border: Border.all(
                                  color: isSelected ? InkTheme.goldAccent : InkTheme.inkMuted,
                                  width: isSelected ? 2.5 : 1.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                shipClass.name.toUpperCase(),
                                style: InkTheme.statLabel.copyWith(
                                  color: isSelected ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Selected Ship Preview Card
                ParchmentCard(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgAssetView(
                            assetPath: SvgAssetView.pathForShip(_selectedClass),
                            width: 110,
                            height: 110,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _shipTitle(_selectedClass),
                                  style: InkTheme.titleMedium.copyWith(fontSize: 22),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _shipDescription(_selectedClass),
                                  style: InkTheme.body.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceAround,
                        children: _buildStatColumns(_selectedClass),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Embark Button
                InkButton(
                  label: 'COMMISSION & SET SAIL',
                  isPrimary: true,
                  onPressed: _onCommission,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shipTitle(ShipClass sClass) => switch (sClass) {
        ShipClass.standard => 'Standard Naval Barque',
        ShipClass.freighter => 'Armored Heavy Freighter',
        ShipClass.ironclad => 'Steam-Plated Ironclad',
        ShipClass.corvette => 'Wind-Skimming Corvette',
        ShipClass.clipper => 'Razor Clipper Skiff',
        ShipClass.bombardier => 'Siege Bombardier Barque',
        ShipClass.corsair => 'Tactical Corsair Sloop',
      };

  String _shipDescription(ShipClass sClass) => switch (sClass) {
        ShipClass.standard =>
          'A balanced all-rounder vessel. Reliable cannon mounts and steady hull construction.',
        ShipClass.freighter =>
          'Massive hold capacity designed for trade and looting. Survives with safe stash carrying 5% gold & cargo to heirs.',
        ShipClass.ironclad =>
          'Heavy reinforced armor plates. Features Fortify trait and prow ram that shatters monster carapace.',
        ShipClass.corvette =>
          'Raked sails built for supreme speed. Features Evasion trait: naturally dodges strikes and maneuvers.',
        ShipClass.clipper =>
          'Streamlined racer mounting a Precision Culverin. Surgical critical strikes ignore 50% carapace.',
        ShipClass.bombardier =>
          'Heavy deck joists mounting high-angle Mortar artillery. Crushes carapace (+50% blast) and disrupts frenzy.',
        ShipClass.corsair =>
          'Equipped with Harpoon Winch rigging to sever tentacles and tether charging beasts, with expanded cargo.',
      };

  List<Widget> _buildStatColumns(ShipClass sClass) {
    return switch (sClass) {
      ShipClass.standard => [
          _statItem('HULL HP', '90'),
          _statItem('UTILITY (2T)', 'Gunnery Drill'),
          _statItem('TACTICAL BELT', '3 Slots'),
          _statItem('SIGNATURE (1T)', 'Twin Chasers'),
        ],
      ShipClass.freighter => [
          _statItem('HULL HP', '85'),
          _statItem('HEIR STASH', '5% Gold & Belt'),
          _statItem('TACTICAL BELT', '4 Slots'),
          _statItem('SIGNATURE (1T)', 'Harpoon Winch'),
        ],
      ShipClass.ironclad => [
          _statItem('HULL HP', '120'),
          _statItem('FORTIFY DEF', '-3 Dmg Flat'),
          _statItem('TACTICAL BELT', '3 Slots'),
          _statItem('SIGNATURE (1T)', 'Prow Ram'),
        ],
      ShipClass.corvette => [
          _statItem('HULL HP', '75'),
          _statItem('BASE EVASION', '25% Dodge'),
          _statItem('TACTICAL BELT', '3 Slots'),
          _statItem('SIGNATURE (1T)', 'Culverin'),
        ],
      ShipClass.clipper => [
          _statItem('HULL HP', '75'),
          _statItem('BASE EVASION', '25% Dodge'),
          _statItem('TACTICAL BELT', '3 Slots'),
          _statItem('SIGNATURE (1T)', 'Culverin'),
        ],
      ShipClass.bombardier => [
          _statItem('HULL HP', '95'),
          _statItem('UTILITY (2T)', 'Spotter Flare'),
          _statItem('TACTICAL BELT', '3 Slots'),
          _statItem('SIGNATURE (1T)', 'Siege Mortar'),
        ],
      ShipClass.corsair => [
          _statItem('HULL HP', '85'),
          _statItem('UTILITY (2T)', 'Tether-Trap'),
          _statItem('TACTICAL BELT', '4 Slots'),
          _statItem('SIGNATURE (1T)', 'Harpoon Winch'),
        ],
    };
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: InkTheme.caption),
        const SizedBox(height: 2),
        Text(value, style: InkTheme.statValue),
      ],
    );
  }
}
