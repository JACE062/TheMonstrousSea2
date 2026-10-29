import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'combat_log_view.dart';
import 'ink_button.dart';

/// Opens the voyage log without interrupting battle playback underneath it.
Future<void> showBattleChronicle(
  BuildContext context,
  GameController controller, {
  CombatLogScrollState? scrollState,
}) async {
  final previousFocus = FocusManager.instance.primaryFocus;
  final route = DialogRoute<void>(
    context: context,
    builder: (context) => CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          backgroundColor: InkTheme.parchmentSurface,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: InkTheme.inkPrimary, width: 2),
          ),
          child: LayoutBuilder(
            builder: (context, bounds) => SizedBox(
              width: math.min(860, bounds.maxWidth),
              height: math.min(680, bounds.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('CHRONICLE OF BATTLE', style: InkTheme.titleMedium),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) => CombatLogView(
                          entries: controller.structuredCombatLog,
                          scrollState: scrollState,
                          showHeader: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkButton(
                        key: const ValueKey('chronicle-close'),
                        label: 'CLOSE',
                        compact: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  if (previousFocus?.context != null && previousFocus!.canRequestFocus) {
    previousFocus.requestFocus();
  }
}
