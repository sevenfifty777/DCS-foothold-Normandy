# Arrow ID & Supply Arrow Changes

This document summarizes the changes made to arrow/marker allocation and supply-arrow handling to avoid ID collisions and keep the original arrow system working.

## Summary of problems
- Both the original connection arrows and the custom supply-arrow system used numeric IDs that overlapped.
- The engine (and other script code) removes marks by numeric ID in many places; collisions caused arrows to disappear unexpectedly.

## Files changed
- `scripts/new templates logic/WWII_Normandy_Foothold_Custom_v2.5.3/zoneCommander_moose-Custom_WWII_new.lua`
  - Added non-destructive guards for globals: `_globalArrowCounter = _globalArrowCounter or 1201` and `_activeArrowIds = _activeArrowIds or {}`.
  - Introduced `ARROW_ID_OFFSET` and local supply allocation: `supplyArrowCounter` and `supplyActiveArrowIds` to isolate the custom supply arrow ID space from mission marks and the original arrow system.
  - Added per-connection mapping `BattleCommander.supplyArrowIds` so supply arrows are tracked per connection key (`from..">"..to`).
  - In `drawSupplyArrows()`:
    - Remove any existing per-key arrow before drawing new one.
    - Allocate new arrow IDs from `supplyArrowCounter` and store in `supplyActiveArrowIds` (short-term) and `self.supplyArrowIds[key]` (persistent per-connection).
    - Prune stale `self.supplyArrowIds` entries after drawing.
  - Added `self:drawSupplyArrowsDebounced(true)` call at the end of `BattleCommander:RefreshConnectionsLines(...)` to ensure supply arrows refresh when connections refresh.

- `scripts/new templates logic/Foothold_GCW_V4.6.0_Coldwar-Modern/zoneCommanderv2.lua`
  - Made initialization of `_globalArrowCounter` and `_activeArrowIds` non-destructive (`or`-guard) so other files won't clobber them if load order differs.

- `scripts/zoneCommander_moose-Custom_WWII.lua`
  - Made initialization of `_globalArrowCounter` and `_activeArrowIds` non-destructive.

- `archive/zoneCommander_moose-Custom_WWII_2.5.3.lua`
  - Made initialization of `_globalArrowCounter` and `_activeArrowIds` non-destructive.

## Rationale
- Avoid numeric ID collisions between mission marks and custom supply arrows by dedicating a high ID range to supply arrows (via `supplyArrowCounter`) and keeping original arrows using the original globals.
- Keep original code behavior unchanged where possible; only the custom system was modified to be self-contained.
- Ensure supply arrows refresh whenever connections are refreshed by adding a safe call at the end of `RefreshConnectionsLines`.

## Behavior after changes
- Original connection arrows: continue to use `_globalArrowCounter` and `_activeArrowIds`.
- Custom supply arrows: draw and track using `supplyArrowCounter`, `supplyActiveArrowIds`, and `self.supplyArrowIds`.
- Supply arrows are refreshed when `drawSupplyArrowsDebounced()` is called; `RefreshConnectionsLines` also triggers the debounced redraw now, ensuring coverage for most update paths.

## Testing checklist (recommended)
1. Start the mission in DCS and verify connection arrows from the original system still appear and persist.
2. Trigger supply-related events (train spawn/destroy, connection changes) and verify supply arrows appear and persist.
3. Observe logs if `DRAW_SUPPLY_ARROWS_DEBUG_LOGGING = true` to confirm draw/skip decisions.
4. Watch for any Lua errors; functions use `pcall` on optional removals to avoid exceptions.

## Rollback steps
- Revert the edits to the file(s) listed above. Use git to checkout the previous versions or delete the new additions in this repo if required.

## Notes & follow-ups
- If load-order issues appear, further guard initialization of the globals (already done) or centralize arrow ID allocation into a single utility (e.g., `UTILS.GetMarkID()` is used by the original code; consider using it for supply arrows if desired).
- If you'd like, I can run a final grep and generate a short list of all `trigger.action.removeMark`/`arrowToAll` call sites for a deeper audit.

## Audit: mark/arrow API call sites found
Below are the repository locations where DCS mark/arrow APIs were detected. These are potential places that allocate or remove numeric mark IDs and may interact with arrow IDs.

- `scripts/new templates logic/WWII_Normandy_Foothold_Custom_v2.5.3/zoneCommander_moose-Custom_WWII_new.lua`:
  - `trigger.action.removeMark(markId)` [L2101]
  - `trigger.action.markToCoalition(missionMarkId, ...)` [L3783, L3828]
  - multiple `trigger.action.removeMark(event.idx)` usages around L11269-L11446
  - `trigger.action.arrowToAll(..., arrowId, ...)` usages around L15806-L15945
  - `trigger.action.markToCoalition(id, ...)` [L29249]

- `scripts/Splash_Damage_3.4.2_Standard_With_Ground_Ordnance - WWII.lua`:
  - `trigger.action.markToCoalition(markerId, ...)` [L2598]
  - `trigger.action.removeMark(id)` [L2604, L2638]

- `scripts/zoneCommander_moose-Custom_WWII.lua`:
  - `trigger.action.removeMark(markId)` [L2101]
  - `trigger.action.markToCoalition(missionMarkId, ...)` [L3779, L3824]
  - `trigger.action.arrowToAll(..., arrowId, ...)` usages around L15788-L15913
  - multiple `trigger.action.removeMark(event.idx)` usages around L11265-L11401
  - `trigger.action.markToCoalition(id, ...)` [L29212]

- `scripts/new templates logic/Foothold_GCW_V4.6.0_Coldwar-Modern/zoneCommanderv2.lua`:
  - `trigger.action.markToCoalition(missionMarkId, ...)` [L3834, L3879]
  - `trigger.action.arrowToAll(..., arrowId, ...)` usages around L15390-L15445
  - `trigger.action.markToCoalition(id, ...)` [L28679]

- `archive/zoneCommander_moose-Custom_WWII_2.5.3.lua`:
  - `trigger.action.markToCoalition(missionMarkId, ...)` [L2107, L2141]
  - `trigger.action.arrowToAll(..., arrowId, ...)` usages around L7933-L8091

These matches are a good starting point for auditing who creates and who removes marks by numeric ID. If you want, I can:

- Expand the list with exact code snippets for each match.
- Add a short recommendation per site whether it should use the shared `UTILS.GetMarkID()` or a namespaced allocator.


---
Generated changeset documentation by automated edits on request.
