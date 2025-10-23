env.info("ZoneSetup: is loading.")

function merge(tbls)
	local res = {}
	for i,v in ipairs(tbls) do
		for i2,v2 in ipairs(v) do
			table.insert(res,v2)
		end
	end
	
	return res
end

function allExcept(tbls, except)
	local tomerge = {}
	for i,v in pairs(tbls) do
		if i~=except then
			table.insert(tomerge, v)
		end
	end
	return merge(tomerge)
end
-- PROFILER.Start() -- don't run during mission CPU consumption profiling
-- Define how many upgrade levels (1-5), and what equipment is part of the upgrade level - for every zonetype you plan to use.
upgrades = {
	CarrierEssexUpgrades = {
		blue = {"CarrierEssexSeaman"},
		red = {}
	},
    CarrierUpgrades = {
        blue = {"CarrierGroup-Chase", "CarrierGroup-LST"},
        red = {}
    },
    AxeCarrierUpgrades = {
        blue = {"CarrierGroup-LST", "CarrierGroup-LST"},
        red = {'AxeCarrierGroup-Chase','AxeCarrierGroup-LST','AxeCarrierGroup-subs', 'AxeCarrierGroup-schnell'}
    },
    airfieldUK1 = {
        blue = {"UK-INF-MK1", "UK-ARMOR", "UK-AAA-OPTFLAK", "UK-TRUCK", "UK-AAA-bofors", "UK-AAA-M1"},
        red = {}
    },
	airfieldUK2 = {
        blue = {"UK-INF-MK1", "UK-ARMOR", "UK-AAA-OPTFLAK", "UK-TRUCK", "UK-AAA-QF", "UK-AAA-M45"},
        red = {}
    },
	airfieldFR1 = {
        blue = {"UK-INF-MK1", "UK-ARMOR", "UK-AAA-OPTFLAK", "UK-TRUCK", "UK-AAA-bofors", "UK_ART-FHM2A1"},
        red = {"AXE-ART-FH", "AXE-ARMOR-LIGHT", "AXE-AAA-OPTFLAK", "AXE-TRUCK", "AXE-AAA-18-36"}
    },
	airfieldFR2 = {
        blue = {"UK-INF-MK1", "UK-ARMOR", "UK-AAA-OPTFLAK", "UK-TRUCK", "UK-AAA-bofors", "UK-ART-L118"},
        red = {"AXE-ART-SPH", "AXE-ARMOR-LIGHT", "AXE-AAA-OPTFLAK", "AXE-TRUCK", "AXE-AAA-37-41"}
    },

	DunkirkPort = {
		blue = {},
		red = {}
	},
	Cherbourg = {
		blue = {},
		red = {}
	},
	Calais = {
		blue = {},
		red = {}
	},
	LeHavre = {
		blue = {},
		red = {}
	},
	Caen = {
		blue = {},
		red = {}
	},
	Valognes = {
		blue = {},
		red = {}
	},
	Paris = {
		blue = {},
		red = {"Paris-AAA-37-41", "Paris-AAA-37-41-1", "Paris-AAA-37-41-2"}
	},
	Orly = {
		blue = {},
		red = {"AXE-ART-SPH", "AXE-ARMOR-TIG-PAN", "AXE-AAA-OPTFLAK", "AXE-TRUCK", "AXE-AAA-37-41"}
	},
	London = {
		blue = {"London-AAA-bofors", "London-AAA-bofors-1", "London-AAA-bofors-2"},
		red = {}
	},
	empty = {
		blue = {},
		red = {}
	},
	V1 = {
		blue = {},
		red = {"AXE-INF-MAUSER98"}
	},
	V1_Brecourt = {
		blue = {},
		red = {"AXE-INF-MAUSER98", "V1 Launch Site - Brecourt", "Fueltank-Brecourt"}
	},
	V1_Wallon_Cappel = {
		blue = {},
		red = {"AXE-INF-MAUSER98", "V1 Launch Site - Wallon-Cappel", "Fueltank-WallonCappel"}
	},
	V1_Crecy_Forest = {
		blue = {},
		red = {"AXE-INF-MAUSER98", "V1 Launch Site - Crecy Forest", "Fueltank-CrecyForest"}
	},
	V1_Flixecourt = {
		blue = {},
		red = {"AXE-INF-MAUSER98", "V1 Launch Site - Flixecourt", "Fueltank-Flixecourt"}
	},
	V1_Val_Ygot = {
		blue = {},
		red = {"AXE-INF-MAUSER98", "V1 Launch Site - Val Ygot", "Fueltank-ValYgot"}
	},
	V1_Herbouville = {
		blue = {},
		red = {"AXE-INF-MAUSER98", "V1 Launch Site - Herbouville", "Fueltank-Herbouville"}
	},
	V1_Neuville = {
		blue = {},
		red = {"AXE-INF-MAUSER98", "V1 Launch Site - Neuville", "Fueltank-Neuville"}
	},


	----------------Radar Upgrades----------------
	
	EWRPointeDesGroins = {
		blue = {},
		red = {"AXE-AAA-37-Pointe-des-Groins", "AXE-AAA-OPTFLAK-Pointe-des-Groins", "EWR-Pointe-des-Groins",}
	},
	EWRPointeDuHoc = {
		blue = {},
		red = {"EWR-PointeDuHoc",}
	},
	EWRCapGrisNez = {
		blue = {},
		red = {"EWR-CapGrisNez"}
	},
	
	
	--[[
	hidden = {
        blue = {},
        red = {"Red EWR Fixed", "Red EWR Fixed 2", "Red EWR Fixed 3", 'Red SAM SHORAD SA-15 Fixed Hidden', 'Red Navy Patrol Fixed',}
    }
		--]]
}




-- Set flavor text for your mission waypoints/zones
flavor = {
	BigginHill = 'WPT 1\n',
	Odiham = 'WPT 2\n',
	Farnborough = 'WPT 3\n',
	Manston = 'WPT 4\n',
	Hawkinge = 'WPT 5\n',
	Lympne = 'WPT 6\n',
	Chailey = 'WPT 7\n',
	Ford = 'WPT 8\n',
	Tangmere = 'WPT 9\n',
	Funtington = 'WPT 10\n',
	['Needs Oar Point'] = 'WPT 11\n',
	Friston = 'WPT 12\n',
	Dunkirk = 'WPT 13\n',
	['Dunkirk-Port'] = 'WPT 14\n',
	['Saint-Omer'] = 'WPT 15\n',
	Merville = 'WPT 16\n',
	Abbeville = 'WPT 17\n',
	Amiens = 'WPT 18\n',
	Cherbourg = 'WPT 19\n',
	Calais = 'WPT 20\n',
	['Saint-Aubain'] = 'WPT 21\n',
	Fecamp = 'WPT 22\n',
	['Le Havre'] = 'WPT 23\n',
	Rouen = 'WPT 24\n',
	Carpiquet = 'WPT 25\n',
	Caen = 'WPT 26\n',
	['Sainte-Croix'] = 'WPT 27\n',
	['Saint-Pierre'] = 'WPT 28\n',
	['Longues-Sur-Mer'] = 'WPT 29\n',
	Cricqueville = 'WPT 30\n',
	['Le Molay'] = 'WPT 31\n',
	Brucheville = 'WPT 32\n',
	Valognes = 'WPT 33\n',
	Maupertus = 'WPT 34\n',
	Bernay = 'WPT 35\n',
	['Saint-Andre'] = 'WPT 36\n',
	CarrierGroup = 'WPT 37\n',
	AxeCarrierGroup = 'WPT 38\n',
	Paris = 'WPT 39\n',
	Orly = 'WPT 40\n',
	London = 'WPT 41\n',
	['Pointe des Groins'] = 'WPT 42\n',
	['Pointe du Hoc'] = 'WPT 43\n',
	['Cap Gris-Nez'] = 'WPT 44\n',
	['Le Touquet'] = 'WPT 45\n',
	Dover = 'WPT 46\n'

}



-- Setup the file path for pesistent status saving
local filepath = 'foothold_normandy_1.0.lua'
if lfs then 
	local dir = lfs.writedir()..'Missions/Saves/'
	lfs.mkdir(dir)
	filepath = dir..filepath
	env.info('Foothold - Save file path: '..filepath)
end
bc = BattleCommander:new(filepath, 10, 60)



-- Define all your zones on the map, which side they start as, upgrade level and more. These can be capturable or give a specific benefit or bonus.
-- Side 0 = Neutral, Side 1 = Red and Side 2 = Blue
-- The income parameter is amount of credits per tick, a tick is 10 seconds. Ie. 1 = 360 credits per hour, 2 = 720, 3 = 1080, 4 = 1440 and 5 = 1800.

