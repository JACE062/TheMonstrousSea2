import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import 'playtest_screen.dart';

/// Debug entry point that leaves the normal game's controller mounted intact.
class PlaytestHost extends StatefulWidget {
  const PlaytestHost({
    super.key,
    required this.child,
    required this.gameBuilder,
    this.openOnStart = const bool.fromEnvironment('PLAYTEST'),
  });
  final Widget child;
  final Widget Function(GameController) gameBuilder;
  final bool openOnStart;

  @override
  State<PlaytestHost> createState() => _PlaytestHostState();
}

class _PlaytestHostState extends State<PlaytestHost> {
  bool _open = false;
  late bool _showNormalGame = !widget.openOnStart;

  @override
  void initState() {
    super.initState();
    if (widget.openOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openLab();
      });
    }
  }

  Future<void> _openLab() async {
    if (!kDebugMode || _open) return;
    _open = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PlaytestScreen(gameBuilder: widget.gameBuilder),
        ),
      );
    } finally {
      _open = false;
      if (mounted && !_showNormalGame) setState(() => _showNormalGame = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.f10): _openLab},
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            Material(
              color: InkTheme.parchmentSurface,
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _openLab,
                  child: const Text('PLAYTEST MENU  •  F10'),
                ),
              ),
            ),
            Expanded(
              child: _showNormalGame
                  ? widget.child
                  : const Center(child: Text('Opening playtest menu…')),
            ),
          ],
        ),
      ),
    );
  }
}
