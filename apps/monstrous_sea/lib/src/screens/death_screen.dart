import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';

/// Screen displayed when the captain falls to the deep, offering heir succession.
class DeathScreen extends StatefulWidget {
  const DeathScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends State<DeathScreen> {
  late final TextEditingController _heirNameController;
  ShipClass _chosenClass = ShipClass.standard;

  @override
  void initState() {
    super.initState();
    final prevName = widget.controller.captainName;
    _heirNameController = TextEditingController(text: 'Heir of $prevName');
  }

  @override
  void dispose() {
    _heirNameController.dispose();
    super.dispose();
  }

  void _onContinueLineage() {
    final name = _heirNameController.text.trim();
    if (name.isEmpty) return;
    widget.controller.dispatch(ContinueLineage(name, _chosenClass));
  }

  @override
  Widget build(BuildContext context) {
    final lineage = widget.controller.lineage;
    final lastRecord = lineage.history.isNotEmpty ? lineage.history.last : null;
    final isFreighter = widget.controller.ship?.shipClass == ShipClass.freighter;

    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'A WATERY GRAVE',
                  style: InkTheme.titleLarge.copyWith(
                    fontSize: 36,
                    color: InkTheme.crimsonAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'The timbers splintered. The deep claimed another valiant captain.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Demise Record Card
                ParchmentCard(
                  borderColor: InkTheme.crimsonAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CAPTAIN\'S DEMISE LEDGER', style: InkTheme.statLabel),
                      const SizedBox(height: 10),
                      if (lastRecord != null) ...[
                        Text(
                          'Captain ${lastRecord.captainName} of The ${lastRecord.shipName}',
                          style: InkTheme.titleMedium.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 6),
                        Text('Fell to: ${lastRecord.causeOfDeath}', style: InkTheme.bodyBold.copyWith(color: InkTheme.crimsonAccent)),
                        Text('Monsters Defeated in Life: ${lastRecord.monstersDefeated}', style: InkTheme.body),
                        Text('Highest Danger Level Reached: ${lastRecord.highestDifficultyReached}', style: InkTheme.body),
                      ],
                      const Divider(height: 20),
                      Text(
                        'Generational Toll: ${lineage.captainsLost} Captains lost across time • ${lineage.totalMonstersDefeated} beasts slain in total',
                        style: InkTheme.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Freighter Inheritance Notice
                if (isFreighter)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: InkTheme.parchmentHighlight,
                      border: Border.all(color: InkTheme.goldAccent, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '★ Freighter Safe Stash Salvaged! The next heir will inherit 5% of accumulated gold and stashed cargo hold items.',
                      style: InkTheme.bodyBold.copyWith(color: InkTheme.goldAccent),
                    ),
                  ),

                // Heir Name & Ship Selection
                ParchmentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROCLAIM HEIR TO THE BLOODLINE', style: InkTheme.statLabel),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _heirNameController,
                        style: InkTheme.titleMedium.copyWith(fontSize: 20),
                        decoration: const InputDecoration(
                          hintText: 'Enter Heir Name...',
                          filled: true,
                          fillColor: InkTheme.parchmentHighlight,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('HEIR\'S COMMISSIONED CLASS', style: InkTheme.statLabel),
                      const SizedBox(height: 8),
                      Row(
                        children: ShipClass.values.map((sClass) {
                          final isSelected = _chosenClass == sClass;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () => setState(() => _chosenClass = sClass),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? InkTheme.parchmentHighlight : InkTheme.parchmentSurface,
                                    border: Border.all(
                                      color: isSelected ? InkTheme.goldAccent : InkTheme.inkMuted,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    sClass.name.toUpperCase(),
                                    style: InkTheme.statLabel.copyWith(
                                      fontSize: 11,
                                      color: isSelected ? InkTheme.crimsonAccent : InkTheme.inkPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Continuation Buttons
                Row(
                  children: [
                    Expanded(
                      child: InkButton(
                        label: 'CONTINUE THE HUNT',
                        isPrimary: true,
                        onPressed: _onContinueLineage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkButton(
                        label: 'ABANDON HUNT',
                        isDanger: true,
                        onPressed: () => widget.controller.dispatch(const AbandonHunt()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
