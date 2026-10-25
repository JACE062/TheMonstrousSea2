import 'dart:ui' show AppExitResponse, AppExitType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'ink_button.dart';
import 'settings_dialog.dart';

/// Only complete checkpoints may be saved and left through the game menu.
bool canSaveAndLeave(GameController controller) =>
    !controller.isPlayingEvents &&
    const {
      SessionPhase.captainCreation,
      SessionPhase.port,
      SessionPhase.stronghold,
      SessionPhase.helm,
      SessionPhase.loot,
      SessionPhase.shipwreck,
      SessionPhase.merchant,
      SessionPhase.expeditionVictory,
      SessionPhase.death,
      SessionPhase.ended,
    }.contains(controller.phase);

/// Makes the same menu available to framed pages and the battle command dock.
class PauseMenuScope extends InheritedWidget {
  const PauseMenuScope({
    super.key,
    required this.openMenu,
    required this.saveAndReturnToTitle,
    required super.child,
  });

  final VoidCallback openMenu;
  final VoidCallback saveAndReturnToTitle;

  static PauseMenuScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PauseMenuScope>();

  @override
  bool updateShouldNotify(PauseMenuScope oldWidget) =>
      openMenu != oldWidget.openMenu ||
      saveAndReturnToTitle != oldWidget.saveAndReturnToTitle;
}

class PauseMenuButton extends StatelessWidget {
  const PauseMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = PauseMenuScope.maybeOf(context);
    return IconButton(
      key: const ValueKey('pause-menu-button'),
      icon: Icon(
        menu == null ? Icons.settings : Icons.pause,
        color: InkTheme.inkSecondary,
      ),
      tooltip: menu == null ? 'Settings & Accessibility' : 'Pause menu (Esc)',
      onPressed: menu?.openMenu ?? () => SettingsDialog.show(context),
    );
  }
}

/// Blocks new input while allowing an already dispatched action to finish.
/// Opening this menu does not create a combat save or restart event playback.
class PauseMenuHost extends StatefulWidget {
  const PauseMenuHost({
    super.key,
    required this.controller,
    required this.label,
    required this.child,
    this.onReturnToTitle,
  });

  final GameController controller;
  final String label;
  final Widget child;
  final VoidCallback? onReturnToTitle;

  @override
  State<PauseMenuHost> createState() => _PauseMenuHostState();
}

class _PauseMenuHostState extends State<PauseMenuHost> {
  final _menuRevision = ValueNotifier(0);
  DialogRoute<void>? _menuRoute;
  bool _menuOpen = false;
  bool _busy = false;
  String? _error;

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    _menuRevision.value++;
  }

  @override
  void dispose() {
    _menuRevision.dispose();
    super.dispose();
  }

  Future<void> _openMenu() async {
    if (_menuOpen || _busy || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final previousFocus = FocusManager.instance.primaryFocus;
    _menuOpen = true;
    final route = DialogRoute<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: Listenable.merge([widget.controller, _menuRevision]),
        builder: (context, _) => _dialog(context),
      ),
    );
    _menuRoute = route;
    _refresh();
    try {
      await Navigator.of(context, rootNavigator: true).push(route);
      await route.completed;
    } finally {
      _menuRoute = null;
      _menuOpen = false;
      if (mounted) {
        _refresh();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              !_busy &&
              previousFocus?.context != null &&
              previousFocus!.canRequestFocus) {
            previousFocus.requestFocus();
          }
        });
      }
    }
  }

  Future<void> _leave({required bool exit}) async {
    if (_busy ||
        !canSaveAndLeave(widget.controller) ||
        (!exit && widget.onReturnToTitle == null)) {
      return;
    }
    _busy = true;
    _error = null;
    _refresh();
    var failure = 'Could not save your progress. Please try again.';
    try {
      if (widget.controller.autoSave) await widget.controller.persistState();
      if (!mounted) return;
      if (exit) {
        failure = 'The game could not close. Please try again.';
        final response = await ServicesBinding.instance.exitApplication(
          AppExitType.required,
        );
        if (response != AppExitResponse.exit) _error = failure;
      } else {
        final route = _menuRoute;
        if (route != null && route.isActive) {
          route.navigator!.pop();
          // Remove the dialog's controller listeners before the lineage route
          // can unmount and dispose its controller.
          await route.completed;
        }
        if (mounted) widget.onReturnToTitle!();
      }
    } catch (_) {
      _error = failure;
    } finally {
      if (mounted) {
        _busy = false;
        _refresh();
        if (_error != null && !_menuOpen) _openMenu();
      }
    }
  }

  void _returnToTitle() => _leave(exit: false);

  Widget _dialog(BuildContext context) {
    final controller = widget.controller;
    final allowed = canSaveAndLeave(controller);
    final reason = controller.isPlayingEvents
        ? 'An action is still playing. Wait for it to finish before leaving.'
        : !allowed
        ? 'Finish this encounter, then continue to Set Course before saving or '
              'leaving.'
        : null;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!_busy) Navigator.of(context).pop();
        },
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: !_busy,
          child: AlertDialog(
            backgroundColor: InkTheme.parchmentSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: InkTheme.inkPrimary, width: 2),
            ),
            title: Text('PAUSED', style: InkTheme.titleMedium),
            scrollable: true,
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    controller.autoSave ? 'CURRENT LINEAGE' : 'UNSAVED SESSION',
                    style: InkTheme.statLabel,
                  ),
                  Text(widget.label, style: InkTheme.body),
                  const SizedBox(height: 16),
                  InkButton(
                    key: const ValueKey('pause-resume'),
                    label: 'RESUME',
                    isPrimary: true,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 8),
                  InkButton(
                    key: const ValueKey('pause-settings'),
                    label: 'SETTINGS',
                    onPressed: _busy
                        ? null
                        : () => SettingsDialog.show(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.autoSave
                        ? allowed
                              ? 'Your saved voyage will resume from this stop.'
                              : 'Combat turns and unfinished encounters cannot be resumed.'
                        : 'This session is not saved. Exiting does not save this scenario.',
                    style: InkTheme.caption,
                  ),
                  if (reason != null) ...[
                    const SizedBox(height: 8),
                    Text(reason, style: InkTheme.body),
                  ],
                  if (widget.onReturnToTitle == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Return to title is unavailable for this session.',
                      style: InkTheme.caption,
                    ),
                  ],
                  const SizedBox(height: 12),
                  InkButton(
                    key: const ValueKey('pause-return'),
                    label: _busy
                        ? 'SAVING…'
                        : controller.autoSave
                        ? 'SAVE & RETURN TO TITLE'
                        : 'RETURN TO TITLE',
                    onPressed:
                        allowed && !_busy && widget.onReturnToTitle != null
                        ? () => _leave(exit: false)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  InkButton(
                    key: const ValueKey('pause-exit'),
                    label: controller.autoSave
                        ? 'SAVE & EXIT GAME'
                        : 'EXIT GAME',
                    onPressed: allowed && !_busy
                        ? () => _leave(exit: true)
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: InkTheme.body.copyWith(
                        color: InkTheme.crimsonAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PauseMenuScope(
    openMenu: _openMenu,
    saveAndReturnToTitle: _returnToTitle,
    child: CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _openMenu},
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _openMenu();
          },
          child: IgnorePointer(
            ignoring: _menuOpen || _busy,
            child: ExcludeFocus(
              excluding: _menuOpen || _busy,
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  );
}
