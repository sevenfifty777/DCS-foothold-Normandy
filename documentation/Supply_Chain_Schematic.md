# Supply Chain Schematic — WWII Normandy Foothold

> **🚂 Train: NOT ACTIVE** — 5 railway zones defined but commented out (`HiddenRailwayLondonVictoria`, `Waterloo`, `LondonBridge`, `Dover`, `Ford`).

---

## ✈️ AIR SUPPLY (`SupplyAirTemplate`)

### 🔴 AXE

```
ORLY (hub) ──► Le Havre, Caen, Saint-André, Amiens, Merville, DunkirkPort, Cherbourg
BERNAY ──────► Caen
```

### 🔵 UK

```
FARNBOROUGH (hub) ──► BigginHill [Air], Ford* [Air], NeedsOarPoint [Air]
                  └──► Odiham [Convoy]

BIGGINHILL (hub) ───► London, Manston, Dover, Friston, Chailey
                 └──► Calais* (urgent if captured)

MANSTON ────────────► DunkirkPort* (urgent)
NEEDS OAR POINT ────► Cherbourg*, Maupertus* (urgent)
ODIHAM ─────────────► Cherbourg*, Caen* (urgent)
```

_\* = AXE zone, supplied urgently when UK-captured_

---

## 🚛 GROUND CONVOY (`SupplyConvoy`)

### 🔴 AXE permanent chains

| From | → To |
|---|---|
| Caen | Sainte-Croix, Carpiquet |
| Cherbourg | Maupertus |
| Dunkirk | Calais |
| DunkirkPort | Dunkirk, Saint-Omer |
| Le Molay | Cricqueville, Longues-Sur-Mer, Saint-Pierre |
| Merville | Saint-Omer |
| Valognes | Brucheville |

### 🔵 UK home territory chains

```
London ──► BigginHill
Dover ──► Hawkinge ──► Lympne
Ford ──► Tangmere ──► Funtington
Chailey ──► Friston
Farnborough ──► Odiham
Dunkirk ──► Calais  (permanent once Dunkirk is UK-held, not ForceUrgent)
```

### 🔵 UK forward convoys _(ForceUrgent — captured AXE zones re-supply neighbours)_

| From (if UK-held) | → To |
|---|---|
| Amiens | Abbeville, Rouen, Paris |
| Abbeville | Amiens, Le Touquet, Fécamp |
| Bernay | Saint-André, Saint-Aubain, Rouen |
| Caen | Carpiquet, Sainte-Croix, Le Molay, Longues-Sur-Mer, Saint-Pierre, Bernay, Saint-Aubain |
| Calais | Dunkirk, Saint-Omer, Le Touquet |
| Carpiquet | Bernay |
| Cherbourg | Valognes, Maupertus, Brucheville |
| Cricqueville | Le Molay, Longues-Sur-Mer |
| Dunkirk | Saint-Omer, Merville |
| DunkirkPort | Dunkirk, Saint-Omer, Merville |
| Fécamp | Le Havre, Rouen |
| Le Havre | Fécamp, Rouen, Bernay |
| Le Molay | Cricqueville, Longues-Sur-Mer, Saint-Pierre |
| Le Touquet | Abbeville, Merville |
| Longues-Sur-Mer | Le Molay, Saint-Pierre |
| Maupertus | Valognes, Brucheville |
| Merville | Abbeville, Le Havre |
| Paris | Orly |
| Rouen | Amiens, Fécamp, Saint-André, Saint-Aubain |
| Saint-André | Rouen, Orly |
| Saint-Aubain | Rouen |
| Sainte-Croix | Le Molay, Saint-Pierre |
| Saint-Omer | Merville, Abbeville, Le Touquet |
| Saint-Pierre | Le Molay, Sainte-Croix |
| Valognes | Le Molay, Brucheville |
| Brucheville | Cricqueville, Le Molay |

---

## ⚓ NAVAL (`SupplyNavalTemplate` via hidden zones)

### 🔴 AXE hidden ports

| From | → To |
|---|---|
| Naval Cherbourg | Le Havre |
| Naval Le Havre | DunkirkPort, CarrierGroup (attack) |
| Naval Dieppe | AxeCarrierGroup |
| Naval Dunkirk | Cherbourg, Dover (attack) |

> Forms a coastal ring: `Cherbourg → Le Havre → DunkirkPort` with Dunkirk closing the loop back to Cherbourg.

### 🔴 AXE zone-based naval supply

| From (zone, AXE-held) | → To |
|---|---|
| DunkirkPort | Le Havre |

> Distinct from the hidden ports above — this runs from the `DunkirkPort` zone itself when AXE-controlled.

### 🔵 UK hidden ports

| From | → To |
|---|---|
| Naval Portsmouth | CarrierGroup, Cherbourg, Cricqueville, Longues-Sur-Mer, Saint-Pierre |
| Naval Dover | CarrierGroup, AxeCarrierGroup, DunkirkPort, Calais, Dunkirk |

> Portsmouth supplies the D-Day landing beaches; Dover handles the Channel/Pas-de-Calais zone.

---

## 🚂 TRAIN (planned, not active)

The v2.5.3 working script has **no hidden railway zones** defined. However, the supply network topology includes `"train"` type connections registered via `bc:addConnectionSupply` for both coalitions — these define intended rail corridors without spawning any vehicles.

**UK train corridors (topology only):**
- London → Manston, Farnborough, Chailey, Ford, Hawkinge

**AXE train corridors (topology only):**
- Cherbourg → Valognes → Le Molay → Caen
- Bernay → Caen
- Amiens → Abbeville → Le Touquet
- DunkirkPort → Calais, Le Havre
- Le Havre → Rouen, Fécamp
- Paris → Orly, Saint-Aubain, Fécamp, Saint-André → Bernay

The older production script (`Normandy_Zone_Setup-Custom.lua`) retains 11 commented-out hidden railway zone definitions (LondonVictoria, Waterloo, LondonBridge, Dover, Ford, Hawkinge, Cherbourg, Valognes, Caen, Le Havre, Bernay). Reactivating trains requires restoring those zones and adding `GroupCommander` train template entries.
