# Flutter + Flame isolated evaluation

This standalone Windows app does not import the production app or core and never initializes save storage. It bundles byte-identical copies of the shared fixture, ship, monster and font.

Run from this directory with the installed Flutter SDK:

```powershell
C:/flutter/bin/flutter.bat pub get --offline
C:/flutter/bin/flutter.bat analyze lib
C:/flutter/bin/flutter.bat build windows --release --no-pub
./build/windows/x64/runner/Release/combat_comparison.exe --out=C:/absolute/output/path
```

The executable automatically exports actual native rendered 1000x620 PNGs and exits. A paused `FlameGame` advances through Flame's `stepEngine`; game state notifies a Flutter HUD. `RepaintBoundary.toImage` captures the composed GameWidget and HUD after `endOfFrame`. It is an offline deterministic capture hook, not real-time playback or a frame-rate benchmark. Trace values come from the live game and the HUD builder used by that captured frame.

The synthetic fixture supplies all outcomes. Flame renders the art, movement, waves, impact strokes and floating feedback. Flutter renders bars, labels and persistent statuses. It is neutral comparison geometry, not a proposed production UI.
