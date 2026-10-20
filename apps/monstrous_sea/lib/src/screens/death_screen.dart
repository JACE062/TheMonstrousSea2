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
  int _selectedCandidateIndex = 0;

  @override
  void initState() {
    super.initState();
    final candidates = widget.controller.pendingHeirCandidates;
    if (candidates.isNotEmpty) {
      _heirNameController = TextEditingController(
        text: candidates.first.defaultName,
      );
    } else {
      final prevName = widget.controller.captainName;
      _heirNameController = TextEditingController(
        text: prevName.isNotEmpty ? 'Heir of $prevName' : 'Heir of the Deep',
      );
    }
  }

  @override
  void dispose() {
    _heirNameController.dispose();
    super.dispose();
  }

  void _onContinueLineage() {
    final name = _heirNameController.text.trim();
    if (name.isEmpty) return;
    final candidates = widget.controller.pendingHeirCandidates;
    final selected =
        (candidates.isNotEmpty &&
            _selectedCandidateIndex >= 0 &&
            _selectedCandidateIndex < candidates.length)
        ? candidates[_selectedCandidateIndex]
        : null;
    final profile = widget.controller.profile;
    final blueprint =
        BlueprintId.values
            .where(
              (id) =>
                  id.name == profile.activeBlueprintId &&
                  profile.isBlueprintUnlocked(id),
            )
            .firstOrNull ??
        BlueprintId.standard;
    widget.controller.dispatch(
      ContinueLineage(
        name,
        blueprint.shipClass,
        boon: selected?.boon,
        quirk: selected?.quirk,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lineage = widget.controller.lineage;
    final lastRecord = lineage.history.isNotEmpty ? lineage.history.last : null;
    final isFreighter =
        widget.controller.ship?.shipClass == ShipClass.freighter;
    final nemesis = widget.controller.activeNemesis;
    final candidates = widget.controller.pendingHeirCandidates;

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
                  lastRecord?.causeOfDeath.contains('Ascended') == true
                      ? 'ASCENDED INTO THE DEEP'
                      : 'A WATERY GRAVE',
                  style: InkTheme.titleLarge.copyWith(
                    fontSize: 36,
                    color: InkTheme.crimsonAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  lastRecord?.causeOfDeath.contains('Ascended') == true
                      ? 'The captain claimed the Primordial Core. The flagship returns alone to harbor with the Covenant awoken.'
                      : 'The timbers splintered. The deep claimed another valiant captain.',
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
                      Text(
                        'CAPTAIN\'S DEMISE LEDGER',
                        style: InkTheme.statLabel,
                      ),
                      const SizedBox(height: 10),
                      if (lastRecord != null) ...[
                        Text(
                          'Captain ${lastRecord.captainName} of The ${lastRecord.shipName}',
                          style: InkTheme.titleMedium.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fell to: ${lastRecord.causeOfDeath}',
                          style: InkTheme.bodyBold.copyWith(
                            color: InkTheme.crimsonAccent,
                          ),
                        ),
                        Text(
                          'Monsters Defeated in Life: ${lastRecord.monstersDefeated}',
                          style: InkTheme.body,
                        ),
                        Text(
                          'Highest Danger Level Reached: ${lastRecord.highestDifficultyReached}',
                          style: InkTheme.body,
                        ),
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

                // Nemesis Ascended Card
                if (nemesis != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: InkTheme.crimsonAccent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: InkTheme.crimsonAccent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: InkTheme.crimsonAccent,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'NEMESIS ASCENDED: ${nemesis.moniker.toUpperCase()}',
                                style: InkTheme.titleMedium.copyWith(
                                  color: InkTheme.crimsonAccent,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Felled Captain ${nemesis.predecessorCaptain} in Region ${nemesis.regionIndex + 1}.',
                          style: InkTheme.bodyBold,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The beast grows more cunning and ruthless in the deep. Confront it on a future voyage to avenge your ancestor.',
                          style: InkTheme.body,
                        ),
                        const Divider(
                          height: 16,
                          color: InkTheme.crimsonAccent,
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Vengeance Bounty: ',
                              style: InkTheme.caption.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '+${nemesis.bountyGold} Gold • +${nemesis.bountySeaGlass} Sea Glass • +${nemesis.bountyMonsterBone} Monster Bone • +${nemesis.bountyBarnacles} Barnacles',
                              style: InkTheme.caption.copyWith(
                                color: InkTheme.goldAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

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
                      'Freighter Safe Stash Salvaged! The next heir will inherit 5% of accumulated gold and saved tactical belt provisions.',
                      style: InkTheme.bodyBold.copyWith(
                        color: InkTheme.goldAccent,
                      ),
                    ),
                  ),

                // Heir Candidates Selection
                if (candidates.isNotEmpty) ...[
                  Text('SELECT HEIR CANDIDATE', style: InkTheme.statLabel),
                  const SizedBox(height: 6),
                  Text(
                    'Each heir inherits unique bloodline dispositions forged by your lineage\'s pact with the sea.',
                    style: InkTheme.subtitle,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: List.generate(candidates.length, (index) {
                      final candidate = candidates[index];
                      final isSelected = _selectedCandidateIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCandidateIndex = index;
                              _heirNameController.text = candidate.defaultName;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? InkTheme.parchmentHighlight
                                  : InkTheme.parchmentSurface,
                              border: Border.all(
                                color: isSelected
                                    ? InkTheme.goldAccent
                                    : InkTheme.inkMuted,
                                width: isSelected ? 2.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: InkTheme.goldAccent.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        candidate.defaultName,
                                        style: InkTheme.titleMedium.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? InkTheme.crimsonAccent
                                              : InkTheme.inkPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: InkTheme.goldAccent.withValues(
                                            alpha: 0.2,
                                          ),
                                          border: Border.all(
                                            color: InkTheme.goldAccent,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'SELECTED',
                                          style: InkTheme.caption.copyWith(
                                            color: InkTheme.goldAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Boon
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(
                                          alpha: 0.15,
                                        ),
                                        border: Border.all(
                                          color: Colors.blue.shade700,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'BOON',
                                        style: InkTheme.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            candidate.boon.name,
                                            style: InkTheme.bodyBold,
                                          ),
                                          Text(
                                            candidate.boon.description,
                                            style: InkTheme.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Quirk
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepOrange.withValues(
                                          alpha: 0.15,
                                        ),
                                        border: Border.all(
                                          color: Colors.deepOrange.shade700,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'QUIRK',
                                        style: InkTheme.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            candidate.quirk.name,
                                            style: InkTheme.bodyBold,
                                          ),
                                          Text(
                                            candidate.quirk.description,
                                            style: InkTheme.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],

                // Heir name; ancestral blueprint changes belong at the home port
                ParchmentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROCLAIM HEIR TO THE BLOODLINE',
                        style: InkTheme.statLabel,
                      ),
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
                      Text(
                        'The Bloodbound Ship returns to the home port. Prepare the next voyage there and choose from your unlocked ancestral blueprints.',
                        style: InkTheme.body.copyWith(fontSize: 15),
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
                        onPressed: () =>
                            widget.controller.dispatch(const AbandonHunt()),
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
