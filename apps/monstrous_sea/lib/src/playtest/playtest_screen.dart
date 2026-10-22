import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:monstrous_core/monstrous_core.dart';

import '../game_controller.dart';
import '../theme/ink_theme.dart';
import '../widgets/ink_button.dart';
import '../widgets/parchment_card.dart';
import '../widgets/parchment_scaffold.dart';
import 'playtest_config.dart';

class PlaytestScreen extends StatefulWidget {
  const PlaytestScreen({super.key, required this.gameBuilder});
  final Widget Function(GameController) gameBuilder;

  @override
  State<PlaytestScreen> createState() => _PlaytestScreenState();
}

class _PlaytestScreenState extends State<PlaytestScreen> {
  final _form = GlobalKey<FormState>();
  final _gold = TextEditingController(text: '250');
  final _seed = TextEditingController(text: '42');
  BlueprintId _blueprint = BlueprintId.standard;
  int _hullTier = 1;
  int _armamentTier = 1;
  int _region = 0;
  PlaytestDestination _destination = PlaytestDestination.regionStart;
  final _hardpoints = {
    for (final slot in playtestSlots) slot: const PlaytestHardpoint(),
  };
  GameController? _active;
  PlaytestConfig? _lastConfig;
  int _launchNumber = 0;

  void _disposeAfterUnmount(GameController? controller) {
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  @override
  void dispose() {
    _disposeAfterUnmount(_active);
    _gold.dispose();
    _seed.dispose();
    super.dispose();
  }

  void _launch([PlaytestConfig? repeat]) {
    if (!kDebugMode) return;
    if (repeat == null && !(_form.currentState?.validate() ?? false)) return;
    final config =
        repeat ??
        PlaytestConfig(
          blueprint: _blueprint,
          hullTier: _hullTier,
          armamentTier: _armamentTier,
          region: _region,
          destination: _destination,
          gold: int.parse(_gold.text),
          seed: int.parse(_seed.text),
          hardpoints: _hardpoints,
        );
    final controller = createPlaytestController(config);
    final previous = _active;
    setState(() {
      _active = controller;
      _lastConfig = config;
      _launchNumber++;
    });
    _disposeAfterUnmount(previous);
  }

  Widget _choice<T>(
    String label,
    T value,
    Map<T, String> options,
    ValueChanged<T>? onChanged,
  ) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: ValueKey(label),
        value: value,
        isExpanded: true,
        items: [
          for (final option in options.entries)
            DropdownMenuItem(
              value: option.key,
              child: Tooltip(
                message: option.value,
                child: Text(
                  option.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
        onChanged: onChanged == null
            ? null
            : (value) {
                if (value != null) onChanged(value);
              },
      ),
    ),
  );

  Widget _fields(List<Widget> fields) => LayoutBuilder(
    builder: (context, bounds) {
      final width = bounds.maxWidth >= 640
          ? (bounds.maxWidth - 16) / 2
          : bounds.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 20,
        children: [
          for (final field in fields) SizedBox(width: width, child: field),
        ],
      );
    },
  );

  void _changeHardpoint(
    HardpointType slot, {
    int? mark,
    String? power,
    int? tier,
  }) {
    final previous = _hardpoints[slot]!;
    setState(
      () => _hardpoints[slot] = PlaytestHardpoint(
        mark: mark ?? previous.mark,
        power: power == null
            ? previous.power
            : OceanPower.values.where((p) => p.name == power).firstOrNull,
        blessingTier: tier ?? previous.blessingTier,
      ),
    );
  }

  Widget _hardpoint(HardpointType slot) {
    final setup = _hardpoints[slot]!;
    return ParchmentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(slot.displayName, style: InkTheme.titleMedium),
          const SizedBox(height: 16),
          _fields([
            _choice<int>('${slot.name} Mk', setup.mark, const {
              1: 'Mk I',
              2: 'Mk II',
              3: 'Mk III',
            }, (value) => _changeHardpoint(slot, mark: value)),
            _choice<String>(
              '${slot.name} dedication',
              setup.power?.name ?? 'none',
              {
                'none': 'No blessing',
                for (final power in OceanPower.values)
                  power.name: power.displayName,
              },
              (value) => _changeHardpoint(slot, power: value),
            ),
            _choice<int>(
              '${slot.name} blessing tier',
              setup.blessingTier,
              const {1: 'Tier I', 2: 'Tier II', 3: 'Tier III'},
              setup.power == null
                  ? null
                  : (value) => _changeHardpoint(slot, tier: value),
            ),
          ]),
        ],
      ),
    );
  }

  String? _validateNumber(String? text, int maximum) {
    final value = int.tryParse(text ?? '');
    return value == null || value < 0 || value > maximum
        ? 'Enter a whole number from 0 to $maximum.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    if (_active != null) {
      final config = _lastConfig!;
      return Column(
        children: [
          Material(
            color: InkTheme.parchmentSurface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'PLAYTEST • Seed ${config.seed} • Progress is not saved',
                    style: InkTheme.caption,
                  ),
                  TextButton(
                    onPressed: () => _launch(config),
                    child: const Text('RELAUNCH'),
                  ),
                  TextButton(
                    onPressed: () {
                      final previous = _active;
                      setState(() => _active = null);
                      _disposeAfterUnmount(previous);
                    },
                    child: const Text('CHANGE SCENARIO'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: KeyedSubtree(
              key: ValueKey(_launchNumber),
              child: widget.gameBuilder(_active!),
            ),
          ),
        ],
      );
    }
    return ParchmentScaffold(
      bottomNavigationBar: Material(
        color: InkTheme.parchmentSurface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: InkButton(
              label: 'LAUNCH PLAYTEST',
              isPrimary: true,
              width: double.infinity,
              onPressed: () => _launch(),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('PLAYTEST MENU', style: InkTheme.titleLarge),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('CLOSE'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Experiment with a build without changing your real voyage or permanent progress. '
                    'Every launch creates a fresh, unsaved session.',
                    style: InkTheme.body,
                  ),
                  const SizedBox(height: 24),
                  _fields([
                    _choice('Blueprint', _blueprint, {
                      for (final bp in BlueprintId.values)
                        bp: bp.shipClass.displayName,
                    }, (value) => setState(() => _blueprint = value)),
                    _choice<int>('Hull tier', _hullTier, const {
                      1: 'Tier 1',
                      2: 'Tier 2',
                      3: 'Tier 3',
                      4: 'Tier 4',
                    }, (value) => setState(() => _hullTier = value)),
                    _choice<int>(
                      'Ancestral signature tier',
                      _armamentTier,
                      const {1: 'Tier 1', 2: 'Tier 2', 3: 'Tier 3'},
                      (value) => setState(() => _armamentTier = value),
                    ),
                    _choice('Destination', _destination, const {
                      PlaytestDestination.regionStart: 'Region start',
                      PlaytestDestination.titan: 'Region Titan',
                      PlaytestDestination.caldera: 'Caldera ending choice',
                    }, (value) => setState(() => _destination = value)),
                    _choice<int>(
                      'Region',
                      _destination == PlaytestDestination.caldera ? 2 : _region,
                      {
                        for (var i = 0; i < SeaChart.totalRegions; i++)
                          i: SeaChart.regionName(i),
                      },
                      _destination == PlaytestDestination.caldera
                          ? null
                          : (value) => setState(() => _region = value),
                    ),
                    TextFormField(
                      key: const ValueKey('playtest-gold'),
                      controller: _gold,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Starting gold',
                        border: OutlineInputBorder(),
                      ),
                      validator: (text) => _validateNumber(text, 999999),
                    ),
                    TextFormField(
                      key: const ValueKey('playtest-seed'),
                      controller: _seed,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Random seed',
                        border: OutlineInputBorder(),
                      ),
                      validator: (text) => _validateNumber(text, 2147483647),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Text(
                    'Hardpoint tempers and blessings are independent. Ancestral signature strength '
                    'is separate from the voyage’s Mk and blessing tiers.',
                    style: InkTheme.body,
                  ),
                  const SizedBox(height: 20),
                  for (final slot in playtestSlots) ...[
                    _hardpoint(slot),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
