# WWII Normandy Foothold - Player Guide

## Mission Overview

Welcome to the WWII Normandy Foothold dynamic campaign! This is a persistent territory control mission where the Blue coalition (Allies) fights to liberate France from Red coalition (Axis) control. Your actions directly impact the outcome of the campaign.

### Mission Versions

**Two versions are available:**

- **Full Version** (`WWII_Normandy_Foothold_Custom_v1.0.miz`) - Requires all mods installed for complete functionality
- **No Mods Version** (`WWII_Normandy_Foothold_Custom_v1.0_nomods.miz`) - **No mods required**, but V1 rocket launchers will be non-functional

**Note:** If playing the nomods version, V1 launch sites will exist on the map but cannot fire rockets due to the missing V1 launcher mod. All other mission features remain fully functional.
            If you switch between versions you will have to delete or rename the file foothold_normandy_1.0.lua

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Territory Control System](#territory-control-system)
3. [Supply & Logistics](#supply--logistics)
4. [Railway System](#railway-system)
5. [Dynamic Events](#dynamic-events)
6. [V1 Rocket Sites](#v1-rocket-sites)
7. [Strategic Objectives](#strategic-objectives)
8. [Credits & Economy](#credits--economy)
9. [Mission Tracking](#mission-tracking)
10. [Radio Menus & Features](#radio-menus--features)
11. [AI Support](#ai-support)

---

## Getting Started

### Spawning In

When you spawn at any airfield or carrier, you will receive:
- **Automatic Callsign Assignment** with IFF code
- **Weather Information** (wind, temperature, altimeter)
- **Active Runway Information** (for airbases)
- **BRC Information** (for carrier operations)

---

## Territory Control System

### Zone Types

**Capturable Zones:**
- **Airbases** - Can be captured and upgraded with supplies
- **Cities** - Strategic locations providing income
- **Ports** - Critical for naval operations
- **Railway Stations** - Supply network hubs

**Special Zones:**
- **Radar Sites** - Provide enemy early warning (Pointe des Groins, Pointe du Hoc, Cap Gris-Nez)
- **V1 Launch Sites** - Active rocket launching facilities
- **Hidden Railway Subzones** - Automatically sync with parent zone control

### Zone Status

- **Blue (Allied)** - Friendly territory
- **Red (Axis)** - Enemy territory
- **Neutral (Gray)** - Contested/unoccupied

### Capturing Zones

**Ground Units:**
Zones are captured when:
1. All enemy units in the zone are destroyed
2. Friendly ground units enter and hold the zone
3. Supply convoys successfully reach neutral zones

**Supply Delivery:**
Neutral zones can be captured by:
- Using **Emergency Capture** from F10 menu (500 credits)
- Waiting for automatic supply convoy arrival
- C47 cargo delivery (not landing due to DCS , orbiting in zone to capture)
- Train & Trucks supply convoy (train will continuously move between zone , due to DCS it can'y be late activated)

---

## Supply & Logistics

### Supply Mechanics

**What Supply Does:**
- Spawns defensive units (infantry, armor, AAA)
- Repairs damaged units
- Upgrades zone defenses
- Required to capture neutral zones

**Supply Costs:**
- **Resupply Zone**: 200 credits
- **Fully Upgrade Zone**: 1,000 credits
- **Emergency Capture**: 500 credits

### Supply Routes (Arrows on Map)

**Blue Arrow (Road Supply):**
- Convoy trains & truck routes between zones
- Vulnerable to air attack
- Slower but more flexible
- Air supply by C-47

**Train Icon (Railway Supply):**
- Fast, efficient supply lines
- Follows railway infrastructure
- **Destroyed if railway station is destroyed**

### Supply Convoys

**Automatic Behavior:**
- AI commander automatically dispatches supply missions
- Convoys spawn from friendly zones
- Travel to zones needing supplies or under threat
- Priority given to:
  - Neutral zones near capture
  - Damaged friendly zones
  - Frontline positions

**Player Missions:**
Generated every 2-5 minutes, tracked in mission list:
- "**Resupply [Zone]**" - Escort supply convoy
- Completion awards credits and helps war effort

---

## Railway System

### Railway Infrastructure

**Railway Stations (Critical Targets!):**
Each major zone has hidden railway depots that supply military units:

**Blue Railways:**
- London → Farnborough, Manston, Ford, Chailey, Hawkinge

**Red Railways:**
- Paris → Orly, Saint-Andre, Fecamp, Saint-Aubain
- Cherbourg → Valognes → Le Molay → Caen
- Le Havre → Fecamp, Rouen
- Amiens → Abbeville → Le Touquet
- Dunkirk-Port → Calais

### Railway Destruction Effects

**When you destroy a railway station:**
1. **All dependent train groups immediately destroyed**
2. **Supply route permanently broken** (shown on map)
3. **Bonus credits awarded** (2,000 per dependent unit destroyed)
4. **Strategic impact message** displayed

**Example:** Destroying the railway at Abbeville stops all trains running:
- Amiens → Abbeville
- Abbeville → Le Touquet

### Finding Railway Targets

Railway stations are **hidden subzones** near major airbases and cities. Look for:
- Railway track clusters
- Train depot buildings
- Fuel tanks near tracks
- Static train cars
- photos of targets are available in kneeboards

**Tip:** Use low-altitude reconnaissance to locate exact positions before bombing runs.

### Train Groups

**Active Train Routes:**
- Carry supplies between zones
- **1,000 credit bonus** for destroying enemy trains

---

## Dynamic Events

### Event Frequency

Events occur based on EventCommander schedule:
- **Check Frequency**: Every 30-60 minutes
- **Skip Chance**: 10% chance to skip
- **Cooldowns**: Prevent rapid successive events

### Event Types

#### 1. **Bomber Red (Enemy Strike)**

**Frequency:** Every ~35 minutes minimum

**Description:**
- 6x enemy bombers spawn from Red airbase
- Target: Random Blue zone
- May have fighter escort

**Player Mission:**
- **"Intercept Bombers"**
- Destroy bombers before they reach target
- Rewards: Credits for kills + zone defense

**Spawn/Target Examples:**
- From: Orly, Abbeville, Merville, Carpiquet
- To: BigginHill, Ford, Dover, Manston

---

#### 2. **Bomber Blue (Allied Strike)**

**Frequency:** Every ~30 minutes minimum

**Description:**
- 4x Allied bombers B-17G spawn from Blue airbase
- Target: Random Red zone
- 2x Fighter escort
- **Enemy interceptors will scramble!**

**Player Mission:**
- **"Bomber Strike"**
- Escort bombers to target
- Defend against Red interceptors
- Cover bombing run

**Warning Messages:**
- "Allied bombers launched from [Zone]"
- "Target: [Zone]"
- "WARNING: Expect enemy interceptors!"

---

#### 3. **Navy Artillery Strike**

**Frequency:** Every ~40 minutes minimum

**Description:**
- Naval strike group approaches French coast
- Targets: Saint-Pierre areas
- Vulnerable to air attack

**Player Mission:**
- **"Naval Artillery CAP"**
- Provide air cover for naval group
- Intercept enemy strikers
- Ensure naval bombardment succeeds

---

#### 4. **V1 Rocket Attack**

**Frequency:** Every ~45 minutes minimum

**Description:**
- V1 rockets launch toward Blue zones
- Multiple rockets per barrage
- Launch from active V1 sites

**Player Mission:**
- **"V1 Rocket Attack"**
- Locate and destroy launch site
- Intercept rockets in flight (difficult)
- Evacuate target area

**Active V1 Sites:**
- Brecourt
- Herbouville
- Val Ygot
- Crecy Forest
- Flixecourt
- Wallon-Cappel
- Neuville

**⚠️ Note for Nomods Version:** V1 rocket attacks will NOT occur in the nomods mission version due to the missing V1 launcher mod. V1 sites can still be destroyed for bonus credits, but they will not launch rockets.

---

## V1 Rocket Sites

### ⚠️ Nomods Version Limitation

**If playing the nomods version (`WWII_Normandy_Foothold_Custom_v1.0_nomods.miz`):**
- V1 launch sites exist on the map
- Sites can still be destroyed for bonus credits (500 cr each)
- **V1 rockets will NOT launch** due to missing V1 launcher mod
- All other gameplay features remain functional

### Destroying V1 Sites

Each V1 site has TWO critical targets:

#### 1. **V1 Launcher Units**
- Mobile launcher vehicles (v1_launcher, V1x10)
- Usually 1 launchers per site
- Destroy to stop rocket launches
- **Not present in nomods version**

#### 2. **Fuel Storage Tanks**
- Static fuel tank ("toplivo-bak" model)
- One per site
- Destruction of fuel tank will simulate destruction of launcher and Fire control with multiple explosions
- **Required for site destruction bonus and disable the zone**

### Complete Destruction Process

**Step 1:** Locate V1 site zone (marked on map)

**Step 2:** Destroy all launcher units
- Bomb or strafe launcher vehicles
- Site will be still active unless fuel tank is destroyed at mission restart (but no more launch possible if launcher was destroyed)

**Step 3:** Destroy fuel tank
- Usually near launchers
- Large static fuel tank model
- **Napalm effect triggers on destruction!**

**Step 4:** Site permanently disabled
- Zone marked as destroyed
- **500 credit bonus** awarded
- Message: "V1 Launch Site at [Name] Destroyed"

### Napalm Effect

When fuel tanks are destroyed:
- Large explosion triggered
- Fire effects spread
- Nearby units damaged
- Big smoke column (visual marker)

### V1 Site Locations

1. **V1 Launch Site - Brecourt**
2. **V1 Launch Site - Herbouville**
3. **V1 Launch Site - Val Ygot**
4. **V1 Launch Site - Crecy Forest**
5. **V1 Launch Site - Flixecourt**
6. **V1 Launch Site - Wallon-Cappel**
7. **V1 Launch Site - Neuville**

Each site has hidden fuel tank: "Fueltank-[SiteName]"

---

## Strategic Objectives

### High-Value Targets

#### Radar Sites (1,000 credits each)
- **Pointe des Groins** - Cherbourg area
- **Pointe du Hoc** - Normandy coast
- **Cap Gris-Nez** - Calais area

**Effect:** Disables enemy early warning, site cannot respawn

#### Railway Stations (2,000+ credits)
Strategic infrastructure targets:
- Destroy to cut enemy supply chains
- Bonus for each dependent unit destroyed
- Permanently breaks supply routes

#### V1 Sites (500 credits each)
- Stop rocket attacks on Allied territory
- Must destroy both launchers AND fuel tanks
- 7 sites total

### Income-Generating Zones

Capturing these provides **continuous credit income**:

**High Value (Income = 1):** 360 credits/hour
- BigginHill, Farnborough, Odiham
- Dover, Ford, Needs Oar Point
- Cherbourg, Calais, Le Havre
- London, Paris, Orly
- Valognes, Caen, Amiens, Rouen, Merville

**Strategic Locations:**
- Major airbases
- Port cities
- Capital regions

---

## Credits & Economy

### Earning Credits

**Combat Rewards:**
- Infantry kill: 10 credits
- Ground vehicle: 10 credits
- SAM system: 30 credits
- Structure: 30 credits
- Airplane: 30 credits
- Helicopter: 30 credits
- Ship: 250 credits
- Cargo crate delivery: 200 credits
- Rescued pilot: 100 credits

**Strategic Bonuses:**
- Radar site destroyed: 1,000 credits
- V1 site destroyed: 500 credits
- Railway station destroyed: 2,000+ credits (plus dependent units)
- Enemy train destroyed: 1,000 credits

**Mission Completion:**
- Dynamic CAP mission: Variable (100 credits per kill target)
- Mission objectives: Tracked and rewarded

**Zone Income:**
- Passive income from controlled zones
- 360 credits/hour per income zone

### Spending Credits (F10 Menu)

**Supply Options:**
- Resupply Zone: 200 credits
- Fully Upgrade Zone: 1,000 credits
- Emergency Capture (Neutral): 500 credits

**Air Support (F10 → Shop):**
- Dynamic CAP: 250 credits
- Dynamic CAS: 250 credits

**Reconnaissance:**
- Smoke Markers: 20 credits
- Shows enemy positions with red smoke

### Credit Penalties

**-100 credits** when you die/lose aircraft
- Encourages careful flying
- RTB and rearm rather than suicide runs

---

## Mission Tracking

### Mission Types

The mission system automatically generates objectives:

#### 1. **Resupply Missions**
- "Resupply [Zone]"
- Escort supply convoys
- Protect friendly zones needing supplies
- Generated every 2-5 minutes

#### 2. **Attack Missions**
- "Attack [Zone]"
- Destroy enemy forces
- Target frontline enemy zones
- Generated every 2-5 minutes

#### 3. **Capture Missions**
- "Capture [Zone]"
- Secure neutral territory
- Help supply convoys reach zone
- Generated every 2-5 minutes

#### 4. **CAP Missions**
- Dynamic player competition
- Kill X enemy aircraft
- Scoreboard tracks kills
- Winner gets bonus credits

#### 5. **Event Missions**
- Bomber interception
- Bomber escort
- Naval artillery escort
- V1 site destruction
- Generated by event system

### Mission Audio Cues

**Mission Start:**
- "Ding" sound for new mission
- Check F10 mission list

**Mission End:**
- "Cancel" sound
- Check results

**Special Missions:**
- "CAS" sound for attack missions
- "Admin" sound for special events

---

## Radio Menus & Features

### F10 Menu Structure

#### **ATIS and Closest Airbase**
- Get Closest Friendly Airbase
  - Distance and bearing
  - Current weather
  - Active runway
- Get ATIS for Mother (Carrier)
- Get ATIS for [Airbase]
  - Wind, altimeter, runway info

#### **Shop Menu** (Credits required)
- Resupply friendly Zone: 200 cr
- Fully Upgrade Friendly Zone: 1,000 cr
- Emergency capture neutral zone: 500 cr
- Dynamic CAP: 250 cr
- Dynamic CAS: 250 cr
- Smoke markers: 20 cr

### ATIS Information

**Available at Blue Airbases:**
- BigginHill, Odiham, Farnborough
- Manston, Hawkinge, Lympne
- Chailey, Ford, Tangmere, Funtington
- Needs Oar Point, Friston
- And all captured French bases

**ATIS Provides:**
- Current wind (direction/speed)
- Altimeter setting
- Active runway(s)
- Temperature

**Carrier ATIS:**
- Wind on deck
- Altimeter
- BRC (Base Recovery Course)
- TACAN information

---

## AI Support

### Dynamic CAP (250 credits)

**How it works:**
1. Purchase from F10 menu
2. Select spawn zone from submenu
3. AI fighters spawn and establish CAP
4. **Automatic interception** of enemy aircraft
5. RTB when mission complete

**Availability:**
- Requires 1+ enemy aircraft in area
- Cooldown: 30 minutes after previous CAP ends
- Player competition: Kill targets for bonus

### Dynamic CAS (250 credits)

**How it works:**
1. Purchase from F10 menu
2. Select target enemy zone
3. AI finds closest Blue zone (20+ NM away)
4. Mosquitos spawn and attack target
5. Provides ground support

**Best Used For:**
- Softening enemy defenses
- Supporting ground offensives
- Clearing heavily defended zones


## Tips & Strategies

### For New Players

1. **Start Simple**
   - Spawn at BigginHill or Farnborough
   - Check F10 missions
   - Escort supply convoys first
   - Learn the map layout

2. **Use ATIS**
   - Always get weather before takeoff
   - Check closest friendly airbase
   - Know your emergency alternates

3. **Watch Your Credits**
   - Don't waste on unnecessary purchases
   - Save for strategic upgrades
   - Death costs 100 credits!

4. **Mission Priority**
   - Resupply missions help the most
   - Attack missions when confident
   - CAP missions for air combat practice

### Advanced Tactics

1. **Railway Interdiction**
   - Study railway supply map
   - Target choke points
   - Destroy stations for maximum impact
   - Follow up on broken supply lines

2. **V1 Site Elimination**
   - Recon first - locate fuel tanks
   - Use heavy ordnance
   - Confirm both launchers AND tank destroyed
   - Watch for napalm effect

3. **Coordinated Strikes**
   - Time attacks with bomber events
   - Use Dynamic CAS + player CAS
   - Clear air defenses before bombers arrive
   - Escort is force multiplier

4. **Income Strategy**
   - Prioritize capturing income zones
   - Defend income zones from attack
   - Upgrade defenses at income locations
   - Passive income funds the war

### Carrier Operations

---

## Persistence System

### Mission Progress Saves

**Automatically Saved:**
- Zone control status
- Credit balances
- Shop item availability
- Railway destruction status
- V1 site destruction status
- Train group destruction status
- Unit deployment levels

**On Mission Restart:**
- Previous state restored
- Destroyed railways remain destroyed
- Destroyed V1 sites remain destroyed
- Destroyed trains remain destroyed
- Zone ownership preserved
- Credit balance preserved

### Save File Location

`DCS/Missions/Saves/foothold_normandy_1.0.lua`

**Manual Reset:**
Can be triggered via F10 menu when mission complete

---

## Victory Conditions

### Mission Complete

**Win Condition:**
All Red zones captured or destroyed

**Triggers when:**
- No enemy zones remain active
- All V1 sites destroyed
- All strategic objectives captured

**Completion Message:**
"Enemy has been defeated. Mission Complete."

**Options After Victory:**
- Continue playing
- Restart mission (via F10 menu)
- Save progress cleared on restart

---

## Troubleshooting

### Common Issues

**"No ATIS available"**
- Airbase not Blue controlled
- Check zone status on map
- Capture airbase first

**"Supply convoy not arriving"**
- Railway destroyed - use road supply
- Zone surrounded - clear route
- Use Emergency Capture (500 cr)

**"CAP mission not generating"**
- No enemy aircraft in area
- Previous CAP on cooldown
- Check enemy air activity

**"Credits not awarded"**
- Target may be neutral
- Check coalition of target
- Some units worth 0 credits

### Performance

**If experiencing lag:**
- Dynamic events spawn many units
- Multiple convoys running
- Use "Destroy Group" commands for finished AI missions
- Some automatic cleanup occurs

---

## Mission Details

**Mission Name:** WWII Normandy Foothold v2.2
**Theater:** Normandy 1944
**Era:** World War II
**Type:** Dynamic Territory Control
**Difficulty:** Variable (depends on player coordination)
**Recommended Players:** 2-32
**Persistence:** Enabled

---

## Credits

**Original Mission Developer:** Leka - Creator of the Foothold Framework
**Custom Implementation:** WWII Normandy Adaptation
**V1 Launcher Mod:** SUNTSAG - Creator of the WW2 V1 German Rocket Launcher mod
**Scripts:**
- Moose Framework
- BattleCommander System
- ZoneCommander
- EventCommander
- MissionCommander
- Custom welcome/ATIS system

---

## Quick Reference

### Important Zones
- **Allied HQ:** London, BigginHill, Farnborough
- **Axis HQ:** Paris, Orly
- **Strategic Ports:** Cherbourg, Calais, Le Havre, Dover

### Quick Credits
- Infantry/Vehicle: 10 cr
- SAM/Structure/Aircraft: 30 cr
- Ship: 250 cr
- Radar Site: 1,000 cr
- V1 Site: 500 cr
- Railway: 2,000+ cr
- Train: 1,000 cr

### Event Frequency
- Check: Every 30-60 min
- Bomber Red: ~30 min cooldown
- Bomber Blue: ~35 min cooldown
- Navy Strike: ~40 min cooldown
- V1 Attack: ~45 min cooldown

---

**Good luck, and may your bombs fly true!** 🎯
