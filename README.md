# The Monstrous Sea 2

A turn-based naval roguelite about an inherited ship, a cursed bloodline, and the monsters waiting beyond the harbor.

Command the Bloodbound Flagship through dangerous waters, build around its fixed armaments, and decide which risks are worth taking. When a captain falls, an heir takes command with new strengths and quirks. Recovered materials and ancestral blueprints help the family prepare for its next voyage.

A spiritual successor to the original Java console game, built with **Flutter**, **Flame**, and a **Dart gameplay engine**, with an ink-and-parchment nautical aesthetic.

**Status:** In active development and playtesting. Windows desktop is the primary development target. Combat balance, presentation, story delivery, and later progression are still evolving.

## What you can play

- **Tactical sea battles:** Read the monster's next intent, choose a helm order, and use Short, Medium, and Long range to control the fight.
- **Five flagship blueprints:** Start with Standard and unlock Ironclad, Clipper, Bombardier, and Corsair. Each has its own Broadside, Signature, and Utility hardpoints.
- **Voyage builds:** Combine shrine blessings, gold-funded hull upgrades, hardpoint tempering, and single-use belt supplies.
- **Exploration:** Choose lookout headings across three regions, finding beasts, wrecks, shrines, traders, and places to repair.
- **A continuing bloodline:** Choose an heir after defeat, invest recovered materials at home, and face the beast that took the previous captain as a Nemesis.
- **Separate lineage saves:** Continue different hunts from the title menu. A completed hunt with a saved final-choice snapshot can explore one independent alternate fate while preserving its original ending.

## Run on Windows

These instructions run the game from source. Clone or download this repository, then open a terminal in its root directory.

### Prerequisites

- Flutter with **Dart 3.13 or newer**, matching the packages' SDK constraints.
- The Windows desktop toolchain, including Visual Studio's **Desktop development with C++** workload. Visual Studio Code can be used as your editor; the native build tools come from Visual Studio.

Follow [Flutter's Windows setup guide](https://docs.flutter.dev/platform-integration/windows/setup) to install and verify the toolchain. Check your local setup with:

```powershell
flutter doctor -v
flutter devices
```

The device list should include Windows. From the repository root, launch the game:

```powershell
cd apps/monstrous_sea
flutter pub get
flutter run -d windows
```

The local gameplay package is resolved through the app's dependency configuration; it does not need to be installed separately.

## Your first voyage

1. Choose **New Lineage** at the title menu and label the save, then name your captain. A fresh profile starts with the Standard flagship and enters its first battle directly.
2. Read the monster's intent and threatened ranges before choosing your attack. Select a helm order to move with your next turn-ending action.
3. Use your Broadside, Signature, and Utility as they become available. Consumables are single-use quick actions with a per-turn limit.
4. After encounters, collect or leave supplies and choose your next heading. Seek shelter for repairs and voyage upgrades, and inspect your ship when planning a build.
5. If the captain falls, choose an heir and prepare the next voyage at home. Permanent blueprint purchases use recovered materials; upgrades earned at sea belong to that voyage.

Press **Esc** or select the pause icon to open **Resume**, **Settings**, and save/exit controls. Esc closes the current dialog first, then the pause menu. Settings adjusts text size. Hover over battle controls and status labels for their current effects, restrictions, and tactical details; the belt's question mark explains quick-item rules.

The title menu lets you select a lineage and **Continue**, start another with **New Lineage**, open **Settings**, or **Exit Game**. Each lineage keeps independent progress and its own ending. Save labels do not set captains' surnames. The pause menu identifies the current lineage and offers **Save & Return to Title** and **Save & Exit Game** at supported stops. During combat or unfinished encounters, finish the encounter and continue to Set Course first. An action already underway finishes while Pause blocks new orders; opening it does not create a mid-battle save. Completed hunts also offer **Return to Menu**.

## Playtest menu (debug builds)

Click **Playtest Menu** at the top of the window, or press **F10**, to configure a fresh test session. Choose a blueprint, hull and ancestral signature tiers, each hardpoint's Mk and blessing dedication/tier, starting gold, and a repeatable random seed. Launch at a region's opening course choices, its Titan, or the **Caldera ending choice** to test both endings without combat.

During a test, **Relaunch** resets the same scenario and seed; **Change Scenario** returns to the configuration. Close the menu to resume your normal game. Test sessions do not autosave or change your real profile.

To open the menu directly, run this from `apps/monstrous_sea`:

```powershell
flutter run -d windows --dart-define=PLAYTEST=true
```

Direct playtest startup defers loading the normal game until you return to it. The menu is available only in debug builds.

## Save data

On Windows, saves are stored in:

```text
%LOCALAPPDATA%\TheMonstrousSea2\Saves
```

`lineages.json` lists save labels and the last opened lineage. Each lineage's `player_profile.json` and `voyage_save.json` live in `lineages/<slot-id>/`. These hold permanent progress and the latest supported checkpoint, including home preparation, offered heirs and resolved endings. Individual combat turns are not saved for mid-battle resume.

Your previous single save is imported once as **Original Lineage**, preserving the source files as backups. Legacy Documents saves still import through the existing migration first. Unreadable saves show an error rather than silently starting over. Use **New Lineage** to test a fresh start without deleting your existing progress.

## Build a Windows release

From `apps/monstrous_sea`:

```powershell
flutter build windows --release
```

The x64 output is in `build/windows/x64/runner/Release/`. To share a build, include the entire release folder, including its DLLs and `data` directory, together with the executable.

## Project layout

| Directory | Contents |
| --- | --- |
| [`apps/monstrous_sea`](apps/monstrous_sea/) | Flutter application, Flame battle presentation, interface, assets, and platform storage. |
| [`packages/monstrous_core`](packages/monstrous_core/) | Gameplay rules, content, commands/events, and save models in pure Dart. |
| [`packages/monstrous_sim`](packages/monstrous_sim/) | Automated voyages and balance simulation tools. |
| [`docs`](docs/README.md) | Detailed design references, development backlog, and historical evidence. Contains story spoilers. |

## Development and feedback

For architecture, test commands, and development workflows, see the [developer guide](CLAUDE.md). The [backlog](docs/BACKLOG.md) tracks known issues and planned work; narrative references contain ending spoilers.

If you report a playtest issue, include what happened, what you expected, your region and ship blueprint, steps to reproduce it, and a screenshot when useful.
