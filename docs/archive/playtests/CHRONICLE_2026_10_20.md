# Chronicle voyage history and scrolling — 20 October 2026

Completion evidence for the lifecycle and scrolling follow-ups within PT2-11. The current backlog retains the unresolved command-station layout, log reading space, intent placement and floating-feedback design work.

## Implemented behavior

The controller previously accumulated messages without clearing them for a new voyage. It now clears after a successful heir selection or fresh home departure and before appending the new events. The dead captain's messages remain available until succession. Ordinary rewards, subsequent encounters and stronghold departures retain the current voyage's earlier messages. Invalid commands do not clear the log.

The Chronicle owns its scroll state. Opening a battle or reopening the hidden Chronicle starts at the latest messages before any player action. Layout settlement accounts for lazy variable-height entries and changed viewport dimensions. Incoming entries follow only while the reader stays at the live end. Scrolling back pauses automatic following; Latest Messages resumes it. The battle screen no longer jumps the log after dispatch or animation completion.

The Chronicle remains session memory; no combat-log save schema or separate historical archive was added. No gameplay balance, art assets or broader battle layout changed.

## Verification

- Flutter analysis clean; all **174 app tests passed** under the disposable test-storage guard.
- Three controller regressions exercise actual sinking and succession through a third voyage, fresh-start opening events, compatibility home-to-helm departure, retained ordinary-reward/stronghold history, and rejected-command behavior.
- Five widget cases exercise long variable-height histories at 360/1280px with 115%/130% text, initial positioning without an action, live append, drag and mouse-wheel history reading, append/resize while reading, return to latest, a new encounter view, and a short 48px log panel.
- One additional real battle-scene case verifies initial position, actual cannon dispatch/event playback while reading history, and hiding/reopening the Chronicle. The existing art-recovery tests continue to pass.
- A font-loaded widget run passed all nine battle-art/Chronicle cases. Readable 1280px/130% captures were inspected in `apps/monstrous_sea/build/art-recovery-chronicle-history.png` and `art-recovery-chronicle-latest.png` (ignored review output). The return control fits within the current panel; these are widget/engine captures with system fallback fonts, not native replay or approval of the full command-station design.
- No native rebuild replaced the output used by the running player game. Core/simulator behavior was unchanged, so their broad suites were not repeated. Production saves were not used by fixtures or repaired.

Documentation/link checks and diff review accompany this receipt. Player replay should confirm the interaction in ordinary multi-encounter voyages; the broader PT2-11 remains open.
