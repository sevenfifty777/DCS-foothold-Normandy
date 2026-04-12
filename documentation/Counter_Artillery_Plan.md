# Counter-Artillery Mission Plan (WIP)

## Concept

When a UK ARTY group reaches its fire point and calls `startFiringAtZone()`, the system detects it and spawns a Red aircraft specifically tasked to hunt and destroy that artillery group.

---

## Detection Hook — where to intercept

**Best location: inside `BattleCommander:startFiringAtZone()`** in `zoneCommander_moose-Custom_WWII_new.lua`

This function is called exactly once per group when it reaches its fire point and opens fire. It is the cleanest single-event hook — no polling needed, no duplicates.

Currently it:
1. Marks `gc._artilleryOnStation = true`
2. Starts the repeating 10-minute fire timer

We add **step 3**: call a new `bc:_triggerCounterArtillery(groupname, zonename)` function right after.

---

## Information Available at Detection Time

| Data | Source |
|---|---|
| Artillery group name | `groupname` parameter |
| Target zone being shelled | `zonename` parameter |
| Artillery group live position | `Group.getByName(groupname):getUnit(1):getPoint()` |
| Artillery origin zone | `gc.zoneCommander.zone` |
| Artillery coalition side | `Group.getByName(groupname):getCoalition()` — react only when side == 2 (Blue/UK) |

---

## Response Logic — `_triggerCounterArtillery()`

### Step 1 — Guard checks
- Ignore if the firing group is Red (side 1) — we only counter Blue arty
- Ignore if a counter-arty response is already active for this group (tracked via `_counterArtyActive[groupname]`)
- Ignore if no Red airbase zone is active and within reasonable range

### Step 2 — Find a responding Red airbase
- Scan all active Red `zones` that have an airbase (`zone.airbaseName ~= nil`)
- Pick the one closest to the arty group's current live position
- Optional: add a maximum range cap (e.g. skip if nearest Red base > 80 nm)

### Step 3 — Spawn the response aircraft
- Spawn from a dedicated ME template (e.g. `AXE_CounterArty_Fw190`) at the responding airbase
- Inject a waypoint toward the arty group's live position
- Aircraft targets the specific ground group by name

### Step 4 — Track and clean up
- Register `_counterArtyActive[groupname] = true` immediately on spawn
- Cleanup runs in the existing 60s scheduler — when `gc._artilleryOnStation == nil` (group dead or back in hangar), the entry is removed from `_counterArtyActive`
- This re-arms the counter for the next deployment of that arty group

---

## Aircraft Tasking Options

| Option | Complexity | Notes |
|---|---|---|
| **A. Reuse existing GroupCommander** | Low | Set `urgent=true` on an existing Red CAS mission targeting the arty's origin zone. Simple but aircraft won't know the exact fire point. |
| **B. Dedicated counter-arty template** | Medium | New ME group e.g. `AXE_CounterArty_Fw190` per airbase. Spawned via MOOSE with a waypoint injected to the arty's live position. Most accurate. |
| **C. Modify existing attack GroupCommander dynamically** | Medium-High | Temporarily override `targetzone` on a sleeping Red attack GC and force-spawn it. Reuses existing framework fully. |

**Recommended: Option B** — clean, purpose-built, gives control over aircraft type per airbase, and the live position waypoint makes the intercept genuinely useful.

---

## Data Flow Summary

```
UK ARTY group reaches fire point
  └─► startFiringAtZone() called
        └─► [NEW] _triggerCounterArtillery(groupName, targetZoneName)
              ├─ Guard: is it Blue? Already responded?
              ├─ Find nearest active Red airbase zone
              ├─ Get live arty group position
              ├─ SPAWN "AXE_CounterArty_<template>" with injected waypoint
              └─ Mark _counterArtyActive[groupName] = true

Scheduler (60s) cleans up:
  └─► For each entry in _counterArtyActive:
        └─ If gc._artilleryOnStation == nil → remove entry (re-arms for next cycle)
```

---

## Mission Editor Preparation Required

- One or more ME group templates named e.g.:
  - `AXE_CounterArty_Fw190`
  - `AXE_CounterArty_Bf109`
- Groups should be placed at a Red airbase with `late activation = true`
- No anchor trigger zones needed
- No new script trigger zones needed

---

## Implementation Files

- **Modified**: `scripts/new templates logic/WWII_Normandy_Foothold_Custom_v2.5.3/zoneCommander_moose-Custom_WWII_new.lua`
  - Hook inside `BattleCommander:startFiringAtZone()`
  - New function `BattleCommander:_triggerCounterArtillery()`
  - Cleanup logic inside the existing 60s scheduler
- **Modified**: Mission `.miz` — add counter-arty ME templates at Red airbases
