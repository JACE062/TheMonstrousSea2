import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import 'loot_supplies_view.dart';

class WreckSuppliesView extends StatelessWidget {
  const WreckSuppliesView({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) {
    final wreckId = controller.session.currentWreck?.id;
    return LootSuppliesView(
      controller: controller,
      onContinue: () {
        if (controller.phase == SessionPhase.shipwreck &&
            controller.session.currentWreck?.id == wreckId &&
            controller.session.currentWreck?.isSettled == true &&
            controller.pendingLoot.isEmpty) {
          controller.dispatch(
            ChooseWreckRecovery(wreckId!, WreckRecoveryChoice.depart),
          );
        }
      },
    );
  }
}
