# Alternate fate and page framing — 21 October 2026

FUT-06 step 3 implements the user's accepted rule: one persistent alternate branch per completed original lineage. The title menu creates it from a dedicated unresolved-Caldera snapshot, then resumes the same independent save on later visits. The original Shatter ending is preserved. Branches cannot create further branches. No rewards transfer between saves and no ending command is replayed during branch creation.

## Save boundaries

- The app captures a deep-copied profile/voyage envelope at the final-choice checkpoint and before resolving a loaded choice. Publication uses a flushed temporary-file rename before resolved-ending saves. Failed snapshot writes remain retryable, including before a final menu/exit save.
- Later voyages update the snapshot when they reach their own final choice, retaining prior Covenant history/materials. Ordinary checkpoint saving never rewinds gameplay to this file.
- Branch creation writes both destination files before catalog publication. A stable hashed identity allows interrupted publication to retry. An existing catalog branch is loaded as-is; malformed existing saves fail instead of becoming fresh branches.
- Older completed saves without a valid snapshot remain readable. Their other fate is unavailable; the implementation never reverses a resolved ending or invents missing progression.
- Debug scenarios remain unsaved. All verification used disposable directories or in-memory services, without reading or modifying player saves. Existing separate profile/checkpoint crash-atomicity and multi-process catalog limitations remain.

## Page frame

The playtest host and lineage route now contribute headers through a shared scope. The page scaffold includes them and its fixed footer inside the cartouche inset, rather than framing only the central body. The prologue keeps its scrollable reading area, fixed Embark action and existing wording. Loading/error pages and debug scenario headers use the same composition; the battle arena remains intentionally frameless.

## Verification

- Full app suite: **255 tests passed**, Flutter analysis clean.
- Two subsequently added edge-case regressions pass with the focused storage/snapshot suite (**20 cases**): preserving prior Covenant progression in a later snapshot and refusing to replace a damaged published branch. No production code changed after full-suite validation.
- Storage checks cover exact pre-choice state, byte-preserved original ending files, independent Claim rewards/heirs, restart and repeated/concurrent branch requests, interrupted catalog publication, unreadable/missing snapshots and forbidden nested branches.
- Controller checks cover immediate resolution of a loaded choice, snapshot immutability during later saving, retry after snapshot failure, and unsaved debug sessions. Menu checks cover create/retry/Claim/return/resume wiring.
- Full-app frame containment checks cover 360×900 and 1600×1000 at 115% and 130% text. Readable fallback-font captures were inspected at both sizes under ignored `apps/monstrous_sea/build/framed-intro-{360,1600}.png`. These are widget captures, not final themed-font approval or native gameplay verification.
- Documentation and whitespace checks pass. No core combat rules or simulator behavior changed. Player replay of normal completed lineages and alternate Covenant progression remains valuable.
