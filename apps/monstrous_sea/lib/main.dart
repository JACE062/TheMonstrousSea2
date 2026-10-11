import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'src/game_controller.dart';
import 'src/screens/battle_screen.dart';
import 'src/screens/captain_screen.dart';
import 'src/screens/death_screen.dart';
import 'src/screens/intro_screen.dart';
import 'src/screens/loot_screen.dart';
import 'src/screens/merchant_screen.dart';
import 'src/screens/port_screen.dart';
import 'src/screens/rest_screen.dart';
import 'src/screens/sea_chart_screen.dart';
import 'src/theme/ink_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MonstrousSeaApp());
}

class MonstrousSeaApp extends StatelessWidget {
  const MonstrousSeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Monstrous Sea',
      debugShowCheckedModeBanner: false,
      theme: InkTheme.themeData,
      home: const GameOrchestratorView(),
    );
  }
}

class GameOrchestratorView extends StatefulWidget {
  const GameOrchestratorView({
    super.key,
    this.controller,
    this.skipIntro = false,
  });

  final GameController? controller;
  final bool skipIntro;

  @override
  State<GameOrchestratorView> createState() => _GameOrchestratorViewState();
}

class _GameOrchestratorViewState extends State<GameOrchestratorView> {
  late final GameController _controller;
  late bool _introDismissed = widget.skipIntro;
  bool _showingChartModal = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GameController();
    _controller.addListener(_onControllerStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    super.dispose();
  }

  void _onControllerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initial Atmospheric Intro
    if (!_introDismissed && _controller.phase == SessionPhase.captainCreation) {
      return IntroScreen(
        onStart: () => setState(() => _introDismissed = true),
      );
    }

    // 2. Active Screen based on SessionPhase
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _resolveScreenForPhase(),
    );
  }

  Widget _resolveScreenForPhase() {
    if (_showingChartModal) {
      return SeaChartScreen(
        key: const ValueKey('sea_chart_modal'),
        seaChart: _controller.seaChart,
        onClose: () => setState(() => _showingChartModal = false),
      );
    }

    switch (_controller.phase) {
      case SessionPhase.captainCreation:
        return CaptainScreen(
          key: const ValueKey('captain_screen'),
          controller: _controller,
        );

      case SessionPhase.port:
        return PortScreen(
          key: const ValueKey('port_screen'),
          controller: _controller,
          onOpenChart: () => setState(() => _showingChartModal = true),
        );

      case SessionPhase.merchant:
        return MerchantScreen(
          key: const ValueKey('merchant_screen'),
          controller: _controller,
        );

      case SessionPhase.battle:
        return BattleScreen(
          key: ValueKey('battle_screen_${_controller.currentMonster?.id}'),
          controller: _controller,
        );

      case SessionPhase.loot:
        return LootScreen(
          key: const ValueKey('loot_screen'),
          controller: _controller,
        );

      case SessionPhase.restArea:
        return RestScreen(
          key: const ValueKey('rest_screen'),
          controller: _controller,
          onOpenChart: () => setState(() => _showingChartModal = true),
        );

      case SessionPhase.death:
        return DeathScreen(
          key: const ValueKey('death_screen'),
          controller: _controller,
        );

      case SessionPhase.ended:
        return IntroScreen(
          key: const ValueKey('ended_screen'),
          onStart: () {
            setState(() {
              _introDismissed = false;
              _showingChartModal = false;
            });
          },
        );
    }
  }
}
