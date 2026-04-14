# WWII Coalition Aircraft Filtering

Dynamic warehouse filtering that enforces period-correct aircraft availability per airbase. Allied aircraft are only available at Blue-held airbases; Axis aircraft only at Red-held ones. The filter updates automatically on every zone capture.

---

## How It Works

Three config lists in `Foothold Config.lua` drive the system:

| List | Purpose |
|---|---|
| `blueAircraftWWII` | Aircraft available at Allied (Blue) airbases |
| `redAircraftWWII` | Aircraft available at Axis (Red) airbases |
| `excludedAircraftWWII` | Modern/cold-war aircraft zeroed at **all** WWII airbases regardless of side |

On mission load the filter runs at **T+5 seconds**, after the framework's own warehouse setup at T+1s. After that it fires automatically **3 seconds after every zone capture** via a `registerTrigger('lost')` hook on every airbase zone.

For each airbase the function does five passes in order:

1. Zero everything in `excludedAircraftWWII` (modern aircraft deny list)
2. Zero the opposite coalition's WWII aircraft
3. Zero everything in `restockAircraft` (community mod aircraft set unlimited by the framework)
4. Zero any other aircraft found in `GetInventory()` that are not in the allow list
5. Set the correct coalition's WWII aircraft to unlimited

> Aircraft shown as `(0)` in the slot screen are correctly blocked. Aircraft shown without a number are set to unlimited.

---

## DCS Engine Limitation — Unlimited Flag

**Aircraft set to Unlimited in the Mission Editor warehouse cannot be zeroed by any script.** DCS enforces the Unlimited flag at the engine level and `STORAGE:SetItem(name, 0)` has no effect on them.

As long as an aircraft is set to **Limited** in ME (any quantity — 1, 10000, it doesn't matter), the script can override it at runtime. The actual number you put in ME is irrelevant; it will be replaced by the filter.

This is the same requirement as the Coldwar era filter built into the Foothold framework.

---

## Mission Editor Setup (Required)

This step must be done once in the ME. Without it, any aircraft with the Unlimited flag will remain available regardless of side.

### Step-by-step

1. Open the mission (`.miz`) in the **DCS Mission Editor**.
2. Go to **Warehouse** (top menu bar → Warehouse, or click any airbase → Warehouse button).
3. For every airbase, ensure all aircraft are set to **Limited** (any quantity). Uncheck the **Unlimited** checkbox. The script will set the correct values at runtime — the number you enter in ME does not matter.
   - **WWII aircraft** (both Allied and Axis) — must be **Limited** so the script can set them to unlimited for the correct side and zero for the wrong side.
   - **Modern aircraft** — must be **Limited** so the script can zero them. If they are set to **Unlimited** in ME, the script cannot remove them.
4. Save and republish the mission.

If modern aircraft are already present as Limited (e.g. qty 10000) in your ME warehouse, you do not need to change them — the script will zero them automatically.

### Aircraft to set to Limited qty 1 everywhere

**Allied (Blue):**
| DCS Type Name | Aircraft |
|---|---|
| `SpitfireLFMkIX` | Spitfire LF Mk. IX |
| `SpitfireLFMkIXCW` | Spitfire LF Mk. IX CW |
| `MosquitoFBMkVI` | Mosquito FB Mk. VI |
| `F4U-1D` | F4U-1D Corsair |
| `F4U-1D_CW` | F4U-1D Corsair CW |
| `P-47D-30` | P-47D-30 Thunderbolt |
| `P-47D-30bl1` | P-47D-30bl1 Thunderbolt |
| `P-47D-40` | P-47D-40 Thunderbolt |
| `P-51D` | P-51D Mustang |
| `P-51D-30-NA` | P-51D-30 Mustang |
| `TF-51D` | TF-51D (trainer) |
| `I-16` | I-16 |
| `La-7` | La-7 |

**Axis (Red):**
| DCS Type Name | Aircraft |
|---|---|
| `Bf-109K-4` | Bf 109 K-4 |
| `FW-190A8` | Fw 190 A-8 |
| `FW-190D9` | Fw 190 D-9 |

### Quick tip — "Copy to all airbases"

The ME Warehouse dialog has a **"Copy to all"** button. You can use it to set all WWII aircraft to Limited at once, then copy to all airbases. The quantity you enter doesn't matter — just make sure the Unlimited checkbox is **not** ticked.

> **Warning:** "Copy to all" includes ships. Ships use different warehouse logic — verify ship warehouses look correct after copying.

---

## Customising the Aircraft Lists

All three lists are defined in `Foothold Config.lua` near the bottom (above `restockAircraft`). They are guarded with `or {}` / `or { ... }` so you can override them from the external save-game config without editing the script.

### Adding a new Allied aircraft

```lua
blueAircraftWWII = blueAircraftWWII or {
    -- existing entries ...
    "NewTypeNameHere",
}
```

### Adding a new Axis aircraft

```lua
redAircraftWWII = redAircraftWWII or {
    -- existing entries ...
    "NewTypeNameHere",
}
```

### Blocking an additional modern type

If a modern aircraft still appears in the slot screen after the ME setup, add it to `excludedAircraftWWII`:

```lua
excludedAircraftWWII = excludedAircraftWWII or {
    -- existing entries ...
    "UnwantedTypeNameHere",
}
```

> Type names are **case-sensitive** and must match DCS internal names exactly. Wrong names fail silently. Check `DCS.log` for `WWII_Aircraft:` lines to verify the filter ran.

---

## Debugging

The filter writes a log line for every airbase it processes:

```
WWII_Aircraft: side=2 applied to Biggin Hill
WWII_Aircraft: side=1 applied to Abbeville Drucat
```

If a modern aircraft is still visible despite being in `excludedAircraftWWII`:
1. Check whether it is set to **Unlimited** in the ME warehouse — that is the only cause.
2. Set it to **Limited qty 0** in ME and save the mission.

If the `WWII_Aircraft:` log lines are absent entirely, the zone setup script did not load correctly.

---

## Files Modified

| File | Change |
|---|---|
| `scripts/.../Foothold Config.lua` | Added `blueAircraftWWII`, `redAircraftWWII`, `excludedAircraftWWII` tables |
| `scripts/.../Normandy_Zone_Setup-Custom_new.lua` | Added `applyWWIIAircraftToAirbase()` function, startup scheduler, and per-zone capture hooks |
