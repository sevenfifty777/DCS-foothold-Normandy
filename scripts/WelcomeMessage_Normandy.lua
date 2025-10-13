BASE:I("Loading Leka's special all in one script handler")

-- This script handles statics, Welcome messages, Callsign assigement, Escort, Missle tracking, Radio menu for ATIS and getting closest Airbase.

-- This script needs cuople of things, Static unit called EventMan and the carrier named CVN-72 or change those names bellow,
-- most importantly it needs Moose.

static = STATIC:FindByName("EventMan", true)


local atisZones = {
    ["BigginHill"] = {airbaseName = AIRBASE.Normandy.Biggin_Hill},
    ["Odiham"] = {airbaseName = AIRBASE.Normandy.Odiham},
    ["Farnborough"] = {airbaseName = AIRBASE.Normandy.Farnborough},
    ["Manston"] = {airbaseName = AIRBASE.Normandy.Manston},
    ["Hawkinge"] = {airbaseName = AIRBASE.Normandy.Hawkinge},
    ["Lympne"] = {airbaseName = AIRBASE.Normandy.Lympne},
    ["Chailey"] = {airbaseName = AIRBASE.Normandy.Chailey},
    ["Ford"] = {airbaseName = AIRBASE.Normandy.Ford},
    ["Tangmere"] = {airbaseName = AIRBASE.Normandy.Tangmere},
    ["Funtington"] = {airbaseName = AIRBASE.Normandy.Funtington},
    ["Needs Oar Point"] = {airbaseName = AIRBASE.Normandy.Needs_Oar_Point},
    ["Friston"] = {airbaseName = AIRBASE.Normandy.Friston},
    ["Dunkirk"] = {airbaseName = AIRBASE.Normandy.Dunkirk_Mardyck},
    ["Saint-Omer"] = {airbaseName = AIRBASE.Normandy.Saint_Omer_Wizernes},
    ["Merville"] = {airbaseName = AIRBASE.Normandy.Merville_Calonne},
    ["Abbeville"] = {airbaseName = AIRBASE.Normandy.Abbeville_Drucat},
    ["Amiens"] = {airbaseName = AIRBASE.Normandy.Amiens_Glisy},
    ["Saint-Aubain"] = {airbaseName = AIRBASE.Normandy.Saint_Aubin},
    ["Fecamp"] = {airbaseName = AIRBASE.Normandy.Fecamp_Benouville},
    ["Rouen"] = {airbaseName = AIRBASE.Normandy.Rouen_Boos},
    ["Carpiquet"] = {airbaseName = AIRBASE.Normandy.Carpiquet},
    ["Sainte-Croix"] = {airbaseName = AIRBASE.Normandy.Sainte_Croix_sur_Mer},
    ["Saint-Pierre"] = {airbaseName = AIRBASE.Normandy.Saint_Pierre_du_Mont},
    ["Longues-Sur-Mer"] = {airbaseName = AIRBASE.Normandy.Longues_sur_Mer},
    ["Cricqueville"] = {airbaseName = AIRBASE.Normandy.Cricqueville_en_Bessin},
    ["Le Molay"] = {airbaseName = AIRBASE.Normandy.Le_Molay},
    ["Brucheville"] = {airbaseName = AIRBASE.Normandy.Brucheville},
    ["Maupertus"] = {airbaseName = AIRBASE.Normandy.Maupertus},
    ["Bernay"] = {airbaseName = AIRBASE.Normandy.Bernay_Saint_Martin},
    ["Saint-Andre"] = {airbaseName = AIRBASE.Normandy.Saint_Andre_de_lEure},
    ["Orly"] = {airbaseName = AIRBASE.Normandy.Orly},
}
local atisZoneNames = {

}
-- Define all zones
local allZones = {
    "CarrierGroup", "AxeCarrierGroup", "BigginHill", "Odiham", "Farnborough", "Manston", "Hawkinge", "Lympne", "Chailey", "Ford", "Tangmere", "Funtington",
    "Needs Oar Point", "Friston", "Dunkirk", "Dunkirk-Port", "Saint-Omer", "Merville", "Abbeville", "Amiens", "Cherbourg", "Calais", "Saint-Aubain",
    "Fecamp", "Le Havre", "Rouen", "Carpiquet", "Caen", "Sainte-Croix", "Saint-Pierre", "Longues-Sur-Mer", "Cricqueville", "Le Molay", "Brucheville",
    "Valognes", "Maupertus", "Bernay", "Saint-Andre", "Paris", "Orly", "London", "Le Touquet", "Pointe des Groins", "Pointe du Hoc", "Cap Gris-Nez", "Dover"
}



airbaseStatics = {
}

followID={}
staticDetails = {}

function GatherStaticDetails()
    for airbaseName, staticNames in pairs(airbaseStatics) do
        for _, staticName in ipairs(staticNames) do
            local static = STATIC:FindByName(staticName,true)
            if static and static:IsAlive() then
                local point = static:GetPointVec3()
                local typeName = static:GetTypeName()
                if typeName == ".Command Center" then
                shapeName = shapeName or "ComCenter"
                end
                local coalitionSide = static:GetCoalition()
                local heading = static:GetHeading()
                staticDetails[staticName] = {
                    airbaseName = airbaseName,
                    typeName = typeName,
                    shapeName = shapeName,
                    coalitionSide = coalitionSide,
                    point = point,
                    heading = heading,
                }
            else
                env.info("Static not found or not alive: " .. staticName)
            end
        end
    end
end

function RespawnStaticsForAirbase(airbaseName, coalitionSide)
    local statics = airbaseStatics[airbaseName]
    if not statics then
        return
    end

    local countryID
    if coalitionSide == coalition.side.BLUE then
        countryID = country.id.USA
    elseif coalitionSide == coalition.side.RED then
        countryID = country.id.RUSSIA
    else
        return
    end

    for _, staticName in ipairs(statics) do
        local static = STATIC:FindByName(staticName, false)
        if static and static:IsAlive() then
            static:ReSpawn(countryID)
        else
            local details = staticDetails[staticName]
            if details then
                local headingInRadians = math.rad(details.heading)
                local spawnTemplate = {
                    ["name"] = staticName,
                    ["type"] = details.typeName,
                    ["category"] = "Static",
                    ["country"] = countryID,
                    ["heading"] = headingInRadians,
                    ["position"] = details.point,
                }
                local spawnStatic = SPAWNSTATIC:NewFromTemplate(spawnTemplate, countryID)
                spawnStatic:SpawnFromCoordinate(COORDINATE:NewFromVec3(details.point))
            end
        end
    end
end

GatherStaticDetails()


local zoneAssignments = {}
local playerZoneVisits = {}
local globalCallsignAssignments = {}

function logZoneAssignments()
    BASE:I("Zone Assignments:")
    for zone, assignments in pairs(zoneAssignments) do
        BASE:I("Zone: " .. zone)
        for fullCallsign, assignedPlayer in pairs(assignments) do
            BASE:I("    Callsign: " .. fullCallsign .. " -> Player: " .. assignedPlayer)
        end
    end
end
local function isCallsignUsedInOtherZones(fullCallsign, currentZone)
    for zone, assignments in pairs(zoneAssignments) do
        if assignments[fullCallsign] then
            if zone ~= currentZone then
                return true
            elseif assignments[fullCallsign] then
                return true
            end
        end
    end
    return false
end

function getPlayerAssignment(playerName)
    if globalCallsignAssignments[playerName] then
        local callsignInfo = globalCallsignAssignments[playerName]
        BASE:I(string.format("Player '%s' has callsign '%s' in zone '%s'", playerName, callsignInfo.callsign, callsignInfo.zoneName))
        return callsignInfo.callsign, callsignInfo.zoneName
    end
    BASE:I(string.format("Player '%s' has no callsign assignment.", playerName))
    return nil, nil
end

