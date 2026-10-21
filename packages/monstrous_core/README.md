# monstrous_core

The pure Dart gameplay engine for [The Monstrous Sea 2](../../README.md). It contains combat rules, encounter content, navigation, flagship builds, lineage progression, narration, and serialized save models. It has no Flutter or Flame dependencies.

The desktop app and headless simulator both use this package. `GameSession` receives commands and returns game events, while an injectable random-number source supports reproducible scenarios.

## Example

```dart
import 'package:monstrous_core/monstrous_core.dart';

void main() {
  final session = GameSession(rng: SeededGameRng(42));
  final events = session.dispatch(const BeginFirstVoyage('Mara'));
  print(session.phase);
  print('${events.length} opening events');
}
```

## Validation

From this directory, using Dart 3.13 or newer:

```powershell
dart pub get
dart analyze
dart test
```

See the [developer guide](../../CLAUDE.md) for architecture and the [documentation guide](../../docs/README.md) for current game rules and design references. Narrative documentation contains spoilers.
