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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
      };

  String _shipDescription(ShipClass sClass) => switch (sClass) {
        ShipClass.standard =>
          'A balanced all-rounder vessel. Reliable cannon mounts and steady hull construction.',
        ShipClass.freighter =>
          'Massive hold capacity designed for trade and looting. Survives with safe stash carrying 5% gold & cargo to heirs.',
        ShipClass.ironclad =>
          'Heavy reinforced armor plates. Features Fortify trait: nullifies incoming attack damage and deflects monster strikes.',
        ShipClass.corvette =>
          'Raked sails built for supreme speed. Features Evasion trait: naturally dodges strikes and can execute evasive maneuvers.',
      };

  List<Widget> _buildStatColumns(ShipClass sClass) {
    return switch (sClass) {
      ShipClass.standard => [
          _statItem('HULL HP', '90 - 110'),
          _statItem('ARMOR CLASS', '10 AC'),
          _statItem('CARGO HOLD', '15 - 25'),
          _statItem('GUN WEIGHT', '7 Wt'),
        ],
      ShipClass.freighter => [
          _statItem('HULL HP', '105 - 145'),
          _statItem('ARMOR CLASS', '8 AC'),
          _statItem('CARGO HOLD', '20 - 40'),
          _statItem('GUN WEIGHT', '3 Wt'),
        ],
      ShipClass.ironclad => [
          _statItem('HULL HP', '90 - 110'),
          _statItem('ARMOR CLASS', '12 AC'),
          _statItem('DAMAGE REDUCT', '3 Flat'),
          _statItem('GUN WEIGHT', '10 Wt'),
        ],
      ShipClass.corvette => [
          _statItem('HULL HP', '70 - 90'),
          _statItem('ARMOR CLASS', '6 AC'),
          _statItem('BASE EVASION', '10%'),
          _statItem('GUN WEIGHT', '5 Wt'),
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
