# Isolated combat presentation comparison

User-authorized two-hour evaluation, started `2026-10-27T05:05:09Z`, deadline `2026-10-27T07:05:09Z` (26 October 23:05 → 27 October 01:05 America/Denver).

This is a synthetic battle-presentation fixture. No production rules, save code or combat UI changes. Parent owns this brief, shared fixture/art, audit and media conversion. Workers own only their assigned engine directory plus engine-specific evidence. Follow root AGENTS.md.

## Shared contract

- Both read the actual `fixture.json` and byte-identical `assets/ship.png`, `assets/monster.png`, `assets/font.ttf`; no engine-specific invented outcomes.
- Real render size 1000×620, 30 fps, 10 seconds of logical time. Native Windows preferred; report any fallback. No runtime performance claims from frame capture speed.
- In baseline, playback speed is 1× and each hit applies barrier consumption and hull HP at its impact. Do not implement the later maintenance change yet.
- Represent a moving ship, monster attack impact, barrier absorption, four separately visible hits, Burn application/tick/expiration. Persistent status badges and short impact numbers may explain events; do not replace them with a log or written recap.
- Use simple neutral labels/geometry. The scene is not a proposed redesign. Clear engine name and baseline/revised designation; same font and visual requirements.
- Parchment `#f3ead7`, ink `#211d18`, hull gold `#b98b00`, enemy red `#9c302e`, barrier blue `#398a99`, Burn orange `#c26a20`.
- Suggested consistent geometry: title at (30,24); ship HP label/bar at (30,105)/(30,145,440,20); monster HP label/bar at (560,105)/(560,145,410,20); bearing at (400,185); combatants at fixture coordinates, both PNG scales 0.24; status badges near ship at y=450; impact feedback near affected combatant at y=250; lower margin may identify fixed fixture and speed. No large permanent event list.
- Export actual rendered PNG frames under `evidence/<engine>/<run>/frames/frame_0000.png` etc. Logical time of frame i is `i * 1000 / 30 * speed`, ending at >=10000ms. Prefer deterministic stepping over real-time screenshots.
- Export `trace.json` containing engine/version/renderer, fixture SHA256, speed, timing parameter, per-frame logical time, displayed HP/barrier/status/bearing/ship x and observed event markers. State should be the state actually driving rendering, not a separate expected-output function.
- Report source editing/build/run friction honestly. Keep baseline source snapshot and logs before the later patch. Use isolated app/profile paths; never access production saves. Engine may use custom capture/test hooks, which must be disclosed.

## Follow-up and completion

After a working baseline is frozen, parent will give both workers the same maintenance change. Record that edit and verification separately. Root will verify both against independent expected fixture facts, inspect actual frames/recordings, encode videos and make the comparative recommendation. Do not start migration.