function findOrAssignSlot(playerName, groupName, zoneName)
    local existingCallsign, assignedZone = getPlayerAssignment(playerName)
    if existingCallsign then
        if assignedZone == zoneName then
            for prefix, typeAssignments in pairs(aircraftAssignments) do
                if string.find(groupName, prefix) then
                    for callsign, details in pairs(typeAssignments) do
                        if string.find(existingCallsign, callsign) then
                            local number = tonumber(string.sub(existingCallsign, -1))
                            if number then
                                local IFF = details.IFFs[number]
                                BASE:I(string.format("Reusing existing callsign %s for player %s in zone %s", existingCallsign, playerName, zoneName))
                                return existingCallsign, IFF
                            end
                        end
                    end
                end
            end
        else
            releaseSlot(playerName, assignedZone)
            globalCallsignAssignments[playerName] = nil
            BASE:I("Removed old callsign " .. existingCallsign .. " for player: " .. playerName)
        end
    end

    zoneAssignments[zoneName] = zoneAssignments[zoneName] or {}

    local prefix, preferredOrder = getPreferredOrder(groupName)
    if not preferredOrder then return nil, nil end

    if #preferredOrder == 1 then
        local baseCallsign = preferredOrder[1]
        local maxNumber = 0
        for zone, assignments in pairs(zoneAssignments) do
            for fullCallsign in pairs(assignments) do
                if string.find(fullCallsign, baseCallsign) then
                    local number = tonumber(string.sub(fullCallsign, -1))
                    if number and number > maxNumber then maxNumber = number end
                end
            end
        end
        local newCallsign = baseCallsign .. (maxNumber + 1)
        local IFF = aircraftAssignments[prefix][baseCallsign].IFFs[(maxNumber % #aircraftAssignments[prefix][baseCallsign].IFFs) + 1]
        zoneAssignments[zoneName][newCallsign] = playerName
        globalCallsignAssignments[playerName] = {callsign = newCallsign, zoneName = zoneName, groupName = groupName}
        BASE:I(string.format("Assigned %s to player %s in zone %s", newCallsign, playerName, zoneName))
        logZoneAssignments()
        return newCallsign, IFF
    end

    local availableMainCallsign, existingPrefixInZone
    for _, mainCallsign in ipairs(preferredOrder) do
        for i = 1, #aircraftAssignments[prefix][mainCallsign].IFFs do
            local fullCallsign = mainCallsign .. "" .. i
            if zoneAssignments[zoneName][fullCallsign] then
                existingPrefixInZone = mainCallsign
                break
            end
        end
        if existingPrefixInZone then break end
    end

    if not existingPrefixInZone then
        for _, mainCallsign in ipairs(preferredOrder) do
            local usedElsewhere = false
            for zone, assignments in pairs(zoneAssignments) do
                if zone ~= zoneName then
                    for fullCallsign in pairs(assignments) do
                        if string.find(fullCallsign, mainCallsign) then usedElsewhere = true break end
                    end
                end
            end
            if not usedElsewhere then availableMainCallsign = mainCallsign break end
        end
    else
        availableMainCallsign = existingPrefixInZone
    end

    if availableMainCallsign then
        for i, IFF in ipairs(aircraftAssignments[prefix][availableMainCallsign].IFFs) do
            local fullCallsign = availableMainCallsign .. "" .. i
            if not zoneAssignments[zoneName][fullCallsign] then
                zoneAssignments[zoneName][fullCallsign] = playerName
                globalCallsignAssignments[playerName] = {callsign = fullCallsign, zoneName = zoneName, groupName=groupName}
                BASE:I(string.format("Assigned %s to player %s in zone %s", fullCallsign, playerName, zoneName))
                logZoneAssignments()
                return fullCallsign, IFF
            end
        end
    end

    for _, mainCallsign in ipairs(preferredOrder) do
        for i, IFF in ipairs(aircraftAssignments[prefix][mainCallsign].IFFs) do
            local fullCallsign = mainCallsign .. "" .. i
            if not isCallsignUsedInOtherZones(fullCallsign, zoneName) and not zoneAssignments[zoneName][fullCallsign] then
                zoneAssignments[zoneName][fullCallsign] = playerName
                globalCallsignAssignments[playerName] = {callsign = fullCallsign, zoneName = zoneName, groupName=groupName}
                BASE:I(string.format("Assigned %s to player %s in zone %s (cycled back, first available)", fullCallsign, playerName, zoneName))
                logZoneAssignments()
                return fullCallsign, IFF
            end
        end
    end

    for _, mainCallsign in ipairs(preferredOrder) do
        for i, IFF in ipairs(aircraftAssignments[prefix][mainCallsign].IFFs) do
            local fullCallsign = mainCallsign .. "" .. i
            if not zoneAssignments[zoneName][fullCallsign] then
                zoneAssignments[zoneName][fullCallsign] = playerName
                globalCallsignAssignments[playerName] = {callsign = fullCallsign, zoneName = zoneName,groupName=groupName}
                BASE:I(string.format("Assigned %s to player %s in zone %s (cycled back, fallback)", fullCallsign, playerName, zoneName))
                logZoneAssignments()
                return fullCallsign, IFF
            end
        end
    end

    return nil, nil
end

function getPreferredOrder(groupName)
    for prefix, typeAssignments in pairs(aircraftAssignments) do
        if string.find(groupName, prefix) then
            local order
            if prefix == "F.A.18"    then preferredOrder = {"Arctic1","Bender2","Crimson3","Dusty4","Lion3"}
            elseif prefix == "F.16CM"   then preferredOrder = {"Indy9","Jester1","Venom4"}
            elseif prefix == "A.10C"    then preferredOrder = {"Hawg8","Tusk2","Pig7"}
            elseif prefix == "AH.64D"   then preferredOrder = {"Rage9","Salty1"}
            elseif prefix == "AJS37"    then preferredOrder = {"Fenris6","Grim7"}
            elseif prefix == "UH.1H"    then preferredOrder = {"Nitro5"}
            elseif prefix == "CH.47F"   then preferredOrder = {"Greyhound3"}
            elseif prefix == "F.15E.S4" then preferredOrder = {"Hitman3"}
            elseif prefix == "F.14.B"   then preferredOrder = {"Elvis5","Mustang4"}
            elseif prefix == ".OH.58D"  then preferredOrder = {"Blackjack4"}
            elseif prefix == "Mi.24P"  then preferredOrder = {"Scorpion3"}
            elseif prefix == "AV.8B"  then preferredOrder = {"Quarterback1"}
            end
            return prefix, preferredOrder
        end
    end
end
aircraftAssignments = {
    ["F.A.18"] = {
        ["Arctic1"] = {
            IFFs = {1400, 1401, 1402, 1403},
            assignments = {}
        },
        ["Bender2"] = {
            IFFs = {1404, 1405, 1406, 1407},
            assignments = {}
        },
        ["Crimson3"] = {
            IFFs = {1410, 1411, 1412, 1413},
            assignments = {}
        },
        ["Dusty4"] = {
            IFFs = {1300, 1301, 1302, 1303},
            assignments = {}
        },
        ["Lion3"] = {
            IFFs = {1310, 1311, 1312, 1313},
            assignments = {}
        },
    },
    ["F.16CM"] = {
        ["Jester1"] = {
            IFFs = {1510, 1511, 1512, 1513},
            assignments = {}
        },
        ["Indy9"] = {
            IFFs = {1500, 1501, 1502, 1503},
            assignments = {}
        },
        ["Venom4"] = {
            IFFs = {1610, 1611, 1612, 1613},
            assignments = {}
        },
    },
    ["A.10C"] = {
        ["Hawg8"] = {
            IFFs = {1330, 1331, 1332, 1333},
            assignments = {}
        },
        ["Tusk2"] = {
            IFFs = {1350, 1351, 1352, 1353},
            assignments = {}
        },
        ["Pig7"] = {
            IFFs = {1340, 1341, 1342, 1343},
            assignments = {}
        },
    },
    ["AH.64D"] = {
        ["Rage9"] = {
            IFFs = {1610, 1611, 1612, 1613},
            assignments = {}
        },
        ["Salty1"] = {
            IFFs = {1620, 1621, 1622, 1623},
            assignments = {}
        },
    },
    ["AJS37"] = {
        ["Fenris6"] = {
            IFFs = {1060, 1061, 1062, 1063},
            assignments = {}
        },
        ["Grim7"] = {
            IFFs = {1070, 1071, 1072, 1073},
            assignments = {}
        },
    },
    ["UH.1H"] = {
        ["Nitro5"] = {
            IFFs = {1050, 1051, 1052, 1053},
            assignments = {}
        },
    },
    ["CH.47F"] = { 
        ["Greyhound3"] = { 
            IFFs = {1370, 1371, 1372, 1373}, 
            assignments = {}
        },
    },
    ["Mi.24P"] = { 
        ["Scorpion3"] = { 
            IFFs = {0610, 0611, 0612, 0613}, 
            assignments = {}
        },
    },
    ["AV.8B"] = { 
        ["Quarterback1"] = { 
            IFFs = {0434, 0435, 0436, 0437}, 
            assignments = {}
        },
    },
    ["F.15E.S4"] = { 
        ["Hitman3"] = { 
            IFFs = {1360, 1361, 1362, 1363}, 
            assignments = {}
        },
    },
	[".OH.58D"] = { 
        ["Blackjack4"] = { 
            IFFs = {1440, 1441, 1442, 1443}, 
            assignments = {}
        },
    },
    ["F.14.B"] = { 
        ["Elvis5"] = { 
            IFFs = {1100, 1101, 1102, 1103}, 
            assignments = {}
        },
        ["Mustang4"] = { 
            IFFs = {1104, 1105, 1106, 1107}, 
            assignments = {}
        },
    },
}

function releaseSlot(playerName, zoneName)
    if zoneAssignments[zoneName] then
        for callsign, assignedPlayer in pairs(zoneAssignments[zoneName]) do
            if assignedPlayer == playerName then
                zoneAssignments[zoneName][callsign] = nil

                globalCallsignAssignments[playerName] = nil

                BASE:I(string.format("Released %s from player %s in zone %s", callsign, playerName, zoneName))
                break
            end
        end
    end
end
function sendGreetingToPlayer(unitName,greetingMessage)
	local u=UNIT:FindByName(unitName)
	if not(u and u:IsAlive())then return end
	MESSAGE:New(greetingMessage,55,Information,true):ToUnit(u)
end
function sendDetailedMessageToPlayer(playerUnitID, message, playerGroupID, unitName)
    local u = UNIT:FindByName(unitName)
    if not (u and u:IsAlive()) then return end
    local g = u:GetGroup()
    if g then playerGroupID = g:GetID() end

    local dur = 120
    if u:InAir() then
    BASE:I(string.format("sendDetailedMessageToPlayer: Short message used for %s, altitude %.1f", unitName, u:GetAltitude(true)))
    dur = 10 end
    MESSAGE:New(message, dur):ToUnit(u)
    if playerGroupID and trigger.misc.getUserFlag(180) == 0 then
        trigger.action.outSoundForGroup(playerGroupID, "admin.wav")
    end
end
local function getAltimeter()
    local coord = COORDINATE:NewFromVec3({x = 0, y = 0, z = 0})
    local pressure_hPa = coord:GetPressure(0)  
    local pressureInHg = pressure_hPa * 0.0295300
    return string.format("Altimeter %.2f", pressureInHg)
end

local function getBRC()
    if IsGroupActive("CVN-73") then
        local myAirboss = AIRBOSS:New("CVN-73")
        local brc = myAirboss:GetBRC()
        return string.format("BRC %d°", brc)
    --elseif IsGroupActive("CVN-72") then
      --  local myAirboss2 = AIRBOSS:New("CVN-72")
      --  local brc = myAirboss2:GetBRC()
      --  return string.format("BRC %d°", brc)
    else
        return "BRC data unavailable"
    end
end

local function getCarrierWind()
    local cvn
    if IsGroupActive('CVN-73') then
        cvn = UNIT:FindByName("CVN-73")
    elseif IsGroupActive('CVN-72') then
        cvn = UNIT:FindByName("CVN-72")
    end
    if cvn then
        local cvnCoord = cvn:GetCoordinate()
        local windDirection, windSpeed = cvnCoord:GetWind(18)
        if windDirection and windSpeed then
            local windSpeedKnots = windSpeed * 1.94384  
            windDirection = (windDirection + 360) % 360
            return string.format("Wind is %03d° at %d knots", windDirection, windSpeedKnots)
        else
            return "Wind data unavailable"
        end
    else
        return "Carrier not found"
    end
end
function getCarrierInfo()
    if IsGroupActive("CVN-73") then
        return "George Washington", "73X"
    elseif IsGroupActive("CVN-72") then
        return "Abraham Lincoln", "72X"
    else
        return "Unknown Carrier", "N/A"
    end
end

local function getAirbaseWind(airbaseName)
    local airbase = AIRBASE:FindByName(airbaseName)
    if airbase then
        local airbaseCoord = airbase:GetCoordinate()  
        local windDirection, windSpeed = airbaseCoord:GetWind(10)
        if windDirection and windSpeed then
            local windSpeedKnots = math.floor(windSpeed * 1.94384)
            windDirection = (windDirection + 360) % 360
            return string.format("Wind is %03d° at %d", windDirection, windSpeedKnots), windDirection
        else
            return "Wind data unavailable", nil
        end
    else
        return "Airbase not found", nil
    end
end

local function fetchActiveRunway(zoneName)
    local airbase = AIRBASE:FindByName(atisZones[zoneName].airbaseName)
    if not airbase then
        trigger.action.outText("Airbase/FARP conflict detected or airbase not found: " .. atisZones[zoneName].airbaseName, 10)
        return "Airbase data unavailable."
    end
    local landingRunway, takeoffRunway = airbase:GetActiveRunway()
    if not landingRunway and not takeoffRunway then
        return "No active runway data available."
    end
    local landingRunwayName
    local takeoffRunwayName
    if landingRunway then
        landingRunwayName = airbase:GetRunwayName(landingRunway)
    end
    if takeoffRunway then
        takeoffRunwayName = airbase:GetRunwayName(takeoffRunway)
    end
    if landingRunwayName and takeoffRunwayName then
        if landingRunwayName == takeoffRunwayName then
            return string.format("Active runway is %s", landingRunwayName)
        else
            return string.format("Active runway for landing is %s, for takeoff is %s", landingRunwayName, takeoffRunwayName)
        end
    elseif landingRunwayName then
        return string.format("Active runway (landing) is %s", landingRunwayName)
    elseif takeoffRunwayName then
        return string.format("Active runway (takeoff) is %s", takeoffRunwayName)
    else
        return "No active runway data available."
    end
end

local function getPlayerWind(playerCoord)
    local playerPosition = playerCoord:GetVec3()
    local windVector = atmosphere.getWind(playerPosition)
    if windVector then
        local windSpeedMps = math.sqrt(windVector.x^2 + windVector.z^2)
        local windSpeedKnots = math.floor(windSpeedMps * 1.94384)
        local originalWindDirection = math.deg(math.atan2(windVector.z, windVector.x))
        originalWindDirection = (originalWindDirection + 360) % 360
        local originatingWindDirection = (originalWindDirection + 180) % 360
        return string.format("Wind is %03d° at %d", originatingWindDirection, windSpeedKnots), originatingWindDirection
    else
        return "Wind data unavailable", nil
    end
end
local function getPlayerTemperature(playerCoord)
    local playerPosition = playerCoord:GetVec3()
    local temperatureCelsius = playerCoord:GetTemperature(playerPosition.y)
    
    if temperatureCelsius then
        return string.format("Temperature is %d°C", temperatureCelsius)
    else
        return "Temperature data unavailable"
    end
end

-- ATIS MENU --

local function sendATISInformation(client, group, zoneName)
    if not client then return end
    local messageText  
    if string.find(zoneName, "Carrier") then
        local windMessage = getCarrierWind()
        local brcMessage = getBRC()  
        local altimeterMessage = getAltimeter()
        messageText = string.format("ATIS for Mother:\n\n%s, %s\n\n%s", windMessage, altimeterMessage, brcMessage or "BRC data unavailable")
        MESSAGE:New(messageText, 15, ""):ToUnit(client)
    else        
        local windMessage, windDirection = getAirbaseWind(atisZones[zoneName].airbaseName)
        if windMessage == "Wind data unavailable" or windMessage == "Airbase not found" then
            messageText = string.format("ATIS for %s:\n\n%s", zoneName, windMessage)
        else
            local runwayInfo = fetchActiveRunway(zoneName, windDirection)
            messageText = string.format("ATIS for %s:\n\n%s, %s\n\n%s.", zoneName, windMessage, getAltimeter(), runwayInfo or "Runway information not available")
        end
        MESSAGE:New(messageText, 20, ""):ToUnit(client)
    end
end

local MainMenu = {}

function getClosestFriendlyAirbaseInfo(client)
    if not client or not client:IsAlive() then
        BASE:E("Client is nil or not alive.")
        return
    end
    local playerCoord = client:GetCoordinate()
    if not playerCoord then
        MESSAGE:New("Unable to determine player position.", 15, ""):ToUnit(client)
        return
    end
    local clientType = client:GetTypeName()
    local considerCVN72 = (clientType == "FA-18C_hornet")
    local closestZoneName, closestDistance, closestBearing = nil, math.huge, nil
    local closestNormalZoneName, closestNormalDistance, closestNormalBearing = nil, math.huge, nil

    local cvnCoord, cvnDistance, cvnBearing
    if considerCVN72 then
        local cvn
			if IsGroupActive('CVN-73') then
				cvn = UNIT:FindByName("CVN-73")
			elseif IsGroupActive('CVN-72') then
				cvn = UNIT:FindByName("CVN-72")
			end
        if cvn then
            cvnCoord = cvn:GetCoordinate()
            cvnDistance = playerCoord:Get2DDistance(cvnCoord)
            local trueBearingToCVN = playerCoord:HeadingTo(cvnCoord, nil)
            local magneticDeclination = playerCoord:GetMagneticDeclination()
            cvnBearing = (trueBearingToCVN - magneticDeclination + 360) % 360

            if cvnDistance < closestDistance then
                closestZoneName = cvn:GetName()
                closestDistance = cvnDistance
                closestBearing = cvnBearing
            end
        end
    end
    for zoneName, details in pairs(atisZones) do
        local airbase = AIRBASE:FindByName(details.airbaseName)
        if airbase and airbase:GetCoalition() == coalition.side.BLUE then
            local distanceToAirbase = playerCoord:Get2DDistance(airbase:GetCoordinate())
            local trueBearingToAirbase = playerCoord:HeadingTo(airbase:GetCoordinate(), nil)
            local magneticDeclination = playerCoord:GetMagneticDeclination()
            local magneticBearingToAirbase = (trueBearingToAirbase - magneticDeclination + 360) % 360

            if distanceToAirbase < closestDistance then
                closestZoneName = zoneName
                closestDistance = distanceToAirbase
                closestBearing = magneticBearingToAirbase
            end
            if not string.find(zoneName, "Carrier") and distanceToAirbase < closestNormalDistance then
                closestNormalZoneName = zoneName
                closestNormalDistance = distanceToAirbase
                closestNormalBearing = magneticBearingToAirbase
            end
        end
    end
	if closestZoneName == "CVN-72" or closestZoneName == "CVN-73" then
		local brcMessage = getBRC()
		local tacanCode = closestZoneName == "CVN-72" and "72X" or "73X"
		local cvnMessageText = string.format("Carrier: %s\n\nDistance: %.2f NM, Bearing: %03d°\n\nTACAN: %s, %s",
											 closestZoneName, closestDistance * 0.000539957, closestBearing, tacanCode, brcMessage)
		MESSAGE:New(cvnMessageText, 25, ""):ToUnit(client)
	end
    if closestNormalZoneName then
        local distanceInNM = closestNormalDistance * 0.000539957
        local displayName = closestNormalZoneName .. (WaypointList[closestNormalZoneName] or "")
        local windMessage, windDirection = getAirbaseWind(atisZones[closestNormalZoneName] and atisZones[closestNormalZoneName].airbaseName or "")
        local altimeterMessage, runwayInfo = "", ""

        if windMessage ~= "Wind data unavailable" and windMessage ~= "Airbase not found" then
            altimeterMessage = getAltimeter()
            runwayInfo = fetchActiveRunway(closestNormalZoneName, windDirection) or "Runway information not available"
        end
        local normalMessageText = string.format("Closest Friendly Airfield: %s\n\nDistance: %.2f NM, Bearing: %03d°\n\n%s%s%s",
                                                displayName, distanceInNM, closestNormalBearing, windMessage,
                                                altimeterMessage ~= "" and (", " .. altimeterMessage) or "",
                                                runwayInfo ~= "" and ("\n\n" .. runwayInfo) or "")
        MESSAGE:New(normalMessageText, 25, ""):ToUnit(client)
    end
end

function SetupATISMenu(client)
    local group = client:GetGroup()
    if not group then return end

    local groupID = group:GetName()

    if MainMenu[groupID] then
        MainMenu[groupID]:Remove()
    end

    local mainMenu = MENU_GROUP:New(group, "ATIS and Closest Airbase")
    MainMenu[groupID] = mainMenu

    local atisMenu = MENU_GROUP:New(group, "ATIS Information", mainMenu)
    MENU_GROUP_COMMAND:New(group, "Get Closest Friendly Airbase", mainMenu, getClosestFriendlyAirbaseInfo, client)
    MENU_GROUP_COMMAND:New(group, "Get ATIS for Mother", atisMenu, sendATISInformation, client, group, "Carrier")

    local currentMenu = atisMenu
    local menuItemCount = 2

    for zoneName, details in pairs(atisZones) do
        if not zoneName:find("Carrier") then
            local airbase = AIRBASE:FindByName(details.airbaseName)
            if airbase and airbase:GetCoalitionName() == 'Blue' then
                if menuItemCount >= 9 then
                    currentMenu = MENU_GROUP:New(group, "Next Page...", atisMenu)
                    menuItemCount = 0
                end
                MENU_GROUP_COMMAND:New(group, "Get ATIS for " .. zoneName, currentMenu, sendATISInformation, client, group, zoneName)
                menuItemCount = menuItemCount + 1
            end
        end
    end
end

function static:onBaseCapture(_event)
local event = _event -- Core.Event#EVENTDATA
if event.id == EVENTS.BaseCaptured and event.Place then
	local capturedBaseName = event.Place:GetName()  
	local coalitionSide = event.Place:GetCoalition()

	if (atisZoneNames[capturedBaseName] or atisZones[capturedBaseName]) and event.Place:GetCoalition() == coalition.side.BLUE then  
		
			local clientSet = SET_CLIENT:New():FilterCategories("plane"):FilterCoalitions("blue"):FilterAlive():FilterOnce()
			clientSet:ForEachClient(function(client)
				SetupATISMenu(client)  
				
				local messageText = string.format("ATIS for %s is now available.", capturedBaseName)
				MESSAGE:New(messageText, 25, ""):ToClient(client)
			end)
		end
	end  
end
activeCSMenus = {}
function static:onPlayerSpawn(_event)
local event = _event
if event.id == EVENTS.PlayerEnterAircraft and event.IniUnit and event.IniPlayerName then
	local player = event.IniUnit
	local playerName = player:GetPlayerName()
	local UnitName = player:GetName()
	if player:GetUnitCategory() == Unit.Category.AIRPLANE then
		SetupATISMenu(player)
	end
	local group = player:GetGroup()
	local groupName = group:GetName()
	
	local foundZone = false
	
	for _, zoneName in ipairs(allZones) do
		local zone = ZONE:New(zoneName)
		if zone and zone:IsCoordinateInZone(player:GetCoordinate()) then
			  foundZone = true
			local playerUnitID = player:GetID()
			local playerGroupID = player:GetGroup():GetID()
			
			local isNewVisit = not playerZoneVisits[playerName] or not playerZoneVisits[playerName][zoneName]
			playerZoneVisits[playerName] = playerZoneVisits[playerName] or {}
			playerZoneVisits[playerName][zoneName] = true

			local assignedCallsign, assignedIFF = findOrAssignSlot(playerName, groupName, zoneName)

			local altimeterMessage = getAltimeter()
			local temperatureMessage = getPlayerTemperature(player:GetCoordinate())
			local greetingMessage, detailedMessage
            local windMessage,displayWindDirection=atisZones[zoneName] and getAirbaseWind(atisZones[zoneName].airbaseName) or getPlayerWind(player:GetCoordinate())
            local activeRunwayMessage=atisZones[zoneName] and fetchActiveRunway(zoneName,displayWindDirection) or "N/A"

                local brcMessage = getBRC()
				local carrierWindMessage = getCarrierWind()
				local carrierName, tacanCode = getCarrierInfo()
				if string.find(zoneName, "Carrier") then

                   if assignedCallsign and assignedIFF then
					greetingMessage = string.format("Welcome aboard %s, %s!\n\nYou have been assigned to %s, IFF %d.\n\nStandby for weather report from Mother.", carrierName, playerName, assignedCallsign, assignedIFF)
					detailedMessage = string.format("Welcome aboard %s, %s!\n\n%s, %s, %s\n\nTCN: %s, %s\n\nOnce 7 miles out, push Tactical on CH 3.", carrierName, assignedCallsign, carrierWindMessage, temperatureMessage, altimeterMessage, tacanCode, brcMessage)
				else
					greetingMessage = string.format("Welcome aboard %s, %s!\n\nStandby for weather and BRC.", carrierName, playerName)
					detailedMessage = string.format("Welcome aboard %s, %s!\n\n%s, %s, %s\n\nTCN: %s, %s\n\nOnce 7 miles out, push Tactical on CH 3.", carrierName, playerName, carrierWindMessage, temperatureMessage, altimeterMessage, tacanCode, brcMessage)
				end
			else
				local windMessage, displayWindDirection

				if atisZones[zoneName] then
					windMessage, displayWindDirection = getAirbaseWind(atisZones[zoneName].airbaseName)
					local activeRunwayMessage = fetchActiveRunway(zoneName, displayWindDirection)

					if isNewVisit then
						if assignedCallsign and assignedIFF then
							greetingMessage = string.format("Welcome to %s, %s!\n\nYou have been assigned to %s, IFF %d.\n\nStandby for weather and ATIS information.", zoneName, playerName, assignedCallsign, assignedIFF)
							detailedMessage = string.format("Welcome to %s, %s!\n\n%s, %s, %s.\n\n%s.\n\nOnce airborne push Tactical on CH 3.", zoneName, assignedCallsign, windMessage, temperatureMessage, altimeterMessage, activeRunwayMessage)
						else
							greetingMessage = string.format("Welcome to %s, %s!\n\nStandby for weather information.", zoneName, playerName)
							detailedMessage = string.format("Welcome to %s, %s!\n\n%s, %s, %s.\n\n%s.\n\nOnce airborne push Tactical on CH 3.", zoneName, playerName, windMessage, temperatureMessage, altimeterMessage, activeRunwayMessage)
						end

					else
						if assignedCallsign and assignedIFF then
							greetingMessage = string.format("Welcome back to %s, %s!\n\nYou have been assigned to %s, IFF %d.\n\nYou'll receive the latest weather and ATIS info shortly.", zoneName, playerName, assignedCallsign, assignedIFF)
							detailedMessage = string.format("Welcome back to %s, %s!\n\n%s, %s, %s.\n\n%s.\n\nOnce airborne push Tactical on CH 3.", zoneName, assignedCallsign, windMessage, temperatureMessage, altimeterMessage, activeRunwayMessage)
						else
							greetingMessage = string.format("Welcome back to %s, %s!\n\nStandby for updated weather information.", zoneName, playerName)
							detailedMessage = string.format("Welcome back to %s, %s!\n\n%s, %s, %s.\n\n%s.\n\nOnce airborne push Tactical on CH 3.", zoneName, playerName, windMessage, temperatureMessage, altimeterMessage, activeRunwayMessage)
						end
					end
				else

					local playerCoord = player:GetCoordinate()
					windMessage, _ = getPlayerWind(playerCoord)
					temperatureMessage = getPlayerTemperature(playerCoord)

					if isNewVisit then
						if assignedCallsign and assignedIFF then
							greetingMessage = string.format("Welcome to %s, %s!\n\nYou have been assigned to %s, IFF %d.\n\nStandby for weather information.", zoneName, playerName, assignedCallsign, assignedIFF)
							detailedMessage = string.format("Welcome to %s, %s!\n\n%s, %s, %s.\n\nOnce airborne push Tactical on CH 3.\n\nDon't forget supplies.", zoneName, assignedCallsign, windMessage, temperatureMessage, altimeterMessage)
						else
							greetingMessage = string.format("Welcome to %s, %s!\n\nStandby for weather information.", zoneName, playerName)
							detailedMessage = string.format("Welcome to %s, %s!\n\n%s, %s, %s.\n\nOnce airborne push Tactical on CH 3.\n\nDon't forget supplies.", zoneName, playerName, windMessage, temperatureMessage, altimeterMessage)
						end

					else
						if assignedCallsign and assignedIFF then
							greetingMessage = string.format("Welcome back to %s, %s!\n\nYou have been assigned to %s, IFF %d.\n\nYou'll receive updated weather information shortly.", zoneName, playerName, assignedCallsign, assignedIFF)
							detailedMessage = string.format("Welcome back to %s, %s!\n\n%s, %s, %s.\n\nOnce airborne push Tactical on CH 3.\n\nDon't forget supplies.", zoneName, assignedCallsign, windMessage, temperatureMessage, altimeterMessage)
						else
							greetingMessage = string.format("Welcome back to %s, %s!\n\nStandby for updated weather information.", zoneName, playerName)
							detailedMessage = string.format("Welcome back to %s, %s!\n\n%s, %s, %s.\n\nOnce airborne push Tactical on CH 3.\n\nDon't forget supplies.", zoneName, playerName, windMessage, temperatureMessage, altimeterMessage)
						end
					end
				end
			end
               sendGreetingToPlayer(UnitName, greetingMessage)
                if followID[playerName] then followID[playerName]:Stop()
                followID[playerName] = nil
                end
                followID[playerName] = SCHEDULER:New(nil, sendDetailedMessageToPlayer, {playerUnitID, detailedMessage, playerGroupID, UnitName}, 60)
                local subs = {}
                local function buildCallSignMenu()
                        local csMenu = MENU_GROUP:New(group, "Change Call Sign")
                        activeCSMenus[groupName] = csMenu
                        local prefix, preferredOrder = getPreferredOrder(groupName)
                        local function refreshSubmenus()
                            if preferredOrder and type(preferredOrder) == "table" then
                                for _, base in ipairs(preferredOrder) do
                                    if subs[base] then
                                        subs[base]:Remove()
                                    end
                                end
                            end
                            for _, base in ipairs(preferredOrder) do
                                subs[base] = MENU_GROUP:New(group, base, csMenu)
                                for i, iff in ipairs(aircraftAssignments[prefix][base].IFFs) do
                                    local fullCS = base..i
                                    if not zoneAssignments[zoneName][fullCS] then
                                        MENU_GROUP_COMMAND:New(group, fullCS, subs[base], function()
                                        local prev = globalCallsignAssignments[playerName]
                                        if prev and zoneAssignments[prev.zoneName] and zoneAssignments[prev.zoneName][prev.callsign] == playerName then
                                            zoneAssignments[prev.zoneName][prev.callsign] = nil
                                        end
                                        zoneAssignments[zoneName][fullCS] = playerName
                                        globalCallsignAssignments[playerName] = {callsign = fullCS, zoneName = zoneName,groupName=groupName}
                                        if followID[playerName] then followID[playerName]:Stop() followID[playerName]=nil end
                                        if string.find(zoneName,"Carrier") then
                                            sendGreetingToPlayer(UnitName, string.format("Welcome aboard %s, %s!\n\nYou have been assigned to %s, IFF %d.\n\nStandby for weather report from Mother.", carrierName, playerName, fullCS, iff))
                                            followID[playerName] = SCHEDULER:New(nil, sendDetailedMessageToPlayer, {playerUnitID, string.format("Welcome aboard %s, %s!\n\n%s, %s, %s\n\nTCN: %s, %s\n\nOnce 7 miles out, push Tactical on CH 3.", carrierName, fullCS, carrierWindMessage, temperatureMessage, altimeterMessage, tacanCode, brcMessage), playerGroupID, UnitName}, 60)
                                        else
                                            sendGreetingToPlayer(UnitName, string.format("Welcome to %s, %s!\n\nYou have been assigned to %s, IFF %d.\n\nStandby for weather and ATIS information.", zoneName, playerName, fullCS, iff))
                                            followID[playerName] = SCHEDULER:New(nil, sendDetailedMessageToPlayer, {playerUnitID, string.format("Welcome to %s, %s!\n\n%s, %s, %s.\n\n%s.\n\nOnce airborne push Tactical on CH 3.", zoneName, fullCS, windMessage, temperatureMessage, altimeterMessage, activeRunwayMessage), playerGroupID, UnitName}, 60)
                                        end
                                        refreshSubmenus()
                                    end)
                                end
                            end
                        end
                        SCHEDULER:New(nil, function()
                            if activeCSMenus and activeCSMenus[groupName] then
                                activeCSMenus[groupName]:Remove()
                                activeCSMenus[groupName] = nil
                            end
                        end, {}, 60)
                    end
                     refreshSubmenus()
                end
                if assignedCallsign and assignedIFF then
                buildCallSignMenu()
                end
            end
        end
		if not foundZone then
			local carrierUnit

			if IsGroupActive("CVN-72") then
				carrierUnit = UNIT:FindByName("CVN-72")
			elseif IsGroupActive("CVN-73") then
				carrierUnit = UNIT:FindByName("CVN-73")
			end

			if carrierUnit then
				local carrierPos = carrierUnit:GetCoordinate()
				local playerPos = player:GetCoordinate()
				local distanceToCarrier = playerPos:Get2DDistance(carrierPos)

				if distanceToCarrier < 200 then
					local assignedCallsign, assignedIFF = findOrAssignSlot(playerName, groupName, carrierUnit:GetName())
					local playerUnitID = player:GetID()
					local altimeterMessage = getAltimeter()
					local temperatureMessage = getPlayerTemperature(carrierPos)
					local brcMessage = getBRC()
					local carrierWindMessage = getCarrierWind()

					if assignedCallsign and assignedIFF then
						greetingMessage = string.format("Welcome aboard Abraham Lincoln, %s!\n\nYou have been assigned to %s, IFF %d.\n\nStandby for weather report from Mother.", playerName, assignedCallsign, assignedIFF)
						detailedMessage = string.format("Welcome aboard Abraham Lincoln, %s!\n\n%s, %s, %s\n\n%s\n\nOnce 7 miles out, push Tactical on CH 3.", assignedCallsign, carrierWindMessage, temperatureMessage, altimeterMessage, brcMessage)
					else
						greetingMessage = string.format("Welcome aboard Abraham Lincoln, %s!\n\nStandby for weather and BRC.", playerName)
						detailedMessage = string.format("Welcome aboard Abraham Lincoln, %s!\n\n%s, %s, %s\n\n%s\n\nOnce 7 miles out, push Tactical on CH 3.", playerName, carrierWindMessage, temperatureMessage, altimeterMessage, brcMessage)
					end

					sendGreetingToPlayer(UnitName, greetingMessage)
					timer.scheduleFunction(sendDetailedMessageToPlayer, {playerUnitID, detailedMessage, player:GetGroup():GetID(),UnitName}, timer.getTime() + 60)
				else
					return
				end
			else
				MESSAGE:New("Carrier CVN-72 is not available.", 15, ""):ToUnit(player)
			end
		end
    end
end
function WeaponImpact(Weapon)
    local impactPos = Weapon:GetImpactVec3()
    if impactPos then
        trigger.action.explosion(impactPos, 150)
        BASE:I("Explosion triggered at impact position.")
    end
	Weapon:StopTrack()
end
function WeaponTrack(Weapon)
    local target = Weapon:GetTarget()
    if target and target.GetUnitCategory and target:GetUnitCategory() == Unit.Category.HELICOPTER and target:GetCoalition() == coalition.side.RED then
        return
    end
end

function static:OnEventShot(EventData)
    local eventdata = EventData
    if eventdata and eventdata.weapon and eventdata.IniUnit and eventdata.IniPlayerName then
        local initiator = eventdata.IniUnit
        local playerName = eventdata.IniPlayerName

        if initiator and (initiator:GetUnitCategory() == Unit.Category.AIRPLANE or initiator:GetUnitCategory() == Unit.Category.HELICOPTER) then
            local weapon = WEAPON:New(eventdata.weapon)
            if weapon:IsMissile() then
                local target = eventdata.TgtUnit
                if target and target.GetUnitCategory and target:GetUnitCategory() == Unit.Category.HELICOPTER and target:GetCoalition() == coalition.side.RED then
                    weapon:SetFuncTrack(WeaponTrack)
                    weapon:SetFuncImpact(WeaponImpact)
                    weapon:StartTrack()
					BASE:I("Tracking RED coalition helicopter target.")
                end
            end
        end
    end
end

spawnedGroups = {}
local escortGroups = {}
local menuEscortRequest = {}
local escortRequestMenus = {}
local escortMenus = {}

function AddEscortRequestMenu(group)
    if not group then
        return
    end
    local groupName = group:GetName()
    escortRequestMenus[groupName] = MENU_GROUP_COMMAND:New(group, "Request Escort", nil, EscortClientGroup, group)
end
function EnableEscortRequestMenu(group)
    if not group then
        return
    end
    local groupName = group:GetName()
    if menuEscortRequest[groupName] then
        menuEscortRequest[groupName]:Remove()
    end
end
function RequestEscort(group)
    EscortClientGroup(group)
    local groupName = group:GetName()
    if menuEscortRequest[groupName] then
        menuEscortRequest[groupName]:Remove()
        menuEscortRequest[groupName] = nil
    end
end
function RemoveRequestEscortMenu(group)
    local groupName = group:GetName()
    if escortRequestMenus[groupName] then
        escortRequestMenus[groupName]:Remove()
        escortRequestMenus[groupName] = nil
    end
end
function FindEscortTemplateWithAlias(clientGroup, alias)
    local groupName = clientGroup:GetName()
    local aircraftType = clientGroup:GetUnit(1):GetTypeName()

    local templateName = "EscortA10"
    if string.find(aircraftType, "F-15") then
        templateName = "EscortF15"
    end

    local escortSpawn = SPAWN:NewWithAlias(templateName, alias)
    return escortSpawn
end

function EscortClientGroup(clientGroup)
    local groupName = clientGroup:GetName()
    local spawnCount = spawnedGroups[groupName] and spawnedGroups[groupName].escortSpawnCount or 1
    local alias = groupName .. "_Escort_" .. string.format("%03d", spawnCount)
    local escortSpawn = FindEscortTemplateWithAlias(clientGroup, alias)

    local clientPosition = clientGroup:GetPointVec3()
    local clientHeading = clientGroup:GetHeading()
    local distanceBehindMeters = 1500

    local offsetX = math.cos(math.rad(clientHeading)) * distanceBehindMeters
    local offsetZ = math.sin(math.rad(clientHeading)) * distanceBehindMeters

    local escortSpawnPosition = {
        x = clientPosition.x - offsetX,
        y = clientPosition.y + 3700,
        z = clientPosition.z - offsetZ
    }
    local escortCoord = COORDINATE:NewFromVec3(escortSpawnPosition, clientHeading)

        escortSpawn:InitSkill("Excellent"):InitHeading(clientHeading):OnSpawnGroup(function(spawnedEscortGroup)
        local escortGroup = FLIGHTGROUP:New(spawnedEscortGroup)
		escortGroup:SetSpeed(600)
        escortGroup:GetGroup():CommandSetUnlimitedFuel(true):SetOptionRadarUsingForContinousSearch(true)
        escortGroup:SwitchROE(1)
        escortGroups[groupName] = escortGroup
        local escortAuftrag = AUFTRAG:NewESCORT(clientGroup, {x = -100, y = 3048, z = 100}, 40, {"Air"})
        escortGroup:AddMission(escortAuftrag)
        escortGroup:MissionStart(escortAuftrag)

        MESSAGE:New("ESCORT IS ON ROUTE.\n\nYou can control the escort from the radio menu.", 20):ToGroup(clientGroup)
        RemoveRequestEscortMenu(clientGroup)
        AddEscortMenu(clientGroup)

        function escortGroup:OnAfterDead(From, Event, To)
            escortGroups[groupName] = nil
            RemoveEscortMenu(clientGroup)

            if clientGroup and clientGroup:IsAlive() then
                MESSAGE:New("Your escort group has been destroyed. Takeoff from an airfield to get a new one.", 10):ToGroup(clientGroup)
            end
        end
    end)
    escortSpawn:SpawnFromCoordinate(escortCoord)
    spawnedGroups[groupName].escortSpawnCount = spawnCount + 1
end
function AddEscortMenu(group)
    if not group then
        return
    end
    local groupName = group:GetName()

    escortMenus[groupName] = MENU_GROUP:New(group, "Escort")
    
    MENU_GROUP_COMMAND:New(group, "Patrol Ahead 15 NM", escortMenus[groupName], PatrolAhead, group)
    MENU_GROUP_COMMAND:New(group, "Racetrack, On my nose 20 NM", escortMenus[groupName], RaceTrackOnNose, group)
    MENU_GROUP_COMMAND:New(group, "Racetrack, Left to right 20 NM", escortMenus[groupName], RaceTrackLeftToRight, group)
    MENU_GROUP_COMMAND:New(group, "Racetrack, Right to left 20 NM", escortMenus[groupName], RaceTrackRightToLeft, group)
    MENU_GROUP_COMMAND:New(group, "Start Orbit", escortMenus[groupName], EscortOrbit, group)
    MENU_GROUP_COMMAND:New(group, "Rejoin", escortMenus[groupName], EscortRejoin, group)
    MENU_GROUP_COMMAND:New(group, "Escort RTB", escortMenus[groupName], EscortAbort, group)


end
function RemoveEscortMenu(group)
    local groupName = group:GetName()
    if escortMenus[groupName] then
        escortMenus[groupName]:Remove()
        escortMenus[groupName] = nil
    else
        env.info("No escort menu found for " .. groupName .. ".")
    end
end
function EscortOrbit(group)
    local escortGroup = escortGroups[group:GetName()]
    if escortGroup then
        local clientCoord = group:GetPointVec2()
        local escortHeading = group:GetHeading()
        local orbitAuftrag = AUFTRAG:NewORBIT(clientCoord, 25000, 350, escortHeading, 1)
        escortGroup:AddMission(orbitAuftrag)
        local currentMission = escortGroup:GetMissionCurrent()
        if currentMission then
		currentMission:__Cancel(5)
        end        

        MESSAGE:New("Escort is setting up an orbit.", 20):ToGroup(group)
    else
        MESSAGE:New("No active escort found.", 10):ToGroup(group)
    end
end
function PatrolAhead(group)
    if not group or not group:IsAlive() then
        MESSAGE:New("Unable to set up patrol: escort group is invalid or not alive.", 20):ToAll()
        return
    end
    local escortGroup = escortGroups[group:GetName()]
    if escortGroup then
        local clientHeading = group:GetHeading()
        local PatrolAheadAuftrag = AUFTRAG:NewCAPGROUP(group, 25000, 550, clientHeading, 15, 15, 0, 3, {"Air"}, 40)
        escortGroup:AddMission(PatrolAheadAuftrag)
		PatrolAheadAuftrag:SetMissionSpeed(550)		
        local currentMission = escortGroup:GetMissionCurrent()
        if currentMission then
		currentMission:__Cancel(5)
        end        
        MESSAGE:New("Escort is setting up a patrol ahead at 10 NM\n\nAI might take their time", 20):ToGroup(group)
    else
        MESSAGE:New("No active escort found.", 20):ToGroup(group)
    end
end
function RaceTrackOnNose(group)
    local escortGroup = escortGroups[group:GetName()]
    if escortGroup then
        local clientCoord = group:GetPointVec3()
        local clientHeading = group:GetHeading()
		
        local RaceTrackOnNoseAuftrag = AUFTRAG:NewPATROL_RACETRACK(clientCoord, 25000, 370, clientHeading, 20)
        RaceTrackOnNoseAuftrag:SetMissionSpeed(500)
        RaceTrackOnNoseAuftrag:SetROT(2)
		RaceTrackOnNoseAuftrag:SetROE(3)
        escortGroup:AddMission(RaceTrackOnNoseAuftrag)
        local currentMission = escortGroup:GetMissionCurrent()
        if currentMission then
		currentMission:__Cancel(5)
        end
        
       MESSAGE:New("Escort is setting up a 20 NM racetrack at heading " .. clientHeading, 20):ToGroup(group)
    else
        MESSAGE:New("No active escort found.", 10):ToGroup(group)
    end
end
function RaceTrackLeftToRight(group)
    local escortGroup = escortGroups[group:GetName()]
    if escortGroup then
        local clientCoord = group:GetPointVec3()
        local clientHeading = group:GetHeading()
        local headingLeftToRight = (clientHeading - 90) % 360
		
        local RaceTrackLeftToRightAuftrag = AUFTRAG:NewPATROL_RACETRACK(clientCoord, 25000, 370, headingLeftToRight, 20)
        escortGroup:AddMission(RaceTrackLeftToRightAuftrag)
        RaceTrackLeftToRightAuftrag:SetMissionSpeed(500)
        RaceTrackLeftToRightAuftrag:SetROT(2)
		RaceTrackLeftToRightAuftrag:SetROE(3)
        local currentMission = escortGroup:GetMissionCurrent()
        if currentMission then
		currentMission:__Cancel(3)
        end
        MESSAGE:New("Escort is setting up a 20 NM racetrack at heading " .. headingLeftToRight, 20):ToGroup(group)
    else
        MESSAGE:New("No active escort found.", 20):ToGroup(group)
    end
end
function RaceTrackRightToLeft(group)
    local escortGroup = escortGroups[group:GetName()]
    if escortGroup then
        local clientCoord = group:GetPointVec3()
        local clientHeading = group:GetHeading()
        local headingRightToLeft = (clientHeading + 90) % 360
        local RaceTrackRightToLeftAuftrag = AUFTRAG:NewPATROL_RACETRACK(clientCoord, 25000, 370, headingRightToLeft, 20)
        escortGroup:AddMission(RaceTrackRightToLeftAuftrag)
        RaceTrackRightToLeftAuftrag:SetMissionSpeed(600)
        RaceTrackRightToLeftAuftrag:SetROT(2)
		RaceTrackRightToLeftAuftrag:SetROE(3)
        local currentMission = escortGroup:GetMissionCurrent()
        if currentMission then
		currentMission:__Cancel(5)
        end
        MESSAGE:New("Escort is setting up a 20 NM racetrack at heading " .. headingRightToLeft, 20):ToGroup(group)
    else
        MESSAGE:New("No active escort found.", 20):ToGroup(group)
    end
end
function EscortRejoin(group)
    local escortGroup = escortGroups[group:GetName()]
    if escortGroup then
    
		local clientCoord = group:GetPointVec3()
        local escortAuftrag = AUFTRAG:NewESCORT(group, {x=-100, y=3048, z=300}, 40, {"Air"})
        escortGroup:AddMission(escortAuftrag)
        escortAuftrag:SetMissionSpeed(600)
        escortAuftrag:SetROE(1)
        escortAuftrag:SetROT(3)
        local currentMission = escortGroup:GetMissionCurrent()
        if currentMission then
		currentMission:__Cancel(5)
        end
        MESSAGE:New("Escort is rejoining your formation.", 20):ToGroup(group)
    else
        MESSAGE:New("No active escort found.", 10):ToGroup(group)
    end
end
function EscortAbort(group)
    local escortGroup = escortGroups[group:GetName()]
    if escortGroup then
                
        escortGroup:CancelAllMissions()
        MESSAGE:New("Escort is RTB", 20):ToGroup(group)
    else
        MESSAGE:New("No active escort found.", 10):ToGroup(group)
    end
end
function static:OnEventTakeoff(EventData)
    if not EventData.IniUnit or not EventData.IniPlayerName then
        return
    end

    local playerUnit = EventData.IniUnit
    local playerGroup = playerUnit:GetGroup()
    local PGName = playerGroup:GetName()
    local playerType = playerUnit:GetTypeName()

    if playerType == "F-15ESE" or playerType == "A-10C_2" or playerType == "Hercules" then
        spawnedGroups[PGName] = spawnedGroups[PGName] or {
            playerName = EventData.IniPlayerName,
            escortGroups = {},
            menuEscortRequest = nil,
            escortSpawnCount = 1
        }

        MESSAGE:New("Escort is available, " .. EventData.IniPlayerName .. ".", 10, ""):ToUnit(playerUnit)
        AddEscortRequestMenu(playerGroup)
        menuEscortRequest[PGName] = spawnedGroups[PGName].menuEscortRequest

    end
end
function static:OnEventPilotDead(EventData)
    if EventData.IniUnit and EventData.IniPlayerName then
        local playerUnit = EventData.IniUnit
        local playerGroup = playerUnit:GetGroup()

        if playerGroup then
            local groupName = playerGroup:GetName()
            local escortGroup = escortGroups[groupName]

            if escortGroup then
                escortGroup:Destroy()
                escortGroups[groupName] = nil
            end
        end
    end
end
function static:OnEventLand(EventData)
    if EventData.id == EVENTS.Land and EventData.IniUnit then
        local landedUnit = EventData.IniUnit
        local group = landedUnit:GetGroup()
        if group then
            local groupName = group:GetName()

            if string.sub(groupName, 1, 6) == "f16cap" or string.sub(groupName, 1, 4) == "sead" or string.sub(groupName, 1, 3) == "cas" then
                local filteredGroup = SET_GROUP:New():FilterPrefixes("f16cap", "sead", "cas"):FilterAlive():FilterOnce()
                SCHEDULER:New(nil, function()
                    filteredGroup:ForEachGroupAlive(function(GROUP)
                        local units = GROUP:GetUnits()
                        if units then
                            for _, unit in ipairs(units) do
                                local speedInKMH = unit:GetVelocityKMH()
                                if speedInKMH < 120 then
                                    unit:Destroy()
                                end
                            end
                        else
                            env.info("No valid units found in the group: " .. GROUP:GetName())
                        end
                    end)
                end, {}, 5)
            end

            if EventData.IniPlayerName then
                local escortGroup = escortGroups[groupName]
                if escortGroup then
                    escortGroup:Destroy()
                    escortGroups[groupName] = nil
                    RemoveEscortMenu(group)
                end
            end
        else
            env.info("OnEventLand: Group is nil for landed unit.")
        end
    end
end
function static:OnEventPlayerLeaveUnit(EventData)
    BASE:I("OnEventPlayerLeaveUnit called")

    if EventData.id == EVENTS.PlayerLeaveUnit or EventData.id == EVENTS.PilotDead then
        if EventData.IniUnit and EventData.IniPlayerName then
            local playerUnit = EventData.IniUnit
            playerGroup = playerUnit:GetGroup()
            if playerGroup then
                local groupName = playerGroup:GetName()
                local escortGroup = escortGroups[groupName]
                if escortGroup then
                    escortGroup:Destroy()
                    escortGroups[groupName] = nil
                    BASE:I("Escort group for " .. groupName .. " has been destroyed because the player left the unit.")
                end
            end

            local playerName = EventData.IniPlayerName
            if followID and playerName and followID[playerName] then
                followID[playerName]:Stop()
                followID[playerName] = nil
            end
            if activeCSMenus and playerGroup then
                local groupName = playerGroup:GetName()
                if activeCSMenus[groupName] then
                    activeCSMenus[groupName]:Remove()
                    activeCSMenus[groupName] = nil
                end
            end
            BASE:I("Player leaving unit: " .. playerName)

            if globalCallsignAssignments[playerName] then
                local callsignInfo = globalCallsignAssignments[playerName]
                local zoneName = callsignInfo.zoneName
                BASE:I("Player had assignment: " .. callsignInfo.callsign .. " in zone " .. zoneName)

                releaseSlot(playerName, zoneName)
                globalCallsignAssignments[playerName] = nil
            else
                BASE:I("No global assignment found for player: " .. playerName)
            end
        else
            BASE:I("IniPlayerName is nil. Player might have disconnected without a proper event.")

            local clientSet = SET_CLIENT:New():FilterCategories("plane"):FilterCategories("helicopter"):FilterCoalitions("blue"):FilterAlive():FilterOnce()

            for playerName, callsignInfo in pairs(globalCallsignAssignments) do
                local isPlayerAlive = false

                clientSet:ForEachClient(function(client)
                    if client:GetPlayerName() == playerName then
                        isPlayerAlive = true
                    end
                end)

                if not isPlayerAlive then
                    local zoneName=callsignInfo.zoneName
                    local gname=callsignInfo.groupName
                    releaseSlot(playerName,zoneName)
                    if followID and followID[playerName] then followID[playerName]:Stop() followID[playerName]=nil end
                    if activeCSMenus and gname and activeCSMenus[gname] then activeCSMenus[gname]:Remove() activeCSMenus[gname]=nil end
                    globalCallsignAssignments[playerName]=nil
                end
            end
        end
    else
        BASE:I("Event ID does not match PlayerLeaveUnit or PilotDead")
    end
    if activeCSMenus and playerGroup then
    activeCSMenus[playerGroup:GetName()] = nil
    end
end


AIGroups = {
  sead = {},
  f16cap = {},
  cas = {},
  decoy = {}
}

destroyMenuHandles = {
  sead = nil,
  f16cap = nil,
  cas = nil,
  decoy = nil
}

function anyGroupAlive(tName)
  if not AIGroups[tName] then return false end
  for gName,_ in pairs(AIGroups[tName]) do
    local g = Group.getByName(gName)
    if g and g:isExist() then return true end
  end
  return false
end

function destroySeadGroups()
  for gName,_ in pairs(AIGroups.sead) do
    local g = Group.getByName(gName)
    if g and g:isExist() then g:destroy() end
  end
  if destroyMenuHandles.sead then
    MESSAGE:New("SEAD GROUP DESTROYED OR KILLED IN ACTION", 15):ToAll()
    trigger.action.setUserFlag("sead", false)
    missionCommands.removeItemForCoalition(coalition.side.BLUE, destroyMenuHandles.sead)
    destroyMenuHandles.sead = nil
  end
end

function destroydecoyGroups()
  for gName,_ in pairs(AIGroups.decoy) do
    local g = Group.getByName(gName)
    if g and g:isExist() then g:destroy() end
  end
  if destroyMenuHandles.decoy then
    MESSAGE:New("DECOY GROUP DESTROYED OR KILLED IN ACTION", 15):ToAll()
    trigger.action.setUserFlag("decoy", false)
    missionCommands.removeItemForCoalition(coalition.side.BLUE, destroyMenuHandles.decoy)
    destroyMenuHandles.decoy = nil
  end
end

function destroyF16capGroups()
  for gName,_ in pairs(AIGroups.f16cap) do
    local g = Group.getByName(gName)
    if g and g:isExist() then g:destroy() end
  end
  if destroyMenuHandles.f16cap then
    MESSAGE:New("CAP GROUP DESTROYED OR KILLED IN ACTION", 15):ToAll()
    trigger.action.setUserFlag("cap", false)
    missionCommands.removeItemForCoalition(coalition.side.BLUE, destroyMenuHandles.f16cap)
    destroyMenuHandles.f16cap = nil
  end
end

function destroyCasGroups()
  for gName,_ in pairs(AIGroups.cas) do
    local g = Group.getByName(gName)
    if g and g:isExist() then g:destroy() end
  end
  if destroyMenuHandles.cas then
    MESSAGE:New("CAS GROUP DESTROYED OR KILLED IN ACTION", 15):ToAll()
    trigger.action.setUserFlag("cas", false)
    missionCommands.removeItemForCoalition(coalition.side.BLUE, destroyMenuHandles.cas)
    destroyMenuHandles.cas = nil
  end
end

function ensureSeadMenu()
  if not destroyMenuHandles.sead and anyGroupAlive("sead") and trigger.misc.getUserFlag("sead") == 0 then
    trigger.action.setUserFlag("sead", true)
    SCHEDULER:New(nil, function()
      destroyMenuHandles.sead = missionCommands.addCommandForCoalition(coalition.side.BLUE, "Destroy SEAD Group", nil, destroySeadGroups)
    end, {}, 30)
  end
end

function ensureDecoyMenu()
  if not destroyMenuHandles.decoy and anyGroupAlive("decoy") and trigger.misc.getUserFlag("decoy") == 0 then
    trigger.action.setUserFlag("decoy", true)
    SCHEDULER:New(nil, function()
      destroyMenuHandles.decoy = missionCommands.addCommandForCoalition(coalition.side.BLUE, "Destroy Decoy Group", nil, destroydecoyGroups)
    end, {}, 30)
  end
end

function ensureF16capMenu()
  if not destroyMenuHandles.f16cap and anyGroupAlive("f16cap") and trigger.misc.getUserFlag("cap") == 0 then
    trigger.action.setUserFlag("cap", true)
    SCHEDULER:New(nil, function()
      destroyMenuHandles.f16cap = missionCommands.addCommandForCoalition(coalition.side.BLUE, "Destroy CAP Group", nil, destroyF16capGroups)
    end, {}, 30)
  end
end

function ensureCasMenu()
  if not destroyMenuHandles.cas and anyGroupAlive("cas") and trigger.misc.getUserFlag("cas") == 0 then
    trigger.action.setUserFlag("cas", true)
    SCHEDULER:New(nil, function()
      destroyMenuHandles.cas = missionCommands.addCommandForCoalition(coalition.side.BLUE, "Destroy CAS Group", nil, destroyCasGroups)
    end, {}, 30)
  end
end

function static:OnEventEngineStartup(EventData)
  if not EventData or not EventData.IniGroup then return end
  local gName = EventData.IniGroup:GetName()
  if string.find(gName, "sead") then
    AIGroups.sead[gName] = true
    ensureSeadMenu()
  elseif string.find(gName, "f16cap") then
    AIGroups.f16cap[gName] = true
    ensureF16capMenu()
  elseif string.find(gName, "cas") then
    AIGroups.cas[gName] = true
    ensureCasMenu()
  elseif string.find(gName, "decoy") then
    AIGroups.decoy[gName] = true
    ensureDecoyMenu()
  end
end


static:HandleEvent(EVENTS.Shot, static.OnEventShot)
static:HandleEvent(EVENTS.Land, static.OnEventLand)
static:HandleEvent(EVENTS.PlayerEnterAircraft, static.onPlayerSpawn)
static:HandleEvent(EVENTS.BaseCaptured, static.onBaseCapture)
static:HandleEvent(EVENTS.PlayerLeaveUnit, static.OnEventPlayerLeaveUnit)
static:HandleEvent(EVENTS.Takeoff, static.OnEventTakeoff)
static:HandleEvent(EVENTS.PilotDead, static.OnEventPilotDead)
static:HandleEvent(EVENTS.EngineStartup, static.OnEventEngineStartup)

_SETTINGS:SetPlayerMenuOff()
_SETTINGS:SetA2G_BR()
_SETTINGS:SetA2A_BULLS()
_SETTINGS:SetImperial()

BASE:I("Loading completed for Leka's special all in one script handler")