zones = {
    BigginHill = ZoneCommander:new({zone='BigginHill', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.BigginHill, income=1}),
	Odiham = ZoneCommander:new({zone='Odiham', side=2, level=20, upgrades=upgrades.airfieldUK2, crates={}, flavorText=flavor.Odiham, income=1}),
	Farnborough = ZoneCommander:new({zone='Farnborough', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Farnborough, income=1}),
	Manston = ZoneCommander:new({zone='Manston', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Manston}),
	Dover = ZoneCommander:new({zone='Dover', side=0, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Dover, income=1, NeutralAtStart=true}),
	Hawkinge = ZoneCommander:new({zone='Hawkinge', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Hawkinge}),
	Lympne = ZoneCommander:new({zone='Lympne', side=2, level=20, upgrades=upgrades.airfieldUK2, crates={}, flavorText=flavor.Lympne}),
	Chailey = ZoneCommander:new({zone='Chailey', side=2, level=20, upgrades=upgrades.airfieldUK2, crates={}, flavorText=flavor.Chailey}),
	Ford = ZoneCommander:new({zone='Ford', side=0, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Ford, income=1, NeutralAtStart=true}),
	Tangmere = ZoneCommander:new({zone='Tangmere', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Tangmere}),
	Funtington = ZoneCommander:new({zone='Funtington', side=2, level=20, upgrades=upgrades.airfieldUK2, crates={}, flavorText=flavor.Funtington}),
	NeedsOarPoint = ZoneCommander:new({zone='Needs Oar Point', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.NeedsOarPoint, income=1}),
	Friston = ZoneCommander:new({zone='Friston', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Friston}),
	Dunkirk = ZoneCommander:new({zone='Dunkirk', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Dunkirk}),
	DunkirkPort = ZoneCommander:new({zone='Dunkirk-Port', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.DunkirkPort, income=1}),
	SaintOmer = ZoneCommander:new({zone='Saint-Omer', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.SaintOmer}),
	Merville = ZoneCommander:new({zone='Merville', side=0, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Merville, income=1}),
	Abbeville = ZoneCommander:new({zone='Abbeville', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Abbeville}),
	Amiens = ZoneCommander:new({zone='Amiens', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Amiens, income=1, NeutralAtStart=true}),
	Cherbourg = ZoneCommander:new({zone='Cherbourg', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Cherbourg, income=1}),
	Calais = ZoneCommander:new({zone='Calais', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Calais, income=1}),
	SaintAubain = ZoneCommander:new({zone='Saint-Aubain', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.SaintAubain}),
	Fecamp = ZoneCommander:new({zone='Fecamp', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Fecamp}),
	LeHavre = ZoneCommander:new({zone='Le Havre', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.LeHavre, income=1}),
	Rouen = ZoneCommander:new({zone='Rouen', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Rouen, income=1}),
	Carpiquet = ZoneCommander:new({zone='Carpiquet', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Carpiquet}),
	Caen = ZoneCommander:new({zone='Caen', side=0, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Caen, income=1, NeutralAtStart=true}),
	SainteCroix = ZoneCommander:new({zone='Sainte-Croix', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.SainteCroix}),
	SaintPierre = ZoneCommander:new({zone='Saint-Pierre', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.SaintPierre}),
	LonguesSurMer = ZoneCommander:new({zone='Longues-Sur-Mer', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.LonguesSurMer}),
	Cricqueville = ZoneCommander:new({zone='Cricqueville', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Cricqueville}),
	LeMolay = ZoneCommander:new({zone='Le Molay', side=0, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.LeMolay}),
	Brucheville = ZoneCommander:new({zone='Brucheville', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Brucheville}),
	Valognes = ZoneCommander:new({zone='Valognes', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Valognes, income=1, NeutralAtStart=true}),
	Maupertus = ZoneCommander:new({zone='Maupertus', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Maupertus}),
	Bernay = ZoneCommander:new({zone='Bernay', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Bernay}),
	SaintAndre = ZoneCommander:new({zone='Saint-Andre', side=0, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.SaintAndre}),
	CarrierGroup = ZoneCommander:new({zone='CarrierGroup', side=2, level=20, upgrades=upgrades.CarrierUpgrades, crates={}, flavorText=flavor.CarrierGroup}),
	hiddenCarrierEssex = ZoneCommander:new({zone='HiddenCarrierEssex', side=2, level=20, upgrades=upgrades.CarrierEssexUpgrades}),
	AxeCarrierGroup = ZoneCommander:new({zone='AxeCarrierGroup', side=1, level=20, upgrades=upgrades.AxeCarrierUpgrades, crates={}, flavorText=flavor.AxeCarrierGroup}),
	Paris = ZoneCommander:new({zone='Paris', side=1, level=20, upgrades=upgrades.Paris, crates={}, flavorText=flavor.Paris, income=1}),
	Orly = ZoneCommander:new({zone='Orly', side=1, level=20, upgrades=upgrades.Orly, crates={}, flavorText=flavor.Orly, income=1}),
	London = ZoneCommander:new({zone='London', side=2, level=20, upgrades=upgrades.London, crates={}, flavorText=flavor.London, income=1}),
	PointeDesGroins = ZoneCommander:new({zone='Pointe des Groins', side=1, level=20, upgrades=upgrades.EWRPointeDesGroins, crates={}, flavorText=flavor.PointeDesGroins}),
	PointeDuHoc = ZoneCommander:new({zone='Pointe du Hoc', side=1, level=20, upgrades=upgrades.EWRPointeDuHoc, crates={}, flavorText=flavor.PointeDuHoc}),
	CapGrisNez = ZoneCommander:new({zone='Cap Gris-Nez', side=1, level=20, upgrades=upgrades.EWRCapGrisNez, crates={}, flavorText=flavor.CapGrisNez}),
	LeTouquet = ZoneCommander:new({zone='Le Touquet', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor['Le Touquet'], income=1}),
	V1_Wallon_Cappel = ZoneCommander:new({zone='V1 Launch Site - Wallon-Cappel', side=1, level=20, upgrades=upgrades.V1_Wallon_Cappel, crates={}, flavorText=flavor['V1 Launch Site - Wallon-Cappel']}),
	V1_Crecy_Forest = ZoneCommander:new({zone='V1 Launch Site - Crecy Forest', side=1, level=20, upgrades=upgrades.V1_Crecy_Forest, crates={}, flavorText=flavor['V1 Launch Site - Crecy Forest']}),
	V1_Flixecourt = ZoneCommander:new({zone='V1 Launch Site - Flixecourt', side=1, level=20, upgrades=upgrades.V1_Flixecourt, crates={}, flavorText=flavor['V1 Launch Site - Flixecourt']}),
	V1_Val_Ygot = ZoneCommander:new({zone='V1 Launch Site - Val Ygot', side=1, level=20, upgrades=upgrades.V1_Val_Ygot, crates={}, flavorText=flavor['V1 Launch Site - Val Ygot']}),
	V1_Herbouville = ZoneCommander:new({zone='V1 Launch Site - Herbouville', side=1, level=20, upgrades=upgrades.V1_Herbouville, crates={}, flavorText=flavor['V1 Launch Site - Herbouville']}),
	V1_Brecourt = ZoneCommander:new({zone='V1 Launch Site - Brecourt', side=1, level=20, upgrades=upgrades.V1_Brecourt, crates={}, flavorText=flavor['V1 Launch Site - Brecourt']}),
	V1_Neuville = ZoneCommander:new({zone='V1 Launch Site - Neuville', side=1, level=20, upgrades=upgrades.V1_Neuville, crates={}, flavorText=flavor['V1 Launch Site - Neuville']}),

	hiddenRailwayFord = ZoneCommander:new({zone='HiddenRailwayFord', side=2, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayCherbourg = ZoneCommander:new({zone='HiddenRailwayCherbourg', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayValognes = ZoneCommander:new({zone='HiddenRailwayValognes', side=0, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayCaen = ZoneCommander:new({zone='HiddenRailwayCaen', side=0, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenTrainDepotValognes = ZoneCommander:new({zone='HiddenTrainDepotValognes', side=0, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayLeHavre = ZoneCommander:new({zone='HiddenRailwayLeHavre', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayBernay = ZoneCommander:new({zone='HiddenRailwayBernay', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwaySaintAndre = ZoneCommander:new({zone='HiddenRailwaySaintAndre', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayOrly = ZoneCommander:new({zone='HiddenRailwayOrly', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayParisSaintLazare = ZoneCommander:new({zone='HiddenRailwayParisSaintLazare', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayParisGareDuNord = ZoneCommander:new({zone='HiddenRailwayParisGareDuNord', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayParisGareDeLest = ZoneCommander:new({zone='HiddenRailwayParisGareDeLest', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayFecamp = ZoneCommander:new({zone='HiddenRailwayFecamp', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayPowerplantFecamp = ZoneCommander:new({zone='HiddenRailwayPowerplantFecamp', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayDepotRouen = ZoneCommander:new({zone='HiddenRailwayDepotRouen', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayDepotSaintAubain = ZoneCommander:new({zone='HiddenRailwayDepotSaintAubain', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayTrainDepotAmiens = ZoneCommander:new({zone='HiddenRailwayTrainDepotAmiens', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayAbbeville = ZoneCommander:new({zone='HiddenRailwayAbbeville', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayDunkirkPort = ZoneCommander:new({zone='HiddenRailwayDunkirkPort', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayLeTouquet = ZoneCommander:new({zone='HiddenRailwayLeTouquet', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),
	hiddenRailwayCalais = ZoneCommander:new({zone='HiddenRailwayCalais', side=1, level=20, upgrades=upgrades.empty, isRailwaySubzone=true}),


}

-- Railway subzone to parent zone mapping
-- This defines which railway subzones are contained within which parent zones
RAILWAY_SUBZONE_MAPPING = {
    ["hiddenRailwayFord"] = "Ford",           -- hiddenRailwayFord subzone is inside Ford zone
    ["hiddenRailwayCherbourg"] = "Cherbourg", -- hiddenRailwayCherbourg subzone is inside Cherbourg zone
	["hiddenRailwayValognes"] = "Valognes",   -- hiddenRailwayValognes subzone is inside Valognes zone
	["hiddenTrainDepotValognes"] = "Valognes", -- hiddenTrainDepotValognes subzone is inside Valognes zone
	["hiddenRailwayCaen"] = "Caen",           -- hiddenRailwayCaen subzone is inside Caen zone
	["hiddenRailwayLeHavre"] = "LeHavre",     -- hiddenRailwayLeHavre subzone is inside LeHavre zone
	["hiddenRailwayBernay"] = "Bernay",       -- hiddenRailwayBernay subzone is inside Bernay zone
	["hiddenRailwaySaintAndre"] = "SaintAndre", -- hiddenRailwaySaintAndre subzone is inside SaintAndre zone
	["hiddenRailwayOrly"] = "Orly",           -- hiddenRailwayOrly subzone is inside Orly zone
	["hiddenRailwayParisSaintLazare"] = "Paris", -- hiddenRailwayParisSaintLazare subzone is inside Paris zone
	["hiddenRailwayParisGareDuNord"] = "Paris",  -- hiddenRailwayParisGareDuNord subzone is inside Paris zone
	["hiddenRailwayParisGareDeLest"] = "Paris",  -- hiddenRailwayParisGareDeLest subzone is inside Paris zone
	["hiddenRailwayFecamp"] = "Fecamp",           -- hiddenRailwayFecamp subzone is inside Fecamp zone
	["hiddenRailwayPowerplantFecamp"] = "Fecamp", -- hiddenRailwayPowerplantFecamp subzone is inside Fecamp zone
	["hiddenRailwayDepotRouen"] = "Rouen",             -- hiddenRailwayDepotRouen subzone is inside Rouen zone
	["hiddenRailwayDepotSaintAubain"] = "SaintAubain", -- hiddenRailwayDepotSaintAubain subzone is inside SaintAubain zone
	["hiddenRailwayTrainDepotAmiens"] = "Amiens",     -- hiddenRailwayTrainDepotAmiens subzone is inside Amiens zone
	["hiddenRailwayAbbeville"] = "Abbeville",         -- hiddenRailwayAbbeville subzone is inside Abbeville zone
	["hiddenRailwayDunkirkPort"] = "DunkirkPort",   -- hiddenRailwayDunkirkPort subzone is inside DunkirkPort zone
	["hiddenRailwayLeTouquet"] = "LeTouquet",       -- hiddenRailwayLeTouquet subzone is inside LeTouquet zone
	["hiddenRailwayCalais"] = "Calais",             -- hiddenRailwayCalais subzone is inside Calais zone


}


--- Napalm Funtion for V1 site------------------
--- 
napalmCounter = 1

local options = {
  ["napalm"] = true, 
  ["phosphor"] = true,
  ["bigsmoke"] = true,
}


-- Napalm explosion functions (copied from napalm_unit.lua)


local function explodeNapalm(vec3)
    trigger.action.explosion(vec3, 10)
end

local function bigSmoke(vec3)
    trigger.action.effectSmokeBig(vec3, 2, 0.5)
end
local function removeNapalm(staticName) 
StaticObject.getByName(staticName):destroy()
end

local function phosphor(vec3) 
	for i =	1,math.random(3, 10) do 
        azimuth = 30 * i
		--angle = mist.utils.toRadian((math.random(1, 360)))
		--local randVec = mist.utils.makeVec3GL((mist.getRandPointInCircle(vec3, 5, 1, 0, 360)))
		trigger.action.signalFlare(vec3, 2, azimuth)
	end
end

local function napalmOnImpact(impactPoint)
	--env.info("Napalm Impact at: x=" .. tostring(impactPoint.x) .. ", y=" .. tostring(impactPoint.y) .. ", z=" .. tostring(impactPoint.z))
	local napalmName = "napalmImpact" .. napalmCounter
	napalmCounter = napalmCounter + 1
    local owngroupID = math.random(9999,99999)
    local cvnunitID = math.random(9999,99999)
_dataFuel =   
    {
        ["groupId"] = owngroupID,
        ["category"] = "Fortifications",
        ["shape_name"] = "toplivo-bak",
        ["type"] = "Fuel tank",
        ["unitId"] = cvnunitID,
        ["rate"] = 100,
        ["y"] = impactPoint.z,
        ["x"] = impactPoint.x,
        ["name"] = napalmName,
        ["heading"] = 0,
        ["dead"] = false,
        ["hidden"] = true,

    } -- end of function
    

    
    if options.napalm == true then
        coalition.addStaticObject(country.id.CJTF_BLUE, _dataFuel )
        timer.scheduleFunction(explodeNapalm, impactPoint, timer.getTime() + 0.1)
        timer.scheduleFunction(removeNapalm, napalmName, timer.getTime() + 0.12)
    end
  
    if options.phosphor == true then
        timer.scheduleFunction(phosphor, impactPoint, timer.getTime() + 0.12)
    end
	if options.bigsmoke == true then
    	timer.scheduleFunction(bigSmoke, impactPoint, timer.getTime() + 5)
	end


end
function searchTargets(pType, pzone)
	local foundUnits = {}
    local sphere = trigger.misc.getZone(pzone)
	local volS = {
	   id = world.VolumeType.SPHERE,
	   params = {
		 point = sphere.point,
		 radius = sphere.radius
	   }
	 }
	 local ifFound = function(foundItem, val)
				foundUnits[#foundUnits + 1] = foundItem
				return true
			end
	world.searchObjects(pType, volS, ifFound)
	return foundUnits
end

function fUnitCoord(pzone)
    local FoundUnits = nil
	local targetCoord = nil
	local TGT = nil
    
	--local FoundUnits = searchTargets({Object.Category.UNIT, Object.Category.STATIC, Object.Category.SCENERY})
    local FoundUnits = searchTargets(Object.Category.UNIT, pzone)
	if 	FoundUnits ~= nil and #FoundUnits > 0 then
		for i, targetUnit in ipairs(FoundUnits) do
            local delay = math.random(10,20)
			targetCoord = targetUnit:getPoint()
			TYP = targetUnit:getTypeName()
			TGT = targetUnit:getName()
            CAT = targetUnit:getCategory()
            OBJCAT = Object.getCategory(targetUnit)
			
            --trigger.action.outText(TGT.. ': X: '.. targetCoord.x .. ' Y: ' .. targetCoord.y .. ' Z: ' .. targetCoord.z, 10)
            --trigger.action.outText(TGT.. ':: '.. TYP , 10)
            env.info(TGT.. ':: '.. TYP)
            if TYP == "V1x10" or TYP == "v1_launcher" or TYP == "fire_control" then  -- only target units and statics
                timer.scheduleFunction(napalmOnImpact, targetCoord, timer.getTime() + delay)
                if TYP == "V1x10" or TYP == "v1_launcher" then
                    CustomFlags[TGT] = true
                end
            end
        end
	else
		zeusMessages.setMessageDelayed("No Target found in the zone" , 30, 8, true)
		return false
	end
end;

-- Enhanced railway subzone synchronization system
RailwaySyncSystem = {}
RailwaySyncSystem.syncInProgress = false
RailwaySyncSystem.lastSyncTime = 0
RailwaySyncSystem.syncCooldown = 5 -- Minimum seconds between sync operations
RailwaySyncSystem.pendingSyncs = {}
RailwaySyncSystem.syncHistory = {}
RailwaySyncSystem.maxHistorySize = 50

-- Function to synchronize railway subzone coalition with parent zone
function synchronizeRailwaySubzones(forceSync)
    -- Prevent concurrent sync operations
    if RailwaySyncSystem.syncInProgress and not forceSync then
        env.info("Railway Coalition Sync: Sync already in progress, queuing request")
        return false
    end

    -- Rate limiting to prevent performance issues
    local currentTime = timer.getAbsTime()
    if not forceSync and (currentTime - RailwaySyncSystem.lastSyncTime) < RailwaySyncSystem.syncCooldown then
        env.info("Railway Coalition Sync: Rate limited, queuing sync request")
        table.insert(RailwaySyncSystem.pendingSyncs, {time = currentTime, force = forceSync})
        return false
    end

    RailwaySyncSystem.syncInProgress = true
    RailwaySyncSystem.lastSyncTime = currentTime

    env.info("Railway Coalition Sync: Starting robust synchronization of railway subzones with parent zones")

    local syncResults = {
        success = 0,
        failed = 0,
        skipped = 0,
        errors = {}
    }

    for subzoneName, parentZoneName in pairs(RAILWAY_SUBZONE_MAPPING) do
        local success, errorMsg = pcall(function()
            local subzone = zones[subzoneName]
            local parentZone = zones[parentZoneName]

            -- Validate both zones exist
            if not subzone then
                local error = "Railway Coalition Sync: Subzone " .. subzoneName .. " not found in zones table"
                env.error(error)
                table.insert(syncResults.errors, error)
                syncResults.failed = syncResults.failed + 1
                return
            end

            if not parentZone then
                local error = "Railway Coalition Sync: Parent zone " .. parentZoneName .. " not found in zones table"
                env.error(error)
                table.insert(syncResults.errors, error)
                syncResults.failed = syncResults.failed + 1
                return
            end

            -- Skip if already synchronized (unless force sync)
            if not forceSync and subzone.side == parentZone.side then
                --env.info("Railway Coalition Sync: " .. subzoneName .. " already matches parent " .. parentZoneName .. " (both side " .. subzone.side .. ")")
                syncResults.skipped = syncResults.skipped + 1
                return
            end

            -- Validate parent zone state
            if not parentZone.active then
                --env.info("Railway Coalition Sync: Parent zone " .. parentZoneName .. " is inactive, skipping sync for " .. subzoneName)
                syncResults.skipped = syncResults.skipped + 1
                return
            end

            --env.info("Railway Coalition Sync: Synchronizing " .. subzoneName .. " (side " .. subzone.side .. ") with parent " .. parentZoneName .. " (side " .. parentZone.side .. ")")

            -- Store old state for rollback capability
            local oldSubzoneSide = subzone.side
            local oldBcSubzoneSide = nil
            local bcSubzone = bc:getZoneByName(subzone.zone)
            if bcSubzone then
                oldBcSubzoneSide = bcSubzone.side
            end

            -- Perform synchronization
            local syncSuccess = false
            if pcall(function()
                -- Change the subzone to match parent zone coalition
                subzone.side = parentZone.side

                -- Also update the BattleCommander zone if it exists
                if bcSubzone then
                    bcSubzone.side = parentZone.side
                    --env.info("Railway Coalition Sync: Updated BC zone coalition for " .. subzoneName)
                end

                -- If the subzone has an associated zone object in DCS, update it as well
                local dcsZone = trigger.misc.getZone(subzone.zone)
                if dcsZone then
                   --env.info("Railway Coalition Sync: Updated DCS zone coalition for " .. subzoneName)
                end

                syncSuccess = true
            end) then
                if syncSuccess then
                    --env.info("Railway Coalition Sync: Successfully synchronized " .. subzoneName .. " to side " .. parentZone.side)
                    syncResults.success = syncResults.success + 1

                    -- Record sync in history
                    table.insert(RailwaySyncSystem.syncHistory, {
                        time = currentTime,
                        subzone = subzoneName,
                        parent = parentZoneName,
                        oldSide = oldSubzoneSide,
                        newSide = parentZone.side,
                        success = true
                    })

                    -- Trim history if too large
                    if #RailwaySyncSystem.syncHistory > RailwaySyncSystem.maxHistorySize then
                        table.remove(RailwaySyncSystem.syncHistory, 1)
                    end

                    -- Provide feedback to players
                    local coalitionText = parentZone.side == 1 and "RED" or "BLUE"
                    trigger.action.outTextForCoalition(parentZone.side,
                        "Railway station " .. subzoneName .. " now under " .. coalitionText .. " control", 10)
                else
                    -- Rollback on failure
                    subzone.side = oldSubzoneSide
                    if bcSubzone then
                        bcSubzone.side = oldBcSubzoneSide
                    end
                    syncResults.failed = syncResults.failed + 1
                end
            else
                -- Rollback on exception
                subzone.side = oldSubzoneSide
                if bcSubzone then
                    bcSubzone.side = oldBcSubzoneSide
                end
                syncResults.failed = syncResults.failed + 1
            end
        end)

        if not success then
            local error = "Railway Coalition Sync: Exception during sync of " .. subzoneName .. ": " .. errorMsg
            env.error(error)
            table.insert(syncResults.errors, error)
            syncResults.failed = syncResults.failed + 1
        end
    end

    -- Refresh supply arrows to reflect changes
    if syncResults.success > 0 then
        env.info("Railway Coalition Sync: Refreshing supply arrows due to " .. syncResults.success .. " successful synchronizations")
        pcall(function() bc:drawSupplyArrows() end)
    end

    -- Log summary
    env.info(string.format("Railway Coalition Sync: Complete - Success: %d, Failed: %d, Skipped: %d, Errors: %d",
        syncResults.success, syncResults.failed, syncResults.skipped, #syncResults.errors))

    if #syncResults.errors > 0 then
        env.error("Railway Coalition Sync: Errors encountered:")
        for _, error in ipairs(syncResults.errors) do
            env.error("  " .. error)
        end
    end

    RailwaySyncSystem.syncInProgress = false

    -- Process any pending sync requests
    if #RailwaySyncSystem.pendingSyncs > 0 then
        local nextSync = table.remove(RailwaySyncSystem.pendingSyncs, 1)
        --env.info("Railway Coalition Sync: Processing queued sync request")
        timer.scheduleFunction(synchronizeRailwaySubzones, {nextSync.force}, timer.getTime() + 1)
    end

    return syncResults.success > 0
end

-- Make the function globally accessible
_G.synchronizeRailwaySubzones = synchronizeRailwaySubzones

-- Function to register triggers for parent zones to update railway subzones when captured
local function registerRailwaySubzoneTriggers()
    env.info("Railway Coalition Sync: Registering triggers for parent zones")
    
    for subzoneName, parentZoneName in pairs(RAILWAY_SUBZONE_MAPPING) do
        local subzone = zones[subzoneName]
        local parentZone = zones[parentZoneName]
        
        if subzone and parentZone then
            -- Register capture trigger
            parentZone:registerTrigger('captured', function(event, sender)
                --env.info("Railway Coalition Sync: Parent zone " .. parentZoneName .. " captured by side " .. sender.side .. ", updating subzone " .. subzoneName)
                
                -- Update both the local zones table and the BattleCommander zone
                local railwaySubzone = zones[subzoneName]
                local bcRailwaySubzone = bc:getZoneByName(subzone.zone)
                
                if railwaySubzone then
                    railwaySubzone.side = sender.side
                    --env.info("Railway Coalition Sync: Updated local " .. subzoneName .. " to side " .. sender.side)
                end
                
                if bcRailwaySubzone then
                    bcRailwaySubzone.side = sender.side
                    --env.info("Railway Coalition Sync: Updated BC " .. subzoneName .. " to side " .. sender.side)
                end
                
                -- Provide feedback to players
                local coalitionText = sender.side == 1 and "RED" or "BLUE"
                trigger.action.outTextForCoalition(sender.side, 
                    "Railway station " .. subzoneName .. " now under " .. coalitionText .. " control", 10)
                
                -- Refresh supply arrows to reflect the change
                --env.info("Railway Coalition Sync: Refreshing supply arrows due to zone capture")
                bc:drawSupplyArrows()
            end, 'railwaySync_' .. subzoneName .. '_captured')
            
            -- Register lost trigger
            parentZone:registerTrigger('lost', function(event, sender)
                --env.info("Railway Coalition Sync: Parent zone " .. parentZoneName .. " lost by side " .. sender.side)
                -- Note: The subzone will be updated when the new side captures the parent zone
            end, 'railwaySync_' .. subzoneName .. '_lost')
            
            --env.info("Railway Coalition Sync: Registered triggers for " .. parentZoneName .. " -> " .. subzoneName)
        end
    end
    
    env.info("Railway Coalition Sync: All triggers registered")
end

WaypointList = {
	BigginHill = ' (1)',
	Odiham = ' (2)',
	Farnborough = ' (3)',
	Manston = ' (4)',
	Hawkinge = ' (5)',
	Lympne = ' (6)',
	Chailey = ' (7)',
	Ford = ' (8)',
	Tangmere = ' (9)',
	Funtington = ' (10)',
	['Needs Oar Point'] = ' (11)',
	Friston = ' (12)',
	Dunkirk = ' (13)',
	['Dunkirk-Port'] = ' (14)',
	['Saint-Omer'] = ' (15)',
	Merville = ' (16)',
	Abbeville = ' (17)',
	Amiens = ' (18)',
	Cherbourg = ' (19)',
	Calais = ' (20)',
	['Saint-Aubain'] = ' (21)',
	Fecamp = ' (22)',
	['Le Havre'] = ' (23)',
	Rouen = ' (24)',
	Carpiquet = ' (25)',
	Caen = ' (26)',
	['Sainte-Croix'] = ' (27)',
	['Saint-Pierre'] = ' (28)',
	['Longues-Sur-Mer'] = ' (29)',
	Cricqueville = ' (30)',
	['Le Molay'] = ' (31)',
	Brucheville = ' (32)',
	Valognes = ' (33)',
	Maupertus = ' (34)',
	Bernay = ' (35)',
	['Saint-Andre'] = ' (36)',
	CarrierGroup = ' (37)',
	AxeCarrierGroup = ' (38)',
	Paris = ' (39)',
	Orly = ' (40)',
	London = ' (41)',
	['Pointe des Groins'] = ' (42)',
	['Pointe du Hoc'] = ' (43)',
	['Cap Gris-Nez'] = ' (44)',
	['Le Touquet'] = ' (45)',
	Dover = ' (46)',
}

zones.Amiens:addGroups({
    --GroupCommander:new({name='AXE_Amiens-resupply-Abbeville', mission='supply', targetzone='Abbeville', type = 'surface'}),
    --GroupCommander:new({name='AXE_Amiens-resupply-Fecamp', mission='supply', targetzone='Fecamp', type = 'surface'}),
	GroupCommander:new({name='AXE_Amiens-attack-Chailey', mission='attack', targetzone='Chailey', type = 'air'}),
})
zones.Abbeville:addGroups({
    --GroupCommander:new({name='AXE_Abbeville-resupply-Amiens', mission='supply', targetzone='Amiens', type = 'surface'}),
	GroupCommander:new({name='AXE_Abbeville-patrol-LeTouquet', mission='patrol', targetzone='Le Touquet', type = 'air'}),
	--GroupCommander:new({name='AXE_Abbeville-resupply-SaintAubain', mission='supply', targetzone='Saint-Aubain', type = 'surface'}),
})
zones.Bernay:addGroups({
    --GroupCommander:new({name='AXE_Bernay-resupply-SaintAndre', mission='supply', targetzone='SaintAndre', type = 'surface'}),
	GroupCommander:new({name='AXE_Bernay-resupply-Caen', mission='supply', targetzone='Caen', type = 'surface'}),
})
zones.Caen:addGroups({
    GroupCommander:new({name='AXE_Caen-resupply-SainteCroix', mission='supply', targetzone='Sainte-Croix', type = 'surface'}),
    GroupCommander:new({name='AXE_Caen-resupply-Carpiquet', mission='supply', targetzone='Carpiquet', type = 'surface'}),
    --GroupCommander:new({name='AXE_Caen-resupply-LeMolay', mission='supply', targetzone='LeMolay', type = 'surface'}),
})
zones.Calais:addGroups({
    --GroupCommander:new({name='AXE_Calais-resupply-DunkirkPort', mission='supply', targetzone='DunkirkPort', type = 'surface'}),
})
zones.Carpiquet:addGroups({
	GroupCommander:new({name='AXE_Carpiquet-attack-Ford', mission='attack', targetzone='Ford', type = 'air'}),

})
zones.Cherbourg:addGroups({
    GroupCommander:new({name='AXE_Cherbourg-resupply-Maupertus', mission='supply', targetzone='Maupertus', type = 'surface'}),
})

zones.Dunkirk:addGroups({
	GroupCommander:new({name='AXE_Dunkirk-resupply-Calais', mission='supply', targetzone='Calais', type = 'surface'}),
    GroupCommander:new({name='AXE_Dunkirk-patrol-Calais', mission='patrol', targetzone='Calais'}),
})
zones.DunkirkPort:addGroups({
	GroupCommander:new({name='AXE_DunkirkPort-resupply-LeHavre', mission='supply', targetzone='Le Havre', type = 'surface'}),
    GroupCommander:new({name='AXE_DunkirkPort-resupply-Dunkirk', mission='supply', targetzone='Dunkirk', type = 'surface'}),
    GroupCommander:new({name='AXE_DunkirkPort-resupply-SaintOmer', mission='supply', targetzone='Saint-Omer', type = 'surface'}),

})
zones.Fecamp:addGroups({
    --GroupCommander:new({name='AXE_Fecamp-resupply-LeHavre', mission='supply', targetzone='Le Havre', type = 'surface'}),
	GroupCommander:new({name='AXE_Fecamp-patrol-LeHavre', mission='patrol', targetzone='Le Havre'}),
})
zones.Maupertus:addGroups({
	GroupCommander:new({name='AXE_Maupertus-patrol-Cherbourg', mission='patrol', targetzone='Cherbourg'}),
	GroupCommander:new({name='AXE_Maupertus-attack-NeedsOarPoint', mission='attack', targetzone='Needs Oar Point', type = 'air'}),
})

zones.Merville:addGroups({
    GroupCommander:new({name='AXE_Merville-resupply-SaintOmer', mission='supply', targetzone='Saint-Omer', type = 'surface'}),
	GroupCommander:new({name='AXE_Merville-attack-BigginHill', mission='attack', targetzone='BigginHill', type = 'air'}),
})

zones.LeHavre:addGroups({
    --GroupCommander:new({name='AXE_LeHavre-resupply-Fecamp', mission='supply', targetzone='Fecamp', type = 'surface'}),
    --GroupCommander:new({name='AXE_LeHavre-resupply-Rouen', mission='supply', targetzone='Rouen', type = 'surface'}),
})
zones.LeMolay:addGroups({
    GroupCommander:new({name='AXE_LeMolay-resupply-Cricqueville', mission='supply', targetzone='Cricqueville', type = 'surface'}),
	GroupCommander:new({name='AXE_LeMolay-resupply-LonguesSurMer', mission='supply', targetzone='Longues-Sur-Mer', type = 'surface'}),
	GroupCommander:new({name='AXE_LeMolay-resupply-SaintPierreDuMont', mission='supply', targetzone='Saint-Pierre', type = 'surface'}),
	--GroupCommander:new({name='AXE_LeMolay-patrol-SainteCroix', mission='patrol', targetzone='Sainte-Croix'}),
	--GroupCommander:new({name='AXE_LeMolay-patrol-SaintPierre', mission='patrol', targetzone='Saint-Pierre'}),
	GroupCommander:new({name='AXE_LeMolay-patrol-Caen', mission='patrol', targetzone='Caen'}),
})

zones.Orly:addGroups({
    GroupCommander:new({name='AXE_Orly-resupply-LeHavre', mission='supply', targetzone='Le Havre', type = 'surface'}),
	GroupCommander:new({name='AXE_Orly-resupply-Caen', mission='supply', targetzone='Caen', type = 'surface'}),
	GroupCommander:new({name='AXE_Orly-resupply-SaintAndre', mission='supply', targetzone='Saint-Andre', type = 'surface'}),
	GroupCommander:new({name='AXE_Orly-resupply-Amiens', mission='supply', targetzone='Amiens', type = 'surface'}),
	GroupCommander:new({name='AXE_Orly-resupply-Merville', mission='supply', targetzone='Merville', type = 'surface'}),
	GroupCommander:new({name='AXE_Orly-resupply-DunkirkPort', mission='supply', targetzone='Dunkirk-Port', type = 'surface'}),
	GroupCommander:new({name='AXE_Orly-resupply-Cherbourg', mission='supply', targetzone='Cherbourg', type = 'surface'}),	
})

zones.Paris:addGroups({
    --GroupCommander:new({name='AXE_Paris-resupply-Fecamp', mission='supply', targetzone='Fecamp', type = 'surface'}),
    --GroupCommander:new({name='AXE_Paris-resupply-SaintAubain', mission='supply', targetzone='Saint-Aubain', type = 'surface'}),
})
zones.SaintAubain:addGroups({
    GroupCommander:new({name='AXE_SaintAubain-patrol-Rouen', mission='patrol', targetzone='Rouen'}),
	GroupCommander:new({name='AXE_SaintAubain-resupply-AxeCarrierGroup', mission='supply', targetzone='AxeCarrierGroup', type = 'surface'}),
})

zones.SainteCroix:addGroups({
    --GroupCommander:new({name='AXE_SainteCroix-resupply-Caen', mission='supply', targetzone='Caen', type = 'surface'}),
})
zones.SaintOmer:addGroups({
    --GroupCommander:new({name='AXE_SaintOmer-resupply-Merville', mission='supply', targetzone='Merville', type = 'surface'}),
})
zones.Valognes:addGroups({
    GroupCommander:new({name='AXE_Valognes-resupply-Brucheville', mission='supply', targetzone='Brucheville', type = 'surface'}),
    --GroupCommander:new({name='AXE_Valognes-resupply-LeMolay', mission='supply', targetzone='Le Molay', type = 'surface'}),
})
zones.BigginHill:addGroups({
    GroupCommander:new({name='UK_BigginHill-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
    GroupCommander:new({name='UK_BigginHill-resupply-Dover', mission='supply', targetzone='Dover', type = 'surface'}),
	GroupCommander:new({name='UK_BigginHill-resupply-Friston', mission='supply', targetzone='Friston', type = 'surface'}),
	GroupCommander:new({name='UK_BigginHill-resupply-Chalay', mission='supply', targetzone='Chalay', type = 'surface'}),
	GroupCommander:new({name='UK_BigginHill-resupply-Calais', mission='supply', targetzone='Calais', type = 'surface'}),
	GroupCommander:new({name='UK_BigginHill-attack-LeHavre', mission='attack', targetzone='Le Havre', type = 'air'}),
	--GroupCommander:new({name='UK_BigginHill-attack-LeHavre-escort', mission='escort', targetzone='Le Havre', type = 'air'}),
	GroupCommander:new({name='UK_BigginHill-attack-DunkirkPort', mission='attack', targetzone='Dunkirk-Port', type = 'air'}),
	--GroupCommander:new({name='UK_BigginHill-attack-DunkirkPort-escort', mission='escort', targetzone='Dunkirk-Port', type = 'air'}),
	GroupCommander:new({name='UK_BigginHill-patrol-Friston', mission='patrol', targetzone='Friston'}),
	
})
zones.Farnborough:addGroups({
    GroupCommander:new({name='UK_Farnborough-resupply-BigginHill', mission='supply', targetzone='BigginHill', type = 'surface'}),
    GroupCommander:new({name='UK_Farnborough-resupply-Odiham', mission='supply', targetzone='Odiham', type = 'surface'}),
	GroupCommander:new({name='UK_Farnborough-resupply-Ford', mission='supply', targetzone='Ford', type = 'surface', urgent = function() return zones.Ford.side == 0 end, ForceUrgent = true}),
    GroupCommander:new({name='UK_Farnborough-resupply-NeedsOarPoint', mission='supply', targetzone='Needs Oar Point', type = 'surface'}),
	GroupCommander:new({name='UK_Farnborough-attack-Caen', mission='attack', targetzone='Caen', type = 'air'}),
	--GroupCommander:new({name='UK_Farnborough-attack-Caen-escort', mission='escort', targetzone='Caen', type = 'air'}),
})

zones.Dover:addGroups({
	GroupCommander:new({name='UK_Dover-resupply-Hawkinge', mission='supply', targetzone='Hawkinge', type = 'surface'}),
	GroupCommander:new({name='UK_Dover-capture-AxeCarrierGroup', mission='supply', targetzone='AxeCarrierGroup', type='surface', condition = function() return zones.Dover.active end, urgent = function() return zones.AxeCarrierGroup.side == 0 end, ForceUrgent = true}),
	GroupCommander:new({name='UK_Dover-capture-DunkirkPort', mission='supply', targetzone='Dunkirk-Port', type='surface', condition = function() return zones.Dover.active end, urgent = function() return zones.DunkirkPort.side == 0 end, ForceUrgent = true}),
    GroupCommander:new({name='UK_Dover-capture-Calais', mission='supply', targetzone='Calais', type = 'surface', condition = function() return zones.Dover.active end, urgent = function() return zones.Calais.side == 0 end, ForceUrgent = true}),
	GroupCommander:new({name='UK_Dover-supply-CarrierGroup', mission='supply', targetzone='CarrierGroup', type='surface'}),

})

zones.Hawkinge:addGroups({
	GroupCommander:new({name='UK_Hawkinge-resupply-Lympne', mission='supply', targetzone='Lympne', type = 'surface'}),
	--GroupCommander:new({name='UK_Hawkinge-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})

zones.Ford:addGroups({
	GroupCommander:new({name='UK_Ford-resupply-Tangmere', mission='supply', targetzone='Tangmere', type = 'surface'}),
	--GroupCommander:new({name='UK_Ford-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})
zones.Funtington:addGroups({
	GroupCommander:new({name='UK_Funtington-attack-Cherbourg', mission='attack', targetzone='Cherbourg'}),
	--GroupCommander:new({name='UK_Funtington-attack-Cherbourg-escort', mission='escort', targetzone='Cherbourg'}),
	--GroupCommander:new({name='UK_Ford-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})
zones.Tangmere:addGroups({
	GroupCommander:new({name='UK_Tangmere-resupply-Funtington', mission='supply', targetzone='Funtington', type = 'surface'}),
	--GroupCommander:new({name='UK_Ford-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})
zones.Chailey:addGroups({
	GroupCommander:new({name='UK_Chailey-resupply-Friston', mission='supply', targetzone='Friston', type = 'surface'}),
	GroupCommander:new({name='UK_Chailey-patrol-Friston', mission='patrol', targetzone='Friston'}),
	
})
zones.London:addGroups({
    GroupCommander:new({name='UK_London-resupply-BigginHill', mission='supply', targetzone='BigginHill', type = 'surface'}),
    --GroupCommander:new({name='UK_London-resupply-Farnborough', mission='supply', targetzone='Farnborough', type = 'surface'}),
    --GroupCommander:new({name='UK_London-resupply-Ford', mission='supply', targetzone='Ford', type = 'surface'}),
    --GroupCommander:new({name='UK_London-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})
zones.Manston:addGroups({
	GroupCommander:new({name='UK_Manston-patrol-Dover', mission='patrol', targetzone='Dover'}),
    GroupCommander:new({name='UK_Manston-resupply-DunkirkPort', mission='supply', targetzone='Dunkirk-Port', type = 'surface'}),
	--GroupCommander:new({name='UK_Manston-resupply-Hawkinge', mission='supply', targetzone='Hawkinge', type = 'surface'}),
	--GroupCommander:new({name='UK_Manston-resupply-Lympne', mission='supply', targetzone='Lympne', type = 'surface'}),
})	
zones.NeedsOarPoint:addGroups({
	--GroupCommander:new({name='UK_NeedsOarPoint-resupply-Farnborough', mission='supply', targetzone='Farnborough', type = 'surface'}),
	GroupCommander:new({name='UK_NeedsOarPoint-patrol-Ford', mission='patrol', targetzone='Ford'}),
	
})
zones.Odiham:addGroups({
	GroupCommander:new({name='UK_Odiham-resupply-Cherbourg', mission='supply', targetzone='Cherbourg', type = 'surface'}),
	GroupCommander:new({name='UK_Odiham-resupply-Caen', mission='supply', targetzone='Caen', type = 'surface'}),
	--GroupCommander:new({name='UK_Odiham-resupply-BigginHill', mission='supply', targetzone='BigginHill', type = 'surface'}),
})
-- Add defined Groups in Mission Editor to your Zones in ZoneCommander

zones.V1_Brecourt:addCriticalObject('Fueltank-Brecourt')
zones.V1_Herbouville:addCriticalObject('Fueltank-Herbouville')
zones.V1_Val_Ygot:addCriticalObject('Fueltank-ValYgot')
zones.V1_Crecy_Forest:addCriticalObject('Fueltank-CrecyForest')
zones.V1_Flixecourt:addCriticalObject('Fueltank-Flixecourt')
zones.V1_Wallon_Cappel:addCriticalObject('Fueltank-WallonCappel')
zones.V1_Neuville:addCriticalObject('Fueltank-Neuville')


-- Add all zones to BattleCommander


for i,v in pairs(zones) do
	bc:addZone(v)
end

-- Initialize railway subzone synchronization
synchronizeRailwaySubzones()
registerRailwaySubzoneTriggers()

-- Add connections between zones to give players an overview of the tactical advancement options and supply routes
--[[ Old connections - commented out for clarity
bc:addConnection("BigginHill","Farnborough")
bc:addConnection("BigginHill","Needs Oar Point")
bc:addConnection("BigginHill","Manston")
bc:addConnection("BigginHill","Chailey")
bc:addConnection("Farnborough","Odiham")
bc:addConnection("Farnborough","Tangmere")
bc:addConnection("Farnborough","Funtington")
bc:addConnection("Farnborough","Ford")
bc:addConnection("Odiham","Needs Oar Point")
bc:addConnection("Manston","Hawkinge")
bc:addConnection("Manston","Lympne")
bc:addConnection("Hawkinge","Lympne")
bc:addConnection("Chailey","Ford")
bc:addConnection("Chailey","Friston")
bc:addConnection("Chailey","Funtington")
bc:addConnection("Chailey","Tangmere")
bc:addConnection("Ford","Tangmere")
bc:addConnection("Ford","Fecamp")
bc:addConnection("Tangmere","Funtington")
bc:addConnection("Needs Oar Point","Cherbourg")
bc:addConnection("Friston","Saint-Aubain")
bc:addConnection("Manston","Dunkirk-Port")
bc:addConnection("Manston","Dover")
bc:addConnection("Dunkirk-Port","Dunkirk")
bc:addConnection("Dunkirk-Port","Calais")
bc:addConnection("Saint-Omer","Dunkirk-Port")
bc:addConnection("Saint-Omer","Dunkirk")
bc:addConnection("Saint-Omer","Calais")
bc:addConnection("Saint-Omer","Cap Gris-Nez")
bc:addConnection("Merville","Saint-Omer")
bc:addConnection("Abbeville","Le Touquet")
bc:addConnection("Amiens","Abbeville")
bc:addConnection("Amiens","Merville")
bc:addConnection("Amiens","Saint-Aubain")
bc:addConnection("Rouen","Saint-Aubain")
bc:addConnection("Rouen","Fecamp")
bc:addConnection("Le Havre","Fecamp")
bc:addConnection("Le Havre","Cherbourg")
bc:addConnection("Saint-Andre","Rouen")
bc:addConnection("Saint-Andre","Bernay")
bc:addConnection("Bernay","Caen")
bc:addConnection("Bernay","Le Havre")
bc:addConnection("Caen","Carpiquet")
--bc:addConnection("Sainte-Croix","Longues-Sur-Mer")
--bc:addConnection("Longues-Sur-Mer","Saint-Pierre")
bc:addConnection("Saint-Pierre","Cricqueville")
bc:addConnection("Saint-Pierre","Pointe du Hoc")
bc:addConnection("Carpiquet","Le Molay")
bc:addConnection("Carpiquet","Sainte-Croix")
bc:addConnection("Le Molay","Sainte-Croix")
bc:addConnection("Le Molay","Longues-Sur-Mer")
bc:addConnection("Le Molay","Saint-Pierre")
bc:addConnection("Le Molay","Brucheville")
bc:addConnection("Brucheville","Valognes")
bc:addConnection("Valognes","Cherbourg")
bc:addConnection("Cherbourg","Maupertus")
bc:addConnection("Cherbourg","Pointe des Groins")
bc:addConnection("Orly","Le Havre")
bc:addConnection("Orly","Caen")
bc:addConnection("Orly","Saint-Andre")
bc:addConnection("Orly","Amiens")
bc:addConnection("Orly","Merville")
bc:addConnection("Orly","Dunkirk-Port")
bc:addConnection("Orly","Cherbourg")
--]]
-----------BLUE SUPPLY CHAIN ----------------
bc:addConnectionSupply("BigginHill","Manston")
bc:addConnectionSupply("BigginHill","Friston")
bc:addConnectionSupply("BigginHill","Chailey")
bc:addConnectionSupply("BigginHill","Dover")
bc:addConnectionSupply("Farnborough","Needs Oar Point")
bc:addConnectionSupply("Farnborough","Ford")
bc:addConnectionSupply("Farnborough","BigginHill")
bc:addConnectionSupply("Farnborough","Odiham")
bc:addConnectionSupply("London","Manston","train")
bc:addConnectionSupply("London","Farnborough","train")
bc:addConnectionSupply("London","Chailey","train")
bc:addConnectionSupply("London","Ford","train")
bc:addConnectionSupply("London","Hawkinge","train")
--bc:addConnectionSupply("London","BigginHill","train")
bc:addConnectionSupply("Manston","Dover")
bc:addConnectionSupply("Dover","Hawkinge")
bc:addConnectionSupply("Hawkinge","Lympne")
bc:addConnectionSupply("Ford","Tangmere")
bc:addConnectionSupply("Tangmere","Funtington")
bc:addConnectionSupply("Chailey","Friston")


-----------RED SUPPLY CHAIN ----------------
bc:addConnectionSupply("Orly","Dunkirk-Port")
bc:addConnectionSupply("Orly","Le Havre")
bc:addConnectionSupply("Orly","Cherbourg")
bc:addConnectionSupply("Orly","Amiens")
bc:addConnectionSupply("Orly","Merville")
bc:addConnectionSupply("Orly","Saint-Andre")
bc:addConnectionSupply("Cherbourg","Valognes","train")
bc:addConnectionSupply("Cherbourg","Maupertus")
bc:addConnectionSupply("Valognes","Le Molay","train")
bc:addConnectionSupply("Valognes","Brucheville")
bc:addConnectionSupply("Le Molay","Caen","train")
bc:addConnectionSupply("Le Molay","Cricqueville")
bc:addConnectionSupply("Le Molay","Saint-Pierre")
bc:addConnectionSupply("Le Molay","Longues-Sur-Mer")
bc:addConnectionSupply("Caen","Sainte-Croix")
bc:addConnectionSupply("Bernay","Caen","train")
bc:addConnectionSupply("Caen","Carpiquet")
bc:addConnectionSupply("Dunkirk-Port","Saint-Omer")
bc:addConnectionSupply("Dunkirk-Port","Calais","train")
bc:addConnectionSupply("Dunkirk-Port","Dunkirk")
bc:addConnectionSupply("Dunkirk","Le Havre")
bc:addConnectionSupply("Merville","Saint-Omer")
bc:addConnectionSupply("Amiens","Abbeville","train")
bc:addConnectionSupply("Abbeville","Le Touquet","train")
bc:addConnectionSupply("Le Havre","Rouen","train")
bc:addConnectionSupply("Le Havre","Fecamp","train")
bc:addConnectionSupply("Paris","Orly","train")
bc:addConnectionSupply("Paris","Saint-Aubain","train")
bc:addConnectionSupply("Paris","Fecamp","train")
bc:addConnectionSupply("Paris","Saint-Andre","train")
bc:addConnectionSupply("Saint-Andre","Bernay","train")





zones.PointeDesGroins:registerTrigger('lost', function(event, sender) 
	sender:disableZone()
	bc:addFunds(2,1000)
	trigger.action.outTextForCoalition(2,'Radar at Pointe Des Groins Cleared\n+1000 credits',20)
end, 'disablePointeDesGroins')
zones.PointeDuHoc:registerTrigger('lost', function(event, sender) 
	sender:disableZone()
	bc:addFunds(2,1000)
	trigger.action.outTextForCoalition(2,'Radar at Pointe Du Hoc Cleared\n+1000 credits',20)
end, 'disablePointeDuHoc')
zones.CapGrisNez:registerTrigger('lost', function(event, sender) 
	sender:disableZone()
	bc:addFunds(2,1000)
	trigger.action.outTextForCoalition(2,'Radar at Cap Gris Nez Cleared\n+1000 credits',20)
end, 'disableCapGrisNez')
--[[
zones.AxeCarrierGroup:registerTrigger('lost', function(event, sender) 
	sender:disableZone()
	bc:addFunds(1,5000)
	trigger.action.outTextForCoalition(1,'Enemy Carrier Group Destroyed\n+5000 credits',20)
end, 'disableAxeCarrierGroup')
--]]
zones.V1_Brecourt:registerTrigger('destroyed', function(event, sender) 
    env.info("V1_Brecourt destroyed trigger activated")
	fUnitCoord("V1 Launch Site - Brecourt")
    sender:disableZone()
    bc:addFunds(2, 500)
    trigger.action.outTextForCoalition(2, 'V1 Launch Site at Brecourt Destroyed\n+500 credits', 20)
    --env.info("Trigger execution completed")
end, 'disableV1Brecourt')
zones.V1_Herbouville:registerTrigger('destroyed', function(event, sender) 
	env.info("V1_Herbouville destroyed trigger activated")
	fUnitCoord("V1 Launch Site - Herbouville")
	sender:disableZone()
	bc:addFunds(2, 500)
	trigger.action.outTextForCoalition(2, 'V1 Launch Site at Herbouville Destroyed\n+500 credits', 20)
	--env.info("Trigger execution completed")
end, 'disableV1Herbouville')
zones.V1_Val_Ygot:registerTrigger('destroyed', function(event, sender) 
	env.info("V1_Val_Ygot destroyed trigger activated")
	fUnitCoord("V1 Launch Site - Val Ygot")
	sender:disableZone()
	bc:addFunds(2, 500)
	trigger.action.outTextForCoalition(2, 'V1 Launch Site at Val Ygot Destroyed\n+500 credits', 20)
	--env.info("Trigger execution completed")
end, 'disableV1ValYgot')
zones.V1_Crecy_Forest:registerTrigger('destroyed', function(event, sender) 
	env.info("V1_Crecy_Forest destroyed trigger activated")
	fUnitCoord("V1 Launch Site - Crecy Forest")
	sender:disableZone()
	bc:addFunds(2, 500)
	trigger.action.outTextForCoalition(2, 'V1 Launch Site at Crecy Forest Destroyed\n+500 credits', 20)
	--env.info("Trigger execution completed")
end, 'disableV1CrecyForest')
zones.V1_Flixecourt:registerTrigger('destroyed', function(event, sender) 
	env.info("V1_Flixecourt destroyed trigger activated")
	fUnitCoord("V1 Launch Site - Flixecourt")
	sender:disableZone()
	bc:addFunds(2, 500)
	trigger.action.outTextForCoalition(2, 'V1 Launch Site at Flixecourt Destroyed\n+500 credits', 20)
	--env.info("Trigger execution completed")
end, 'disableV1Flixecourt')
zones.V1_Wallon_Cappel:registerTrigger('destroyed', function(event, sender) 
	env.info("V1_Wallon_Cappel destroyed trigger activated")
	fUnitCoord("V1 Launch Site - Wallon Cappel")
	sender:disableZone()
	bc:addFunds(2, 500)
	trigger.action.outTextForCoalition(2, 'V1 Launch Site at Wallon Cappel Destroyed\n+500 credits', 20)
	--env.info("Trigger execution completed")
end, 'disableV1WallonCappel')
zones.V1_Neuville:registerTrigger('destroyed', function(event, sender) 
	env.info("V1_Neuville destroyed trigger activated")
	fUnitCoord("V1 Launch Site - Neuville")
	sender:disableZone()
	bc:addFunds(2, 500)
	trigger.action.outTextForCoalition(2, 'V1 Launch Site at Neuville Destroyed\n+500 credits', 20)
	--env.info("Trigger execution completed")
end, 'disableV1Neuville')






function SpawnFriendlyAssets()
	if zones.Dover.active and zones.AxeCarrierGroup.side == 0 then
		trigger.action.outText("Our ships are standing to capture red carrier zone ", 15)
		trigger.action.outSoundForCoalition(2, "admin.ogg")
	end

end

timer.scheduleFunction(SpawnFriendlyAssets,{},timer.getTime()+10)


zones.BigginHill.airbaseName = "Biggin Hill"
zones.Odiham.airbaseName = "Odiham"
zones.Farnborough.airbaseName = "Farnborough"
zones.Manston.airbaseName = "Manston"
zones.Hawkinge.airbaseName = "Hawkinge"
zones.Lympne.airbaseName = "Lympne"
zones.Chailey.airbaseName = "Chailey"
zones.Ford.airbaseName = "Ford"
zones.Tangmere.airbaseName = "Tangmere"
zones.Funtington.airbaseName = "Funtington"
zones.NeedsOarPoint.airbaseName = "Needs Oar Point"
zones.Friston.airbaseName = "Friston"
zones.Dunkirk.airbaseName = "Dunkirk-Mardyck"
--zones.DunkirkPort.airbaseName = nil
zones.SaintOmer.airbaseName = "Saint-Omer Wizernes"
zones.Merville.airbaseName = "Merville Calonne"
zones.Abbeville.airbaseName = "Abbeville Drucat"
zones.Amiens.airbaseName = "Amiens-Glisy"
--zones.Cherbourg.airbaseName = nil
--zones.Calais.airbaseName = nil
zones.SaintAubain.airbaseName = "Saint-Aubin"
zones.Fecamp.airbaseName = "Fecamp-Benouville"
--zones.LeHavre.airbaseName = nil
zones.Rouen.airbaseName = "Rouen-Boos"
zones.Carpiquet.airbaseName = "Carpiquet"
--zones.Caen.airbaseName = nil
zones.SainteCroix.airbaseName = "Sainte-Croix-sur-Mer"
zones.SaintPierre.airbaseName = "Saint Pierre du Mont"
zones.LonguesSurMer.airbaseName = "Longues-sur-Mer"
zones.Cricqueville.airbaseName = "Cricqueville-en-Bessin"
zones.LeMolay.airbaseName = "Le Molay"
zones.Brucheville.airbaseName = "Brucheville"
--zones.Valognes.airbaseName = nil
zones.Maupertus.airbaseName = "Maupertus"
zones.Bernay.airbaseName = "Bernay Saint Martin"
zones.SaintAndre.airbaseName = "Saint-Andre-de-lEure"
zones.Orly.airbaseName = "Orly"

local showCredIncrease = function(event, sender)
	trigger.action.outTextForCoalition(sender.side, '+'..math.floor(sender.income*360)..' Credits/Hour', 5)
end


-- Start of original script----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------

local missionCompleted = false
local checkMissionComplete = function(event, sender)
	if missionCompleted then return end
	local done = true
	for i, v in ipairs(bc:getZones()) do
		if not v.zone:lower():find("hidden") and v.side == 1 then
			done = false
			break
		end
	end

	if done then
		missionCompleted = true
		trigger.action.setUserFlag(180, true)
		trigger.action.outText("Enemy has been defeated.\n\nMission Complete.\n\nYou can restart the mission from the radio menu.", 120)

		timer.scheduleFunction(function()
			trigger.action.outSoundForCoalition(2, "BH.ogg")
		end, {}, timer.getTime() + 5)

			local subMenu = missionCommands.addSubMenuForCoalition(2, "Restart and Reset?", nil)
			missionCommands.addCommandForCoalition(2, "Yes", subMenu, function()
					Utils.saveTable(bc.saveFile, 'zonePersistance', {})
					if resetSaveFileAndFarp then
					resetSaveFileAndFarp()
					end
				trigger.action.outText("Restarting now..", 120)
				timer.scheduleFunction(function()
					trigger.action.setUserFlag(181, true)
				end, {}, timer.getTime() + 5)
			end)
			missionCommands.addCommandForCoalition(2, "No", subMenu, function()
		end)
	end
end

for i,v in ipairs(bc:getZones()) do
	v:registerTrigger('lost', checkMissionComplete, 'missioncompleted')
end


-------------------------------------------------------------------------------------------------------------------------------
local upgradeMenu = nil
bc:registerShopItem('supplies2', 'Resupply friendly Zone', 200, function(sender)
    if upgradeMenu then
        return 'Choose zone from F10 menu'
    end

    local upgradeZone = function(target)
        if upgradeMenu then
            local zn = bc:getZoneByName(target)
            if zn and zn.side == 2 then
                zn:upgrade()
            else
                return 'Zone not friendly'
            end
            
            upgradeMenu = nil
        end
    end
    upgradeMenu = bc:showTargetZoneMenu(2, 'Select Zone to resupply', upgradeZone, 2, true)
    
    trigger.action.outTextForCoalition(2, 'Supplies prepared. Choose zone from F10 menu', 15)
end,
function(sender, params)
    if params.zone and params.zone.side == 2 then
        params.zone:upgrade()
    else
        return 'Can only target friendly zone'
    end
end)
local fullyUpgradeMenu=nil
bc:registerShopItem('supplies','Fully Upgrade Friendly Zone',1000,
function(sender)
    if fullyUpgradeMenu then
        return'Choose zone from F10 menu to fully upgrade'
    end
    local fullyUpgradeZone
    fullyUpgradeZone=function(target)
        if fullyUpgradeMenu then
            local zn=bc:getZoneByName(target)
            if zn and zn.side==2 then
                local function repairs()
                    local n=0
                    for _,v in pairs(zn.built)do
                        local g=Group.getByName(v)
                        if g then
                            if g:getSize()<g:getInitialSize() then n=n+1
                            else
                                for _,u in ipairs(g:getUnits())do
                                    if u and u:isExist() and u:getLife()<u:getLife0() then n=n+1 break end
                                end
                            end
                        end
                    end
                    return n
                end
                local upgs=zn.upgrades.blue or{}
                local todo=repairs()+(#upgs-Utils.getTableSize(zn.built))
                if todo>0 then
                    local function loop()
                        local before=Utils.getTableSize(zn.built)
                        zn:upgrade()
                        local now=Utils.getTableSize(zn.built)
                        if repairs()>0 or now<#upgs then
                            timer.scheduleFunction(loop,{},timer.getTime()+2)
                        else
                            trigger.action.outTextForCoalition(2,target..' is now fully upgraded!',15)
                        end
                    end
                    loop()
                else
                    trigger.action.outTextForCoalition(2,target..' is already fully upgraded',15)
                end
            else
                return'Zone not friendly'
            end
            fullyUpgradeMenu=nil
        end
    end
    fullyUpgradeMenu=bc:showTargetZoneMenu(2,'Select Zone to Fully Upgrade',fullyUpgradeZone,2,true)
    trigger.action.outTextForCoalition(2,'Preparing to full upgrade and repair. Choose zone from F10 menu',15)
end,
function(sender,params)
    if params.zone and params.zone.side==2 then
        local zn=params.zone
        local upgs=zn.upgrades.blue or{}
        local function repairs()
            local n=0
            for _,v in pairs(zn.built)do
                local g=Group.getByName(v)
                if g then
                    if g:getSize()<g:getInitialSize() then n=n+1
                    else
                        for _,u in ipairs(g:getUnits())do
                            if u and u:isExist() and u:getLife()<u:getLife0() then n=n+1 break end
                        end
                    end
                end
            end
            return n
        end
        local function loop()
            local before=Utils.getTableSize(zn.built)
            zn:upgrade()
            local now=Utils.getTableSize(zn.built)
            if repairs()>0 or now<#upgs then
                timer.scheduleFunction(loop,{},timer.getTime()+2)
			else
				trigger.action.outTextForCoalition(2,params.zone.zone..' is now fully upgraded!',15)
			end
        end
        loop()
    else
        return'Can only target friendly zone'
    end
end)

-- new menu
local supplyMenu=nil
bc:registerShopItem('capture','Emergency capture neutral zone',500,
function(sender)
	if supplyMenu then
		return 'Choose a zone from F10 menu'
	end
    local cost=500
    trigger.action.outTextForCoalition(2,'Select zone from F10 menu',15)
    supplyMenu=bc:showEmergencyNeutralZoneMenu(2,'Select Zone for Emergency capture',
    function(zonename)
        if not zonename then
            bc:addFunds(2,cost)
            if supplyMenu then missionCommands.removeItemForCoalition(2,supplyMenu) end
            supplyMenu=nil
            trigger.action.outTextForCoalition(2,'No zone name selected, purchase refunded',10)
            return 'No zone name'
        end
        local chosenZone=bc:getZoneByName(zonename)
        if not chosenZone then
            bc:addFunds(2,cost)
            if supplyMenu then missionCommands.removeItemForCoalition(2,supplyMenu) end
            supplyMenu=nil
            trigger.action.outTextForCoalition(2,'Zone not found, purchase refunded',10)
            return 'Zone not found'
        end
        if chosenZone.side~=0 then
            bc:addFunds(2,cost)
            if supplyMenu then missionCommands.removeItemForCoalition(2,supplyMenu) end
            supplyMenu=nil
            trigger.action.outTextForCoalition(2,'Zone is not neutral anymore, purchase refunded',10)
            return 'Zone is no longer neutral!'
        end
        local bestCommander,status=findNearestAvailableSupplyCommander(chosenZone)
        if not bestCommander then
            bc:addFunds(2,cost)
            if supplyMenu then missionCommands.removeItemForCoalition(2,supplyMenu) end
            supplyMenu=nil
            if status=='inprogress' then
                trigger.action.outTextForCoalition(2,'Supply to '..chosenZone.zone..' already in progress, purchase refunded',10)
                return 'Supply mission in progress for this zone'
            else
                trigger.action.outTextForCoalition(2,'No suitable supply group found for '..chosenZone.zone..', purchase refunded',10)
                return 'No available supply convoys'
            end
        end
        bestCommander.targetzone=zonename
        bestCommander.state='preparing'
        bestCommander.urgent=true
        bestCommander.lastStateTime=timer.getAbsTime()-999999
        trigger.action.outTextForCoalition(2,'Emergency Capture from '..bestCommander.name..' heading to '..zonename,10)
        if supplyMenu then
            missionCommands.removeItemForCoalition(2,supplyMenu)
            supplyMenu=nil
        end
        return nil
    end)
    return nil
end,
function(sender,params)
    if not params.zone or params.zone.side~=0 then
        return 'Zone is not neutral'
    end
    local chosenZone=bc:getZoneByName(params.zone.zone)
    local bestCommander,status=findNearestAvailableSupplyCommander(chosenZone)
    if not bestCommander then
        if status=='inprogress' then
            return 'Supply mission in progress for this zone'
        else
            return 'No available supply convoys'
        end
    end
    bestCommander.targetzone=params.zone.zone
    bestCommander.state='preparing'
    bestCommander.urgent=true
    bestCommander.lastStateTime=timer.getAbsTime()-999999
    trigger.action.outTextForCoalition(2,'Emergency Capture from '..bestCommander.name..' heading to '..params.zone.zone,10)
    return nil
end)
-------------------------------------------------------------------------------------------------------------------------------
local smoketargets = function(tz)
	if not tz or not tz.built then return end
	local units = {}
	for i,v in pairs(tz.built) do
		local g = Group.getByName(v)
		if g and g:isExist() then
			local gUnits = g:getUnits()
			if gUnits then
				for i2,v2 in ipairs(gUnits) do
					table.insert(units,v2)
				end
			end
		end
	end
	local tgts = {}
	for i=1,3,1 do
		if #units > 0 then
			local selected = math.random(1,#units)
			table.insert(tgts,units[selected])
			table.remove(units,selected)
		end
	end
	for i,v in ipairs(tgts) do
		if v and v:isExist() then
			local pos = v:getPosition().p
			trigger.action.smoke(pos,1)
		end
	end
end

local smokeTargetMenu = nil
bc:registerShopItem('smoke', 'Smoke markers', 20, function(sender)
	if smokeTargetMenu then
		return 'Choose target zone from F10 menu'
	end
	
	local launchAttack = function(target)
		if smokeTargetMenu then
			local tz = bc:getZoneByName(target)
			smoketargets(tz)
			smokeTargetMenu = nil
			trigger.action.outTextForCoalition(2, 'Targets marked with RED smoke at '..target, 15)
		end
	end
	
	smokeTargetMenu = bc:showTargetZoneMenu(2, 'Smoke marker target', launchAttack, 1)
	
	trigger.action.outTextForCoalition(2, 'Choose target zone from F10 menu', 15)
end,
function(sender, params)
	if params.zone and params.zone.side == 1 then
		smoketargets(params.zone)
		trigger.action.outTextForCoalition(2, 'Targets marked with RED smoke at '..params.zone.zone, 15)
	else
		return 'Can only target enemy zone'
	end
end)
-------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------DYNAMIC SHOP ------------------------------------------


bc:registerShopItem('dynamiccap', 'Dynamic CAP', 250, function(sender)
    if capActive then
        return 'CAP mission still in progress'
    end
    buildCapMenu()
	
	MESSAGE:New("CAP is requested. Select spawn zone.", 10):ToAll()
end,
function (sender, params)
    if capActive then
        return 'CAP mission still in progress'
    end
    buildCapMenu()

	MESSAGE:New("CAP is requested. Select spawn zone.", 10):ToAll()
end)


bc:registerShopItem('dynamiccas', 'Dynamic CAS', 250,
function(sender)
    if casActive then
        return 'CAS mission still in progress'
    end
    CASTargetMenu = bc:showTargetZoneMenu(2, 'Select CAS Target', function(targetZoneName, menu)
        local spawnZone = findClosestBlueZoneOutside(targetZoneName, 25)
        if not spawnZone then
            trigger.action.outTextForCoalition(2, 'No friendly zone available for CAS spawn 20+ NM away.', 15)
            return
        end
        spawnCasAt(spawnZone, targetZoneName)
        CASTargetMenu = nil
    end, 1)
    return 'Select CAS target zone from F10'
end,
function(sender, params)
    if not params.zone or params.zone.side ~= 1 then
        return 'Can only target enemy zone'
    end
    if casActive then
        return 'CAS mission still in progress'
    end
    local closestBlue = findClosestBlueZoneOutside(params.zone.zone, 25)
    if not closestBlue then
        return 'No friendly zone available for CAS spawn.'
    end
    spawnCasAt(closestBlue, params.zone.zone)
    return true
end)

---------------------------------------------END DYNAMIC SHOP ------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
bc:addShopItem(2, 'sweep', -1)
bc:addShopItem(2, 'antiship', -1)
bc:addShopItem(2, 'sead', -1)
bc:addShopItem(2, 'cas', -1)
--bc:addShopItem(2, 'cruisemsl', 12)
bc:addShopItem(2, 'supplies', -1)
bc:addShopItem(2, 'supplies2', -1)
--bc:addShopItem(2, 'jtac', -1)
bc:addShopItem(2, 'smoke', -1)
--bc:addShopItem(2, 'jam', -1)
--bc:addShopItem(2, 'awacs', -1)

--bc:addShopItem(2, 'armor', -1)
--bc:addShopItem(2, 'artillery', -1)
--bc:addShopItem(2, 'recon', -1)
--bc:addShopItem(2, 'airdef', -1)
--bc:addShopItem(2, 'antiship', -1)
--bc:addShopItem(2, 'dynamicdecoy', -1)
bc:addShopItem(2, 'dynamiccas', -1)
bc:addShopItem(2, 'dynamiccap', -1)
bc:addShopItem(2, 'capture', -1)

-------------------------------------------------------------------------------------------------------------------------------
--red support------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------

local upgradeMenuRed = nil
bc:registerShopItem('suppliesRed2', 'Resupply friendly Red Zone', 200, function(sender)
    if upgradeMenuRed then
        return 'Choose zone from F10 menu'
    end

    local upgradeZone = function(target)
        if upgradeMenuRed then
            local zn = bc:getZoneByName(target)
            if zn and zn.side == 2 then
                zn:upgrade()
            else
                return 'Zone not friendly'
            end
            
            upgradeMenuRed = nil
        end
    end
    upgradeMenuRed = bc:showTargetZoneMenu(1, 'Select Zone to resupply', upgradeZone, 2, true)
    
    trigger.action.outTextForCoalition(1, 'suppliesRed prepared. Choose zone from F10 menu', 15)
end,
function(sender, params)
    if params.zone and params.zone.side == 2 then
        params.zone:upgrade()
    else
        return 'Can only target friendly Red Zone'
    end
end)
local fullyupgradeMenuRed=nil
bc:registerShopItem('suppliesRed','Fully Upgrade friendly Red Zone',1000,
function(sender)
    if fullyupgradeMenuRed then
        return'Choose zone from F10 menu to fully upgrade'
    end
    local fullyUpgradeZone
    fullyUpgradeZone=function(target)
        if fullyupgradeMenuRed then
            local zn=bc:getZoneByName(target)
            if zn and zn.side==2 then
                local function repairs()
                    local n=0
                    for _,v in pairs(zn.built)do
                        local g=Group.getByName(v)
                        if g then
                            if g:getSize()<g:getInitialSize() then n=n+1
                            else
                                for _,u in ipairs(g:getUnits())do
                                    if u and u:isExist() and u:getLife()<u:getLife0() then n=n+1 break end
                                end
                            end
                        end
                    end
                    return n
                end
                local upgs=zn.upgrades.blue or{}
                local todo=repairs()+(#upgs-Utils.getTableSize(zn.built))
                if todo>0 then
                    local function loop()
                        local before=Utils.getTableSize(zn.built)
                        zn:upgrade()
                        local now=Utils.getTableSize(zn.built)
                        if repairs()>0 or now<#upgs then
                            timer.scheduleFunction(loop,{},timer.getTime()+2)
                        else
                            trigger.action.outTextForCoalition(1,target..' is now fully upgraded!',15)
                        end
                    end
                    loop()
                else
                    trigger.action.outTextForCoalition(1,target..' is already fully upgraded',15)
                end
            else
                return'Zone not friendly'
            end
            fullyupgradeMenuRed=nil
        end
    end
    fullyupgradeMenuRed=bc:showTargetZoneMenu(1,'Select Zone to Fully Upgrade',fullyUpgradeZone,2,true)
    trigger.action.outTextForCoalition(1,'Preparing to full upgrade and repair. Choose zone from F10 menu',15)
end,
function(sender,params)
    if params.zone and params.zone.side==2 then
        local zn=params.zone
        local upgs=zn.upgrades.blue or{}
        local function repairs()
            local n=0
            for _,v in pairs(zn.built)do
                local g=Group.getByName(v)
                if g then
                    if g:getSize()<g:getInitialSize() then n=n+1
                    else
                        for _,u in ipairs(g:getUnits())do
                            if u and u:isExist() and u:getLife()<u:getLife0() then n=n+1 break end
                        end
                    end
                end
            end
            return n
        end
        local function loop()
            local before=Utils.getTableSize(zn.built)
            zn:upgrade()
            local now=Utils.getTableSize(zn.built)
            if repairs()>0 or now<#upgs then
                timer.scheduleFunction(loop,{},timer.getTime()+2)
			else
				trigger.action.outTextForCoalition(1,params.zone.zone..' is now fully upgraded!',15)
			end
        end
        loop()
    else
        return'Can only target friendly Red Zone'
    end
end)

-- new menu
local supplyMenuRed=nil
bc:registerShopItem('captureRed','Emergency capture Red neutral zone',500,
function(sender)
	if supplyMenuRed then
		return 'Choose a zone from F10 menu'
	end
    local cost=500
    trigger.action.outTextForCoalition(1,'Select zone from F10 menu',15)
    supplyMenuRed=bc:showEmergencyNeutralZoneMenu(1,'Select Zone for Emergency capture Red',
    function(zonename)
        if not zonename then
            bc:addFunds(1,cost)
            if supplyMenuRed then missionCommands.removeItemForCoalition(1,supplyMenuRed) end
            supplyMenuRed=nil
            trigger.action.outTextForCoalition(1,'No zone name selected, purchase refunded',10)
            return 'No zone name'
        end
        local chosenZone=bc:getZoneByName(zonename)
        if not chosenZone then
            bc:addFunds(1,cost)
            if supplyMenuRed then missionCommands.removeItemForCoalition(1,supplyMenuRed) end
            supplyMenuRed=nil
            trigger.action.outTextForCoalition(1,'Zone not found, purchase refunded',10)
            return 'Zone not found'
        end
        if chosenZone.side~=0 then
            bc:addFunds(1,cost)
            if supplyMenuRed then missionCommands.removeItemForCoalition(1,supplyMenuRed) end
            supplyMenuRed=nil
            trigger.action.outTextForCoalition(1,'Zone is not neutral anymore, purchase refunded',10)
            return 'Zone is no longer neutral!'
        end
        local bestCommander,status=findNearestAvailableSupplyCommander(chosenZone)
        if not bestCommander then
            bc:addFunds(1,cost)
            if supplyMenuRed then missionCommands.removeItemForCoalition(1,supplyMenuRed) end
            supplyMenuRed=nil
            if status=='inprogress' then
                trigger.action.outTextForCoalition(1,'Supply to '..chosenZone.zone..' already in progress, purchase refunded',10)
                return 'Supply mission in progress for this zone'
            else
                trigger.action.outTextForCoalition(1,'No suitable supply group found for '..chosenZone.zone..', purchase refunded',10)
                return 'No available supply convoys'
            end
        end
        bestCommander.targetzone=zonename
        bestCommander.state='preparing'
        bestCommander.urgent=true
        bestCommander.lastStateTime=timer.getAbsTime()-999999
        trigger.action.outTextForCoalition(1,'Emergency capture Red from '..bestCommander.name..' heading to '..zonename,10)
        if supplyMenuRed then
            missionCommands.removeItemForCoalition(1,supplyMenuRed)
            supplyMenuRed=nil
        end
        return nil
    end)
    return nil
end,
function(sender,params)
    if not params.zone or params.zone.side~=0 then
        return 'Zone is not neutral'
    end
    local chosenZone=bc:getZoneByName(params.zone.zone)
    local bestCommander,status=findNearestAvailableSupplyCommander(chosenZone)
    if not bestCommander then
        if status=='inprogress' then
            return 'Supply mission in progress for this zone'
        else
            return 'No available supply convoys'
        end
    end
    bestCommander.targetzone=params.zone.zone
    bestCommander.state='preparing'
    bestCommander.urgent=true
    bestCommander.lastStateTime=timer.getAbsTime()-999999
    trigger.action.outTextForCoalition(1,'Emergency capture Red from '..bestCommander.name..' heading to '..params.zone.zone,10)
    return nil
end)

bc:addShopItem(1, 'suppliesRed', -1)
bc:addShopItem(1, 'suppliesRed2', -1)
bc:addShopItem(1, 'captureRed', -1)
budgetAI = BudgetCommander:new({ battleCommander = bc, side=1, decissionFrequency=20*60, decissionVariance=10*60, skipChance = 10})
budgetAI:init()
--end red support

supplyZones = {
    'BigginHill',
	'Odiham',
	'Farnborough',
	'Manston',
	'Hawkinge',
	'Lympne',
	'Chailey',
	'Ford',
	'Tangmere',
	'Funtington',
	'NeedsOarPoint',
	'Friston',
	'Dunkirk',
	'SaintOmer',
	'Merville',
	'Abbeville',
	'Amiens',
	'SaintAubain',
	'Fecamp',
	'Rouen',
	'Carpiquet',
	'SainteCroix',
	'SaintPierre',
	'LonguesSurMer',
	'Cricqueville',
	'LeMolay',
	'Brucheville',
	'Maupertus',
	'Bernay',
	'SaintAndre',
	'CarrierGroup',
	'AxeCarrierGroup',
	'DunkirkPort',
	'Calais',
	'Cherbourg',
	'Caen',
	'Valognes',
	'LeHavre',
	'Paris',
	'Orly',
	'London',
	'hiddenCarrierEssex',
}

lc = LogisticCommander:new({battleCommander = bc, supplyZones = supplyZones})
lc:init()

bc:loadFromDisk() -- will load and overwrite default zone levels, sides, funds, and available shop items
bc:init()
bc:startRewardPlayerContribution(15,{infantry = 10, ground = 10, sam = 30, structure=30, airplane = 30, ship = 250, helicopter=30, crate=200, rescue = 100})
mc = MissionCommander:new({side = 2, battleCommander = bc, checkFrequency = 60})
HercCargoDropSupply.init(bc)
bc:buildZoneDistanceCache()
buildSubZoneRoadCache()
bc:buildConnectionMap()
--evc = EventCommander:new({ decissionFrequency=1*60, decissionVariance=1*60, skipChance = 10})
evc = EventCommander:new({ 
    decissionFrequency = 15*60,
    decissionVariance = 5*60,
    skipChance = 10
})
evc:init()

----------------------------------------------- Bomber Red event ---------------------------------------------
local bomb_COOLDOWN = 2100
local lastbomb_COOLDOWN  = -bomb_COOLDOWN

-- Updated bomber event to use spawnBomberStrikerAt with dynamic zone selection
evc:addEvent({
id='bomb',
action=function()
  -- Spawn bombers from a red zone to attack a blue zone
  -- Select random red spawn zone and random blue target zone
  local redZones = {}
  local blueZones = {}
  
  for _, zone in ipairs(bc:getZones()) do
    if zone.side == 1 and zone.active and not zone.zone:lower():find("hidden") then
      table.insert(redZones, zone.zone)
    elseif zone.side == 2 and zone.active and not zone.zone:lower():find("hidden") then
      table.insert(blueZones, zone.zone)
    end
  end
  
  if #redZones > 0 and #blueZones > 0 then
    local spawnZone = redZones[math.random(#redZones)]
    local targetZone = blueZones[math.random(#blueZones)]
    
    -- Store zones for mission display
    bomberMissionSpawnZone = spawnZone
    bomberMissionTargetZone = targetZone
    
    spawnBomberStrikerAt(spawnZone, targetZone)
  end
end,
canExecute=function()
  if timer.getTime()-lastbomb_COOLDOWN < bomb_COOLDOWN then return false end
  if bomberActive then return false end
  
  -- Check if there are any blue zones to target
  for _, zone in ipairs(bc:getZones()) do
    if zone.side == 2 and zone.active and not zone.zone:lower():find("hidden") then
      return true
    end
  end
  return false
end
})

-- Track bomber mission spawn and target zones
bomberMissionSpawnZone = nil
bomberMissionTargetZone = nil

mc:trackMission({
title = "Intercept Bombers",
description = function()
    local desc = "Enemy bombers spotted!\nIntercept and destroy them before they reach their target."
    if bomberMissionSpawnZone and bomberMissionTargetZone then
        desc = desc .. "\n\nSpawn Zone: " .. bomberMissionSpawnZone
        desc = desc .. "\nTarget Zone: " .. bomberMissionTargetZone
    end
    return desc
end,
messageStart = function()
    local msg = "New mission: Intercept Bombers"
    if bomberMissionSpawnZone and bomberMissionTargetZone then
        msg = msg .. "\n\nEnemy bombers detected near " .. bomberMissionSpawnZone
        msg = msg .. "\nProbable Target: " .. bomberMissionTargetZone
    end
    return msg
end,
messageEnd=function() 
    lastbomb_COOLDOWN=timer.getTime()
    bomberMissionSpawnZone = nil
    bomberMissionTargetZone = nil
    return "Mission ended: Intercept Bombers" 
end,
startAction = function()
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "ding.ogg")
        end
    end,
    endAction = function()
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
isActive = function()
return bomberActive
end
})

-------------------------------------------- End of Bomber Red event ------------------------------------------

----------------------------------------------- Bomber Blue event ---------------------------------------------
local bombBlue_COOLDOWN = 1800
local lastbombBlue_COOLDOWN = -bombBlue_COOLDOWN

-- Blue bomber event to use spawnBlueBomberStrikerAt with dynamic zone selection
evc:addEvent({
id='bombBlue',
action=function()
  -- Spawn blue bombers from a blue zone to attack a red zone
  -- Select random blue spawn zone and random red target zone
  local blueZones = {}
  local redZones = {}
  
  for _, zone in ipairs(bc:getZones()) do
    if zone.side == 2 and zone.active and not zone.zone:lower():find("hidden") then
      table.insert(blueZones, zone.zone)
    elseif zone.side == 1 and zone.active and not zone.zone:lower():find("hidden") then
      table.insert(redZones, zone.zone)
    end
  end
  
  if #blueZones > 0 and #redZones > 0 then
    local spawnZone = blueZones[math.random(#blueZones)]
    local targetZone = redZones[math.random(#redZones)]
    
    -- Store zones for mission display
    bomberBlueMissionSpawnZone = spawnZone
    bomberBlueMissionTargetZone = targetZone
    
    spawnBlueBomberStrikerAt(spawnZone, targetZone)
  end
end,
canExecute=function()
  if timer.getTime()-lastbombBlue_COOLDOWN < bombBlue_COOLDOWN then return false end
  if bomberBlueActive then return false end
  
  -- Check if there are any red zones to target
  for _, zone in ipairs(bc:getZones()) do
    if zone.side == 1 and zone.active and not zone.zone:lower():find("hidden") then
      return true
    end
  end
  return false
end
})

-- Track blue bomber mission spawn and target zones
bomberBlueMissionSpawnZone = nil
bomberBlueMissionTargetZone = nil

mc:trackMission({
title = "Bomber Strike",
description = function()
    local desc = "Allied bombers launching strike mission!\nProvide escort and ensure mission success."
    if bomberBlueMissionSpawnZone and bomberBlueMissionTargetZone then
        desc = desc .. "\n\nSpawn Zone: " .. bomberBlueMissionSpawnZone
        desc = desc .. "\nTarget Zone: " .. bomberBlueMissionTargetZone
    end
    if redInterceptorActive then
        desc = desc .. "\n\nWARNING: Enemy interceptors scrambled!"
    end
    return desc
end,
messageStart = function()
    local msg = "New mission: Bomber Strike"
    if bomberBlueMissionSpawnZone and bomberBlueMissionTargetZone then
        msg = msg .. "\n\nAllied bombers launched from " .. bomberBlueMissionSpawnZone
        msg = msg .. "\nTarget: " .. bomberBlueMissionTargetZone
        msg = msg .. "\n\nWARNING: Expect enemy interceptors!"
    end
    return msg
end,
messageEnd=function() 
    lastbombBlue_COOLDOWN=timer.getTime()
    bomberBlueMissionSpawnZone = nil
    bomberBlueMissionTargetZone = nil
    return "Mission ended: Bomber Strike" 
end,
startAction = function()
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "ding.ogg")
        end
    end,
    endAction = function()
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
isActive = function()
return bomberBlueActive
end
})

-------------------------------------------- End of Bomber Blue event ------------------------------------------

----------------------------------------------- Navy Artillery event ---------------------------------------------
local navyArty_COOLDOWN = 2400
local lastNavyArty_COOLDOWN = -navyArty_COOLDOWN
-- Navy Artillery event
evc:addEvent({
id='navyArty',
action=function()
  -- Spawn Navy Artillery at CarrierGroup to target Saint-Pierre
  spawnNavyArtyAt("NavyStrike", "Saint-Pierre", "Carpiquet")
end,
canExecute=function()
  if timer.getTime()-lastNavyArty_COOLDOWN < navyArty_COOLDOWN then return false end
  if navyArtyActive then return false end
  local trg = {'Saint-Pierre'}
  for _,v in ipairs(trg) do
    if bc:getZoneByName(v).side == 1 then return true end
  end
  return false
end
})

mc:trackMission({
title = "Naval Artillery CAP",
description = "Allied Naval artillery Group on the way to French coast\nCover their advance from Strikers and Fighters.",
messageStart = "New mission: Cover Naval Artillery Group",
messageEnd=function() lastNavyArty_COOLDOWN=timer.getTime() return "Mission ended: Naval Artillery" end,
startAction = function()
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "ding.ogg")
        end
    end,
    endAction = function()
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
isActive = function()
return navyArtyActive
end
})

-------------------------------------------- End of Navy Artillery event ------------------------------------------
---
---------------------------------------------- V1 Artillery event ---------------------------------------------
local v1Arty_COOLDOWN = 1200
local lastV1Arty_COOLDOWN = -v1Arty_COOLDOWN

-- Helper function to check if ANY V1 site is active
local function isAnyV1Active()
    for siteName, isActive in pairs(v1ArtyActive) do
        if isActive then return true end
    end
    return false
end

-- V1 Artillery event - Now uses random site selection
evc:addEvent({
    id='v1Arty',
    action=function()
        -- Use the random V1 launcher function
        launchRandomV1Artillery()
    end,
    canExecute=function()
        if timer.getTime() - lastV1Arty_COOLDOWN < v1Arty_COOLDOWN then return false end
        if isAnyV1Active() then return false end
        
        -- Check if ANY target zones configured in V1_SITE_CONFIG are Blue
        for siteName, targetZones in pairs(V1_SITE_CONFIG) do
            for _, zoneName in ipairs(targetZones) do
                local zone = bc:getZoneByName(zoneName)
                if zone and zone.side == 2 then
                    return true
                end
            end
        end
        return false
    end
})

mc:trackMission({
    title = "V1 Rocket Attack",
    description = "Enemy V1 rockets incoming!\nDestroy the launch site or evacuate the area.",
    messageStart = "Warning: V1 rocket barrage detected!",
    messageEnd = function() 
        lastV1Arty_COOLDOWN = timer.getTime() 
        return "V1 rocket attack ended" 
    end,
    startAction = function()
        if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "ding.ogg")
        end
    end,
    endAction = function()
        if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
    isActive = function()
        return isAnyV1Active()
    end
})
-------------------------------------------- End of V1 Artillery event ------------------------------------------
-- scenery and missions

local sceneryList = {
  ["RailwayFord"] = {SCENERY:FindByZoneName("HiddenRailwayFord")},
  ["RailwayCherbourg"] = {SCENERY:FindByZoneName("HiddenRailwayCherbourg")},
  ["RailwayValognes"] = {SCENERY:FindByZoneName("HiddenRailwayValognes")},
  ["RailwayTrainDepotValognes"] = {SCENERY:FindByZoneName("HiddenTrainDepotValognes")},
  ["RailwayCaen"] = {SCENERY:FindByZoneName("HiddenRailwayCaen")},
  ["RailwayLeHavre"] = {SCENERY:FindByZoneName("HiddenRailwayLeHavre")},
  ["RailwayBernay"] = {SCENERY:FindByZoneName("HiddenRailwayBernay")},
  ["RailwaySaintAndre"] = {SCENERY:FindByZoneName("HiddenRailwaySaintAndre")},
  ["RailwayOrly"] = {SCENERY:FindByZoneName("HiddenRailwayOrly")},
  ["RailwayParisSaintLazare"] = {SCENERY:FindByZoneName("HiddenRailwayParisSaintLazare")},
  ["RailwayParisGareDeLest"] = {SCENERY:FindByZoneName("HiddenRailwayParisGareDeLest")},
  ["RailwayParisGareDuNord"] = {SCENERY:FindByZoneName("HiddenRailwayParisGareDuNord")},
  ["RailwayFecamp"] = {SCENERY:FindByZoneName("HiddenRailwayFecamp")},
  ["RailwayPowerplantFecamp"] = {SCENERY:FindByZoneName("HiddenRailwayPowerplantFecamp")},
  ["RailwayDepotRouen"] = {SCENERY:FindByZoneName("HiddenRailwayDepotRouen")},
  ["RailwayDepotSaintAubain"] = {SCENERY:FindByZoneName("HiddenRailwayDepotSaintAubain")},
  ["RailwayTrainDepotAmiens"] = {SCENERY:FindByZoneName("HiddenRailwayTrainDepotAmiens")},
  ["RailwayAbbeville"] = {SCENERY:FindByZoneName("HiddenRailwayAbbeville")},
  ["RailwayDunkirkPort"] = {SCENERY:FindByZoneName("HiddenRailwayDunkirkPort")},
  ["RailwayLeTouquet"] = {SCENERY:FindByZoneName("HiddenRailwayLeTouquet")},
  ["RailwayCalais"] = {SCENERY:FindByZoneName("HiddenRailwayCalais")},

  --["SuezBridge"] = {SCENERY:FindByZoneName("SuezBridge")},
 -- ["factoryBulding3"] = {SCENERY:FindByZoneName("factoryBulding3")},
 -- ["factoryBulding2"] = {SCENERY:FindByZoneName("factoryBulding2")},
 -- ["factoryBulding"] = {SCENERY:FindByZoneName("factoryBulding")},
}

-- Railway Station to Group Mapping
-- Maps railway stations to military groups that depend on them for supply
RAILWAY_STATION_GROUPS = {
    ["RailwayFord"] = {
        "UK_London-resupply-Ford"
    },
    ["RailwayCherbourg"] = {
        "AXE_Train_Cherbourg-resupply-Valognes"
    },
	["RailwayValognes"] = {
		"AXE_Train_Cherbourg-resupply-Valognes"
	},
	["RailwayTrainDepotValognes"] = {
		"AXE_Train_Valognes-resupply-Le Molay"
	},
	["RailwayCaen"] = {
		"AXE_Train_Le Molay-resupply-Caen",
		"AXE_Train_Bernay-resupply-Caen"
	},
	["RailwayLeHavre"] = {
		"AXE_Train_Le Havre-resupply-Fecamp",
		"AXE_Train_Le Havre-resupply-Rouen"
	},
	["RailwayBernay"] = {
		"AXE_Train_Bernay-resupply-Caen",
		"AXE_Train_Saint-Andre-resupply-Bernay"
	},
	["RailwaySaintAndre"] = {
		"AXE_Train_Saint-Andre-resupply-Bernay",
		"AXE_Train_Paris-resupply-Saint-Andre"
	},
	["RailwayOrly"] = {
		"AXE_Train_Paris-resupply-Orly"
	},
	["RailwayParisSaintLazare"] = {
		"AXE_Train_Paris-resupply-Saint-Andre"
	},
	["RailwayParisGareDeLest"] = {
		"AXE_Train_Paris-resupply-Orly"
	},
	["RailwayParisGareDuNord"] = {
		"AXE_Train_Paris-resupply-Fecamp",
		"AXE_Train_Paris-resupply-Saint-Aubain"
	},
	["RailwayFecamp"] = {
		"AXE_Train_Le Havre-resupply-Fecamp"
	},
	["RailwayPowerplantFecamp"] = {
		"AXE_Train_Paris-resupply-Fecamp",
		"AXE_Train_Le Havre-resupply-Fecamp"
	},
	["RailwayDepotRouen"] = {
		"AXE_Train_Le Havre-resupply-Rouen"
	},
	["RailwayDepotSaintAubain"] = {
		"AXE_Train_Paris-resupply-Saint-Aubain"
	},
	["RailwayTrainDepotAmiens"] = {
		"AXE_Train_Amiens-resupply-Abbeville"
	},
	["RailwayAbbeville"] = {
		"AXE_Train_Amiens-resupply-Abbeville",
		"AXE_Train_Abbeville-resupply-Le Touquet"
	},
	["RailwayDunkirkPort"] = {
		"AXE_Train_Dunkirk-Port-resupply-Calais"
	},
	["RailwayLeTouquet"] = {
		"AXE_Train_Abbeville-resupply-Le Touquet"
	},
	["RailwayCalais"] = {
		"AXE_Train_Dunkirk-Port-resupply-Calais"
	},
}

-- Track which stations have been destroyed to avoid duplicate processing
local railwayStationsDestroyed = {}

-- Track which train groups have been destroyed to avoid duplicate processing
local trainGroupsDestroyed = {}

-- Function to destroy groups dependent on a railway station
--[[
local function destroyRailwayDependentGroups(stationName)
    if railwayStationsDestroyed[stationName] then
        return -- Already processed this station
    end
    
    railwayStationsDestroyed[stationName] = true
    
    local groupsToDestroy = RAILWAY_STATION_GROUPS[stationName]
    if not groupsToDestroy then
        return
    end
    
    -- Get the parent zone to check coalition
    local parentZoneName = RAILWAY_SUBZONE_MAPPING[stationName]
    local parentZone = parentZoneName and zones[parentZoneName]
    local parentCoalition = parentZone and parentZone.side or 0
    
    local destroyedCount = 0
    local destroyedNames = {}
    
    for _, groupName in ipairs(groupsToDestroy) do
        local group = Group.getByName(groupName)
        if group then
            group:destroy()
            destroyedCount = destroyedCount + 1
            table.insert(destroyedNames, groupName)
            env.info("Railway Station System: Destroyed group " .. groupName .. " due to " .. stationName .. " destruction")
        end
    end
    
    -- Provide feedback to players and award credits based on parent zone coalition
    if destroyedCount > 0 then
        local stationDisplayName = stationName:gsub("Railway", "Railway Station ")
        local message = string.format(
            "%s destroyed!\n%d military units abandoned due to supply disruption:\n%s", 
            stationDisplayName,
            destroyedCount,
            table.concat(destroyedNames, ", ")
        )
        
        -- Award credits to BLUE coalition if parent zone is RED (enemy supply disruption)
        if parentCoalition == 1 then
            trigger.action.outTextForCoalition(2, message, 20)
            
            -- Award bonus credits for strategic targeting of enemy supply lines
            local bonus = destroyedCount * 2000
            bc:addFunds(2, bonus)
            
            local bonusMessage = string.format("Enemy supply line disrupted! Strategic targeting bonus: +%d credits", bonus)
            trigger.action.outTextForCoalition(2, bonusMessage, 10)
            
            env.info("Railway Station System: Awarded " .. bonus .. " credits to BLUE for destroying RED railway station " .. stationName)
        elseif parentCoalition == 2 then
            -- If parent zone is BLUE, notify but don't award credits (friendly fire)
            trigger.action.outTextForCoalition(2, "Friendly railway station destroyed: " .. message, 20)
            env.info("Railway Station System: No credits awarded - friendly railway station " .. stationName .. " destroyed")
        else
            -- Neutral zone - minimal notification
            trigger.action.outTextForCoalition(2, message, 15)
            env.info("Railway Station System: Neutral railway station " .. stationName .. " destroyed")
        end
        bc:drawSupplyArrows()
        -- Save the updated state
        --saveRailwayState()
    end
end
--]]
local function destroyRailwayDependentGroups(stationName)
    if railwayStationsDestroyed[stationName] then
        return -- Already processed this station
    end
    
    railwayStationsDestroyed[stationName] = true
    
    local groupsToDestroy = RAILWAY_STATION_GROUPS[stationName]
    if not groupsToDestroy then
        return
    end
    
    local destroyedCount = 0
    local destroyedNames = {}
    local creditsAwarded = { [1] = 0, [2] = 0 }  -- Track credits awarded to each coalition
    
    for _, groupName in ipairs(groupsToDestroy) do
        local group = Group.getByName(groupName)
        if group then
            local groupCoalition = group:getCoalition()
            
            group:destroy()
            trainGroupsDestroyed[groupName] = true
            CustomFlags[groupName] = true
            destroyedCount = destroyedCount + 1
            table.insert(destroyedNames, groupName)
           -- env.info("Railway Station System: Destroyed group " .. groupName .. " due to " .. stationName .. " destruction")
            
            -- Award credits to the opposing coalition
            if groupCoalition == 1 then
                -- RED group destroyed - award to BLUE
                local bonus = 2000
                bc:addFunds(2, bonus)
                creditsAwarded[2] = creditsAwarded[2] + bonus
            elseif groupCoalition == 2 then
                -- BLUE group destroyed - award to RED
                local bonus = 2000
                bc:addFunds(1, bonus)
                creditsAwarded[1] = creditsAwarded[1] + bonus
            end
        end
    end
    
    -- Provide feedback to players
    if destroyedCount > 0 then
        local stationDisplayName = stationName:gsub("Railway", "Depot ")
        local message = string.format(
            "%s destroyed!\n%d military units abandoned due to supply disruption:\n%s", 
            stationDisplayName,
            destroyedCount,
            table.concat(destroyedNames, ", ")
        )
        
        -- Send messages and bonuses based on credits awarded
        if creditsAwarded[2] > 0 then
            trigger.action.outTextForCoalition(2, message, 20)
            local bonusMessage = string.format("Enemy railway infrastructure destroyed! Strategic targeting bonus: +%d credits", creditsAwarded[2])
            trigger.action.outTextForCoalition(2, bonusMessage, 10)
            --env.info("Railway Station System: Awarded " .. creditsAwarded[2] .. " credits to BLUE for destroying enemy railway station " .. stationName)
        end
        
        if creditsAwarded[1] > 0 then
            trigger.action.outTextForCoalition(1, message, 20)
            local bonusMessage = string.format("Enemy railway infrastructure destroyed! Strategic targeting bonus: +%d credits", creditsAwarded[1])
            trigger.action.outTextForCoalition(1, bonusMessage, 10)
            --env.info("Railway Station System: Awarded " .. creditsAwarded[1] .. " credits to RED for destroying enemy railway station " .. stationName)
        end
        
        -- If no credits were awarded (neutral groups), still show the message
        if creditsAwarded[1] == 0 and creditsAwarded[2] == 0 then
            trigger.action.outTextForCoalition(2, message, 15)
            trigger.action.outTextForCoalition(1, message, 15)
            --env.info("Railway Station System: Neutral railway station " .. stationName .. " destroyed - no credits awarded")
        end
        
        bc:drawSupplyArrows()
        -- Save the updated state
        --saveRailwayState()
    end
end


-- Function to restore railway destruction state on mission restart
local function restoreRailwayDestructionState()
    env.info("Railway Station System: Checking for previously destroyed stations...")
    
    for stationName, isDestroyed in pairs(CustomFlags) do
        if isDestroyed == true and stationName:lower():find("railway") then
            env.info("Railway Station System: Restoring destruction state for " .. stationName)
            
            -- Find and destroy the scenery objects using explosions
            local sceneries = sceneryList[stationName]
            if sceneries then
                for _, scenery in ipairs(sceneries) do
                    if scenery then
                        -- Use explosion to damage scenery
                        trigger.action.explosion(scenery:GetPointVec3(), 500)
                        env.info("Railway Station System: Used explosion to damage scenery for " .. stationName)
                    end
                end
            end
            
            -- Destroy dependent groups using existing function
            destroyRailwayDependentGroups(stationName)
            bc:drawSupplyArrows()
            -- Provide feedback about restoration
            local stationDisplayName = stationName:gsub("Railway", "Railway Station ")
            trigger.action.outTextForCoalition(2, 
                stationDisplayName .. " remains destroyed from previous mission", 15)
        end
    end
	env.info("Railway Station System: previously destroyed stations Check complete")
end

-- Function to restore train group destruction state on mission restart
local function restoreTrainGroupDestructionState()
    env.info("Train Group System: Checking for previously destroyed train groups...")
    
    for groupName, isDestroyed in pairs(CustomFlags) do
        if isDestroyed == true and (groupName:find("AXE_Train_") or groupName:find("UK_Train_")) then
            --env.info("Train Group System: Restoring destruction state for " .. groupName)
            
            -- Mark this train group as destroyed in our tracking
            trainGroupsDestroyed[groupName] = true
            
            
            -- Find and destroy the train group if it exists
            local group = Group.getByName(groupName)
            if group then
                group:destroy()
                --env.info("Train Group System: Destroyed train group " .. groupName)
                
                -- Determine coalition for feedback
                local coalition = 2 -- Default to Blue coalition
                if groupName:find("AXE_Train_") then
                    coalition = 2 -- Blue coalition gets notification for Red train destruction
                elseif groupName:find("UK_Train_") then
                    coalition = 1 -- Red coalition gets notification for Blue train destruction
                end
                
                -- Provide feedback to players
                trigger.action.outTextForCoalition(coalition, 
                    "Train " .. groupName .. " remains destroyed from previous mission", 10)
            --else
              --env.info("Train Group System: Train group " .. groupName .. " not found (already destroyed)")
            end
        end
    end
	env.info("Train Group System: previously destroyed train Check complete")
end
-- function restoreTrainGroupDestructionState()
--     env.info("Train Group System: Checking for previously destroyed train groups...")
    
--     for groupName, isDestroyed in pairs(CustomFlags) do
--         if isDestroyed == true and (groupName:find("AXE_Train_") or groupName:find("UK_Train_")) then
--             -- CRITICAL FIX: Check if the railway infrastructure supports this train
--             local shouldBeDestroyed = false
            
--             -- Check railway station dependencies
--             if RAILWAY_STATION_GROUPS then
--                 for stationName, associatedTrains in pairs(RAILWAY_STATION_GROUPS) do
--                     for _, trainName in ipairs(associatedTrains) do
--                         if trainName == groupName then
--                             -- Check if the railway station is destroyed
--                             if CustomFlags[stationName] == true then
--                                 shouldBeDestroyed = true
--                                 env.info("Train Group System: " .. groupName .. " should be destroyed - railway station " .. stationName .. " is destroyed")
--                                 break
--                             end
--                         end
--                     end
--                     if shouldBeDestroyed then break end
--                 end
--             end
            
--             -- Only destroy if railway infrastructure is actually destroyed
--             if shouldBeDestroyed then
--                 trainGroupsDestroyed[groupName] = true
--                 local group = Group.getByName(groupName)
--                 if group then
--                     group:destroy()
--                     env.info("Train Group System: Destroyed train group " .. groupName .. " due to destroyed railway infrastructure")
--                 end
--             else
--                 -- IMPORTANT: Clear the flag if railway is operational
--                 env.info("Train Group System: Clearing destruction flag for " .. groupName .. " - railway infrastructure is operational")
--                 CustomFlags[groupName] = nil
--             end
--         end
--     end
    
--     env.info("Train Group System: Restoration check complete")
-- end

local function restoreV1GroupDestructionState()
    env.info("V1 Group System: Checking for previously destroyed V1 launchers...")
    
    for unitName, isDestroyed in pairs(CustomFlags) do
        if isDestroyed == true and unitName:find("V1 Launch Site -") then
            --env.info("V1 Group System: Restoring destruction state for " .. unitName)
            
            -- Extract group name from unit name by removing the unit identifier (# 1-01, etc.)
            local groupName = unitName:match("^(.+) # %d+%-%d+$")
            if groupName then
                --env.info("V1 Group System: Extracted group name: " .. groupName)
                
                -- Find and destroy the V1 group if it exists
                local group = Group.getByName(groupName)
                if group then
                    group:destroy()
                    --env.info("V1 Group System: Destroyed V1 group " .. groupName)
                    
                    -- Provide feedback to Blue coalition (V1 is Red, so Blue gets credit)
                    trigger.action.outTextForCoalition(2, 
                        "V1 launcher " .. groupName .. " remains destroyed from previous mission", 10)
                --else
                    --env.info("V1 Group System: V1 group " .. groupName .. " not found (already destroyed)")
                end
            --else
                --env.info("V1 Group System: Could not extract group name from " .. unitName)
            end
        end
    end
	env.info("V1 Group System: Check complete")
end


-- Call restoration functions to restore states from previous sessions
restoreRailwayDestructionState()
restoreTrainGroupDestructionState()
restoreV1GroupDestructionState()

-- Monitor train groups for destruction
-- DELAY START: Wait 60 seconds after mission start to allow DCS to fully initialize all units
SCHEDULER:New(nil, function()
    env.info("Train Group System: Checking for destroyed train groups...")
    
    -- Check both Red and Blue coalitions for train groups
    -- Red coalition (coalition 1) - check for AXE_Train_ groups
    local redGroundGroups = coalition.getGroups(1, Group.Category.GROUND) or {}
    local redTrainGroups = coalition.getGroups(1, Group.Category.TRAIN) or {}
    
    -- Blue coalition (coalition 2) - check for UK_Train_ groups  
    local blueGroundGroups = coalition.getGroups(2, Group.Category.GROUND) or {}
    local blueTrainGroups = coalition.getGroups(2, Group.Category.TRAIN) or {}
    
    -- env.info("Ground Group System: Found " .. #redGroundGroups .. " Red ground groups")
    -- env.info("Train Group System: Found " .. #redTrainGroups .. " Red train groups")
    -- env.info("Ground Group System: Found " .. #blueGroundGroups .. " Blue ground groups")
    -- env.info("Train Group System: Found " .. #blueTrainGroups .. " Blue train groups")
    
    -- Combine all group types
    local allGroups = {}
    for _, group in ipairs(redGroundGroups) do
        table.insert(allGroups, group)
    end
    for _, group in ipairs(redTrainGroups) do
        table.insert(allGroups, group)
    end
    for _, group in ipairs(blueGroundGroups) do
        table.insert(allGroups, group)
    end
    for _, group in ipairs(blueTrainGroups) do
        table.insert(allGroups, group)
    end
    
    local trainGroupCount = 0
    for _, group in ipairs(allGroups) do
        local groupName = group:getName()
        
        -- Check for both AXE_Train_ (Red) and UK_Train_ (Blue) groups
        if groupName and (groupName:find("AXE_Train_") or groupName:find("UK_Train_")) then
            trainGroupCount = trainGroupCount + 1
            --env.info("Train Group System: Found train group " .. groupName .. ", checking status...")
            
            if not trainGroupsDestroyed[groupName] then
                local units = group:getUnits()
                local isDestroyed = false
                
                if not units or #units == 0 then
                    isDestroyed = true
                    --env.info("Train Group System: " .. groupName .. " has no units")
                else
                    -- For trains, check if the single unit is alive
                    local unit = units[1]
                    if not unit or not unit:isExist() or unit:getLife() <= 1 then
                        isDestroyed = true
                        --env.info("Train Group System: " .. groupName .. " unit is destroyed/dead")
                    --else
                      --env.info("Train Group System: " .. groupName .. " is still operational (life: " .. unit:getLife() .. ")")
                    end
                end
                
                if isDestroyed then
                    -- Train group has been destroyed
                    trainGroupsDestroyed[groupName] = true
                    CustomFlags[groupName] = true
                    
                    --env.info("Train Group System: " .. groupName .. " destroyed, setting CustomFlag")
                    
                    -- Determine coalition for feedback and credits
                    local rewardCoalition, creditAmount
                    if groupName:find("AXE_Train_") then
                        -- Red train destroyed, reward Blue coalition
                        rewardCoalition = 2
                        creditAmount = 1000
                        trigger.action.outTextForCoalition(2, 
                            "Enemy train " .. groupName .. " destroyed!", 10)
                    elseif groupName:find("UK_Train_") then
                        -- Blue train destroyed, reward Red coalition
                        rewardCoalition = 1
                        creditAmount = 1000
                        trigger.action.outTextForCoalition(1, 
                            "Enemy train " .. groupName .. " destroyed!", 10)
                    end
                    
                    -- Award bonus credits for destroying strategic asset
                    if rewardCoalition and creditAmount then
                        bc:addFunds(rewardCoalition, creditAmount)
                        trigger.action.outTextForCoalition(rewardCoalition, 
                            "Strategic asset destroyed: +" .. creditAmount .. " credits", 10)
                    end
                    
                    -- Update supply arrow display to reflect broken supply chain
                    --env.info("Train Group System: Refreshing supply arrows due to train destruction")
                    bc:drawSupplyArrows()
                    
                    -- Notify about supply chain disruption
                    if rewardCoalition then
                        trigger.action.outTextForCoalition(rewardCoalition, 
                            "Enemy supply chain disrupted! Train routes now cut off.", 15)
                    end
                end
            else
                env.info("Train Group System: " .. groupName .. " already marked as destroyed")
            end
        end
    end
    
    --env.info("Train Group System: Found " .. trainGroupCount .. " train groups total")
    env.info("Train Group System: Check complete")
end, {}, 30, 300)

SCHEDULER:New(nil, function()
    for name, sceneries in pairs(sceneryList) do
        local allBelow50 = true
        for _, scenery in ipairs(sceneries) do
            if scenery and scenery:GetRelativeLife() > 50 then
                allBelow50 = false
                break
            end
        end
        if allBelow50 then
            CustomFlags[name] = true
            -- Check if this is a railway station and process group destruction
            if name:lower():find("railway") then
                destroyRailwayDependentGroups(name)
            end
        end
    end
end, {}, 60, 300)

-- CRITICAL FIX: Delay scenery monitoring to prevent false railway destruction at mission start
-- Wait 120 seconds to ensure all scenery objects are properly initialized before checking health
-- SCHEDULER:New(nil, function()
--     env.info("Scenery Monitoring System: Starting health check cycle...")
    
--     local stationsChecked = 0
--     local stationsDestroyed = 0
    
--     for name, sceneries in pairs(sceneryList) do
--         stationsChecked = stationsChecked + 1
--         env.info("Scenery Monitoring System: Checking " .. name .. " with " .. #sceneries .. " scenery objects")
        
--         local allBelow50 = true
--         local objectsFound = 0
--         local objectsAlive = 0
--         local lifeValues = {}
        
--         for i, scenery in ipairs(sceneries) do
--             if scenery then
--                 objectsFound = objectsFound + 1
--                 local life = scenery:GetRelativeLife()
--                 table.insert(lifeValues, string.format("obj%d=%.1f", i, life))
                
--                 env.info("Scenery Monitoring System: " .. name .. " object " .. i .. " has life: " .. life)
                
--                 if life > 50 then
--                     objectsAlive = objectsAlive + 1
--                     allBelow50 = false
--                     env.info("Scenery Monitoring System: " .. name .. " object " .. i .. " is alive (life > 50)")
--                 else
--                     env.info("Scenery Monitoring System: " .. name .. " object " .. i .. " is destroyed/damaged (life <= 50)")
--                 end
--             else
--                 env.error("Scenery Monitoring System: " .. name .. " has NULL scenery object at index " .. i)
--             end
--         end
        
--         env.info("Scenery Monitoring System: " .. name .. " summary - Objects found: " .. objectsFound .. "/" .. #sceneries .. ", Alive: " .. objectsAlive .. ", Life values: [" .. table.concat(lifeValues, ", ") .. "]")
        
--         if allBelow50 then
--             stationsDestroyed = stationsDestroyed + 1
--             env.info("Scenery Monitoring System: DESTROYING " .. name .. " - all objects below 50% health")
--             CustomFlags[name] = true
            
--             -- Check if this is a railway station and process group destruction
--             if name:lower():find("railway") then
--                 env.info("Scenery Monitoring System: Processing railway destruction for " .. name)
--                 destroyRailwayDependentGroups(name)
--             end
--         else
--             env.info("Scenery Monitoring System: " .. name .. " is operational - at least one object above 50% health")
            
--             -- IMPORTANT: Clear any existing destruction flags for healthy stations
--             if CustomFlags[name] == true then
--                 env.info("Scenery Monitoring System: Clearing previous destruction flag for " .. name .. " (now healthy)")
--                 CustomFlags[name] = nil
--             end
--         end
--     end
    
--     env.info("Scenery Monitoring System: Health check complete - Checked: " .. stationsChecked .. ", Destroyed: " .. stationsDestroyed)
    
--     if stationsDestroyed > 0 then
--         env.info("Scenery Monitoring System: Refreshing supply arrows due to " .. stationsDestroyed .. " destroyed stations")
--         bc:drawSupplyArrows()
--     end
-- end, {}, 60, 20)


--[[ old static missions
mc:trackMission({
	title = "Escort",
	description = "Friendly cargo transport has entered the airspace from the south. Protect it from the enemy.",
	messageStart = "New mission: Escort",
	messageEnd = "Mission ended: Escort",
	startAction = function() trigger.action.outSoundForCoalition(2,"ding.ogg") end,
	endAction = function() 
		trigger.action.outSoundForCoalition(2,"cancel.ogg")
	end,
	isActive = function()
		if Group.getByName('escort1') then return true end
		
		return false
	end
})

mc:trackMission({
	title = "Intercept",
	description = "Enemy cargo transport has entered the airspace from the south. Intercept and destroy it before it escapes.",
	messageStart = "New mission: Intercept",
	messageEnd = "Mission ended: Intercept",
	startAction = function() trigger.action.outSoundForCoalition(2,"ding.ogg") end,
	endAction = function() 
		trigger.action.outSoundForCoalition(2,"cancel.ogg")
	end,
	isActive = function()
		if Group.getByName('intercept1') then return true end
		
		return false
	end
})

mc:trackMission({
	title = "Destroy artillery",
	description = "The enemy has deployed artillery near OlfOrote. Destroy it before it has a chance to fire",
	messageStart = "New mission: Destroy artillery",
	messageEnd = "Mission ended: Destroy artillery",
	startAction = function() trigger.action.outSoundForCoalition(2,"ding.ogg") end,
	endAction = function() 
		trigger.action.outSoundForCoalition(2,"cancel.ogg")
	end,
	isActive = function()
		if Group.getByName('redmlrs1') then return true end
		
		return false
	end
})

--]]

resupplyTarget = nil
mc:trackMission({
    title = function()
        local wp = WaypointList[resupplyTarget] or ""
        return "Resupply " .. resupplyTarget .. wp
    end,
    description = function()
        return "Deliver supplies to " .. resupplyTarget end,
    messageStart = function()
        local wp = WaypointList[resupplyTarget] or ""
        return "New mission: Resupply " .. resupplyTarget .. wp
    end,
    messageEnd = function()
        return "Mission ended: Resupply " .. resupplyTarget end,
    startAction = function()
        if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "ding.ogg")
        end
    end,
    endAction = function()
		resupplyTarget = nil
        if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
    isActive = function()
        if not resupplyTarget then return false end

        local targetzn = bc:getZoneByName(resupplyTarget)
        return targetzn:canRecieveSupply()
    end
})

attackTarget = nil
mc:trackMission({
    title = function()
        local wp = WaypointList[attackTarget] or ""
        return "Attack " .. attackTarget .. wp
    end,
    description = function()
        local wp = WaypointList[attackTarget] or ""
        return "Destroy enemy forces at " .. attackTarget end,
    messageStart = function()
        local wp = WaypointList[attackTarget] or ""
        return "New mission: Attack " .. attackTarget .. wp
    end,
    messageEnd = function()
        return "Mission ended: Attack " .. attackTarget end,
    startAction = function()
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "cas.ogg")
        end
    end,
    endAction = function()
		attackTarget = nil
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
    isActive = function()
        if not attackTarget then return false end
        local targetzn = bc:getZoneByName(attackTarget)
        return targetzn.side == 1
    end
})


captureTarget = nil
mc:trackMission({
    title = function()
        local wp = WaypointList[captureTarget] or ""
        return "Capture " .. captureTarget .. wp
    end,
    description = function()
        return captureTarget .. " is neutral. Capture it by delivering supplies" end,
    messageStart = function()
        local wp = WaypointList[captureTarget] or ""
        return "New mission: Capture " .. captureTarget .. wp
    end,
    messageEnd = function()
        return "Mission ended: Capture " .. captureTarget end,
    startAction = function()
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "ding.ogg")
        end
    end,
    endAction = function()
		captureTarget = nil
         if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
    isActive = function()
        if not captureTarget then return false end

        local targetzn = bc:getZoneByName(captureTarget)
        return targetzn.side == 0 and targetzn.active
    end
})

---------------------------------------------------------------------
--                          CAP MISSION                            --

capMissionTarget = nil
capKillsByPlayer = {}
capTargetPlanes = 0
capWinner = nil
capMissionCooldownUntil = 0

mc:trackMission({
    title = function() return "CAP mission" end,
    description = function()
        if not next(capKillsByPlayer) then
            return "Kill "..capTargetPlanes.." A/A targets without getting shot down, who wins?"
        else
            local scoreboard = "Current Kill Count:\n"
            for playerName, kills in pairs(capKillsByPlayer) do
                scoreboard = scoreboard .. string.format("%s: %d\n", playerName, kills)
            end
            return string.format("Kill %d A/A targets, who wins?\n\n%s", capTargetPlanes, scoreboard)
        end
    end,
    messageStart = function()
        return "New CAP mission: Kill "..capTargetPlanes.." A/A targets." end,
    messageEnd = function() return "Mission ended: CAP" end,
    startAction = function()
        if not missionCompleted then
            trigger.action.outSoundForCoalition(2, "ding.ogg")
        end
    end,
    endAction = function()
        if capWinner then
            local reward = capTargetPlanes * 100
            capMissionCooldownUntil = timer.getTime() + 1800
            trigger.action.outTextForCoalition(2, "["..capWinner.."] completed the CAP mission!\nReward: "..reward.." credits", 20)
            bc:addFunds(2, reward)
        end
        capMissionTarget = nil
        capKillsByPlayer = {}
        capWinner = nil
		capTargetPlanes = 0
        if not missionCompleted then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
    isActive = function()
        if not capMissionTarget then return false end
        return true
    end
})

function checkAndGenerateCAPMission()
	if capMissionTarget ~= nil or timer.getTime() < capMissionCooldownUntil then
		return
	end
	local countInAir = 0
	for _, zC in pairs(bc.zones) do
		if zC.side == 1 and zC.active then
			for _, groupCom in ipairs(zC.groups) do
				if groupCom.side == 1
				and (groupCom.mission == 'attack' or groupCom.mission == 'patrol')
				and groupCom.state == 'inair' then
					countInAir = countInAir + 1
				end
			end
		end
	end
	local players = getBluePlayersCount()
	local limit = getCapLimit(players)
	if players == 0 then return end
	if countInAir >= 1 then
		if limit == 1 then
			capTargetPlanes = math.random(1,2)
		elseif limit == 2 then
			capTargetPlanes = math.random(2,4)
		elseif limit == 3 then
			capTargetPlanes = math.random(2,5)
		elseif limit == 4 then
			capTargetPlanes = math.random(3,6)
		elseif limit == 99999 then
			capTargetPlanes = math.random(3,6)
		end
		capMissionTarget = "Active"
	end
end

--                    End of CAP MISSION                           --
---------------------------------------------------------------------


function generateCaptureMission()
    if captureTarget ~= nil then return end
    
    local validzones = {}
    for _, v in ipairs(bc.zones) do
        if v.active and v.side == 0 and (not v.NeutralAtStart or v.firstCaptureByRed) and 
           not string.find(v.zone, "Hidden") then
            table.insert(validzones, v.zone)
        end
    end
    
    if #validzones == 0 then return end
    
    local choice = math.random(1, #validzones)
    if validzones[choice] then
        captureTarget = validzones[choice]
        return true
    end
end

function generateAttackMission()
	if attackTarget ~= nil then return end
		
	local validzones = {}
	for _,v in ipairs(bc.connections) do
		local to = bc:getZoneByName(v.to)
		local from = bc:getZoneByName(v.from)
		
		if from.side ~= to.side and from.side ~= 0  and to.side ~= 0 and from.active and to.active then
			if from.side == 1 then
				table.insert(validzones, from.zone)
			elseif to.side == 1 then
				table.insert(validzones, to.zone)
			end
		end
	end
	
	if #validzones == 0 then return end
	
	local choice = math.random(1, #validzones)
	if validzones[choice] then
		attackTarget = validzones[choice]
		return true
	end
end

function generateSupplyMission()
    if missionCompleted then return end
    if resupplyTarget ~= nil then return end

    local validzones = {}
    for _, v in ipairs(bc.zones) do
        if v.side == 2 and v:canRecieveSupply() then
            table.insert(validzones, v.zone)
        end
    end

    if #validzones == 0 then return end

    local choice = math.random(1, #validzones)
    if validzones[choice] then
        resupplyTarget = validzones[choice]
        return true
    end
end

timer.scheduleFunction(function(_, time)
	if generateCaptureMission() then
		return time+300
	else
		return time+120
	end
end, {}, timer.getTime() + 20)

timer.scheduleFunction(function(_, time)
	if generateAttackMission() then
		return time+300
	else
		return time+120
	end
end, {}, timer.getTime() + 40)

timer.scheduleFunction(function(_, time)
	if generateSupplyMission() then
		return time+300
	else
		return time+120
	end
end, {}, timer.getTime() + 60)





--- Function to check for player death and subtract a specific amount from the coalition 'bank'

local ev = {} 
ev.bc = bc
function ev:onEvent(event)
    if event.id ~= world.event.S_EVENT_UNIT_LOST then return end 
    if not event.initiator then return end 
    if not event.initiator.getPlayerName then return end 
    if not event.initiator:getPlayerName() then return end 
    
    trigger.action.outText("Player aircraft lost, 100 credits subtracted from coalition ", 10)
--	 trigger.action.outText("Player aircraft lost, 100 credits subtracted from coalition "..event.initiator:getCoalition(), 10) -- Version with coalition number included	
    self.bc:addFunds(event.initiator:getCoalition(),-100) 
end

world.addEventHandler(ev)
mc:init()

----------------------- FLAGS --------------------------

function checkZoneFlags()
--[[
	if zones.rotahill.wasblue and not zones.rotaintl.wasblue and trigger.action.setUserFlag("100") == false then
		trigger.action.setUserFlag("100", true)
	end
	if zones.rotaintl.wasblue and trigger.misc.getUserFlag("101") == 0 then
		trigger.action.setUserFlag("100", false)
		trigger.action.setUserFlag("101", true)
	end
--]]
--[[
	if trigger.misc.getUserFlag(50700) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local zn = bc:getZoneByName('Valognes')
            if zn and zn.side == 0 then 
				zn:capture(1)
				--trigger.action.outText("Valognes captured ", 10)
			elseif zn and zn.side == 1 then
				zn:upgrade()
				--trigger.action.outText("Valognes upgraded ", 10)
			else
                return 'blue zone'
            end
		trigger.action.setUserFlag("Valognes", false)
	end
--]]
-------------- Capture/Upgrade Trains Blue-------------------
if trigger.misc.getUserFlag(300) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('London')
		local zntgt = bc:getZoneByName('Farnborough')
            if znsrc and znsrc.side == 2 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(2)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 2 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Farnborough is Red zone'
				end
			else
				--trigger.action.outText("London is not Red, cannot capture or upgrade Valognes", 10)
				return 'London is not Red zone'
            end
		trigger.action.setUserFlag(300, 0)
	end

	if trigger.misc.getUserFlag(301) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('London')
		local zntgt = bc:getZoneByName('Manston')
            if znsrc and znsrc.side == 2 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(2)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 2 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Manston is Red zone'
				end
			else
				--trigger.action.outText("London is not Red, cannot capture or upgrade Valognes", 10)
				return 'London is not Blue zone'
            end
		trigger.action.setUserFlag(301, 0)
	end

	if trigger.misc.getUserFlag(302) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('London')
		local zntgt = bc:getZoneByName('Ford')
            if znsrc and znsrc.side == 2 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(2)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 2 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Ford is Red zone'
				end
			else
				--trigger.action.outText("London is not Red, cannot capture or upgrade Valognes", 10)
				return 'London is not Blue zone'
            end
		trigger.action.setUserFlag(302, 0)
	end

	if trigger.misc.getUserFlag(303) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('London')
		local zntgt = bc:getZoneByName('Chailey')
            if znsrc and znsrc.side == 2 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(2)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 2 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Chailey is Red zone'
				end
			else
				--trigger.action.outText("London is not Red, cannot capture or upgrade Valognes", 10)
				return 'London is not Blue zone'
            end
		trigger.action.setUserFlag(303, 0)
	end

	if trigger.misc.getUserFlag(304) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Manston')
		local zntgt = bc:getZoneByName('Dover')
            if znsrc and znsrc.side == 2 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(2)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 2 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Dover is Red zone'
				end
			else
				--trigger.action.outText("London is not Red, cannot capture or upgrade Valognes", 10)
				return 'Manston is not Blue zone'
            end
		trigger.action.setUserFlag(304, 0)
	end


-------------- Capture/Upgrade Trains Red-------------------
	if trigger.misc.getUserFlag(200) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Cherbourg')
		local zntgt = bc:getZoneByName('Valognes')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Valognes is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Cherbourg is not Red zone'
            end
		trigger.action.setUserFlag(200, 0)
	end

	if trigger.misc.getUserFlag(201) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Valognes')
		local zntgt = bc:getZoneByName('Le Molay')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Le Molay is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Valognes is not Red zone'
            end
		trigger.action.setUserFlag(201, 0)
	end

	if trigger.misc.getUserFlag(202) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Le Molay')
		local zntgt = bc:getZoneByName('Caen')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Caen is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Le Molay is not Red zone'
            end
		trigger.action.setUserFlag(202, 0)
	end

	if trigger.misc.getUserFlag(203) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Bernay')
		local zntgt = bc:getZoneByName('Caen')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Caen is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Bernay is not Red zone'
            end
		trigger.action.setUserFlag(203, 0)
	end


	if trigger.misc.getUserFlag(204) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Saint-Andre')
		local zntgt = bc:getZoneByName('Bernay')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Bernay is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Saint-Andre is not Red zone'
            end
		trigger.action.setUserFlag(204, 0)
	end


	if trigger.misc.getUserFlag(205) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Le Havre')
		local zntgt = bc:getZoneByName('Fecamp')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Fecamp is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Le Havre is not Red zone'
            end
		trigger.action.setUserFlag(205, 0)
	end


	if trigger.misc.getUserFlag(206) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Le Havre')
		local zntgt = bc:getZoneByName('Rouen')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Rouen is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Le Havre is not Red zone'
            end
		trigger.action.setUserFlag(206, 0)
	end

	if trigger.misc.getUserFlag(207) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Paris')
		local zntgt = bc:getZoneByName('Fecamp')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Fecamp is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Paris is not Red zone'
            end
		trigger.action.setUserFlag(207, 0)
	end

	if trigger.misc.getUserFlag(208) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Paris')
		local zntgt = bc:getZoneByName('Saint-Aubain')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Saint-Aubain is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Paris is not Red zone'
            end
		trigger.action.setUserFlag(208, 0)
	end

	if trigger.misc.getUserFlag(209) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Dunkirk-Port')
		local zntgt = bc:getZoneByName('Calais')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Fecamp is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Amiens is not Red zone'
            end
		trigger.action.setUserFlag(209, 0)
	end

	if trigger.misc.getUserFlag(210) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Abbeville')
		local zntgt = bc:getZoneByName('Amiens')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Amiens is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Abbeville is not Red zone'
            end
		trigger.action.setUserFlag(210, 0)
	end


	if trigger.misc.getUserFlag(211) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Abbeville')
		local zntgt = bc:getZoneByName('Le Touquet')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Le Touquet is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Abbeville is not Red zone'
            end
		trigger.action.setUserFlag(211, 0)
	end

	if trigger.misc.getUserFlag(211) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Calais')
		local zntgt = bc:getZoneByName('Dinkirk-Port')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Dinkirk-Port is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Calais is not Red zone'
            end
		trigger.action.setUserFlag(211, 0)
	end

	if trigger.misc.getUserFlag(212) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Paris')
		local zntgt = bc:getZoneByName('Orly')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Orly is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Paris is not Red zone'
            end
		trigger.action.setUserFlag(212, 0)
	end

	if trigger.misc.getUserFlag(213) == 1 then
		--trigger.action.outText("Falg Valognes = 1 trigg ", 10)
		local znsrc = bc:getZoneByName('Le Havre')
		local zntgt = bc:getZoneByName('Rouen')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
				else
					return 'Rouen is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				return 'Le Havre is not Red zone'
            end
		trigger.action.setUserFlag(213, 0)
	end



---------------------------------------------------------------------
	if trigger.misc.getUserFlag("cap") == 1 then
	  if not anyGroupAlive("f16cap") then
		destroyF16capGroups()
	  trigger.action.setUserFlag("cap", false)
	  end
	end

	if trigger.misc.getUserFlag("cas") == 1 then
	  if not anyGroupAlive("cas") then
		destroyCasGroups()
		trigger.action.setUserFlag("cas", false)
	  end
	end

	if trigger.misc.getUserFlag("decoy") == 1 then
	  if not anyGroupAlive("decoy") then
		destroydecoyGroups()
		trigger.action.setUserFlag("decoy", false)
	  end
	end

	if trigger.misc.getUserFlag("sead") == 1 then
	  if not anyGroupAlive("sead") then
		destroySeadGroups()
		trigger.action.setUserFlag("sead", false)
	  end
	end
end
timer.scheduleFunction(function()
    checkZoneFlags()
    return timer.getTime() + 30
end, {}, timer.getTime() + 2)
