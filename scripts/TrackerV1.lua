missile_tracker_options = {
    ---------------------------------------------------------------------- Debug -----------------------------------------------------------------------------
    ["game_messages"] = false, --enable some messages on screen
    ["debug"] = false,  --enable debugging messages 
    ["weapon_missing_message"] = false, --false disables messages alerting you to missiles missing from the missilesTable
	
    ---------------------------------------------------------------------- Radio -----------------------------------------------------------------------------
   -- ["enable_radio_menu"] = true, --enables the in-game radio menu for modifying settings
    
	
}

local s_enable = 1
Rate = 0.1
Message_Frequency = 300 --seconds
----[[ ##### End of SCRIPT CONFIGURATION ##### ]]----

--Helper function: Trim whitespace.
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

missilesTable = {
   
	 ["V1M"] = { explosive = 200, shaped_charge = false },
	
}


----[[ ##### HELPER/UTILITY FUNCTIONS ##### ]]----

--Global table to track processed unit IDs
local processedUnitIds = {}

--Function to clear processed unit IDs after a delay
function clearProcessedUnitIds(unitId)
    if processedUnitIds[unitId] then
        processedUnitIds[unitId] = nil
    end
end

local function debugMsg(str)
    if missile_tracker_options.debug == true then
        debugCounter = (debugCounter or 0) + 1
        local uniqueStr = str .. " [" .. timer.getTime() .. " - " .. debugCounter .. "]"
        trigger.action.outText(uniqueStr, 5)
        env.info("DEBUG: " .. uniqueStr)
    end
end
  
local function gameMsg(str)
    if missile_tracker_options.game_messages == true then
        trigger.action.outText(str, 5)
    end
end
  
local function getDistance(obj1PosX, obj1PosZ, obj2PosX, obj2PosZ)
	local xDiff = obj1PosX - obj2PosX
	local yDiff = obj1PosZ - obj2PosZ
	return math.sqrt(xDiff * xDiff + yDiff * yDiff) -- meters
end

local function getBearing(obj1PosX, obj1PosZ, obj2PosX, obj2PosZ)
    local bearing = math.atan2(obj2PosZ - obj1PosZ, obj2PosX - obj1PosX)
    if bearing < 0 then
        bearing = bearing + 2 * math.pi
    end
    bearing = bearing * 180 / math.pi
    return bearing    -- degrees
end
  


MslHandler = {}
tracked_missiles = {}

function track_msls()
--  env.info("Weapon Track Start")
    local bullseye = coalition.getMainRefPoint(2)
	local referenceX = bullseye.x
	local referenceZ = bullseye.z
    local missilTable = {}
    for msl_id_, mslData in pairs(tracked_missiles) do
        if mslData.wpn:isExist() then  -- just update speed, position and direction.
        mslData.pos = mslData.wpn:getPosition().p
        mslData.dir = mslData.wpn:getPosition().x
        mslData.speed = mslData.wpn:getVelocity()
        weaponName = mslData.wpn:getTypeName()
        initiator = mslData.init
       --weaponName = mslData.name
        --mslData.lastIP = land.getIP(mslData.pos, mslData.dir, 50)
        debugMsg("Tick Track for " .. weaponName .. " at X: " .. string.format("%.0f", mslData.pos.x) .. ", Y: " .. string.format("%.0f", mslData.pos.y) .. ", Z: " .. string.format("%.0f", mslData.pos.z) .. " - V1")
        local bearing = getBearing(referenceX,referenceZ,mslData.pos.x,mslData.pos.z)
		bearingType = nil
		
        if (bearing > 11.25 and bearing <= 33.75) then
            bearingType = " NNE "
        elseif (bearing > 33.75 and bearing <= 56.25) then
            bearingType = " NE "
        elseif (bearing > 56.25 and bearing <= 78.75) then
            bearingType = " ENE "
        elseif (bearing > 78.75 and bearing <= 101.25) then
            bearingType = " E "
        elseif (bearing > 101.25 and bearing <= 123.75) then
            bearingType = " ESE "
        elseif (bearing > 123.75 and bearing <= 146.25) then
            bearingType = " SE "
        elseif (bearing > 146.25 and bearing <= 168.75) then
            bearingType = " SSE "
        elseif (bearing > 168.75 and bearing <= 191.25) then
            bearingType = " S "
        elseif (bearing > 191.25 and bearing <= 213.75) then
            bearingType = " SSW "
        elseif (bearing > 213.75 and bearing <= 236.25) then
            bearingType = " SW "
        elseif (bearing > 236.25 and bearing <= 258.75) then
            bearingType = " WSW "
        elseif (bearing > 258.75 and bearing <= 281.25) then
            bearingType = " W "
        elseif (bearing > 281.25 and bearing <= 303.75) then
            bearingType = " WNW "
        elseif (bearing > 303.75 and bearing <= 326.25) then
            bearingType = " NW "
        elseif (bearing > 326.25 and bearing <= 348.75) then
            bearingType = " NNW "
        else
            -- North sector covers from 348.75 to 360, and 0 to 11.25
            bearingType = " N "
        end

        local rangeM = getDistance(referenceX,referenceZ,mslData.pos.x,mslData.pos.z)
        --range = mist.utils.metersToNM(rangeM)
        range = metersToNM(rangeM)
        
        debugMsg("Tick Track for " .. weaponName .. " Bearing: " .. bearingType .. ", Range: " .. range .. " - initiator: " .. initiator)

        local j = #missilTable + 1
		missilTable[j] = {}
		missilTable[j].name = weaponName
		missilTable[j].bearing = bearingType
		missilTable[j].range = range
        missilTable[j].init = initiator
        --displayMessageToAll(mslData.name, bearingType, range)
        --else -- wpn no longer exists, must be dead.
        --tracked_missiles[msl_id_] = nil -- remove from tracked missiles first.         
        end
        --return weaponName, bearingType, range
        
    end
    return missilTable
--  env.info("Weapon Track End")
end

function metersToNM(meters)
	return meters/1852
end

function outText(missilTable)
	local status, result = pcall(function()
		
		local message = {}
		--local altUnits
		--local speedUnits
		local rangeUnits = "NM"
		
		
		
		if #missilTable >= 1 then
			local maxThreats = 8
			local messageGreeting = "EWRS Alert V1 Launched: "
			
			
			--Display table
			table.insert(message, "\n")
			table.insert(message, messageGreeting)
			table.insert(message, "\n\n")
			table.insert(message, string.format( "%-16s", "TYPE"))
			table.insert(message, string.format( "%-12s", "BRG"))
			table.insert(message, string.format( "%-12s", "RNG"))
            table.insert(message, string.format( "%-12s", "V1 SITE"))
			--table.insert(message, string.format( "%-21s", "ALT"))
			--table.insert(message, string.format( "%-15s", "SPD"))
			--table.insert(message, string.format( "%-3s", "HDG"))
			table.insert(message, "\n")
				
			for k = 1, maxThreats do
				if missilTable[k] == nil then break end
				table.insert(message, "\n")
				table.insert(message, string.format( "%-16s", missilTable[k].name))
				if missilTable[k].range == nil then
					table.insert(message, string.format( "%-4s", " "))
					table.insert(message, string.format( "%-12s", "POSITION"))
                    table.insert(message, string.format( "%-4s", " "))
					--table.insert(message, string.format( "%-21s", " "))
					--table.insert(message, string.format( "%-15s", "UNKNOWN"))
					--table.insert(message, string.format( "%-3s", " "))
				else
					table.insert(message, string.format( "%-6s", missilTable[k].bearing))
					table.insert(message, string.format( "%12d %-5s", missilTable[k].range, rangeUnits))
                    table.insert(message, string.format( "%-12s", missilTable[k].init))
					--table.insert(message, string.format( "%9d %s", missilTable[k].altitude, altUnits))
					--table.insert(message, string.format( "%9d %s", missilTable[k].speed, speedUnits))
					--table.insert(message, string.format( "         %-16s", missilTable[k].heading))
				end
				table.insert(message, "\n")
			end
			--trigger.action.outTextForGroup(activePlayer.groupID, table.concat(message), 25)
            trigger.action.outTextForCoalition(2 , table.concat(message), 10)
		end
	end)
	if not status then
		env.error(string.format("EWRS outText Error: %s", result))
	end
end

function displayMessageToAll()
local status, result = pcall(function()
timer.scheduleFunction(displayMessageToAll, nil, timer.getTime() + Message_Frequency)

outText(track_msls())
end)
if not status then
env.error(string.format("EWRS displayMessageToAll Error: %s", result))
end
end







--[[
function displayMessageToAll()
    local missilName, bearingType, range = track_msls()
    trigger.action.outText("Alert" .. missilName .. " - " .. bearingType .. " - " .. range , 10, false)
      
end
--]]
function onMslEvent(event)
    if event.id == world.event.S_EVENT_SHOT then
        if event.weapon then
            local ordnance = event.weapon
            --verify isExist and getDesc
            local isValid = false
            local status, desc = pcall(function() return ordnance:isExist() and ordnance:getDesc() end)
            if status and desc then
                isValid = true
            end
            if not isValid then
                if missile_tracker_options.debug then
                    env.info("Missile Tracker: Invalid weapon object in S_EVENT_SHOT")
                    debugMsg("Invalid weapon object in S_EVENT_SHOT")
                end
                return
            end
            --Safely get typeName with pcall
            local status, typeName = pcall(function() return trim(ordnance:getTypeName()) end)
            if not status or not typeName then
                if missile_tracker_options.debug then
                    env.info("Missile Tracker: Failed to get weapon typeName: " .. tostring(typeName))
                    debugMsg("Failed to get weapon typeName: " .. tostring(typeName))
                end
                return
            end
 
            if missile_tracker_options.debug then
                env.info("Weapon fired: [" .. typeName .. "]")
                debugMsg("Weapon fired: [" .. typeName .. "]")
            end
		
            --Debug the exact typeName and missilesTable lookup
            if missile_tracker_options.debug then
                debugMsg("Checking missilesTable for typeName: [" .. typeName .. "]")
            end
            local weaponData = missilesTable[typeName]
            if missile_tracker_options.debug then
            if weaponData then
                    debugMsg("Found in missilesTable: explosive=" .. weaponData.explosive .. ", shaped_charge=" .. tostring(weaponData.shaped_charge))
                else
                    debugMsg("Not found in missilesTable: [" .. typeName .. "]")
                end
            end
             
            --Handle other tracked missiles in missilesTable
            if weaponData then
                if (ordnance:getDesc().category ~= 0) and event.initiator then
                    if ordnance:getDesc().category == 1 then --Missiles
                        if (ordnance:getDesc().MissileCategory ~= 1 and ordnance:getDesc().MissileCategory ~= 2) then --Exclude AAM and SAM
                            tracked_missiles[event.weapon.id_] = { 
                                wpn = ordnance, 
                                init = event.initiator:getName(), 
                                pos = ordnance:getPoint(), 
                                dir = ordnance:getPosition().x, 
                                name = typeName, 
                                speed = ordnance:getVelocity(), 
                                cat = ordnance:getCategory() 
                            }
                        end
                    else --Rockets, bombs, etc.
                        tracked_missiles[event.weapon.id_] = { 
                            wpn = ordnance, 
                            init = event.initiator:getName(), 
                            pos = ordnance:getPoint(), 
                            dir = ordnance:getPosition().x, 
                            name = typeName, 
                            speed = ordnance:getVelocity(), 
                            cat = ordnance:getCategory() 
                        }
                    end
                end
                return --Exit after handling known missiles
            end

            --Log missing missiles
            --env.info("Missile Tracker: " .. typeName .. " missing from script (" .. (event.initiator and event.initiator:getTypeName() or "no initiator") .. ")")
            if missile_tracker_options.weapon_missing_message then
                        trigger.action.outText("Missile Tracker: " .. typeName .. " missing from script (" .. (event.initiator and event.initiator:isExist() and event.initiator:getTypeName() or "no initiator") .. ")", 3)
                        env.info("Current keys in missilesTable:")
                        for k, v in pairs(missilesTable) do
                            env.info("Key: [" .. k .. "]")
                        end
  
            end
        end
    end
end

function onV1KillEvent(event)
  if event.id == world.event.S_EVENT_KILL and event.target and event.target:getTypeName() == "V1" then
    local killer = event.initiator
    if killer and killer.getPlayerName then
      local pname = killer:getPlayerName()
      if pname then
        -- Reward logic (adjust reward amount as needed)
        bc:addFunds(killer:getCoalition(), 100)
        bc:addStat(pname, "V1 Kills", 1)
        trigger.action.outTextForCoalition(killer:getCoalition(), "["..pname.."] destroyed a V1! +100 credits", 10)
      end
    end
  end
end



  
local function protectedCall(...)
    local status, retval = pcall(...)
    if not status then
        env.warning("Missile tracker script error... gracefully caught! " .. retval, true)
    end
end
  
function MslHandler:onEvent(event)
    protectedCall(onMslEvent, event)
end


if (s_enable == 1) then
    gameMsg("Track V1 SCRIPT RUNNING")
    env.info("Track V1 SCRIPT RUNNING")

    timer.scheduleFunction(function()
        protectedCall(track_msls)
        return timer.getTime() + Rate
    end, {}, timer.getTime() + Rate)
    timer.scheduleFunction(displayMessageToAll, nil, timer.getTime() + Message_Frequency)
    world.addEventHandler(MslHandler)
    world.addEventHandler({onEvent = onV1KillEvent})
end
