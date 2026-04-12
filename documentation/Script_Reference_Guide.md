# Foothold Normandy — Script Reference Guide

**Version**: v2.5.3 new templates  
**Scripts**: `zoneCommander_moose-Custom_WWII_new.lua` · `Normandy_Zone_Setup-Custom_new.lua` · `WelcomeMessage_Normandy_new.lua`  
**Reference engine**: `Foothold_GCW_V4.5.5_Coldwar-Modern/zoneCommander.lua`

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Cache System Reference](#2-cache-system-reference)
3. [Spawning APIs](#3-spawning-apis)
4. [AI Control Reference](#4-ai-control-reference)
5. [Supply System — Trains](#5-supply-system--trains)
6. [Supply System — Naval & BATTLESHIP](#6-supply-system--naval--battleship)
7. [Connection Map & Supply Arrows](#7-connection-map--supply-arrows)
8. [WelcomeMessage / Player Layer](#8-welcomemessage--player-layer)
9. [Normandy-Specific Features](#9-normandy-specific-features)
10. [Migration: Old → New (v2.5.3)](#10-migration-old--new-v253)
11. [GCW vs WWII Feature Comparison](#11-gcw-vs-wwii-feature-comparison)

---

## 1. Architecture Overview

### 1.1 Three-Layer Model

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 3: Player   WelcomeMessage_Normandy_new.lua              │
│           ATIS · Callsign · Escort · Events                     │
│           Reads: zones, bc, WaypointList, Era, RankingSystem    │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: Data     Normandy_Zone_Setup-Custom_new.lua           │
│           Zone defs · Supply routes · Shop · Boot sequence      │
│           Writes: zones, bc, upgrades, flavor, supplyZones      │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: Engine   zoneCommander_moose-Custom_WWII_new.lua      │
│           Caching · Spawning · AI · Arrows · NavalRoute         │
│           Writes: CustomZone, Respawn, Utils, GlobalSettings    │
│                   BattleCommander class, GroupCommander class   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Load Order

Scripts must be loaded in this order inside the mission (DO file triggers):

1. `zoneCommander_moose-Custom_WWII_new.lua` — defines all framework classes and functions
2. `Normandy_Zone_Setup-Custom_new.lua` — uses the framework to define the mission
3. `WelcomeMessage_Normandy_new.lua` — reads the configured mission state

### 1.3 Globals Ownership Table

| Global | Written by | Read by |
|--------|-----------|---------|
| `bc` (`BattleCommander`) | Setup | WelcomeMessage, Setup |
| `zones` | Setup | WelcomeMessage, Setup |
| `upgrades` | Setup | Setup |
| `flavor` | Setup | Engine (zone labels) |
| `WaypointList` | Setup | WelcomeMessage |
| `supplyZones` | Setup | Engine (LogisticCommander) |
| `CustomZone` | Engine | Setup, WelcomeMessage |
| `Respawn` | Engine | Setup |
| `Utils` | Engine | Setup, WelcomeMessage |
| `GlobalSettings` | Engine (defaults) → Setup (overrides) | Engine |
| `_globalArrowCounter` | Engine (line 3681) | Engine |
| `_activeArrowIds` | Engine | Engine |
| `USED_SUB_ZONES` | Engine | Engine |
| `INVALID_SPAWN_SUB_ZONES` | Engine | Engine |
| `LandingSpots` | **REMOVED** (see §2) | — |
| `CustomFlags` | Setup (triggers) | Engine (train skip logic) |
| `RAILWAY_STATION_GROUPS` | Setup | Engine (scenery callbacks) |
| `sceneryList` | Setup | Engine |
| `SplashDamage` | Splash script | Setup (hunter count) |
| `NAVAL_ROUTE_DEBUG_LOGGING` | Engine (line 5245) | Engine |
| `DRAW_SUPPLY_ARROWS_DEBUG_LOGGING` | Engine (line 14300) | Engine |

---

## 2. Cache System Reference

All caches use a **nil / false sentinel pattern**: `nil` = not yet looked up; `false` = looked up but not found. This prevents repeated DCS API calls for missing resources.

### 2.1 Zone Caches

| Variable | Engine line | Key | Value | Reset |
|----------|-------------|-----|-------|-------|
| `customZoneCache` | ~22 | zone name | `CustomZone` object | never |
| `triggerZoneCache` | ~34 | zone name | DCS trigger zone table \| `false` | never |
| `mooseZoneCache` | ~45 | zone name | Moose `ZONE` object \| `false` | never |
| `airbaseCache` | ~25 | airbase name | Moose `AIRBASE` object \| `false` | never |
| `dcsAirbaseCache` | ~30 | airbase name | raw DCS `Airbase` \| `false` | never |

**Access functions:**
- `CustomZone:getByName(name)` — returns cached `CustomZone` or creates one
- `getTriggerZoneCached(name)` — returns `triggerZoneCache[name]`
- `getMooseZone(name)` — returns `mooseZoneCache[name]`
- `getAirbaseByName(name)` — tries both AIRBASE and raw DCS caches
- `getDcsAirbaseByName(name)` — raw DCS only

### 2.2 Zone Name Index

```lua
local zoneByName = nil   -- built lazily on first use

local function buildZoneByName()
    zoneByName = {}
    for _, z in ipairs(env.mission.triggers.zones or {}) do
        zoneByName[z.name] = z
    end
end
```

Built once on first call to `CustomZone:getByName()` or `collectSubZones()`. O(1) lookup of any trigger zone by name.

### 2.3 Sub-Zone Cache

```lua
local subZoneCache = {}
local function collectSubZones(baseName)
    if subZoneCache[baseName] then return subZoneCache[baseName] end
    -- scans zoneByName for all keys matching: baseName .. "-" .. pure_numeric_suffix
    subZoneCache[baseName] = sorted_list
    return sorted_list
end
```

**Key difference from old engine:**
- **Old**: Sequential scan `baseName.."-1"` to `baseName.."-100"` — breaks on the first missing number. Zones `A-1, A-2, A-4` would only find `A-1, A-2`.
- **New**: Dictionary scan over all zone names — finds all numeric suffixes regardless of gaps.

### 2.4 Zone Center Cache

```lua
local zoneCenterCache = {}
function getZoneCenter(name)
    if zoneCenterCache[name] then return zoneCenterCache[name] end
    -- reads trigger zone point
    zoneCenterCache[name] = { x = z.x, y = z.z }  -- DCS y/z axis mapping
    return c
end
```

Returns `{x, y}` where `y` maps to DCS Z-axis (horizontal). Used for all 2D zone-distance calculations.

### 2.5 Group Template Cache

```lua
local groupTemplateCache = nil

function buildTemplateCache()
    groupTemplateCache = {}
    for coaName, coa in pairs(env.mission.coalition) do
        for country in coa.country do
            for cat, catTbl in pairs(country) do
                for g in catTbl.group do
                    local t = DeepCopy(g)
                    t.category   = cat
                    t.countryId  = country.id
                    t.coaSideEnum= coalition.side[upper(coaName)]
                    groupTemplateCache[g.name] = t
                end
            end
        end
    end
end
```

Called explicitly from Setup at boot. Delivers the canonical Mission Editor template for any group name via `FetchMETemplate(name)`.

**`MISSING_GROUPS{}` tracking (new):** When `FetchMETemplate` or `ResolveNamedGroupTemplate` cannot find a template in any lookup step, `MISSING_GROUPS[grpName] = true` is set and an `env.info()` entry is written. Check `dcs.log` for `MISSING_GROUPS:` entries after a mission load to find broken ME template references.

### 2.6 SAM Sub-Zone Cache

```lua
local function getSamSubZones(zoneName, used)
    -- finds trigger zones matching: zoneName:lower() .. "-sam-" .. anySuffix
```

Separate pool for SAM groups. SAM groups are routed to `-sam-` named sub-zones; non-SAM groups are filtered away from them. This prevents strategic SAMs from spawning at road-side sub-zones meant for ground forces.

### 2.7 Landing Spot Pool System

**Old engine (removed):** `LandingSpots[zoneName]` — a flat global table filled by `PrecomputeLandingSpots()`.  
**New engine:** Pool-based with lazy initialization:

```lua
local landingSpotPoolByPrefix     = {}
local forcedLandingSpotPoolByZone = {}

-- Returns a pool of valid LZ coordinates for zones matching this prefix
local function _getLandingSpotPoolForPrefix(prefix)

-- Returns forced LZ pool from trigger zones named: zoneName.."-land-forced-N"
local function _getForcedLandingSpotPool(zoneName)

-- Called by PrecomputeLandingSpots() to fully reinitialize
local function _resetLandingSpotPoolCaches()
```

`PrecomputeLandingSpots(maxPerZone, attemptsPerZone, maxSlopeDeg)` now uses 600 attempts (was 300) and 12° max slope (was 15°).

> **Migration note:** Any Setup code that directly accessed `LandingSpots[zoneName]` must be updated to use `_getLandingSpotPoolForPrefix(prefix)` or `_getForcedLandingSpotPool(zoneName)`.

### 2.8 Other Caches

| Variable | Purpose |
|----------|---------|
| `headingTrigCache{}` | Memoized `{h, psi, cos, sin}` per integer heading degree — avoids repeated trig in `SpawnAtPoint()` |
| `buildingCache{}` | `world.searchObjects(SCENERY)` results per zone — used by scenery destruction callbacks |
| `USED_SUB_ZONES{}` | Global cross-zone set — prevents the same sub-zone from being occupied twice simultaneously |
| `INVALID_SPAWN_SUB_ZONES{}` | Blacklisted sub-zones that failed `GetValidCords()` — permanently excluded from spawning |
| `ZONE_VALID_SUBZONES{}` | Sub-zones with road/runway surface, pre-validated for ground convoys |
| `SUBZONE_NEAR_ROAD{}` | `true` if any road exists within 1000m of a sub-zone center |
| `ZONE_DISTANCES{}` | Pairwise zone distances in meters — keyed `"ZoneA->ZoneB"` — used for distance caps |
| `dc.PATH_CACHE{}` | Road path from `land.findPathOnRoads()`, keyed `"A>B"` bidirectionally |

### 2.9 Supply Arrow Caches

| Variable | Purpose |
|----------|---------|
| `_activeArrowIds{}` | All currently drawn map mark IDs (both tactical and supply arrows) |
| `_globalArrowCounter` | Integer counter initialized at 1201 in engine (line 3681); increments per arrow |
| `self.ConnectionArrowIds{}` | Per-connection mark IDs keyed `"from=>to"` — used by `RefreshConnectionsLines()` |
| `self.supplyArrowIds{}` | Per-supply-connection mark IDs — used by `RefreshConnectionsLines()` for supply arrows |
| `self.supplyArrowDebounce{}` | `{lastCallTime, debounceDelay=60, pendingCall, scheduledFunction}` |

### 2.10 Intel / Territory Caches

| Variable | Purpose |
|----------|---------|
| `zoneIntels{}` | Per-zone intel state: `{markerByKey, moveNoticeAtByGroup, builtIndex, lastSnapshot, nextIntelAt}` |
| `intelExpireTimes{}` | Expiry timestamps for intel sessions |
| `intelActiveZones{}` | Boolean active flags per zone |
| `_enemyTerritoryOverlayZones{}` | Zone list for enemy territory shading |
| `_friendlyTerritoryOverlayZones{}` | Zone list for friendly territory shading |
| `_neutralTerritoryOverlayZones{}` | Zone list for neutral territory shading |

---

## 3. Spawning APIs

### 3.1 Template Resolution Chain

When any function needs a group template, this 3-step chain is followed:

```
1. GROUP:FindByName(name)         -- live group currently in DCS world
        ↓ fail
2. FetchMETemplate(name)          -- groupTemplateCache (built at startup)
        ↓ fail
3. _DATABASE.Templates.Groups[name].Template  -- Moose internal database
        ↓ fail
   → MISSING_GROUPS[name] = true  + env.info() warning
```

Old engine used only steps 1 and 2.

### 3.2 `buildTemplateCache()` / `FetchMETemplate(name)`

```lua
-- Called once at boot from Setup (~line 1902 of Setup)
function buildTemplateCache()

-- Returns a DeepCopy of the ME template for groupName
function FetchMETemplate(name)
    if not groupTemplateCache then buildTemplateCache() end
    local t = groupTemplateCache[name]
    return t and UTILS.DeepCopy(t) or nil
end
```

### 3.3 `Respawn.Group(groupName, uncontrolled)`

Low-level spawner. Used primarily for Fixed groups and airbase-related spawns.

```lua
function Respawn.Group(groupName, uncontrolled)
    -- 1. Destroys existing live group if present
    -- 2. FetchMETemplate(groupName)
    -- 3. freshIds(tpl)  — assigns new unique group/unit IDs (gid start 7000, uid start 90000)
    -- 4. Sets lateActivation = false
    -- 5. Sets uncontrolled = true if param is true (parked aircraft)
    -- 6. FixSelfTasks() — patches EPLRS/beacon/ICLS task IDs
    -- 7. coalition.addGroup() → returns new DCS group
end
```

### 3.4 `Respawn.SpawnAtPoint(grpName, coord, headingDeg, distNm, alt, spd)`

Air-spawn variant:

```lua
function Respawn.SpawnAtPoint(grpName, coord, headingDeg, distNm, alt, spd)
    -- 1. FetchMETemplate
    -- 2. Rotates all unit positions around coord using headingTrigCache[headingDeg]
    -- 3. Builds 2-waypoint route (ingress + fly-away)
    -- 4. coalition.addGroup()
end
```

### 3.5 `SpawnCustom(grname, zoneName)`

Standard zone-aware spawn for ground/air groups:

```lua
function SpawnCustom(grname, zoneName)
    spawnCounter[grname] = (spawnCounter[grname] or 0) + 1
    local alias = string.format("%s # %d", grname, spawnCounter[grname])

    -- Template resolution (3-step)
    local tpl = ResolveNamedGroupTemplate(grname)

    -- Surface type: water for carrier/naval zones, land/road for land zones
    local isCarrier = isCarrierZoneName(zoneName)  -- checks "carrier" or "naval" tokens first

    -- SPAWN:NewFromTemplate(tpl, alias)
    --   :InitSkill("Excellent")
    --   :InitRandomizeUnits(true, 100, 30):InitHeading(1,359)   -- land
    --   :InitRandomizeUnits(true, 1500, 1000)                   -- carrier/naval
    --   :InitHiddenOnMFD()   -- for SAM/EWR groups
    --   :InitHiddenOnMap()   -- for "IsNotShown" or EWR names

    -- GetValidCords(zoneName, allowedSurfaces, maxAttempts)
    -- coalition.addGroup()
end
```

**SAM groups skip `InitRandomizeUnits`** (they spawn at their exact ME position).  
**Fixed groups** (name contains `"Fixed"`) also skip sub-zone selection and spawn at ME position.

### 3.6 `CustomZone:spawnGroup(grname, forceFirst)`

High-level dispatcher with sub-zone logic:

```lua
function CustomZone:spawnGroup(grname, forceFirst)
    -- Fixed? → spawn at ME position, no sub-zone
    -- SAM?   → getSamSubZones(self.zone, usedSamSubZones)
    -- Normal → collectSubZones(self.zone), pick unused via getRandomUnusedSpawnZone()
    --          marks used in: self.usedSpawnZones  AND  USED_SUB_ZONES (global)
    -- Falls back to parent zone itself if no sub-zones available
    -- Tries up to #zonePool attempts (removing failures from pool each try)
end
```

**`CustomZone:clearUsedSpawnZones(zone)`** — clears `USED_SUB_ZONES` entries for this zone prefix. Called when zone side changes.

### 3.7 `isCarrierZoneName(zoneName)` — Line 831

```lua
function isCarrierZoneName(zoneName)
    if zoneNameContainsToken(zoneName, "carrier") then return true end
    if zoneNameContainsToken(zoneName, "naval")   then return true end
    -- also checks GlobalSettings.carrierZoneNames table
    return false
end
```

The "naval" token check means all six hidden naval base zones (`HiddenAXENavalbaseCherbourg`, etc.) are automatically treated as water-spawn zones without any additional configuration.

### 3.8 `PrecomputeLandingSpots(maxPerZone, attemptsPerZone, maxSlopeDeg)`

Precomputes valid helicopter landing positions in zones ending in `-land` or `-land-N`:

- 600 attempts per zone (was 300 in old engine)
- Max slope 12° (was 15°)
- Tests surface type (LAND or ROAD only) and slope via `Utils.getTerrainSlopeAtPoint`
- Falls back to trigger zones named `zoneName-land-forced-N` if no valid spots found
- Results stored in pool system, not flat `LandingSpots[]` global

---

## 4. AI Control Reference

### 4.1 `GroupCommander:new(params)` — All Fields

```lua
GroupCommander:new({
    name       = 'AXE_LeMolay-resupply-Caen',   -- unique mission name (used in mc:trackMission)
    mission    = 'supply',                        -- 'supply' | 'attack' | 'patrol'
    template   = 'SupplyConvoy',                  -- template table var name (string)
    targetzone = 'Caen',                          -- target zone name (string)
    type       = 'surface',                       -- 'surface' | 'air'
    condition  = function() return zones.LeMolay.active end,   -- optional: false = skip mission
    urgent     = function() return zones.Caen.side == 0 end,   -- optional: true = high priority
    ForceUrgent = true,                           -- static always-urgent flag
    MissionType = 'CAP',                          -- for air: 'CAP'|'CAS'|'RUNWAYSTRIKE'|'ANTISHIP'|'BATTLESHIP'
    Altitude   = CapAltitude()                    -- optional: altitude override (meters)
})
```

`condition` evaluates at mission generation time. If it returns `false`, the mission is skipped entirely that cycle.  
`urgent` evaluates at mission generation time. If it returns `true`, the mission gets highest priority scheduling.

### 4.2 Mission Types Table

| MissionType | Template variable | Notes |
|-------------|-----------------|-------|
| `CAP` | `CapPlaneTemplate` | `{Fw190D9, Bf109, P51, Spitfire}` |
| `CAS` | `CasPlaneTemplate` | `{JU88, P47, Mosquito, A20, F4UD}` |
| `RUNWAYSTRIKE` | `RunwayStrikePlaneTemplate` | `{Mosquito, JU88}` |
| `ANTISHIP` | `AntiShipPlaneTemplate` | `{F4UD, P47, Fw190D9, JU88}` — air attacks on naval targets |
| `BATTLESHIP` | `BattleshipTemplate` | `{AXEBattleshipTemplate, UKBattleshipTemplate}` — surface ship attacks |
| supply | `SupplyConvoy` | Ground convoy |
| supply (naval) | `SupplyNavalTemplate` | `{AxeNavalSupplyTemplate, UKNavalSupplyTemplate}` |
| supply (air) | `SupplyPlaneTemplate` | C47 variants |

### 4.3 `BudgetCommander`

```lua
budgetAI = BudgetCommander:new({
    battleCommander   = bc,
    side              = 1,         -- RED side AI
    decissionFrequency= 20*60,     -- decision every 20 min
    decissionVariance = 10*60,     -- ±10 min variance
    skipChance        = 10         -- 10% chance to skip a decision
})
budgetAI:init()
```

Makes automated upgrade/spawn decisions for the RED side.

### 4.4 `EventCommander`

```lua
evc = EventCommander:new({ decissionFrequency=10*60, decissionVariance=10*60, skipChance=10 })

-- Events must be defined BEFORE evc:init()
evc:addEvent('bombRed',   { ... cooldown=35*60 ... })
evc:addEvent('bombBlue',  { ... cooldown=35*60 ... })
evc:addEvent('navyArty',  { ... cooldown=40*60 ... })
evc:addEvent('v1Arty',    { ... cooldown=20*60 ... })

evc:init()   -- called AFTER all events are defined (corrected from old engine)
```

**`navyArty` event**: Advances a naval artillery group toward Saint-Pierre. Uses `bc:getZoneByName()` to find active red coastal zones, spawns the group, assigns a fire mission.

**`v1Arty` event**: Picks a random active V1 site from `V1_SITE_CONFIG`, calls `launchRandomV1Artillery(siteName)`. See §9.1 for V1 mechanics.

### 4.5 `MissionCommander`

```lua
mc = MissionCommander:new({ side=2, battleCommander=bc, checkFrequency=60 })
```

Player-facing mission tracking system. Audio cues: `ding.ogg` (mission available), `cancel.ogg` (mission ended).

Mission tracking API (new in v2.5.3):
- `bc:addMissionTag(zone, missionType)` — marks a zone as having an active mission of this type
- `bc:removeMissionTag(zone, missionType)` — clears the tag
- `bc:refreshZoneLabel(zone)` — updates the F10 map zone label

> **Old API** (removed): `ActiveCurrentMission[zone] = MissionType` (direct table write), `z:updateLabel()`.

### 4.6 `StartBomberAuftrag(tag, grpName, tgtList, escortGroup)`

Normandy-exclusive MOOSE bomber mission spawner:

```lua
function StartBomberAuftrag(tag, grpName, tgtList, escortGroup)
    -- 1. Find closest enemy (side=2) zone in tgtList to bomber current position
    -- 2. Build ComboTask with getAttackTask() for each unit in z.built
    -- 3. Route: ingress WP at 25NM from target, RTB cleanup WP
    -- 4. Escort via DCS Escort task linked by groupId
    -- 5. Store in _G[tag..'Bomber'], _G[tag..'Mission']
end
```

### 4.7 `DynamicHybridFiller` Configuration

```lua
DynamicHybridConfig = {
    enabled           = true,
    runOnce           = true,
    airMaxNm          = 120,    -- max range for air missions
    heloCasMaxNm      = 40,     -- max range for helo CAS
    minGroundAttackNm = 10,
    surfaceMaxNm      = 30,     -- max range for surface convoys
    minTargetNm       = 10,
    filterDelaySec    = 5,
    minCapAttackNm    = 35,
    minPlaneAttackNm  = 25,
    minHeloAttackNm   = 15,
    log               = true
}
bc:startDynamicHybridFiller(DynamicHybridConfig)
```

### 4.8 `RedReactiveCounterpressure`

```lua
if RedReactiveConfig.enabled then
    bc:startRedReactiveCounterpressure(RedReactiveConfig)
end
```

Dynamically scales RED AI difficulty in response to player performance.

### 4.9 Hunter System

```lua
local HuntNumber = SplashDamage and math.random(10,20) or math.random(8,16)
bc:initHunter(HuntNumber)
```

Spawns 8–16 (without SplashDamage) or 10–20 (with SplashDamage) AI hunter aircraft. `SplashDamage` is the global set by `Splash_Damage_*.lua`.

### 4.10 Player Mission Types (Setup `mc:trackMission` registrations)

| Mission ID | Trigger | Notes |
|-----------|--------|-------|
| Capture | `generateCaptureMission()` at +20s | Targets neutral enemy-adjacent zones |
| Attack (×2) | `generateAttackMission()` at +35s | `attackTarget1`, `attackTarget2` — frontline-weighted |
| SEAD | `generateSEADMission()` at +120s | New in v2.5.3 |
| DEAD | `generateDEADMission()` at +140s | New in v2.5.3 |
| CAS | `checkAndGenerateCASMission()` at +180s | Checks for active enemy in range |
| Recon | `checkAndGenerateReconMissionV2()` at +200s | New, calls `startZoneIntel()` on completion |
| Resupply (×2) | `generateSupplyMission()` at +60s | `resupplyTarget1`, `resupplyTarget2` |
| CAP | `checkAndGenerateCAPMission()` at +480s | Long delay — background filler |
| Runway Strike | `generateRunwayStrikeMission()` at +210s | Targets enemy airfields |

---

## 5. Supply System — Trains

### 5.1 Dual Connection Architecture

The WWII engine maintains two separate connection lists:

| List | Variable | Drawn by | Visual |
|------|---------|---------|--------|
| Tactical | `bc.connections` | `DrawConnectionLines()` | Thin arrows (0.5) border-to-border |
| Supply | `bc.connectionssupply` | `drawSupplyArrows()` | Thick arrows (2) with train-skip logic |

**GCW engine uses only one list** (`bc.connections`) — no supply arrow system.

### 5.2 `bc:addConnectionSupply(from, to, method)`

```lua
-- Road convoy connection (no method = 'default')
bc:addConnectionSupply("BigginHill", "Manston")

-- Train connection
bc:addConnectionSupply("London", "Manston", "train")
```

Appends `{from=f, to=t, method=supplyMethod or 'default'}` to `bc.connectionssupply`.

### 5.3 Train Group Naming Convention

```lua
function BattleCommander:getTrainGroupForConnection(from, to)
    -- Returns: "AXE_Train_{from}-resupply-{to}"  (side=1)
    -- Returns: "UK_Train_{from}-resupply-{to}"   (side=2)
end
```

For every `bc:addConnectionSupply("A", "B", "train")` call, the ME must contain groups named:
- `AXE_Train_A-resupply-B`
- `UK_Train_A-resupply-B`

### 5.4 Complete Train Route Declarations

**Blue (UK) — 5 routes from London:**

| From | To |
|------|----|
| London | Manston |
| London | Farnborough |
| London | Chailey |
| London | Ford |
| London | Hawkinge |

**Red (AXE) — 15 routes:**

| From | To |
|------|----|
| Cherbourg | Valognes |
| Valognes | Le Molay |
| Le Molay | Caen |
| Bernay | Caen |
| Dunkirk-Port | Calais |
| Amiens | Abbeville |
| Abbeville | Le Touquet |
| Le Havre | Rouen |
| Le Havre | Fecamp |
| Paris | Orly |
| Paris | Saint-Aubain |
| Paris | Fecamp |
| Paris | Saint-Andre |
| Saint-Andre | Bernay |

### 5.5 Train Arrow Skip Logic (`drawSupplyArrows()`, line 14415)

When drawing supply arrows, train connections are validated through 4 sequential checks. The arrow is hidden if any check fails:

```lua
if v.method == 'train' then
    local trainGroupName = self:getTrainGroupForConnection(v.from, v.to)

    -- Check 1: group name resolved
    if not trainGroupName then skipArrow = true end

    -- Check 2: CustomFlags destroyed marker (set by ME triggers)
    if CustomFlags[trainGroupName] == true then skipArrow = true end

    -- Check 3: group exists in DCS world
    local trainGroup = Group.getByName(trainGroupName)
    if not trainGroup then skipArrow = true end

    -- Check 4: group has alive units (new in v2.5.3)
    local units = trainGroup:getUnits()
    if not units or #units == 0 then skipArrow = true end
    if units[1]:getLife() <= 1 then skipArrow = true end
end
```

> `CustomFlags[trainGroupName] = true` is set by Mission Editor triggers when a train group is destroyed. This handles cases where a DCS group still exists (dead units) but should be treated as permanently destroyed.

### 5.6 Railway Station Scenery System

`sceneryList` maps railway station trigger zone names to their DCS scenery object IDs. `RAILWAY_STATION_GROUPS` maps each station to the train group names that depend on it:

```lua
RAILWAY_STATION_GROUPS = {
    ['StationCherbourg'] = { 'AXE_Train_Cherbourg-resupply-Valognes', 'UK_Train_Cherbourg-resupply-Valognes' },
    -- ...
}
```

Destroying the station scenery object disables the linked train groups via their `criticalObject` callbacks.

### 5.7 `drawSupplyArrowsDebounced(forceImmediate)`

Enforces a minimum 60-second interval between `drawSupplyArrows()` calls.

```lua
BattleCommander.supplyArrowDebounce = {
    lastCallTime    = 0,
    debounceDelay   = 60,   -- seconds minimum between calls
    pendingCall     = false,
    scheduledFunction = nil     -- SCHEDULER reference, stopped if a new forced call arrives
}
```

Whenever a zone changes side, the framework calls `drawSupplyArrowsDebounced()`. The debounce prevents hundreds of simultaneous redraws during mission start when all zones initialize.  
`forceImmediate = true` bypasses the debounce (used at boot initialization).

---

## 6. Supply System — Naval & BATTLESHIP

### 6.1 Hidden Naval Base Pattern

Six invisible spawn zones prefixed `Hidden*Navalbase*` act as permanent off-map naval spawn hubs:

| Zone | Coalition | Location role |
|------|----------|--------------|
| `HiddenUKNavalbasePortsmouth` | Blue (2) | English south coast |
| `HiddenUKNavalbaseDover` | Blue (2) | Strait of Dover |
| `HiddenAXENavalbaseCherbourg` | Red (1) | Normandy peninsula |
| `HiddenAXENavalbaseDieppe` | Red (1) | Normandy coast east |
| `HiddenAXENavalbaseLeHavre` | Red (1) | Seine mouth |
| `HiddenAXENavalbaseDunkirk` | Red (1) | Belgium coast |

Each zone has:
- An upgrade group: `UK_Tug` or `AXE_Tug`
- Supply missions targeting carrier or port zones
- BATTLESHIP missions targeting enemy coastal zones

### 6.2 `isCarrierZoneName(zoneName)` — Naval Zone Detection

```lua
function isCarrierZoneName(zoneName)
    if zoneNameContainsToken(zoneName, "carrier") then return true end  -- CarrierGroup
    if zoneNameContainsToken(zoneName, "naval")   then return true end  -- HiddenAXENavalbase*
    for _, token in ipairs(GlobalSettings.carrierZoneNames or {}) do    -- custom names
        if zoneNameContainsToken(zoneName, token) then return true end
    end
    return false
end
```

The "naval" token match means all six hidden naval base zones are automatically recognized as water zones — spawn coordinates will be over water, not on land.

`GlobalSettings.carrierZoneNames = { "CarrierGroup" }` — additional override from Setup.

### 6.3 `dc.BuildSupplyNavalRoute(originZoneName, targetZoneName, speed)` — Line 5349

Builds a multi-waypoint naval route from origin to target:

```lua
function dc.BuildSupplyNavalRoute(originZoneName, targetZoneName, speed)
    -- 1. Check ZONE_DISTANCES[key] ≤ 200nm (naval distance cap; convoys cap at 40nm)
    -- 2. If origin zone name contains "naval" → use zone center directly (already over water)
    -- 3. Otherwise → find safe water point via dc.FindSafeWaterPoint()
    -- 4. Build waypoints: 1 start + 1 per 15km (max 8 intermediate) + 1 destination
    -- 5. Each WP uses naval_buildWP(coord, speed, altitude=0)
    -- Returns: route table, or nil on failure
end
```

### 6.4 `dc.FindSafeWaterPoint(basePoint, maxRadius)` — Line 5255

Coast clearance algorithm:

```lua
function dc.FindSafeWaterPoint(basePoint, maxRadius)
    -- For each candidate point at increasing radius from basePoint:
    --   Probe 16 equally-spaced angles at 2km offset from candidate
    --   All 16 probes must return land.SurfaceType == 3 (WATER)
    --   Returns first valid "safe" point, or nil if none found
end
```

`NAVAL_ROUTE_DEBUG_LOGGING` (line 5245) controls detailed route-building logs. Set to `false` in production (default in v2.5.3).

### 6.5 BATTLESHIP vs ANTISHIP Distinction

| MissionType | Executor | Purpose |
|-------------|---------|---------|
| `BATTLESHIP` | Surface ship group | Ship-to-shore / ship-to-ship bombardment |
| `ANTISHIP` | Aircraft | Air attack on enemy naval targets |

### 6.6 BATTLESHIP GroupCommanders

| Source Zone | Target | Template | Condition |
|------------|--------|---------|-----------|
| `hiddenAXENavalbaseLeHavre` | CarrierGroup | BattleshipTemplate | `zones.LeHavre.active` |
| `hiddenAXENavalbaseDunkirk` | Dover | BattleshipTemplate | (none) |
| `AxeCarrierGroup` | CarrierGroup | BattleshipTemplate | `zones.AxeCarrierGroup.active` |
| `CarrierGroup` | AxeCarrierGroup | BattleshipTemplate | (none) |
| `CarrierGroup` | Le Havre | BattleshipTemplate | (none) |
| `CarrierGroup` | Cherbourg | BattleshipTemplate | (none) |
| `CarrierGroup` | Sainte-Croix | BattleshipTemplate | (none) |
| `hiddenUKNavalbaseDover` | DunkirkPort | BattleshipTemplate | `zones.Dover.active` |

### 6.7 NavalSupply GroupCommanders

| Source Zone | Target | Condition |
|------------|--------|-----------|
| `hiddenAXENavalbaseCherbourg` | Le Havre | `zones.Cherbourg.active` |
| `hiddenAXENavalbaseLeHavre` | Dunkirk-Port | (none) |
| `hiddenAXENavalbaseDieppe` | AxeCarrierGroup | `zones.SaintAubain.active` |
| `hiddenAXENavalbaseDunkirk` | Cherbourg | (none) |
| `hiddenUKNavalbasePortsmouth` | CarrierGroup | urgent if `zones.CarrierGroup.side == 0` |
| `hiddenUKNavalbaseDover` | AxeCarrierGroup | `zones.Dover.active` |
| `hiddenUKNavalbaseDover` | DunkirkPort | `zones.Dover.active` |
| `hiddenUKNavalbaseDover` | Calais | `zones.Dover.active` |
| `hiddenUKNavalbaseDover` | CarrierGroup | `zones.Dover.active` |

---

## 7. Connection Map & Supply Arrows

### 7.1 WWII Dual System vs GCW Single System

| Aspect | WWII (this mission) | GCW (reference engine) |
|--------|-------------------|----------------------|
| Lists | `bc.connections` + `bc.connectionssupply` | `bc.connections` only |
| Draw functions | `DrawConnectionLines()` + `drawSupplyArrows()` | `DrawConnectionLines()` only |
| Train-skip logic | Yes — in `drawSupplyArrows()` | Not applicable |
| Debounce | Yes — 60s minimum between supply arrow redraws | No |
| Mark ID source | `_globalArrowCounter` (integer, starts 1201) | `UTILS.GetMarkID()` |
| Topology rebuild | Full rebuild every call | Incremental dirty-flag system |
| Connection flags | Not supported | `drawBoth`, `preserveDirection`, `StartNormal`, `isSamOrDefence` |

### 7.2 `bc:buildConnectionMap()` and `bc:buildConnectionSupplyMap()`

Both called at boot from Setup. Both perform a **full rebuild** scanning the entire list each call:

```lua
function BattleCommander:buildConnectionMap()
    ZONE_CONNECTED_TO_BLUE = {}
    ZONE_CONNECTED_BLUE_COUNT = {}
    self.connectionMap = {}
    for _, c in ipairs(self.connections) do
        self.connectionMap[c.from] = self.connectionMap[c.from] or {}
        self.connectionMap[c.to]   = self.connectionMap[c.to]   or {}
        self.connectionMap[c.from][c.to] = true
        self.connectionMap[c.to][c.from] = true
        -- also updates ZONE_CONNECTED_TO_BLUE / ZONE_CONNECTED_BLUE_COUNT
    end
end
```

`buildConnectionSupplyMap()` is identical but iterates `self.connectionssupply`.

### 7.3 `DrawConnectionLines()` — Tactical Connections

Draws thin arrows (thickness 0.5) between tactically connected zones, from zone border to zone border (using `GetConnectionEdgePoint()`). Clears and redraws all arrows each call.

### 7.4 `drawSupplyArrows()` — Supply Connections

Draws thick arrows (thickness 2) between supply-connected zones, from zone center. Includes train validation (§5.5). Clears `_activeArrowIds` and redraws all on each call.

**Debug logging flags:**
- `DRAW_SUPPLY_ARROWS_DEBUG_LOGGING = false` (line 14300) — gates detailed per-arrow logs via `supplyArrowLog()`
- `NAVAL_ROUTE_DEBUG_LOGGING = false` (line 5245) — gates naval route construction logs

### 7.5 `RefreshConnectionsLines(zoneName)`

Partial refresh — only redraws tactical arrows for connections involving `zoneName`. Uses `self.ConnectionArrowIds` to find and replace existing mark IDs.

### 7.6 Arrow Color Logic

| Condition | Color |
|-----------|-------|
| `fromZone.side == 2` and target not RED | Blue |
| `fromZone.side == 1` and target not BLUE | Red |
| Any other combination | White (neutral) |

---

## 8. WelcomeMessage / Player Layer

### 8.1 Script Dependencies

```lua
-- Read at script load time:
zones          -- zone table from Setup
bc             -- BattleCommander from Setup
WaypointList   -- numbered waypoint keys from Setup
Era            -- mission era string from Setup (always "WWII" here)
RankingSystem  -- bool flag from engine
EscortTakeoffFromGround -- bool flag from Setup
```

### 8.2 Zone List Building

```lua
-- Builds allZones list from zones table: reads zone.isHeloSpawn, zone.zone, zone.airbaseName
BuildAllZonesFromFootholdZones()

-- Builds atisZones list: only zones with an airbaseName that is currently blue-coalition
BuildAtisZonesFromFootholdZones()
```

### 8.3 ATIS System

```lua
-- Per-script airbase cache (independent of engine's airbaseCache)
local atisAirbaseObjects = {}
local function GetAirbaseByNameCached(airbaseName)
    -- Moose AIRBASE:FindByName() cached per name
end
```

`SetupATISMenu()` — builds the F10 ATIS menu using `WaypointList` indices for zone ordering. Each menu entry (zone is blue-owned and has an airbase) calls the ATIS information function, which reads frequency from the `AIRBASE.Normandy.*` enum.

**ESSEX Carrier:**
- Frequency: `124.00 AM`
- Morse: `ESS: · ··· ···`
- TACAN: dynamic from carrier AIRBASE object

### 8.4 Callsign Assignment System

```lua
local globalCallsignAssignments = {}   -- {callsignBase → {slotIndex→playerName}}
local zoneAssignments = {}             -- {zoneName → {callsignBase → {slotIndex→playerName}}}

-- Called when player enters a unit:
findOrAssignSlot(groupName, zoneName, playerName)
    → getPreferredOrder(groupName)   -- aircraft-type → preferred callsign bases
    → isCallsignUsedInOtherZones()  -- cross-zone uniqueness check

-- Called when player leaves:
releaseSlot(groupName, playerName)
```

### 8.5 WWII Callsign Table (10 Aircraft Types)

| Aircraft Prefix | Callsign Base | IFF Codes |
|----------------|--------------|-----------|
| `F.4.UD` | BlackSheep1 | 1400–1403 |
| `Spitfire.LF.MkIX` | Circus1 | 1510–1513 |
| `Mosquito.FB.MkVI` | Beer1 | 1330–1333 |
| `P.47D` | Detroit1 | 1610–1613 |
| `P.51D` | Mickey1 | 1560–1563 |
| `Bf.109K` | Schwarz1 | 1060–1063 |
| `FW.190.A8` | Panther1 | 1050–1053 |
| `FW.190.D9` | Angriff1 | 1370–1373 |
| `I.16` | Berkut1 | 1360–1363 |
| `Yak.52` | Medved1 | 1434–1437 |

### 8.6 32 ATIS Airfields (Normandy map)

All 32 entries reference `AIRBASE.Normandy.*` enum values. The list covers both English (Biggin Hill, Farnborough, Ford, Hawkinge, Lympne, Manston, Odiham, Tangmere, etc.) and French (Carpiquet, Cherbourg, Maupertus, Merville, Saint-Andre, etc.) airfields.

### 8.7 `EscortClientGroup(clientGroup)`

```lua
function EscortClientGroup(clientGroup)
    -- 1. FindEscortTemplateWithAlias() — WWII template selection
    -- 2. If EscortTakeoffFromGround: SpawnEscortFromGround()
    --    Else: SpawnEscortInAirBehindClient() — 1500m behind, 10000ft above
    -- 3. FLIGHTGROUP:New(spawnedGroup)
    -- 4. AUFTRAG:NewESCORT(clientFlightGroup)
    -- 5. escort FLIGHTGROUP:AddMission(auftrag)
end
```

Escort controllable modes: Flightsweep, Engage-if-Engaged, Patrol Ahead 15NM, Racetrack (3 variants), Orbit, Rejoin, RTB.

### 8.8 Event Registrations

```lua
static:HandleEvent(EVENTS.Shot,           static.OnEventShot)
static:HandleEvent(EVENTS.BaseCaptured,   static.onBaseCapture)
static:HandleEvent(EVENTS.PlayerLeaveUnit, static.OnEventPlayerLeaveUnit)
static:HandleEvent(EVENTS.PilotDead,      static.OnEventPlayerLeaveUnit)
static:HandleEvent(EVENTS.Ejection,       static.OnEventPlayerLeaveUnit)
static:HandleEvent(EVENTS.Takeoff,        static.OnEventTakeoff)
```

All events routed through the `static` (`EventMan`) STATIC object as Moose event anchor.

---

## 9. Normandy-Specific Features

### 9.1 V1 Rocket / Napalm System

**7 V1 launch sites:** `V1_Brecourt`, `V1_Wallon_Cappel`, `V1_Crecy_Forest`, `V1_Flixecourt`, `V1_Val_Ygot`, `V1_Herbouville`, `V1_Neuville`

Each site uses:
```lua
zones.V1_Brecourt:addCriticalObject('Fueltank-Brecourt')
```
Destroying the fuel tank triggers zone loss: `+500 blue credits` + `sender:disableZone()`.

**Impact effect system:**
```lua
function napalmOnImpact(impactPoint)
    -- 1. Spawn a 'Fuel tank' static at impact point
    -- 2. trigger.action.explosion() after 0.1s
    -- 3. Remove static after 0.12s
    -- 4. phosphor(impactPoint) — fires 3-10 signal flares at 30° azimuths
    -- 5. Big smoke effect after 5s
end

function phosphor(vec3)
    -- Fires flares at 16 random 30°-separated azimuths around impact point
end
```

**Target selection:**
```lua
function searchTargets(pType, pzone)  -- finds V1/fire_control units in zone
function fUnitCoord(pzone)            -- applies napalmOnImpact to all found targets
```

**V1 firing** (via `v1Arty` EventCommander event):
```lua
function launchRandomV1Artillery(siteName)
    -- Picks random target zone from V1_SITE_CONFIG[siteName]
    -- Calls fUnitCoord on the target zone
end
```

`CustomFlags[launchGroupName] = true` marks a V1 launcher as destroyed in ME triggers.

### 9.2 EWR Zone Reward System

Three EWR zones use the `'lost'` trigger (not `'destroyed'`):

```lua
zones.PointeDesGroins:registerTrigger('lost', function(event, sender)
    bc:addFunds(2, 1000)   -- +1000 blue credits
    sender:disableZone()
end)
-- Same for PointeDuHoc and CapGrisNez
```

**Zone structure:** Each EWR zone has dedicated AAA upgrade groups (`EWRPointeDesGroins`, `EWRPointeDuHoc`, `EWRCapGrisNez`) + radar unit.

### 9.3 `GlobalSettings` Overrides

These Normandy-specific values are set in Setup, overriding engine defaults:

| Setting | Normandy Value | Notes |
|---------|---------------|-------|
| `autoSuspendNmBlue` | `80` nm | Suspend blue zones >80 NM behind front |
| `autoSuspendNmRed` | `110` nm | Suspend red zones >110 NM behind front |
| `maxSupplyPerZoneBlue` | `1` | Max 1 supply convoy per blue zone |
| `maxSupplyPerZoneRed` | `2` | Max 2 supply convoys per red zone |
| `capRearlineNmBlue` | `30` nm | Blue CAP coverage rear boundary |
| `capRearlineNmRed` | `60` nm | Red CAP coverage rear boundary |
| `capAssistEnabled` | `true` | CAP zones assist each other |
| `frontlineMaxSegmentNm` | `120` nm | Max frontline segment length |
| `frontlineDistanceLimitBlue` | `30` nm | Blue frontline depth limit |
| `frontlineDistanceLimitRed` | `60` nm | Red frontline depth limit |
| `proximityWakeNm` | `30` nm | Wake range for zone activation |
| `carrierZoneNames` | `{ "CarrierGroup" }` | Additional carrier zone tokens |
| `ShowEnemyTerritoryOverlay` | `true` | Red territory shading |
| `ShowFriendlyTerritoryOverlay` | `true` | Green territory shading |
| `ShowNeutralTerritoryOverlay` | `true` | White territory shading |

### 9.4 Carrier Zones

**`CarrierGroup`** (Blue):
- Upgrades: `CarrierGroup-Chase`, `CarrierGroup-LST`, `CarrierGroup-land-1`, `CarrierGroup-land-2`
- 4 BATTLESHIP GroupCommanders attacking: AxeCarrierGroup, Le Havre, Cherbourg, Sainte-Croix
- Carrier CAP: `CapCarrierGroup` template (F4UD only)

**`AxeCarrierGroup`** (Red):
- Upgrades: `AxeCarrierGroup-Chase`, `AxeCarrierGroup-LST`, `AxeCarrierGroup-sub-1`, `AxeCarrierGroup-sub-2`, `AxeCarrierGroup-schnell-1`
- 1 BATTLESHIP GroupCommander attacking CarrierGroup

### 9.5 Commented-Out / Disabled Features

These features exist in the scripts but are disabled for the Normandy map:

| Feature | Status | Reason |
|---------|--------|--------|
| JTAC drones (`JTAC` class, `JTAC9line`) | Commented out | WWII era |
| AWACS spawns | Commented out | WWII era |
| Tanker flights (Arco/Texaco) | Commented out | WWII era |
| SEAD/Decoy shop items | Commented out | No radar-guided SAMs |
| Combined Arms | Commented out | CA not suitable |
| FARP deployment | Commented out | Not applicable |
| Railway ZoneCommander zones | All commented out | 17 `hiddenRailway*` zone stubs preserved |
| `RAILWAY_SUBZONE_MAPPING` | Written but commented | Planned feature, not activated |
| Hercules cargo supply (`HercCargoDropSupply`) | Absent | WWII era dicts don't have C-130 |
| `zsam` shop item | Removed | No modern SAM systems |

---

## 10. Migration: Old → New (v2.5.3)

This section documents everything that changed between the original `scripts/*.lua` files and the `scripts/new templates logic/WWII_Normandy_Foothold_Custom_v2.5.3/*_new.lua` files.

### 10.1 What Did NOT Change (Normandy Customizations Preserved)

All Normandy-specific customizations are **identical** between old and new:

- ✅ All 46+ zone definitions (side, level, upgrades)
- ✅ All GroupCommander entries (including naval and BATTLESHIP)
- ✅ All 7 V1 site `addCriticalObject` registrations
- ✅ All EWR zone `registerTrigger` callbacks (PointeDesGroins, PointeDuHoc, CapGrisNez)
- ✅ All 4 EventCommander event payloads (bombRed, bombBlue, navyArty, v1Arty)
- ✅ All `addConnectionSupply` entries (20 train + all road routes)
- ✅ `sceneryList` and `RAILWAY_STATION_GROUPS`
- ✅ `supplyZones` list and `bc:addZone` loop

### 10.2 Caching Changes

| Change | Action Required |
|--------|----------------|
| `LandingSpots[zoneName]` global removed; replaced by pool system | Audit any Setup code that reads `LandingSpots[x]` directly — none found in current Setup |
| `collectSubZones()` now handles sparse numbering (gaps OK) | No action needed; behavior is strictly better |
| `airbaseCache` / `dcsAirbaseCache` added to engine | No action; WelcomeMessage per-script cache is redundant but harmless |
| `MISSING_GROUPS{}` tracking added | Run mission and check `dcs.log` for `MISSING_GROUPS:` entries to find broken ME templates |
| `PrecomputeLandingSpots()`: 300→600 attempts, 15°→12° slope | No action; produces better landing spots with potential for slight longer startup |

### 10.3 Debug Flags (Patched in This Version)

The following debug flags were **active** in the received engine files and have been **patched to off** as part of v2.5.3 preparation:

| Flag | Location | Patched value |
|------|---------|--------------|
| `NAVAL_ROUTE_DEBUG_LOGGING` | Engine line 5245 | `false` |
| `env.info("DEBUG: drawSupplyArrows called")` | Engine line (was 14416) | removed |
| `env.info("DEBUG: Cleared existing arrows.")` | Engine (was 14419, 14547) | removed |
| `env.info("DEBUG: No supply connections to draw.")` | Engine (was 14427) | removed |
| `env.info("DEBUG: Drawiing Connection lines")` | Engine (was 14540) | removed |
| `supplyArrowLog("DEBUG: Processing connection...")` per-arrow log | Engine | removed |

Supply arrow verbose logging (`DRAW_SUPPLY_ARROWS_DEBUG_LOGGING`) was already `false` — no patch needed.

### 10.4 Supply Arrow System

| Change | Action Required |
|--------|----------------|
| `drawSupplyArrows()` train-skip logic enhanced: now also checks unit aliveness | No action; strictly more robust |
| `_globalArrowCounter` initialization moved into engine (line 3681) | No action; no duplicate in Setup |
| Debounce SCHEDULER reference stored in `supplyArrowDebounce.scheduledFunction` | No action |

**Connection map for supply arrows** — the `bc:addConnectionSupply()` call API is **unchanged**. All existing supply route declarations work without modification.

### 10.5 BATTLESHIP / Naval Routes

| Change | Action Required |
|--------|----------------|
| `isCarrierZoneName()` now uses `zoneNameContainsToken()` helper with "carrier" AND "naval" checks | No action; hidden naval base zones (`HiddenAXENavalbase*`) still correctly detected via "naval" token |
| `dc.BuildSupplyNavalRoute()` API signature unchanged | No action |
| `NAVAL_ROUTE_DEBUG_LOGGING` was `true` in received file | Now patched to `false` (§10.3) |

### 10.6 Framework-Level Improvements (Author Changes)

These changes are in the new templates and represent engine-level improvements:

| Area | Old | New |
|------|-----|-----|
| `evc:init()` call order | Called before events defined (bug) | Called after all events registered |
| `evc decissionFrequency` | 15 min | 10 min |
| `evc skipChance` | 15% | 10% |
| `autoSuspendNmBlue` | 60 nm | 80 nm |
| `autoSuspendNmRed` | 80 nm | 110 nm |
| Mission tracking API | `ActiveCurrentMission[]` direct table | `bc:addMissionTag()` / `bc:removeMissionTag()` / `bc:refreshZoneLabel()` |
| Zone label refresh | `z:updateLabel()` | `bc:refreshZoneLabel(zone)` |
| Contribution API | Direct `bc.playerContributions[2][pl]` | `bc:addContribution(pl, 2, share)` |
| `generateCaptureMission` return value on active | `return nil` | `return true` |
| Supply mission tracking | Single `resupplyTarget` | Dual `resupplyTarget1`, `resupplyTarget2` |
| Attack mission tracking | Single `attackTarget` | Dual `attackTarget1`, `attackTarget2` with frontline weighting |
| New missions | None | SEAD (+120s), DEAD (+140s), Recon (+200s) |
| Shop system | Flat list, hardcoded prices | Categorical `ShopCats`, `ShopRankRequirements`, `SHOP_PRICE_DEFAULTS` |
| Shop items added | — | flare, illum, zlogc (logistic center), zwh50 (warehouse resupply) |
| Shop items removed | dynamicarco, dynamictexaco, dynamicsead, dynamicstatic, zsam | (intentional for WWII era) |
| Shop RED items | None | `redzoneupgrade`, `redmassattack` |
| Random upgrades at load | Not present | `applyRandomRedUpgrades()` / `applyRandomBlueUpgrades()` based on `bc.saveLoaded` |
| Warehouse persistence | Not present | `startWarehousePersistence()` |
| `intel` shop condition | Zone must be active (NOT suspended) | Zone must be suspended |
| `DynamicHybridFiller` | Not present | Active |
| `RedReactiveCounterpressure` | Not present | Active |
| `BudgetCommander` (RED AI) | Not present | Active |
| DCS Convoy init target tails | 5 | 15 |

---

## 11. GCW vs WWII Feature Comparison

| Feature | WWII Normandy | GCW Cold War |
|---------|:------------:|:-----------:|
| **Train supply system** | ✅ Full | ❌ None |
| **Naval supply routing** | ✅ `BuildSupplyNavalRoute()` | ❌ Static ships |
| **BATTLESHIP mission type** | ✅ Full | ❌ None |
| **V1 / napalm impact system** | ✅ Full | ❌ None |
| **MOOSE bomber missions** (`StartBomberAuftrag`) | ✅ | ❌ Raw DCS controller |
| **Supply arrow system** (`drawSupplyArrows`) | ✅ Separate from tactical | ❌ Single system |
| **Train-skip arrow logic** | ✅ | ❌ Not applicable |
| **Dual `connections` + `connectionssupply`** | ✅ | ❌ Single list |
| **Supply arrow debounce** | ✅ 60s | ❌ |
| **Zone intel system** | ❌ | ✅ Full |
| **Territory overlay** | ✅ (backported) | ✅ Full |
| **Incremental connection topology** | ❌ Full rebuild each call | ✅ Dirty-flag incremental |
| **`hiddenConnections` list** | ❌ | ✅ |
| **SAM `-sam-` subzone segregation** | ✅ (backported to new) | ✅ |
| **`MISSING_GROUPS{}` tracking** | ✅ (backported to new) | ✅ |
| **`ResolveNamedGroupTemplate` (3-step)** | ✅ (backported to new) | ✅ |
| **`HideSAMOnMFD` configurable** | ❌ | ✅ |
| **Zone `size` parameter** | ❌ | ✅ `'big'/'medium'/'small'` etc. |
| **`NeutralAtStart` / `Popup` zones** | ❌ | ✅ Insurgency/popup |
| **FSM crash monitor** | ❌ | ✅ |
| **Spawn evaluation budget** | ❌ | ✅ |
| **Recon mission tracking** | ✅ (new, via `startZoneIntel`) | ✅ Full |
| **Flight time credit system** | ❌ | ✅ |
| **Era-conditional templates** | ❌ (WWII only) | ✅ Coldwar/Modern branches |
| **`createDirectoryRecursive()` in-file** | ❌ | ✅ |
| **`isCarrierZoneName()` helper** | ✅ (with "naval" token) | ✅ (without "naval") |
| **`landingSpotPoolByPrefix` pool system** | ✅ (backported) | ✅ |
| **`DynamicHybridFiller`** | ✅ (backported) | ✅ |
| **`RedReactiveCounterpressure`** | ✅ (backported) | ✅ |
| **`BudgetCommander`** | ✅ RED side | ✅ |

---

## Appendix: Key Line Number Reference

| Item | File | Approx. Line |
|------|------|-------------|
| Zone caches (6) | Engine | 22–70 |
| `buildZoneByName()` | Engine | ~72 |
| Landing spot pool system | Engine | 83–215 |
| `PrecomputeLandingSpots()` | Engine | 216–260 |
| `buildTemplateCache()` | Engine | 261–300 |
| `FetchMETemplate()` | Engine | ~302 |
| `ResolveNamedGroupTemplate()` | Engine | 351–380 |
| `isCarrierZoneName()` | Engine | 831 |
| `SpawnCustom()` | Engine | ~845 |
| `CustomZone` class | Engine | 671–910 |
| `CustomZone:spawnGroup()` | Engine | ~960 |
| `collectSubZones()` | Engine | ~515 |
| `GlobalSettings` defaults | Engine | ~3700 |
| `_globalArrowCounter = 1201` | Engine | 3681 |
| `NAVAL_ROUTE_DEBUG_LOGGING` | Engine | 5245 |
| `dc.FindSafeWaterPoint()` | Engine | 5255 |
| `dc.BuildSupplyNavalRoute()` | Engine | 5349 |
| `DRAW_SUPPLY_ARROWS_DEBUG_LOGGING` | Engine | 14300 |
| `supplyArrowLog()` | Engine | 14303 |
| `BattleCommander.supplyArrowDebounce` | Engine | ~14370 |
| `drawSupplyArrowsDebounced()` | Engine | 14378 |
| `drawSupplyArrows()` | Engine | 14415 |
| `getTrainGroupForConnection()` | Engine | 14279 |
| `DrawConnectionLines()` | Engine | 14537 |
| `RefreshConnectionsLines()` | Engine | ~14597 |
| `WaypointList` | Setup | 1 |
| `upgrades` table | Setup | ~24 |
| Zone definitions (`zones = {}`) | Setup | ~282 |
| Blue supply connections | Setup | ~900 |
| Red supply connections | Setup | ~923 |
| EWR trigger callbacks | Setup | ~991 |
| V1 `addCriticalObject` calls | Setup | ~760 |
| Shop items | Setup | ~1200–1800 |
| `supplyZones` list | Setup | ~1800 |
| `bc:init()` boot sequence | Setup | ~1875 |
| `evc`/`mc` / events | Setup | ~1953 |
| `sceneryList` | Setup | ~2400 |
| `RAILWAY_STATION_GROUPS` | Setup | ~2500 |
| ATIS airbase cache | WelcomeMessage | 17–33 |
| `BuildAllZonesFromFootholdZones()` | WelcomeMessage | ~51 |
| WWII callsign table | WelcomeMessage | ~370–440 |
| ESSEX carrier ATIS | WelcomeMessage | ~503–560 |
| `EscortClientGroup()` | WelcomeMessage | ~1650 |
| Event registrations | WelcomeMessage | end of file |
