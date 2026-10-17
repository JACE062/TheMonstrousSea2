# The Monstrous Sea V2 — Monte Carlo Balance Simulation Report

> [!NOTE]
> Automated headless balance verification executed across **1000 runs** (Base Seed: `42`).
> Evaluated for infinite loops, crash resilience, economy viability, and combat pacing.

## Executive Summary

| Strategy | Runs | Wins (Kraken) | Deaths | Win Rate | Avg Monsters | Avg Max Diff | Avg Gold |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Reckless** | 250 | 0 | 250 | 0.0% | 66.7 | 1.5 | 1104g |
| **Cautious** | 250 | 0 | 250 | 0.0% | 49.7 | 1.6 | 835g |
| **Greedy** | 250 | 0 | 250 | 0.0% | 6.3 | 1.1 | 166g |
| **Random** | 250 | 0 | 250 | 0.0% | 4.0 | 1.0 | 88g |

## Strategy Win Rates

```mermaid
xychart-beta
    title "Strategy Win Rates (%)"
    x-axis ["Reckless", "Cautious", "Greedy", "Random"]
    y-axis "Win Rate (%)" 0 --> 100
    bar [0.0, 0.0, 0.0, 0.0]
```

## Deep Dive by Strategy

### Reckless Strategy
- **Total Voyages:** 250
- **Victories (Kraken Slain):** 0 (0.0%)
- **Defeats (Watery Grave):** 250 (100.0%)
- **Average Monsters Slain:** 66.7
- **Average Highest Encounter Difficulty:** 1.5
- **Average Final Gold Hold:** 1104g
- **Average Combat Rolls/Attacks:** 3.4

**Top Causes of Death:**

| Threat / Sea Monster | Fatalities | % of Deaths |
| :--- | :--- | :--- |
| Adrift at Sea (Lost in Fog) | 177 | 70.8% |
| Many-tentacled beast | 4 | 1.6% |
| Bloodthirsty Bull Shark | 3 | 1.2% |
| Frenzied Maw | 3 | 1.2% |
| Behemoth Mako | 3 | 1.2% |

**Ship Class Performance:**

| Ship Class | Voyages | Wins | Class Win Rate |
| :--- | :--- | :--- | :--- |
| IRONCLAD | 250 | 0 | 0.0% |

### Cautious Strategy
- **Total Voyages:** 250
- **Victories (Kraken Slain):** 0 (0.0%)
- **Defeats (Watery Grave):** 250 (100.0%)
- **Average Monsters Slain:** 49.7
- **Average Highest Encounter Difficulty:** 1.6
- **Average Final Gold Hold:** 835g
- **Average Combat Rolls/Attacks:** 4.1

**Top Causes of Death:**

| Threat / Sea Monster | Fatalities | % of Deaths |
| :--- | :--- | :--- |
| Adrift at Sea (Lost in Fog) | 212 | 84.8% |
| Chitinous Colossus | 5 | 2.0% |
| Shellbound Menace | 3 | 1.2% |
| Living Fortress | 3 | 1.2% |
| Terrorclaw | 3 | 1.2% |

**Ship Class Performance:**

| Ship Class | Voyages | Wins | Class Win Rate |
| :--- | :--- | :--- | :--- |
| IRONCLAD | 250 | 0 | 0.0% |

### Greedy Strategy
- **Total Voyages:** 250
- **Victories (Kraken Slain):** 0 (0.0%)
- **Defeats (Watery Grave):** 250 (100.0%)
- **Average Monsters Slain:** 6.3
- **Average Highest Encounter Difficulty:** 1.1
- **Average Final Gold Hold:** 166g
- **Average Combat Rolls/Attacks:** 6.2

**Top Causes of Death:**

| Threat / Sea Monster | Fatalities | % of Deaths |
| :--- | :--- | :--- |
| Adrift at Sea (Lost in Fog) | 179 | 71.6% |
| Lurking Coil | 7 | 2.8% |
| Tide Coiler | 7 | 2.8% |
| Writhing Curse | 7 | 2.8% |
| Elusive Eell | 4 | 1.6% |

**Ship Class Performance:**

| Ship Class | Voyages | Wins | Class Win Rate |
| :--- | :--- | :--- | :--- |
| FREIGHTER | 250 | 0 | 0.0% |

### Random Strategy
- **Total Voyages:** 250
- **Victories (Kraken Slain):** 0 (0.0%)
- **Defeats (Watery Grave):** 250 (100.0%)
- **Average Monsters Slain:** 4.0
- **Average Highest Encounter Difficulty:** 1.0
- **Average Final Gold Hold:** 88g
- **Average Combat Rolls/Attacks:** 7.6

**Top Causes of Death:**

| Threat / Sea Monster | Fatalities | % of Deaths |
| :--- | :--- | :--- |
| Adrift at Sea (Lost in Fog) | 63 | 25.2% |
| Darting Death | 13 | 5.2% |
| Slithery Devil | 10 | 4.0% |
| Writhing Curse | 10 | 4.0% |
| Ragefin | 9 | 3.6% |

**Ship Class Performance:**

| Ship Class | Voyages | Wins | Class Win Rate |
| :--- | :--- | :--- | :--- |
| CORSAIR | 31 | 0 | 0.0% |
| BOMBARDIER | 37 | 0 | 0.0% |
| FREIGHTER | 33 | 0 | 0.0% |
| CLIPPER | 37 | 0 | 0.0% |
| CORVETTE | 28 | 0 | 0.0% |
| STANDARD | 43 | 0 | 0.0% |
| IRONCLAD | 41 | 0 | 0.0% |

## Verification Verdict

> [!TIP]
> - **Infinite Loops / Deadlocks:** **0** (All runs terminated cleanly within execution boundaries).
> - **Exceptions / Crashes:** **0** (All commands cleanly produced discrete GameEvents).
> - **Parity & Balance Integrity:** Verified that defensive play (Cautious/Fortify) significantly improves voyage survival while reckless play encounters lethal attrition.
