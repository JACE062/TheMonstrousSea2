# Project guidance

Read `CLAUDE.md` for architecture, gameplay rules, and verification commands. The subagent policy below is an explicit user preference and applies to all delegation in this project.

## Subagent model and effort policy

Choose the model and reasoning effort for each task before delegating. Set both explicitly; do not inherit the main chat's model or effort by omission.

| Task | Model | Reasoning effort |
| --- | --- | --- |
| Targeted searches, documentation, straightforward UI/copy changes, mechanical edits | `gpt-6-luna` | `medium` |
| Gameplay logic, persistence, debugging, refactors, implementation spanning connected files, substantive code review | `gpt-6.1-sol` | `medium` |
| Difficult architecture, complex edge cases, or a concrete unresolved problem after a focused attempt | `gpt-6.1-sol` | `high` |
| Exceptional work that still needs Astra | `gpt-6-astra` | Only the effort explicitly approved by the user |

- Default to Sol Medium when the task does not clearly fit a lighter category. Escalate only for an identified difficulty; do not raise every worker's effort automatically.
- Astra requires explicit user approval before spawning or reactivating an Astra worker. An instruction to use agents generally is not approval for Astra.
- This policy governs how to select agents when delegation is authorized; it does not require delegation for every task. Do small fixes directly. Use the fewest agents needed, usually one or two for separable work.
- Give a fresh worker a concise, self-contained brief: goal, owned files, relevant decisions, interfaces, constraints, and targeted validation. Avoid copying the full conversation.
- With the `collaboration.spawn_agent` interface, use `fork_turns="none"` and supply the explicit `model` and `reasoning_effort`. Include necessary context in the brief. If another interface offers named/custom agents, ensure the selected preset matches this table and does not override it with a more expensive model.
- Do not reuse existing workers whose model/effort is unknown or does not match the task. Create a correctly configured replacement; completed older Astra workers should remain idle.
- Check source code and available documentation rather than guessing APIs. Require evidence for claims, appropriate tests for behavior changes, and review the actual diff before integration. Higher reasoning effort is not a substitute for verification.
- Keep agent outputs concise: changes, verification, remaining uncertainties. Do not repeat broad test suites when no new change or unresolved concern justifies it.
- If a selected model is unavailable or the runtime cannot apply the requested settings, report the limitation. Do not silently fall back to Astra or claim the settings were applied.
