# Supply Missions Reference
## DCS Foothold Normandy - GroupCommander Supply Routes

This document lists all active supply missions configured in the mission.

---

## Axis/AXE Supply Network

### Ground Convoys (SupplyConvoy Template)

| Source Zone | Destination Zone | Mission Name | Notes |
|------------|------------------|--------------|-------|
| Caen | Sainte-Croix | AXE_Caen-resupply-SainteCroix | |
| Caen | Carpiquet | AXE_Caen-resupply-Carpiquet | |
| Cherbourg | Maupertus | AXE_Cherbourg-resupply-Maupertus | |
| Dunkirk | Calais | AXE_Dunkirk-resupply-Calais | |
| DunkirkPort | Dunkirk | AXE_DunkirkPort-resupply-Dunkirk | |
| DunkirkPort | Saint-Omer | AXE_DunkirkPort-resupply-SaintOmer | |
| Merville | Saint-Omer | AXE_Merville-resupply-SaintOmer | |
| Le Molay | Cricqueville | AXE_LeMolay-resupply-Cricqueville | |
| Le Molay | Longues-Sur-Mer | AXE_LeMolay-resupply-LonguesSurMer | |
| Le Molay | Saint-Pierre | AXE_LeMolay-resupply-SaintPierreDuMont | |
| Valognes | Brucheville | AXE_Valognes-resupply-Brucheville | |

### Air Supply - C-47 Transport (No Template / Default)

| Source Zone | Destination Zone | Mission Name | Notes |
|------------|------------------|--------------|-------|
| Bernay | Caen | AXE_Bernay-resupply-Caen | C-47 airlift |
| Orly | Le Havre | AXE_Orly-resupply-LeHavre | C-47 airlift from hub |
| Orly | Caen | AXE_Orly-resupply-Caen | C-47 airlift from hub |
| Orly | Saint-Andre | AXE_Orly-resupply-SaintAndre | C-47 airlift from hub |
| Orly | Amiens | AXE_Orly-resupply-Amiens | C-47 airlift from hub |
| Orly | Merville | AXE_Orly-resupply-Merville | C-47 airlift from hub |
| Orly | Dunkirk-Port | AXE_Orly-resupply-DunkirkPort | C-47 airlift from hub |
| Orly | Cherbourg | AXE_Orly-resupply-Cherbourg | C-47 airlift from hub |

### Naval Supply (SupplyNavalTemplate)

| Source Zone | Destination Zone | Mission Name | Notes |
|------------|------------------|--------------|-------|
| DunkirkPort | Le Havre | AXE_DunkirkPort-resupply-LeHavre | Port to port |
| hiddenAXENavalbaseCherbourg | Le Havre | AXE_hiddenAXENavalbaseCherbourg-resupply-LeHavre | Conditional: Cherbourg.active |
| hiddenAXENavalbaseLeHavre | Dunkirk-Port | AXE_hiddenAXENavalbaseLeHavre-resupply-DunkirkPort | |
| hiddenAXENavalbaseDieppe | AxeCarrierGroup | AXE_hiddenAXENavalbaseDieppe-resupply-AxeCarrierGroup | Conditional: SaintAubain.active |
| hiddenAXENavalbaseDunkirk | Cherbourg | AXE_hiddenAXENavalbaseDunkirk-resupply-Cherbourg | |

**Total Axis Supply Routes: 24**

---

## Allied/UK Supply Network

### Ground Convoys (SupplyConvoy Template)

| Source Zone | Destination Zone | Mission Name | Notes |
|------------|------------------|--------------|-------|
| Farnborough | Odiham | UK_Farnborough-resupply-Odiham | |
| Dover | Hawkinge | UK_Dover-resupply-Hawkinge | |
| Hawkinge | Lympne | UK_Hawkinge-resupply-Lympne | |
| Ford | Tangmere | UK_Ford-resupply-Tangmere | |
| Tangmere | Funtington | UK_Tangmere-resupply-Funtington | |
| Chailey | Friston | UK_Chailey-resupply-Friston | |
| London | BigginHill | UK_London-resupply-BigginHill | |

### Air Supply - C-47 Transport (No Template / Default)

