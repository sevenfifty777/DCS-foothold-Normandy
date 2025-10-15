# Zeus Manual (English)

## Installation

**Prerequisite:** You need to comment following lines in `MissionScripting.lua`:

```lua
--sanitizeModule('io')
--sanitizeModule('lfs')
```

Create trigger: **DO SCRIPT FILE** and select `zeus_Full_v2.0.lua` file

## Options

Added Napalm and Phosphor option for Strike Ground effects. By default, effects are disabled.

To enable (`true`) / disable (`false`) each effect, modify those options on top of the script:

```lua
options = {
  ["napalm"] = false, 
  ["phosphor"] = false, 
}
```

## Zeus How To

Creation of Bandits (jet, Warbird, helo), support (JTAC, AWACS), Ground effect (Illumination, smoke, strike)

### Creation Method

Creates a marker on the map F10: `UnitModel;UnitName;Coalition` (without closing the marker)

- **UnitModel**: corresponds to the type of aircraft to spawn
- **Semicolon** (`;`) is required
- **UnitName**: corresponds to a name of your choice that is different each time if several spawn (if the UnitName is the same it destroys the previously created unit and replaces it with the new one)
- **Coalition**: this is optional to force the coalition side

### Unit Destruction Method

The easiest way is to use the same marker and replace the UnitModel with `destroy`

**Example:**

Creation:
```
f15;bandit01
mig29;toto05
```

Destruction:
```
destroy;bandit01
destroy;toto05
```

If you give same UnitName, UnitModel previous aircraft will be destroyed and new one created.

## Support Units

Support (JTAC, tanker)

**Support:** The units created will be from the same coalition as your player, immortal and invisible.

### JTAC
- **Drone**: Predator
- **Freq JTAC**: 134.000 MHz AM (invisible, immortal)

### Texaco 5.1
- **Aircraft**: KC-135MPRS
- **Freq**: 283.000
- **TACAN**: 68X
- **Alt**: 24000
- **Hypodrome**: west-east departure

### Arco 5.1
- **Aircraft**: KC-135
- **Freq**: 282.000
- **TACAN**: 69X
- **Alt**: 20000
- **Hypodrome**: west-east departure

**Note:** The Texaco always does a spin before getting into its pattern (I don't know why). Arco freq set to 282 to allow F4 to call refuelling.

### Support (UnitModel) List:
- `jtac`
- `texaco`
- `arco`

**Example:**
```
jtac;reaper1
texaco;tkr1
arco;tkr2
```

## Bandits Units

Bandits (jet, Warbird, helo (WIP))

**Bandits:** The units created will be from the enemy coalition.

### Jets (UnitModel) List:
- `mig29`
- `mig23`
- `mig21`
- `j11`
- `m2k`
- `f14`
- `f15`
- `f16`
- `f18`
- `f1`
- `f4`
- `f5`
- `mig28`

**Note:** The `mig28` is a black livery F5 (Top Gun)

**Example:**
```
mig29;bandit1
mig28;mechant3
```

### Warbird (UnitModel) List:
- `p51`
- `spit`
- `mossy`
- `bf109`
- `fw190d9`
- `fw190a8`
- `ju88`

**Example:**
```
bf109;achtungbaby
```

## Ground Effects

Ground effect (Illumination, smoke, strike)

### Illumination
Flares lighting up on the marker 15 seconds after creation. 5 flares are released at the marker at a random altitude between 600 and 1200 m, lifetime ~ 5 min.

**Creation marker on F10:** `illumin;name`

**Example:**
```
illumin;here
```

### Smoke
Smoke created at the marker (red, green, white, blue, orange)

**Creation marker on F10:** `smoke;color`

**Possibilities:**
```
smoke;green
smoke;red
smoke;white
smoke;blue
smoke;orange
```

### Strike
Simulates artillery strike request. 15 explosions at the marker within a radius of +/- 30 meters, altitude between 0-5 meters and random power, options for Napalm and Phosphor.

**Creation marker on F10:** `strike;name`

**Example:**
```
strike;here
```

## Modification

This script is still WIP, planning to add ship and ground unit. Already tested spawning CVN but it causes some issues and warehouse is empty when carrier is spawned.

The spawn logic by default: all aircraft will spawn in opposite coalition except tanker and JTAC.

Now you have option to force the coalition, this is explained at the beginning of this doc.

### Adding New Units

You can add more units yourself.

To add new aircraft you just need to add it in list at the top of the script (`airUnitDB`) which corresponds to the UnitModel you will have to put in marker.

Then add simplified data like for F14, where you have to choose template, most of aircraft are `fighter` or `fighter_link16` like F16, F18 or F15.

Then define your payload, speed, altitude, livery, etc.

**Example:**

```lua
["f14"] = {
    template = "fighter",
    type = "F-14B",
    livery = "rogue nation(top gun - maverick)",
    altitude = 8534.4,
    speed = 220.97222222222,
    frequency = 124,
    payload = {
        pylons = {
            [1] = {["CLSID"] = "{LAU-138 wtip - AIM-9M}"},
            [2] = {["CLSID"] = "{SHOULDER AIM-7P}"},
            [3] = {["CLSID"] = "{F14-300gal}"},
            [4] = {["CLSID"] = "{AIM_54C_Mk60}"},
            [5] = {["CLSID"] = "{AIM_54C_Mk60}"},
            [6] = {["CLSID"] = "{AIM_54C_Mk60}"},
            [7] = {["CLSID"] = "{AIM_54C_Mk60}"},
            [8] = {["CLSID"] = "{F14-300gal}"},
            [9] = {["CLSID"] = "{SHOULDER AIM-7P}"},
            [10] = {["CLSID"] = "{LAU-138 wtip - AIM-9M}"}
        },
        fuel = 7348,
        flare = 60,
        ammo_type = 1,
        chaff = 140,
        gun = 100
    }
},
```

## Contact

You can send me message in ED forum: [https://forum.dcs.world/profile/122914-titi69/](https://forum.dcs.world/profile/122914-titi69/)
