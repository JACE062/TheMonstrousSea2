import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';

/// The first captain names the bloodline and sails the Standard flagship.
/// Later generations return to Port to choose unlocked ancestral blueprints.
class CaptainScreen extends StatefulWidget {
  const CaptainScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<CaptainScreen> createState() => _CaptainScreenState();
}

class _CaptainScreenState extends State<CaptainScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Eldred Thorne',
  );
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCommission() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a name for the first captain.');
      return;
    }
    if (!widget.controller.profile.hasBegunFirstVoyage) {
      widget.controller.dispatch(BeginFirstVoyage(name));
    } else {
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
      widget.controller.dispatch(NameCaptain(name));
      if (widget.controller.ship == null) {
        widget.controller.dispatch(ChooseShip(blueprint.shipClass));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ParchmentScaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
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
              const SizedBox(height: 12),
              Text(
                widget.controller.profile.hasBegunFirstVoyage
                    ? 'The Bloodbound Ship has returned. Take command, then prepare your next voyage at the home port.'
                    : 'The Bloodbound Ship answers to your name. Your first voyage begins in the Siren Shoals.',
                style: InkTheme.body.copyWith(fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ParchmentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "CAPTAIN'S NAME",
                      style: InkTheme.statLabel.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: InkTheme.body.copyWith(fontSize: 20),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onCommission(),
                      decoration: InputDecoration(
                        hintText: 'Enter captain name',
                        errorText: _nameError,
                        filled: true,
                        fillColor: InkTheme.parchmentHighlight,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (!widget.controller.profile.hasBegunFirstVoyage)
                ParchmentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'THE STANDARD FLAGSHIP',
                        style: InkTheme.titleMedium.copyWith(fontSize: 23),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Naval Cannon Battery · Broadside\nTwin Chaser Cannons · Signature\nGun-Deck Bracing · Utility',
                        style: InkTheme.body.copyWith(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Three fixed fittings. Set your range, fire a volley, and survive the beast ahead. New blueprints await later generations at the home port.',
                        style: InkTheme.body.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              InkButton(
                label: widget.controller.profile.hasBegunFirstVoyage
                    ? 'TAKE COMMAND'
                    : 'BEGIN FIRST VOYAGE',
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
