# DCS Foothold Normandy

A dynamic territory control mission for DCS World set in World War II Normandy, where Allied forces fight to liberate France from Axis control.

## 🎯 Mission Overview

**WWII Normandy Foothold** is a persistent, dynamic campaign featuring:
- Territory capture and control mechanics
- Strategic railway interdiction system
- V1 rocket launch sites
- Dynamic supply logistics
- Persistent progression across mission restarts
- AI commander systems for both sides
- Credit-based economy for purchasing support

## 📚 Documentation

Detailed guides and information:

- **[Player Guide](documentation/Foothold_Normandy_Player_Guide.md)** - Complete mission guide with all features, mechanics, and strategies
- **[Player Guide (HTML)](documentation/Foothold_Normandy_Player_Guide.html)** - Web-friendly version

## 🎮 Mission Files

- **Mission File**: [`missions/WWII_Normandy_Foothold_Custom_v1.0.miz`](missions/)
- **Theater**: Normandy 1944 Map (required)
- **Era**: World War II
- **Players**: 2-32 recommended
- **Type**: Dynamic Territory Control with Persistence

## 🔧 Required Pack/Mods

### DCS: WWII Assets Pack
The DCS: World War II Assets Pack provides numerous World War II air, land and sea assets to populate the Normandy and other DCS World maps with. Eagle Dynamics has spent several years creating an entirely new set of combat vehicles to support DCS: World War II, and each unit is created with an exceptional level of detail and accuracy.

In addition to populating World War II era maps, this asset pack can be used with all other DCS World map modules.

- **Type**: Official DCS Module (Required)
- **Available**: DCS E-Shop and Steam

### V1 Rocket Launcher
The V1 German Rocket Launcher mod is essential for the mission's V1 rocket attack mechanics.

- **Documentation**: [V1 Launcher Installation Guide](documentation/WW2%20V1%20German%20Rocket%20Launcher.md)
- **Download**: [Mega.nz Link](https://mega.nz/file/YZcThapa#esMMJJWy590onz6fWJgMs7RvZ9pk5Crzp6ETmiYW4L0)
- **Creator**: SUNTSAG

### Railway Assets Pack WWII
Adds historically accurate railway assets for enhanced visual realism.

- **Documentation**: [Railway Assets Installation Guide](documentation/Railway%20Assets%20Pack%20WWII.md)
- **Download**: [ED User Files](https://www.digitalcombatsimulator.com/en/files/3345513/)
- **Location**: Also included in [`mods/tech/`](mods/tech/)

### Aircraft Liveries
Custom German WWII liveries for period-accurate aircraft appearance.

- **B-17G German Liveries**: [`mods/liveries/B-17G.rar`](mods/liveries/) *(Not currently used in mission)*
- **C-47 German Liveries**: [`mods/liveries/C-47.rar`](mods/liveries/) *(Used for Axis transport due to lack of dedicated German transport aircraft)*

**Note**: These liveries are optional enhancements and not required for mission functionality.

## 📜 Mission Scripts

The mission uses several custom Lua scripts for dynamic gameplay:

### Core Scripts
- **[Moose Framework](scripts/Moose_2025-09-27_TT.lua)** - Main framework for mission logic
- **[Zone Commander](scripts/zoneCommander_moose-Custom_WWII.lua)** - Territory control and zone management
- **[Normandy Zone Setup](scripts/Normandy_Zone_Setup-Custom.lua)** - Zone definitions and configuration

### Gameplay Systems
- **[Zeus Full v2.0](scripts/zeus_Full_v2.0.lua)** - Dynamic spawning and other action via F10 marker
- **[Splash Damage](scripts/Splash_Damage_3.4.2_Standard_With_Ground_Ordnance.lua)** - Enhanced damage mechanics
- **[EWRS](scripts/EWRS.lua)** - Early Warning Radar System simulating WWII-era radar detection and tracking
- **[Tracker V1](scripts/TrackerV1.lua)** - V1 Rocket tracking (EWR style)
- **[Welcome Message](scripts/WelcomeMessage_Normandy.lua)** - Player briefing and ATIS system

## 🎯 Key Features

### Territory Control
- Capture airbases, cities, ports, and railway stations
- Supply and logistics system with convoy escorts
- Zone upgrade mechanics using credits

### Strategic Objectives
- **Railway Interdiction**: Destroy enemy supply lines for massive strategic impact
- **V1 Launch Sites**: Eliminate rocket threats (7 sites total)
- **Radar Sites**: Disable enemy early warning systems
- **Dynamic Events**: Bomber strikes, naval artillery, and more

### Economy System
- Earn credits through combat and objectives
- Purchase supplies, AI support, and strategic options
- Passive income from controlled territories

### Persistence
- Mission state saves automatically
- Destroyed infrastructure remains destroyed
- Territory ownership persists across restarts
- Credit balances maintained

## 🖼️ Target Reference Images

Railway station target references available in [`images/`](images/):
- Abbeville Railway
- Caen Railway
- Calais Railway
- Cherbourg Railway
- Dunkirk Port Railway
- Fecamp Railway & Power Plant
- Le Havre Railway
- Saint-Aubain Train Depot

## 🚀 Quick Start

1. **Install Required Mods** (see above)
2. **Download Mission File** from `missions/` folder
3. **Read Player Guide** for detailed instructions
4. **Launch Mission** in DCS World
5. **Check F10 Menu** for ATIS, objectives, and shop options

## 👥 Credits

- **Original Mission Framework**: Leka - Creator of the Foothold Framework
- **V1 Launcher Mod**: SUNTSAG
- **WWII Normandy Adaptation**: Custom implementation
- **Frameworks**: Moose, BattleCommander, ZoneCommander, EventCommander

## 📋 License

See [LICENSE](LICENSE) file for details.

## 🔗 Repository Structure

```
DCS-foothold-Normandy/
├── documentation/          # Mission guides and mod installation instructions
├── images/                # Reference images for railway targets
├── missions/              # Mission (.miz) file
├── mods/                  # Required mod files
│   ├── liveries/         # Aircraft livery packs
│   └── tech/             # Technical mods (V1 launcher, railway assets)
└── scripts/              # Lua scripts used in the mission
```

---

**Ready to liberate Normandy? Good luck, and may your bombs fly true!** 🎯✈️
