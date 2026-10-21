# Navigation and salvage verification — 20 October 2026

Historical completion receipt for PT2-09, PT2-10, PT2-15 and PT2-16. Current behavior belongs in `docs/CURRENT_GAME.md`; player replay remains useful. The separate missing Standard ship asset report is PT2-25 and is not resolved by this work.

## Flow and restrictions

After loot claims/explicit abandonment, the app controller resolves the engine's compatibility Rest checkpoint with `TakeHelm` before one UI notification. Ordinary rewards reach Setting Course; Titan rewards reach the next stronghold or final resolution. Full-belt loot remains a decision rather than being skipped. Inspection defaults closed below the headings. Emergency triage remains available at the helm, retaining the original 25% hull floor and two-gold-per-HP cost. Island, shrine and wreck decisions keep their own screens.

Older Rest checkpoints follow this route on load. Production autosave records the resulting offered courses once; reload restores those offers. Reward checkpoints retain pending items and the victory-gold banner without awarding gold again. Completed-encounter state is used by the chart after reload even when no live monster object remains.

AnimatedSwitcher retains departing screens for its 350ms fade. Helm now freezes its rendered departure view instead of reading a chart that has already advanced. A steering guard prevents duplicate activation. Current/outgoing transition wrappers retain identical keyed structure while disabling outgoing pointer/focus input; a regression caught and corrected an intermediate implementation that recreated the outgoing screen and lost its state.

Quirk restrictions use the same engine explanation in both validation and presentation. Reckless Helmsman's Dead Ahead course is visibly disabled with persistent text, tooltip and semantic hint. Blood Oath disables alternatives to the offered Nemesis. Guaranteed Haven/Titan convergence remains reachable. This work preserves the existing between-encounter checkpoint policy; it does not add mid-combat resume or serialized RNG state.

## Approved wreck rewards

The player accepted Search Hold always granting 2–4 Sea Glass, with independent rolls for 1 Depth-Wrought Iron at 25% and one single-use consumable at 50%, in every region. Strongbox retains 60–120 gold plus 2–4 Sea Glass; timbers retain up-to-25% hull healing under existing penalties plus 1–2 Sea Glass. Copy matches these rewards and no longer promises weapons.

The receipt shows actual quantities, item identity, gold or healing, including no usable consumable and zero hull healing. Wreck snapshots retain the spent choice, receipt, name, current ship and pending overflow. Full belts expose jettison/stow/leave decisions; both departure commands reject unresolved supplies. Reload cannot salvage the wreck again. Bots explicitly leave overflow rather than attempting an invalid departure.

## Verification and limits

- Core analysis clean; 452 tests passed. New deterministic cases cover both probability boundaries in all three regions, reward types, no-item/zero-healing receipts, full-belt claim/discard, checkpoint round trips, duplicate-salvage rejection, matching quirk enforcement and convergence exceptions.
- Simulator analysis clean; 33 tests passed. The separate 1,000-voyage audit completed with zero crashes or loops: 250 fresh Standard voyages per Reckless/Cautious/Greedy/Random strategy, base seed 42 and the existing Random strategy seed 777. Kraken victories were 0/1/1/0, versus 0/1/1/1 in the preceding tentacle receipt. Changed salvage rewards also change RNG consumption; this is a routing/regression audit, not a controlled combat-balance comparison or human win-rate target. Other blueprints remain locked and the audit stops at the first Kraken.
- App analysis clean; 153 tests passed. New tests cover all ordinary loot commands, full/empty loot, direct routing after each Titan, preserved blessings, real battle loot saved/reloaded without duplicate gold, old Rest migration with stable saved offers, emergency triage, outgoing offers during transition, duplicate activation, visible restrictions and wreck overflow handling. Existing startup/migration expectations now reflect direct course entry.
- Two native Windows checks passed at 115% and 130% text with readable system fallback fonts. Ignored captures in `apps/monstrous_sea/build/` include `wreck-receipt-native-*`, `wreck-feedback-native-*`, `helm-arrival-native-*` and `helm-feedback-native-*`. These exercise the receipt, full-belt controls and blocked-course explanation; they do not complete the deferred command-station redesign or themed-font review.
- Tests and simulations use isolated state/storage. Production saves were untouched, and no art was generated or replaced. The supplied missing-asset screenshot is preserved separately as PT2-25 evidence.


## Later correction — inherited UI fixtures were not fully isolated

An audit on 20 October 2026 found older UI/art fixtures with default autosave and no injected storage. Full app test runs that included those fixtures could overwrite production profiles with fixture data, including unpaid blueprint unlocks. Earlier blanket statements that verification left production saves untouched were not established for those runs; the passing test counts above do not prove isolation. The specialized tests that explicitly disabled autosave/injected storage remain distinct from that inherited full-suite risk. The fixtures are now corrected and a tested per-suite disposable storage fallback protects future default controllers. See the test-save isolation and battle-art receipt in the archive index and PT2-27 in the live backlog. No historical test result is being relabeled as a storage-isolation check.
