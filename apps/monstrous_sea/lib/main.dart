import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:monstrous_core/monstrous_core.dart';

import 'src/game_controller.dart';
import 'src/playtest/playtest_host.dart';
import 'src/screens/battle_screen.dart';
import 'src/screens/caldera_outcome_screen.dart';
import 'src/screens/captain_screen.dart';
import 'src/screens/death_screen.dart';
import 'src/screens/helm_screen.dart';
import 'src/screens/intro_screen.dart';
import 'src/screens/lineage_menu_screen.dart';
import 'src/screens/loot_screen.dart';
import 'src/screens/merchant_screen.dart';
import 'src/screens/port_screen.dart';
import 'src/screens/stronghold_screen.dart';
import 'src/screens/respite_island_screen.dart';
import 'src/screens/rest_screen.dart';
import 'src/screens/sea_chart_screen.dart';
import 'src/screens/shipwreck_screen.dart';
import 'src/screens/shrine_screen.dart';
import 'src/screens/smuggler_screen.dart';
import 'src/screens/victory_screen.dart';
import 'src/settings/game_settings.dart';
import 'src/services/lineage_store.dart';
import 'src/theme/ink_theme.dart';
import 'src/widgets/parchment_scaffold.dart';
import 'src/widgets/pause_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MonstrousSeaApp());
}

class MonstrousSeaApp extends StatelessWidget {
  const MonstrousSeaApp({super.key, this.controller, this.lineageStore});

  final GameController? controller;
  final LineageStore? lineageStore;

  Widget _normalHome() => controller != null
      ? GameOrchestratorView(controller: controller)
      : LineageMenuScreen(
          store: lineageStore,
          gameBuilder: (controller, onReturnToMenu) => GameOrchestratorView(
            controller: controller,
            skipIntro: controller.profile.hasBegunFirstVoyage,
            onReturnToMenu: onReturnToMenu,
          ),
        );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameSettings.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'The Monstrous Sea',
          debugShowCheckedModeBanner: false,
          theme: InkTheme.themeData,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(GameSettings.instance.fontScale),
              ),
              child: child!,
            );
          },
          home: kDebugMode
              ? PlaytestHost(
                  gameBuilder: (testController) => GameOrchestratorView(
                    controller: testController,
                    skipIntro: true,
                  ),
                  child: _normalHome(),
                )
              : _normalHome(),
        );
      },
    );
  }
}

class GameOrchestratorView extends StatefulWidget {
  const GameOrchestratorView({
    super.key,
    this.controller,
    this.skipIntro = false,
    this.loadStorage,
    this.onReturnToMenu,
  });

  final GameController? controller;
  final bool skipIntro;

  /// Injected controllers normally already contain test or live session state.
  final bool? loadStorage;
  final VoidCallback? onReturnToMenu;

  @override
  State<GameOrchestratorView> createState() => _GameOrchestratorViewState();
}

