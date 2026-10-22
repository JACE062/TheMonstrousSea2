import 'dart:ui' show AppExitResponse, AppExitType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';

/// Read at the player's pace, independently of the short live battle log.
class CalderaOutcomeScreen extends StatelessWidget {
  const CalderaOutcomeScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final choice = controller.session.calderaOutcome!;
    final lore = EldritchLore.calderaClimax[choice]!;
    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  lore.displayName,
                  style: InkTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Captain ${controller.captainName}',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ParchmentCard(
                  child: Text(
                    lore.narrativeOutcome,
                    style: InkTheme.body.copyWith(fontSize: 18, height: 1.6),
                  ),
                ),
                const SizedBox(height: 24),
                InkButton(
                  label: choice == CalderaClimaxChoice.claimCore
                      ? 'CHOOSE AN HEIR'
                      : 'THE HUNT IS ENDED',
                  isPrimary: true,
                  onPressed: () {
                    if (!controller.session.hasReadCalderaOutcome) {
                      controller.dispatch(const AcknowledgeCalderaOutcome());
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A completed hunt has no Start control that can restart a finished session.
class HuntEndedScreen extends StatefulWidget {
  const HuntEndedScreen({
    super.key,
    required this.controller,
    this.onReturnToMenu,
  });

  final GameController controller;

  final VoidCallback? onReturnToMenu;

  @override
  State<HuntEndedScreen> createState() => _HuntEndedScreenState();
}

class _HuntEndedScreenState extends State<HuntEndedScreen> {
  bool _exiting = false;
  String? _exitError;

  Future<void> _exitGame() async {
    if (_exiting) return;
    setState(() {
      _exiting = true;
      _exitError = null;
    });
    var failureMessage =
        'Your completed hunt could not be saved. Please try Exit Game again.';
    try {
      // Queue a final snapshot after any pending autosaves. Debug playtests
      // deliberately remain unsaved, including when leaving the application.
      if (widget.controller.autoSave) {
        await widget.controller.persistState();
      }
      if (!mounted) return;
      failureMessage = 'The game could not close. Please try Exit Game again.';
      final response = await ServicesBinding.instance.exitApplication(
        AppExitType.required,
      );
      if (mounted && response != AppExitResponse.exit) {
        setState(() => _exitError = failureMessage);
      }
    } catch (_) {
      if (mounted) setState(() => _exitError = failureMessage);
    } finally {
      if (mounted) setState(() => _exiting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ParchmentScaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text(
                EldritchLore.huntEndedTitle,
                style: InkTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                EldritchLore.huntEndedMessage,
                style: InkTheme.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (widget.onReturnToMenu != null) ...[
                InkButton(
                  label: 'RETURN TO MENU',
                  onPressed: _exiting ? null : widget.onReturnToMenu,
                ),
                const SizedBox(height: 12),
              ],
              InkButton(
                label: _exiting ? 'EXITING…' : 'EXIT GAME',
                semanticLabel: 'Exit game',
                isPrimary: true,
                onPressed: _exiting ? null : _exitGame,
              ),
              if (_exitError != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _exitError!,
                    style: InkTheme.body.copyWith(
                      color: InkTheme.crimsonAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
