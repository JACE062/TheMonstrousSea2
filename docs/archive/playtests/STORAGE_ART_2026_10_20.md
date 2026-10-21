# Test-save isolation and battle-art recovery — 20 October 2026

Completion evidence for the verified unsafe test-write path in PT2-27 and recovery handling in PT2-25. Current rules and outstanding limits remain in the live reference set.

## Unpaid blueprint ownership: verified test leakage

The production purchase handler does spend materials correctly. The broader audit found twelve legacy controller constructors across seven UI test files with default autosave and no injected directory. Several fixtures directly add Ironclad/other unlocks to their test profiles, then dispatch commands. Windows storage resolves through LocalAppData directly, so these fixtures could write their artificial profiles to the player's real save directory. This is not an affordability-check bug.

The isolation regression reproduces that exact pattern in a disposable directory: a default-autosave controller writes Ironclad ownership despite having no materials and issuing no purchase. This verifies the mechanism without writing production saves. It is consistent with the player's report, but no historical transaction trail exists to prove which earlier fixture write produced the observed first-visit state.

All twelve constructors now disable autosave. Persistence tests still use explicit disposable directories. The root Flutter test configuration additionally installs a disposable default directory during the suite's actual setUpAll/tearDownAll lifetime. A main-only zone wrapper was insufficient because test bodies run later in runner-owned zones; the regression caught that intermediate design. Explicit directories take priority over scoped async overrides and the suite fallback. Injected defaults skip legacy migration, so real legacy saves cannot be imported into fixtures. Production processes leave the override unset and retain the normal save location.

**Correction:** Earlier blanket statements that full app verification left production saves untouched were not established. Inherited fixtures were missed even though newer targeted tests explicitly isolated storage. The earlier stronghold/combat/navigation receipts now carry dated corrections. Their test counts remain historical results, not evidence of storage isolation. No current player profile was relocked, charged or repaired during this work.

## Missing illustrations: recoverable scene loading

The Standard PNG exists in both source and the current Windows bundle with matching SHA-256 `AEB057AF7CB85F7FA7522A1B1996F3B532DB5521CB6AF0A29D53B325AEF6EB33`. Repeated cold scene loads using the full approved asset paths succeed. The original intermittent absence is not reproduced; the file's present existence does not explain that earlier event.

Injected missing-file tests exposed another issue: Flame 1.38.2's image cache forks failed futures through internal `then` calls without error handlers. Simply catching the caller's load exception still emits unhandled errors. The scene now reads/decodes first and inserts only successful images into its local cache. The normal approved illustrations remain unchanged.

When an illustration fails, a labeled cartouche replaces only that visual, and its health panel offers Retry Art with a readable explanation. The game/event queue still loads, weapon actions finish and unlock normally, and retry does not reset the current fight. Only failed assets are retried; a failed retry remains available, and completion after scene removal is safe. The old generic fallback ship/creature sketches are replaced by explicit structural placeholders rather than new entity art.

## Verification

- Flutter analysis clean. All **165 app tests passed** under the disposable default-storage guard. The gameplay engine and simulator were unchanged; their broad suites were not repeated.
- Two new isolation cases cover forgotten default autosave, an unpaid fixture unlock reaching only disposable storage, explicit-directory precedence, nested async scopes and disabled implicit legacy import. Existing storage migration and profile purchase tests also pass.
- Eight new art cases cover repeated cold loads, missing ship art at 360/1280px and 115%/130% text, an undecodable PNG, both missing illustrations, repeat failure/recovery, actual weapon action completion, and removing a scene while retry is pending. Cold scene startup is performed in real async time without separately prewarming assets; this avoids the widget test's fake-clock codec deadlock.
- A separate font-loaded widget run checks the recovery view with readable system fonts and material icons. Captures `apps/monstrous_sea/build/art-recovery-missing.png` and `art-recovery-recovered.png` are ignored local review output. They show the unavailable/retry notice and restored approved art. These are widget/engine captures, not a native window replay or final themed-font approval.
- No Windows rebuild/native integration run was performed against the shared output because a game process was running from it. The user's active executable and its bundle were left in place. The original intermittent file-loading trigger still needs player replay.

Documentation/link checks and the final diff check accompany this receipt. No art generation, economic rebalance, retroactive material charge or player-save repair is part of the change.
