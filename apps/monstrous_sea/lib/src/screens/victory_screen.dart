import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';

/// The final decision after defeating the Ancient Leviathan.
class VictoryScreen extends StatelessWidget {
  const VictoryScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => ParchmentScaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                EldritchLore.calderaTitle,
                style: InkTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(EldritchLore.calderaIntroduction, style: InkTheme.body),
              const SizedBox(height: 20),
              ParchmentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Captain ${controller.captainName}',
                      style: InkTheme.titleMedium,
                    ),
                    if (controller.ship != null)
                      Text(controller.ship!.name, style: InkTheme.body),
                    const SizedBox(height: 8),
                    Text(
                      '${controller.session.monstersDefeatedThisLife} beasts defeated • ${controller.ship?.gold ?? 0} gold',
                      style: InkTheme.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              for (final choice in CalderaClimaxChoice.values) ...[
                _choiceCard(choice),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _choiceCard(CalderaClimaxChoice choice) {
    final lore = EldritchLore.calderaClimax[choice]!;
    return ParchmentCard(
      borderColor: choice == CalderaClimaxChoice.shatterCore
          ? InkTheme.goldAccent
          : InkTheme.crimsonAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(lore.promptTitle, style: InkTheme.titleMedium),
          const SizedBox(height: 12),
          Text(lore.consequence, style: InkTheme.body),
          const SizedBox(height: 20),
          InkButton(
            label: lore.displayName.toUpperCase(),
            semanticLabel: '${lore.displayName}. ${lore.consequence}',
            isPrimary: choice == CalderaClimaxChoice.shatterCore,
            onPressed: controller.phase == SessionPhase.expeditionVictory
                ? () {
                    if (controller.phase == SessionPhase.expeditionVictory) {
                      controller.dispatch(ResolveCalderaClimax(choice));
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
