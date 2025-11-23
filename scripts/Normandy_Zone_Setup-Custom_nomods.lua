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
	-- CarrierEssexUpgrades = {
	-- 	blue = {"CarrierEssexSeaman"},
	-- 	red = {}
	-- },
    CarrierUpgrades = {
        blue = {"CarrierGroup-Chase", "CarrierGroup-LST",},
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
        blue = {"UK-INF-MK1", "UK-ARMOR", "UK-AAA-OPTFLAK", "UK-TRUCK", "UK-AAA-bofors", "UK-ART-FHM2A1"},
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
	Hidden_UK_supply = {
		blue = {"UK_Tug"},
		red = {}
	},
	Hidden_AXE_supply = {
		blue = {},
		red = {"AXE_Tug"}
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




-- Setup the file path for pesistent status saving
local filepath = 'foothold_normandy_nomods_1.0.lua'
if lfs then 
	local dir = lfs.writedir()..'Missions/Saves/'
	lfs.mkdir(dir)
	filepath = dir..filepath
	env.info('Foothold - Save file path: '..filepath)
end
bc = BattleCommander:new(filepath, 10, 60)
if RankingSystem then
bc.rankFile = (lfs and (lfs.writedir()..'Missions/Saves/Foothold_Ranks.lua')) or 'Foothold_Ranks.lua'
env.info('Foothold - Rank file path: '..bc.rankFile)
end
Hunt = true

zones = {
    BigginHill = ZoneCommander:new({zone='BigginHill', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.BigginHill}),
	Odiham = ZoneCommander:new({zone='Odiham', side=2, level=20, upgrades=upgrades.airfieldUK2, crates={}, flavorText=flavor.Odiham}),
	Farnborough = ZoneCommander:new({zone='Farnborough', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Farnborough}),
	Manston = ZoneCommander:new({zone='Manston', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Manston}),
	Dover = ZoneCommander:new({zone='Dover', side=0, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Dover, income=1}),
	Hawkinge = ZoneCommander:new({zone='Hawkinge', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Hawkinge}),
	Lympne = ZoneCommander:new({zone='Lympne', side=2, level=20, upgrades=upgrades.airfieldUK2, crates={}, flavorText=flavor.Lympne}),
	Chailey = ZoneCommander:new({zone='Chailey', side=2, level=20, upgrades=upgrades.airfieldUK2, crates={}, flavorText=flavor.Chailey}),
	Ford = ZoneCommander:new({zone='Ford', side=0, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Ford}),
	Tangmere = ZoneCommander:new({zone='Tangmere', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Tangmere}),
	Funtington = ZoneCommander:new({zone='Funtington', side=2, level=20, upgrades=upgrades.airfieldUK2, crates={}, flavorText=flavor.Funtington}),
	NeedsOarPoint = ZoneCommander:new({zone='Needs Oar Point', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.NeedsOarPoint}),
	Friston = ZoneCommander:new({zone='Friston', side=2, level=20, upgrades=upgrades.airfieldUK1, crates={}, flavorText=flavor.Friston}),
	Dunkirk = ZoneCommander:new({zone='Dunkirk', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Dunkirk}),
	DunkirkPort = ZoneCommander:new({zone='Dunkirk-Port', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.DunkirkPort, income=1}),
	SaintOmer = ZoneCommander:new({zone='Saint-Omer', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.SaintOmer}),
	Merville = ZoneCommander:new({zone='Merville', side=0, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Merville}),
	Abbeville = ZoneCommander:new({zone='Abbeville', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Abbeville}),
	Amiens = ZoneCommander:new({zone='Amiens', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Amiens}),
	Cherbourg = ZoneCommander:new({zone='Cherbourg', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Cherbourg, income=1}),
	Calais = ZoneCommander:new({zone='Calais', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Calais, income=1}),
	SaintAubain = ZoneCommander:new({zone='Saint-Aubain', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.SaintAubain}),
	Fecamp = ZoneCommander:new({zone='Fecamp', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Fecamp}),
	LeHavre = ZoneCommander:new({zone='Le Havre', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.LeHavre, income=1}),
	Rouen = ZoneCommander:new({zone='Rouen', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Rouen}),
	Carpiquet = ZoneCommander:new({zone='Carpiquet', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Carpiquet}),
	Caen = ZoneCommander:new({zone='Caen', side=0, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Caen, income=1}),
	SainteCroix = ZoneCommander:new({zone='Sainte-Croix', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.SainteCroix}),
	SaintPierre = ZoneCommander:new({zone='Saint-Pierre', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.SaintPierre}),
	LonguesSurMer = ZoneCommander:new({zone='Longues-Sur-Mer', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.LonguesSurMer}),
	Cricqueville = ZoneCommander:new({zone='Cricqueville', side=1, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Cricqueville}),
	LeMolay = ZoneCommander:new({zone='Le Molay', side=0, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.LeMolay}),
	Brucheville = ZoneCommander:new({zone='Brucheville', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Brucheville}),
	Valognes = ZoneCommander:new({zone='Valognes', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Valognes}),
	Maupertus = ZoneCommander:new({zone='Maupertus', side=1, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.Maupertus}),
	Bernay = ZoneCommander:new({zone='Bernay', side=0, level=20, upgrades=upgrades.airfieldFR2, crates={}, flavorText=flavor.Bernay}),
	SaintAndre = ZoneCommander:new({zone='Saint-Andre', side=0, level=20, upgrades=upgrades.airfieldFR1, crates={}, flavorText=flavor.SaintAndre}),
	CarrierGroup = ZoneCommander:new({zone='CarrierGroup', side=2, level=20, upgrades=upgrades.CarrierUpgrades, crates={}, flavorText=flavor.CarrierGroup}),
	--hiddenCarrierEssex = ZoneCommander:new({zone='HiddenCarrierEssex', side=2, level=20, upgrades=upgrades.CarrierEssexUpgrades}),
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

	hiddenUKNavalbasePortsmouth = ZoneCommander:new({zone='HiddenUKNavalbasePortsmouth', side=2, level=20, upgrades=upgrades.Hidden_UK_supply}),
	hiddenUKNavalbaseDover = ZoneCommander:new({zone='HiddenUKNavalbaseDover', side=2, level=20, upgrades=upgrades.Hidden_UK_supply}),
	hiddenAXENavalbaseCherbourg = ZoneCommander:new({zone='HiddenAXENavalbaseCherbourg', side=1, level=20, upgrades=upgrades.Hidden_AXE_supply}),
	hiddenAXENavalbaseDieppe = ZoneCommander:new({zone='HiddenAXENavalbaseDieppe', side=1, level=20, upgrades=upgrades.Hidden_AXE_supply}),
	hiddenAXENavalbaseLeHavre = ZoneCommander:new({zone='HiddenAXENavalbaseLeHavre', side=1, level=20, upgrades=upgrades.Hidden_AXE_supply}),
	hiddenAXENavalbaseDunkirk = ZoneCommander:new({zone='HiddenAXENavalbaseDunkirk', side=1, level=20, upgrades=upgrades.Hidden_AXE_supply}),
	-- hiddenRailwayLondonVictoriaStation = ZoneCommander:new({zone='HiddenRailwayLondonVictoriaStation', side=2, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayWaterlooStation = ZoneCommander:new({zone='HiddenRailwayWaterlooStation', side=2, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayLondonBridgeStation = ZoneCommander:new({zone='HiddenRailwayLondonBridgeStation', side=2, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayDover = ZoneCommander:new({zone='HiddenRailwayDover', side=0, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayFord = ZoneCommander:new({zone='HiddenRailwayFord', side=2, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayHawkinge = ZoneCommander:new({zone='HiddenRailwayHawkinge', side=2, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayCherbourg = ZoneCommander:new({zone='HiddenRailwayCherbourg', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayValognes = ZoneCommander:new({zone='HiddenRailwayValognes', side=0, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayCaen = ZoneCommander:new({zone='HiddenRailwayCaen', side=0, level=20, upgrades=upgrades.empty}),
	-- hiddenTrainDepotValognes = ZoneCommander:new({zone='HiddenTrainDepotValognes', side=0, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayLeHavre = ZoneCommander:new({zone='HiddenRailwayLeHavre', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayBernay = ZoneCommander:new({zone='HiddenRailwayBernay', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwaySaintAndre = ZoneCommander:new({zone='HiddenRailwaySaintAndre', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayOrly = ZoneCommander:new({zone='HiddenRailwayOrly', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayParisSaintLazare = ZoneCommander:new({zone='HiddenRailwayParisSaintLazare', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayParisGareDuNord = ZoneCommander:new({zone='HiddenRailwayParisGareDuNord', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayParisGareDeLest = ZoneCommander:new({zone='HiddenRailwayParisGareDeLest', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayFecamp = ZoneCommander:new({zone='HiddenRailwayFecamp', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayPowerplantFecamp = ZoneCommander:new({zone='HiddenRailwayPowerplantFecamp', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayDepotRouen = ZoneCommander:new({zone='HiddenRailwayDepotRouen', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayRouen = ZoneCommander:new({zone='HiddenRailwayRouen', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayDepotSaintAubain = ZoneCommander:new({zone='HiddenRailwayDepotSaintAubain', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayTrainDepotAmiens = ZoneCommander:new({zone='HiddenRailwayTrainDepotAmiens', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayAbbeville = ZoneCommander:new({zone='HiddenRailwayAbbeville', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayDunkirkPort = ZoneCommander:new({zone='HiddenRailwayDunkirkPort', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayLeTouquet = ZoneCommander:new({zone='HiddenRailwayLeTouquet', side=1, level=20, upgrades=upgrades.empty}),
	-- hiddenRailwayCalais = ZoneCommander:new({zone='HiddenRailwayCalais', side=1, level=20, upgrades=upgrades.empty}),
}

-- Railway subzone to parent zone mapping
-- This defines which railway subzones are contained within which parent zones
-- RAILWAY_SUBZONE_MAPPING = {
--     ["hiddenRailwayFord"] = "Ford",           -- hiddenRailwayFord subzone is inside Ford zone
--     ["hiddenRailwayCherbourg"] = "Cherbourg", -- hiddenRailwayCherbourg subzone is inside Cherbourg zone
-- 	["hiddenRailwayValognes"] = "Valognes",   -- hiddenRailwayValognes subzone is inside Valognes zone
-- 	["hiddenTrainDepotValognes"] = "Valognes", -- hiddenTrainDepotValognes subzone is inside Valognes zone
-- 	["hiddenRailwayCaen"] = "Caen",           -- hiddenRailwayCaen subzone is inside Caen zone
-- 	["hiddenRailwayLeHavre"] = "LeHavre",     -- hiddenRailwayLeHavre subzone is inside LeHavre zone
-- 	["hiddenRailwayBernay"] = "Bernay",       -- hiddenRailwayBernay subzone is inside Bernay zone
-- 	["hiddenRailwaySaintAndre"] = "SaintAndre", -- hiddenRailwaySaintAndre subzone is inside SaintAndre zone
-- 	["hiddenRailwayOrly"] = "Orly",           -- hiddenRailwayOrly subzone is inside Orly zone
-- 	["hiddenRailwayParisSaintLazare"] = "Paris", -- hiddenRailwayParisSaintLazare subzone is inside Paris zone
-- 	["hiddenRailwayParisGareDuNord"] = "Paris",  -- hiddenRailwayParisGareDuNord subzone is inside Paris zone
-- 	["hiddenRailwayParisGareDeLest"] = "Paris",  -- hiddenRailwayParisGareDeLest subzone is inside Paris zone
-- 	["hiddenRailwayFecamp"] = "Fecamp",           -- hiddenRailwayFecamp subzone is inside Fecamp zone
-- 	["hiddenRailwayPowerplantFecamp"] = "Fecamp", -- hiddenRailwayPowerplantFecamp subzone is inside Fecamp zone
-- 	["hiddenRailwayDepotRouen"] = "Rouen",             -- hiddenRailwayDepotRouen subzone is inside Rouen zone
-- 	["hiddenRailwayDepotSaintAubain"] = "SaintAubain", -- hiddenRailwayDepotSaintAubain subzone is inside SaintAubain zone
-- 	["hiddenRailwayTrainDepotAmiens"] = "Amiens",     -- hiddenRailwayTrainDepotAmiens subzone is inside Amiens zone
-- 	["hiddenRailwayAbbeville"] = "Abbeville",         -- hiddenRailwayAbbeville subzone is inside Abbeville zone
-- 	["hiddenRailwayDunkirkPort"] = "DunkirkPort",   -- hiddenRailwayDunkirkPort subzone is inside DunkirkPort zone
-- 	["hiddenRailwayLeTouquet"] = "LeTouquet",       -- hiddenRailwayLeTouquet subzone is inside LeTouquet zone
-- 	["hiddenRailwayCalais"] = "Calais",             -- hiddenRailwayCalais subzone is inside Calais zone


-- }


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



CapPlaneTemplate = CapPlaneTemplate or {
	'AXECapFw190D9Template',
	'AXECapBf109Template',
	'UKCapP51Template',
	'UKCapSpitFireTemplate',
}
-- HeloSupplyTemplate = HeloSupplyTemplate or {
--     'RED_MI-8',
--     'BLUE_CH-47',
--     'BLUE_UH-60A',
-- }
CasPlaneTemplate = CasPlaneTemplate or {
	'AXECasJU88Template',
	'UKCasP47Template',
	'UKCasMosquitoTemplate',
	'UKCasA20Template',
	'UKCasF4UDTemplate',
}
-- SeadPlaneTemplate = SeadPlaneTemplate or {
--     'RED_JF17_ONESHIP',
--     'RED_JF17_TWOSHIP',
--     'RED_SU25T_ONESHIP',
--     'RED_SU25T_TWOSHIP',
--     'RED_SU-34_ONESHIP',
--     'RED_SU-34_TWOSHIP',
--     'RED_SU-24M_TWOSHIP',
--     'RED_SU-24M_ONESHIP',
-- 	'BLUE_HORNET_SEAD',
	
-- }
-- CasHeloTemplate = CasHeloTemplate or {
--     'RED_Mi-24P_ONESHIP',
--     'RED_Mi-24P_TWOSHIP',
--     'RED_M-28N_ONESHIP',
--     'RED_M-28N_TWOSHIP',
--     'BLUE_AH-64D_ONESHIP',
--     'BLUE_AH-64D_TWOSHIP',
--     'BLUE_AH-1W',
--     'BLUE_SA342M',
-- }
-- AttackConvoy = AttackConvoy or {
--     "AttackConvoy 1",
--     "AttackConvoy 2",
--     "AttackConvoy 3",
--     "AttackConvoy 4",
-- }

CapCarrierGroup = CapCarrierGroup or {
	'UKCapF4UDTemplate',
}
-- SeadCarrierGroup = SeadCarrierGroup or {
--     'BLUE_HORNET_SEAD',
-- }

RunwayStrikePlaneTemplate = RunwayStrikePlaneTemplate or {
	"UKCasMosquitoTemplate",
	"AXERunwayJU88Template",
}



SupplyConvoy = SupplyConvoy or {
    "AxeConvoySupplyTemplate",
    "UKConvoySupplyTemplate",
}

SupplyPlaneTemplate = SupplyPlaneTemplate or {
	"AxeC47SupplyTemplate",
	"UKC47SupplyTemplate",
}

SupplyNavalTemplate = SupplyNavalTemplate or {
	"AxeNavalSupplyTemplate",
	"UKNavalSupplyTemplate",
}
AntiShipPlaneTemplate = AntiShipPlaneTemplate or {
	"UKAntiShipF4UDTemplate",
	"UKAntishipP47Template",
	"AXEAntiShipFw190D9Template",
	"AXEAntishipJU88Template",
	
}

BattleshipTemplate = BattleshipTemplate or {
	"AXEBattleshipTemplate",
	"UKBattleshipTemplate",
}
function CasAltitude() return math.random(5,15)*1000 end
function CapAltitude() return math.random(15,20)*1000 end
--function SeadAltitude() return math.random(25,33)*1000 end
function RunwayStrikeAltitude() return math.random(23,28)*1000 end



zones.Amiens:addGroups({
    --GroupCommander:new({name='AXE_Amiens-resupply-Abbeville', mission='supply', targetzone='Abbeville', type = 'surface'}),
    --GroupCommander:new({name='AXE_Amiens-resupply-Fecamp', mission='supply', targetzone='Fecamp', type = 'surface'}),
	GroupCommander:new({name='AXE_Amiens-attack-Chailey', mission='attack', template='RunwayStrikePlaneTemplate', MissionType='RUNWAYSTRIKE', targetzone='Chailey', Altitude = RunwayStrikeAltitude()}),
})
zones.Abbeville:addGroups({
    --GroupCommander:new({name='AXE_Abbeville-resupply-Amiens', mission='supply', targetzone='Amiens', type = 'surface'}),
	GroupCommander:new({name='AXE_Abbeville-patrol-LeTouquet', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Le Touquet', Altitude = CapAltitude()}),
	--GroupCommander:new({name='AXE_Abbeville-resupply-SaintAubain', mission='supply', targetzone='Saint-Aubain', type = 'surface'}),
})
zones.Bernay:addGroups({
    --GroupCommander:new({name='AXE_Bernay-resupply-SaintAndre', mission='supply', targetzone='SaintAndre', type = 'surface'}),
	GroupCommander:new({name='AXE_Bernay-resupply-Caen', mission='supply', targetzone='Caen', type = 'surface'}),
})
zones.Caen:addGroups({
    GroupCommander:new({name='AXE_Caen-resupply-SainteCroix', mission='supply', template='SupplyConvoy', targetzone='Sainte-Croix', type = 'surface'}),
    GroupCommander:new({name='AXE_Caen-resupply-Carpiquet', mission='supply', template='SupplyConvoy', targetzone='Carpiquet', type = 'surface'}),
    --GroupCommander:new({name='AXE_Caen-resupply-LeMolay', mission='supply', targetzone='LeMolay', type = 'surface'}),
})
zones.Calais:addGroups({
    --GroupCommander:new({name='AXE_Calais-resupply-DunkirkPort', mission='supply', targetzone='DunkirkPort', type = 'surface'}),
})
zones.Carpiquet:addGroups({
	GroupCommander:new({name='AXE_Carpiquet-attack-Ford', mission='attack', template='CasPlaneTemplate', MissionType='CAS', targetzone='Ford', Altitude = CasAltitude()}),

})
zones.Cherbourg:addGroups({
    GroupCommander:new({name='AXE_Cherbourg-resupply-Maupertus', mission='supply', template='SupplyConvoy', targetzone='Maupertus', type = 'surface'}),
})

zones.Dunkirk:addGroups({
	GroupCommander:new({name='AXE_Dunkirk-resupply-Calais', mission='supply', template='SupplyConvoy', targetzone='Calais', type = 'surface'}),
    GroupCommander:new({name='AXE_Dunkirk-patrol-Calais', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Calais'}),
})
zones.DunkirkPort:addGroups({
	GroupCommander:new({name='AXE_DunkirkPort-resupply-LeHavre', mission='supply', template='SupplyNavalTemplate', targetzone='Le Havre', type = 'surface'}),
    GroupCommander:new({name='AXE_DunkirkPort-resupply-Dunkirk', mission='supply', template='SupplyConvoy', targetzone='Dunkirk', type = 'surface'}),
    GroupCommander:new({name='AXE_DunkirkPort-resupply-SaintOmer', mission='supply', template='SupplyConvoy', targetzone='Saint-Omer', type = 'surface'}),

})
zones.Fecamp:addGroups({
    --GroupCommander:new({name='AXE_Fecamp-resupply-LeHavre', mission='supply', targetzone='Le Havre', type = 'surface'}),
	GroupCommander:new({name='AXE_Fecamp-patrol-LeHavre', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Le Havre', Altitude = CapAltitude()}),
	GroupCommander:new({name='UK_Manston-attack-CarrierGroup', mission='attack', template='AntiShipPlaneTemplate', MissionType='ANTISHIP', targetzone='CarrierGroup', Altitude = CasAltitude()}),

})
zones.Maupertus:addGroups({
	GroupCommander:new({name='AXE_Maupertus-patrol-Cherbourg', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Cherbourg', Altitude = CapAltitude()}),
	GroupCommander:new({name='AXE_Maupertus-attack-NeedsOarPoint', mission='attack', template='CasPlaneTemplate', MissionType='CAS', targetzone='Needs Oar Point', Altitude = CasAltitude()}),
	GroupCommander:new({name='AXE_Maupertus-attack-CarrierGroup', mission='attack', template='CasPlaneTemplate', MissionType='CAS', targetzone='CarrierGroup', Altitude = CasAltitude()}),

})

zones.Merville:addGroups({
    GroupCommander:new({name='AXE_Merville-resupply-SaintOmer', mission='supply', template='SupplyConvoy', targetzone='Saint-Omer', type = 'surface'}),
	GroupCommander:new({name='AXE_Merville-attack-BigginHill', mission='attack', template='RunwayStrikePlaneTemplate', MissionType='RUNWAYSTRIKE', targetzone='BigginHill', Altitude = RunwayStrikeAltitude()}),
})

zones.LeHavre:addGroups({
    --GroupCommander:new({name='AXE_LeHavre-resupply-Fecamp', mission='supply', targetzone='Fecamp', type = 'surface'}),
    --GroupCommander:new({name='AXE_LeHavre-resupply-Rouen', mission='supply', targetzone='Rouen', type = 'surface'}),
})
zones.LeMolay:addGroups({
    GroupCommander:new({name='AXE_LeMolay-resupply-Cricqueville', mission='supply', template='SupplyConvoy', targetzone='Cricqueville', type = 'surface'}),
	GroupCommander:new({name='AXE_LeMolay-resupply-LonguesSurMer', mission='supply', template='SupplyConvoy', targetzone='Longues-Sur-Mer', type = 'surface'}),
	GroupCommander:new({name='AXE_LeMolay-resupply-SaintPierreDuMont', mission='supply', template='SupplyConvoy', targetzone='Saint-Pierre', type = 'surface'}),
	--GroupCommander:new({name='AXE_LeMolay-patrol-SainteCroix', mission='patrol', targetzone='Sainte-Croix'}),
	--GroupCommander:new({name='AXE_LeMolay-patrol-SaintPierre', mission='patrol', targetzone='Saint-Pierre'}),
	GroupCommander:new({name='AXE_LeMolay-patrol-Caen', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Caen', Altitude = CapAltitude()}),
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
    GroupCommander:new({name='AXE_SaintAubain-patrol-Rouen', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Rouen', Altitude = CapAltitude()}),
	-- GroupCommander:new({name='AXE_SaintAubain-resupply-AxeCarrierGroup', mission='supply', template='SupplyNavalTemplate', targetzone='AxeCarrierGroup', type = 'surface'}),
})

zones.SainteCroix:addGroups({
    --GroupCommander:new({name='AXE_SainteCroix-resupply-Caen', mission='supply', targetzone='Caen', type = 'surface'}),
})
zones.SaintOmer:addGroups({
    --GroupCommander:new({name='AXE_SaintOmer-resupply-Merville', mission='supply', targetzone='Merville', type = 'surface'}),
})
zones.Valognes:addGroups({
    GroupCommander:new({name='AXE_Valognes-resupply-Brucheville', mission='supply', template='SupplyConvoy', targetzone='Brucheville', type = 'surface'}),
    --GroupCommander:new({name='AXE_Valognes-resupply-LeMolay', mission='supply', targetzone='Le Molay', type = 'surface'}),
})
zones.BigginHill:addGroups({
    GroupCommander:new({name='UK_BigginHill-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
    GroupCommander:new({name='UK_BigginHill-resupply-Dover', mission='supply', targetzone='Dover', type = 'surface'}),
	GroupCommander:new({name='UK_BigginHill-resupply-Friston', mission='supply', targetzone='Friston', type = 'surface'}),
	GroupCommander:new({name='UK_BigginHill-resupply-Chailey', mission='supply', targetzone='Chailey', type = 'surface'}),
	GroupCommander:new({name='UK_BigginHill-resupply-Calais', mission='supply', targetzone='Calais', type = 'surface'}),
	GroupCommander:new({name='UK_BigginHill-attack-LeHavre', mission='attack', template='CasPlaneTemplate', MissionType='CAS', targetzone='Le Havre', Altitude = CasAltitude()}),
	--GroupCommander:new({name='UK_BigginHill-attack-LeHavre-escort', mission='escort', targetzone='Le Havre', type = 'air'}),
	GroupCommander:new({name='UK_BigginHill-attack-DunkirkPort', mission='attack', template='CasPlaneTemplate', MissionType='CAS', targetzone='Dunkirk-Port', Altitude = CasAltitude()}),
	--GroupCommander:new({name='UK_BigginHill-attack-DunkirkPort-escort', mission='escort', targetzone='Dunkirk-Port', type = 'air'}),
	GroupCommander:new({name='UK_BigginHill-patrol-Friston', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Friston', Altitude = CapAltitude()}),

})
zones.Farnborough:addGroups({
    GroupCommander:new({name='UK_Farnborough-resupply-BigginHill', mission='supply', targetzone='BigginHill', type = 'surface'}),
    GroupCommander:new({name='UK_Farnborough-resupply-Odiham', mission='supply', template='SupplyConvoy', targetzone='Odiham', type = 'surface'}),
	GroupCommander:new({name='UK_Farnborough-resupply-Ford', mission='supply', targetzone='Ford', type = 'surface', urgent = function() return zones.Ford.side == 0 end, ForceUrgent = true}),
    GroupCommander:new({name='UK_Farnborough-resupply-NeedsOarPoint', mission='supply', targetzone='Needs Oar Point', type = 'surface'}),
	GroupCommander:new({name='UK_Farnborough-attack-Caen', mission='attack', template='CasPlaneTemplate', MissionType='CAS', targetzone='Caen', Altitude = CasAltitude()}),
	--GroupCommander:new({name='UK_Farnborough-attack-Caen-escort', mission='escort', targetzone='Caen', type = 'air'}),
})

zones.Dover:addGroups({
	GroupCommander:new({name='UK_Dover-resupply-Hawkinge', mission='supply', template='SupplyConvoy', targetzone='Hawkinge', type = 'surface'}),
	-- GroupCommander:new({name='UK_Dover-capture-AxeCarrierGroup', mission='supply', template='SupplyNavalTemplate', targetzone='AxeCarrierGroup', type='surface', condition = function() return zones.Dover.active end, urgent = function() return zones.AxeCarrierGroup.side == 0 end, ForceUrgent = true}),
	-- GroupCommander:new({name='UK_Dover-capture-DunkirkPort', mission='supply', template='SupplyNavalTemplate', targetzone='Dunkirk-Port', type='surface', condition = function() return zones.Dover.active end, urgent = function() return zones.DunkirkPort.side == 0 end, ForceUrgent = true}),
    -- GroupCommander:new({name='UK_Dover-capture-Calais', mission='supply', template='SupplyNavalTemplate', targetzone='Calais', type = 'surface', condition = function() return zones.Dover.active end, urgent = function() return zones.Calais.side == 0 end, ForceUrgent = true}),
	-- GroupCommander:new({name='UK_Dover-supply-CarrierGroup', mission='supply', template='SupplyNavalTemplate', targetzone='CarrierGroup', type='surface'}),

})

zones.Hawkinge:addGroups({
	GroupCommander:new({name='UK_Hawkinge-resupply-Lympne', mission='supply', template='SupplyConvoy', targetzone='Lympne', type = 'surface'}),
	--GroupCommander:new({name='UK_Hawkinge-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})

zones.Ford:addGroups({
	GroupCommander:new({name='UK_Ford-resupply-Tangmere', mission='supply', template='SupplyConvoy', targetzone='Tangmere', type = 'surface'}),
	--GroupCommander:new({name='UK_Ford-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})
zones.Funtington:addGroups({
	GroupCommander:new({name='UK_Funtington-attack-Cherbourg', mission='attack', template='CasPlaneTemplate', MissionType='CAS', targetzone='Cherbourg', Altitude = CasAltitude()}),
	--GroupCommander:new({name='UK_Funtington-attack-Cherbourg-escort', mission='escort', targetzone='Cherbourg'}),
	--GroupCommander:new({name='UK_Ford-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})
zones.Tangmere:addGroups({
	GroupCommander:new({name='UK_Tangmere-resupply-Funtington', mission='supply', template='SupplyConvoy', targetzone='Funtington', type = 'surface'}),
	--GroupCommander:new({name='UK_Ford-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})
zones.Chailey:addGroups({
	GroupCommander:new({name='UK_Chailey-resupply-Friston', mission='supply', template='SupplyConvoy', targetzone='Friston', type = 'surface'}),
	GroupCommander:new({name='UK_Chailey-patrol-Friston', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Friston', Altitude = CapAltitude()}),
	
})
zones.London:addGroups({
    GroupCommander:new({name='UK_London-resupply-BigginHill', mission='supply', template='SupplyConvoy', targetzone='BigginHill', type = 'surface'}),
    --GroupCommander:new({name='UK_London-resupply-Farnborough', mission='supply', targetzone='Farnborough', type = 'surface'}),
    --GroupCommander:new({name='UK_London-resupply-Ford', mission='supply', targetzone='Ford', type = 'surface'}),
    --GroupCommander:new({name='UK_London-resupply-Manston', mission='supply', targetzone='Manston', type = 'surface'}),
})
zones.Manston:addGroups({
	GroupCommander:new({name='UK_Manston-patrol-Dover', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Dover', Altitude = CapAltitude()}),
    GroupCommander:new({name='UK_Manston-resupply-DunkirkPort', mission='supply', targetzone='Dunkirk-Port', type = 'surface'}),
	GroupCommander:new({name='UK_Manston-attack-AxeCarrierGroup', mission='attack', template='AntiShipPlaneTemplate', MissionType='ANTISHIP', targetzone='AxeCarrierGroup', Altitude = CasAltitude()}),

	--GroupCommander:new({name='UK_Manston-resupply-Hawkinge', mission='supply', targetzone='Hawkinge', type = 'surface'}),
	--GroupCommander:new({name='UK_Manston-resupply-Lympne', mission='supply', targetzone='Lympne', type = 'surface'}),
})	
zones.NeedsOarPoint:addGroups({
	--GroupCommander:new({name='UK_NeedsOarPoint-resupply-Farnborough', mission='supply', targetzone='Farnborough', type = 'surface'}),
	GroupCommander:new({name='UK_NeedsOarPoint-patrol-Ford', mission='patrol', template='CapPlaneTemplate', MissionType='CAP', targetzone='Ford', Altitude = CapAltitude()}),
	
})
zones.Odiham:addGroups({
	GroupCommander:new({name='UK_Odiham-resupply-Cherbourg', mission='supply', targetzone='Cherbourg', type = 'surface'}),
	GroupCommander:new({name='UK_Odiham-resupply-Caen', mission='supply', targetzone='Caen', type = 'surface'}),
	--GroupCommander:new({name='UK_Odiham-resupply-BigginHill', mission='supply', targetzone='BigginHill', type = 'surface'}),
})


zones.hiddenAXENavalbaseCherbourg:addGroups({
	GroupCommander:new({name='AXE_hiddenAXENavalbaseCherbourg-resupply-LeHavre', mission='supply', template='SupplyNavalTemplate', targetzone='Le Havre', type = 'surface', condition = function() return zones.Cherbourg.active end}),
})
zones.hiddenAXENavalbaseLeHavre:addGroups({
	GroupCommander:new({name='AXE_hiddenAXENavalbaseLeHavre-resupply-DunkirkPort', mission='supply', template='SupplyNavalTemplate', targetzone='Dunkirk-Port', type = 'surface'}),
	GroupCommander:new({name='AXE_NavalbaseLeHavre-attack-CarrierGroup', mission='attack', template='BattleshipTemplate', MissionType='BATTLESHIP', targetzone='CarrierGroup', type = 'surface', condition = function() return zones.LeHavre.active end}),
})
zones.hiddenAXENavalbaseDieppe:addGroups({
	GroupCommander:new({name='AXE_hiddenAXENavalbaseDieppe-resupply-AxeCarrierGroup', mission='supply', template='SupplyNavalTemplate', targetzone='AxeCarrierGroup', type = 'surface', condition = function() return zones.SaintAubain.active end}),
})

zones.hiddenUKNavalbasePortsmouth:addGroups({
	GroupCommander:new({name='UK_hiddenUKNavalbasePortsmouth-resupply-CarrierGroup', mission='supply', template='SupplyNavalTemplate', targetzone='CarrierGroup', type = 'surface', urgent = function() return zones.CarrierGroup.side == 0 end, ForceUrgent = true}),
})

zones.hiddenUKNavalbaseDover:addGroups({
	GroupCommander:new({name='UK_hiddenUKNavalbaseDover-capture-AxeCarrierGroup', mission='supply', template='SupplyNavalTemplate', targetzone='AxeCarrierGroup', type='surface', condition = function() return zones.Dover.active end, urgent = function() return zones.AxeCarrierGroup.side == 0 end, ForceUrgent = true}),
	GroupCommander:new({name='UK_hiddenUKNavalbaseDover-capture-DunkirkPort', mission='supply', template='SupplyNavalTemplate', targetzone='Dunkirk-Port', type='surface', condition = function() return zones.Dover.active end, urgent = function() return zones.DunkirkPort.side == 0 end, ForceUrgent = true}),
    GroupCommander:new({name='UK_hiddenUKNavalbaseDover-capture-Calais', mission='supply', template='SupplyNavalTemplate', targetzone='Calais', type = 'surface', condition = function() return zones.Dover.active end, urgent = function() return zones.Calais.side == 0 end, ForceUrgent = true}),
	GroupCommander:new({name='UK_hiddenUKNavalbaseDover-supply-CarrierGroup', mission='supply', template='SupplyNavalTemplate', targetzone='CarrierGroup', type='surface', condition = function() return zones.Dover.active end}),
	GroupCommander:new({name='UK_hiddenUKNavalbaseDover-attack-DunkirkPort', mission='attack', template='BattleshipTemplate', targetzone='Dunkirk-Port', type='surface', condition = function() return zones.Dover.active end}),
	
})

zones.hiddenAXENavalbaseDunkirk:addGroups({
	GroupCommander:new({name='AXE_hiddenAXENavalbaseDunkirk-resupply-Cherbourg', mission='supply', template='SupplyNavalTemplate', targetzone='Cherbourg', type = 'surface'}),
	GroupCommander:new({name='AXE_NavalbaseDunkirk-attack-Dover', mission='attack', template='BattleshipTemplate', MissionType='BATTLESHIP', targetzone='Dover', type = 'surface', condition = function() return zones.DunkirkPort.active end}),
})

zones.AxeCarrierGroup:addGroups({
	GroupCommander:new({name='AXE_AxeCarrierGroup-attack-CarrierGroup', mission='attack', template='BattleshipTemplate', MissionType='BATTLESHIP', targetzone='CarrierGroup', type = 'surface'}),
})
zones.CarrierGroup:addGroups({
	GroupCommander:new({name='UK_CarrierGroup-attack-AxeCarrierGroup', mission='attack', template='BattleshipTemplate', MissionType='BATTLESHIP', targetzone='AxeCarrierGroup', type = 'surface'}),
	GroupCommander:new({name='UK_CarrierGroup-attack-LeHavre', mission='attack', template='BattleshipTemplate', MissionType='BATTLESHIP', targetzone='Le Havre', type = 'surface'}),
	GroupCommander:new({name='UK_CarrierGroup-attack-Cherbourg', mission='attack', template='BattleshipTemplate', MissionType='BATTLESHIP', targetzone='Cherbourg', type = 'surface'}),
	GroupCommander:new({name='UK_CarrierGroup-attack-SainteCroix', mission='attack', template='BattleshipTemplate', MissionType='BATTLESHIP', targetzone='Sainte-Croix', type = 'surface'}),
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
-- synchronizeRailwaySubzones()
-- registerRailwaySubzoneTriggers()
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
bc:addConnectionSupply("Dunkirk-Port","Le Havre")
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

	if zones.Dover.active and zones.DunkirkPort.side == 0 then
		trigger.action.outText("Our ships are standing to capture Dunkirk Port", 15)
		trigger.action.outSoundForCoalition(2, "admin.ogg")
	end

	if zones.Dover.active and zones.Calais.side == 0 then
		trigger.action.outText("Our ships are standing to capture Calais zone", 15)
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
zones.CarrierGroup.airbaseName = "ESSEX"

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
                            SCHEDULER:New(nil,loop,{},2,0)
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
                SCHEDULER:New(nil,loop,{},2,0)
			else
				trigger.action.outTextForCoalition(2,params.zone.zone..' is now fully upgraded!',15)
			end
        end
        loop()
    else
        return'Can only target friendly zone'
    end
end)


-----------------------------------------------DYNAMIC SHOP ------------------------------------------


bc:registerShopItem('dynamiccap', 'Dynamic CAP', 500, function(sender)
    if capActive then
        return 'CAP mission still in progress'
    end
		if capParentMenu then
		return 'Choose spawn zone from F10 menu'
	end
    buildCapMenu()
	trigger.action.outTextForCoalition(2, 'CAP is requested. Select spawn zone.', 10)
    return
end,
function (sender, params)
    if capActive then
        return 'CAP mission still in progress'
    end
    buildCapMenu()

	trigger.action.outTextForCoalition(2, 'CAP is requested. Select spawn zone.', 10)
    return
end)

bc:registerShopItem('dynamicarco', 'Dynamic Tanker (Drogue)', 100, function(sender)
    if ArcoActive then
        return 'Arco is still airborne'
    end
		if ArcoParentMenu then
		return 'Choose spawn zone from F10 menu'
	end
    buildArcoMenu()
	trigger.action.outTextForCoalition(2, 'Tanker (Drogue) is requested. Select spawn zone.', 10)
    return
end,
function (sender, params)
    if ArcoActive then
        return 'Arco is still airborne'
    end
    buildArcoMenu()

	trigger.action.outTextForCoalition(2, 'Tanker (Drogue) is requested. Select spawn zone.', 10)
    return
end)

bc:registerShopItem('dynamictexaco', 'Dynamic Tanker (Boom)', 100, function(sender)
    if TexacoActive then
        return 'Texaco is still airborne'
    end
		if TexacoParentMenu then
		return 'Choose spawn zone from F10 menu'
	end
    buildTexacoMenu()
	trigger.action.outTextForCoalition(2, 'Tanker (Boom) is requested. Select spawn zone.', 10)
    return
end,
function (sender, params)
    if TexacoActive then
        return 'Texaco is still airborne'
    end
    buildTexacoMenu()

	trigger.action.outTextForCoalition(2, 'Tanker (Boom) is requested. Select spawn zone.', 10)
    return
end)

bc:registerShopItem('dynamiccas', 'Dynamic CAS', 1000,
function(sender)
    if casActive then
        return 'CAS mission still in progress'
    end
	if CASTargetMenu then
		return 'Choose target zone from F10 menu'
	end
    local minNM = 25
    local allow = {}
    for _, z in ipairs(bc:getZones()) do
        if z.side == 1 and findClosestBlueZoneOutside(z.zone, minNM) then
            allow[z.zone] = true
        end
    end
    if not next(allow) then
        trigger.action.outTextForCoalition(2, 'No enemy zone is far enough (>'..minNM..' NM) from the front line.', 10)
        return
    end
    CASTargetMenu = bc:showTargetZoneMenu(2, 'Select CAS Target', function(targetZoneName, menu)
        if casActive then return end
        local spawnZone, dist = findClosestBlueZoneOutside(targetZoneName, minNM)
        if not spawnZone then
            return 'No friendly zone available for CAS spawn '..minNM..'+ NM away'
        end
        local offset = (dist and dist < minNM) and (minNM - dist) or 0
        spawnCasAt(spawnZone, targetZoneName, offset)
        CASTargetMenu = nil
    end, 1, nil, allow)
    trigger.action.outTextForCoalition(2, 'Select CAS target zone from F10', 10)
    return
end,
function(sender, params)
    if params.zone and params.zone.side == 1 then
        if casActive then return 'CAS mission still in progress' end
        local minNM = 25
        local closestBlue, dist = findClosestBlueZoneOutside(params.zone.zone, minNM)
        if not closestBlue then
            return 'No friendly zone available for CAS spawn.'
        end
        local offset = (dist and dist < minNM) and (minNM - dist) or 0
        spawnCasAt(closestBlue, params.zone.zone, offset)
        return
    else
        return 'Can only target enemy zone'
    end
end)

bc:registerShopItem('dynamicdecoy', 'Dynamic Decoy', 300,
function(sender)
    if decoyActive then
        return 'Decoy mission still in progress'
    end
	if DECOYTargetMenu then
		return 'Choose target zone from F10 menu'
	end

    local minNM = 40
    local allow = {}
    for _, z in ipairs(bc:getZones()) do
        if z.side == 1 and findClosestBlueZoneOutside(z.zone, minNM) then
            allow[z.zone] = true
        end
    end
    if not next(allow) then
        trigger.action.outTextForCoalition(2, 'No enemy zone is far enough (>'..minNM..' NM) from the front line.', 10)
        return
    end

    DECOYTargetMenu = bc:showTargetZoneMenu(2, 'Select Decoy Target', function(targetZoneName, menu)
        if decoyActive then return end
        local spawnZone, dist = findClosestBlueZoneOutside(targetZoneName, minNM)
        if not spawnZone then
            trigger.action.outTextForCoalition(2, 'No friendly zone available for Decoy spawn '..minNM..'+ NM away.', 15)
            return
        end
        local offset = (dist and dist < minNM) and (minNM - dist) or 0
        spawnDecoyAt(spawnZone, targetZoneName, offset)
        DECOYTargetMenu = nil
    end, 1, nil, allow)

    trigger.action.outTextForCoalition(2, 'Select Decoy target zone from F10', 10)
    return
end,
function(sender, params)
    if params.zone and params.zone.side == 1 then
        if decoyActive then
            return 'Decoy mission still in progress'
        end
        local minNM = 40
        local closestBlue, dist = findClosestBlueZoneOutside(params.zone.zone, minNM)
        if not closestBlue then
            return 'No friendly zone available for Decoy spawn.'
        end
        local offset = (dist and dist < minNM) and (minNM - dist) or 0
        spawnDecoyAt(closestBlue, params.zone.zone, offset)
        return
    else
        return 'Can only target enemy zone'
    end
end)


bc:registerShopItem('dynamicsead', 'Dynamic SEAD', 500,
function(sender)
    if seadActive then
        return 'SEAD mission still in progress'
    end
	if SEADTargetMenu then
		return 'Choose target zone from F10 menu'
	end

    local minNM = 40
    local allow = {}
    for _, z in ipairs(bc:getZones()) do
        if z.side == 1 and findClosestBlueZoneOutside(z.zone, minNM) then
            allow[z.zone] = true
        end
    end
    if not next(allow) then
        trigger.action.outTextForCoalition(2, 'No enemy zone is far enough (>'..minNM..' NM) from the front line.', 10)
        return
    end

    SEADTargetMenu = bc:showTargetZoneMenu(2, 'Select SEAD Target', function(targetZoneName, menu)
        if seadActive then return end
        local spawnZone, dist = findClosestBlueZoneOutside(targetZoneName, minNM)
        if not spawnZone then
            trigger.action.outTextForCoalition(2, 'No friendly zone available for SEAD spawn '..minNM..'+ NM away.', 15)
            return
        end
        local offset = (dist and dist < minNM) and (minNM - dist) or 0
        spawnSeadAt(spawnZone, targetZoneName, offset)
        SEADTargetMenu = nil
    end, 1, nil, allow)

    trigger.action.outTextForCoalition(2, 'Select SEAD target zone from F10', 10)
    return
end,
function(sender, params)
    if params.zone and params.zone.side == 1 then
        if seadActive then
            return 'SEAD mission still in progress'
        end
        local minNM = 40
        local closestBlue, dist = findClosestBlueZoneOutside(params.zone.zone, minNM)
        if not closestBlue then
            return 'No friendly zone available for SEAD spawn.'
        end
        local offset = (dist and dist < minNM) and (minNM - dist) or 0
        spawnSeadAt(closestBlue, params.zone.zone, offset)
        return
    else
        return 'Can only target enemy zone'
    end
end)

bc:registerShopItem('dynamicbomb', 'Dynamic Bomb run', 500,
function(sender)
    if bomberActive then
        return 'Bomb mission still in progress'
    end
	if BomberTargetMenu then
        return 'Choose target zone from F10 menu'
    end

    local minNM = 25
    local allow = {}
    for _, z in ipairs(bc:getZones()) do
        if z.side == 1 and findClosestBlueZoneOutside(z.zone, minNM) then
            allow[z.zone] = true
        end
    end
    if not next(allow) then
        trigger.action.outTextForCoalition(2, 'No enemy zone is far enough (>'..minNM..' NM) from the front line.', 10)
        return
    end

    BomberTargetMenu = bc:showTargetZoneMenu(2, 'Select bomb run target', function(targetZoneName, menu)
        if bomberActive then return end
        local spawnZone, dist = findClosestBlueZoneOutside(targetZoneName, minNM)
        if not spawnZone then
            trigger.action.outTextForCoalition(2, 'No friendly zone available for Bomb spawn '..minNM..'+ NM away.', 15)
            return
        end
        local offset = (dist and dist < minNM) and (minNM - dist) or 0
        spawnBomberAt(spawnZone, targetZoneName, offset)
        BomberTargetMenu = nil
    end, 1, nil, allow)

    trigger.action.outTextForCoalition(2, 'Select bomb run target zone from F10', 10)
    return
end,
function(sender, params)
    if params.zone and params.zone.side == 1 then
        if bomberActive then
            return 'Bomb run mission still in progress'
        end
        local minNM = 25
        local closestBlue, dist = findClosestBlueZoneOutside(params.zone.zone, minNM)
        if not closestBlue then
            return 'No friendly zone available for bomb run spawn.'
        end
        local offset = (dist and dist < minNM) and (minNM - dist) or 0
        spawnBomberAt(closestBlue, params.zone.zone, offset)
        return
    else
        return 'Can only target enemy zone'
    end
end)

---------------------------------------------END DYNAMIC SHOP ------------------------------------------

-- local jtacDrones
-- local jtacTargetMenu = nil
-- for _,n in ipairs({'jtacDroneColdwar1','jtacDroneColdwar2','jtacDrone1','jtacDrone2'}) do
--     local g = Group.getByName(n)
--     if g then g:destroy() end
-- end
-- if Era == 'Coldwar' then
-- jtacDrones = {JTAC:new({name = 'jtacDroneColdwar1'}),JTAC:new({name = 'jtacDroneColdwar2'})}
-- else
-- jtacDrones = {JTAC:new({name = 'jtacDrone1'}),JTAC:new({name = 'jtacDrone2'})}
-- end
-- bc:registerShopItem('jtac','MQ-9 Reaper JTAC mission',150,function(sender)
-- 	if jtacTargetMenu then return 'Choose target zone from F10 menu' end
-- 	local spawnAndOrbit = function(target)
-- 		if jtacTargetMenu then
-- 			local zn = bc:getZoneByName(target)
-- 			for _,v in ipairs(jtacQueue) do
-- 				if v.tgtzone and v.tgtzone.zone == zn.zone then
-- 					trigger.action.outTextForCoalition(2,'JTAC already active over '..zn.zone..' Select another zone',10)
-- 					return 'duplicate zone'
-- 				end
-- 			end
-- 			if #jtacQueue == 2 then
-- 				local old = table.remove(jtacQueue,1)
-- 				local gr = Group.getByName(old.name)
-- 				if gr then gr:destroy() end
-- 			end
-- 			local dr = jtacDrones[1]
-- 			for i,v in ipairs(jtacDrones) do
-- 				if not Utils.isGroupActive(Group.getByName(v.name)) then dr = v break end
-- 			end
-- 			dr:deployAtZone(zn)
-- 			dr:showMenu()
-- 			table.insert(jtacQueue,dr)
-- 			if Era == 'Coldwar' then
-- 				trigger.action.outTextForCoalition(2,'Friendly Tomcat deployed over '..target..' - JTACs active '..#jtacQueue..' / 2',15)
-- 			else
-- 				trigger.action.outTextForCoalition(2,'Reaper drone deployed over '..target..' - JTACs active '..#jtacQueue..' / 2',15)
-- 			end
-- 			jtacTargetMenu = nil
-- 		end
-- 	end
-- 	jtacTargetMenu = bc:showTargetZoneMenu(2,'Deploy JTAC',spawnAndOrbit,1)
-- 	trigger.action.outTextForCoalition(2,'Choose which zone to deploy JTAC at from F10 menu',15)
-- end,function(sender,params)
-- 	if params.zone and params.zone.side == 1 then
-- 		for _,v in ipairs(jtacQueue) do
-- 			if v.tgtzone and v.tgtzone.zone == params.zone.zone then
-- 				return 'JTAC already active over '..params.zone.zone..' Choose another zone'
-- 			end
-- 		end
-- 		if #jtacQueue == 2 then
-- 			local old = table.remove(jtacQueue,1)
-- 			local gr  = Group.getByName(old.name)
-- 			if gr then gr:destroy() end
-- 		end
-- 		local dr = jtacDrones[1]
-- 		for i,v in ipairs(jtacDrones) do
-- 			if not Utils.isGroupActive(Group.getByName(v.name)) then dr = v break end
-- 		end
-- 		dr:deployAtZone(params.zone)
-- 		dr:showMenu()
-- 		table.insert(jtacQueue,dr)
-- 		if Era == 'Coldwar' then
-- 			trigger.action.outTextForCoalition(2,'Friendly Tomcat deployed over '..params.zone.zone..' - JTACs active '..#jtacQueue..' / 2',15)
-- 		else
-- 			trigger.action.outTextForCoalition(2,'Reaper drone deployed over '..params.zone.zone..' - JTACs active '..#jtacQueue..' / 2',15)
-- 		end
-- 	else
-- 		return 'Can only target enemy zone'
-- 	end
-- end)
-- ----------------------------------- START own 9 line jtac AM START ----------------------------------
-- jtacZones = {}
-- local jtacTargetMenu2 = nil
-- local droneAM
-- Group.getByName('JTAC9lineamColdwar'):destroy()
-- Group.getByName('JTAC9lineam'):destroy()
-- if Era == 'Coldwar' then
-- droneAM = JTAC9line:new({name = 'JTAC9lineamColdwar'})
-- else
-- droneAM = JTAC9line:new({name = 'JTAC9lineam'})
-- end
-- bc:registerShopItem('9lineam', 'Jtac 9line AM', 0, function(sender)
--     if jtacTargetMenu2 then
--         return 'Choose target zone from F10 menu'
--     end
    
--     local spawnAndOrbit2 = function(target)
--         if jtacTargetMenu2 then
--             local zn = bc:getZoneByName(target)
--             droneAM:deployAtZone(zn)
-- 			jtacZones[target] = {drone = Era == 'Coldwar' and 'JTAC9lineamColdwar' or 'JTAC9lineam'}
			
-- 		trigger.action.outTextForCoalition(2, 'Reaper drone deployed over ' .. target .. '. Contact Springfield on 241.00 AM ', 30)
--         jtacTargetMenu2 = nil
-- 		end
--     end
    
--     jtacTargetMenu2 = bc:showTargetZoneMenu(2, 'Deploy JTAC to Zone', spawnAndOrbit2, 1)
--     trigger.action.outTextForCoalition(2, 'Choose which zone to deploy JTAC at from F10 menu', 15)
-- end,
-- function(sender, params)
--     if params.zone and params.zone.side == 1 then
--         droneAM:deployAtZone(params.zone)
--         jtacZones[params.zone.zone] = {drone = Era == 'Coldwar' and 'JTAC9lineamColdwar' or 'JTAC9lineam'}
-- 		if Era == 'Coldwar' then
-- 			trigger.action.outTextForCoalition(2, 'Friendly Tomcat deployed over ' .. params.zone.zone .. '. Contact Springfield on 241.00 AM ', 30)
        
--     	else
-- 			trigger.action.outTextForCoalition(2, 'Reaper drone deployed over ' .. params.zone.zone .. '. Contact Springfield on 241.00 AM ', 30)
-- 		end
--     else
--         return 'Can only target enemy zone'
--     end
-- end)

--   ------------------------------ END 9 line jtac AM END ----------------------------------
--   ----------------------------- START 9 line jtac fm START ---------------------------
-- Group.getByName('JTAC9linefmColdwar'):destroy()
-- Group.getByName('JTAC9linefm'):destroy()
-- local jtacTargetMenu3 = nil
-- local droneFM
-- if Era == 'Coldwar' then
-- droneFM = JTAC9line:new({name = 'JTAC9linefmColdwar'})
-- else
-- droneFM = JTAC9line:new({name = 'JTAC9linefm'})
-- end
-- bc:registerShopItem('9linefm', 'Jtac 9line FM', 0, function(sender)
--     if jtacTargetMenu3 then
--         return 'Choose target zone from F10 menu'
--     end
    
--     local spawnAndOrbit3 = function(target)
--         if jtacTargetMenu3 then
--             local zn = bc:getZoneByName(target)
--             droneFM:deployAtZone(zn)
			
-- 			jtacZones[target] = {drone = Era == 'Coldwar' and 'JTAC9linefmColdwar' or 'JTAC9linefm'}
			
		
-- 		if Era == 'Coldwar' then
-- 			trigger.action.outTextForCoalition(2, 'Friendly Tomcat deployed over ' .. target .. '. Contact Uzi on 31.00 FM ', 30)
-- 		else
-- 			trigger.action.outTextForCoalition(2, 'Reaper drone deployed over ' .. target .. '. Contact Uzi on 31.00 FM ', 30)  
-- 		end            
--             jtacTargetMenu3 = nil
--         end
--     end
    
--     jtacTargetMenu3 = bc:showTargetZoneMenu(2, 'Deploy JTAC to Zone', spawnAndOrbit3, 1)
--     trigger.action.outTextForCoalition(2, 'Choose which zone to deploy JTAC at from F10 menu', 15)
-- end,
-- function(sender, params)
--     if params.zone and params.zone.side == 1 then
--         droneFM:deployAtZone(params.zone)
--         jtacZones[params.zone.zone] = {drone = Era == 'Coldwar' and 'JTAC9linefmColdwar' or 'JTAC9linefm'}

-- 		if Era == 'Coldwar' then
-- 			trigger.action.outTextForCoalition(2, 'Friendly Tomcat deployed over ' .. params.zone.zone .. '. Contact Uzi on 31.00 FM ', 30)
        
--     	else
-- 			trigger.action.outTextForCoalition(2, 'Reaper drone deployed over ' .. params.zone.zone .. '. Contact Uzi on 31.00 FM ', 30)
-- 		end
--     else
--         return 'Can only target enemy zone'
--     end
-- end)

  -------------------------- END 9 line jtac FM END ----------------------------------

-- function CheckJtacStatus()
-- 	 if jtacZones == nil then
-- 			return false
-- 		end

--     local jtacFound = false
    
--     for zoneName, jtacInfo in pairs(jtacZones) do
--         local jtacGroup = Group.getByName(jtacInfo.drone)
--         if jtacGroup and Utils.isGroupActive(jtacGroup) then
--             local zone = bc:getZoneByName(zoneName)
--             if zone and (zone.side == 0 or not zone.active) then
--                 jtacGroup:destroy()
--                 jtacZones[zoneName] = nil
--                 jtacFound = true
--             end
--         else
--             jtacZones[zoneName] = nil
--         end
--     end

--     return jtacFound
-- end

  -------------------------- END 9 line jtac FM END ----------------------------------
local smoketargets = function(tz)
	if not tz or not tz.built then
		env.info("smoketargets: no tz/built for zone "..tostring(tz and tz.zone or "nil"))
		return
	end
	local units, statics, dangling, toRemove = {}, {}, {}, {}
	for i,v in pairs(tz.built) do
		local g = Group.getByName(v)
		if g and g:isExist() then
			local gUnits = g:getUnits()
			if gUnits then
				for i2,v2 in ipairs(gUnits) do
					table.insert(units, v2)
				end
			end
        else
            local st = StaticObject.getByName(v)
            if st and st:isExist() then
                table.insert(statics, st)
            else
                table.insert(dangling, tostring(v))
                table.insert(toRemove, i)
            end
        end
	end
	if #dangling > 0 then
		--trigger.action.outTextForCoalition(2, "(BUG) "..tz.zone.." error has unresolved entries: "..table.concat(dangling,", ")..". Please report to Leka.", 30)
		for _,k in ipairs(toRemove) do tz.built[k] = nil end
	end
	local points = {}
	for _,u in ipairs(units) do if u and u:isExist() then local p=u:getPosition().p; if p then table.insert(points,p) end end end
	for _,s in ipairs(statics) do local p=s:getPoint(); if p then table.insert(points,p) end end
	for i=1,3 do
		if #points == 0 then break end
		local idx = math.random(1,#points)
		trigger.action.smoke(points[idx],1)
		table.remove(points,idx)
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
	if params.zone and params.zone.side == 1 and not params.zone.suspended then
		smoketargets(params.zone)
		trigger.action.outTextForCoalition(2, 'Targets marked with RED smoke at '..params.zone.zone, 15)
	else
		return 'Can only target enemy zone'
	end
end)
-- if not Era == 'Coldwar' then
-- Group.getByName('ewAircraft'):destroy()
-- local jamMenu = nil
-- bc:registerShopItem('jam', 'Jam radars at zone', 500, function(sender)
-- 	local gr = Group.getByName('ewAircraft')
-- 	if Utils.isGroupActive(gr) then 
-- 		return 'Jamming mission still in progress'
-- 	end
	
-- 	RespawnGroup('ewAircraft')
	
-- 	if jamMenu then
-- 		return 'Choose target zone from F10 menu'
-- 	end
	
-- 	local startJam = function(target)
-- 		if jamMenu then
-- 			bc:jamRadarsAtZone('ewAircraft', target)
-- 			jamMenu = nil
-- 			trigger.action.outTextForCoalition(2, 'Growler jamming radars at '..target, 15)
-- 		end
-- 	end
	
-- 	jamMenu = bc:showTargetZoneMenu(2, 'Jamming target', startJam, 1)
-- 	trigger.action.outTextForCoalition(2, 'Choose target zone from F10 menu', 15)
-- end,
-- function(sender, params)
-- 	if params.zone and params.zone.side == 1 and not params.zone.suspended then
-- 		local gr = Group.getByName('ewAircraft')
-- 		if Utils.isGroupActive(gr) then 
-- 			return 'Jamming mission still in progress'
-- 		end
		
-- 		RespawnGroup('ewAircraft')
		
-- 		SCHEDULER:New(nil,function(target)
-- 			local ew = Group.getByName('ewAircraft')
-- 			if ew then
-- 				local err = bc:jamRadarsAtZone('ewAircraft', target)
-- 				if err then
-- 					return err
-- 				end
				
-- 				trigger.action.outTextForCoalition(2, 'Growler jamming radars at '..target, 15)
-- 			end
-- 		end,{params.zone.zone},2,0)
		
-- 	else
-- 		return 'Can only target enemy zone'
-- 	end
-- end)
-- end
-- Group.getByName('ca-tanks-Coldwar'):destroy()
-- Group.getByName('ca-tanks'):destroy()
-- tanksMenu = nil
-- bc:registerShopItem('armor', 'Deploy armor (for combined arms)', 100, function(sender)
	
-- 	if tanksMenu then
-- 		return 'Choose deploy zone from F10 menu'
-- 	end
	
-- 	local deployTanks = function(target)
-- 		if tanksMenu then
		
-- 			local zn = CustomZone:getByName(target)
-- 			zn:spawnGroup((Era == 'Coldwar') and 'ca-tanks-Coldwar' or 'ca-tanks')
			
-- 			tanksMenu = nil
-- 			trigger.action.outTextForCoalition(2, 'Friendly armor deployed at '..target, 15)
-- 		end
-- 	end
	
-- 	tanksMenu = bc:showTargetZoneMenu(2, 'Deploy armor (Choose friendly zone)', deployTanks, 2)
-- 	trigger.action.outTextForCoalition(2, 'Choose deploy zone from F10 menu', 15)
-- end,
-- function(sender, params)
-- 	if params.zone and params.zone.side == 2 and not params.zone.suspended then
		
-- 		local zn = CustomZone:getByName(params.zone.zone)
-- 		zn:spawnGroup((Era == 'Coldwar') and 'ca-tanks-Coldwar' or 'ca-tanks')
-- 		trigger.action.outTextForCoalition(2, 'Friendly armor deployed at '..params.zone.zone, 15)
-- 	else
-- 		return 'Can only deploy at friendly zone'
-- 	end
-- end)
-- Group.getByName('ca-arty'):destroy()
-- artyMenu = nil
-- bc:registerShopItem('artillery', 'Deploy artillery (for combined arms)', 100, function(sender)
	
-- 	if artyMenu then
-- 		return 'Choose deploy zone from F10 menu'
-- 	end
	
-- 	local deployArty = function(target)
-- 		if artyMenu then
		
-- 			local zn = CustomZone:getByName(target)
-- 			zn:spawnGroup('ca-arty')
			
-- 			artyMenu = nil
-- 			trigger.action.outTextForCoalition(2, 'Friendly artillery deployed at '..target, 15)
-- 		end
-- 	end
	
-- 	artyMenu = bc:showTargetZoneMenu(2, 'Deploy artillery (Choose friendly zone)', deployArty, 2)
-- 	trigger.action.outTextForCoalition(2, 'Choose deploy zone from F10 menu', 15)
-- end,
-- function(sender, params)
-- 	if params.zone and params.zone.side == 2 and not params.zone.suspended then
		
-- 		local zn = CustomZone:getByName(params.zone.zone)
-- 		zn:spawnGroup('ca-arty')
-- 		trigger.action.outTextForCoalition(2, 'Friendly artillery deployed at '..params.zone.zone, 15)
-- 	else
-- 		return 'Can only deploy at friendly zone'
-- 	end
-- end)
-- Group.getByName('ca-recon'):destroy()
-- reconMenu = nil
-- bc:registerShopItem('recon', 'Deploy recon group (for combined arms)', 50, function(sender)
	
-- 	if reconMenu then
-- 		return 'Choose deploy zone from F10 menu'
-- 	end
	
-- 	local deployRecon = function(target)
-- 		if reconMenu then
		
-- 			local zn = CustomZone:getByName(target)
-- 			zn:spawnGroup('ca-recon')
			
-- 			reconMenu = nil
-- 			trigger.action.outTextForCoalition(2, 'Friendly recon group deployed at '..target, 15)
-- 		end
-- 	end
	
-- 	reconMenu = bc:showTargetZoneMenu(2, 'Deploy recon group (Choose friendly zone)', deployRecon, 2)
-- 	trigger.action.outTextForCoalition(2, 'Choose deploy zone from F10 menu', 15)
-- end,
-- function(sender, params)
-- 	if params.zone and params.zone.side == 2 then
		
-- 		local zn = CustomZone:getByName(params.zone.zone)
-- 		zn:spawnGroup('ca-recon')
-- 		trigger.action.outTextForCoalition(2, 'Friendly recon group deployed at '..params.zone.zone, 15)
-- 	else
-- 		return 'Can only deploy at friendly zone'
-- 	end
-- end)
-- Group.getByName('ca-airdef'):destroy()
-- airdefMenu = nil
-- bc:registerShopItem('airdef', 'Deploy air defence (for combined arms)', 150, function(sender)
	
-- 	if airdefMenu then
-- 		return 'Choose deploy zone from F10 menu'
-- 	end
	
-- 	local deployAirDef = function(target)
-- 		if airdefMenu then
		
-- 			local zn = CustomZone:getByName(target)
-- 			zn:spawnGroup('ca-airdef')
			
-- 			airdefMenu = nil
-- 			trigger.action.outTextForCoalition(2, 'Friendly air defence deployed at '..target, 15)
-- 		end
-- 	end
	
-- 	airdefMenu = bc:showTargetZoneMenu(2, 'Deploy air defence (Choose friendly zone)', deployAirDef, 2)
-- 	trigger.action.outTextForCoalition(2, 'Choose deploy zone from F10 menu', 15)
-- end,
-- function(sender, params)
-- 	if params.zone and params.zone.side == 2 and not params.zone.suspended then
		
-- 		local zn = CustomZone:getByName(params.zone.zone)
-- 		zn:spawnGroup('ca-airdef')
-- 		trigger.action.outTextForCoalition(2, 'Friendly air defence deployed at '..params.zone.zone, 15)
-- 	else
-- 		return 'Can only deploy at friendly zone'
-- 	end
-- end)
-- new menu
local supplyMenu=nil
bc:registerShopItem('capture','Capture neutral zone',500,
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
--end of menu

local intelMenu=nil
bc:registerShopItem('intel','Intel on enemy zone',150,function(sender)
	if intelMenu then
		return 'Already choosing a zone'
	end
	local pickZone = function(targetZoneName)
		if intelMenu then
			local zoneObj = bc:getZoneByName(targetZoneName)
			if not zoneObj or zoneObj.side ~= 1 or not zoneObj.suspended then
			--if not zoneObj or zoneObj.side ~= 1 then
				return 'Must pick an enemy zone'
			end
			intelActiveZones[targetZoneName] = true
			startZoneIntel(targetZoneName)
			trigger.action.outTextForCoalition(2, 'Intel available for '..targetZoneName..'. Check Zone status. Valid for 1 hour', 15)
			timer.scheduleFunction(function(args)
				local zName = args[1]
				if intelActiveZones[zName] then intelActiveZones[zName] = false end
				local zn = bc:getZoneByName(zName)
				if zn and zn.updateLabel then zn:updateLabel() end
				trigger.action.outTextForCoalition(2, 'Intel on '..zName..' has expired.', 10)
			end, {targetZoneName}, timer.getTime()+60*60)
			intelMenu = nil
		end
	end
	intelMenu = bc:showTargetZoneMenu(2, 'Choose Enemy Zone for Intel', pickZone, 1)
	trigger.action.outTextForCoalition(2, 'Intel purchase started. Select enemy zone from F10 menu.', 15)
end,
function(sender, params)
	if params.zone and params.zone.side == 1 and not params.zone.suspended then
		intelActiveZones[params.zone.zone] = true
		startZoneIntel(params.zone.zone)
		trigger.action.outTextForCoalition(2, 'Intel available for '..params.zone.zone..'. Check Zone status. Valid for 1 hour', 15)
		SCHEDULER:New(nil,function(zName)
			if intelActiveZones[zName] then intelActiveZones[zName] = false end
			local zn = bc:getZoneByName(zName)
			if zn and zn.updateLabel then zn:updateLabel() end
			trigger.action.outTextForCoalition(2, 'Intel on '..zName..' has expired.', 10)
		end,{params.zone.zone},3600)
	else
		return 'Must pick an enemy zone'
	end
end)

------------------------------------------- Zone upgrades --------------------------------------------
local function buildAllowTable()
	local t = {}
	for _, z in pairs(bc:getZones()) do
		local max = 1 + (bc.globalExtraUnlock and 1 or 0)
        if z.side == 2 and (z.upgradesUsed or 0) < max
           and not z.zone:lower():find("carrier") then
			t[z.zone] = true
		end
	end
	return t
end

local infMenu=nil
bc:registerShopItem('zinf','Add infantry squad to zone',500,function(sender)
	if infMenu then
		return 'Already choosing a zone'
	end
	local pickZone=function(zName)
		if infMenu then
			local z=bc:getZoneByName(zName)
			if not z or z.side~=2 or z.supsended then
				return 'Must pick friendly zone'
			end
			if z.upgradesUsed >= (1 + (bc.globalExtraUnlock and 1 or 0)) then
				return 'Zone already upgraded'
			end
			z:addExtraSlot('UK-INF-MK1')
			z:updateLabel()
			if bc.globalExtraUnlock then
                trigger.action.outTextForCoalition(2,'Infantry added to '..zName..' for 500',10)
            else
                trigger.action.outTextForCoalition(2,'Infantry added to '..zName..' for 500 - buy the Global extra slot to upgrade this zone again',30)
            end
			missionCommands.removeItemForCoalition(2,infMenu)
			infMenu=nil
		end
	end
	local allow = buildAllowTable()
	if not next(allow) then
		if not bc.globalExtraUnlock then
			return 'All zones already upgraded - purchase Global extra slot to add another'
		end
		return 'No eligible zone'
	end
	infMenu = bc:showTargetZoneMenu(2,'Choose Zone for Infantry',pickZone,2,nil,allow)
	trigger.action.outTextForCoalition(2,'Select friendly zone from F10 menu.',15)
end,
function(sender,params)
	if params.zone and params.zone.side==2 and not params.zone.suspended then
		local max = 1 + (bc.globalExtraUnlock and 1 or 0)
		if params.zone.upgradesUsed >= max then
			if not bc.globalExtraUnlock then
				return 'Zone already upgraded - purchase Global extra slot to add another'
			end
			return 'Zone already upgraded'
		end
		params.zone:addExtraSlot('UK-INF-MK1')
		params.zone:updateLabel()
		if bc.globalExtraUnlock then
		trigger.action.outTextForCoalition(2,'Infantry added to '..params.zone.zone..' for 500',10)
		else
		trigger.action.outTextForCoalition(2,'Infantry added to '..params.zone.zone..' for 500 - buy the Global extra slot to upgrade this zone again',30)
		end
	else
		return 'Must pick friendly zone'
	end
end)
local samLabel = (Era == 'Coldwar') and 'Add Hawk system to a zone'
                                   or  'Add Nasams system to a zone'
local samMenu=nil
bc:registerShopItem('zsam',samLabel,2000,function(sender)
	if samMenu then
		return 'Already choosing a zone'
	end
	local pickZone=function(zName)
		if samMenu then
			local z=bc:getZoneByName(zName)
			if not z or z.side~=2 or z.suspended then
				return 'Must pick friendly zone'
			end
		if z.upgradesUsed >= (1 + (bc.globalExtraUnlock and 1 or 0)) then
			return 'Zone already upgraded'
		end
            local slot = (Era == 'Coldwar') and 'blueHAWK Coldwar' or 'bluePD1'
            z:addExtraSlot(slot)
			z:updateLabel()
			local sys = (Era == 'Coldwar') and 'Hawk' or 'Nasams'
            if bc.globalExtraUnlock then	
                trigger.action.outTextForCoalition(2,sys..' added to '..zName..' for 2000',10)
            else
                trigger.action.outTextForCoalition(2,sys..' added to '..zName..' for 2000 - buy the Global extra slot to upgrade this zone again',30)
            end
			missionCommands.removeItemForCoalition(2,samMenu)
			samMenu=nil
		end
	end

	local allow = buildAllowTable()
	if not next(allow) then
		if not bc.globalExtraUnlock then
			return 'All zones already upgraded - purchase Global extra slot to add another'
		end
		return 'No eligible zone'
	end
	samMenu = bc:showTargetZoneMenu(2,'Choose Zone for SAM',     pickZone,2,nil,allow)
	trigger.action.outTextForCoalition(2,'Select friendly zone from F10 menu.',15)
end,
function(sender,params)
	if params.zone and params.zone.side==2 and not params.zone.suspended then
		local max = 1 + (bc.globalExtraUnlock and 1 or 0)
		if params.zone.upgradesUsed >= max then
			if not bc.globalExtraUnlock then
				return 'Zone already upgraded - purchase Global extra slot to add another'
			end
			return 'Zone already upgraded'
		end
		params.zone:addExtraSlot((Era == 'Coldwar') and 'blueHAWK Coldwar' or 'bluePD1')
		params.zone:updateLabel()
		local sys = (Era == 'Coldwar') and 'Hawk' or 'Nasams'
        if bc.globalExtraUnlock then
            trigger.action.outTextForCoalition(2,sys..' added to '..params.zone.zone..' for 2000',10)
        else
            trigger.action.outTextForCoalition(2,sys..' added to '..params.zone.zone..' for 2000 - buy the Global extra slot to upgrade this zone again',30)
        end
	else
		return 'Must pick friendly zone'
	end
end)

local armMenu=nil
bc:registerShopItem('zarm','Add armor group to a zone',1000,function(sender)
	if armMenu then
		return 'Already choosing a zone'
	end
	local pickZone=function(zName)
		if armMenu then
			local z=bc:getZoneByName(zName)
			if not z or z.side~=2 or z.suspended then
				return 'Must pick friendly zone'
			end
			if z.upgradesUsed >= (1 + (bc.globalExtraUnlock and 1 or 0)) then
				return 'Zone already upgraded'
			end
			local slotID = (Era == 'Coldwar') and 'blueArmor_cw' or 'UK-ARMOR'
			z:addExtraSlot(slotID)
			z:updateLabel()
			if bc.globalExtraUnlock then
				trigger.action.outTextForCoalition(2,'Armor added to '..zName..' for 1000',10)
			else
				trigger.action.outTextForCoalition(2,'Armor added to '..zName..' for 1000 - buy the Global extra slot to upgrade this zone again',30)
			end
			missionCommands.removeItemForCoalition(2,armMenu)
			armMenu=nil
		end
	end
	local allow = buildAllowTable()
	if not next(allow) then
		if not bc.globalExtraUnlock then
			return 'All zones already upgraded - purchase Global extra slot to add another'
		end
		return 'No eligible zone'
	end
	armMenu = bc:showTargetZoneMenu(2,'Choose Zone for Armor',   pickZone,2,nil,allow)
	trigger.action.outTextForCoalition(2,'Select friendly zone from F10 menu.',15)
end,
function(sender,params)
	if params.zone and params.zone.side==2 and not params.zone.suspended then
		local max = 1 + (bc.globalExtraUnlock and 1 or 0)
		if params.zone.upgradesUsed >= max then
			if not bc.globalExtraUnlock then
				return 'Zone already upgraded - purchase Global extra slot to add another'
			end
			return 'Zone already upgraded'
		end
		local slotID = (Era == 'Coldwar') and 'blueArmor_cw' or 'UK-ARMOR'
		params.zone:addExtraSlot(slotID)
		params.zone:updateLabel()
		if bc.globalExtraUnlock then
			trigger.action.outTextForCoalition(2,'Armor added to '..params.zone.zone..' for 1000',10)
		else
			trigger.action.outTextForCoalition(2,'Armor added to '..params.zone.zone..' for 1000\nBuy the Global extra slot to upgrade this zone again',30)
		end
	else
		return 'Must pick friendly zone'
	end
end)
--Group.getByName('bluePATRIOT'):destroy()
-- local patMenu=nil
-- bc:registerShopItem('zpat','Add Patriot system to zone',5000,function(sender)
-- 	if patMenu then
-- 		return 'Already choosing a zone'
-- 	end
-- 	local pickZone=function(zName)
-- 		if patMenu then
-- 			local z=bc:getZoneByName(zName)
-- 			if not z or z.side~=2 or z.suspended then
-- 				return 'Must pick friendly zone'
-- 			end
-- 			if z.upgradesUsed >= (1 + (bc.globalExtraUnlock and 1 or 0)) then
-- 				return 'Zone already upgraded'
-- 			end
-- 			z:addExtraSlot('bluePATRIOT')
-- 			z:updateLabel()
-- 			if bc.globalExtraUnlock then
--                 trigger.action.outTextForCoalition(2,'Patriot added to '..zName..' for 5000',10)
--             else
--                 trigger.action.outTextForCoalition(2,'Patriot added to '..zName..' for 5000 - buy the Global extra slot to upgrade this zone again',30)
--             end
-- 			missionCommands.removeItemForCoalition(2,patMenu)
-- 			patMenu=nil
-- 		end
-- 	end
-- 	local allow = buildAllowTable()
-- 	if not next(allow) then
-- 		if not bc.globalExtraUnlock then
-- 			return 'All zones already upgraded - purchase Global extra slot to add another'
-- 		end
-- 		return 'No eligible zone'
-- 	end
-- 	patMenu = bc:showTargetZoneMenu(2,'Choose Zone for Patriot SAM system',pickZone,2,nil,allow)
-- 	trigger.action.outTextForCoalition(2,'Select friendly zone from F10 menu.',15)
-- end,
-- function(sender,params)
-- 	if params.zone and params.zone.side==2 and not params.zone.suspended then
-- 		local max = 1 + (bc.globalExtraUnlock and 1 or 0)
-- 		if params.zone.upgradesUsed >= max then
-- 			if not bc.globalExtraUnlock then
-- 				return 'Zone already upgraded - purchase Global extra slot to add another'
-- 			end
-- 			return 'Zone already upgraded'
-- 		end
-- 		params.zone:addExtraSlot('bluePATRIOT')
-- 		params.zone:updateLabel()
-- 		if bc.globalExtraUnlock then
-- 		trigger.action.outTextForCoalition(2,'Patriot added to '..params.zone.zone..' for 5000',10)
-- 		else
-- 		trigger.action.outTextForCoalition(2,'Patriot added to '..params.zone.zone..' for 5000 - buy the Global extra slot to upgrade this zone again',30)
-- 		end
-- 	else
-- 		return 'Must pick friendly zone'
-- 	end
-- end)

bc:registerShopItem('gslot','Unlock extra upgrade slot',3000,function(sender)
    if bc.globalExtraUnlock then
        return 'Already unlocked'
    end
    bc.globalExtraUnlock = true
    for _,z in pairs(bc:getZones()) do

    end
    trigger.action.outTextForCoalition(2,'All zones can now buy a second upgrade',15)
	bc:removeShopItem(2, 'gslot')
	return nil
end)
------------------------------------------- End of Zone upgrades ----------------------------------------

-- first value below is how much in stock, the second number value is the ranking in the shop menu list, the third is the new ranking system.
--bc:addShopItem(2, 'jtac', -1, 1, 2) -- MQ-9 Reaper JTAC mission
bc:addShopItem(2, 'dynamiccap', -1, 1, 1) -- CAP
bc:addShopItem(2, 'dynamiccas', -1, 2, 1) -- CAS
bc:addShopItem(2, 'dynamicbomb', -1, 3, 1) -- Bomber
--bc:addShopItem(2, 'dynamicsead', -1, 5, 4) -- SEAD
--bc:addShopItem(2, 'dynamicdecoy', -1, 6, 1) -- Decoy flight
--[[ if UseStatics == true then
    bc:addShopItem(2, 'dynamicstatic', -1,7,4) -- Static buildings
end ]]
-- bc:addShopItem(2, 'dynamicarco', -1, 8, 3) -- Navy tanker
-- bc:addShopItem(2, 'dynamictexaco', -1, 9, 3) -- Airforce tanker

bc:addShopItem(2, 'capture', -1, 4, 1) -- emergency capture
bc:addShopItem(2, 'smoke', -1, 5, 1) -- smoke on target
bc:addShopItem(2, 'intel', -1, 6, 1) -- Intel
bc:addShopItem(2, 'supplies2', -1, 7, 1) -- upgrade friendly zone
bc:addShopItem(2, 'supplies', -1, 8, 1) -- fully upgrade friendly zone
bc:addShopItem(2, 'zinf', -1, 9, 1) -- add infantry to a zone
bc:addShopItem(2, 'zarm', -1, 10, 1) -- add armour group to a zone
--bc:addShopItem(2, 'zsam', -1, 17, 6) -- add Nasams to a zone
bc:addShopItem(2, 'gslot', 1, 11, 1) -- add another slot for upgrade
-- if Era == 'Modern' then
--     bc:addShopItem(2, 'zpat', -1, 19, 8) -- Patriot system.
-- end
-- bc:addShopItem(2, 'armor', -1, 20, 3) -- combined arms
-- bc:addShopItem(2, 'artillery', -1, 21, 3) -- combined arms
-- bc:addShopItem(2, 'recon', -1, 22, 3) -- combined arms
-- bc:addShopItem(2, 'airdef', -1, 23, 3) -- combined arms
-- bc:addShopItem(2, '9lineam', -1, 24, 1) -- free jtac
-- bc:addShopItem(2, '9linefm', -1, 25, 1) -- free jtac
-- bc:addShopItem(2, 'cruisemsl', 12, 26, 10) -- Cruise missiles

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
	--'hiddenCarrierEssex',
}

lc = LogisticCommander:new({battleCommander = bc, supplyZones = supplyZones})
lc:init()

bc:loadFromDisk() --will load and overwrite default zone levels, sides, funds and available shop items
bc:init()
bc:startRewardPlayerContribution(15,{infantry = 10, ground = 10, sam = 30, airplane = 30, ship = 250, helicopter=30, crate=200, rescue = 300, ['Zone upgrade'] = 100, ['Zone capture'] = 200, ['CAP mission'] = true, ['CAS mission'] = true})
HercCargoDropSupply.init(bc)
buildTemplateCache()
bc:buildZoneDistanceCache()
buildSubZoneRoadCache()
bc:buildConnectionMap()
bc:buildConnectionSupplyMap()
DynamicConvoy.InitTargetTails(5)
DynamicConvoy.InitRoadPathCacheFromCommanders(GroupCommanders)
PrecomputeLandingSpots()
Frontline.ReindexZoneCalcs()
bc:buildCapSpawnBuckets()
local HuntNumber = SplashDamage and math.random(10,15) or math.random(8,15)
bc:initHunter(HuntNumber)
SCHEDULER:New(nil, function() bc:_buildHunterBaseList() end, {}, 1)

SCHEDULER:New(nil, function() spawnAwacs(1,nil,10) end, {}, 5)
SCHEDULER:New(nil, function() spawnAwacs(2,nil,10) end, {}, 6)

AWACS_CFG = {
    [1] = { alt=30000, speed=350, hdg=270, leg=15, sep=150 }, -- red
    [2] = { alt=30000, speed=350, hdg=270, leg=15, sep=75 }   -- blue
}

GlobalSettings.autoSuspendNmBlue = 1000   		-- suspend blue zones deeper than this nm
GlobalSettings.autoSuspendNmRed = 1000   		-- suspend red zones deeper than this nm
evc = EventCommander:new({ decissionFrequency=15*60, decissionVariance=10*60, skipChance = 15})
evc:init()
mc = MissionCommander:new({side = 2, battleCommander = bc, checkFrequency = 60})
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
  ["RailwayLondonVictoriaStation"] = {SCENERY:FindByZoneName("HiddenRailwayLondonVictoriaStation")},
  ["RailwayWaterlooStation"] = {SCENERY:FindByZoneName("HiddenRailwayWaterlooStation")},
  ["RailwayLondonBridgeStation"] = {SCENERY:FindByZoneName("HiddenRailwayLondonBridgeStation")},
  ["RailwayDover"] = {SCENERY:FindByZoneName("HiddenRailwayDover")},
  ["RailwayFarnborough"] = {SCENERY:FindByZoneName("HiddenRailwayFarnborough")},
  ["RailwayFord"] = {SCENERY:FindByZoneName("HiddenRailwayFord")},
  ["RailwayHawkinge"] = {SCENERY:FindByZoneName("HiddenRailwayHawkinge")},
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
  ["RailwayRouen"] = {SCENERY:FindByZoneName("HiddenRailwayRouen")},
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
	["RailwayLondonVictoriaStation"] = {
		"UK_Train_London-resupply-Farnborough"
	},
	["RailwayWaterlooStation"] = {
		"UK_Train_London-resupply-Chailey",
		"UK_Train_London-resupply-Ford"
	},
	["RailwayLondonBridgeStation"] = {
		"UK_Train_London-resupply-Manston",
		"UK_Train_London-resupply-Hawkinge"
		
	},
	["RailwayDover"] = {
		"UK_Train_Manston-resupply-Dover"
	},
	["RailwayFarnborough"] = {
		"UK_Train_London-resupply-Farnborough"
	},
	["RailwayFord"] = {
		"UK_Train_London-resupply-Ford"
	},
	["RailwayHawkinge"] = {
		"UK_Train_London-resupply-Hawkinge"
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
	["RailwayRouen"] = {
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

DEPENDENT_DEBUG_LOGGING = false
-- Helper functions for debug logging
local function dependLog(message)
    if DEPENDENT_DEBUG_LOGGING then
        env.info(message)
    end
end


local function destroyRailwayDependentGroups(stationName)
    env.info("destroyRailwayDependentGroups: ===== CALLED FOR STATION: " .. tostring(stationName) .. " =====")
    
    if railwayStationsDestroyed[stationName] then
        env.info("destroyRailwayDependentGroups: Station " .. stationName .. " already processed, returning early")
        return -- Already processed this station
    end
    
    railwayStationsDestroyed[stationName] = true
    dependLog("destroyRailwayDependentGroups: Marked station " .. stationName .. " as destroyed in railwayStationsDestroyed table")
    
    local groupsToDestroy = RAILWAY_STATION_GROUPS[stationName]
    if not groupsToDestroy then
        dependLog("destroyRailwayDependentGroups: ERROR - No groups mapped to station " .. stationName .. " in RAILWAY_STATION_GROUPS table")
        dependLog("destroyRailwayDependentGroups: Available stations in RAILWAY_STATION_GROUPS:")
        for stationKey, _ in pairs(RAILWAY_STATION_GROUPS) do
            env.info("destroyRailwayDependentGroups:   - " .. stationKey)
        end
        return
    end
    
   dependLog("destroyRailwayDependentGroups: Found " .. #groupsToDestroy .. " groups to destroy for station " .. stationName)
    for i, groupName in ipairs(groupsToDestroy) do
        env.info("destroyRailwayDependentGroups:   Group " .. i .. ": '" .. groupName .. "'")
    end
    
    local destroyedCount = 0
    local destroyedNames = {}
    local creditsAwarded = { [1] = 0, [2] = 0 }  -- Track credits awarded to each coalition
    
    for _, groupName in ipairs(groupsToDestroy) do
        dependLog("destroyRailwayDependentGroups: Processing group '" .. groupName .. "'...")
        
        local group = Group.getByName(groupName)
        if group then
            local groupCoalition = group:getCoalition()
            dependLog("destroyRailwayDependentGroups: SUCCESS - Found group '" .. groupName .. "', coalition: " .. groupCoalition)
            
            -- Check if group exists and has units
            local units = group:getUnits()
            if units and #units > 0 then
                dependLog("destroyRailwayDependentGroups: Group '" .. groupName .. "' has " .. #units .. " units")
                for j, unit in ipairs(units) do
                    if unit and unit:isExist() then
                        env.info("destroyRailwayDependentGroups:   Unit " .. j .. ": " .. unit:getName() .. " (life: " .. unit:getLife() .. ")")
                    end
                end
            else
                env.info("destroyRailwayDependentGroups: WARNING - Group '" .. groupName .. "' has no units!")
            end
            
            group:destroy()
            trainGroupsDestroyed[groupName] = true
            CustomFlags[groupName] = true
            destroyedCount = destroyedCount + 1
            table.insert(destroyedNames, groupName)
            env.info("destroyRailwayDependentGroups: DESTROYED group '" .. groupName .. "' and set CustomFlags[" .. groupName .. "] = true")
            
            -- Award credits to the opposing coalition
            if groupCoalition == 1 then
                -- RED group destroyed - award to BLUE
                local bonus = 2000
                bc:addFunds(2, bonus)
                creditsAwarded[2] = creditsAwarded[2] + bonus
                dependLog("destroyRailwayDependentGroups: Awarded " .. bonus .. " credits to BLUE (coalition 2) for destroying RED group '" .. groupName .. "'")
            elseif groupCoalition == 2 then
                -- BLUE group destroyed - award to RED
                local bonus = 2000
                bc:addFunds(1, bonus)
                creditsAwarded[1] = creditsAwarded[1] + bonus
                dependLog("destroyRailwayDependentGroups: Awarded " .. bonus .. " credits to RED (coalition 1) for destroying BLUE group '" .. groupName .. "'")
            else
                env.info("destroyRailwayDependentGroups: Unknown coalition " .. groupCoalition .. " for group '" .. groupName .. "' - no credits awarded")
            end
        else
            env.info("destroyRailwayDependentGroups: ERROR - Group '" .. groupName .. "' NOT FOUND in DCS mission!")
            dependLog("destroyRailwayDependentGroups: This means the group name in RAILWAY_STATION_GROUPS doesn't match actual groups in the mission")
        end
    end
    
   dependLog("destroyRailwayDependentGroups: SUMMARY - Destroyed " .. destroyedCount .. " out of " .. #groupsToDestroy .. " groups for station " .. stationName)
    
    -- Provide feedback to players
    if destroyedCount > 0 then
        local stationDisplayName = stationName:gsub("Railway", "Depot ")
        local message = string.format(
            "%s destroyed!\n%d military units abandoned due to supply disruption:\n%s", 
            stationDisplayName,
            destroyedCount,
            table.concat(destroyedNames, ", ")
        )
        
        dependLog("destroyRailwayDependentGroups: Sending player notifications...")
        
        -- Send messages and bonuses based on credits awarded
        if creditsAwarded[2] > 0 then
            trigger.action.outText(message, 20)
            local bonusMessage = string.format("Enemy railway infrastructure destroyed! Strategic targeting bonus: +%d credits", creditsAwarded[2])
            trigger.action.outTextForCoalition(2, bonusMessage, 10)
            dependLog("destroyRailwayDependentGroups: Sent message to BLUE coalition about " .. creditsAwarded[2] .. " credits")
        end
        
        if creditsAwarded[1] > 0 then
            trigger.action.outText(message, 20)
            local bonusMessage = string.format("Enemy railway infrastructure destroyed! Strategic targeting bonus: +%d credits", creditsAwarded[1])
            trigger.action.outTextForCoalition(1, bonusMessage, 10)
            dependLog("destroyRailwayDependentGroups: Sent message to RED coalition about " .. creditsAwarded[1] .. " credits")
        end
        
        -- If no credits were awarded (neutral groups), still show the message
        if creditsAwarded[1] == 0 and creditsAwarded[2] == 0 then
            trigger.action.outTextForCoalition(2, message, 15)
            trigger.action.outTextForCoalition(1, message, 15)
            dependLog("destroyRailwayDependentGroups: No credits awarded - neutral/unknown groups destroyed")
        end
        
        dependLog("destroyRailwayDependentGroups: Calling bc:drawSupplyArrowsDebounced()...")
        bc:drawSupplyArrowsDebounced()
        dependLog("destroyRailwayDependentGroups: ===== COMPLETED FOR STATION: " .. stationName .. " =====")
    else
        env.info("destroyRailwayDependentGroups: ===== NO GROUPS DESTROYED FOR STATION: " .. stationName .. " =====")
    end
end

RESTORE_RAILWAY_DEBUG_LOGGING = false
-- Helper functions for debug logging
local function restoreRailwayLog(message)
    if RESTORE_RAILWAY_DEBUG_LOGGING then
        env.info(message)
    end
end
-- Function to restore railway destruction state on mission restart
local function restoreRailwayDestructionState()
    env.info("restoreRailwayDestructionState: ===== STARTING RAILWAY RESTORATION CHECK =====")
    
    local stationsProcessed = 0
    local stationsRestored = 0
    
    for stationName, isDestroyed in pairs(CustomFlags) do
        if isDestroyed == true and stationName:lower():find("railway") then
            stationsProcessed = stationsProcessed + 1
            restoreRailwayLog("restoreRailwayDestructionState: Processing destroyed station: " .. stationName)
            
            -- Find and destroy the scenery objects using explosions
            local sceneries = sceneryList[stationName]
            if sceneries then
                restoreRailwayLog("restoreRailwayDestructionState: Found " .. #sceneries .. " scenery objects for " .. stationName)
                for i, scenery in ipairs(sceneries) do
                    if scenery then
                        -- Use explosion to damage scenery
                        trigger.action.explosion(scenery:GetPointVec3(), 500)
                        restoreRailwayLog("restoreRailwayDestructionState: Used explosion to damage scenery object " .. i .. " for " .. stationName)
                    else
                        env.info("restoreRailwayDestructionState: WARNING - Scenery object " .. i .. " is NULL for " .. stationName)
                    end
                end
            else
                env.info("restoreRailwayDestructionState: WARNING - No scenery objects found for " .. stationName .. " in sceneryList")
            end
            
            -- Destroy dependent groups using existing function
            restoreRailwayLog("restoreRailwayDestructionState: Calling destroyRailwayDependentGroups for " .. stationName)
            destroyRailwayDependentGroups(stationName)
            bc:drawSupplyArrowsDebounced()
            
            stationsRestored = stationsRestored + 1
            
            -- Provide feedback about restoration
            local stationDisplayName = stationName:gsub("Railway", "Railway Station ")
            trigger.action.outTextForCoalition(2, 
                stationDisplayName .. " remains destroyed from previous mission", 15)
            
            restoreRailwayLog("restoreRailwayDestructionState: Completed restoration for " .. stationName)
        end
    end
    
    env.info("restoreRailwayDestructionState: ===== RAILWAY RESTORATION COMPLETE =====")
    restoreRailwayLog("restoreRailwayDestructionState: Processed " .. stationsProcessed .. " destroyed stations, restored " .. stationsRestored)
end


RESTORE_TRAIN_DEBUG_LOGGING = false
-- Helper functions for debug logging
local function restoreTrainLog(message)
    if RESTORE_TRAIN_DEBUG_LOGGING then
        env.info(message)
    end
end
-- Function to restore train group destruction state on mission restart
local function restoreTrainGroupDestructionState()
    env.info("restoreTrainGroupDestructionState: ===== STARTING TRAIN RESTORATION CHECK =====")
    
    local trainsProcessed = 0
    local trainsDestroyed = 0
    
    for groupName, isDestroyed in pairs(CustomFlags) do
        if isDestroyed == true and (groupName:find("AXE_Train_") or groupName:find("UK_Train_")) then
            trainsProcessed = trainsProcessed + 1
            restoreTrainLog("restoreTrainGroupDestructionState: Processing destroyed train: " .. groupName)
            
            -- Mark this train group as destroyed in our tracking
            trainGroupsDestroyed[groupName] = true
            restoreTrainLog("restoreTrainGroupDestructionState: Marked " .. groupName .. " as destroyed in trainGroupsDestroyed table")
            
            -- Find and destroy the train group if it exists
            local group = Group.getByName(groupName)
            if group then
                group:destroy()
                trainsDestroyed = trainsDestroyed + 1
                restoreTrainLog("restoreTrainGroupDestructionState: Successfully destroyed train group " .. groupName)
                
                -- Determine coalition for feedback
                local coalition = 2 -- Default to Blue coalition
                if groupName:find("AXE_Train_") then
                    coalition = 2 -- Blue coalition gets notification for Red train destruction
                    restoreTrainLog("restoreTrainGroupDestructionState: " .. groupName .. " is RED train, notifying BLUE coalition")
                elseif groupName:find("UK_Train_") then
                    coalition = 1 -- Red coalition gets notification for Blue train destruction
                    restoreTrainLog("restoreTrainGroupDestructionState: " .. groupName .. " is BLUE train, notifying RED coalition")
                end
                
                -- Provide feedback to players
                trigger.action.outTextForCoalition(coalition, 
                    "Train " .. groupName .. " remains destroyed from previous mission", 10)
            else
                env.info("restoreTrainGroupDestructionState: Train group " .. groupName .. " not found in DCS mission (already destroyed or doesn't exist)")
            end
        end
    end
    
    env.info("restoreTrainGroupDestructionState: ===== TRAIN RESTORATION COMPLETE =====")
    restoreTrainLog("restoreTrainGroupDestructionState: Processed " .. trainsProcessed .. " train flags, destroyed " .. trainsDestroyed .. " active trains")
end

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
SCHEDULER:New(nil, function()
    env.info("Train Group System: ===== STARTING TRAIN MONITORING CYCLE =====")
    
    -- Check both Red and Blue coalitions for train groups
    -- Red coalition (coalition 1) - check for AXE_Train_ groups
    local redGroundGroups = coalition.getGroups(1, Group.Category.GROUND) or {}
    local redTrainGroups = coalition.getGroups(1, Group.Category.TRAIN) or {}
    
    -- Blue coalition (coalition 2) - check for UK_Train_ groups  
    local blueGroundGroups = coalition.getGroups(2, Group.Category.GROUND) or {}
    local blueTrainGroups = coalition.getGroups(2, Group.Category.TRAIN) or {}
    
    -- env.info("Train Group System: Found " .. #redGroundGroups .. " Red ground groups")
    -- env.info("Train Group System: Found " .. #redTrainGroups .. " Red train groups")
    -- env.info("Train Group System: Found " .. #blueGroundGroups .. " Blue ground groups")
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
    
    --env.info("Train Group System: Total groups to check: " .. #allGroups)
    
    local trainGroupCount = 0
    local trainGroupsFound = {}
    
    for _, group in ipairs(allGroups) do
        local groupName = group:getName()
        
        -- Check for both AXE_Train_ (Red) and UK_Train_ (Blue) groups
        if groupName and (groupName:find("AXE_Train_") or groupName:find("UK_Train_")) then
            trainGroupCount = trainGroupCount + 1
            table.insert(trainGroupsFound, groupName)
            --env.info("Train Group System: Found train group '" .. groupName .. "', checking status...")
            
            if not trainGroupsDestroyed[groupName] then
                local units = group:getUnits()
                local isDestroyed = false
                
                if not units or #units == 0 then
                    isDestroyed = true
                    --env.info("Train Group System: '" .. groupName .. "' has no units - DESTROYED")
                else
                    -- For trains, check if the single unit is alive
                    local unit = units[1]
                    if not unit or not unit:isExist() or unit:getLife() <= 1 then
                        isDestroyed = true
                        --env.info("Train Group System: '" .. groupName .. "' unit is destroyed/dead - DESTROYED")
                    --else
                        --env.info("Train Group System: '" .. groupName .. "' is still operational (life: " .. unit:getLife() .. ")")
                    end
                end
                
                if isDestroyed then
                    -- Train group has been destroyed
                    trainGroupsDestroyed[groupName] = true
                    CustomFlags[groupName] = true
                    
                    --env.info("Train Group System: '" .. groupName .. "' destroyed, setting CustomFlag")
                    
                    -- Determine coalition for feedback and credits
                    local rewardCoalition, creditAmount
                    if groupName:find("AXE_Train_") then
                        -- Red train destroyed, reward Blue coalition
                        rewardCoalition = 2
                        creditAmount = 1000
                        trigger.action.outTextForCoalition(2, 
                            "Enemy train " .. groupName .. " destroyed!", 10)
                        --env.info("Train Group System: Rewarding BLUE coalition for destroying RED train '" .. groupName .. "'")
                    elseif groupName:find("UK_Train_") then
                        -- Blue train destroyed, reward Red coalition
                        rewardCoalition = 1
                        creditAmount = 1000
                        trigger.action.outTextForCoalition(1, 
                            "Enemy train " .. groupName .. " destroyed!", 10)
                        --env.info("Train Group System: Rewarding RED coalition for destroying BLUE train '" .. groupName .. "'")
                    end
                    
                    -- Award bonus credits for destroying strategic asset
                    if rewardCoalition and creditAmount then
                        bc:addFunds(rewardCoalition, creditAmount)
                        trigger.action.outTextForCoalition(rewardCoalition, 
                            "Strategic asset destroyed: +" .. creditAmount .. " credits", 10)
                        --env.info("Train Group System: Awarded " .. creditAmount .. " credits to coalition " .. rewardCoalition)
                    end
                    
                    -- Update supply arrow display to reflect broken supply chain
                    --env.info("Train Group System: Refreshing supply arrows due to train destruction")
                    bc:drawSupplyArrowsDebounced()
                    
                    -- Notify about supply chain disruption
                    if rewardCoalition then
                        trigger.action.outTextForCoalition(rewardCoalition, 
                            "Enemy supply chain disrupted! Train routes now cut off.", 15)
                    end
                end
            -- else
            --     env.info("Train Group System: '" .. groupName .. "' already marked as destroyed")
            end
        end
    end
    
    --env.info("Train Group System: Found " .. trainGroupCount .. " train groups total:")
    for i, name in ipairs(trainGroupsFound) do
        env.info("Train Group System:   " .. i .. ". " .. name)
    end
    
    env.info("Train Group System: ===== TRAIN MONITORING CYCLE COMPLETE =====")
end, {}, 60, 120)

-- SCHEDULER:New(nil, function()
--     for name, sceneries in pairs(sceneryList) do
--         local allBelow50 = true
--         for _, scenery in ipairs(sceneries) do
--             if scenery and scenery:GetRelativeLife() > 50 then
--                 allBelow50 = false
--                 break
--             end
--         end
--         if allBelow50 then
--             CustomFlags[name] = true
--             -- Check if this is a railway station and process group destruction
--             if name:lower():find("railway") then
--                 destroyRailwayDependentGroups(name)
--             end
--         end
--     end
-- end, {}, 60, 60)

SCHEDULER:New(nil, function()
    env.info("Real-time Railway Monitoring: Checking scenery health...")
    
    for name, sceneries in pairs(sceneryList) do
        local allBelow50 = true
        local anyDestroyed = false
        
        for _, scenery in ipairs(sceneries) do
            if scenery then
                local life = scenery:GetRelativeLife()
                if life > 50 then
                    allBelow50 = false
                else
                    anyDestroyed = true
                end
            end
        end
        
        -- Check if this railway station was just destroyed (not already flagged)
        if allBelow50 and not CustomFlags[name] then
            env.info("Real-time Railway Monitoring: " .. name .. " just destroyed! Destroying dependent trains...")
            CustomFlags[name] = true
            
            -- CRITICAL: Call the train destruction function immediately during gameplay
            if name:lower():find("railway") then
                destroyRailwayDependentGroups(name)
                env.info("Real-time Railway Monitoring: Processed train destruction for " .. name)
            end
        elseif not allBelow50 and CustomFlags[name] then
            -- Railway has been repaired/restored
            env.info("Real-time Railway Monitoring: " .. name .. " has been restored")
            CustomFlags[name] = nil
        end
    end
    
    env.info("Real-time Railway Monitoring: Check complete")
end, {}, 30, 60)

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
        local MissionType = "Resupply"
        ActiveCurrentMission[resupplyTarget] = MissionType
        local z = bc:getZoneByName(resupplyTarget) ; if z then z:updateLabel() end
        if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "ding.ogg")
        end
    end,
    endAction = function()       
        local MissionType = "Resupply"
        if ActiveCurrentMission[resupplyTarget] == MissionType then
            ActiveCurrentMission[resupplyTarget] = nil
        end
        local z = bc:getZoneByName(resupplyTarget) ; if z then z:updateLabel() end
        resupplyTarget = nil
        if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
    isActive = function()
        if not resupplyTarget then return false end

        local targetzn = bc:getZoneByName(resupplyTarget)
        return targetzn and targetzn.side == 2 and targetzn:canRecieveSupply()
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
		ActiveCurrentMission[attackTarget] = ActiveCurrentMission[attackTarget] or {}
		ActiveCurrentMission[attackTarget]["Attack"] = true
		local z = bc:getZoneByName(attackTarget) if z then z:updateLabel() end
		if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
			trigger.action.outSoundForCoalition(2, "cas.ogg")
		end
	end,
	endAction = function()
		local t = (type(ActiveCurrentMission) == 'table') and ActiveCurrentMission[attackTarget] or nil
		if type(t) == 'table' then
			t["Attack"] = nil
			if not next(t) then ActiveCurrentMission[attackTarget] = nil end
		end
		local z = bc:getZoneByName(attackTarget) if z then z:updateLabel() end
		attackTarget = nil
		if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
			trigger.action.outSoundForCoalition(2, "cancel.ogg")
		end
	end,
    isActive = function()
        if not attackTarget then return false end
        local targetzn = bc:getZoneByName(attackTarget)
        return targetzn.side == 1 and not targetzn.suspended
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
        local MissionType = "Capture"
        ActiveCurrentMission[captureTarget] = MissionType
        local z = bc:getZoneByName(captureTarget) ; if z then z:updateLabel() end
        if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
            trigger.action.outSoundForCoalition(2, "ding.ogg")
        end
    end,
    endAction = function()
        local MissionType = "Capture"
        if ActiveCurrentMission[captureTarget] == MissionType then
            ActiveCurrentMission[captureTarget] = nil
        end
        local z = bc:getZoneByName(captureTarget) ; if z then z:updateLabel() end
        captureTarget = nil
        if not missionCompleted then
            trigger.action.outSoundForCoalition(2, "cancel.ogg")
        end
    end,
    isActive = function()
        if not captureTarget then return false end
        local targetzn = bc:getZoneByName(captureTarget)
        return targetzn.side == 0 and targetzn.active
    end
})


function generateCaptureMission()
    if captureTarget ~= nil then return end
    
    local validzones = {}
    for _, v in ipairs(bc.zones) do

        if v.active and v.side == 0 and (not v.NeutralAtStart or v.firstCaptureByRed) and
           not v.ForceNeutral and not string.find(v.zone, "Hidden") and (not v.zone:find("AxeCarrierGroup")) then
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
            local pname  = capWinner
            bc.playerContributions[2][pname] = (bc.playerContributions[2][pname] or 0) + reward
            local jp = bc.jointPairs and bc.jointPairs[pname]
            if jp and bc:_jointPartnerAlive(pname) and bc:_jointPartnerAlive(jp) and bc.playerContributions[2][jp] ~= nil then
                bc.playerContributions[2][jp] = (bc.playerContributions[2][jp] or 0) + reward
                bc:addTempStat(jp,'CAP mission (Joint mission)',1)
                bc:addTempStat(pname,'CAP mission (Joint mission)',1)
                trigger.action.outTextForCoalition(2,"["..pname.."] and ["..jp.."] completed the CAP mission!\nReward pending: "..reward.." credits each (land to redeem).",20)
                local jgn = bc.groupNameByPlayer[jp]
                local jgr = Group.getByName(jgn)
                if jgr then
                    local ju = jgr:getUnit(1)
                    if ju and not Utils.isInAir(ju) then
                        SCHEDULER:New(nil,function()
                            if ju and ju:isExist() then
                                world.onEvent({id=world.event.S_EVENT_LAND,time=timer.getAbsTime(),initiator=ju,initiatorPilotName=jp,initiator_unit_type=ju:getTypeName(),initiator_coalition=ju:getCoalition(),skipRewardMsg=true})
                            end
                        end,{},5,0)
                    end
                end
            else
                bc:addTempStat(pname,'CAP mission',1)
                trigger.action.outTextForCoalition(2,"["..pname.."] completed the CAP mission!\nReward pending: "..reward.." credits (land to redeem).",20)
            end
            capMissionCooldownUntil = timer.getTime() + 900
        end
        capMissionTarget = nil
        capKillsByPlayer = {}
        capWinner        = nil
        capTargetPlanes  = 0
        if not missionCompleted then
            trigger.action.outSoundForCoalition(2,"cancel.ogg")
        end
	end,
    isActive = function()
        if not capMissionTarget then return false end
        return true
    end
})



--                    End of CAP MISSION                           --
---------------------------------------------------------------------

---------------------------------------------------------------------
--                          CAS MISSION                            --
casMissionTarget = nil
casKillsByPlayer = {}
casTargetKills = 0
casWinner = nil
casMissionCooldownUntil = 0

mc:trackMission({
	title = function() return 'CAS mission' end,
	description = function()
		if not next(casKillsByPlayer) then
			return 'Destroy '..casTargetKills..' ground targets without getting shot down, who wins?'
		else
			local scoreboard = 'Current Kill Count:\n'
			for playerName, kills in pairs(casKillsByPlayer) do
				scoreboard = scoreboard..string.format('%s: %d\n', playerName, kills)
			end
			return string.format('Destroy %d ground targets, who wins?\n\n%s', casTargetKills, scoreboard)
		end
	end,
	messageStart = function()
		return 'New CAS mission: Destroy '..casTargetKills..' ground targets.'
	end,
	messageEnd = '',
	startAction = function()
		if not missionCompleted then trigger.action.outSoundForCoalition(2,'ding.ogg') end
	end,
    endAction = function()
        if casWinner then
            local reward = casTargetKills*30
            local pname  = casWinner
            bc.playerContributions[2][pname] = (bc.playerContributions[2][pname] or 0) + reward
            local jp = bc.jointPairs and bc.jointPairs[pname]
            if jp and bc:_jointPartnerAlive(pname) and bc:_jointPartnerAlive(jp) and bc.playerContributions[2][jp] ~= nil then
                bc.playerContributions[2][jp] = (bc.playerContributions[2][jp] or 0) + reward
            	bc:addTempStat(jp,'CAS mission (Joint mission)',1)
				bc:addTempStat(pname,'CAS mission (Joint mission)',1)
				trigger.action.outTextForCoalition(2,'['..pname..'] and ['..jp..'] completed the CAS mission!\nReward pending: '..reward..' credits each (land to redeem).',20)
                local jgn = bc.groupNameByPlayer[jp]
                local jgr = Group.getByName(jgn)
                if jgr then
                    local ju = jgr:getUnit(1)
                    if ju and not Utils.isInAir(ju) then
                        SCHEDULER:New(nil,function()
                            if ju and ju:isExist() then
                                world.onEvent({id=world.event.S_EVENT_LAND,time=timer.getAbsTime(),initiator=ju,initiatorPilotName=jp,initiator_unit_type=ju:getTypeName(),initiator_coalition=ju:getCoalition(),skipRewardMsg=true})
                            end
                        end,{},5,0)
                    end
                end
			else
            	bc:addTempStat(pname,'CAS mission',1)
				trigger.action.outTextForCoalition(2,'['..pname..'] completed the CAS mission!\nReward pending: '..reward..' credits (land to redeem).',20)
			end
            
            casMissionCooldownUntil = timer.getTime()+900
        end
        casMissionTarget  = nil
        casKillsByPlayer  = {}
        casWinner         = nil
        casTargetKills    = 0
        if not missionCompleted then trigger.action.outSoundForCoalition(2,'cancel.ogg') end
    end,
	isActive = function()
		if not casMissionTarget then return false end
		return true
	end
})
--                    End of CAS MISSION                           --
---------------------------------------------------------------------

---------------------------------------------------------------------
--                     		ESCORT MISSION                         --

function generateEscortMission(zoneName, groupName, groupID, group, mission)
    local mission = mission or missions[zoneName]
    if not mission then return false end

    missionGroupIDs[zoneName] = missionGroupIDs[zoneName] or {}
    missionGroupIDs[zoneName][groupID] = {
        groupID = groupID,
        group = group
    }
	if IsGroupActive(mission.missionGroup) then
		trigger.action.outSoundForGroup(groupID, "ding.ogg")
		trigger.action.outTextForGroup(groupID, "Active mission is pending:\n\nEscort convoy from " .. mission.zone .. " to " .. mission.TargetZone, 30)
        return
    end
	if mc.missionFlags[zoneName] then
			trigger.action.outSoundForGroup(groupID, "ding.ogg")
			trigger.action.outTextForGroup(groupID, "Special mission available:\n\nEscort convoy from " .. mission.zone .. " to " .. mission.TargetZone, 30)
		return 
	end

    mc:trackMission({
        MainTitle = function() return "Escort mission" end,
        title = function() return "Escort mission" end,
		titleBefore = function(self)
			self.notified = true
			trigger.action.outSoundForGroup(groupID, "ding.ogg")
			trigger.action.outTextForGroup(groupID, "Special mission available:\n\nEscort convoy from " .. mission.zone .. " to " .. mission.TargetZone, 30)
		 end,
        description = function() return "\nEscort a convoy to " .. mission.TargetZone .. "\nThe roads are filled with hostile enemies." end,
        isEscortMission = true,
        accept = false,
        missionGroup = mission.missionGroup,
        zoneName = zoneName,
        messageStart = function() return "Escort convoy to " .. mission.TargetZone end,
		missionFail = function(self)
		self.accept = false
		if not IsGroupActive(mission.missionGroup) then
			mc.missionFlags[zoneName] = nil
			if missionGroupIDs[zoneName] and next(missionGroupIDs[zoneName]) then
				for groupName, data in pairs(missionGroupIDs[zoneName]) do
					local groupID = data.groupID
					local group = data.group
					trigger.action.outSoundForGroup(groupID, "cancel.ogg")
					trigger.action.outTextForGroup(groupID, "Mission failed:\n\nConvoy was destroyed\n\nStandby, looking for a new group...", 30)
					removeMissionMenuForAll(mission.zone, groupID)
					if trackedGroups[groupName] then
						trackedGroups[groupName] = nil
						--handleMission(zoneName, groupName, groupID, group)
					end
				end
			else
				trigger.action.outSoundForCoalition(2, "cancel.ogg")
				trigger.action.outTextForCoalition(2, "Mission failed:\n\nConvoy was destroyed", 30)
				removeMissionMenuForAll(mission.zone, nil, true)
				destroyGroupIfActive(mission.missionGroup)
			end
			return true
		end
		return false
		end,
		startOver = function(self)
			timer.scheduleFunction(function()
		if missionGroupIDs[zoneName] then
			for groupName, data in pairs(missionGroupIDs[zoneName]) do
				local groupID = data.groupID
				local group = data.group
				handleMission(zoneName, groupName, groupID, group)
				return nil
			end
		end	
			end, nil, timer.getTime() + 10)
		end,
        startAction = function() return IsGroupActive(mission.missionGroup) end,
		endAction = function()
			local targetZone = bc:getZoneByName(mission.TargetZone)
			if targetZone.side == 2 and targetZone.active then
				local reward   = 1000
				local playlist = {}
				if missionGroupIDs[zoneName] then
					for _, data in pairs(missionGroupIDs[zoneName]) do
						local grp = data.group
						if grp and grp:isExist() then
							for _, u in pairs(grp:getUnits()) do
								local pl = u:getPlayerName()
								if pl and pl ~= "" then
									playlist[pl] = true
								end
							end
						end
					end
				end
				local cnt   = 0
				local names = {}
				for pl in pairs(playlist) do
					cnt = cnt + 1
					names[#names + 1] = pl
				end
				local share = cnt > 0 and math.floor(reward / cnt) or reward
				if cnt > 0 then
					for pl in pairs(playlist) do
						if bc.playerContributions[2][pl] ~= nil then
							bc.playerContributions[2][pl] = bc.playerContributions[2][pl] + share
							bc:addTempStat(pl,'Escort Mission',1)
						end
					end
				else
					bc:addFunds(2, reward)
				end
				if missionGroupIDs[zoneName] then
					for groupName, data in pairs(missionGroupIDs[zoneName]) do
						local groupID = data.groupID
						local grp     = data.group
						if grp and grp:isExist() then
							removeMissionMenuForAll(mission.zone, groupID)
						end
						if trackedGroups[groupName] then
							trackedGroups[groupName] = nil
						end
						destroyGroupIfActive(mission.missionGroup)
						timer.scheduleFunction(function()
							handleMission(mission.TargetZone, groupName, groupID, grp)
						end, nil, timer.getTime() + 30)
					end
				else
					removeMissionMenuForAll(mission.zone, nil, true)
					destroyGroupIfActive(mission.missionGroup)
				end
				mc.missionFlags[zoneName] = nil
				local msg
				if cnt > 1 then
					msg = "Escort mission completed by " .. table.concat(names, ", ") .. "\ncredit " .. share .. " each - land to redeem"
				elseif cnt == 1 then
					msg = "Escort mission completed by " .. names[1] .. "\ncredit " .. reward .. " - land to redeem"
				else
					msg = "Escort mission completed — no players alive.\nReward + " .. reward
				end
				trigger.action.outSoundForCoalition(2, "ding.ogg")
				trigger.action.outTextForCoalition(2, msg, 20)
				return true
			end
			return false
		end,
        isActive = function()
            local targetZone = bc:getZoneByName(mission.TargetZone)
            if targetZone.side ~= 2 and targetZone.active and not targetZone.suspended then
                return true
            end
            return false
        end,
        returnAccepted = function(self)
            if not self.accept then return false end
            return IsGroupActive(mission.missionGroup)
        end,
    })

    mc.missionFlags[zoneName] = true
	mc.escortMissionGenerated = true
end

---------------------------------------------------------------------
--                     END OF ESCORT MISSION                       --

---------------------------------------------------------------------
--                      RUNWAY STRIKE MISSION                     --

mc:trackMission({
    title=function() return 'Bomb runway' end,
    description=function()
      local wp=WaypointList[runwayTargetZone] or ""
      if #runwayNames>1 then
        return 'Drop 1 bomb on each runway at '..runwayTargetZone..wp
      else
        return 'Drop 1 bomb on the runway at '..runwayTargetZone..wp
      end
    end,
    messageStart=function()
    local wp=WaypointList[runwayTargetZone] or ""
      if #runwayNames>1 then
        return 'New mission: Bomb all runways at '..runwayTargetZone..wp
      else
        return 'New mission: Bomb runway at '..runwayTargetZone..wp
      end
    end,
	messageEnd = function()
		trigger.action.outSoundForCoalition(2,'cancel.ogg')
		if runwayTargetZone then
			if runwayCompleted then
				local cred = (need and need>1) and 200 or 100
				if bomberName and runwayPartnerName then
					return 'Mission ended: Bomb runway at '..runwayTargetZone..' completed by '..bomberName..' and '..runwayPartnerName..'\ncredit '..cred..' each - land to redeem'
				elseif bomberName then
					return 'Mission ended: Bomb runway at '..runwayTargetZone..' completed by '..bomberName..'\ncredit '..cred..' - land to redeem'
				else
					return 'Mission ended: Bomb runway at '..runwayTargetZone..' completed'
				end
			else
				return 'Mission ended: Bomb runway at '..runwayTargetZone..' canceled'
			end
		else
			return 'Mission canceled: Bomb runway'
		end
	end,
	startAction = function()
    ActiveCurrentMission[runwayTargetZone] = type(ActiveCurrentMission[runwayTargetZone]) == 'table' and ActiveCurrentMission[runwayTargetZone] or {}
    ActiveCurrentMission[runwayTargetZone]["Bomb runway"] = true

	local z = bc:getZoneByName(runwayTargetZone) if z then z:updateLabel() end
	if not missionCompleted and trigger.misc.getUserFlag(180) == 0 then
		trigger.action.outSoundForCoalition(2, "ding.ogg")
	end
	end,
endAction = function()
    if RunwayHandler then
        RunwayHandler:UnHandleEvent(EVENTS.Shot)
        RunwayHandler = nil
        runwayMission = nil
    end
    if runwayTargetZone then
        RUNWAY_ZONE_COOLDOWN[runwayTargetZone] = timer.getTime() + 1800
        local t = (type(ActiveCurrentMission) == 'table') and ActiveCurrentMission[runwayTargetZone] or nil
        if type(t) == 'table' then
            t["Bomb runway"] = nil
            if not next(t) then ActiveCurrentMission[runwayTargetZone] = nil end
        end
        local z = bc:getZoneByName(runwayTargetZone) if z then z:updateLabel() end
    end
    runwayCooldown = timer.getTime() + 900
    runwayTargetZone, bomberName, runwayTarget = nil, nil, nil
end,
	isActive = function()
        if not runwayMission then return false end
        local targetzn = bc:getZoneByName(runwayTargetZone)
        return targetzn and targetzn.side == 1
    end
})

---------------------------------------------------------------------
--                 END OF RUNWAY STRIKE MISSION                   --

function generateAttackMission()
    if missionCompleted then return end
    if attackTarget ~= nil then return end

	local validzones = {}
	for _, v in ipairs(bc.connections) do
		local from, to = bc:getConnectionZones(v)

        local function checkValid(zone)
			local lname = zone.zone:lower()
            return zone.side == 1 and zone.active and not isZoneUnderSEADMission(zone.zone)
			and not lname:find('sam') and not lname:find('defence') and not lname:find('papa') and
			not lname:find('juliett') and not lname:find('india') and not lname:find('delta') and
			not lname:find('bravo') and not lname:find('hotel')
        end

	if from and to and from.side ~= to.side and from.side ~= 0 and to.side ~= 0 and 
		((not to.suspended) or from.suspended) then
			if checkValid(from) then table.insert(validzones, from.zone) end
			if checkValid(to)   then table.insert(validzones, to.zone)   end
		end
	end

    if #validzones == 0 then return end

    local choice = math.random(1, #validzones)
    attackTarget = validzones[choice]
    return true
end

function generateSupplyMission()
	if resupplyTarget ~= nil then return end
		
	local validzones = {}
	for _,v in ipairs(bc.zones) do
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
end, {}, timer.getTime() + 35)
timer.scheduleFunction(function(_, time)
	if checkAndGenerateCASMission() then
		return time+300
	else
		return time+120
	end
end, {}, timer.getTime() + 180)
timer.scheduleFunction(function(_, time)
	if generateSupplyMission() then
		return time+300
	else
		return time+120
	end
end, {}, timer.getTime() + 60)
timer.scheduleFunction(function(_,time)
   if checkAndGenerateCAPMission() then
		return time+300
	else
		return time+120
	end
end, {}, timer.getTime() + 480)
timer.scheduleFunction(function(_,time)
    if generateRunwayStrikeMission() then
        return time+300
    else
        return time+120
    end
end,{},timer.getTime()+210)
mc:init()

----------------------- FLAGS --------------------------

function checkZoneFlags()

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
		--env.info("Flag 200 triggered")
		local znsrc = bc:getZoneByName('Cherbourg')
		local zntgt = bc:getZoneByName('Valognes')
            if znsrc and znsrc.side == 1 then 
				if zntgt and zntgt.side == 0 then
					zntgt:capture(1)
					--trigger.action.outText("Valognes captured ", 10)
					--env.info("Valognes captured")
				elseif zntgt and zntgt.side == 1 then
					zntgt:upgrade()
					--trigger.action.outText("Valognes upgraded ", 10)
					--env.info("Valognes upgraded")
				else
					return 'Valognes is blue zone'
				end
			else
				--trigger.action.outText("Cherbourg is not Red, cannot capture or upgrade Valognes", 10)
				--env.info("Cherbourg is not Red zone")
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

buildingCache = buildingCache or {}
for _, z in ipairs(bc:getZones()) do
	local c = CustomZone:getByName(z.zone)
	if c then c:getZoneBuildings() end
end
----------------------- END OF FLAGS --------------------------
--configure zone messages 


env.info("Mission Setup : is completed!")