| Source Zone | Destination Zone | Mission Name | Notes |
|------------|------------------|--------------|-------|
| BigginHill | Manston | UK_BigginHill-resupply-Manston | C-47 airlift |
| BigginHill | Dover | UK_BigginHill-resupply-Dover | C-47 airlift |
| BigginHill | Friston | UK_BigginHill-resupply-Friston | C-47 airlift |
| BigginHill | Chailey | UK_BigginHill-resupply-Chailey | C-47 airlift |
| BigginHill | Calais | UK_BigginHill-resupply-Calais | C-47 airlift |
| Farnborough | BigginHill | UK_Farnborough-resupply-BigginHill | C-47 airlift |
| Farnborough | Ford | UK_Farnborough-resupply-Ford | C-47 airlift - Urgent if Ford contested |
| Farnborough | Needs Oar Point | UK_Farnborough-resupply-NeedsOarPoint | C-47 airlift |
| Manston | Dunkirk-Port | UK_Manston-resupply-DunkirkPort | C-47 airlift |
| Odiham | Cherbourg | UK_Odiham-resupply-Cherbourg | C-47 airlift |
| Odiham | Caen | UK_Odiham-resupply-Caen | C-47 airlift |

### Naval Supply (SupplyNavalTemplate)

| Source Zone | Destination Zone | Mission Name | Notes |
|------------|------------------|--------------|-------|
| hiddenUKNavalbasePortsmouth | CarrierGroup | UK_hiddenUKNavalbasePortsmouth-resupply-CarrierGroup | Urgent if carrier contested |
| hiddenUKNavalbaseDover | AxeCarrierGroup | UK_hiddenUKNavalbaseDover-capture-AxeCarrierGroup | Conditional/Urgent capture mission |
| hiddenUKNavalbaseDover | Dunkirk-Port | UK_hiddenUKNavalbaseDover-capture-DunkirkPort | Conditional/Urgent capture mission |
| hiddenUKNavalbaseDover | Calais | UK_hiddenUKNavalbaseDover-capture-Calais | Conditional/Urgent capture mission |
| hiddenUKNavalbaseDover | CarrierGroup | UK_hiddenUKNavalbaseDover-supply-CarrierGroup | Conditional: Dover.active |

**Total Allied Supply Routes: 23**

---

## Supply Type Definitions

### SupplyConvoy
Ground-based convoy supply missions using trucks and ground transport vehicles.

### SupplyNavalTemplate
Naval supply missions using ships to transport supplies between ports and naval bases.

### Air Supply - C-47 Transport (No Template)
Air supply missions using C-47 Skytrain/Dakota aircraft to transport supplies between airfields. These missions use the default surface type but are executed via airlift rather than ground convoy.

---

## Supply Mission Conditions

Some supply missions have special conditions:

- **Urgent Missions**: Triggered when destination zone is contested (side == 0)
  - `UK_Farnborough-resupply-Ford` (ForceUrgent if Ford contested)
  - `UK_hiddenUKNavalbasePortsmouth-resupply-CarrierGroup` (urgent if carrier contested)
  - Naval capture missions from Dover

- **Conditional Missions**: Only active when source zone is active
  - `AXE_hiddenAXENavalbaseCherbourg-resupply-LeHavre` (requires Cherbourg.active)
  - `AXE_hiddenAXENavalbaseDieppe-resupply-AxeCarrierGroup` (requires SaintAubain.active)
  - All hiddenUKNavalbaseDover missions (require Dover.active)

---

## Major Supply Hubs

### Axis Supply Hubs
- **Orly**: Major hub supplying 7 destinations (Le Havre, Caen, Saint-Andre, Amiens, Merville, Dunkirk-Port, Cherbourg)
- **Le Molay**: Regional hub supplying 3 destinations (Cricqueville, Longues-Sur-Mer, Saint-Pierre)
- **DunkirkPort**: Coastal hub with both naval and ground supply capabilities

### Allied Supply Hubs
- **BigginHill**: Major hub supplying 5 destinations (Manston, Dover, Friston, Chailey, Calais)
- **Farnborough**: Strategic hub supplying 4 destinations (BigginHill, Odiham, Ford, Needs Oar Point)
- **hiddenUKNavalbaseDover**: Naval hub with capture and resupply missions

---

## Statistics Summary

| Category | Axis/AXE | Allied/UK | Total |
|----------|----------|-----------|-------|
| Ground Convoys (SupplyConvoy) | 11 | 7 | 18 |
| Air Supply - C-47 Transport | 8 | 11 | 19 |
| Naval Supply (SupplyNavalTemplate) | 5 | 5 | 10 |
| **Total Active Routes** | **24** | **23** | **47** |

---

*Generated from: `scripts/Normandy_Zone_Setup-Custom.lua`*  
*Mission Version: 2.5.3*  
*Last Updated: December 16, 2025*
