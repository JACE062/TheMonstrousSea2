# Documentation guide

For a game overview, setup instructions, and how to play, start with the [project README](../README.md). This directory contains the detailed development and design references, including story spoilers.

Start here for The Monstrous Sea V2. This guide replaced the overlapping handoff, original remake plan, and milestone specifications on 20 October 2026.

## Current reference set

| Document | Owns | Read when |
| --- | --- | --- |
| [Current game](CURRENT_GAME.md) | Approved gameplay rules, implemented baseline, and explicitly retired systems. | Implementing or reviewing game behavior. |
| [Lore](LORE.md) | Narrative canon, spoiler boundaries, and the distinction between story intent and delivered presentation. | Writing story, naming, or narrative UI. |
| [Backlog](BACKLOG.md) | Open playtest issues, pending design decisions, deferred art, and future feature scopes. | Choosing or implementing the next task. |
| [Developer guide](../CLAUDE.md) | Architecture, source navigation, tooling, and verification. | Changing or validating the repository. |
| [Agent guidance](../AGENTS.md) | Documentation reading contract and the user's model/effort policy. | Delegating or choosing project context. |
| [Platform decision](decisions/0001-platform.md) | Accepted Flutter + Flame / pure Dart boundary. | Reconsidering technical architecture. |

The [asset manifest](art/sea_map_art_manifest.json), [art revision records](art/sea_map_revisions_v5.json), and [approved chart markers](art/chart_icon_prompts.json) are visual evidence for asset work. They do not define gameplay. [Playtest screenshots](playtests/2026-10-20/) remain available as evidence.

## Authority and status

1. The user's current instructions and explicitly accepted decisions take precedence.
2. Use the current reference set for approved behavior. Read the relevant backlog items alongside it: known implementation bugs are not new design rules.
3. Source code and tests establish what is implemented. If they conflict with an approved rule, record or investigate the discrepancy; do not silently rewrite the intended game to match the bug.
4. Historical documents are context only. Their old “approved,” “locked,” “source of truth,” or “final” labels apply to their original milestone and confer no current authority.

Use these status terms consistently:

| Status | Meaning |
| --- | --- |
| Implemented baseline | Present in the current implementation; still subject to recorded bugs. |
| Approved target / known gap | Required behavior whose implementation is incomplete or incorrect; link its backlog item. |
| Proposed / pending decision | An idea requiring agreement before its unresolved details become requirements. |
| Deferred | Retained future work, with its scope and dependencies stated. |
| Historical / superseded | Preserved evidence that must not be used as an implementation brief. |

Completed work and historical test counts belong in the archive. An old passing suite does not establish that a new playtest issue is resolved. Do not treat a compatibility enum, saved field, obsolete comment, or legacy test helper as approval to restore its former mechanic.

## Current work

The [October 20 backlog](BACKLOG.md#recommended-work-chunks) contains PT2-01 through PT2-27, the six original screenshots, and follow-up death-ledger evidence. Each issue records its status. Nemesis placement, captain-count investigation, and stronghold/home-port continuity are implemented, with player replay still valuable. Serpent evasion, ink feedback and the Kraken release are also corrected. A successful player Kraken replay used a shrine-heavy route and timed defenses; keep the current damage while evaluating more builds/routes. The initial squid/tentacle scaling fix is now implemented with predictable sweeps, live barrage previews and continued per-hit damage growth in later regions; player replay should evaluate later-region difficulty. Navigation flow and explicit wreck outcomes are also implemented, with positive player replay reported. The heir Boon/Quirk rework is tracked as PT2-26: the full eight/eight roster is implemented, with mixed-build and later-region player replay still valuable; recent-offer weighting remains a proposal. The ship-asset failure now has tested recovery/retry handling (PT2-25), with the original trigger still unconfirmed. A verified test-save leak capable of creating unpaid Ironclad ownership has been fixed (PT2-27), and prior blanket storage-isolation claims are corrected in the receipts. Story/name decisions and UI layouts remain separate design work. Master Refits remain deferred Phase 4 work; art generation is also deferred.

PT2-11 now includes the event-by-event displayed-state foundation and the user-selected command-station trial: two weapon cards plus utility, a responsive helm/actions split, brief lookout with Inspect, and modal Chronicle. The Chronicle preserves current-voyage history and deliberate reading, including reopening during the same battle. Player replay is still needed for comprehension, pacing and layout. The supporting [combat UI discussion record](design/combat-ui.md) separates selected trials from open concepts; spatial movement, threat zones and status icons remain separate work.

A substantial [core content and compatibility cleanup](BACKLOG.md#deferred-core-cleanup) is recorded as FUT-05 on 21 October 2026. It covers vestigial ship/weapon content, Titan naming and duplicated text sources; implementation is deferred pending a reachability and save-compatibility inventory.

The revised Caldera endings are integrated into the runtime choice, narration and readable outcome screens. Ending acknowledgement and offered heirs persist across restart; cinematic epilogues and Ancestral Chronicles remain deferred under FUT-04. See [ending canon](LORE.md#the-caldera-and-ending-choices) for spoilers and [current behavior](CURRENT_GAME.md#meta-progression-heirs-and-endings) for the implementation.

The debug [playtest menu](../README.md#playtest-menu-debug-builds) launches configurable builds at region starts, Titans or the Caldera choice, with isolated unsaved sessions and repeatable seeds. This supports faster replay of the remaining backlog without changing real lineage progress.

The normal title menu now selects independent lineage saves, creates fresh hunts without deleting completed ones, and offers Settings/Exit. Supported stops and completed endings can save and return to it. Existing single saves migrate once as Original Lineage with source backups; see [FUT-06](BACKLOG.md#completed-hunts-lineage-saves-and-alternate-fates) for the delivered save features, one persistent alternate fate from a dedicated pre-choice snapshot, and the still-deferred Chronicles work.

## History and maintenance

Use the [archive index and disposition ledger](archive/README.md) only when a task needs historical rationale. The archive preserves source documents and records where every original section was retained, superseded, or left as history. Normal ripgrep searches exclude it through [`.rgignore`](../.rgignore). To deliberately inspect history, scope an explicit `rg --no-ignore` search to `docs/archive`.

- Update a rule in its owning current document instead of appending a competing specification elsewhere.
- Keep observations, accepted requirements, and proposals distinguishable in the backlog. Preserve stable issue IDs and evidence links.
- When work finishes, update the issue status and current rule if necessary; do not turn completed task briefs into competing live manuals.
- Preserve approved art and historical evidence. Moving documentation does not authorize changing game code, save formats, or art assets.
- Run `python tools/check_docs.py` after documentation changes. It checks links/anchors, archive integrity and section coverage, and retention of the original playtest items and screenshots.
