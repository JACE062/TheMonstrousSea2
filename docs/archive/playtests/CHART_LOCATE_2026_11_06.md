# Vessel location and concise service reports — 6 November 2026

Implemented the next player follow-up under [PT2-08](../../BACKLOG.md#pt2-08--sea-chart-needs-a-clearer-player-purpose). [Current game](../../CURRENT_GAME.md#chart-bounds-and-marginalia--5-november-2026) owns delivered behavior. The player likes the bounded chart and Center Journey; icon replacements remain deferred.

Find Vessel and End retain the current zoom and target the visible ship illustration at the center of waters clear of floating reports. Existing camera limits still apply, so exact centering can be restricted near an edge. The illustration’s offset above its arrival node is included. Center Journey and the zoom/pan limits retain their behavior.

Pre-Titan reports now read “Shipwright station to port. Paid hull repairs and voyage refits.” and “Specialist merchant to starboard.” `CourseOption.displayLookoutCall` supplies the same concise copy to layout measurement and rendering, including when the plan was saved with older prose. Stored calls/history are retained without a save rewrite or migration. Fresh plans use the shorter strings. Service mechanics, icons and provisional economy tuning are unchanged.

## Verification and preservation

- **31 font-loaded UI checks passed**, including rendered ship centering at 3×, closest permitted centering at 90%, unchanged zoom for button/End, horizontal/diagonal bounds, chart JSON preservation, compact/desktop layouts and restored older service callouts without plan mutation.
- **25 existing chart rules/restoration tests passed**; app and core analysis are clean. These are focused checks, not a new full-suite or simulator/balance run.
- **Windows Debug build succeeded** under `.dart_tool/chart-locate-preview/`, using exact final app sources/assets, matching dependency lock and the original local core package. The normal game was running; its bundle, older previews and player saves were left untouched. The agent compiled but did not launch the new preview. Close the running game before opening it because normal instances share storage.
- Six selected final captures are retained. The visible-ship centering and concise desktop reports were inspected; compact checks retain wrapping/page scrolling. The player’s [pre-boss screenshot](../../playtests/2026-11-06/chart-locate/01-pre-boss-callouts.png) is copied byte-for-byte. Earlier audit/evidence directories and the simulator remain unchanged.

Code commits are `df81165` (camera) and `f17ec3e` (service copy). The documentation/evidence commit is separate. The [manifest](evidence/chart-locate-2026-11-06/manifest.json) retains full commit IDs, source/input/artifact hashes, final check output and native source verification. Human replay remains useful for this camera/copy refinement.
