# The Monstrous Sea 2 — Desktop app

The Flutter application for The Monstrous Sea 2, with Flame battle rendering, the ink-and-parchment interface, curated art, and platform save storage.

See the [project README](../../README.md) for an overview, Windows setup, how to play, and release-build instructions.

From this directory, with the Windows Flutter toolchain installed:

```powershell
flutter pub get
flutter run -d windows
```

App validation:

```powershell
flutter analyze
flutter test
```

The test harness uses disposable save directories. For architecture, persistence behavior, and native verification guidance, see the [developer guide](../../CLAUDE.md).