class _GameOrchestratorViewState extends State<GameOrchestratorView> {
  late final GameController _controller;
  late bool _introDismissed = widget.skipIntro;
  bool _showingChartModal = false;
  bool _loadingStorage = false;
  bool _storageFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GameController();
    _controller.addListener(_onControllerStateChanged);
    if (widget.loadStorage ?? widget.controller == null) {
      _loadingStorage = true;
      _loadStorage();
    }
  }

  Future<void> _loadStorage() async {
    try {
      await _controller.initializeStorage();
      if (mounted) {
        setState(() {
          _loadingStorage = false;
          _storageFailed = false;
          if (_controller.profile.hasBegunFirstVoyage) _introDismissed = true;
        });
      }
    } catch (error) {
      debugPrint('Unable to initialize saved progress: $error');
      if (mounted) {
        setState(() {
          _loadingStorage = false;
          _storageFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onControllerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildGame(context);
    if (_loadingStorage || _storageFailed ||
        PauseMenuScope.maybeOf(context) != null) {
      return content;
    }
    return PauseMenuHost(
      controller: _controller,
      label: _controller.autoSave ? 'Current lineage' : 'Playtest session',
      onReturnToTitle: widget.onReturnToMenu,
      child: content,
    );
  }

  Widget _buildGame(BuildContext context) {
    if (_storageFailed) {
      return ParchmentScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your saved progress.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _storageFailed = false;
                    _loadingStorage = true;
                  });
                  _loadStorage();
                },
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }
    if (_loadingStorage) {
      return const ParchmentScaffold(
        body: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading your bloodline and voyage',
          ),
        ),
      );
    }
    // 1. Initial Atmospheric Intro
    if (!_introDismissed && _controller.phase == SessionPhase.captainCreation) {
      return IntroScreen(onStart: () => setState(() => _introDismissed = true));
    }

    // 2. Active Screen based on SessionPhase
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [
          for (final outgoing in previous)
            IgnorePointer(
              key: outgoing.key,
              child: ExcludeFocus(child: outgoing),
            ),
          if (current != null)
            IgnorePointer(
              key: current.key,
              ignoring: false,
              child: ExcludeFocus(excluding: false, child: current),
            ),
        ],
      ),
      child: _resolveScreenForPhase(),
    );
  }

  Widget _resolveScreenForPhase() {
    // Session outcomes precede their visual playback. Parent/menu/settings
    // rebuilds must keep that battle mounted until its completion notification.
    if (_controller.isPlayingEvents &&
        _controller.ship != null && _controller.currentMonster != null) {
      return BattleScreen(
        key: ValueKey('battle_screen_${_controller.currentMonster!.id}'),
        controller: _controller,
      );
    }
    if (_controller.session.calderaOutcome != null &&
        !_controller.session.hasReadCalderaOutcome &&
        (_controller.phase == SessionPhase.death ||
            _controller.phase == SessionPhase.ended)) {
      return CalderaOutcomeScreen(
        key: const ValueKey('caldera_outcome'),
        controller: _controller,
      );
    }
    if (_showingChartModal) {
      return SeaChartScreen(
        key: const ValueKey('sea_chart_modal'),
        seaChart: _controller.seaChart,
        isInPort:
            _controller.phase == SessionPhase.port ||
            _controller.phase == SessionPhase.stronghold,
        isCurrentDefeated: _controller.isCurrentEncounterDefeated,
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

      case SessionPhase.stronghold:
        return StrongholdScreen(
          key: const ValueKey('stronghold_screen'),
          controller: _controller,
          onOpenChart: () => setState(() => _showingChartModal = true),
        );

      case SessionPhase.helm:
        return HelmScreen(
          key: const ValueKey('helm_screen'),
          controller: _controller,
          onOpenChart: () => setState(() => _showingChartModal = true),
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

      case SessionPhase.respiteIsland:
        return RespiteIslandScreen(
          key: const ValueKey('respite_island_screen'),
          controller: _controller,
          onOpenChart: () => setState(() => _showingChartModal = true),
        );

      case SessionPhase.shipwreck:
        return ShipwreckScreen(
          key: const ValueKey('shipwreck_screen'),
          controller: _controller,
          onOpenChart: () => setState(() => _showingChartModal = true),
        );

      case SessionPhase.smuggler:
        return SmugglerScreen(
          key: const ValueKey('smuggler_screen'),
          controller: _controller,
          onOpenChart: () => setState(() => _showingChartModal = true),
        );

      case SessionPhase.shrine:
        return ShrineScreen(
          key: const ValueKey('shrine_screen'),
          controller: _controller,
          onOpenChart: () => setState(() => _showingChartModal = true),
        );

      case SessionPhase.expeditionVictory:
        return VictoryScreen(
          key: const ValueKey('victory_screen'),
          controller: _controller,
        );

      case SessionPhase.death:
        return DeathScreen(
          key: const ValueKey('death_screen'),
          controller: _controller,
        );

      case SessionPhase.ended:
        return HuntEndedScreen(
          key: const ValueKey('ended_screen'),
          controller: _controller,
          onReturnToMenu: widget.onReturnToMenu,
        );
    }
  }
}
