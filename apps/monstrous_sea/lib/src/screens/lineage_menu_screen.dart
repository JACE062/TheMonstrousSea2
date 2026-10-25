import 'dart:ui' show AppExitResponse, AppExitType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_controller.dart';
import '../services/lineage_store.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import '../widgets/pause_menu.dart';
import '../widgets/settings_dialog.dart';

/// The title menu owns slot selection; gameplay still uses the same orchestrator.
class LineageMenuScreen extends StatefulWidget {
  const LineageMenuScreen({super.key, required this.gameBuilder, this.store});
  final LineageStore? store;
  final Widget Function(GameController, VoidCallback) gameBuilder;

  @override
  State<LineageMenuScreen> createState() => _LineageMenuScreenState();
}

class _LineageMenuScreenState extends State<LineageMenuScreen> {
  late final LineageStore _store = widget.store ?? LineageStore();
  List<LineageSummary> _summaries = [];
  String? _selectedId;
  String? _error;
  bool _busy = true;
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final catalog = await _store.load();
      final summaries = await _store.summaries();
      if (!mounted) return;
      setState(() {
        _summaries = summaries;
        _selectedId = catalog.activeId;
        _busy = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Your lineages could not be loaded. Your saves have not been replaced. Retry to load them again.';
        });
      }
    }
  }

  Future<void> _open(String id) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    GameController? controller;
    try {
      final storage = await _store.open(id);
      controller = GameController(
        storage: storage,
        retainPreparationCheckpoints: true,
      );
      await controller.initializeStorage();
      if (!mounted) return;
      final label =
          _summaries.where((s) => s.slot.id == id).firstOrNull?.slot.label ??
          'Lineage';
      final active = controller;
      final route = MaterialPageRoute<void>(
        builder: (_) => _LineageGame(
          label: label,
          controller: active,
          gameBuilder: widget.gameBuilder,
        ),
      );
      await _navigator.currentState!.push(route);
      // The route's pop future resolves before its transition has unmounted.
      await route.completed;
      if (mounted) await _reload();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'This lineage could not be opened. Your saved progress has not been replaced. Retry before continuing.';
        });
      }
    } finally {
      controller?.dispose();
    }
  }

  Future<void> _newLineage() async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => const _NewLineageDialog(),
    );
    if (label == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final slot = await _store.create(label);
      await _reload();
      if (mounted && _error == null) await _open(slot.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'The new lineage could not be saved. Existing lineages have not been replaced. Retry to reload the list.';
        });
      }
    }
  }

  Future<void> _exploreOtherFate(String sourceId) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final slot = await _store.exploreOtherFate(sourceId);
      await _reload();
      if (mounted && _error == null) await _open(slot.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'The alternate fate could not be opened. Your completed hunt and any existing branch remain preserved. Retry to reload.';
        });
      }
    }
  }

  Future<void> _exitGame() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await ServicesBinding.instance.exitApplication(
        AppExitType.required,
      );
      if (mounted && response != AppExitResponse.exit) {
        setState(() => _error = 'The game could not close. Please try again.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The game could not close. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => NavigatorPopHandler<void>(
    onPopWithResult: (_) => _navigator.currentState!.maybePop(),
    child: Navigator(
      key: _navigator,
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: _buildMenu),
    ),
  );

  Widget _buildMenu(BuildContext context) {
    final selected = _summaries
        .where((s) => s.slot.id == _selectedId)
        .firstOrNull;
    return ParchmentScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'THE MONSTROUS SEA',
                  style: InkTheme.titleLarge.copyWith(
                    fontSize: MediaQuery.sizeOf(context).width < 480 ? 24 : 34,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'A ship bound to return. A bloodline bound to the hunt.',
                  style: InkTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_busy)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Loading lineage',
                  ),
                if (_error != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: InkTheme.body.copyWith(
                        color: InkTheme.crimsonAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkButton(
                    label: 'RETRY',
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _busy = true;
                              _error = null;
                            });
                            _reload();
                          },
                  ),
                  const SizedBox(height: 16),
                ],
                InkButton(
                  label: 'CONTINUE',
                  subtitle: selected == null
                      ? 'Select a lineage below'
                      : selected.slot.label,
                  isPrimary: true,
                  onPressed:
                      _busy ||
                          _error != null ||
                          selected == null ||
                          !selected.readable
                      ? null
                      : () => _open(selected.slot.id),
                ),
                if (selected?.profile?.hasShatteredFont == true &&
                    selected!.slot.alternateOf == null) ...[
                  const SizedBox(height: 12),
                  InkButton(
                    label: selected.alternateId == null
                        ? 'EXPLORE THE OTHER FATE'
                        : 'CONTINUE OTHER FATE',
                    onPressed:
                        _busy || _error != null || !selected.canExploreOtherFate
                        ? null
                        : () => _exploreOtherFate(selected.slot.id),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selected.canExploreOtherFate
                        ? 'Your peaceful ending stays intact. The other fate is a separate save with its own progress. Returning here continues that same branch.'
                        : 'This completed hunt has no usable pre-choice snapshot. Its ending is preserved; older endings cannot be safely reconstructed.',
                    style: InkTheme.caption,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    InkButton(
                      label: 'NEW LINEAGE',
                      onPressed: _busy || _error != null ? null : _newLineage,
                    ),
                    InkButton(
                      label: 'SETTINGS',
                      onPressed: _busy
                          ? null
                          : () => SettingsDialog.show(context),
                    ),
                    InkButton(
                      label: 'EXIT GAME',
                      onPressed: _busy ? null : _exitGame,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('YOUR LINEAGES', style: InkTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Each save has its own captains, discoveries and ending. New Lineage starts a separate hunt.',
                  style: InkTheme.body,
                ),
                const SizedBox(height: 12),
                if (!_busy && _error == null && _summaries.isEmpty)
                  Text(
                    'No lineages yet. Begin with New Lineage.',
                    style: InkTheme.caption,
                  ),
                for (final summary in _summaries) ...[
                  ParchmentCard(
                    borderColor: summary.slot.id == _selectedId
                        ? InkTheme.goldAccent
                        : InkTheme.inkMuted,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(summary.slot.label, style: InkTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(summary.description, style: InkTheme.body),
                        if (summary.slot.alternateOf != null)
                          Text(
                            'Independent alternate fate',
                            style: InkTheme.caption,
                          ),
                        if (!summary.readable)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () {
                                    setState(() {
                                      _busy = true;
                                      _error = null;
                                    });
                                    _reload();
                                  },
                            child: const Text('RETRY LOAD'),
                          ),
                        const SizedBox(height: 8),
                        InkButton(
                          key: ValueKey('select-${summary.slot.id}'),
                          label: summary.slot.id == _selectedId
                              ? 'SELECTED'
                              : 'SELECT LINEAGE',
                          semanticLabel: 'Select ${summary.slot.label}',
                          onPressed:
                              _busy || _error != null || !summary.readable
                              ? null
                              : () => setState(
                                  () => _selectedId = summary.slot.id,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Retained for callers that inspect the lineage departure policy.
bool canReturnToLineageMenu(GameController controller) =>
    canSaveAndLeave(controller);

class _LineageGame extends StatelessWidget {
  const _LineageGame({
    required this.label,
    required this.controller,
    required this.gameBuilder,
  });
  final String label;
  final GameController controller;
  final Widget Function(GameController, VoidCallback) gameBuilder;

  @override
  Widget build(BuildContext context) => PauseMenuHost(
    controller: controller,
    label: label,
    onReturnToTitle: () => Navigator.of(context).pop(),
    child: Builder(
      builder: (context) => gameBuilder(
        controller,
        PauseMenuScope.maybeOf(context)!.saveAndReturnToTitle,
      ),
    ),
  );
}

class _NewLineageDialog extends StatefulWidget {
  const _NewLineageDialog();
  @override
  State<_NewLineageDialog> createState() => _NewLineageDialogState();
}

class _NewLineageDialogState extends State<_NewLineageDialog> {
  final _label = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _create() {
    if (_form.currentState!.validate()) {
      Navigator.of(context).pop(_label.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: InkTheme.parchmentSurface,
    title: const Text('NEW LINEAGE'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Name this save. This label is separate from your captain’s name and does not set a permanent family surname.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('lineage-label'),
              controller: _label,
              autofocus: true,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Save label'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a label for this save.'
                  : null,
              onFieldSubmitted: (_) => _create(),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('CANCEL'),
      ),
      TextButton(onPressed: _create, child: const Text('CREATE LINEAGE')),
    ],
  );
}
