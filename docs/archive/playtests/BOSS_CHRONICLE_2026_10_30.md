# Chronicle boss identity — 30 October 2026

Historical verification receipt. [Current game](../../CURRENT_GAME.md#combat-resolution-and-monster-behavior) owns current identity behavior; [PT2-13](../../BACKLOG.md#pt2-13--apex-names-are-overlong) tracks the follow-up and broader naming work.

After confirming Sargasso worked, the player reached the World Serpent and found the Chronicle opening still said “THE KRAKEN RISES FROM THE ABYSS!” [Player screenshot](../../playtests/2026-10-30/03-world-serpent-chronicle-player.png). The earlier Titan fix corrected approach calls; this separate hardcoded app-controller message remained.

The boss opening now uses `BattleStarted.monsterName` with the existing uppercase treatment and critical ambient styling. Kraken's wording is unchanged; World Serpent and Ancient Leviathan use their actual identities. Ordinary encounter text is unchanged. Intent narration also preserves an existing leading “The,” avoiding the screenshot's “The The World Serpent.” No combat rules, RNG, save data or historical Chronicle entries are rewritten.

Verification: seven core approach/intent checks passed, including all three real Titan startups, old cached approach correction and an ordinary-name article check. Seventeen app identity/Chronicle checks passed: actual controller startups for all three Titans and an ordinary encounter, plus existing modal/history/resize/Escape checks. Core/app analysis and documentation/diff checks passed. These are targeted checks for a copy-only correction; no balance simulation or native rebuild was needed. Player saves and running build output were untouched.
