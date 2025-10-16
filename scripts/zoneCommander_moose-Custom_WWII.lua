
if Era == 'Gulfwar' then Era = 'Coldwar' end
PATH_CACHE=PATH_CACHE or{}
Respawn = {}

local function DeepCopy(o, s)
  if type(o)~="table" then return o end
  if s and s[o] then return s[o] end
  local t, s = {}, s or {} ; s[o] = t
  for k,v in pairs(o) do t[DeepCopy(k,s)] = DeepCopy(v,s) end
  return setmetatable(t,getmetatable(o))
end

local gid, uid = 7000, 90000
local function freshIds(t)
  t.groupId = gid ;  gid = gid + 1
  for _,u in ipairs(t.units) do
    u.unitId = uid ; uid = uid + 1
  end
end

local function FixSelfTasks(route, newGrpId, newUnitId)
  if not route or not route.points then return end
  for _,pt in ipairs(route.points) do
    local tasks = (((pt.task or {}).params) or {}).tasks
    if tasks then
      for _,tk in ipairs(tasks) do
        local act = (tk.params or {}).action
        if act and act.id == "EPLRS"          then act.params.groupId = newGrpId end
        if act and act.id == "ActivateBeacon" then act.params.unitId  = newUnitId end
        if act and act.id == "ActivateICLS"   then act.params.unitId  = newUnitId end
      end
    end
  end
end

local CAT={plane="AIRPLANE",helicopter="HELICOPTER",vehicle="GROUND",ship="SHIP",static="STATIC"}

local function FetchMETemplate(name)
  for coaName,coa in pairs(env.mission.coalition) do
    if type(coa)=="table" and coa.country then
      for _,country in pairs(coa.country) do
        for cat,catTbl in pairs(country) do
          if type(catTbl)=="table" and catTbl.group then
            for _,g in ipairs(catTbl.group) do
              if g.name==name then
                local t       = DeepCopy(g)
                t.category    = cat
                t.countryId   = country.id
                t.coaSideEnum = coalition.side[string.upper(coaName)]
                return t
              end
            end
          end
        end
      end
    end
  end
  return nil
end

function Respawn.Group(groupName)
  local live = Group.getByName(groupName)
  if live and live:isExist() then live:destroy() end

  local tpl = FetchMETemplate(groupName)
  if not tpl then env.error("Respawn: ME template '"..groupName.."' not found") return end

  freshIds(tpl)
  tpl.lateActivation = false
  FixSelfTasks(tpl.route, tpl.groupId, tpl.units[1].unitId)

  local ok, newGrp = pcall(coalition.addGroup,tpl.countryId,Group.Category[CAT[tpl.category] or "GROUND"],tpl)
  if not ok then env.error("Respawn: addGroup failed - "..tostring(newGrp)) end
  return newGrp
end

function Respawn.SpawnAtPoint(grpName, coord, headingDeg, distNm, alt)
  local tpl = FetchMETemplate(grpName); if not tpl then return end
  
  local ALT = alt and UTILS.FeetToMeters(alt) or tpl.units[1].alt or UTILS.FeetToMeters(25000)

  local cx, cz = coord.x, coord.z
  if coord.GetVec3 then local v = coord:GetVec3(); cx,cz = v.x, v.z end
  local function toRad(deg) if deg<=180 then return math.rad(deg) else return -math.rad(360-deg) end end
  local h = toRad(headingDeg or 0)
  local psi = -h
  local c, s = math.cos(h), math.sin(h)
  local refX, refZ = tpl.units[1].x, tpl.units[1].y
  for _,u in ipairs(tpl.units) do
    local dx, dz = u.x-refX, u.y-refZ
    u.x = cx + dx*c - dz*s
    u.y = cz + dx*s + dz*c
    u.heading = h
    u.psi = psi
    u.alt = ALT
  end
  local d = (distNm or 5)*1852
  local wpX = cx + d*math.cos(h)
  local wpZ = cz + d*math.sin(h)
  if not tpl.route then tpl.route = {points={}} end
  if not tpl.route.points then tpl.route.points = {} end
  tpl.route.points[1] = {type="Turning Point",action="Turning Point",x=tpl.units[1].x,y=tpl.units[1].y,alt=ALT,alt_type="BARO",speed=tpl.units[1].speed or 380,psi=psi,task={id="ComboTask",params={tasks={}}}}
  tpl.route.points[2] = {type="Turning Point",action="Turning Point",x=wpX,y=wpZ,alt=ALT,alt_type="BARO",speed=tpl.route.points[1].speed,psi=psi,task={id="ComboTask",params={tasks={}}}}
  freshIds(tpl)
  tpl.lateActivation = false
  FixSelfTasks(tpl.route, tpl.groupId, tpl.units[1].unitId)
  local ok,newGrp = pcall(coalition.addGroup,tpl.countryId,Group.Category[CAT[tpl.category] or "GROUND"],tpl)
  if not ok then env.error("Respawn: addGroup failed - "..tostring(newGrp)) return nil end
  return newGrp
end

CustomZone = {}
do
	function CustomZone:getByName(name)
		obj = {}
		obj.name = name
		
		local zd = nil
		for _,v in ipairs(env.mission.triggers.zones) do
			if v.name == name then
				zd = v
				break
			end
		end
		
		if not zd then
			return nil
		end

		obj.type = zd.type -- 2 == quad, 0 == circle
		if obj.type == 2 then
			obj.vertices = {}
			for _,v in ipairs(zd.verticies) do
				local vertex = {
					x = v.x,
					y = 0,
					z = v.y
				}
				table.insert(obj.vertices, vertex)
			end
		end
		
		obj.radius = zd.radius
		obj.point = {
			x = zd.x,
			y = 0,
			z = zd.y
		}
		
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function CustomZone:isQuad()
		return self.type==2
	end
	
	function CustomZone:isCircle()
		return self.type==0
	end
	
	function CustomZone:isInside(point)
		if self:isCircle() then
			local dist=UTILS.VecDist2D({x=point.x,y=point.z},{x=self.point.x,y=self.point.z})
			return dist<self.radius
		elseif self:isQuad() then
			return UTILS.IsPointInPolygon({x=point.x,y=point.z},self.vertices)
		end
	end
	
	function CustomZone:getZoneBuildings()
		buildingCache                 = buildingCache or {}
		if buildingCache[self.name] then return buildingCache[self.name] end

		local pts, vol = {}, nil
		if self:isCircle() then
			vol = { id = world.VolumeType.SPHERE,
					params = { point = self.point, radius = self.radius } }
		else
			local r = 0
			for _,v in ipairs(self.vertices) do
				local d = UTILS.VecDist2D({x = v.x, y = v.z},
										{x = self.point.x, y = self.point.z})
				if d > r then r = d end
			end
			vol = { id = world.VolumeType.SPHERE,
					params = { point = self.point, radius = r } }
		end

		world.searchObjects(Object.Category.SCENERY, vol, function(o)
			if o then
				local d = o:getDesc()
				if d and d.attributes and d.attributes.Buildings then
					local p = o:getPoint()
					if self:isInside(p) then pts[#pts + 1] = p end
				end
			end
		end)

		buildingCache[self.name] = pts
		return pts
	end

	function CustomZone:draw(id, border, background)

		--if not self.name:lower():find("hidden") then
		if not (self.name:lower():find("hidden") or self.name:lower():find("railway")) then
			if self:isCircle() then
				trigger.action.circleToAll(-1, id, self.point, self.radius, border, background, 1)
			elseif self:isQuad() then
				trigger.action.quadToAll(-1, id, self.vertices[4], self.vertices[3], self.vertices[2], self.vertices[1], border, background, 1)
			end
		else
			env.info("Zone [" .. self.name .. "] is marked as hidden and will not be drawn.")
		end
	end

	function GetValidCords(zoneName, allowed, attempts)
	local zone = ZONE:FindByName(zoneName)
	if not zone then return nil end
	attempts = attempts or 100
	for _ = 1, attempts do
		local coord = zone:GetRandomCoordinate()
		if allowed[coord:GetSurfaceType()] and coord:GetSurfaceType() ~= land.SurfaceType.RUNWAY then
		return coord
		end
	end
	return nil
	end

	function CustomZone:getRandomSpawnZone()
		local spawnZones = {}
		for i = 1, 100, 1 do
			local zname = self.name .. '-' .. i
			if trigger.misc.getZone(zname) then
				table.insert(spawnZones, zname)
			else
				break
			end
		end

		if #spawnZones == 0 then return nil end

		local choice = math.random(1, #spawnZones)
		return spawnZones[choice]
	end

	function SpawnCustom(grname, zoneName)
	spawnCounter[grname] = (spawnCounter[grname] or 0) + 1
	local alias = string.format("%s # %d", grname, spawnCounter[grname])

	local grp = GROUP:FindByName(grname)
	local tpl = grp and grp:GetTemplate()
	if grp then grp:Destroy() end
	if not tpl then return nil end

	local isCarrierZone = zoneName and zoneName:lower():find("carrier")
	local gr

	if zoneName then
		local allowed = isCarrierZone and {
		[land.SurfaceType.WATER] = true,
		[land.SurfaceType.SHALLOW_WATER] = true
		} or {
		[land.SurfaceType.LAND] = true,
		[land.SurfaceType.ROAD] = true
		}

		local spawn = SPAWN:NewFromTemplate(tpl, grname, alias, true):InitHiddenOnMFD():InitSkill("Excellent")
		if not grname:find("Red SAM") and not grname:find("bluePD1") and not grname:find("bluePD2") and not grname:find("blueHAWK") then
		spawn = isCarrierZone and spawn:InitRandomizeUnits(true, 1500, 1000) or spawn:InitRandomizeUnits(true, 100, 30):InitHeading(1, 359)
		end
		local tries = 0
		while tries < 10 and not gr do
			local coord = zoneName and GetValidCords(zoneName, allowed)
			if coord then
			gr = spawn:SpawnFromCoordinate(coord)
			end
			tries = tries + 1
		end
		return gr
		end
	end


	USED_SUB_ZONES = USED_SUB_ZONES or {}

	function CustomZone:getRandomUnusedSpawnZone(markUsed)
		if markUsed == nil then markUsed = true end
		self.usedSpawnZones = self.usedSpawnZones or {}
		local unused, all = {}, {}
		for i = 1, 100 do
			local zname = self.name .. '-' .. i
			if trigger.misc.getZone(zname) then
				all[#all + 1] = zname
				if not self.usedSpawnZones[zname] and not USED_SUB_ZONES[zname] then
					unused[#unused + 1] = zname
				end
			end
		end
		if #unused == 0 then
			self.usedSpawnZones = {}
			return nil
		end
		local pool = (#unused > 0) and unused or all
		if #pool == 0 then return nil end
		local selected = pool[math.random(1, #pool)]
		if markUsed then
			self.usedSpawnZones[selected] = true
			USED_SUB_ZONES[selected]      = true
		end
		return selected
	end
	
	spawnCounter = spawnCounter or {}



function CustomZone:spawnGroup(grname, forceFirst)
  if not grname or type(grname)~="string" then
    trigger.action.outText("Error: grname is nil or not a valid string",5)
    return nil
  end


	if grname:find("Fixed") then
		local grp = GROUP:FindByName(grname)
		if not grp then trigger.action.outText(grname.." not found, Report it to leka and what map", 60) end
		local tpl = grp and grp:GetTemplate() or UTILS.DeepCopy(_DATABASE.Templates.Groups[grname].Template)
		if grp then grp:Destroy() end
		local g   = SPAWN:NewFromTemplate(tpl,grname,nil,true):InitHiddenOnMFD():Spawn()
		return g and { name = g:GetName() } or nil
	end

	local zonePool = {}
	local unused = {}
	local all    = {}
	for i=1,100 do
		local z = self.name.."-"..i
		if not trigger.misc.getZone(z) then break end
		all[#all+1] = z
		if not (self.usedSpawnZones and self.usedSpawnZones[z]) and not USED_SUB_ZONES[z] then
		unused[#unused+1] = z
		end
	end
	local rest = (#unused>0) and unused or all
	for _,z in ipairs(rest) do zonePool[#zonePool+1]=z end

	if #zonePool==0 then zonePool[#zonePool+1]=self.name end

	for _,spawnzone in ipairs(zonePool) do
		local g = SpawnCustom(grname, spawnzone)
		if g then
		self.usedSpawnZones            = self.usedSpawnZones or {}
		self.usedSpawnZones[spawnzone] = true
		USED_SUB_ZONES[spawnzone]      = true
		return { name = g:GetName() }
		end
	end

	trigger.action.outText("Failed to spawn group: "..grname .. " zone: " .. self.name,5)
	env.info("zoneCommander DEBUG: Failed to spawn group: "..grname .. " zone: " .. self.name)
	return nil
	end

	function CustomZone:clearUsedSpawnZones(zone)
		local prefix = zone or self.name
		for z,_ in pairs(USED_SUB_ZONES) do
			if z:sub(1,#prefix+1) == prefix.."-" then
				USED_SUB_ZONES[z] = nil
			end
		end
	end

end
Utils = {}
do
	function Utils.getPointOnSurface(point)
		return {x = point.x, y = land.getHeight({x = point.x, y = point.z}), z= point.z}
	end
	
	function Utils.getTableSize(tbl)
		local cnt = 0
		for i,v in pairs(tbl) do cnt=cnt+1 end
		return cnt
	end
	
	function Utils.getBearing(fromvec, tovec)
		local fx = fromvec.x
		local fy = fromvec.z
		
		local tx = tovec.x
		local ty = tovec.z
		
		local brg = math.atan2(ty - fy, tx - fx)
		if brg < 0 then
			 brg = brg + 2 * math.pi
		end
		
		brg = brg * 180 / math.pi
		return brg
	end
	
	function Utils.getAGL(object)
		local pt = object:getPoint()
		return pt.y - land.getHeight({ x = pt.x, y = pt.z })
	end
	
	function Utils.isLanded(unit, ignorespeed)
		if not unit then return false end
		local airborne=(unit.inAir and unit:inAir()) or (unit.InAir and unit:InAir()) or false
		if ignorespeed then
			return not airborne
		else
			local v=unit:getVelocity()
			local kmh=math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)*3.6
			return (not airborne) and kmh<4
		end
	end
	
	function IsGroupActive(groupName)
		local group = GROUP:FindByName(groupName)
		if group then
			return group:IsAlive()
		else
			return false
		end
	end

	function activateGroupIfNotActive(groupName)
		if not IsGroupActive(groupName) then
			local group = Group.getByName(groupName)
			if group then
				group:activate()
			else
				return false
			end
		end
	end
	function destroyGroupIfActive(groupName)
		if IsGroupActive(groupName) then
			local group = Group.getByName(groupName)
			if group then
				group:destroy()
			else
				return false
			end
		end
	end
	function SpawnGroupIfNotActive(groupName)
		if not IsGroupActive(groupName) then
			Respawn.Group(groupName)
		end
	end
	function Utils.allGroupIsLanded(group, ignorespeed)
		for _,unit in ipairs(group:getUnits()) do
			if not Utils.isLanded(unit, ignorespeed) then return false end
		end
		return true
	end

	Group.getByNameBase = Group.getByName

	function Utils.isGroupActive(group)
		if not group or group:getSize()==0 then return false end
		local c=group:getController()
		if c and (not c.hasTask or c:hasTask()) then
			return not Utils.allGroupIsLanded(group,true)
		end
		return false
	end
	
	function Utils.isInAir(unit)
	if not unit then return false end
	if unit.InAir then
		return unit:InAir()
	else
		return unit:inAir()
	end
	end
	
	function Utils.isInZone(unit, zonename)
		local zn = CustomZone:getByName(zonename)
		if zn then
			return zn:isInside(unit:getPosition().p)
		end
		
		return false
	end
	
	function Utils.isCrateSettledInZone(crate, zonename)
		local zn = CustomZone:getByName(zonename)
		if zn and crate then
			return (zn:isInside(crate:getPosition().p) and Utils.getAGL(crate)<1)
		end
		
		return false
	end
	
	function Utils.someOfGroupInZone(group, zonename)
		for i,v in pairs(group:getUnits()) do
			if Utils.isInZone(v, zonename) then
				return true
			end
		end
		
		return false
	end
	
	function Utils.allGroupIsLanded(group, ignorespeed)
		for i,v in pairs(group:getUnits()) do
			if not Utils.isLanded(v, ignorespeed) then
				return false
			end
		end
		
		return true
	end
	
	function Utils.someOfGroupInAir(group)
		for i,v in pairs(group:getUnits()) do
			if Utils.isInAir(v) then
				return true
			end
		end
		
		return false
	end
	
	Utils.canAccessFS = true
	function Utils.saveTable(filename, variablename, data)
		if not Utils.canAccessFS then 
			return
		end
		
		if not io then
			Utils.canAccessFS = false
			trigger.action.outText('Persistance disabled, Save file can not be created', 600)
			return
		end
	
		local str = variablename..' = {}'
		for i,v in pairs(data) do
			str = str..'\n'..variablename..'[\''..i..'\'] = '..Utils.serializeValue(v)
		end
	
		File = io.open(filename, "w")
		File:write(str)
		File:close()
	end
	
	function Utils.serializeValue(value)
		local res = ''
		if type(value)=='number' or type(value)=='boolean' then
			res = res..tostring(value)
		elseif type(value)=='string' then
			res = res..'\''..value..'\''
		elseif type(value)=='table' then
			res = res..'{ '
			for i,v in pairs(value) do
				if type(i)=='number' then
					res = res..'['..i..']='..Utils.serializeValue(v)..','
				else
					res = res..'[\''..i..'\']='..Utils.serializeValue(v)..','
				end
			end
			res = res:sub(1,-2)
			res = res..' }'
		end
		return res
	end
	
	function Utils.loadTable(filename)
		if not Utils.canAccessFS then 
			return
		end
		
		if not lfs then
			Utils.canAccessFS = false
			trigger.action.outText('Persistance disabled, Save file can not be created\n\nDe-Sanitize DCS missionscripting.lua', 600)
			return
		end
		
		if lfs.attributes(filename) then
			dofile(filename)
		end
	end
end

	function Utils.log(func)
		return function(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10)
			local err, msg = pcall(func,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10)
			if not err then
				env.info("ERROR - callFunc\n"..msg)
				env.info('Traceback\n'..debug.traceback())
			end
		end
	end
--[[
JTAC = {}
do	
	jtacQueue = jtacQueue or {}
	JTAC.categories = {}
	JTAC.categories['SAM'] = {'SAM SR', 'SAM TR', 'IR Guided SAM'}
	if UseStatics then
	JTAC.categories['Structures'] = {'StaticObjects'}
	end
	JTAC.categories['Infantry'] = {'Infantry'}
	JTAC.categories['Armor'] = {'Tanks','IFV','APC'}
	JTAC.categories['Support'] = {'Unarmed vehicles','Artillery','SAM LL','SAM CC'}
	
	
	--{name = 'groupname'}
	function JTAC:new(obj)
		obj = obj or {}
		obj.lasers = {tgt=nil, ir=nil}
		obj.target = nil
		obj.timerReference = nil
		obj.tgtzone = nil
		obj.priority = nil
		obj.jtacMenu = nil
		obj.laserCode = 1688
		obj.side = Group.getByName(obj.name):getCoalition()
		setmetatable(obj, self)
		self.__index = self
		obj:initCodeListener()
		return obj
	end
	
	function JTAC:initCodeListener()
		local ev = {}
		ev.context = self
		function ev:onEvent(event)
			if event.id == 26 then
				if event.text:find('^jtac%-code:') then
					local s = event.text:gsub('^jtac%-code:', '')
					local code = tonumber(s)
					self.context:setCode(code)
                    trigger.action.removeMark(event.idx)
				end
			end
		end

		world.addEventHandler(ev)
	end
	
	function JTAC:setCode(code)
        if code>=1111 and code <= 1788 then
            self.laserCode = code
            trigger.action.outTextForCoalition(self.side,'JTAC code set to '..code..' at '..self.tgtzone.zone,15)
        else
            trigger.action.outTextForCoalition(self.side, 'Invalid laser code. Must be between 1111 and 1788 ', 10)
        end
    end
	
	function JTAC:showMenu()
		local gr = Group.getByName(self.name)
		if not gr then
			return
		end
		
		if self.jtacMenu then
			missionCommands.removeItemForCoalition(self.side, self.jtacMenu)
			self.jtacMenu = nil
		end

		if not self.jtacMenu then
			self.jtacMenu = missionCommands.addSubMenuForCoalition(self.side, self.tgtzone.zone .. ' JTAC')
			
			missionCommands.addCommandForCoalition(self.side, 'Target report', self.jtacMenu, function(dr)
				if Group.getByName(dr.name) then
					dr:printTarget(true)
				else
					missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
					dr.jtacMenu = nil
				end
			end, self)

			missionCommands.addCommandForCoalition(self.side, 'Next Target', self.jtacMenu, function(dr)
				if Group.getByName(dr.name) then
					dr:searchTarget()
				else
					missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
					dr.jtacMenu = nil
				end
			end, self)
			
			missionCommands.addCommandForCoalition(self.side, 'Smoke on target', self.jtacMenu, function(dr)
				if Group.getByName(dr.name) then
					local tgtunit = Unit.getByName(dr.target)
                    if not tgtunit then
                        tgtunit = StaticObject.getByName(dr.target)
                    end

					if tgtunit then
						trigger.action.smoke(tgtunit:getPoint(), 3)
						trigger.action.outTextForCoalition(dr.side,'JTAC target marked with ORANGE smoke at '..dr.tgtzone.zone,15)
					end
				else
					missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
					dr.jtacMenu = nil
				end
			end, self)
			
			local priomenu = missionCommands.addSubMenuForCoalition(self.side, 'Set Priority', self.jtacMenu)
			for i,v in pairs(JTAC.categories) do
				missionCommands.addCommandForCoalition(self.side, i, priomenu, function(dr, cat)
					if Group.getByName(dr.name) then
						dr:setPriority(cat)
						dr:searchTarget()
					else
						missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
						dr.jtacMenu = nil
					end
				end, self, i)
			end
			
			missionCommands.addCommandForCoalition(self.side, "Clear", priomenu, function(dr)
				if Group.getByName(dr.name) then
					dr:clearPriority()
					dr:searchTarget()
				else
					missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
					dr.jtacMenu = nil
				end
			end, self)
            local dial = missionCommands.addSubMenuForCoalition(self.side, 'Set Laser Code', self.jtacMenu)
            for i2=1,7,1 do
                local digit2 = missionCommands.addSubMenuForCoalition(self.side, '1'..i2..'__', dial)
                for i3=1,9,1 do
                    local digit3 = missionCommands.addSubMenuForCoalition(self.side, '1'..i2..i3..'_', digit2)
                    for i4=1,9,1 do
                        local digit4 = missionCommands.addSubMenuForCoalition(self.side, '1'..i2..i3..i4, digit3)
                        local code = tonumber('1'..i2..i3..i4)
                        missionCommands.addCommandForCoalition(self.side, 'Accept', digit4, Utils.log(self.setCode), self, code)
                    end
                end
            end
			self.selectTargetMenu = missionCommands.addSubMenuForCoalition(self.side, 'Select Target', self.jtacMenu)
		end
	end


	function JTAC:setPriority(prio)
		self.priority = JTAC.categories[prio]
		self.prioname = prio
	end
	
	function JTAC:clearPriority()
		self.priority = nil
	end
	
function JTAC:setTarget(unit)

	if self.lasers.tgt then
		self.lasers.tgt:destroy()
		self.lasers.tgt = nil
	end

	if self.lasers.ir then
		self.lasers.ir:destroy()
		self.lasers.ir = nil
	end

	local me = Group.getByName(self.name)
	if not me then return end


	local pnt = unit:getPoint()
	local adjustedPoint = { x = pnt.x, y = pnt.y + 1.0, z = pnt.z }
	self.lasers.tgt = Spot.createLaser(me:getUnit(1), { x = 0, y = 2.0, z = 0 }, pnt, self.laserCode)
	self.lasers.ir = Spot.createInfraRed(me:getUnit(1), { x = 0, y = 2.0, z = 0 }, pnt)
	self.target = unit:getName()
end

function renameType(tgttype)
	if not tgttype then
		return "Unknown"
	end
	if string.find(tgttype,"ZU%-23 Emplacement") then
		return "ZU-23 Emplacement"
	elseif string.find(tgttype,"BTR_D") then
		return "BTR D"
	elseif string.find(tgttype,"Shilka") then
		return "Shilka"
	elseif string.find(tgttype,"BTR%-82A") then
		return "BTR 82A"
	elseif string.find(tgttype,"BMP%-3") then
		return "BMP 3"
	elseif string.find(tgttype,"ZSU_57_2") then
		return "ZSU 58"
	elseif string.find(tgttype,"generator_5i57") then
		return "SA-10 Generator"
	elseif string.find(tgttype,"tt_zu%-23") then
		return "ZU-23"
	elseif string.find(tgttype,"T%-72") then
		return "Tank T-72"
	elseif string.find(tgttype,"tt_DSHK") then
		return "DSHK Technical"
	elseif string.find(tgttype,"HL_KORD") then
		return "HL Technical"
	elseif string.find(tgttype,"HL_DSHK") then
		return "HL Technical"
	elseif string.find(tgttype,"tt_KORD") then
		return "KORD Technical"
	elseif string.find(tgttype,"APA%-80") then
		return "Zil-131"
	elseif string.find(tgttype,"_Phalanx") then
		return "C-RAM"
	elseif string.find(tgttype,"Tor") then
		return "SA-15"
	elseif string.find(tgttype,"Osa") then
		return "SA-8"
	elseif string.find(tgttype,"manpad") then
		return "MANPAD"
	elseif string.find(tgttype,"Tunguska") then
		return "SA-19"
	elseif string.find(tgttype,"Kub 1S91 str") then
		return "SA-6 STR"
	elseif string.find(tgttype,"Kub 2P25 ln") then
		return "SA-6 LN"
	elseif string.find(tgttype,"snr s%-125 tr") then
		return "SA-3 TR"
	elseif string.find(tgttype,"40B6M tr") then
		return "SA-10 TR"
	elseif string.find(tgttype,"RPC_5N62V") then
		return "SA-5 TR"
	elseif string.find(tgttype,"RLS_19J6") then
		return "SA-5 SR"
	elseif string.find(tgttype,"S%-200_Launcher") then
		return "SA-5 LN"
	elseif string.find(tgttype,"SA%-11 Buk LN") then
		return "SA-11 LN"
	elseif string.find(tgttype,"9S18M1") then
		return "SA-11 SnowDrift SR"
	elseif string.find(tgttype,"9S4770M1") then
		return "SA-11 Command Center"
	elseif string.find(tgttype,"S%-60_Type59") then
		return "S-60 Artillery"
	elseif string.find(tgttype,"p%-19 s%-125 s") then
		return "P19 SAM SR"
	elseif string.find(tgttype,"64H6E sr") then
		return "SA-10 SR 64H6E"
	elseif string.find(tgttype,"40B6MD sr") then
		return "SA-10 SR 40B6MD"
	elseif string.find(tgttype,"5P85C") then
		return "SA-10 LN"
	elseif string.find(tgttype,"5P85D") then
		return "SA-10 LN"
	elseif string.find(tgttype,"54K6") then
		return "SA-10 CP"
	elseif string.find(tgttype,"5p73") then
		return "SA-3 LN"
	elseif string.find(tgttype,"SNR_75V") then
		return "SA-2 TR"
	elseif string.find(tgttype,"Volhov") then
		return "SA-2 LN"
	end
	return tgttype
end

function JTAC:printTarget(makeitlast)
	local toprint=''
	if self.target and self.tgtzone then
		local tgtunit=Unit.getByName(self.target)
		local isStatic=false
		if not tgtunit then
			tgtunit=StaticObject.getByName(self.target)
			isStatic=true
		end
		if tgtunit then
			local pnt=tgtunit:getPoint()
			local tgttype=isStatic and tgtunit:getName() or renameType(tgtunit:getTypeName())
			if self.priority then toprint='Priority targets: '..self.prioname..'\n' end
			local movingLine=''
			if not isStatic then
				local vel=tgtunit:getVelocity()
				if vel then
					local spd=math.sqrt(vel.x^2+vel.z^2)
					if spd>1 then
						local hdg=UTILS.VecHdg(vel);if hdg<0 then hdg=hdg+360 end
						local dir
						if hdg>=337.5 or hdg<22.5 then dir='north bound'
						elseif hdg<67.5 then dir='north east bound'
						elseif hdg<112.5 then dir='east bound'
						elseif hdg<157.5 then dir='south east bound'
						elseif hdg<202.5 then dir='south bound'
						elseif hdg<247.5 then dir='south west bound'
						elseif hdg<292.5 then dir='west bound'
						else dir='north west bound' end
						movingLine='\nTarget is moving '..dir
					end
				end
			end
			toprint=toprint..'Lasing '..tgttype..' at '..self.tgtzone.zone..movingLine..'\nCode: '..self.laserCode..'\n'
			local lat,lon,alt=coord.LOtoLL(pnt)
			local c=COORDINATE:NewFromVec3(pnt)
			local function ddm(v,h)local d=math.floor(math.abs(v))local m=(math.abs(v)-d)*60 return string.format("[%s %02d %06.3f']",h,d,m)end
			local function dms(v,h)local a=math.abs(v)local d=math.floor(a)local m=math.floor((a-d)*60)local s=((a-d)*60-m)*60 return string.format("[%s %02d %02d' %05.2f\"]",h,d,m,s)end
			local ddmStr=ddm(lat,lat>=0 and 'N' or 'S')..'⇢ '..ddm(lon,lon>=0 and 'E' or 'W')
			local dmsStr=dms(lat,lat>=0 and 'N' or 'S')..'⇢ '..dms(lon,lon>=0 and 'E' or 'W')
			local mgrs=c:ToStringMGRS():gsub("^MGRS%s*","")
			toprint=toprint..'\nDDM:  '..ddmStr
			toprint=toprint..'\nDMS:  '..dmsStr
			toprint=toprint..'\nMGRS: '..mgrs
			toprint=toprint..'\n\nAlt: '..math.floor(alt)..'m | '..math.floor(alt*3.280839895)..'ft'
		else
			makeitlast=false
			toprint='No Target'
		end
	else
		makeitlast=false
		toprint='No target'
	end
	local gr=Group.getByName(self.name)
	if makeitlast then
		trigger.action.outTextForCoalition(gr:getCoalition(),toprint,60)
	else
		trigger.action.outTextForCoalition(gr:getCoalition(),toprint,10)
	end
end

	
	function JTAC:clearTarget()
		self.target = nil
		jtacIntelActive[self.tgtzone.zone] = false
		if self.lasers.tgt then
			self.lasers.tgt:destroy()
			self.lasers.tgt = nil
		end
		if self.lasers.ir then
			self.lasers.ir:destroy()
			self.lasers.ir = nil
		end
		if self.timerReference then
			self.timerReference:Stop()
			self.timerReference=nil
		end
		local gr = Group.getByName(self.name)
		if gr then
			gr:destroy()
		end
		missionCommands.removeItemForCoalition(self.side, self.jtacMenu)
		self.jtacMenu = nil
		for i,v in ipairs(jtacQueue) do
			if v == self then table.remove(jtacQueue,i) break end
		end
	end
	
	function JTAC:searchTarget()
		local gr = Group.getByName(self.name)
		if gr then
			if self.tgtzone and self.tgtzone.side~=0 and self.tgtzone.side~=gr:getCoalition() then
				local viabletgts = {}
				for i,v in pairs(self.tgtzone.built) do
					local tgtgr = Group.getByName(v)
					if tgtgr and tgtgr:getSize()>0 then
						for i2,v2 in ipairs(tgtgr:getUnits()) do
							if v2:getLife()>=1 then
								table.insert(viabletgts, v2)
							end
						end
					else
						tgtgr = StaticObject.getByName(v)
						if tgtgr and tgtgr:isExist() then
							local isCritical=false for _,co in ipairs(self.tgtzone.criticalObjects) do if co==v then isCritical=true break end end
							if not isCritical then table.insert(viabletgts, tgtgr) end
						end
					end
				end
				
				if self.priority then
					local priorityTargets = {}
					for i,v in ipairs(viabletgts) do
						for i2,v2 in ipairs(self.priority) do
							if v2 == "StaticObjects" then
								if Object.getCategory(v) == Object.Category.STATIC and v:getName() then
									table.insert(priorityTargets,v)
									break
								end
							elseif v:hasAttribute(v2) and v:getLife()>=1 then
								table.insert(priorityTargets,v)
								break
							end
						end
					end
					
					if #priorityTargets>0 then
						viabletgts = priorityTargets
					else
						self:clearPriority()
						trigger.action.outTextForCoalition(gr:getCoalition(), 'JTAC: No priority targets found', 10)
					end
				end
				
				if #viabletgts>0 then
					local chosentgt = math.random(1, #viabletgts)
					self:setTarget(viabletgts[chosentgt])
					self:printTarget()
					self:buildSelectTargetMenu()
				else
					self:clearTarget()
				end
			else
				self:clearTarget()
			end
		end
	end

	
	function JTAC:searchIfNoTarget()
		if not Group.getByName(self.name) then
			self:clearTarget()
			return
		end
	
		if not self.target then
			self:searchTarget()
			return
		end
	
		local un = Unit.getByName(self.target) or StaticObject.getByName(self.target)
		if un and un:isExist() and un:getLife() >= 1 then

			self:setTarget(un)
			if self.tgtzone and self.tgtzone.built then
				local oldCount = self._lastViableCount or 0
				local newCount = 0
				for _, v in pairs(self.tgtzone.built) do
					local tgtgr = Group.getByName(v)
					if tgtgr and tgtgr:getSize() > 0 then
						for _,unitObj in ipairs(tgtgr:getUnits()) do
							if unitObj:getLife() >= 1 then
								newCount = newCount + 1
							end
						end
					else
						local st = StaticObject.getByName(v)
						if st and st:isExist() then
							local isCritical = false
							for _,co in ipairs(self.tgtzone.criticalObjects) do
								if co == v then
									isCritical = true
									break
								end
							end
							if not isCritical then
								newCount = newCount + 1
							end
						end
					end
				end
	
				if newCount < oldCount then
					self:buildSelectTargetMenu()
				end
				self._lastViableCount = newCount
			end
	
		else
			self:searchTarget()
			self:buildSelectTargetMenu()
		end
	end
	
	jtacIntelActive = jtacIntelActive or {}


	function JTAC:deployAtZone(zoneCom)
		self.tgtzone=zoneCom
		jtacIntelActive[zoneCom.zone]=true
		local p=CustomZone:getByName(self.tgtzone.zone).point
		local coord=COORDINATE:New(p.x,6000,p.z)
		local tpl=UTILS.DeepCopy(_DATABASE.Templates.Groups[self.name].Template)
		self.spawnObj=SPAWN:NewFromTemplate(tpl,self.name,nil,true)
		
			:OnSpawnGroup(function()self:setOrbit(self.tgtzone.zone,p)end)
		self.spawnObj:SpawnFromCoordinate(coord)
		if not self.timerReference then
			self.timerReference=SCHEDULER:New(nil,self.searchIfNoTarget,{self},5,5)
		end
	end


	function JTAC:setOrbit(zonename, point)
		local gr = Group.getByName(self.name)
		if not gr then 
			return
		end
		local GroupID = gr:getID()

		local cnt = gr:getController()
		cnt:setCommand({ 
			id = 'SetInvisible', 
			params = { 
				value = true
			} 
		})
		cnt:setCommand({ 
			id = 'SetImmortal', 
			params = { 
				value = true
			} 
		})
		cnt:setCommand({ 
			id = 'EPLRS', 
			params = { 
				value = true,
				groupId = GroupID
			} 
		})
		cnt:setTask({ 
			id = 'Orbit', 
			params = { 
				pattern = 'Circle',
				point = {x = point.x, y=point.z},
				altitude = 6000
			} 
		})
		
		self:searchTarget()
	end

	function JTAC:sortByThreat(targets)
		local threatRank = {
			['SAM TR']          = 1,
			['IR Guided SAM']   = 2,
			['SAM SR']          = 3,
			['Tanks']           = 4,
			['IFV']             = 5,
			['APC']             = 6,
			['Artillery']       = 7,
			['SAM LL']          = 8,
			['SAM CC']          = 9,
			['Unarmed vehicles']= 10,
			['Infantry']        = 11,
			['Structures']   	= 12
		}

		local function getScore(u)
			local best = 999
			for attr, rank in pairs(threatRank) do
				if u:hasAttribute(attr) and rank < best then
					best = rank
				end
			end
			return best
		end

		table.sort(targets, function(a,b) return getScore(a) < getScore(b) end)
		return targets
	end


	function JTAC:buildSelectTargetMenu()
		if not self.jtacMenu then
			return
		end

		if self.selectTargetMenu then
			missionCommands.removeItemForCoalition(self.side, self.selectTargetMenu)
		end

		self.selectTargetMenu = missionCommands.addSubMenuForCoalition(self.side, 'Select Target', self.jtacMenu)

		local gr = Group.getByName(self.name)
		if not gr or not self.tgtzone or self.tgtzone.side == 0 or self.tgtzone.side == gr:getCoalition() then
			missionCommands.addCommandForCoalition(self.side, 'No valid targets', self.selectTargetMenu, function() end)
			return
		end

		local viabletgts = {}
		for i,v in pairs(self.tgtzone.built) do
			local tgtgr = Group.getByName(v)
			if tgtgr and tgtgr:getSize() > 0 then
				for i2,v2 in ipairs(tgtgr:getUnits()) do
					if v2:getLife() >= 1 then
						table.insert(viabletgts, v2)
					end
				end
			else
				local st = StaticObject.getByName(v)
				if st and st:isExist() then
					local isCritical=false for _,co in ipairs(self.tgtzone.criticalObjects) do if co==v then isCritical=true break end end
					if not isCritical and Object.getCategory(st) == Object.Category.STATIC and st:getName() then
						table.insert(viabletgts, st)
					end
				end
			end
		end
		if self.priority then
			local priorityTargets = {}
			for i,v in ipairs(viabletgts) do
				for i2,v2 in ipairs(self.priority) do
					if v2 == "StaticObjects" then
						if Object.getCategory(v) == Object.Category.STATIC and v:getName() then
							table.insert(priorityTargets,v)
							break
						end
					elseif v:hasAttribute(v2) and v:getLife() >= 1 then
						table.insert(priorityTargets,v)
						break
					end
				end
			end
			if #priorityTargets > 0 then
				viabletgts = priorityTargets
			else
				self:clearPriority()
				trigger.action.outTextForCoalition(gr:getCoalition(), 'JTAC: No priority targets found', 10)
			end
		end

		if #viabletgts == 0 then
			missionCommands.addCommandForCoalition(self.side, 'No valid targets', self.selectTargetMenu, function() end)
			return
		end

		if self.sortByThreat then
			viabletgts = self:sortByThreat(viabletgts)
		end

		local subMenuRef = nil
		for i, unitObj in ipairs(viabletgts) do
			local thisUnit = unitObj
			local label
			if Object.getCategory(thisUnit) == Object.Category.STATIC then
				label = '('..i..') '..(thisUnit:getName() or "Unknown")
			else
				local tgttype = renameType(thisUnit:getTypeName())
				label = '('..i..') '..tgttype
			end
			if self.target == thisUnit:getName() then
				label = label .. ' (Lasing)'
			end
			
			local callback = function()
				self.isManualTarget = true
				self:setTarget(thisUnit)
				self:printTarget(true)
				self:buildSelectTargetMenu()
			end

			if i < 10 then
				missionCommands.addCommandForCoalition(self.side, label, self.selectTargetMenu, callback)
					--env.info("[JTAC] Selected unitObj: " .. (thisUnit:getName() or "NIL"))

			elseif i == 10 then
				subMenuRef = missionCommands.addSubMenuForCoalition(self.side, 'More', self.selectTargetMenu)
				missionCommands.addCommandForCoalition(self.side, label, subMenuRef, callback)
					--env.info("[JTAC] Selected unitObj: " .. (thisUnit:getName() or "NIL"))

			elseif (i - 10) % 9 == 0 then
				subMenuRef = missionCommands.addSubMenuForCoalition(self.side, 'More', subMenuRef)
				missionCommands.addCommandForCoalition(self.side, label, subMenuRef, callback)
					--env.info("[JTAC] Selected unitObj: " .. (thisUnit:getName() or "NIL"))
			else
				missionCommands.addCommandForCoalition(self.side, label, subMenuRef, callback)
					--env.info("[JTAC] Selected unitObj: " .. (thisUnit:getName() or "NIL"))
			end
		end
	end
end
--]]
------------------------------------------ jtac 9 line AM --------------------------------------------
--[[
JTAC9line = {}
do
    function JTAC9line:new(obj)
        obj = obj or {}
        obj.side = Group.getByName(obj.name):getCoalition()
        setmetatable(obj, self)
        self.__index = self
        return obj
    end

	function JTAC9line:deployAtZone(zoneCom)
		self.tgtzone=zoneCom
		local p=CustomZone:getByName(self.tgtzone.zone).point
		local coord=COORDINATE:New(p.x,6000,p.z)
		local tpl=UTILS.DeepCopy(_DATABASE.Templates.Groups[self.name].Template)
		self.spawnObj=SPAWN:NewFromTemplate(tpl,self.name,nil,true)
			:OnSpawnGroup(function()self:setTasks(self.tgtzone.zone,p)end)
		self.spawnObj:SpawnFromCoordinate(coord)
	end


    function JTAC9line:setTasks(zonename, point)
        local gr = Group.getByName(self.name)
        if gr then
            local cnt = gr:getController()
            cnt:setCommand({
                id = 'SetInvisible', 
                params = { 
                    value = true 
                } 
            })

            -- Set ComboTask with FAC and Orbit as sequential tasks
            local comboTask = {
                id = 'ComboTask',
                params = {
                    tasks = {
                        [1] = {  -- FAC Task
                            id = 'FAC',
                            params = {
                                frequency = 241000000,
                                modulation = 0,
                                callname = 2,
                                number = 1,
                                designation = 'Auto',
                                datalink = true,
                                priority = 1
                            }
                        },
                        [2] = {  -- Orbit Task
                            id = 'Orbit',
                            params = {
                                pattern = 'Circle',
                                point = {x = point.x, y = point.z},
                                altitude = 6000,
                                number = 2
                            }
                        }
                    }
                }
            }

            cnt:setTask(comboTask)
        else
            trigger.action.outText("JTAC Group not found after deployment: " .. self.name, 10)
        end
    end
end
--]]
----------------------------------------- jtac 9 line fm --------------------------------------------
--[[
JTAC9linefmr = {}
do
    function JTAC9linefmr:new(obj)
        obj = obj or {}
        obj.side = Group.getByName(obj.name):getCoalition()
        setmetatable(obj, self)
        self.__index = self
        return obj
    end

	function JTAC9linefmr:deployAtZone(zoneCom)
		self.tgtzone=zoneCom
		local p=CustomZone:getByName(self.tgtzone.zone).point
		local coord=COORDINATE:New(p.x,6000,p.z)
		local tpl=UTILS.DeepCopy(_DATABASE.Templates.Groups[self.name].Template)
		self.spawnObj=SPAWN:NewFromTemplate(tpl,self.name,nil,true)
			:OnSpawnGroup(function()self:setTasks(self.tgtzone.zone,p)end)
		self.spawnObj:SpawnFromCoordinate(coord)
	end

    function JTAC9linefmr:setTasks(zonename, point)
        local gr = Group.getByName(self.name)
        if gr then
            local cnt = gr:getController()
            cnt:setCommand({
                id = 'SetInvisible', 
                params = { 
                    value = true 
                } 
            })

            -- Set ComboTask with FAC and Orbit as sequential tasks for 31 MHz FM
            local comboTask = {
                id = 'ComboTask',
                params = {
                    tasks = {
                        [1] = {  -- FAC Task
                            id = 'FAC',
                            params = {
                                frequency = 31000000,  -- 31 MHz
                                modulation = 1,        -- FM modulation
                                callname = 3,
                                number = 1,
                                designation = 'Auto',
                                datalink = true,
                                priority = 1
                            }
                        },
                        [2] = {  -- Orbit Task
                            id = 'Orbit',
                            params = {
                                pattern = 'Circle',
                                point = {x = point.x, y = point.z},
                                altitude = 6000,
                                number = 2
                            }
                        }
                    }
                }
            }

            cnt:setTask(comboTask)
        else
            trigger.action.outText("JTAC Group not found after deployment: " .. self.name, 10)
        end
    end
end
--]]
----------------------------------------- END jtac 9 line FM --------------------------------------------

function CustomRespawn(grpName)
    local g = GROUP:FindByName(grpName)
    if g and g:IsAlive() then
        local tpl       = g:GetTemplate()
        local firstUnit = g:GetUnit(1)
        local coord     = firstUnit and firstUnit:GetCoordinate()

        if coord then
            local sp = SPAWN:NewFromTemplate(tpl, grpName, nil, true)
            sp:InitSkill("Excellent")
            if not string.find(grpName, "Fixed") then
                sp:InitRandomizePosition(true, 75, 30):InitPositionCoordinate(coord)
            end
            sp:Spawn()
        else
           local SP2 = SPAWN:NewFromTemplate(tpl, grpName, nil, true)
			 if not string.find(grpName, "Fixed") then
                SP2:InitRandomizePosition(true, 75, 30)
			 end	
			SP2:Spawn()
        end
    else
        local tpl = UTILS.DeepCopy(_DATABASE.Templates.Groups[grpName].Template)
        SPAWN:NewFromTemplate(tpl, grpName, nil, true):InitSkill("Excellent"):Spawn()
    end
end

function RespawnGroup(grpName)
  local old=GROUP:FindByName(grpName)
  if not old then trigger.action.outText("Group "..tostring(grpName).." not found, please report it to Leka",30) end
  if old then old:Destroy() end
  local tpl=UTILS.DeepCopy(_DATABASE.Templates.Groups[grpName].Template)
  tpl.name=grpName
  return SPAWN:NewFromTemplate(tpl,grpName,nil,true):InitRadioCommsOnOff(false):Spawn()
end

GlobalSettings = {}
do
	GlobalSettings.blockedDespawnTime = 10*60 --used to despawn aircraft that are stuck taxiing for some reason
	GlobalSettings.landedDespawnTime = 1*60
	GlobalSettings.initialDelayVariance = 15 -- minutes
	
	GlobalSettings.messages = {
		grouplost = false,
		captured = true,
		upgraded = true,
		repaired = true,
		zonelost = true,
		disabled = true
	}
	
	GlobalSettings.urgentRespawnTimers = {
    dead = 35,
    hangar = 20,
    preparing = 5
	}
	
	GlobalSettings.defaultRespawns = {}
	GlobalSettings.defaultRespawns[1] = {
supply = { dead=30*60, hangar=15*60, preparing=5*60},
patrol = { dead=40*60, hangar=10*60, preparing=5*60},
attack = { dead=40*60, hangar=10*60, preparing=5*60},
escort = { dead=45*60, hangar=15*60, preparing=5*60}
	}
	
	GlobalSettings.defaultRespawns[2] = {
supply = { dead=35*60, hangar=20*60, preparing=5*60},
patrol = { dead=38*60, hangar=8*60, preparing=2*60},
attack = { dead=38*60, hangar=8*60, preparing=2*60},
escort = { dead=45*60, hangar=15*60, preparing=5*60}
	}
	
	GlobalSettings.respawnTimers = {}
	
	function GlobalSettings.resetDifficultyScaling()
		GlobalSettings.respawnTimers[1] = {
			supply = { 
				dead = GlobalSettings.defaultRespawns[1].supply.dead, 
				hangar = GlobalSettings.defaultRespawns[1].supply.hangar, 
				preparing = GlobalSettings.defaultRespawns[1].supply.preparing
			},
			patrol = { 
				dead = GlobalSettings.defaultRespawns[1].patrol.dead, 
				hangar = GlobalSettings.defaultRespawns[1].patrol.hangar, 
				preparing = GlobalSettings.defaultRespawns[1].patrol.preparing
			},
			attack = { 
				dead = GlobalSettings.defaultRespawns[1].attack.dead, 
				hangar = GlobalSettings.defaultRespawns[1].attack.hangar, 
				preparing = GlobalSettings.defaultRespawns[1].attack.preparing
			},
            escort = { 
				dead = GlobalSettings.defaultRespawns[1].escort.dead, 
				hangar = GlobalSettings.defaultRespawns[1].escort.hangar, 
				preparing = GlobalSettings.defaultRespawns[1].escort.preparing
			}
		}
		
		GlobalSettings.respawnTimers[2] = {
			supply = { 
				dead = GlobalSettings.defaultRespawns[2].supply.dead, 
				hangar = GlobalSettings.defaultRespawns[2].supply.hangar, 
				preparing = GlobalSettings.defaultRespawns[2].supply.preparing
			},
			patrol = { 
				dead = GlobalSettings.defaultRespawns[2].patrol.dead, 
				hangar = GlobalSettings.defaultRespawns[2].patrol.hangar, 
				preparing = GlobalSettings.defaultRespawns[2].patrol.preparing
			},
			attack = { 
				dead = GlobalSettings.defaultRespawns[2].attack.dead, 
				hangar = GlobalSettings.defaultRespawns[2].attack.hangar, 
				preparing = GlobalSettings.defaultRespawns[2].attack.preparing
			},
            escort = { 
                dead = GlobalSettings.defaultRespawns[2].escort.dead, 
                hangar = GlobalSettings.defaultRespawns[2].escort.hangar, 
                preparing = GlobalSettings.defaultRespawns[2].escort.preparing
            }
		}
	end
	
	function GlobalSettings.setDifficultyScaling(value, coalition)
		GlobalSettings.resetDifficultyScaling()
		for i,v in pairs(GlobalSettings.respawnTimers[coalition]) do
			for i2,v2 in pairs(v) do
				GlobalSettings.respawnTimers[coalition][i][i2] = math.floor(GlobalSettings.respawnTimers[coalition][i][i2] * value)
			end
		end
	end
	
	GlobalSettings.resetDifficultyScaling()
end

ejectedPilotOwners = {}
landedPilotOwners = {}

_globalArrowCounter = 1201
_activeArrowIds = {}

MissionTargets        = {}
MissionGroups         = {}
ScoreTargets          = {}
ActiveMission         = {}

function RegisterUnitTarget(uname,reward,stat,flagName)
    if flagName then
        MissionTargets[uname]={reward=reward,stat=stat,flag=flagName}
    else
        MissionTargets[uname]={reward=reward,stat=stat}
    end
end

function RegisterGroupTarget(groupName,reward,stat,flagName)
    local g = Group.getByName(groupName)
    if not g then return end
    local tab = {reward = reward, stat = stat, alive = {}, remaining = 0, killers = {}}
    if flagName then tab.flag = flagName end
    for _,u in ipairs(g:getUnits()) do
        local n = u:getName()
        tab.alive[n] = true
        tab.remaining = tab.remaining + 1
        MissionTargets[n] = {group = groupName}
        if flagName then MissionTargets[n].flag = flagName end
    end
    MissionGroups[groupName] = tab
    if flagName then flag = flagName end
end

function RegisterScoreTarget(flag,obj,reward,stat)
    local st = ScoreTargets[flag]
    if not st then
        st = {objects={},remaining=0,reward=reward,stat=stat}
        ScoreTargets[flag] = st
    end
    st.objects[#st.objects+1] = obj
    st.remaining = st.remaining + 1
end

BattleCommander = {}
do
	BattleCommander.zones = {}
	BattleCommander.indexedZones = {}
	BattleCommander.connections = {}
	BattleCommander.connectionssupply = {}
	BattleCommander.accounts = { [1]=0, [2]=0} -- 1 = red coalition, 2 = blue coalition
	BattleCommander.shops = {[1]={}, [2]={}}
	BattleCommander.shopItems = {}
	BattleCommander.monitorROE = {}
	BattleCommander.playerContributions = {[1]={}, [2]={}}
	BattleCommander.playerRewardsOn = false
	BattleCommander.rewards = {}
	BattleCommander.creditsCap = nil
	BattleCommander.difficultyModifier = 0
	BattleCommander.lastDiffChange = 0
	CustomFlags = CustomFlags or {}
	BattleCommander.groupSupportMenus = {}
	ZONE_DISTANCES = {}

	
	function BattleCommander:RemoveMenuForCoalition(coalition)
		missionCommands.removeItemForCoalition(coalition, {[1]='shop'})
	end
	function BattleCommander:refreshShopMenuForCoalition(coalition)
		missionCommands.removeItemForCoalition(coalition, {[1]='shop'})
		
		local shopmenu = missionCommands.addSubMenuForCoalition(coalition, 'shop')
		local sub1
		local count = 0
		
		local sorted = {}
		for i,v in pairs(self.shops[coalition]) do table.insert(sorted,{i,v}) end
		table.sort(sorted, function(a,b) return a[2].name < b[2].name end)
		
		for i2,v2 in pairs(sorted) do
			local i = v2[1]
			local v = v2[2]
			count = count +1
			if count<10 then
				missionCommands.addCommandForCoalition(coalition, '['..v.cost..'] '..v.name, shopmenu, self.buyShopItem, self, coalition, i)
			elseif count==10 then
				sub1 = missionCommands.addSubMenuForCoalition(coalition, "More", shopmenu)
				missionCommands.addCommandForCoalition(coalition, '['..v.cost..'] '..v.name, sub1, self.buyShopItem, self, coalition, i)
			elseif count%9==1 then
				sub1 = missionCommands.addSubMenuForCoalition(coalition, "More", sub1)
				missionCommands.addCommandForCoalition(coalition, '['..v.cost..'] '..v.name, sub1, self.buyShopItem, self, coalition, i)
			else
				missionCommands.addCommandForCoalition(coalition, '['..v.cost..'] '..v.name, sub1, self.buyShopItem, self, coalition, i)
			end
		end
	end

	function BattleCommander:refreshShopMenuForAllGroupsInCoalition(coal)
		local groups = coalition.getGroups(coal)
		if not groups then return end
		for _, g in pairs(groups) do
			if g and g:isExist() then
				self:refreshShopMenuForGroup(g:getID(), g)
			end
		end
	end
	
	function BattleCommander:new(savepath, updateFrequency, saveFrequency, difficulty) -- difficulty = {start = 1.4, min = -0.5, max = 0.5, escalation = 0.1, fade = 0.1, fadeTime = 30*60, coalition=1} --coalition 1:red 2:blue
		local obj = {}
		obj.saveFile = 'zoneCommander_moose-Custom_WWII.lua'
		if savepath then
			obj.saveFile = savepath
		end
		
		if not updateFrequency then updateFrequency = 10 end
		if not saveFrequency then saveFrequency = 60 end
		
		obj.difficulty = difficulty
		obj.updateFrequency = updateFrequency
		obj.saveFrequency = saveFrequency

		
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	
	--difficulty scaling
	
	function BattleCommander:increaseDifficulty()
		self.difficultyModifier = math.max(self.difficultyModifier-self.difficulty.escalation, self.difficulty.min)
		GlobalSettings.setDifficultyScaling(self.difficulty.start + self.difficultyModifier, self.difficulty.coalition)
		self.lastDiffChange = timer.getAbsTime()
		env.info('increasing diff: '..self.difficultyModifier)
	end
	
	function BattleCommander:decreaseDifficulty()
		self.difficultyModifier = math.min(self.difficultyModifier+self.difficulty.fade, self.difficulty.max)
		GlobalSettings.setDifficultyScaling(self.difficulty.start + self.difficultyModifier,self.difficulty.coalition)
		self.lastDiffChange = timer.getAbsTime()
		env.info('decreasing diff: '..self.difficultyModifier)
	end
	
	--end difficulty scaling
	
	-- shops and currency functions
	function BattleCommander:registerShopItem(id, name, cost, action, altAction)
		self.shopItems[id] = { name=name, cost=cost, action=action, altAction = altAction }
	end
	
	function BattleCommander:addShopItem(coalition, id, ammount)
		local item = self.shopItems[id]
		local sitem = self.shops[coalition][id]
		
		if item then
			if sitem then
				if ammount == -1 then
					sitem.stock = -1
				else
					sitem.stock = sitem.stock+ammount
				end
			else
				self.shops[coalition][id] = { name=item.name, cost=item.cost, stock=ammount }
				self:refreshShopMenuForAllGroupsInCoalition(coalition)
			end
		end
	end
	
	function BattleCommander:removeShopItem(coalition, id)
		self.shops[coalition][id] = nil
		--self:refreshShopMenuForCoalition(coalition)
	end
	
	function BattleCommander:addFunds(coalition, ammount)
		local newAmmount = math.max(self.accounts[coalition] + ammount,0)
		if self.creditsCap then
			newAmmount = math.min(newAmmount, self.creditsCap)
		end
		
		self.accounts[coalition] = newAmmount
	end
	
	function BattleCommander:printShopStatus(coalition)
		local text = 'Credits: '..self.accounts[coalition]
		if self.creditsCap then
			text = text..'/'..self.creditsCap
		end
		
		text = text..'\n'
		
		local sorted = {}
		for i,v in pairs(self.shops[coalition]) do table.insert(sorted,{i,v}) end
		table.sort(sorted, function(a,b) return a[2].name < b[2].name end)
		
		for i2,v2 in pairs(sorted) do
			local i = v2[1]
			local v = v2[2]
			text = text..'\n[Cost: '..v.cost..'] '..v.name
			if v.stock ~= -1 then
				text = text..' [Available: '..v.stock..']'
			end
		end
		
		if self.playerContributions[coalition] then
			for i,v in pairs(self.playerContributions[coalition]) do
				if v>0 then
					text = text..'\n\nUnclaimed credits'
					break
				end
			end
			
			for i,v in pairs(self.playerContributions[coalition]) do
				if v>0 then
					text = text..'\n '..i..' ['..v..']'
				end
			end
		end
		
		trigger.action.outTextForCoalition(coalition, text, 10)
	end
	
	function BattleCommander:buyShopItem(coalition, id, alternateParams, buyerGroupId, buyerGroupObj)

		if id == 'supplies' or id == 'supplies2' then
			local allUpgraded = true
			for _, zone in pairs(self:getZones()) do
				if zone.side == 2 then
					local upgradeCount = Utils.getTableSize(zone.built)
					local totalUpgrades = #zone.upgrades.blue
					if upgradeCount < totalUpgrades then
						allUpgraded = false
						break
					end
					for _, grpName in pairs(zone.built) do
						local gr = Group.getByName(grpName)
						if not gr or gr:getCoalition() ~= 2 or gr:getSize() < gr:getInitialSize() then
							allUpgraded = false
							break
						end
					end
				end
			end
			if allUpgraded then
				if buyerGroupId then
					trigger.action.outTextForGroup(buyerGroupId, "All zones are fully upgraded! No resupply is needed.", 10)
				else
					trigger.action.outTextForCoalition(coalition, "All zones are fully upgraded! No resupply is needed.", 10)
				end
				return
			end
		end

		if id == 'capture' then
			local foundAny = false
			for _, v in ipairs(self:getZones()) do
				if v.active and v.side == 0 and (not v.NeutralAtStart or v.firstCaptureByRed)
				   and not v.zone:lower():find("hidden")
				then
					foundAny = true
					break
				end
			end
			if not foundAny then
				if buyerGroupId then
					trigger.action.outTextForGroup(buyerGroupId, "No valid neutral zones found", 15)
				else
					trigger.action.outTextForCoalition(coalition, "No valid neutral zones found", 15)
				end
				return
			end
		end

		local item = self.shops[coalition][id]
		if not item then
			if buyerGroupId then
				trigger.action.outTextForGroup(buyerGroupId, "Item not found in shop", 5)
			else
				trigger.action.outTextForCoalition(coalition, "Item not found in shop", 5)
			end
			return
		end

		if self.accounts[coalition] < item.cost then
			if buyerGroupId then
				trigger.action.outTextForGroup(buyerGroupId, "Not enough credits for ["..item.name.."]", 5)
			else
				trigger.action.outTextForCoalition(coalition, "Can not afford ["..item.name.."]", 5)
			end
			return
		end

		if item.stock ~= -1 and item.stock <= 0 then
			if buyerGroupId then
				trigger.action.outTextForGroup(buyerGroupId, "["..item.name.."] out of stock", 5)
			else
				trigger.action.outTextForCoalition(coalition, "["..item.name.."] out of stock", 5)
			end
			return
		end

		local success = true
		local sitem = self.shopItems[id]
		if alternateParams ~= nil and type(sitem.altAction) == 'function' then
			success = sitem:altAction(alternateParams)
		elseif type(sitem.action) == 'function' then
			success = sitem:action()
		end

		if success == true or success == nil then
			self.accounts[coalition] = self.accounts[coalition] - item.cost
			if item.stock > 0 then
				item.stock = item.stock - 1
			end
			if item.stock == 0 then
				self.shops[coalition][id] = nil
			end

			if buyerGroupId then
				local buyerName = "Group " .. tostring(buyerGroupId)
				if self.playerNames and self.playerNames[buyerGroupId] then
					buyerName = self.playerNames[buyerGroupId]
				elseif buyerGroupObj and buyerGroupObj:isExist() then
					buyerName = buyerGroupObj:getName()
				end
				self:addStat(buyerName, "Points spent", item.cost)
				trigger.action.outTextForCoalition(
				  coalition,
				  buyerName.." bought:\n\n["..item.name.."] for "..item.cost.." credits.\n\n"..self.accounts[coalition].." credits remaining.",
				  20
				)
				if item.stock == 0 then
					trigger.action.outTextForCoalition(coalition, "["..item.name.."] went out of stock", 5)
				end
			else
				trigger.action.outTextForCoalition(
					coalition,
					"Bought ["..item.name.."] for "..item.cost.."\n"..
					self.accounts[coalition].." credits remaining",
					5
				)
				if item.stock == 0 then
					trigger.action.outTextForCoalition(coalition, "["..item.name.."] went out of stock", 5)
				end
			end

		else
			if type(success) == 'string' then
				if buyerGroupId then
					trigger.action.outTextForGroup(buyerGroupId, success, 5)
				else
					trigger.action.outTextForCoalition(coalition, success, 5)
				end
			else
				if buyerGroupId then
					trigger.action.outTextForGroup(buyerGroupId, 'Not available at the current time', 5)
				else
					trigger.action.outTextForCoalition(coalition, 'Not available at the current time', 5)
				end
			end
			return success
		end
	end


	function BattleCommander:refreshShopMenuForGroup(groupId, groupObj)
		if self.groupSupportMenus[groupId] then 
		missionCommands.removeItemForGroup(groupId, self.groupSupportMenus[groupId]); self.groupSupportMenus[groupId] = nil end
		if not groupObj or not groupObj:isExist() then return end
		local coalition = groupObj:getCoalition()
		local shopMenu = missionCommands.addSubMenuForGroup(groupId, "Support")
		self.groupSupportMenus[groupId] = shopMenu
		local shopData = self.shops[coalition]
		if not shopData then return end
		
		local sortedItems = {}
		for itemId, itemData in pairs(shopData) do table.insert(sortedItems, {id = itemId, data = itemData}) end
		table.sort(sortedItems, function(a, b) return a.data.name < b.data.name end)
		
		local count = 0
		local subMenu
		for _, itemInfo in ipairs(sortedItems) do
			count = count + 1
			local itemId = itemInfo.id
			local itemData = itemInfo.data
			local label = "[" .. itemData.cost .. "] " .. itemData.name
			if count < 10 then
				missionCommands.addCommandForGroup(groupId, label, shopMenu, self.buyShopItem, self, coalition, itemId, nil, groupId, groupObj)
			elseif count == 10 then
				subMenu = missionCommands.addSubMenuForGroup(groupId, "More", shopMenu)
				missionCommands.addCommandForGroup(groupId, label, subMenu, self.buyShopItem, self, coalition, itemId, nil, groupId, groupObj)
			elseif count % 9 == 1 then
				subMenu = missionCommands.addSubMenuForGroup(groupId, "More", subMenu)
				missionCommands.addCommandForGroup(groupId, label, subMenu, self.buyShopItem, self, coalition, itemId, nil, groupId, groupObj)
			else
				missionCommands.addCommandForGroup(groupId, label, subMenu, self.buyShopItem, self, coalition, itemId, nil, groupId, groupObj)
			end
		end
	end

	
	function BattleCommander:addMonitoredROE(groupname)
		table.insert(self.monitorROE, groupname)
	end
	
	function BattleCommander:checkROE(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local controller = gr:getController()
			if controller:hasTask() then
				controller:setOption(0, 2) -- roe = open fire
			else
				controller:setOption(0, 4) -- roe = weapon hold
			end
		end
	end


function BattleCommander:showTargetZoneMenu(coalition, menuname, action, targetzoneside, showUpgradeStatus,allow)
    local executeAction = function(act, params)
        local err = act(params.zone, params.menu) 
        if not err then
            if params.zone and not self:getZoneByName(params.zone).fullyUpgraded then
                missionCommands.removeItemForCoalition(params.coalition, params.menu)
            end
        end
    end

    local menu = missionCommands.addSubMenuForCoalition(coalition, menuname)
    local sub1
    local zones = bc:getZones()
    local count = 0
	
     local cand = {}
    for i, v in ipairs(zones) do
        if (not v.zone:lower():find("hidden")) and (targetzoneside == nil or v.side == targetzoneside) and (not allow or allow[v.zone]) then
            local suf   = WaypointList[v.zone]
            local wpNum = suf and tonumber(suf:match("%d+"))
            cand[#cand+1] = {z = v, wp = wpNum}
        end
    end
	table.sort(cand,function(a,b)
			if a.wp and b.wp       then return a.wp < b.wp end
			if a.wp                then return true        end
			if b.wp                then return false       end
			return a.z.zone < b.z.zone
	end)

    count = 0
    for _, wrap in ipairs(cand) do
        local v   = wrap.z
        local zoneDisplayName = wrap.wp and (v.zone .. WaypointList[v.zone]) or v.zone
        if showUpgradeStatus and v.side == 2 then
            local upgradeCount     = 0
            local totalUpgrades    = #v.upgrades.blue
            for _, builtUnit in pairs(v.built) do
                local gr = Group.getByName(builtUnit)
                if gr and gr:getCoalition() == 2 and gr:getSize() == gr:getInitialSize() then
                    upgradeCount = upgradeCount + 1
                end
            end
            zoneDisplayName = zoneDisplayName .. " " .. upgradeCount .. "/" .. totalUpgrades
        end

        count = count + 1
        if count < 10 then
            missionCommands.addCommandForCoalition(coalition, zoneDisplayName, menu, executeAction, action, {zone = v.zone, menu = menu, coalition = coalition})
        elseif count == 10 then
            sub1 = missionCommands.addSubMenuForCoalition(coalition, "More", menu)
            missionCommands.addCommandForCoalition(coalition, zoneDisplayName, sub1, executeAction, action, {zone = v.zone, menu = menu, coalition = coalition})
        elseif count % 9 == 1 then
            sub1 = missionCommands.addSubMenuForCoalition(coalition, "More", sub1)
            missionCommands.addCommandForCoalition(coalition, zoneDisplayName, sub1, executeAction, action, {zone = v.zone, menu = menu, coalition = coalition})
        else
            missionCommands.addCommandForCoalition(coalition, zoneDisplayName, sub1, executeAction, action, {zone = v.zone, menu = menu, coalition = coalition})
        end
    end

    return menu
end

	function BattleCommander:showEmergencyNeutralZoneMenu(coalition, menuname, callback)
	if not coalition then coalition = 2 end
		local menu = missionCommands.addSubMenuForCoalition(coalition, menuname)
		for _, v in ipairs(self.zones) do
			if v.active and v.side == 0 and (not v.NeutralAtStart or v.firstCaptureByRed)
			   and not v.zone:lower():find("hidden")
			then
				missionCommands.addCommandForCoalition(coalition, v.zone, menu, callback, v.zone)
			end
		end
		return menu
	end
	
	function findNearestAvailableSupplyCommander(chosenZone)
		local best=nil
		local bestDist=99999999
		local inProgressForZone=false
		for _,zC in ipairs(bc.zones) do
			if zC.side==2 and zC.active then
				for _,grpCmd in ipairs(zC.groups) do
					if grpCmd.mission=='supply' and grpCmd.side==2 then
						if grpCmd.targetzone==chosenZone.zone then
							local st=grpCmd.state
							if st=='takeoff' or st=='inair' or st=='landed' or st=='enroute' or st=='atdestination' then
								inProgressForZone=true
							elseif st=='dead' or st=='inhangar' or st=='preparing' then
								local znA = zC.zone
								local znB = chosenZone.zone
								local dist = ZONE_DISTANCES[znA] and ZONE_DISTANCES[znA][znB] or 99999999
								if dist<bestDist then
									bestDist=dist
									best=grpCmd
								end
							end
						end
					end
				end
			end
		end
		if not best and inProgressForZone then
			return nil,'inprogress'
		end
		return best,nil
	end


function measureDistanceZoneToZone(zoneA,zoneB)

	local czA=CustomZone:getByName(zoneA.zone)
	local czB=CustomZone:getByName(zoneB.zone)
	
	if not czA or not czB then return 99999 end
	
	return UTILS.VecDist2D({x=czA.point.x,y=czA.point.z},{x=czB.point.x,y=czB.point.z})
end

	function BattleCommander:getRandomSurfaceUnitInZone(tgtzone, myside)
		local zn = self:getZoneByName(tgtzone)
		
		local selectedUnit = nil
		
		local units = {}
		for _,v in pairs(zn.built) do
			local g = Group.getByName(v)
			if g and g:getCoalition() ~= myside then
				for _,unit in ipairs(g:getUnits()) do
					table.insert(units, unit)
				end
			end
		end
		
		for _,v in ipairs(zn.groups) do
			local g = Group.getByName(v.name)
			
			if g and v.type == 'surface' and v.side ~= myside then
				for _,unit in ipairs(g:getUnits()) do
					table.insert(units, unit)
				end
			end
		end
			
		if #units > 0 then
		 return units[math.random(1, #units)]
		end
	end
	
	function BattleCommander:moveToUnit(tgtunitname, groupname)
		timer.scheduleFunction(function(params, time)
			local group = Group.getByName(params.groupname)
			local unit = Unit.getByName(params.tgtunitname)
			
			if not group or not unit then return end -- do not recalculate route, either target or hunter stopped existing
			
			local pos = unit:getPoint()
			local cnt = group:getController()
			local task = {
				id = "Mission",
				params = {
					airborne = false,
					route = {
						points = {
							[1] = { 
								type=AI.Task.WaypointType.TURNING_POINT, 
								action=AI.Task.TurnMethod.FLY_OVER_POINT,
								speed = 100, 
								x = pos.x + math.random(-100,100), 
								y = pos.z + math.random(-100,100)
							}
						}
					}
				}
			}
			
			cnt:setTask(task)
			return time+50
		end, {tgtunitname = tgtunitname, groupname = groupname}, timer.getTime() + 2)
	end
	
	
	function BattleCommander:startHuntUnitsInZone(tgtzone, groupname)
		if not self.huntedunits then self.huntedunits = {} end
		
		timer.scheduleFunction(function(param, time)
			local group = Group.getByName(param.group)
			
			if not group then 
				param.context.huntedunits[param.group] = nil
				return -- group stopped existing, shut down the hunt
			end
			
			local huntedunit = param.context.huntedunits[param.group]
			if huntedunit and Unit.getByName(huntedunit) then return time+60 end -- hunted unit still exists, check again in a minute
		
			local tgtunit = param.context:getRandomSurfaceUnitInZone(param.zone, group:getCoalition())
			if tgtunit then
				param.context.huntedunits[param.group] = tgtunit:getName()
				param.context:moveToUnit(tgtunit:getName(), param.group)
				return time+120 -- new unit selected, check again in 2 minutes if we should select a new one
			else
				return time+600 -- no unit in zone, try again in 10 minutes
			end
					
		end, {context = self, zone = tgtzone, group = groupname}, timer.getTime()+2)
	end

	function BattleCommander:engageSead(tgtzone, groupname, expendAmmount, weapon)
		local zn = self:getZoneByName(tgtzone)
		local group = Group.getByName(groupname)
		if group and zn.side == group:getCoalition() then
			return 'Can not engage friendly zone'
		end
		if not group then
			return 'Not available'
		end
		local cnt=group:getController()
		cnt:popTask()
		local expCount = AI.Task.WeaponExpend.ALL
		if expendAmmount then
			expCount = expendAmmount
		end
		
		local wepType = Weapon.flag.AnyWeapon
		if weapon then
			wepType = weapon
		end
		for _,v in pairs(zn.built) do
			local g=Group.getByName(v)
			if g then
				for _,u in ipairs(g:getUnits()) do
					if u:hasAttribute('SAM SR') or u:hasAttribute('SAM TR') or u:hasAttribute('IR Guided SAM') then
						local task={
							id='AttackUnit',
							params={
								unitId=u:getID(),
								expend=expCount,
								weaponType=wepType,
								groupAttack=false
							}
						}
						cnt:pushTask(task)
					else
						local task={
							id='AttackGroup',
							params={
								groupId=g:getID(),
								expend=expCount,
								weaponType=wepType,
								groupAttack=false
							}
						}
						cnt:pushTask(task)
					end
				end
			end
		end
	end

	function BattleCommander:engageZone(tgtzone, groupname, expendAmmount, weapon)
		local zn = self:getZoneByName(tgtzone)
		local group = Group.getByName(groupname)
		
		if group and zn.side == group:getCoalition() then
			return 'Can not engage friendly zone'
		end
		
		if not group then
			return 'Not available'
		end
		
		local cnt = group:getController()
		cnt:popTask()
		
		local expCount = AI.Task.WeaponExpend.ONE
		if expendAmmount then
			expCount = expendAmmount
		end
		
		local wepType = Weapon.flag.AnyWeapon
		if weapon then
			wepType = weapon
		end
		
		-- Build up a table of tasks we want to perform.
		local tasks = {}
		for _, v in pairs(zn.built) do
			local g = Group.getByName(v)
			if g then
				table.insert(tasks, {
					id = 'AttackGroup',
					params = {
						groupId     = g:getID(),
						expend      = expCount,
						weaponType  = wepType,
						groupAttack = false
					}
				})
			end
			
			local s = StaticObject.getByName(v)
			if s then
				table.insert(tasks, {
					id = 'AttackUnit',
					params = {
						unitId      = s:getID(),
						expend      = expCount,
						weaponType  = wepType,
						groupAttack = false
					}
				})
			end
		end
		if #tasks > 0 then
			local comboTask = {
				id = 'ComboTask',
				params = {
					tasks = tasks
				}
			}
			cnt:pushTask(comboTask)
		end
	end

	function BattleCommander:carpetBombRandomUnitInZone(tgtzone, groupname)
		local zn = self:getZoneByName(tgtzone)
		local group = Group.getByName(groupname)
		
		if group and zn.side == group:getCoalition() then
			return 'Can not engage friendly zone'
		end
		
		if not group then
			return 'Not available'
		end
		
		local cnt=group:getController()
		cnt:popTask()
		local viabletgts = {}
		for i,v in pairs(zn.built) do
			local g = Group.getByName(v)
			if g then
				for i2,v2 in ipairs(g:getUnits()) do
					table.insert(viabletgts, v2)
				end
			else
				local s = StaticObject.getByName(v)
				if s then
					table.insert(viabletgts,s)
				end
			end
		end
		
		local choice = viabletgts[math.random(1,#viabletgts)]
		local p = choice:getPoint()
		local task = { 
		  id = 'CarpetBombing', 
		  params = { 
			attackType = 'Carpet',
			carpetLength = 1000,
			expend = AI.Task.WeaponExpend.ALL,
			weaponType = Weapon.flag.AnyUnguidedBomb,
			groupAttack = true,
			attackQty = 1,
			altitudeEnabled = true,
			altitude = 7000,
			point = {x=p.x, y=p.z}
		  } 
		}
		cnt:pushTask(task)
	end
	
	function BattleCommander:jamRadarsAtZone(groupname, zonename)
		local gr = Group.getByName(groupname)
		local zn = self:getZoneByName(zonename)
		if not gr then return 'EW group dead' end
		if not zn then return 'Zone not found' end
		if zn.side == gr:getCoalition() then return 'Can not jam friendly zone' end
		
		timer.scheduleFunction(function (param, time)
			local gr = Group.getByName(param.ewgroup)
			local zn = param.context:getZoneByName(param.target)
			if not Utils.isGroupActive(gr) or zn.side == gr:getCoalition() then
				for i,v in pairs(zn.built) do
					local g = Group.getByName(v)
					if g then
						for i2,v2 in ipairs(g:getUnits()) do
							if v2:hasAttribute('SAM SR') or v2:hasAttribute('SAM TR') then
								v2:getController():setOption(0,2)
								v2:getController():setOption(9,2)
							end
						end
					end
				end
				return nil
			else
				for i,v in pairs(zn.built) do
					local g = Group.getByName(v)
					if g then
						for i2,v2 in ipairs(g:getUnits()) do
							if v2:hasAttribute('SAM SR') or v2:hasAttribute('SAM TR') then
								v2:getController():setOption(0,4)
								v2:getController():setOption(9,1)
							end
						end
					end
				end
			end
			
			return time+10
		end, {ewgroup = groupname, target = zonename, context = self}, timer.getTime()+10)
	end
	
	function BattleCommander:startFiringAtZone(groupname, zonename, minutes)
		timer.scheduleFunction(function(param, time)
			local gr = Group.getByName(param.group)
			local abu = param.context:getZoneByName(param.zone)
			
			if not abu or abu.side ~= 2 then return nil end
			if not gr then return nil end
			
			param.context:fireAtZone(abu.zone, param.group, true, 1, 50)
			return time+(param.period*60)
			
		end, {group = groupname, zone = zonename, context=self, period = minutes}, timer.getTime()+5)
	end
	
	function BattleCommander:fireAtZone(tgtzone, groupname, precise, ammount, ammountPerTarget)
		local zn = self:getZoneByName(tgtzone)
		local launchers = Group.getByName(groupname)
		
		if launchers and zn.side == launchers:getCoalition() then
			return 'Can not launch attack on friendly zone'
		end
		
		if not launchers then
			return 'Not available'
		end
		
		if ammountPerTarget==nil then
			ammountPerTarget = 1
		end
		
		if precise then
			local units = {}
			for i,v in pairs(zn.built) do
				local g = Group.getByName(v)
				if g then
					for i2,v2 in ipairs(g:getUnits()) do
						table.insert(units, v2)
					end
				else
					local s = StaticObject.getByName(v)
					if s then
						table.insert(units, s)
					end
				end
			end
			
			if #units == 0 then
				return 'No targets found within zone'
			end
			
			local selected = {}
			for i=1,ammount,1 do
				if #units == 0 then 
					break
				end
				
				local tgt = math.random(1,#units)
				
				table.insert(selected, units[tgt])
				table.remove(units, tgt)
			end
			
			while #selected < ammount do
				local ind = math.random(1,#selected)
				table.insert(selected, selected[ind])
			end
			
			for i,v in ipairs(selected) do
				local unt = v
				if unt then
					local target = {}
					target.x = unt:getPosition().p.x
					target.y = unt:getPosition().p.z
					target.radius = 100
					target.expendQty = ammountPerTarget
					target.expendQtyEnabled = true
					local fire = {id = 'FireAtPoint', params = target}
					
					launchers:getController():pushTask(fire)
				end
			end
		else
			local tz = CustomZone:getByName(zn.zone)
			local target = {}
			target.x = tz.point.x
			target.y = tz.point.y
			target.radius = tz.radius
			target.expendQty = ammount
			target.expendQtyEnabled = true
			local fire = {id = 'FireAtPoint', params = target}
			
			local launchers = Group.getByName(groupname)
			launchers:getController():pushTask(fire)
		end
	end
	
function BattleCommander:getStateTable()
    local states = {zones = {}, accounts = {}}
    
    for i, v in ipairs(self.zones) do
        
        local unitTable = {}
        for i2, v2 in pairs(v.built) do
            unitTable[i2] = {}
            local gr = Group.getByName(v2)
            if gr then
                for i3, v3 in ipairs(gr:getUnits()) do
                    local desc = v3:getDesc()
                    table.insert(unitTable[i2], desc['typeName'])
                end
            end
        end
        
        if v.wasBlue then
            v.firstCaptureByRed = true
        end


        if v.side == 1 or v.side == 2 or not v.active then
            v.firstCaptureByRed = true
        end

        states.zones[v.zone] = { 
            side = v.side, 
            level = Utils.getTableSize(v.built), 
            remainingUnits = unitTable, 
            destroyed = v:getDestroyedCriticalObjects(), 
            active = v.active, 
            triggers = {}, 
            wasBlue = v.wasBlue or false, 
            firstCaptureByRed = v.firstCaptureByRed or false
        }


        for i2, v2 in ipairs(v.triggers) do
            if v2.id then
                states.zones[v.zone].triggers[v2.id] = v2.hasRun
            end
        end
        

        if v.triggers['FriendlyDestroyed'] then
            states.zones[v.zone].triggers['FriendlyDestroyed'] = true
        end
    end
    
    states.accounts = self.accounts
    states.shops = self.shops
    states.difficultyModifier = self.difficultyModifier
    states.playerStats = {}
    

    if self.playerStats then
        for i, v in pairs(self.playerStats) do
            local sanitized = i:gsub("\\", "\\\\")
            sanitized = sanitized:gsub("'", "\\'")
            states.playerStats[sanitized] = v
        end
    end
    
    return states
end
	
	function BattleCommander:getZoneOfUnit(unitname)
		local un = Unit.getByName(unitname)
		
		if not un then 
			return nil
		end
		
		for i,v in ipairs(self.zones) do
			if Utils.isInZone(un, v.zone) then
				return v
			end
		end
		
		return nil
	end
	function BattleCommander:getZoneOfGroup(groupName)
		local gr = Group.getByName(groupName)
		if gr and gr:isExist() then
			local unit = gr:getUnit(1)
			if unit then
				local point = unit:getPoint()
				for i,v in ipairs(self.zones) do
					if Utils.isInZone(unit, v.zone) then
						return v
					end
				end
			end
		end
		return nil
	end
	function BattleCommander:getZoneOfWeapon(weapon)
		if not weapon then 
			return nil
		end
		
		for i,v in ipairs(self.zones) do
			if Utils.isInZone(weapon, v.zone) then
				return v
			end
		end
		
		return nil
	end
	
	function BattleCommander:getZoneOfPoint(point)
		for i,v in ipairs(self.zones) do
			local z = CustomZone:getByName(v.zone)
			if z and z:isInside(point) then
				return v
			end
		end
		
		return nil
	end
	
	function BattleCommander:addZone(zone)
		table.insert(self.zones, zone)
		zone.index = self:getZoneIndexByName(zone.zone)+3000
		zone.battleCommander = self
		self.indexedZones[zone.zone] = zone
	end
	
	function BattleCommander:getZoneByName(name)
		return self.indexedZones[name]
	end
	
	function BattleCommander:addConnection(f, t)
		table.insert(self.connections, {from=f, to=t})
	end

function BattleCommander:addConnectionSupply(f, t, supplyMethod)
table.insert(self.connectionssupply, {from=f, to=t, method=supplyMethod or 'default'})
end
	
	function BattleCommander:getZoneIndexByName(name)
		for i,v in ipairs(self.zones) do
			if v.zone == name then
				return i
			end
		end
	end
	
	function BattleCommander:getZones()
		return self.zones
	end
	
	function BattleCommander:initializeRestrictedGroups()
		for i,v in pairs(_DATABASE.Templates.Groups) do
			local t=v.Template
			if t.units[1].skill=='Client' then
				for i2,v2 in ipairs(self.zones) do
					local zn=CustomZone:getByName(v2.zone)
					local pos3d={x=t.units[1].x,y=0,z=t.units[1].y}
					if zn and zn:isInside(pos3d) then
						local coa=0
						if t.CoalitionID==coalition.side.BLUE then
							coa=2
						elseif t.CoalitionID==coalition.side.RED then
							coa=1
						end
						v2:addRestrictedPlayerGroup({name=t.name,side=coa})
					end
				end
			end
		end
	end

	function shuffleTable(tbl)
		for i = #tbl, 2, -1 do
			local j = math.random(1, i)
			tbl[i], tbl[j] = tbl[j], tbl[i]
		end
	end

	local function ground_buildWP(pt, form, spd)
		return {
			x      = pt.x,
			y      = pt.z or pt.y,                -- DCS route uses “y” for ground
			type   = "Turning Point",
			action = (form=="On Road"  or form=="on_road")  and "On Road"
				  or (form=="Off Road" or form=="off_road") and "Off Road"
				  or form or "Off Road",
			speed  = (spd or 20) / 3.6            -- m/s, default 20 km/h
		}
	end


	local getRoadPt = land.getClosestPointOnRoads
	local function isRoadClose(pt,limit)
		local rx,rz = getRoadPt('roads',pt.x,pt.z)
		if not rx then return false end
		local dx, dz = pt.x-rx, pt.z-rz
		return dx*dx + dz*dz <= (limit or 1000)^2
	end

	SUBZONE_NEAR_ROAD = {}
	ZONE_VALID_SUBZONES = {}
	function buildSubZoneRoadCache()
		for _, zone in ipairs(bc.zones) do
			local zn = zone.zone
			ZONE_VALID_SUBZONES[zn] = {}
			local j = 1
			while true do
				local subName = zn .. "-" .. j
				local subZone = trigger.misc.getZone(subName)
				if not subZone then break end
				local p      = subZone.point
				local px,pz  = p.x,p.z
				local roadClose = isRoadClose(p,1000)
				SUBZONE_NEAR_ROAD[subName] = roadClose and true or false
				if roadClose then
					local st = land.getSurfaceType({x=px,y=pz})
					if st == 1 or st == 4 then
						table.insert(ZONE_VALID_SUBZONES[zn], subName)
					end
				end
				j = j + 1
			end
		end
	end
		ZONE_CONNECTED_TO_BLUE = {}
		ZONE_CONNECTED_TO_RED  = {}
		ZONE_CONNECTED_BLUE_COUNT = {}
	function BattleCommander:buildConnectionMap()
		ZONE_CONNECTED_TO_BLUE = {}
		ZONE_CONNECTED_TO_RED  = {}
		ZONE_CONNECTED_BLUE_COUNT = {}
		self.connectionMap = {}
		for _, c in ipairs(self.connections or {}) do
			local from = c.from
			local to = c.to
			self.connectionMap[from] = self.connectionMap[from] or {}
			self.connectionMap[to]   = self.connectionMap[to]   or {}
			self.connectionMap[from][to] = true
			self.connectionMap[to][from] = true
			local fromZone = self:getZoneByName(from)
			local toZone   = self:getZoneByName(to)
			if fromZone and toZone then
				if fromZone.side == 2 then
					ZONE_CONNECTED_TO_BLUE[to] = true
					ZONE_CONNECTED_BLUE_COUNT[to] = (ZONE_CONNECTED_BLUE_COUNT[to] or 0) + 1
				end
				if toZone.side == 2 then
					ZONE_CONNECTED_TO_BLUE[from] = true
					ZONE_CONNECTED_BLUE_COUNT[from] = (ZONE_CONNECTED_BLUE_COUNT[from] or 0) + 1
				end
			end
		end
		ZONE_NEAR_BLUE = {}
		for _, zoneObj in ipairs(self.zones) do
			local znA = zoneObj.zone
			if zoneObj.side == 1 then
				local best = math.huge
				for _, zB in ipairs(self.zones) do
					if zB.side == 2 then
						local znB = zB.zone
						local d = ZONE_DISTANCES[znA] and ZONE_DISTANCES[znA][znB]
						if d and d < best then best = d end
					end
				end
				if best <= 50*1852 then ZONE_NEAR_BLUE[znA] = true end
			end
		end
	end

	function BattleCommander:buildConnectionSupplyMap()
		ZONE_CONNECTED_TO_BLUE = {}
		ZONE_CONNECTED_TO_RED  = {}
		ZONE_CONNECTED_BLUE_COUNT = {}
		self.connectionsupplyMap = {}
		for _, c in ipairs(self.connectionssupply or {}) do
			local from = c.from
			local to = c.to
			self.connectionsupplyMap[from] = self.connectionsupplyMap[from] or {}
			self.connectionsupplyMap[to]   = self.connectionsupplyMap[to]   or {}
			self.connectionsupplyMap[from][to] = true
			self.connectionsupplyMap[to][from] = true
			local fromZone = self:getZoneByName(from)
			local toZone   = self:getZoneByName(to)
			if fromZone and toZone then
				if fromZone.side == 2 then
					ZONE_CONNECTED_TO_BLUE[to] = true
					ZONE_CONNECTED_BLUE_COUNT[to] = (ZONE_CONNECTED_BLUE_COUNT[to] or 0) + 1
				end
				if toZone.side == 2 then
					ZONE_CONNECTED_TO_BLUE[from] = true
					ZONE_CONNECTED_BLUE_COUNT[from] = (ZONE_CONNECTED_BLUE_COUNT[from] or 0) + 1
				end
			end
		end
		ZONE_NEAR_BLUE = {}
		for _, zoneObj in ipairs(self.zones) do
			local znA = zoneObj.zone
			if zoneObj.side == 1 then
				local best = math.huge
				for _, zB in ipairs(self.zones) do
					if zB.side == 2 then
						local znB = zB.zone
						local d = ZONE_DISTANCES[znA] and ZONE_DISTANCES[znA][znB]
						if d and d < best then best = d end
					end
				end
				if best <= 50*1852 then ZONE_NEAR_BLUE[znA] = true end
			end
		end
	end

	function BattleCommander:buildZoneDistanceCache()
		for i = 1, #self.zones do
			local zoneA  = self.zones[i]
			local znA    = zoneA.zone
			ZONE_DISTANCES[znA] = ZONE_DISTANCES[znA] or {}
			for j = i, #self.zones do
				local zoneB = self.zones[j]
				local znB   = zoneB.zone
				local dist  = (i == j) and 0 or measureDistanceZoneToZone(zoneA, zoneB)
				ZONE_DISTANCES[znA][znB] = dist
				ZONE_DISTANCES[znB] = ZONE_DISTANCES[znB] or {}
				ZONE_DISTANCES[znB][znA] = dist
			end
		end
	end
	GROUP_ZONE_CACHE = {}
	ZONE_FRIENDLY_CACHE = {}
	function BattleCommander:roamGroupsToLocalSubZone(prefix, distanceNm,skip)
		local formations = {"Off Road","On Road","Cone","Diamond","Vee"}  
		local formationsTall = {"Off Road","Cone","Vee"}
		
		local liveSets={}
		if type(prefix)=="table" then
			for _,p in ipairs(prefix) do liveSets[p]=SET_GROUP:New():FilterPrefixes(p):FilterStart() end
		else
			liveSets[prefix]=SET_GROUP:New():FilterPrefixes(prefix):FilterStart()
		end

		local SkipZones = {}
		if type(skip)=="table" then
			for _,zn in pairs(skip) do SkipZones[zn]=true end
		end

		local currentZoneData
		local zonePtr = 1
		local rangeMeters = (distanceNm or 50)*1852
		local function isNearFriendlyZone(currentZone, rangeMeters)
			for _, testZone in ipairs(self.zones) do
				if testZone.side == 2 then
					local dist = ZONE_DISTANCES[currentZone.zone] and ZONE_DISTANCES[currentZone.zone][testZone.zone]
					if dist and dist <= rangeMeters then
						return true
					end
				end
			end
			return false
		end
	
		-- Finds how close a zone is to ANY friendly zone
		local function getCachedZoneDistanceToFriendly(self, zoneObj)
			local best = math.huge
			local znA = zoneObj.zone
			for _, zB in ipairs(self.zones) do
				if zB.side == 2 then
					local znB = zB.zone
					local d = ZONE_DISTANCES[znA] and ZONE_DISTANCES[znA][znB]
					if d and d < best then
						best = d
					end
				end
			end
			return best
		end

		local function collectGroups(prefixList,rangeMeters)
			local zoneGroups={}
			
			
			local function scanPrefix(thisPrefix)
					local set=liveSets[thisPrefix];if not set then return end
					set:ForEachGroup(function(PrefixGroups)
					local gName=PrefixGroups:GetName()
					local gr=Group.getByName(gName)
					if gr and gr:isExist() and gr:getSize()>0 then
						local pForms=(gr:getSize()>4) and formationsTall or formations
						local z = GROUP_ZONE_CACHE[gName]
						if not z then
							z = self:getZoneOfGroup(gName)
							if z then GROUP_ZONE_CACHE[gName] = z end
						end
						if z and not SkipZones[z.zone] then
							local zn=z.zone
							local zoneIsNear=ZONE_FRIENDLY_CACHE[zn]
							if zoneIsNear==nil then
								zoneIsNear = ZONE_CONNECTED_TO_BLUE[zn] or ZONE_NEAR_BLUE[zn] or false
								local count=ZONE_CONNECTED_BLUE_COUNT[zn] or 0
								if not zoneIsNear and count<3 then
									zoneIsNear=isNearFriendlyZone(z,rangeMeters)
								end
								ZONE_FRIENDLY_CACHE[zn] = zoneIsNear
							end
							if zoneIsNear then
								zoneGroups[zn]=zoneGroups[zn] or{}
								zoneGroups[zn][#zoneGroups[zn]+1]={gName=gName,ctrl=gr:getController(),formations=pForms}
							end
						end
					end
				end)
			end
			if type(prefixList)=="table" then
				for _,pfx in ipairs(prefixList) do scanPrefix(pfx) end
			else
				scanPrefix(prefixList)
			end
			return zoneGroups
		end
	
		local function buildCycleData()
			local zoneGroups = collectGroups(prefix,rangeMeters)
			local list = {}
			for zoneName,groupList in pairs(zoneGroups) do
				if not SkipZones[zoneName] then
					local zoneObj = self:getZoneByName(zoneName)
					if zoneObj then
						local d = getCachedZoneDistanceToFriendly(self, zoneObj)
						list[#list+1] = {zoneName=zoneName,groups=groupList,distance=d}
					end
				end
			end
			table.sort(list,function(a,b)return a.distance<b.distance end)
			local connected,other={},{}
			for _,it in ipairs(list) do
				if (ZONE_CONNECTED_BLUE_COUNT[it.zoneName] or 0)>0 then
					connected[#connected+1]=it
				else
					other[#other+1]=it
				end
			end
			local new={}
			for i=1,math.min(2,#connected) do new[#new+1]=connected[i] end
			for i=1,#other do new[#new+1]=other[i] end
			for i=3,#connected do new[#new+1]=connected[i] end
			currentZoneData = new
		end

		local function innerRoam()
			if not currentZoneData or zonePtr>#currentZoneData then return nil end
			local offset = 0
			local scheduledCount = 0


			local maxZonesToMove = 3
			local zoneCounter = 0
			while zonePtr<=#currentZoneData do
                local zData = currentZoneData[zonePtr]
                zonePtr = zonePtr + 1
				local zoneName = zData.zoneName
			  if not SkipZones[zoneName] then
                zoneCounter = zoneCounter + 1
				if zoneCounter > maxZonesToMove then
					break
				end
			  end
                local groupList = zData.groups
                local cz        = CustomZone:getByName(zoneName)
                if cz then
					cz.usedSpawnZones = cz.usedSpawnZones or {}
                    local totalGroups = #groupList
                    local moveCount   = math.random(1, math.min(3, totalGroups))
                    shuffleTable(groupList)
                    local chosenThisPass = {}
					for i = 1, moveCount do
						local gData   = groupList[i]
						local pick    = nil
						local cand    = cz:getRandomUnusedSpawnZone(false)
						if not cand then
							cand = cz:getRandomSpawnZone()
							if cand and USED_SUB_ZONES[cand] then cand = nil end
						end
						if not cand then
							cand = cz:getRandomSpawnZone()
						end
						if cand and not chosenThisPass[cand] then
							pick                          = cand
						end
						if not pick then
							local subZones = {}
							for j = 1, 100 do
								local sub = zoneName.."-"..j
								if not trigger.misc.getZone(sub) then break end
								if not chosenThisPass[sub] then
									subZones[#subZones+1] = sub
								end
							end
							if #subZones > 0 then
								pick = subZones[math.random(1,#subZones)]
							end
						end
					if pick then
						local grp2 = Group.getByName(gData.gName)
						if grp2 and grp2:isExist() and not (underAttack and underAttack[grp2:getID()]) then
							local p0 = grp2:getUnit(1):getPoint()
							local z = trigger.misc.getZone(pick)
							if z then
								local dest = {x = z.point.x, y = z.point.y, z = z.point.z}
								local directD = ((p0.x - dest.x)^2 + (p0.z - dest.z)^2)^0.5

								chosenThisPass[pick] = true
								USED_SUB_ZONES[pick] = true
								local hopMax = math.min(1000, directD * 0.8)
								local nearDestRoad = SUBZONE_NEAR_ROAD[pick] or false
								local nearStartRoad = isRoadClose(p0, hopMax * 1.5)
								local tripLong = directD > 700
								local useRd = (nearStartRoad or nearDestRoad) and tripLong
										local candForms = {}
										for _, f in ipairs(gData.formations) do
											if useRd or f ~= "On Road" then
												candForms[#candForms + 1] = f
											end
										end
										if #candForms == 0 then
											candForms[1] = "Off Road"
										end
										local form      = useRd and "On Road" or candForms[math.random(1, #candForms)]
										--local DispTimer = math.random(60, 300)
										local spd       = math.random(30, 60)
									
									local function moveGroup(gpName, zoneSub, formations, s, theCtrl)
										local grp2=Group.getByName(gpName);if(not grp2)or(not grp2:isExist())or(grp2:getSize()<1)then return end
										local vel=grp2:getUnit(1):getVelocity()or{x=0,y=0,z=0}
										if UTILS.VecNorm(vel)<1 then
											local p0=grp2:getUnit(1):getPoint()
											local subz=nil
											local main=bc:getZoneOfPoint(p0)
											if main then
												for _,cand in ipairs(ZONE_VALID_SUBZONES[main.zone] or{})do
													local cz=CustomZone:getByName(cand)
													if cz and cz:isInside(p0)then subz=cand break end
												end
											end
											env.info("[TEST] "..gpName.." in "..tostring(subz or"no-subzone"))
											local z=trigger.misc.getZone(zoneSub);if not z then return end
											local dest={x=z.point.x,y=z.point.y,z=z.point.z}
											local directD=((p0.x-dest.x)^2+(p0.z-dest.z)^2)^0.5
											if directD>3*1852 then return end
											local tripLong=directD>500
											local nearStartRoad
											if subz then nearStartRoad=SUBZONE_NEAR_ROAD[subz] else nearStartRoad=isRoadClose(p0,math.min(1000,directD*0.8)*1.5) end
											local nearDestRoad=SUBZONE_NEAR_ROAD[zoneSub]or false
											local useRd=(nearStartRoad or nearDestRoad)and tripLong
											local path=nil
											local key=nil
											if useRd then
												local key=math.floor(p0.x/100)..':'..math.floor(p0.z/100)..':'..math.floor(dest.x/100)..':'..math.floor(dest.z/100)
												path=PATH_CACHE[key]
												if not path then
													path=land.findPathOnRoads("roads",p0.x,p0.z,dest.x,dest.z) PATH_CACHE[key]=path
												end
												if directD>1000 then
													if path and#path>0 then
														local rd,prev=0,{x=p0.x,y=p0.z}
														for _,pt in ipairs(path)do pt.z=pt.z or pt.y;rd=rd+UTILS.VecDist2D(prev,{x=pt.x,y=pt.z});if rd>directD*2.0 then useRd=false break end;prev={x=pt.x,y=pt.z} end
													else useRd=false end
												end
											end
											local formation
											if useRd then formation="On Road" else repeat formation=formations[math.random(1,#formations)] until formation~="On Road" end
											env.info("[DEBUG roamGroupsToLocalSubZone] Sending "..gpName.." -> "..zoneSub.." formation="..formation.." speed="..s)
											if not useRd then GROUP:FindByName(gpName):RouteGroundTo(COORDINATE:New(dest.x,0,dest.z),s,formation,1) return end

											theCtrl:popTask()
											local wp1=ground_buildWP(p0,"on_road",s)
											local exitPt=dest
											if path and#path>0 then
												local roadSoFar,prev=0,{x=p0.x,y=p0.z}
												for _,pt in ipairs(path)do pt.z=pt.z or pt.y;local pt2={x=pt.x,y=pt.z};roadSoFar=roadSoFar+UTILS.VecDist2D(prev,pt2);pt._roadDist=roadSoFar;prev=pt2 end
												local offMax=math.min(700,directD*0.8)
												local gainMin=math.max(500,directD*0.5)
												for i=#path,1,-1 do local pt=path[i];local off=UTILS.VecDist2D({x=pt.x,y=pt.z},{x=dest.x,y=dest.z});local gain=directD-(pt._roadDist+off);if off<=offMax and gain>=gainMin then exitPt=pt break end end
												local roadLen=exitPt._roadDist or roadSoFar
												if roadLen>directD*2.0 and(roadLen-directD)>2.0*1852 then exitPt=dest end
											end
											local wp2=ground_buildWP(exitPt,"on_road",s)
											local wp3=ground_buildWP(dest,"Off Road",s)
											theCtrl:setTask({id="Mission",params={route={points={wp1,wp2,wp3}}}})
											if key then PATH_CACHE[key]=nil end
										end
									end

									if zoneCounter % 3 == 0 then
										offset = offset+math.random(300,900)
									end
										
									offset = offset + math.random(60,120)
									--env.info("[DEBUG roamGroupsToLocalSubZone] Scheduling "..gData.gName.." -> "..pick.." formation="..form.." speed="..spd)
									SCHEDULER:New(nil, moveGroup, {gData.gName, pick, gData.formations, spd, gData.ctrl}, offset)
									scheduledCount = scheduledCount + 1
								end
							end
						end
					end
				end
			end
	
			local nextRun = timer.getTime()+offset+10
			return nextRun
		end
	
		local nextBigTime
		local function innerLoop()
			local nxt=innerRoam()
			if nxt and nxt<nextBigTime-1 then SCHEDULER:New(nil,innerLoop,{},nxt-timer.getTime(),0) end
		end
		local function bigLoop()
			USED_SUB_ZONES={}
			buildCycleData()
			nextBigTime=timer.getTime()+math.random(900,2400)
			SCHEDULER:New(nil,bigLoop,{},nextBigTime - timer.getTime(),0)
			innerLoop()
		end
		SCHEDULER:New(nil,bigLoop,{},math.random(10,30),0)
	end
	function forceMissionComplete()
		if not missionCompleted then
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

	function BattleCommander:startMonitorPlayerMarkers()
		markEditedEvent = {}
		markEditedEvent.context = self
		function markEditedEvent:onEvent(event)
			if event.id == 26 and event.text and (event.coalition == 1 or event.coalition == 2) then -- mark changed
				local success = false
				
				if event.text=='help' then
					local toprint = 'Available Commands:'
					toprint = toprint..'\nbuy - display available support items'
					toprint = toprint..'\nbuy:item - buy support item'
					toprint = toprint..'\nstatus - display zone status for 60 seconds'
					toprint = toprint..'\nstats - display complete leaderboard'
					toprint = toprint..'\ntop - display top 5 players from leaderboard'
					toprint = toprint..'\nmystats - display your personal statistics (only in MP)'
					toprint = toprint..'\nmissions display all the active missions'
					
					if event.initiator then
						trigger.action.outTextForGroup(event.initiator:getGroup():getID(), toprint, 20)
					else
						trigger.action.outTextForCoalition(event.coalition, toprint, 20)
					end
					
					success = true
				end
				if event.text=='debughelp' then
					local toprint = 'Available Commands:'
					toprint = toprint..'\nspawn - Spawns the stuff in that zone where the marker was used if the spawn is valid.'
					toprint = toprint..'\nrensa - clears out a zone of units.'
					toprint = toprint..'\nintelstatus - force to display status message all though without intel bought.'
					toprint = toprint..'\ncapture: - capture:2 or capture:1. can be used to capture a neutral zone'
					toprint = toprint..'\nmaxxa - upgrades a zone to the max, current coalition.'
					toprint = toprint..'\nevent - shows in the log the events that is in the script'
					toprint = toprint..'\nevent: will start the event if the canexecute is true. event:eventID'
					toprint = toprint..'\naddfunds: - addfunds:1000 - adds 1000 credits to the blue coalition.'
					toprint = toprint..'\ndebug:  - shows the status of the zone in the log.'
					toprint = toprint..'\naddshop: - Add shop for the coalition and can be used from f10.'
					toprint = toprint..'\nremoveshop: - remove shop for the coalition.'
					

					
					if event.initiator then
						trigger.action.outTextForGroup(event.initiator:getGroup():getID(), toprint, 30)
					else
						trigger.action.outTextForCoalition(event.coalition, toprint, 30)
					end
					
					success = true
				end
				
				if event.text:find('^buy') then
					if event.text == 'buy' then
						local toprint = 'Credits: '..self.context.accounts[event.coalition]
						if self.context.creditsCap then
							toprint = toprint..'/'..self.context.creditsCap
						end
						
						toprint = toprint..'\n'
						local sorted = {}
						for i,v in pairs(self.context.shops[event.coalition]) do table.insert(sorted,{i,v}) end
						table.sort(sorted, function(a,b) return a[2].name < b[2].name end)
						
						for i2,v2 in pairs(sorted) do
							local i = v2[1]
							local v = v2[2]
							toprint = toprint..'\n[Cost: '..v.cost..'] '..v.name..'   buy:'..i
							if v.stock ~= -1 then
								toprint = toprint..' [Available: '..v.stock..']'
							end
						end
						
						if event.initiator then
							trigger.action.outTextForGroup(event.initiator:getGroup():getID(), toprint, 20)
						else
							trigger.action.outTextForCoalition(event.coalition, toprint, 20)
						end
						
						success = true
					elseif event.text:find('^buy\:') then
						local item = event.text:gsub('^buy\:', '')
						local zn = self.context:getZoneOfPoint(event.pos)
						self.context:buyShopItem(event.coalition,item,{zone = zn, point=event.pos})
						success = true
					end
				end
				if event.text=='debug' then
					local z = bc:getZoneOfPoint(event.pos)
					if z then
						local status = ""  -- initialize it
						env.info('-----------------------------------debug '..z.zone..'------------------------------------------')
						for i,v in pairs(z.built) do
							local gr = Group.getByName(v)
							if gr then
								env.info(gr:getName()..' '..gr:getSize()..'/'..gr:getInitialSize())
								for i2,v2 in ipairs(gr:getUnits()) do
									env.info('-'..v2:getName()..' '..v2:getLife()..'/'..v2:getLife0(),30)
								end
							else
								local st = StaticObject.getByName(v)
								if st then
									status = status..'\n  '..v..' 100%'
									env.info('Static: '..v..' 100%')
								end
							end
						end
						env.info('-----------------------------------end debug '..z.zone..'------------------------------------------')
		  
						trigger.action.removeMark(event.idx)
					end
				end
				if event.text=='spawn' then
					local z = bc:getZoneOfPoint(event.pos)
					if z then
						for i,v in ipairs(z.groups) do
							if v.state == 'inhangar' or v.state == 'dead' then
								v.lastStateTime = v.lastStateTime - (24*60*60)
							end
						end
						trigger.action.removeMark(event.idx)
					end
				end
				if event.text=='addshop' then
					bc:refreshShopMenuForCoalition(2)
						trigger.action.removeMark(event.idx)
						success = true
				end
				if event.text=='removeshop' then
					bc:RemoveMenuForCoalition(2)
						trigger.action.removeMark(event.idx)
						success = true
				end
			
				if event.text=='status' then
					local zn = self.context:getZoneOfPoint(event.pos)
					if zn then
						if event.initiator then
							zn:displayStatus(event.initiator:getGroup():getID(), 60)
						else
							zn:displayStatus(nil, 30)
						end
						
						success = true
					else
						success = true
						if event.initiator then
							trigger.action.outTextForGroup(event.initiator:getGroup():getID(), 'Status command only works inside a zone', 20)
						else
							trigger.action.outTextForCoalition(event.coalition, 'Status command only works inside a zone', 20)
						end
					end
				end
				if event.text=='event' then
					for i,v in ipairs(evc.events) do
						env.info(v.id)
					end
					trigger.action.removeMark(event.idx)
				end
				if event.text:find('^event\:') then
					local s = event.text:gsub('^event\:', '')
					local eventname = s
					evc:triggerEvent(eventname)
					trigger.action.removeMark(event.idx)
				end
				if event.text=='rensa' then
					local z = bc:getZoneOfPoint(event.pos)
					if z then
						z:killAll()
						trigger.action.removeMark(event.idx)
						success = true
					end
				end
				if event.text:find('^Message%s*:') then
					local msg = event.text:gsub('^Message%s*:%s*', '')
					trigger.action.outText(msg, 10)
					trigger.action.removeMark(event.idx)
					success = true
				end
				if event.text:find('SpelaMusik') then
					trigger.action.setUserFlag(180, true)
					trigger.action.outSoundForCoalition(2, "BH.ogg")
					trigger.action.removeMark(event.idx)
					success = true
					SCHEDULER:New(nil,function()
						trigger.action.setUserFlag(180, false)
					end,{},300,0)
				end
				if event.text=='AvslutaFoothold' then
					if forceMissionComplete then
						forceMissionComplete()
						trigger.action.removeMark(event.idx)
						success = true
					end
				end
				if event.text=='intelstatus' then
					local z=bc:getZoneOfPoint(event.pos)
					if z then
						if event.initiator then
							z:displayStatus(event.initiator:getGroup():getID(),60,true)
						else
							z:displayStatus(nil,30,true)
						end
						trigger.action.removeMark(event.idx)
						success=true
					end
				end
                if event.text=='missions' then
					mc:printMissions(nil)
                    success = true
                    trigger.action.removeMark(event.idx)
                end
				if event.text:find('^addfunds\:') then
					local s = event.text:gsub('^addfunds\:', '')
					local amount = tonumber(s)
					bc:addFunds(2,amount)
                    success = true
                    trigger.action.removeMark(event.idx)
                end
				if event.text=='upgradera' then
					local z = bc:getZoneOfPoint(event.pos)
					if z then
						z:upgrade()
						trigger.action.removeMark(event.idx)
					end
				end
				if event.text=='recapture' then
					local z = bc:getZoneOfPoint(event.pos)
					if z then
						z:RecaptureBlueZone()
						trigger.action.removeMark(event.idx)
					end
				end
				if event.text=='maxxa' then
					local z = bc:getZoneOfPoint(event.pos)
					if z then
						z:MakeZoneSideAndUpgraded()
						trigger.action.removeMark(event.idx)
					end
				end
				if event.text:find('^capture\:') then
					local s = event.text:gsub('^capture\:', '')
					local side = tonumber(s)
					if side == 1 or side == 2 then
						local z = bc:getZoneOfPoint(event.pos)
						if z then
							z:capture(side)
							trigger.action.removeMark(event.idx)
							success = true
						end
					end
				end
				if event.text=='blå' then
					local z = bc:getZoneOfPoint(event.pos)
					if z then
						z:capture(2)
						trigger.action.removeMark(event.idx)
						success = true
					end
				end
				if event.text=='röd' then
					local z = bc:getZoneOfPoint(event.pos)
					if z then
						z:capture(1)
						trigger.action.removeMark(event.idx)
						success = true
					end
				end
				if event.text=='stats' then
					if event.initiator then
						self.context:printStats(event.initiator:getID())
						success = true
					else
						self.context:printStats()
						success = true
					end
				end
				if event.text=='top' then
					if event.initiator then
						self.context:printStats(event.initiator:getID(), 5)
						success = true
					else
						self.context:printStats(nil, 5)
						success = true
					end
				end
				
				if event.text=='mystats' then
					if event.initiator then
						self.context:printMyStats(event.initiator:getID(), event.initiator:getPlayerName())
						success = true
					end
				end
				
				
				if success then
					trigger.action.removeMark(event.idx)
				end
			end
		end
		
		world.addEventHandler(markEditedEvent)
	end
--[[
function BattleCommander:buildZoneStatusMenu()
    if not self.zoneStatusMenu then
        self.zoneStatusMenu = missionCommands.addSubMenu('Zone Status')
    end

    if self.redSideMenu then
        missionCommands.removeItem(self.redSideMenu)
    end
    if self.blueSideMenu then
        missionCommands.removeItem(self.blueSideMenu)
    end

    self.redSideMenu = missionCommands.addSubMenu('Red Side', self.zoneStatusMenu)
    self.blueSideMenu = missionCommands.addSubMenu('Blue Side', self.zoneStatusMenu)

    local sub1Red, sub1Blue

    self.redSideZones = {}
    self.blueSideZones = {}

    for i, v in ipairs(self.zones) do
        if not v.zone:lower():find("hidden") then
            if v.side == 1 then
                table.insert(self.redSideZones, v)
            elseif v.side == 2 then
                table.insert(self.blueSideZones, v)
            end
        end
    end

    for i, v in ipairs(self.redSideZones) do
        if i < 10 then
            missionCommands.addCommand(v.zone, self.redSideMenu, v.displayStatus, v)
        elseif i == 10 then
            sub1Red = missionCommands.addSubMenu("More", self.redSideMenu)
            missionCommands.addCommand(v.zone, sub1Red, v.displayStatus, v)
        elseif i % 9 == 1 then
            sub1Red = missionCommands.addSubMenu("More", sub1Red)
            missionCommands.addCommand(v.zone, sub1Red, v.displayStatus, v)
        else
            missionCommands.addCommand(v.zone, sub1Red, v.displayStatus, v)
        end
    end

    for i, v in ipairs(self.blueSideZones) do
        if i < 10 then
            missionCommands.addCommand(v.zone, self.blueSideMenu, v.displayStatus, v)
        elseif i == 10 then
            sub1Blue = missionCommands.addSubMenu("More", self.blueSideMenu)
            missionCommands.addCommand(v.zone, sub1Blue, v.displayStatus, v)
        elseif i % 9 == 1 then
            sub1Blue = missionCommands.addSubMenu("More", sub1Blue)
            missionCommands.addCommand(v.zone, sub1Blue, v.displayStatus, v)
        else
            missionCommands.addCommand(v.zone, sub1Blue, v.displayStatus, v)
        end
    end
end
--]]

	function BattleCommander:init()
		self:startMonitorPlayerMarkers()
		self:initializeRestrictedGroups()

		if self.difficulty then
			self.lastDiffChange = timer.getAbsTime()
		end

		table.sort(self.zones, function(a, b) return a.zone < b.zone end)
		for i, v in ipairs(self.zones) do
			v:init()
		end

		for i, v in ipairs(self.connections) do
			local from = CustomZone:getByName(v.from)
			local to = CustomZone:getByName(v.to)

			trigger.action.lineToAll(-1, 1000 + i, from.point, to.point, {1, 1, 1, 0.5}, 2)
		end

		
				self:drawSupplyArrows()


		--missionCommands.addCommandForCoalition(1, 'Budget overview', nil, self.printShopStatus, self, 1)
		--missionCommands.addCommandForCoalition(2, 'Budget overview', nil, self.printShopStatus, self, 2)

		--self:refreshShopMenuForCoalition(1)
		--self:refreshShopMenuForCoalition(2)

	SCHEDULER:New(self,function(o)o:update()end,{},1,self.updateFrequency)
	SCHEDULER:New(self,function(o)o:saveToDisk()end,{},30,self.saveFrequency)
	playerZoneSpawn = playerZoneSpawn or {}
	ev = {}
	function ev:onEvent(event)
		if event.id == world.event.S_EVENT_BIRTH and
		event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT and
		(Unit.getCategoryEx(event.initiator) == Unit.Category.AIRPLANE or Unit.getCategoryEx(event.initiator) == Unit.Category.HELICOPTER) then
			local pname = event.initiator:getPlayerName()
			if pname then
				local un = event.initiator
				local zn = BattleCommander:getZoneOfUnit(un:getName())
				local gr = event.initiator:getGroup()
				local groupId = gr:getID()
				mc:createMissionsMenuForGroup(groupId)
				bc:buildZoneStatusMenuForGroup(groupId)
				if zn then
					local isDifferentSide = zn.side ~= un:getCoalition()
					
					if isDifferentSide and not zn.wasBlue then
						for i, v in pairs(net.get_player_list()) do
							if net.get_name(v) == pname then
								net.send_chat_to('Cannot spawn as '..gr:getName()..' in enemy/neutral zone', v)
								timer.scheduleFunction(function(param, time)
									net.force_player_slot(param, 0, '')
								end, v, timer.getTime() + 0.1)
								break
							end
						end
						trigger.action.outTextForGroup(gr:getID(), 'Cannot spawn as '..gr:getName()..' in enemy/neutral zone', 5)
						if event.initiator and event.initiator:isExist() then
							event.initiator:destroy()
						end
					else
						if handleMission and Unit.getCategoryEx(un) == Unit.Category.HELICOPTER then
							timer.scheduleFunction(function()
								if gr and gr:isExist() then
									handleMission(zn.zone, gr:getName(), gr:getID(), gr)
								end
							end, {}, timer.getTime() + 30)
						end
						if Unit.getCategoryEx(un) == Unit.Category.AIRPLANE then
							if capMissionTarget ~= nil and capKillsByPlayer[pname] then
								capKillsByPlayer[pname] = 0
							end
						if un:getTypeName() ~= "A-10C_2" and un:getTypeName() ~= "Hercules" and un:getTypeName() ~= "A-10A" and un:getTypeName() ~= "AV8BNA" then
								playerZoneSpawn[pname] = zn.zone
							end
						end
					end
				end
			end
		end
	end
	world.addEventHandler(ev)
end

-- Function to get train group name for a supply connection
function BattleCommander:getTrainGroupForConnection(from, to)
    -- Check for Red coalition train groups (AXE_Train_ prefix)
    local redTrainGroupName = "AXE_Train_" .. from .. "-resupply-" .. to
    local redTrainGroup = Group.getByName(redTrainGroupName)
    
    if redTrainGroup then
        return redTrainGroupName
    end
    
    -- Check for Blue coalition train groups (UK_Train_ prefix)
    local blueTrainGroupName = "UK_Train_" .. from .. "-resupply-" .. to
    local blueTrainGroup = Group.getByName(blueTrainGroupName)
    
    if blueTrainGroup then
        return blueTrainGroupName
    end
    
    -- Return nil if no train group exists for this connection
    return nil
end

DRAW_SUPPLY_ARROWS_DEBUG_LOGGING = false -- Set to true to enable debug logging

-- Helper functions for debug logging
local function supplyArrowLog(message)
    if DRAW_SUPPLY_ARROWS_DEBUG_LOGGING then
        env.info(message)
    end
end
function BattleCommander:drawSupplyArrows()
env.info("DEBUG: drawSupplyArrows called")
-- Clear existing arrows
for _, id in ipairs(_activeArrowIds) do
trigger.action.removeMark(id)
end
_activeArrowIds = {} -- Reset the list of active arrow IDs

env.info("DEBUG: Cleared existing arrows.")

if not self.connectionssupply or #self.connectionssupply == 0 then
env.info("DEBUG: No supply connections to draw.")
return
end

for i, v in ipairs(self.connectionssupply) do
local from = CustomZone:getByName(v.from)
local to = CustomZone:getByName(v.to)

local fromZone = self:getZoneByName(v.from)
local toZone   = self:getZoneByName(v.to)

-- Check if this is a train connection and if the train exists
local skipArrow = false
        if v.method == 'train' then
            -- This is a train route - check if train group exists
            local trainGroupName = self:getTrainGroupForConnection(v.from, v.to)
            
            if not trainGroupName then
                skipArrow = true
                supplyArrowLog(string.format("DEBUG: Skipping arrow for train connection %d (%s -> %s) - no train group name found", i, v.from, v.to))
            else
                -- Check if train is marked as destroyed in CustomFlags
                if CustomFlags and CustomFlags[trainGroupName] == true then
                    skipArrow = true
                    supplyArrowLog(string.format("DEBUG: Skipping arrow for train connection %d (%s -> %s) - train group %s is marked as destroyed in CustomFlags", i, v.from, v.to, trainGroupName))
                else
                    local trainGroup = Group.getByName(trainGroupName)
                    
                    if not trainGroup then
                        skipArrow = true
                        supplyArrowLog(string.format("DEBUG: Skipping arrow for train connection %d (%s -> %s) - train group %s doesn't exist", i, v.from, v.to, trainGroupName))
                    else
                        -- Additional check: verify the train group has units and they're alive
                        local units = trainGroup:getUnits()
                        if not units or #units == 0 then
                            skipArrow = true
                            supplyArrowLog(string.format("DEBUG: Skipping arrow for train connection %d (%s -> %s) - train group %s has no units", i, v.from, v.to, trainGroupName))
                        else
                            local unit = units[1]
                            if not unit or not unit:isExist() or unit:getLife() <= 1 then
                                skipArrow = true
                                supplyArrowLog(string.format("DEBUG: Skipping arrow for train connection %d (%s -> %s) - train group %s unit is dead/destroyed", i, v.from, v.to, trainGroupName))
                            else
                                env.info(string.format("DEBUG: Train group %s exists and is operational for connection %d (%s -> %s)", trainGroupName, i, v.from, v.to))
                            end
                        end
                    end
                end
            end
        else
            env.info(string.format("DEBUG: Connection %d (%s -> %s) is not a train route (method: %s), drawing arrow normally", i, v.from, v.to, v.method or 'default'))
        end

-- Draw arrow unless it's a destroyed train route
if not skipArrow then
_globalArrowCounter = _globalArrowCounter + 1 -- Get a new unique ID
local arrowId = _globalArrowCounter
table.insert(_activeArrowIds, arrowId)

supplyArrowLog(string.format("DEBUG: Processing connection %d: from=%s (side %s), to=%s (side %s), New Arrow ID: %d", i, v.from, tostring(fromZone and fromZone.side), v.to, tostring(toZone and toZone.side), arrowId))

if fromZone and toZone and from and to then
if fromZone.side == 2 and toZone.side ~= 1  then
supplyArrowLog(string.format("DEBUG: Drawing BLUE arrow for connection %d", i))
trigger.action.arrowToAll(-1, arrowId, to.point, from.point, {0, 0, 0, 0.5}, {0, 0, 1, 0.5}, 2)
elseif fromZone.side == 1 and toZone.side ~= 2 then
supplyArrowLog(string.format("DEBUG: Drawing RED arrow for connection %d", i))
trigger.action.arrowToAll(-1, arrowId, to.point, from.point, {0, 0, 0, 0.5}, {1, 0, 0, 0.5}, 2)
else
supplyArrowLog(string.format("DEBUG: Drawing NEUTRAL arrow for connection %d", i))
trigger.action.arrowToAll(-1, arrowId, to.point, from.point, {0, 0, 0, 0.5}, {1, 1, 1, 0.5}, 2)
end
else
env.info(string.format("DEBUG: Skipping connection %d due to nil zone/point data.", i))
end
end
end
end

BattleCommander.zoneStatusMenus = {}
BattleCommander.redSideMenus    = {}
BattleCommander.blueSideMenus   = {}

	function BattleCommander:buildZoneStatusMenuForGroup(groupId)
		if not groupId then
			for storedGroupId,_ in pairs(self.zoneStatusMenus) do
				self:buildZoneStatusMenuForGroup(storedGroupId)
			end
			return
		end
		if self.redSideMenus[groupId] then
			missionCommands.removeItemForGroup(groupId, self.redSideMenus[groupId])
			self.redSideMenus[groupId] = nil
		end
		if self.blueSideMenus[groupId] then
			missionCommands.removeItemForGroup(groupId, self.blueSideMenus[groupId])
			self.blueSideMenus[groupId] = nil
		end
		if not self.zoneStatusMenus[groupId] then
			self.zoneStatusMenus[groupId] = missionCommands.addSubMenuForGroup(groupId, "Zone Status")
		end
		self.redSideMenus[groupId] = missionCommands.addSubMenuForGroup(groupId,"Red Side", self.zoneStatusMenus[groupId])
		self.blueSideMenus[groupId] = missionCommands.addSubMenuForGroup(groupId,"Blue Side", self.zoneStatusMenus[groupId])
		local sub1Red, sub1Blue = nil, nil
		self.redSideZones, self.blueSideZones = {}, {}
		for i,v in ipairs(self.zones) do
			if not v.zone:lower():find("hidden") then
				if v.side==1 then table.insert(self.redSideZones,v)
				elseif v.side==2 then table.insert(self.blueSideZones,v) end
			end
		end
		for i,v in ipairs(self.redSideZones) do
			if i<10 then
				missionCommands.addCommandForGroup(groupId,v.zone,self.redSideMenus[groupId],v.displayStatus,v,groupId)
			elseif i==10 then
				sub1Red=missionCommands.addSubMenuForGroup(groupId,"More",self.redSideMenus[groupId])
				missionCommands.addCommandForGroup(groupId,v.zone,sub1Red,v.displayStatus,v,groupId)
			elseif i%9==1 then
				sub1Red=missionCommands.addSubMenuForGroup(groupId,"More",sub1Red)
				missionCommands.addCommandForGroup(groupId,v.zone,sub1Red,v.displayStatus,v,groupId)
			else
				missionCommands.addCommandForGroup(groupId,v.zone,sub1Red,v.displayStatus,v,groupId)
			end
		end
		for i,v in ipairs(self.blueSideZones) do
			if i<10 then
				missionCommands.addCommandForGroup(groupId,v.zone,self.blueSideMenus[groupId],v.displayStatus,v,groupId)
			elseif i==10 then
				sub1Blue=missionCommands.addSubMenuForGroup(groupId,"More",self.blueSideMenus[groupId])
				missionCommands.addCommandForGroup(groupId,v.zone,sub1Blue,v.displayStatus,v,groupId)
			elseif i%9==1 then
				sub1Blue=missionCommands.addSubMenuForGroup(groupId,"More",sub1Blue)
				missionCommands.addCommandForGroup(groupId,v.zone,sub1Blue,v.displayStatus,v,groupId)
			else
				missionCommands.addCommandForGroup(groupId,v.zone,sub1Blue,v.displayStatus,v,groupId)
			end
		end
	end

	function BattleCommander:addTempStat(playerName, statKey, value)
		self.tempStats = self.tempStats or {}
		self.tempStats[playerName] = self.tempStats[playerName] or {}
		self.tempStats[playerName][statKey] = self.tempStats[playerName][statKey] or 0
		self.tempStats[playerName][statKey] = self.tempStats[playerName][statKey] + value
	end
	
	function BattleCommander:addStat(playerName, statKey, value)
		self.playerStats = self.playerStats or {}
		self.playerStats[playerName] = self.playerStats[playerName] or {}
		self.playerStats[playerName][statKey] = self.playerStats[playerName][statKey] or 0
		self.playerStats[playerName][statKey] = self.playerStats[playerName][statKey] + value
	end
	
	function BattleCommander:resetTempStats(playerName)
		self.tempStats = self.tempStats or {}
		self.tempStats[playerName] = {}
	end
	
	function BattleCommander:printTempStats(side, player)
		self.tempStats = self.tempStats or {}
		self.tempStats[player] = self.tempStats[player] or {}
		local sorted = {}
		for i,v in pairs(self.tempStats[player]) do table.insert(sorted,{i,v}) end
		table.sort(sorted, function(a,b) return a[1] < b[1] end)
		
		local message = '['..player..']'
		for i,v in ipairs(sorted) do
			message = message..'\n+'..v[2]..' '..v[1]
		end
		
		trigger.action.outTextForCoalition(side, message , 10)
	end
	
	function BattleCommander:printMyStats(unitid, player)
		self.playerStats = self.playerStats or {}
		self.playerStats[player] = self.playerStats[player] or {}

		local rank = nil
		local sorted2 = {}
		for i, v in pairs(self.playerStats) do
			table.insert(sorted2, {i, v})
		end
		table.sort(sorted2, function(a, b)
			return (a[2]['Points'] or 0) > (b[2]['Points'] or 0)
		end)
		for i, v in ipairs(sorted2) do
			if v[1] == player then
				rank = i
				break
			end
		end

		local playerStats = {
			['Air'] = 0,
			['Helo'] = 0,
			['Ground Units'] = 0,
			['Infantry'] = 0,
			['Ship'] = 0,
			['SAM'] = 0,
			['Structure'] = 0,
			['Deaths'] = 0,
			['Points'] = 0,
			['Points spent'] = 0
		}

		for statKey, statValue in pairs(self.playerStats[player]) do
			if statKey == 'Air' then
				playerStats['Air'] = statValue
			elseif statKey == 'Helo' then
				playerStats['Helo'] = statValue
			elseif statKey == 'SAM' then
				playerStats['SAM'] = statValue
			elseif statKey == 'Ground Units' then
				playerStats['Ground Units'] = (playerStats['Ground Units'] or 0) + statValue
			elseif statKey == 'Infantry' then
				playerStats['Infantry'] = statValue
			elseif statKey == 'Ship' then
				playerStats['Ship'] = statValue
			elseif statKey == 'Structure' then
				playerStats['Structure'] = statValue
			elseif statKey == 'Deaths' then
				playerStats['Deaths'] = statValue
			elseif statKey == 'Points' then
				playerStats['Points'] = statValue
			elseif statKey == 'Points spent' then
				playerStats['Points spent'] = statValue
				
			end
		end

		local message = rank .. ' [' .. player .. ']'

		local displayOrder = {'Air', 'Helo', 'Ground Units', 'Infantry', 'Ship', 'SAM', 'Structure', 'Deaths', 'Points', 'Points spent'}

		for _, statKey in ipairs(displayOrder) do
			message = message .. '\n' .. statKey .. ': ' .. (playerStats[statKey] or 0)
		end

		trigger.action.outTextForUnit(unitid, message, 10)
	end


	function BattleCommander:printStats(unitid, top)
		self.playerStats = self.playerStats or {}
		local sorted = {}
		for i, v in pairs(self.playerStats) do
			table.insert(sorted, {i, v})
		end
		table.sort(sorted, function(a, b)
			return (a[2]['Points'] or 0) > (b[2]['Points'] or 0)
		end)

		local message = '[Leaderboards]'
		if top then
			message = '[Top ' .. top .. ' players]'
		end

		local counter = 0
		for i, v in ipairs(sorted) do
			counter = counter + 1
			if top and counter > top then
				break
			end

			message = message .. '\n\n' .. i .. '. [' .. v[1] .. ']\n'


			local playerStats = {
				['Air'] = 0,
				['Helo'] = 0,
				['Ground Units'] = 0,
				['Ship'] = 0,
				['SAM'] = 0,
				['Structure'] = 0,
				['Deaths'] = 0,
				['Points'] = 0,
				['Points spent'] = 0
			}

		for statKey, statValue in pairs(v[2]) do
			if statKey == 'Air' then
				playerStats['Air'] = statValue
			elseif statKey == 'Helo' then
				playerStats['Helo'] = statValue
			elseif statKey == 'SAM' then
				playerStats['SAM'] = statValue
			elseif statKey == 'Ground Units' or statKey == 'Infantry' then
				playerStats['Ground Units'] = (playerStats['Ground Units'] or 0) + statValue
			elseif statKey == 'Ship' then
				playerStats['Ship'] = statValue
			elseif statKey == 'Structure' then
				playerStats['Structure'] = statValue
			elseif statKey == 'Deaths' then
				playerStats['Deaths'] = statValue
			elseif statKey == 'Points' then
				playerStats['Points'] = statValue
			elseif statKey == 'Points spent' then
				playerStats['Points spent'] = statValue
			end
		end

			local displayOrder = {'Air', 'Helo', 'Ground Units', 'Ship', 'SAM', 'Structure', 'Deaths', 'Points', 'Points spent'}

			for _, statKey in ipairs(displayOrder) do
				message = message .. statKey .. ': ' .. (playerStats[statKey] or 0) .. '\n'
			end
		end

		if unitid then
			trigger.action.outTextForUnit(unitid, message, 15)
		else
			trigger.action.outText(message, 15)
		end
	end
	
	function BattleCommander:commitTempStats(playerName)
		self.tempStats = self.tempStats or {}
		local stats = self.tempStats[playerName]
		if stats then
			for key,value in pairs(stats) do
				self:addStat(playerName, key, value)
			end
			
			self:resetTempStats(playerName)
		end
	end

	
-- hunter script
function BattleCommander:initHunter(threshold)
  self.huntThreshold      = threshold or 9999
  self.huntKills          = {}
  self.huntDone           = {}
  self.huntBases          = nil
end


function BattleCommander:_buildHunterBaseList()
  local list, seen = {}, {}
  for _,z in ipairs(self.zones) do
    if z.side == 1 and z.active then
      local n = z.airbaseName
      if n and not seen[n] then
        local ab = AIRBASE:FindByName(n)
        if ab and ab:IsAirdrome() then
          list[#list+1] = ab
          seen[n]       = true
        end
      end
    end
  end
  self.huntBases = list
end

function BattleCommander:_pickHunterBase(coord,termType,need)
  if not self.huntBases or #self.huntBases==0 then self:_buildHunterBaseList() end
  local min=40*1852
  local cand={}
  for _,ab in ipairs(self.huntBases) do
    local d=coord:Get2DDistance(ab:GetCoordinate())
    cand[#cand+1]={ab=ab,d=d,ok=d>=min}
  end
  table.sort(cand,function(a,b) return a.d<b.d end)
  local tried=0
  for pass=1,2 do
    for _,c in ipairs(cand) do
      if (pass==1 and c.ok) or (pass==2 and not c.ok) then
        local free=c.ab:GetFreeParkingSpotsTable(termType,false)
        if #free>=need then
          table.sort(free,function(a,b)
            local da=a.Coordinate:Get2DDistance(b.Coordinate)
            return da<0
          end)
          -- choose the geometrically nearest pair
          local best1,best2,bestd=nil,nil,nil
          for i=1,#free-1 do
            for j=i+1,#free do
              local d=free[i].Coordinate:Get2DDistance(free[j].Coordinate)
              if not bestd or d<bestd then
                best1,best2,bestd=free[i],free[j],d
              end
            end
          end
          return c.ab,{best1,best2}
        end
        tried=tried+1 ; if tried==3 then return nil end
      end
    end
  end
end


function BattleCommander:_spawnHunterForPlayer(pname,u,termType)
  local unit = UNIT:FindByName(u:getName()) ; if not unit or not unit:IsAlive() then return end
  termType   = termType or AIRBASE.TerminalType.OpenMedOrBig
  local home, spots = self:_pickHunterBase(unit:GetCoordinate(), termType, 2) ; if not home then return end

  if not spots or #spots < 2 then
    env.info(string.format('HUNT-DBG: only %s free spots @%s', spots and #spots or 0, home:GetName()))
    return
  end

  table.sort(spots, function(a,b) return a.TerminalID < b.TerminalID end)

  local s1, s2
  for i = 1, #spots - 1 do
    if spots[i+1].TerminalID == spots[i].TerminalID + 1 then
      s1, s2 = spots[i].TerminalID, spots[i+1].TerminalID
      break
    end
  end
  if not s1 then s1, s2 = spots[1].TerminalID, spots[2].TerminalID end
local template = Era=='Coldwar' and 'RED_MIG23_TEMPLATE' or 'RED_MIG29_TEMPLATE'
local hunter   = SPAWN:NewWithAlias(template, 'HUNTER_'..pname)
  hunter:OnSpawnGroup(function(g)
    Hunt = FLIGHTGROUP:New(g)
    Hunt:SetHomebase(home)
    Intercept = AUFTRAG:NewINTERCEPT(unit:GetGroup())
    Hunt:AddMission(Intercept)
    Intercept:SetMissionAltitude(25000)
    Intercept:SetMissionSpeed(500)
    Hunt:MissionStart(Intercept)
	function Hunt:OnAfterTakeoff(from,event,to)
		local currentMission = self:GetMissionCurrent()
		 if (not unit:IsAlive()) and currentMission then
			currentMission:__Cancel(5) 
		end
	end
	function Hunt:OnAfterTakeoff(from,event,to)
		trigger.action.outTextForCoalition(2, pname..', Enemy is scrambling 2 jets to hunt you down!', 30)
	local BlueVictory = USERSOUND:New( "Watch your six.ogg" )
	local PlayerUnit = CLIENT:FindByPlayerName(pname)
	if PlayerUnit then
	BlueVictory:ToClient( PlayerUnit )
	end
	end
	function Hunt:OnAfterDead(from,event,to)
	bc.huntDone[pname]=nil ; bc.huntKills[pname]=0
	end
	function Hunt:OnAfterLanded(From, Event, To)
    	self:ScheduleOnce(5, function() self:Destroy() end)
	end
  end)
  hunter:SpawnAtParkingSpot(home, {s1, s2}, SPAWN.Takeoff.Hot)
  env.info('Enemy is scrambling 2 jets to hunt you down!')
  --trigger.action.outTextForUnit(u:getID(), pname..', Enemy is scrambling 2 jets to hunt you down!', 30)
end


function BattleCommander:registerHuntKill(pname, initiatorUnit)
  if not playerList[pname] then return end
  if not initiatorUnit or not initiatorUnit:isExist() then return end

  local d = initiatorUnit:getDesc()
  if d and (d.category == Unit.Category.HELICOPTER or d.attributes.Helicopters) then return end

  local t = initiatorUnit:getTypeName()
  if t=="A-10C_2" or t=="A-10A" or t=="AV8BNA" then return end

  self.huntKills[pname] = (self.huntKills[pname] or 0) + 1

	if self.huntKills[pname] >= self.huntThreshold
	and not self.huntDone[pname] then
	local roll = math.random(100)
	env.info(string.format("HUNT-DBG: roll=%d for %s", roll, pname))
	if roll < 10 then
		self.huntDone[pname] = true
		self:_spawnHunterForPlayer(pname, initiatorUnit)
	end
	end
end

	-- defaultReward - base pay, rewards = {airplane=0, helicopter=0, ground=0, ship=0, structure=0, infantry=0, sam=0, crate=0, rescue=0} - overrides
function BattleCommander:startRewardPlayerContribution(defaultReward, rewards)
	self.playerRewardsOn = true
	self.rewards = rewards
	self.defaultReward = defaultReward
	local ev = {}
	ev.context = self
	ev.rewards = rewards
	ev.default = defaultReward


	function ev:onEvent(event)
		local unit = event.initiator
		if unit and Object.getCategory(unit) == Object.Category.UNIT and (Unit.getCategoryEx(unit) == Unit.Category.AIRPLANE or Unit.getCategoryEx(unit) == Unit.Category.HELICOPTER) then
			local side = unit:getCoalition()
			local groupid = unit:getGroup():getID()
			local pname = unit:getPlayerName()
							
			if event.id == 6 then -- Pilot ejected
				if pname then
					if self.context.playerContributions[side][pname]~=nil and self.context.playerContributions[side][pname]>0 then
						local tenp=math.floor(self.context.playerContributions[side][pname]*0.25)
						self.context:addFunds(side,tenp)
						trigger.action.outTextForCoalition(side,'['..pname..'] ejected. +'..tenp..' credits (25% of earnings). Kill statistics lost.',5)
						self.context:addStat(pname,'Points',tenp)
						self.context:addTempStat(pname,'Deaths',1)
						self.context:addStat(pname,'Deaths',1)
						local initiatorObjectID=unit:getObjectID()
						local lostCredits=self.context.playerContributions[side][pname]*0.75
						self.context.playerContributions[side][pname]=0
						local initiatorObjectID=event.initiator:getObjectID()
						ejectedPilotOwners[initiatorObjectID]={player=pname,lostCredits=lostCredits,coalition=side}
						if trackedGroups[groupid] then
							trackedGroups[groupid]=nil
							removeMenusForGroupID(groupid)
							for zName,groupTable in pairs(missionGroupIDs) do
								if groupTable[groupid] then
									groupTable[groupid]=nil
								end
							end
						end
						if capMissionTarget~=nil and capKillsByPlayer[pname]then
							capKillsByPlayer[pname]=0
						end
							if Hunt then
							bc.huntDone[pname] = nil
							end	
					end
				end
			end
			if pname then
				local gObj=unit:getGroup()
				-- Pilot death (NEW)
                if event.id == 9 then -- S_EVENT_PILOT_DEAD
                    self.context:addTempStat(pname,'Deaths',1)
                    self.context:addStat(pname,'Deaths',1)
                    if trackedGroups[groupid] then
                        trackedGroups[groupid]=nil
                        removeMenusForGroupID(groupid)
                        for zName,groupTable in pairs(missionGroupIDs) do
                            if groupTable[groupid] then groupTable[groupid]=nil end
                        end
                        if Hunt then bc.huntDone[pname]=nil end
                    end
                    if capMissionTarget~=nil and capKillsByPlayer[pname] then
                        capKillsByPlayer[pname]=0
                    end
                    
                    if gObj then
                        local gName=gObj:getName()
                        local escortGroup=escortGroups[gName]
                        if escortGroup then
                            escortGroup:Destroy()
                            escortGroups[gName]=nil
                        end
                    end
                end

				if event.id == 15 then
					self.context.playerContributions[side][pname] = 0
					self.context:resetTempStats(pname)
					if Hunt then
					bc.huntDone[pname] = nil
					end
				end

				if (event.id==28) then --killed unit
					if event.target.getCoalition and side ~= event.target:getCoalition() then
						local tgtCoal = event.target:getCoalition()
						if tgtCoal ~= 0 and side ~= tgtCoal then
							if self.context.playerContributions[side][pname] ~= nil then
								local earning,message,stat = self.context:objectToRewardPoints2(event.target)
								if earning and message then
									--trigger.action.outTextForGroup(groupid,'['..pname..'] '..message, 5)
									self.context.playerContributions[side][pname] = self.context.playerContributions[side][pname] + earning
								end
								if stat then
									self.context:addTempStat(pname,stat,1)
									if Hunt and (stat=='Ground Units' or stat=='SAM' or stat=='Infantry') then bc:registerHuntKill(pname, event.initiator) end
								end
								if capMissionTarget ~= nil then
									if (event.target:hasAttribute('Planes') or 
										event.target:hasAttribute('Helicopters')) then
										capKillsByPlayer[pname] = (capKillsByPlayer[pname] or 0) + 1
										local killsSoFar = capKillsByPlayer[pname]
										if killsSoFar >= capTargetPlanes then
											capWinner = pname
											capMissionTarget = nil
											
										end
									end
								end
							end
						end
					end
				end
				if event.id == 4 then -- Landing event
					if self.context.playerContributions[side][pname]~=nil and self.context.playerContributions[side][pname] 
					and self.context.playerContributions[side][pname] > 0 then
						local foundZone = false
						for i, v in ipairs(self.context:getZones()) do
							if ((side == v.side) or (v.wasBlue and side == 2)) and Utils.isInZone(unit, v.zone) then
								foundZone = true
								trigger.action.outTextForGroup(groupid, '[' .. pname .. '] landed at ' .. v.zone .. '.\nWait 5 seconds to claim credits...', 5)

								local claimfunc = function(context, zone, player, unitname)
									local un = Unit.getByName(unitname)
									if un and (Utils.isInZone(un, zone.zone) or zone.wasBlue) and Utils.isLanded(un, true) and un:getPlayerName() == player then
										if un:getLife() > 0 then
											local coalitionSide = zone.side
											if zone.wasBlue then
												coalitionSide = 2
											end

											context:addFunds(coalitionSide, context.playerContributions[coalitionSide][player])
											trigger.action.outTextForCoalition(coalitionSide, '[' .. player .. '] redeemed ' .. context.playerContributions[coalitionSide][player] .. ' credits', 15)
											context:printTempStats(coalitionSide, player)
											context:addTempStat(player, 'Points', context.playerContributions[coalitionSide][player])
											context:commitTempStats(player)
											context.playerContributions[coalitionSide][player] = 0
											context:saveToDisk()
											if Hunt then
											bc.huntDone[pname] = nil
											end
										end
									end
								end

								SCHEDULER:New(nil,claimfunc,{self.context,v,pname,unit:getName()},5,0)
								break
							end
						end

						if not foundZone and unit:getDesc().category == Unit.Category.AIRPLANE then
							local carrierUnit
							if IsGroupActive("CVN-72") then
								carrierUnit = Unit.getByName("CVN-72")
							elseif IsGroupActive("CVN-73") then
								carrierUnit = Unit.getByName("CVN-73")
							else
								env.info("No active carrier found.")
							end

								if carrierUnit then
								local carrierCoord = UNIT:Find(carrierUnit):GetCoordinate()
								local playerCoord  = UNIT:Find(unit):GetCoordinate()
								local distance     = carrierCoord:Get2DDistance(playerCoord)   -- metres


								if distance < 200 then
									trigger.action.outTextForGroup(groupid, '[' .. pname .. '] landed on the Abraham Lincoln.\nWait 10 seconds to claim credits...', 6)
									local claimfunc = function(context, player, unitname)
										local un = Unit.getByName(unitname)
										if un and Utils.isLanded(un, true) and un:getPlayerName() == player then
											if un:getLife() > 0 then
												local coalitionSide = un:getCoalition()
												context:addFunds(coalitionSide, context.playerContributions[coalitionSide][player])
												trigger.action.outTextForCoalition(coalitionSide, '[' .. player .. '] redeemed ' .. context.playerContributions[coalitionSide][player] .. ' credits', 15)
												context:printTempStats(coalitionSide, player)
												context:addTempStat(player, 'Points', context.playerContributions[coalitionSide][player])
												context:commitTempStats(player)
												context.playerContributions[coalitionSide][player] = 0
												if Hunt then
												bc.huntDone[pname] = nil
												end
											end
										end
									end
									SCHEDULER:New(nil,claimfunc,{self.context,pname,unit:getName()},10,0)
								end
							end
						end
					end
					if gObj then
						local gName = gObj:getName()
						local escortGroup = escortGroups[gName]
						if escortGroup then
							escortGroup:Destroy()
						end
					end
				end
				if CreditLosewhenKilled and CreditLosewhenKilled == true then
					if event.id == world.event.S_EVENT_UNIT_LOST then
						self.context:addFunds(side,-100)
						trigger.action.outTextForCoalition(side,'['..pname..'] aircraft lost, -100 credits',10)
					end
				end
			end
		end
	end
	world.addEventHandler(ev)

	local resetPoints = function(context, side)
		local plys = coalition.getPlayers(side)

		local players = {}
		for i, v in pairs(plys) do
			local nm = v:getPlayerName()
			if nm then
				players[nm] = true
			end
		end

		for i, v in pairs(context.playerContributions[side]) do
			if not players[i] then
				context.playerContributions[side][i] = 0
			end
		end
	end

	SCHEDULER:New(nil,resetPoints,{self,1},1,60)
	SCHEDULER:New(nil,resetPoints,{self,2},1,60)
end


	function BattleCommander:objectToRewardPoints(object) -- returns points,message
		local objName = object and object:getName() or ""
		for _, zone in ipairs(self.zones or {}) do
			for _, co in ipairs(zone.criticalObjects or {}) do
				if co == objName then
					return -- Skip awarding if it's a critical static
				end
			end
		end

		if Object.getCategory(object) == Object.Category.UNIT then
			local targetType = object:getDesc().category
			local earning = self.defaultReward
			local message = 'Unit kill +'..earning..' credits'
			
			if targetType == Unit.Category.AIRPLANE and self.rewards.airplane then
				earning = self.rewards.airplane
				message = 'Aircraft kill +'..earning..' credits'
			elseif targetType == Unit.Category.HELICOPTER and self.rewards.helicopter then
				earning = self.rewards.helicopter
				message = 'Helicopter kill +'..earning..' credits'
			elseif targetType == Unit.Category.GROUND_UNIT then
				if (object:hasAttribute('SAM SR') or object:hasAttribute('SAM TR') or object:hasAttribute('IR Guided SAM')) and self.rewards.sam then
					earning = self.rewards.sam
					message = 'SAM kill +'..earning..' credits'							
				elseif object:hasAttribute('Infantry') and self.rewards.infantry then
					earning = self.rewards.infantry
					message = 'Infantry kill +'..earning..' credits'
				else
					earning = self.rewards.ground
					message = 'Ground kill +'..earning..' credits'
				end
			elseif targetType == Unit.Category.SHIP and self.rewards.ship then
				earning = self.rewards.ship
				message = 'Ship kill +'..earning..' credits'
			elseif targetType == Unit.Category.STRUCTURE and self.rewards.structure then
				earning = self.rewards.structure
				message = 'Structure kill +'..earning..' credits'
			end
			
			return earning,message
		end
	end
	
	function BattleCommander:objectToRewardPoints2(object) -- returns points,message
		
		local objName = object and object:getName() or ""
		for _, zone in ipairs(self.zones or {}) do
			for _, co in ipairs(zone.criticalObjects or {}) do
				if co == objName then
					return -- Skip awarding if it's a critical static
				end
			end
		end
		
		local earning = self.defaultReward
		local message = 'Unit kill +'..earning..' credits'
		local statname = 'Ground Units'
		
		if object:hasAttribute('Planes') and self.rewards.airplane then
			earning = self.rewards.airplane
			message = 'Aircraft kill +'..earning..' credits'
			statname = 'Air'
		elseif object:hasAttribute('Helicopters') and self.rewards.helicopter then
			earning = self.rewards.helicopter
			message = 'Helicopter kill +'..earning..' credits'
			statname = 'Helo'
		elseif (object:hasAttribute('SAM SR') or object:hasAttribute('SAM TR') or object:hasAttribute('IR Guided SAM')) and self.rewards.sam then
			earning = self.rewards.sam
			message = 'SAM kill +'..earning..' credits'
			statname = 'SAM'
		elseif object:hasAttribute('Infantry') and self.rewards.infantry then
			earning = self.rewards.infantry
			message = 'Infantry kill +'..earning..' credits'
			statname = 'Infantry'
		elseif object:hasAttribute('Ships') and self.rewards.ship then
			earning = self.rewards.ship
			message = 'Ship kill +'..earning..' credits'
			statname = 'Ship'
		elseif object:hasAttribute('Ground Units') then
			earning = self.rewards.ground
			message = 'Vehicle kill +'..earning..' credits'
			statname = 'Ground Units'
		elseif object:hasAttribute('Buildings') and self.rewards.structure then
			earning = self.rewards.structure
			message = 'Structure kill +'..earning..' credits'
			statname = 'Structure'
		elseif Object.getCategory(object) == Object.Category.STATIC then
			local desc = object:getDesc()
			if desc and desc.category == 4 and self.rewards.structure then
				local name = object:getName()
				local foundInBuilt = false
				local isCritical = false
		
				for _, zone in ipairs(self.zones or {}) do
					if zone.built then
						for _, builtName in pairs(zone.built) do
							if builtName == name then
								foundInBuilt = true
								break
							end
						end
					end
		
					if foundInBuilt then
						if zone.criticalObjects then
							for _, critName in ipairs(zone.criticalObjects) do
								if critName == name then
									isCritical = true
									break
								end
							end
						end
						break
					end
				end
		
				if not foundInBuilt or isCritical then
					earning = nil
					message = nil
					statname = nil
				else
					earning = self.rewards.structure
					message = 'Structure kill +'..earning..' credits'
					statname = 'Structer'
				end
			end
		else
			return -- object does not have any of the attributes
		end
		return earning,message,statname
	end
	
	function BattleCommander:update()
		for i,v in ipairs(self.zones) do
			v:update()
			
		end
		
		for i,v in ipairs(self.monitorROE) do
			self:checkROE(v)
		end
		
		if self.difficulty then
			if timer.getAbsTime()-self.lastDiffChange > self.difficulty.fadeTime then
				self:decreaseDifficulty()
			end
		end
	end
	
	function BattleCommander:saveToDisk()
    local statedata = self:getStateTable()
    
	statedata.customFlags = CustomFlags
	
    -- Modify getStateTable to include wasBlue in the zone data
    for i, v in pairs(self.zones) do
        statedata.zones[v.zone].wasBlue = v.wasBlue or false
    end
    
    Utils.saveTable(self.saveFile, 'zonePersistance', statedata)
	end
end

function BattleCommander:loadFromDisk()
    Utils.loadTable(self.saveFile)
    if zonePersistance then
        if zonePersistance.zones then
            for i, v in pairs(zonePersistance.zones) do
                local zn = self:getZoneByName(i)
                if zn then
                    zn.side = v.side
                    zn.level = v.level
                    
                    if v.remainingUnits then
                        zn.remainingUnits = v.remainingUnits
                    end
                    
                    if type(v.active) == 'boolean' then
                        zn.active = v.active
                    end
                    
                    if not zn.active then
                        zn.side = 0
                        zn.level = 0
                    end
                    
                    if v.destroyed then
                        zn.destroyOnInit = v.destroyed
                    end
                    
                    if v.triggers then
                        for i2, v2 in ipairs(zn.triggers) do
                            local tr = v.triggers[v2.id]
                            if tr then
                                v2.hasRun = tr
                            end
                        end
                    end
                    
                    zn.wasBlue = v.wasBlue or false

                    zn.firstCaptureByRed = v.firstCaptureByRed or false 
                end
            end
        end
        
        if zonePersistance.accounts then
            self.accounts = zonePersistance.accounts
        end
        
		if zonePersistance.shops then
			for sideIndex, sideData in pairs(zonePersistance.shops) do
				for itemId, savedItem in pairs(sideData) do
					local existingItem = self.shops[sideIndex][itemId]
					if existingItem then
						if existingItem.stock ~= -1 then
							if savedItem.stock ~= -1 then
								existingItem.stock = savedItem.stock
							end
						end
					else
						if savedItem.stock ~= -1 then
							local def = self.shopItems[itemId]
							if def then
								self.shops[sideIndex][itemId] = {
									name  = def.name,
									cost  = def.cost,
									stock = savedItem.stock
								}
							end
						end
					end
				end
			end
		end
        
        if zonePersistance.difficultyModifier then
            self.difficultyModifier = zonePersistance.difficultyModifier
            if self.difficulty then
                GlobalSettings.setDifficultyScaling(self.difficulty.start + self.difficultyModifier, self.difficulty.coalition)
            end
        end
        
        if zonePersistance.playerStats then
            self.playerStats = zonePersistance.playerStats
        end
		
		if zonePersistance.customFlags then
            CustomFlags = zonePersistance.customFlags
        end
    end
end



ZoneCommander = {}
do
	--{ zone='zonename', side=[0=neutral, 1=red, 2=blue], level=int, upgrades={red={}, blue={}}, crates={}, flavourtext=string, income=number }
	function ZoneCommander:new(obj)
		obj = obj or {}
		obj.built = {}
		obj.index = -1
		obj.battleCommander = {}
		obj.groups = {}
		obj.restrictedGroups = {}
		obj.criticalObjects = {}
		obj.active = true
		obj.destroyOnInit = {}
		obj.triggers = {}
		
		
	if obj.side ~= 0 then
		obj.firstCaptureByRed = true

	end
		
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	

	
	function ZoneCommander:getFilteredUpgrades()
																								
		local upgrades
		if self.side == 1 then
			upgrades = self.upgrades.red
		elseif self.side == 2 then
			upgrades = self.upgrades.blue
		else
			upgrades = {}
		end

		if UseStatics then return upgrades end
	
		local res = {}
		for idx, name in pairs(upgrades) do
			local isStatic = false
			if self.newStatics then
				for _, data in ipairs(self.newStatics) do
					if data.name == name then
						isStatic = true
						break
					end
				end
			end
	
			if isStatic then
				local st = StaticObject.getByName(name)
				if st and st:isExist() then st:destroy() end
			else
				res[idx] = name
			end
		end
		return res
	end
	

	function ZoneCommander:addRestrictedPlayerGroup(groupinfo)
		table.insert(self.restrictedGroups, groupinfo)
	end
	
	function ZoneCommander:markWithSmoke(requestingCoalition)
		if requestingCoalition and (self.side ~= requestingCoalition and self.side ~= 0) then
			return
		end
	
		local zone = CustomZone:getByName(self.zone)
		local p = Utils.getPointOnSurface(zone.point)
		trigger.action.smoke(p, 0)
	end
	
	--if all critical onjects are lost in a zone, that zone turns neutral and can never be recaptured
	function ZoneCommander:addCriticalObject(staticname)
		table.insert(self.criticalObjects, staticname)
	end
	
	function ZoneCommander:getDestroyedCriticalObjects()
		local destroyed = {}
		for i,v in ipairs(self.criticalObjects) do
			local st = StaticObject.getByName(v)
			if not st or st:getLife()<1 then
				table.insert(destroyed, v)
			end
		end
		
		return destroyed
	end
	
	--zone triggers 
	-- trigger types= captured, upgraded, repaired, lost, destroyed
	function ZoneCommander:registerTrigger(eventType, action, id, timesToRun)
		table.insert(self.triggers, {eventType = eventType, action = action, id = id, timesToRun = timesToRun, hasRun=0})
	end
	
	--return true from eventhandler to end event after run
	function ZoneCommander:runTriggers(eventType)
		for i,v in ipairs(self.triggers) do
			if v.eventType == eventType then
				if not v.timesToRun or v.hasRun < v.timesToRun then
					v.action(v,self)
					v.hasRun = v.hasRun + 1
				end
			end
		end
	end
	--end zone triggers
	-------------------------------------------------------- DISABLE FRIENDLY ZONE ---------------------------------------------------------------------------

	function ZoneCommander:disableFriendlyZone(force)
		if not force then	
			if not self.active or not self.wasBlue then return false end
		end
		if (self.active and self.side == 2) or force then
			self.wasBlue = true
			print("Zone was blue before disabling: " .. self.zone)

			for i, v in pairs(self.built) do
				local gr = Group.getByName(v)
				if gr and gr:getSize() > 0 then
					gr:destroy()
				elseif gr and gr:getSize() == 0 then
					gr:destroy()
				end

				if not gr then
					local st = StaticObject.getByName(v)
					if st and st:getLife() < 1 then
						st:destroy()
					end
				end

				self.built[i] = nil    
			end

			self.side = 0
			self.active = false
			
			if self.airbaseName then
				env.info("Disabling airbase " .. self.airbaseName)
				local ab = Airbase.getByName(self.airbaseName)
				if ab then
					if self.wasBlue and not self.active then
							ab:setCoalition(2)
						if	RespawnStaticsForAirbase then
							RespawnStaticsForAirbase(self.airbaseName, 2)
						end
					end
				else
					env.info("Airbase " .. self.airbaseName .. " is not found")
				end
			end
			if self.wasBlue and not self.active then
				trigger.action.setMarkupColor(2000 + self.index, {0, 0, 0.7, 1})
				trigger.action.setMarkupColorFill(self.index, {0, 0, 1, 0.3})
				trigger.action.setMarkupColor(self.index, {0, 0, 1, 0.3})
				
				if self.isHeloSpawn then
					trigger.action.setMarkupTypeLine(self.index, 2)
					trigger.action.setMarkupColor(self.index, {0, 1, 0, 1})
				end
			end
			
			self:runTriggers('FriendlyDestroyed')
		end
	end

	function ZoneCommander:DestroyHiddenZone()
	if not self.active or not self.side == 1 then return false end
		print("Destroying Hidden zone" .. self.zone)

		for i, v in pairs(self.built) do
			local gr = Group.getByName(v)
			if gr and gr:getSize() > 0 then
				gr:destroy()
			elseif gr and gr:getSize() == 0 then
				gr:destroy()
			end

			if not gr then
				local st = StaticObject.getByName(v)
				if st and st:getLife() < 1 then
					st:destroy()
				end
			end

			self.built[i] = nil    
		end

		self.side = 0
		self.active = false
	end

	function ZoneCommander:disableZone()
    if self.active then
        if self.side == 2 then
            self.wasBlue = true
        elseif self.side == 1 then
            self.wasBlue = false
        else
            self.wasBlue = false
        end

        for i, v in pairs(self.built) do
            local gr = Group.getByName(v)
            if gr and gr:getSize() == 0 then
                gr:destroy()
            end
            if not gr then
                local st = StaticObject.getByName(v)
                if st and st:getLife() < 1 then
                    st:destroy()
                end
            end
            self.built[i] = nil    
        end

        self.side = 0
		if CheckJtacStatus then
			CheckJtacStatus()
		end
        self.active = false
		
		if SpawnFriendlyAssets then
		
			SCHEDULER:New(nil,SpawnFriendlyAssets,{},5,0)
		end
        if GlobalSettings.messages.disabled then
            trigger.action.outText(self.zone .. ' has been destroyed', 5)
			if trigger.misc.getUserFlag(180) == 0 then
				trigger.action.outSoundForCoalition(2, "ding.ogg")
			end
		end
		if not self.active then
			trigger.action.setMarkupColor(2000 + self.index, {0.1,0.1,0.1,1})
			trigger.action.setMarkupColorFill(self.index, {0.1,0.1,0.1,0.3})
			trigger.action.setMarkupColor(self.index, {0.1,0.1,0.1,0.3})
		end
		self:runTriggers('destroyed')
		self.battleCommander:drawSupplyArrows()		
		if DestroyStatic then
			SCHEDULER:New(nil,DestroyStatic,{},5,0)
		end       
    end
end
	
intelActiveZones = intelActiveZones or {}

function ZoneCommander:displayStatus(grouptoshow, messagetimeout, overrideIntel)
    local upgrades=0
    local sidename='Neutral'
    if self.side==1 then
        sidename='Red'
        upgrades = #self:getFilteredUpgrades()
    elseif self.side==2 then
        sidename='Blue'
        upgrades = #self:getFilteredUpgrades()
    end
    if not self.active then
        sidename='None'
    end
    if not self.active and self.wasBlue then
        sidename='Blue'
    end
    local count=0
    if self.built then
        count=Utils.getTableSize(self.built)
    end
    local status=self.zone.." status\n Controlled by: "..sidename
    local isEnemy=(self.side==1)
    local intelActive=(intelActiveZones[self.zone]==true)
    local jtacActive=(jtacIntelActive and jtacIntelActive[self.zone]==true)
    local canSeeEnemy=intelActive or jtacActive
    if overrideIntel and isEnemy then
        canSeeEnemy=true
    end
    if isEnemy and bc.shops and bc.shops[2] and bc.shops[2].intel then
        if canSeeEnemy and self.built and count>0 then
            status=status.."\n Upgrades: "..count.."/"..upgrades
            status=status.."\n Groups:"
            for i,v in pairs(self.built) do
                local gr=Group.getByName(v)
                if gr then
                    local grhealth=math.ceil((gr:getSize()/gr:getInitialSize())*100)
                    grhealth=math.min(grhealth,100)
                    grhealth=math.max(grhealth,1)
                    status=status.."\n  "..v.." "..grhealth.."%"
                else
                    local st=StaticObject.getByName(v)
                    if st then
                        status=status.."\n  "..v.." 100%"
                    end
                end
            end
        else
            status=status.."\n\nBuy intel or deploy a JTAC to gather information on enemy units."
        end
    else
        if self.built and count>0 then
            status=status.."\n Upgrades: "..count.."/"..upgrades
            status=status.."\n Groups:"
            for i,v in pairs(self.built) do
                local gr=Group.getByName(v)
                if gr then
                    local grhealth=math.ceil((gr:getSize()/gr:getInitialSize())*100)
                    grhealth=math.min(grhealth,100)
                    grhealth=math.max(grhealth,1)
                    status=status.."\n  "..v.." "..grhealth.."%"
                else
                    local st=StaticObject.getByName(v)
                    if st then
                        status=status.."\n  "..v.." 100%"
                    end
                end
            end
        end
    end
    if self.flavorText and self.active then
        status=status.."\n\n"..self.flavorText
    end
    if not self.active and not self.wasBlue then
        status=status.."\n\n WARNING: This zone has been irreparably damaged and is no longer of any use"
    end
    if not self.active and self.wasBlue then
        status=status.."\n\nFriendly zone. All units have repositioned near the front line."
        if self.isHeloSpawn then
            status=status.."\n\nFarp/Airfield is operational."
        end
    end
    local zn=CustomZone:getByName(self.zone)
	if zn then
		local pnt      = zn.point
		local c        = COORDINATE:NewFromVec3(pnt)
		local lat, lon = coord.LOtoLL(pnt)

		local function ddm(v,h)
			local d = math.floor(math.abs(v))
			local m = (math.abs(v) - d) * 60
			return string.format("[%s %02d %06.3f']", h, d, m)
		end
		local function dms(v,h)
			local av = math.abs(v)
			local d  = math.floor(av)
			local m  = math.floor((av - d) * 60)
			local s  = ((av - d) * 60 - m) * 60
			return string.format("[%s %02d %02d' %05.2f\"]", h, d, m, s)
		end

		local ddmStr = ddm(lat, lat >= 0 and "N" or "S") .. "⇢ " .. ddm(lon, lon >= 0 and "E" or "W")
		local dmsStr = dms(lat, lat >= 0 and "N" or "S") .. "⇢ " .. dms(lon, lon >= 0 and "E" or "W")
		local mgrs   = c:ToStringMGRS():gsub("^MGRS%s*", "")
		local alt    = c:GetLandHeight()

		status = status
			.. "\n\nDDM:  " .. ddmStr
			.. "\nDMS:  " .. dmsStr
			.. "\nMGRS: " .. mgrs
			.. "\n\nAlt: " .. math.floor(alt) .. "m | " .. math.floor(alt * 3.280839895) .. "ft"
	end
	local timeout = messagetimeout or 15
	if grouptoshow then
		trigger.action.outTextForGroup(grouptoshow, status, timeout)
	else
		trigger.action.outText(status, timeout)
	end
end


---------------------- Capture a zone on command BLUE ---------------------------------

function ZoneCommander:MakeZoneBlue()
	if not self.active or self.wasBlue then return
	end
    if self.active and not self.wasBlue then
        BASE:I("Making this zone Blue: " .. self.zone)
        local unitsInZone = coalition.getGroups(1)
        for _, group in ipairs(unitsInZone) do
            local groupUnits = group:getUnits()
            for _, unit in ipairs(groupUnits) do
                if Utils.isInZone(unit, self.zone) then
                    unit:destroy()
                end
            end
        end
        timer.scheduleFunction(function()
            self:capture(2,true)
            BASE:I("Zone captured by Blue: " .. self.zone)
			self.wasBlue = true
        end, nil, timer.getTime() + 12)
    else
        BASE:I("Zone is either inactive or not controlled by the blue side, no action taken.")
    end
	
end

function ZoneCommander:MakeZoneRed()
    if self.active and self.side == 0 and self.NeutralAtStart and not self.firstCaptureByRed then
        BASE:I("Making this zone Red: " .. self.zone)

        timer.scheduleFunction(function()
            self:capture(1, true)
            BASE:I("Zone captured by Red: " .. self.zone)
        end, {}, timer.getTime() + 2)
    else
        BASE:I("Zone is either inactive or not eligible for red capture, no action taken.")
    end
	
end
---------------------- Capture a zone on command RED ---------------------------------      
function ZoneCommander:MakeZoneRedAndUpgrade()
    if self.active and self.side==0 and self.NeutralAtStart and not self.firstCaptureByRed then
        self:capture(1,true)
        local upgrades=self:getFilteredUpgrades()
        local totalUpgrades=#upgrades
               local function upgradeZone()
            local builtNow=Utils.getTableSize(self.built)
            if builtNow<totalUpgrades then
                self:upgrade(true)
                builtNow=Utils.getTableSize(self.built)
                timer.scheduleFunction(upgradeZone,{},timer.getTime()+2)
            end
        end
        timer.scheduleFunction(upgradeZone,{},timer.getTime()+1)
    else
        BASE:I("Zone is either inactive or not eligible for red capture and upgrade, no action taken.")
    end
	
end

------------------------ UPGRADE RED ZONE ON COMMAND ------------------------------------

function ZoneCommander:MakeRedZoneUpgraded()
    if self.active and self.side==1 then
        local upgrades=self:getFilteredUpgrades()
        local totalUpgrades=#upgrades
        local function upgradeZone()
            local builtNow=Utils.getTableSize(self.built)
            if builtNow<totalUpgrades then
                self:upgrade(true)

                builtNow=Utils.getTableSize(self.built)
                BASE:I("Zone upgraded "..builtNow.."/"..totalUpgrades.." for Red: "..self.zone)
                timer.scheduleFunction(upgradeZone,{},timer.getTime()+2)
            else
                BASE:I("Zone fully upgraded for Red: "..self.zone)
            end
        end
        timer.scheduleFunction(upgradeZone,{},timer.getTime()+1)
    else
        BASE:I("Zone is either inactive or not Red, no action taken.")
    end
end

---------------------- End of Capture a zone on command ---------------------------------
function ZoneCommander:MakeZoneNeutralAgain()
    if not self.active or self.wasBlue then
        return
    end

	self:killAll()

    timer.scheduleFunction(function()
        self.firstCaptureByRed = false
        BASE:I("Zone " .. self.zone .. " has been reset to neutral.")
    end, nil, timer.getTime() + 5)
end
-------------------------- RECAPTURE BLUE ZONE FROM DISABLED STATE ---------------------      
	function ZoneCommander:RecaptureBlueZone()
		env.info("Recapturing Blue zone: " .. self.zone)
	if self.active then
		BASE:I("Zone is already active: " .. self.zone)
		return
	end
		self.active = true
	timer.scheduleFunction(function()
		
		self:capture(2,true)
		
		BASE:I("Zone: " .. self.zone .. " is now active again")

	end, {}, timer.getTime() + 2)
	
end


-------------------------- RECAPTURE BLUE ZONE FROM DISABLED STATE ---------------------
function ZoneCommander:MakeZoneRed()
    if self.active and self.side == 0 and self.NeutralAtStart and not self.firstCaptureByRed then
        BASE:I("Making this zone Red: " .. self.zone)

        timer.scheduleFunction(function()
            self:capture(1, true)
            BASE:I("Zone captured by Red: " .. self.zone)
        end, {}, timer.getTime() + 2)
    else
        BASE:I("Zone is either inactive or not eligible for red capture, no action taken.")
    end
	
end
-------------------------------- maxxa --------------------------------------------------------


function ZoneCommander:MakeZoneSideAndUpgraded()
    if self.active and self.side~=0 then
        self:capture(self.side, true)
		local upgrades=self:getFilteredUpgrades()
        local totalUpgrades=#upgrades
        local sideText=(self.side==1) and "Red" or "Blue"
        BASE:I("Zone captured by "..sideText..": "..self.zone.." ("..Utils.getTableSize(self.built).."/"..totalUpgrades..")")
        local function upgradeZone()
            local builtNow=Utils.getTableSize(self.built)
            if builtNow<totalUpgrades then
                self:upgrade(true)
                builtNow=Utils.getTableSize(self.built)
                timer.scheduleFunction(upgradeZone,{},timer.getTime()+2)
            else
                BASE:I("Zone fully upgraded for "..sideText..": "..self.zone)
            end
        end
        timer.scheduleFunction(upgradeZone,{},timer.getTime()+1)
    end
	
end

function ZoneCommander:init()
	local zone = CustomZone:getByName(self.zone)
	if not zone then
		trigger.action.outText('ERROR: zone ['..self.zone..'] cannot be found in the mission', 60)
		env.info('ERROR: zone ['..self.zone..'] cannot be found in the mission')
	end

	local color = {0.7, 0.7, 0.7, 0.3}
	local textColor = {0.3, 0.3, 0.3, 1}
	if self.side == 1 then
		color = {1, 0, 0, 0.3}
		textColor = {0.7, 0, 0, 0.8}
	elseif self.side == 2 then
		color = {0, 0, 1, 0.3}
		textColor = {0, 0, 0.7, 0.8}
		self.wasBlue = true
	elseif self.side == 0 and self.wasBlue then
		color = {0, 0, 1, 0.3}
		textColor = {0, 0, 0.7, 1}
	end

	if not self.active then
		if self.wasBlue then
			color = {0, 0, 1, 0.3}
			textColor = {0, 0, 0.7, 0.8}
		else
			color = {0.1, 0.1, 0.1, 0.3}
			textColor = {0.1, 0.1, 0.1, 1}
		end
	end

	zone:draw(self.index, color, color)

	local point = zone.point
	if zone:isCircle() then
		point = { x = zone.point.x, y = zone.point.y, z = zone.point.z + zone.radius }
	elseif zone:isQuad() then
		local largestZ = zone.vertices[1].z
		local largestX = zone.vertices[1].x
		for i = 2, 4 do
			if zone.vertices[i].z > largestZ then
				largestZ = zone.vertices[i].z
				largestX = zone.vertices[i].x
			end
		end
		point = { x = largestX, y = zone.point.y, z = largestZ }
	end
	if WaypointList and not self.zone:lower():find("hidden") then
		local waypointLabel = WaypointList[self.zone] or ""
		local msg = " " .. self.zone .. "" .. waypointLabel
		local backgroundColor = {0.7, 0.7, 0.7, 0.8}
		trigger.action.textToAll(-1, 2000 + self.index, point, textColor, backgroundColor, 18, true, msg)
		trigger.action.setMarkupText(2000 + self.index, msg)
	end
	if self.side == 2 and self.isHeloSpawn then
		trigger.action.setMarkupTypeLine(self.index, 2)
		trigger.action.setMarkupColor(self.index, {0,1,0,1})
	end
	if self.wasBlue and not self.active and self.isHeloSpawn then
		trigger.action.setMarkupTypeLine(self.index, 2)
		trigger.action.setMarkupColor(self.index, {0,1,0,1})
	end
	if self.airbaseName then
		timer.scheduleFunction(function()
			local ab = Airbase.getByName(self.airbaseName)
			if ab then
				if ab:autoCaptureIsOn() then ab:autoCapture(false) end
				if not self.active and not self.wasBlue then
					if RespawnStaticsForAirbase then
						RespawnStaticsForAirbase(self.airbaseName, 1)						
					end
					ab:setCoalition(0)
				end
				if self.side == 0 or self.side == 1 then
					if RespawnStaticsForAirbase then
						RespawnStaticsForAirbase(self.airbaseName, 1)		
					end
					ab:setCoalition(1)
				end
				if self.wasBlue then
					if RespawnStaticsForAirbase then
						RespawnStaticsForAirbase(self.airbaseName, 2)
					end
					ab:setCoalition(2)	
				end
			else
				env.info("Airbase " .. self.airbaseName .. " not found")
			end
		end, {}, timer.getTime() +3)
	end

	local upgrades = self:getFilteredUpgrades()

	if self.remainingUnits then
		for i, v in pairs(self.remainingUnits) do
			if not self.built[i] then
				local upg = upgrades[i]
				if not upg then
					--env.info(string.format("[ZoneCommander DEBUG] zone '%s', index '%s' -> 'upgrades[%s]' is nil! leftoverUnits=%s", self.zone, i, i, mist.utils.tableShow(v)))
					--trigger.action.outText(string.format("[ZoneCommander DEBUG] zone '%s', index '%s' -> 'upgrades[%s]' is nil! leftoverUnits=%s", self.zone, i, i, mist.utils.tableShow(v)), 10)
				else
					local staticObj = StaticObject.getByName(upg)
					if staticObj then
						if UseStatics then
							self.built[i] = upg
						end
					else
						if not tostring(upg):find("dismounted") then
						local gr = zone:spawnGroup(upg, false)
						self.built[i] = gr.name
						end
					end
				end
			end
		end
	else
		if Utils.getTableSize(self.built) < self.level then
			for i, v in pairs(upgrades) do
				if not self.built[i] and i <= self.level then
					local staticObj = StaticObject.getByName(v)
					if staticObj then
						if UseStatics then
							self.built[i] = v
						end
					else
						if not tostring(v):find("dismounted") then
							local gr = zone:spawnGroup(v, false)
							if not gr then
								env.info("zoneCommander DEBUG: spawnGroup returned nil for zone ["..self.zone.."] upgrade index "..tostring(i).." name="..(v or "nil"))
							else
								self.built[i] = gr.name
							end
						end
					end
				end
			end
		end
	end
	

		local allUpgrades = {}
		if self.upgrades.red then
			for i, v in pairs(self.upgrades.red) do
				allUpgrades[v] = true
			end
		end
		for v, _ in pairs(allUpgrades) do
			local staticObj = STATIC:FindByName(v, false)
			if staticObj then
				if not self.newStatics then self.newStatics = {} end
				local point = staticObj:GetPointVec3()
				local desc = staticObj:GetDesc()
				local shapeName = desc and desc.shapeName
				local typeName  = staticObj:GetTypeName()
				if typeName == ".Command Center" then
					shapeName = shapeName or "ComCenter"
				end
				if typeName == ".Ammunition depot" then
					shapeName = shapeName or "SkladC"
				end
				--env.info("[ZoneCommander DEBUG] For "..v.." type="..typeName.." shape="..(shapeName or "nil"))
				table.insert(self.newStatics, {
					name = v,
					point = point,
					type = typeName,
					heading = staticObj:GetHeading(),
					country = staticObj:GetCoalition(),
					shapeName = shapeName,
				})
				--env.info("[ZoneCommander DEBUG] Stored static "..v)
			end
		end

	self:weedOutRemainingUnits()
	for i, v in ipairs(self.restrictedGroups) do
		trigger.action.setUserFlag(v.name, v.side ~= self.side)
	end
	for i, v in ipairs(self.groups) do
		v:init()
	end
end


	function ZoneCommander:weedOutRemainingUnits()
		local destroyPersistedUnits = function(context)
			if context.remainingUnits then
				for i2, v2 in pairs(context.built) do
					local bgr = Group.getByName(v2)
					if bgr then
						local need = {}
						if context.remainingUnits[i2] then
							for _, t in ipairs(context.remainingUnits[i2]) do
								need[t] = (need[t] or 0) + 1
							end
						end

						for i3, v3 in ipairs(bgr:getUnits()) do
							local budesc = v3:getDesc()
							if need[budesc.typeName] and need[budesc.typeName] > 0 then
								need[budesc.typeName] = need[budesc.typeName] - 1
							else
								v3:destroy()
							end
						end
					end
				end
			end
			if context.newStatics then
				for _, v4 in ipairs(context.newStatics) do
					local staticName = type(v4) == "table" and v4.name or v4
					local st = StaticObject.getByName(staticName)
					if st and st:isExist() then
						local foundInBuilt = false
						for _, builtName in pairs(context.built) do
							if builtName == staticName then
								foundInBuilt = true
								break
							end
						end
						if not foundInBuilt then
							st:destroy()
						end
					end
				end
			end
		end
		
		SCHEDULER:New(nil,destroyPersistedUnits,{self},3,0)
		SCHEDULER:New(nil, destroyPersistedUnits, {self},6,0)
	end


	
	function ZoneCommander:checkCriticalObjects()
		if not self.active then
			return
		end
		
		local stillactive = false
		if self.criticalObjects and #self.criticalObjects > 0 then
			for i,v in ipairs(self.criticalObjects) do
				local st = StaticObject.getByName(v)
				if st and st:getLife()>1 then
					stillactive = true
				end
				
				--clean up statics that still exist for some reason even though they're dead
				if st and st:getLife()<1 then
					st:destroy()
				end
			end
		else
			stillactive = true
		end
		
		if not stillactive then
			self:disableZone()
		end
	end
	
function ZoneCommander:update()
    self:checkCriticalObjects()

		for i,v in pairs(self.built) do
			local gr = Group.getByName(v)
			local st = StaticObject.getByName(v)
			if gr and gr:getSize() == 0 then
				gr:destroy()
			end
			
			if not gr then
				if st and st:getLife()<1 then
					st:destroy()
				end
			end

			if not gr and not st then
				self.built[i] = nil
				if GlobalSettings.messages.grouplost then trigger.action.outText(self.zone..' lost group '..v, 5) end
			end		
			
			if gr and gr:getSize() == 0 then
				self.built[i] = nil
				if GlobalSettings.messages.grouplost then trigger.action.outText(self.zone..' lost group '..v, 5) end
			end	
			
			if st and st:getLife()<1 then
				self.built[i] = nil
				if GlobalSettings.messages.grouplost then trigger.action.outText(self.zone..' lost group '..v, 5) end
			end	
		
        end
		local empty = true
		for i,v in pairs(self.built) do
			if v then
				empty = false
				break
			end
		end

    if empty and self.side ~= 0 and self.active and not self.isRailwaySubzone then



        if self.battleCommander.difficulty and self.side == self.battleCommander.difficulty.coalition then
            self.battleCommander:increaseDifficulty()           
		end
		self.side = 0
		self.wasBlue = false
        self:runTriggers('lost')
		bc:buildConnectionMap()
		bc:buildConnectionSupplyMap()
		buildCapControlMenu()	
		self.battleCommander:drawSupplyArrows()	
		--self.battleCommander:drawSupplyArrows()	
		local cz = CustomZone:getByName(self.zone)
		if cz then cz:clearUsedSpawnZones(self.zone) end
		self.battleCommander:buildZoneStatusMenuForGroup()
		if self.airbaseName then
			local ab = Airbase.getByName(self.airbaseName)
			if ab then
				BattleCommander:_buildHunterBaseList()
				local currentCoalition = ab:getCoalition()
				if currentCoalition ~= coalition.side.RED then
					if RespawnStaticsForAirbase then
					RespawnStaticsForAirbase(self.airbaseName, coalition.side.RED)
					end
					ab:setCoalition(coalition.side.RED)
				end
			end
		end	
		if self.active and GlobalSettings.messages.zonelost and not self.zone:lower():find("hidden") then
			trigger.action.outText(self.zone .. ' is now neutral ', 15)
			if trigger.misc.getUserFlag(180) == 0 then
				trigger.action.outSoundForCoalition(2, "ding.ogg")
			end
		end
        if self.active then
            trigger.action.setMarkupColor(2000 + self.index, {0.3, 0.3, 0.3, 1})
            trigger.action.setMarkupColorFill(self.index, {0.7, 0.7, 0.7, 0.3})
            trigger.action.setMarkupColor(self.index, {0.7, 0.7, 0.7, 0.3})
        end
		
		if CaptureZoneIfNeutral then
			CaptureZoneIfNeutral()
		end
		if CheckJtacStatus then
			CheckJtacStatus()
		end
	
		if addCTLDZonesForBlueControlled then
			addCTLDZonesForBlueControlled(self.zone)
		end
		if SpawnFriendlyAssets then
			SCHEDULER:New(nil,SpawnFriendlyAssets,{},2,0)
		end
		if synchronizeRailwaySubzones then
			synchronizeRailwaySubzones()
		end
		
    end

    for i, v in ipairs(self.groups) do
        v:update()
    end

    if self.crates then
        for i, v in ipairs(self.crates) do
            local crate = StaticObject.getByName(v)
            if crate and Utils.isCrateSettledInZone(crate, self.zone) then
                if self.side == 0 then
                    self:capture(crate:getCoalition())
                    if self.battleCommander.playerRewardsOn then
                        self.battleCommander:addFunds(self.side, self.battleCommander.rewards.crate)
                        trigger.action.outTextForCoalition(self.side, 'Capture +' .. self.battleCommander.rewards.crate .. ' credits', 5)
                    end
                elseif self.side == crate:getCoalition() then
                    if self.battleCommander.playerRewardsOn then
                        if self:canRecieveSupply() then
                            self.battleCommander:addFunds(self.side, self.battleCommander.rewards.crate)
                            trigger.action.outTextForCoalition(self.side, 'Resupply +' .. self.battleCommander.rewards.crate .. ' credits', 5)
                        else
                            local reward = self.battleCommander.rewards.crate * 0.25
                            self.battleCommander:addFunds(self.side, reward)
                            trigger.action.outTextForCoalition(self.side, 'Resupply +' .. reward .. ' credits (-75% due to no demand)', 5)
                        end
                    end
                    self:upgrade()
                end
				
                crate:destroy()
            end
        end
    end

    for i, v in ipairs(self.restrictedGroups) do
        trigger.action.setUserFlag(v.name, v.side ~= self.side)
    end

    if self.income and self.side ~= 0 and self.active then
        self.battleCommander:addFunds(self.side, self.income)
    end
end

	
	function ZoneCommander:addGroup(group)
		table.insert(self.groups, group)
		group.zoneCommander = self
	end
	
	function ZoneCommander:addGroups(groups)
		for i,v in ipairs(groups) do
			table.insert(self.groups, v)
			v.zoneCommander = self
			
		end
	end
	
	function ZoneCommander:killAll()
		for i,v in pairs(self.built) do
			local gr = GROUP:FindByName(v)
			if gr then
				gr:Destroy()
			else
				local st = StaticObject.getByName(v)
				if st then
					st:destroy()
				end
			end
		end
	end
	

	
function ZoneCommander:capture(newside,silent)
    if self.active and self.side == 0 and newside ~= 0 then
        self.side = newside
		self.battleCommander:buildZoneStatusMenuForGroup()
        local sidename = ''
        local color = {0.7,0.7,0.7,0.3}
        local textcolor = {0.7,0.7,0.7,0.3}
        self.wasBlue = false
		
        trigger.action.setMarkupColor(2000 + self.index, textcolor)

        if self.side == 1 then
            sidename = 'RED'
            color = {1,0,0,0.3}
            textcolor = {0.7,0,0,0.8}
            self.wasBlue = false
			
            if self.NeutralAtStart and not self.firstCaptureByRed then
                self.firstCaptureByRed = true
																			 
            end

        elseif self.side == 2 then
            sidename = 'BLUE'
            color = {0,0,1,0.3}
            textcolor = {0,0,0.7,0.8}
            self.wasBlue = true
	end
		
		if SpawnFriendlyAssets then
			SCHEDULER:New(nil,SpawnFriendlyAssets,{},5,0)	
		end
		if addCTLDZonesForBlueControlled then
			addCTLDZonesForBlueControlled(self.zone)
		end
        trigger.action.setMarkupColor(2000 + self.index, textcolor)
        trigger.action.setMarkupColorFill(self.index, color)
        trigger.action.setMarkupColor(self.index, color)
        self:runTriggers('captured')
		
		-- Synchronize railway subzones when parent zones are captured
		if synchronizeRailwaySubzones then
			synchronizeRailwaySubzones()
		end
		
		bc:buildConnectionMap()
		bc:buildConnectionSupplyMap()
		self.battleCommander:drawSupplyArrows()
		
		if checkAndDisableFriendlyZones then
			checkAndDisableFriendlyZones()
		end
		if not silent then
			if GlobalSettings.messages.captured and self.active then 
            	trigger.action.outText(self.zone .. ' captured by ' .. sidename, 20)
        	elseif GlobalSettings.messages.captured and not self.active and self.wasBlue then 
           	 	trigger.action.outText(self.zone .. ' captured by BLUE\n\nZone is now disabled due to progress, great job!', 20)
			end
		end
		
		if self.active then
			if not silent then
				self:upgrade()
			else
				self:upgrade(true)
			end
		end
		
        if self.wasBlue and self.isHeloSpawn then
            trigger.action.setMarkupTypeLine(self.index, 2)
            trigger.action.setMarkupColor(self.index, {0, 1, 0, 1})
        end  
			if self.airbaseName then
				local ab = Airbase.getByName(self.airbaseName)
				if ab then

					if self.wasBlue then
						self.side = 2
					end
					ab:setCoalition(self.side)
					if RespawnStaticsForAirbase then
					RespawnStaticsForAirbase(self.airbaseName, self.side)
					end
					local baseCaptureEvent = {
						id = world.event.S_EVENT_BASE_CAPTURED,
						initiator = ab,
						place = ab,
						coalition = self.side,
					}
					world.onEvent(baseCaptureEvent)
					BattleCommander:_buildHunterBaseList()
				end
			end
		local isUrgent = type(self.urgent) == "function" and self.urgent() or self.urgent
		
        for _, v in ipairs(self.groups) do
		if v.state == 'inhangar' or v.state == 'dead' then
			 if isUrgent then
					self.lastStateTime = timer.getAbsTime() + 30
				else
					self.lastStateTime = timer.getAbsTime() + math.random(60, GlobalSettings.initialDelayVariance * 60) 
				end
			end
		end

        if self.battleCommander.difficulty and newside == self.battleCommander.difficulty.coalition then
            self.battleCommander:decreaseDifficulty()
        end
    end
	if not silent then		
		if not self.active and not self.wasBlue then
			if GlobalSettings.messages.disabled then
				trigger.action.outText(self.zone..' has been destroyed and can no longer be captured',10)
				SCHEDULER:New(nil,function()
					trigger.action.setMarkupColor(2000 + self.index, {0.1, 0.1, 0.1, 1})
				end,{},0.5,0)
			end
		end
	end
end

	
function ZoneCommander:canRecieveSupply()
    if not self.active then
        --env.info(self.zone .. " is not active, cannot receive supply.")
        return false
    end

    if self.side == 0 then 
        --env.info(self.zone .. " is neutral, can receive supply.")
        return true
    end

    local uncapturedZones = self.battleCommander:buildUncapturedZonesTable()
    if self.firstCaptureByRed and #uncapturedZones > 0 then
        --env.info(self.zone .. " is already captured, and there are uncaptured zones remaining. Supply blocked.")
        return false
    end

	local upgrades = self:getFilteredUpgrades()

	for i, v in pairs(self.built) do
		if not string.find(v, "dismounted") then
			local gr = Group.getByName(v)
			if gr and gr:getSize() < gr:getInitialSize() then
				return true
			end
		end
	end

    if Utils.getTableSize(self.built) < #upgrades then
        --env.info(self.zone .. " has available upgrades. Supply allowed.")
        return true
    end

    --env.info(self.zone .. " is fully upgraded and repaired. Supply blocked.")
    return false
end

	function ZoneCommander:clearWreckage()
		 local zn = trigger.misc.getZone(self.zone)
		 local pos =  {
		x = zn.point.x, 
		y = land.getHeight({x = zn.point.x, y = zn.point.z}), 
		z= zn.point.z
		}
		local radius = zn.radius
		world.removeJunk({id = world.VolumeType.SPHERE,params = {point = pos ,radius = radius}})
	end
	
function ZoneCommander:upgrade(silent)
	if self.active and self.side ~= 0 then
		local zone = CustomZone:getByName(self.zone)
		local upgrades       = self:getFilteredUpgrades()
		local totalUpgrades  = #upgrades
		local function calculateUpgradeCount()
			local fullyRepairedGroups = {}
			for i,v in pairs(self.built) do
				success = false
				local gr = Group.getByName(v)
				if gr then
					local allUnitsRepaired = true
					for _,u in ipairs(gr:getUnits()) do
						if u and u:isExist() then
							if u:getLife() < u:getLife0() then
								allUnitsRepaired = false
								break
							end
						end
					end
					if allUnitsRepaired and gr:getSize() == gr:getInitialSize() then
						table.insert(fullyRepairedGroups,gr)
					end
				end
			end
			return #fullyRepairedGroups
		end
		local upgradeCount = calculateUpgradeCount()
		local repaired     = false
		local success    = false
		for i,v in pairs(self.built) do
			if not string.find(v,"dismounted") then
				local gr = GROUP:FindByName(v)
				if gr then	
					if gr:GetSize() and gr:GetInitialSize() then
						if gr:GetSize() < gr:GetInitialSize() then
							CustomRespawn(v)
							success = true
						end
					else
						zone:spawnGroup(v,false)
						success = true
					end
				end
			if success then
				if not silent then
					if GlobalSettings.messages.repaired then
						if self.side == 1 then
							trigger.action.outText(self.zone..' has been repaired',10)
						else
							trigger.action.outText('Group '..v..' at '..self.zone..' was repaired',10)
						end
					end
				end
				self:runTriggers('repaired')
				self:clearWreckage()
				self.battleCommander:drawSupplyArrows()
				repaired = true
				break
			end
		 end
		end
		if not repaired and upgradeCount == totalUpgrades then
			if self.side == 2 and not silent then
				trigger.action.outText(self.zone..' is already fully upgraded!',10)
			end
			return false
		end
		if not repaired and Utils.getTableSize(self.built) < #upgrades then
			local zone = CustomZone:getByName(self.zone)
			for i,v in pairs(upgrades) do
				if not self.built[i] then
					local isStatic = false
					local stData   = nil
					for _,data in ipairs(self.newStatics or {}) do
						if data.name == v then
							isStatic = true
							stData   = data
							break
						end
					end
					if isStatic and stData then
						if stData.country == 1 then
							stData.country = country.id.RUSSIA
						else
							stData.country = country.id.USA
						end
						local spawnTemplate = {
							name       = stData.name,
							type       = stData.type,
							country    = stData.country,
							shape_name = stData.shapeName,
							heading    = math.rad(stData.heading),
							position   = stData.point
						}
						local spawnStatic = SPAWNSTATIC:NewFromTemplate(spawnTemplate,stData.country)
						local spawnedObject = spawnStatic:SpawnFromCoordinate(COORDINATE:NewFromVec3(stData.point))
						self.built[i] = spawnedObject:GetName()
					else
						local gr   = zone:spawnGroup(v,false)
						self.built[i] = gr.name
					end
					SCHEDULER:New(nil,function()
						upgradeCount = calculateUpgradeCount()
						if self.side == 2 then
							if GlobalSettings.messages.upgraded and not silent then
								trigger.action.outText(self.zone..' upgraded '..upgradeCount..'/'..totalUpgrades,10)
							end
						else
							if not silent then
								if GlobalSettings.messages.upgraded then
									trigger.action.outText(self.zone..' defenses upgraded',10)
								end
							end
						end
					end,{},0.3,0)
					self:runTriggers('upgraded')
					self:clearWreckage()
					break
				end
			end
		end
		return true
	end
	if not self.active then
		if GlobalSettings.messages.disabled and not silent then
			trigger.action.outText(self.zone..' has been destroyed and can no longer be upgraded',10)
		end
	end
	return false
end
end
GroupCommander = {}
do
	--{ name='groupname', mission=['patrol', 'supply', 'attack'], targetzone='zonename', type=['air','carrier_air','surface'] }
function GroupCommander:new(obj)
    obj = obj or {}
    
	obj.diceChance = obj.diceChance or 0
	
    if not obj.type then
        obj.type = 'air'
    end
	obj.Era = obj.Era

    obj.state = 'inhangar' 
    obj.lastStateTime = timer.getAbsTime()
    obj.zoneCommander = {}
    obj.landsatcarrier = obj.type == 'carrier_air'
    obj.side = 0
    

    
    obj.condition = obj.condition or function() return true end

    
    obj.urgent = obj.urgent or false

    setmetatable(obj, self)
    self.__index = self
    return obj
end
	
function GroupCommander:init()
    self.state = 'inhangar'


	local isUrgent = type(self.urgent) == "function" and self.urgent() or self.urgent

    if isUrgent then
        self.lastStateTime = timer.getAbsTime() + 20
    else
        self.lastStateTime = timer.getAbsTime() + math.random(1, GlobalSettings.initialDelayVariance * 60) 
    end


    local gr = Group.getByName(self.name)
    if gr then
        self.side = gr:getCoalition()
        gr:destroy()
    else
        trigger.action.outText('ERROR: group ['..self.name..'] can not be found in the mission', 60)
        env.info('ERROR: group ['..self.name..'] can not be found in the mission')
    end
end

function BattleCommander:buildUncapturedZonesTable()
    local uncapturedZones = {}

    for _, zone in pairs(self.zones) do
        if zone.firstCaptureByRed == false and zone.condition and zone.condition() then
            table.insert(uncapturedZones, zone)
        end
    end

    return uncapturedZones
end

playerList = {}
function getBluePlayersCount()
    local cnt = 0
    for _ in pairs(playerList) do
        cnt = cnt + 1
    end
    return cnt
end

function refreshPlayers()
    local b = coalition.getPlayers(coalition.side.BLUE)
    local current = {}
    for _, unit in ipairs(b) do
        local nm = unit:getPlayerName()
        if nm then
            local desc = unit:getDesc()
            if desc and desc.category == Unit.Category.AIRPLANE then
				if unit:getTypeName() ~= "A-10C_2" and unit:getTypeName() ~= "Hercules" and unit:getTypeName() ~= "A-10A" and unit:getTypeName() ~= "AV8BNA" then
					current[nm] = true
				end
            end
        end
    end
    for storedName in pairs(playerList) do
        if not current[storedName] then
            playerList[storedName] = nil
        end
    end
    for newName in pairs(current) do
        playerList[newName] = true
    end
end

SCHEDULER:New(nil,refreshPlayers,{},10,60)

function getCapLimit(numPlayers)
    if numPlayers == 0 then
        return 1
    elseif numPlayers == 1 then
        return 2
	elseif numPlayers == 2 then
        return 4
    elseif numPlayers == 3 then
        return 5
    else
        return 99999
    end
end

function BattleCommander:getActiveCAPCount(side, missionType)
    local count = 0
    for _, zoneCom in ipairs(self.zones) do
        for _, groupCom in ipairs(zoneCom.groups) do
            if groupCom.side == side and groupCom.MissionType == 'CAP' then
                if missionType then
                    if groupCom.mission == missionType then
                        if groupCom.state == 'takeoff' or groupCom.state == 'inair' then
                            count = count + 1
                        end
                    end
                else
                    if groupCom.state == 'takeoff' or groupCom.state == 'inair' then
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

DebugIsOn = true


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
		elseif limit == 5 then
			capTargetPlanes = math.random(3,6)
		elseif limit == 99999 then
			capTargetPlanes = math.random(3,6)
		end
		capMissionTarget = "Active"
	end
end

function getClosestCapZonesToPlayers(missionType)
	local zoneSide = 0
	if missionType == 'patrol' then
		zoneSide = 1
	elseif missionType == 'attack' then
		zoneSide = 2
	end

	local anchors = {}
	for _, spawnZoneName in pairs(playerZoneSpawn) do
		local spawnZC = bc:getZoneByName(spawnZoneName)
		if spawnZC then
			table.insert(anchors, { zoneName = spawnZC.zone })
		end
	end
	if #anchors == 0 then
		for _, z in ipairs(bc.zones) do
			if z.side == 2 and z.active then
				local cz = CustomZone:getByName(z.zone)
				if cz then
					table.insert(anchors, { zoneName = z.zone })
				end
			end
		end
	end
	if #anchors == 0 then
		return {}
	end

	local zoneDistances = {}
	for _, zoneCom in ipairs(bc.zones) do
		if zoneCom.side == zoneSide and zoneCom.active then
			for _, groupCom in ipairs(zoneCom.groups) do
				if groupCom.MissionType == 'CAP' then
					local realTgtZoneName = groupCom.targetzone
					local tCZ = CustomZone:getByName(realTgtZoneName)
					if tCZ then
						local sumDist = 0
						local znB = realTgtZoneName
						for _, p in ipairs(anchors) do
							local znA = p.zoneName
							local dist = ZONE_DISTANCES[znA] and ZONE_DISTANCES[znA][znB] or 99999999
							sumDist = sumDist + dist
						end
						local avgDist = sumDist / #anchors
						table.insert(zoneDistances, { zone = realTgtZoneName, distance = avgDist })
					end
				end
			end
		end
	end

	table.sort(zoneDistances, function(a, b)
		return a.distance < b.distance
	end)

	return zoneDistances
end

-- Helper function to find GroupCommander by name
function findGroupCommander(groupName)
    for _, zone in ipairs(bc.zones) do
        for _, commander in ipairs(zone.groups) do
            if commander.name == groupName then
                return commander
            end
        end
    end
    return nil
end

--[[ Separate core spawn logic from coordination
function GroupCommander:baseSpawnCheck()
    if Era and self.Era and self.mission ~= 'supply' and self.Era ~= Era then
        return false
    end
    if not self.zoneCommander.active then
        return false
    end
    if self.side ~= self.zoneCommander.side then
        return false
    end
    if self.condition and not self.condition() then
        return false
    end
    return true
end
--]]
function GroupCommander:shouldSpawn()
    --[[ Attack+Escort coordination with debug logging
    if self.mission == 'attack' then
        local escortName = self.name .. '-escort'
        local escortCommander = findGroupCommander(escortName)
        if escortCommander then
            env.info("[ESCORT DEBUG] Attack group " .. self.name .. " found escort " .. escortName)
            local attackReady = self:baseSpawnCheck()
            local escortReady = escortCommander:baseSpawnCheck()
            env.info("[ESCORT DEBUG] Attack ready: " .. tostring(attackReady) .. ", Escort ready: " .. tostring(escortReady))
           -- return attackReady and escortReady
			return self:baseSpawnCheck() and escortCommander:baseSpawnCheck()
        else
            env.info("[ESCORT DEBUG] Attack group " .. self.name .. " - no escort found with name " .. escortName)
            -- Fall through to normal logic if no escort found
        end
    end
    
    if self.mission == 'escort' then
        local attackName = self.name:gsub('-escort$', '')
        local attackCommander = findGroupCommander(attackName)
        if attackCommander then
            env.info("[ESCORT DEBUG] Escort group " .. self.name .. " found attack " .. attackName)
            local escortReady = self:baseSpawnCheck()
            local attackReady = attackCommander:baseSpawnCheck()
            env.info("[ESCORT DEBUG] Escort ready: " .. tostring(escortReady) .. ", Attack ready: " .. tostring(attackReady))
            return self:baseSpawnCheck() and attackCommander:baseSpawnCheck()
        else
            env.info("[ESCORT DEBUG] Escort group " .. self.name .. " - no attack found with name " .. attackName)
            -- Fall through to normal logic if no attack found
        end
    end
--]]    
    -- Default behavior for other missions - use existing logic
if Era and self.Era and self.mission ~= 'supply' and self.Era ~= Era then
        return false
    end
    if not self.zoneCommander.active then
        return false
    end
    if self.side ~= self.zoneCommander.side then
        return false
    end
    if self.condition and not self.condition() then
        return false
    end

    local isUrgent = type(self.urgent) == "function" and self.urgent() or self.urgent
    local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)

    if tg and tg.active then
        if self.mission == 'supply' then
            if tg.side == 0 and (not tg.firstCaptureByRed or self.ForceUrgent) then
                if isUrgent then
                    return true
                end
            end
            if tg.side == self.side or tg.side == 0 then
                self.urgent = false
                return tg:canRecieveSupply()
            end
        end
--[[		if self.mission == 'attack' then
			local escortName = self.name .. '-escort'
			local escortCommander = findGroupCommander(escortName)
			if escortCommander then
				env.info("[ESCORT DEBUG] Attack group " .. self.name .. " found escort " .. escortName)
				local attackReady = self:baseSpawnCheck()
				local escortReady = escortCommander:baseSpawnCheck()
				env.info("[ESCORT DEBUG] Attack ready: " .. tostring(attackReady) .. ", Escort ready: " .. tostring(escortReady))
			return attackReady and escortReady
				--return self:baseSpawnCheck() and escortCommander:baseSpawnCheck()
			else
				env.info("[ESCORT DEBUG] Attack group " .. self.name .. " - no escort found with name " .. escortName)
				-- Fall through to normal logic if no escort found
			end
		end
		
		if self.mission == 'escort' then
			local attackName = self.name:gsub('-escort$', '')
			local attackCommander = findGroupCommander(attackName)
			if attackCommander then
				env.info("[ESCORT DEBUG] Escort group " .. self.name .. " found attack " .. attackName)
				local escortReady = self:baseSpawnCheck()
				local attackReady = attackCommander:baseSpawnCheck()
				env.info("[ESCORT DEBUG] Escort ready: " .. tostring(escortReady) .. ", Attack ready: " .. tostring(attackReady))
			return attackReady and escortReady
				--return self:baseSpawnCheck() and attackCommander:baseSpawnCheck()
			else
				env.info("[ESCORT DEBUG] Escort group " .. self.name .. " - no attack found with name " .. attackName)
				-- Fall through to normal logic if no attack found
			end
		end
--]]
        if (self.mission == 'patrol') and (self.MissionType == 'CAP') then
            if tg.side == self.side then
                local totalPlayers = getBluePlayersCount()
                local limit = getCapLimit(totalPlayers)
                local currentCap = self.zoneCommander.battleCommander:getActiveCAPCount(self.side, 'patrol')

				if limit == 99999 or limit == 4 then
                    return true
                end

                if currentCap >= limit then
                    if DebugIsOn then
                        env.info(string.format("[DEBUG] CAP patrol limit reached: currentCap=%d, limit=%d, mission=%s",
                            currentCap, limit, self.name))
                    end
                    self.state = 'inhangar'
                    self.lastStateTime = timer.getAbsTime() + math.random(60, 1800)
                    return false
                end

                local zoneDistances = getClosestCapZonesToPlayers('patrol')
                local capLeft = limit - currentCap
                if capLeft < 1 then capLeft = 1 end
                local allowedZones = {}
                for i = 1, #zoneDistances do
                    if i > capLeft then
                        break
                    end
                    table.insert(allowedZones, zoneDistances[i].zone)
                end
                local isInAllowedList = false
                for _, zName in ipairs(allowedZones) do
                    if zName == tg.zone then
                        isInAllowedList = true
                        break
                    end
                end
                if not isInAllowedList then
                    if DebugIsOn then
                        env.info(string.format("[DEBUG] CAP patrol is not within the top %d zones; skipping spawn: mission=%s",
                            capLeft, self.name))
                    end
					self.state = 'inhangar'
                    self.lastStateTime = timer.getAbsTime() + math.random(90, 180)
                    return false
                end
                if DebugIsOn then
                    env.info(string.format("[DEBUG] CAP patrol spawn allowed at zone=%s, mission=%s", tg.zone, self.name))
                end
                return true
            end
            return false
        end

        if (self.mission == 'patrol') and not (self.MissionType == 'CAP') then
            if tg.side == self.side then
                return true
            end
        end

        if (self.mission == 'attack') and (self.MissionType == 'CAP') then
            if tg.side ~= self.side and tg.side ~= 0 then
                local totalPlayers = getBluePlayersCount()
                local limit = getCapLimit(totalPlayers)
                local currentCap = self.zoneCommander.battleCommander:getActiveCAPCount(self.side, 'attack')

				if limit == 99999 or limit == 4 then
                    return true
                end

                if currentCap >= limit then
                    if DebugIsOn then
                        env.info(string.format("[DEBUG] CAP attack limit reached: currentCap=%d, limit=%d, mission=%s",
                            currentCap, limit, self.name))
                    end
                    self.state = 'inhangar'
					self.lastStateTime = timer.getAbsTime() + math.random(90, 180)
                    return false
                end

--[[                 if totalPlayers == 0 then
                    if DebugIsOn then
                        env.info(string.format("[DEBUG] No players, but limit=%d, currentCap=%d;  OK to spawn: mission=%s",
                            limit, currentCap, self.name))
                    end
                    return true
                end ]]

                local zoneDistances = getClosestCapZonesToPlayers('attack')
                local capLeft = limit - currentCap
                if capLeft < 1 then capLeft = 1 end
                local allowedZones = {}
                for i = 1, #zoneDistances do
                    if i > capLeft then
                        break
                    end
                    table.insert(allowedZones, zoneDistances[i].zone)
                end
                local isInAllowedList = false
                for _, zName in ipairs(allowedZones) do
                    if zName == tg.zone then
                        isInAllowedList = true
                        break
                    end
                end
                if not isInAllowedList then
                    if DebugIsOn then
                        env.info(string.format("[DEBUG] attack CAP is not within the top %d zones; skipping spawn: mission=%s",
                            capLeft, self.name))
                    end
					self.state = 'inhangar'
                    self.lastStateTime = timer.getAbsTime() + math.random(90, 180)
                    return false
                end
                env.info(string.format("[DEBUG] CAP attack spawn allowed at zone=%s, mission=%s", tg.zone, self.name))
                return true
            end
        end

        if (self.mission == 'attack') and not (self.MissionType == 'CAP') then
            if tg.side ~= self.side and tg.side ~= 0 then
                return true
            end
        end
        return false
    end
    return false
end

	function GroupCommander:clearWreckage()
		local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
		tg:clearWreckage()
	end

function GroupCommander:_jtacMessage(txt, instant, z)
    z = z or self.targetzone or (self.zoneCommander and self.zoneCommander.zone)
    if not z then return end
    for _,v in ipairs(jtacQueue or {}) do
        if v.tgtzone and v.tgtzone.zone == z then
            if instant then
                trigger.action.outTextForCoalition(2, txt..' '..z, 25)
            else
                timer.scheduleFunction(
                    function() trigger.action.outTextForCoalition(2, txt..' '..z, 25) end,
                    {}, timer.getTime() + math.random(30,60)
                )
            end
            break
        end
    end
end

function GroupCommander:_getAirType()
	local gr = Group.getByName(self.name)
	if gr then
		local u = gr:getUnit(1)
		if u then
			local d = u:getDesc()
			if d and d.attributes and d.attributes.Helicopters then
				return 'helicopter'
			end
		end
	end
	return 'plane'
end
	
function GroupCommander:processAir()
	local originZone = self.zoneCommander and self.zoneCommander.zone
    local gr = Group.getByName(self.name)
    local coalition = self.side
    local isUrgent = type(self.urgent) == "function" and self.urgent() or self.urgent
    local respawnTimers = isUrgent and GlobalSettings.urgentRespawnTimers or GlobalSettings.respawnTimers[coalition][self.mission]
    local spawnDelayFactor = self.spawnDelayFactor or 1
	if self.mission == 'supply' and not isUrgent then
		local pc = getBluePlayersCount()
		if pc == 0 then
			spawnDelayFactor = spawnDelayFactor * 2
		elseif pc == 1 then
			spawnDelayFactor = spawnDelayFactor * 1.5
		end
		--env.info(string.format("[SUPPLY_DELAY] players=%d factor=%.2f mission=%s", pc, spawnDelayFactor, self.name))
	end
    if not gr or gr:getSize() == 0 then
        if gr and gr:getSize() == 0 then
            gr:destroy()
        end

        if self.state ~= 'inhangar' and self.state ~= 'preparing' and self.state ~= 'dead' then
            self.state = 'dead'
            self.lastStateTime = timer.getAbsTime()
        end
    end

    if self.state == 'inhangar' then
        if timer.getAbsTime() - self.lastStateTime > (respawnTimers.hangar * spawnDelayFactor) then
            if self.diceChance and self.diceChance > 0 and not self.diceRolled then
                self.diceRolled = true
                local roll = math.random(1, 100)
                if roll > self.diceChance then
                    --env.info("Group [" .. self.name .. "] dice roll = " .. roll .. " > " .. self.diceChance .. ", skipping spawn")
                    self.state = 'dead'               -- move to dead
                    self.lastStateTime = timer.getAbsTime()
                    self.diceRolled = false           -- reset so we can roll again later
                    return
                else
                    --env.info("Group [" .. self.name .. "] dice roll = " .. roll .. " <= " .. self.diceChance .. ", proceeding to spawn")
                end
            end

            if self:shouldSpawn() then
                self.state = 'preparing'
                self.lastStateTime = timer.getAbsTime()
            end
        end
    elseif self.state == 'preparing' then
        if timer.getAbsTime() - self.lastStateTime > (respawnTimers.preparing * spawnDelayFactor) then
            if self:shouldSpawn() then
                if isUrgent then
                    env.info("Group [" .. self.name .. "] is spawning urgently!")
                else
                    env.info("Group [" .. self.name .. "] is spawning normally.")
                end
                
                self:clearWreckage()
				Respawn.Group(self.name)
				local tp = self:_getAirType()
				self:_jtacMessage('JTAC: We spotted enemy '..tp..' starting up at', nil, originZone)
				self._zonePinged = nil
                self.state = 'takeoff'
                self.lastStateTime = timer.getAbsTime()
            end
        end
    elseif self.state == 'takeoff' then
        if timer.getAbsTime() - self.lastStateTime > GlobalSettings.blockedDespawnTime then
            if gr and Utils.allGroupIsLanded(gr, self.landsatcarrier) then
                gr:destroy()
                self.state = 'inhangar'
                self.lastStateTime = timer.getAbsTime()
            end
	elseif gr and Utils.someOfGroupInAir(gr) then
		local tp = self:_getAirType()
		self:_jtacMessage('JTAC: enemy '..tp..' just took off from', true, originZone)
		self.state = 'inair'
		self.lastStateTime = timer.getAbsTime()
        end
	elseif self.state=='inair' and self.mission=='supply' and not self._zonePinged then
		local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
		if tg and gr and Utils.someOfGroupInZone(gr, tg.zone) then
			local tp = self:_getAirType()
			self:_jtacMessage('JTAC: Have eyes on enemy '..tp..' inbound and about to land at',true,tg.zone)
			self._zonePinged = true
		end	
    elseif self.state == 'inair' then
        if gr and Utils.allGroupIsLanded(gr, self.landsatcarrier) then
            self.state = 'landed'
            self.lastStateTime = timer.getAbsTime()
        end
	--[[
	elseif self.state == 'inair' then
    -- NEW: Automatic bombing task assignment for attack missions
		if self.mission == 'attack' and not self._bombingTaskAssigned then
			local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
			if tg and gr and gr:isExist() and gr:getSize() > 0 then
				-- Mark as assigned to prevent repeated calls
				self._bombingTaskAssigned = true
				
				-- Use engageZone for precise targeting (you can change this to carpetBombRandomUnitInZone if preferred)
				--self.zoneCommander.battleCommander:engageZone(self.targetzone, self.name, AI.Task.WeaponExpend.ALL)
				self.zoneCommander.battleCommander:carpetBombRandomUnitInZone(self.targetzone, self.name)

				
				env.info("Bombing task assigned to: " .. self.name .. " targeting: " .. self.targetzone)
			end
		end
    --]]
    -- Existing landing check
		if gr and Utils.allGroupIsLanded(gr, self.landsatcarrier) then
			self.state = 'landed'
			self.lastStateTime = timer.getAbsTime()
		end

    elseif self.state == 'landed' then
        if self.mission == 'supply' then
            local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
            if tg and gr and Utils.someOfGroupInZone(gr, tg.zone) then
				self.state         = 'inhangar'
				self.lastStateTime = timer.getAbsTime()
				if tg.side == 0 then
					tg:capture(self.side)
				elseif tg.side == self.side then
					tg:upgrade()
				end
				SCHEDULER:New(nil,function()
					gr:destroy()
				end,{},0.3,0)
			end
		end
        if timer.getAbsTime() - self.lastStateTime > GlobalSettings.landedDespawnTime then
            if gr then
                gr:destroy()
                self.state = 'inhangar'
                self.lastStateTime = timer.getAbsTime()
            end
        end
    elseif self.state == 'dead' then
	--	self._bombingTaskAssigned = false
        if timer.getAbsTime() - self.lastStateTime > (respawnTimers.dead * spawnDelayFactor) then
            if self:shouldSpawn() then
                self.state = 'preparing'
                self.lastStateTime = timer.getAbsTime()
            end
        end
    end
end

	
	function GroupCommander:processSurface()
		local originZone = self.zoneCommander and self.zoneCommander.zone
		local gr = Group.getByName(self.name)
		local coalition = self.side
		local isUrgent = type(self.urgent) == "function" and self.urgent() or self.urgent
		local respawnTimers = isUrgent and GlobalSettings.urgentRespawnTimers or GlobalSettings.respawnTimers[coalition][self.mission]
		local spawnDelayFactor = self.spawnDelayFactor or 1
		if self.mission == 'supply' and not isUrgent then
			local pc = getBluePlayersCount()
			if pc == 0 then
				spawnDelayFactor = spawnDelayFactor * 1.5
			elseif pc == 1 then
				spawnDelayFactor = spawnDelayFactor * 1.1
			end
			--env.info(string.format("[SUPPLY_DELAY] players=%d factor=%.2f mission=%s", pc, spawnDelayFactor, self.name))
		end

		if not gr or gr:getSize() == 0 then
			if gr and gr:getSize() == 0 then
				gr:destroy()
			end

			if self.state ~= 'inhangar' and self.state ~= 'preparing' and self.state ~= 'dead' then
				self.state = 'dead'
				self.lastStateTime = timer.getAbsTime()
			end
		end

   		 if self.state == 'inhangar' then
			if timer.getAbsTime() - self.lastStateTime > (respawnTimers.hangar * spawnDelayFactor) then
				if self.diceChance and self.diceChance > 0 and not self.diceRolled then
					self.diceRolled = true
					local roll = math.random(1, 100)
					if roll > self.diceChance then
						self.state = 'dead'
						self.lastStateTime = timer.getAbsTime()
						self.diceRolled = false
						return
					end
				end
            if self:shouldSpawn() then
                self.state = 'preparing'
                self.lastStateTime = timer.getAbsTime()
            end
        end
		elseif self.state == 'preparing' then
			if timer.getAbsTime() - self.lastStateTime > (respawnTimers.preparing * spawnDelayFactor) then
				if self:shouldSpawn() then
					if isUrgent then
						env.info("Group [" .. self.name .. "] is spawning urgently!")
					else
						env.info("Group [" .. self.name .. "] is spawning normally.")
					end
					self:clearWreckage()
					Respawn.Group(self.name)
					self:_jtacMessage('JTAC: We spotted enemy convoy headed outside',nil,originZone)
					self.state = 'enroute'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		elseif self.state == 'enroute' then
			local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
			if tg and gr and Utils.someOfGroupInZone(gr, tg.zone) then
				self.state = 'atdestination'
				self.lastStateTime = timer.getAbsTime()
			end
		elseif self.state == 'atdestination' then
			if self.mission == 'supply' then
				if timer.getAbsTime() - self.lastStateTime > GlobalSettings.landedDespawnTime then
					local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
					if tg and gr and Utils.someOfGroupInZone(gr, tg.zone) then
						self.state         = 'inhangar'
						self.lastStateTime = timer.getAbsTime()
						if tg.side == 0 then
							SCHEDULER:New(nil,function()
							tg:capture(self.side)
							end,{},0.3,0)
						elseif tg.side == self.side then
							tg:upgrade()
						end
						gr:destroy()
					end
				end
		elseif self.mission == 'attack' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.landedDespawnTime then
				local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
				if tg and gr and Utils.someOfGroupInZone(gr, tg.zone) then
					if tg.side == 0 then
						tg:capture(self.side)
						gr:destroy()
						self.state = 'inhangar'
						self.lastStateTime = timer.getAbsTime()
					end
				end
			end
		end
		elseif self.state == 'dead' then
			if timer.getAbsTime() - self.lastStateTime > (respawnTimers.dead * spawnDelayFactor) then
				if self:shouldSpawn() then
					self.state = 'preparing'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		end
	end

	function GroupCommander:update()
		if self.type == 'air' or self.type == 'carrier_air' then
			self:processAir()
		elseif self.type == 'surface' then
			self:processSurface()
		end
	end
end

BudgetCommander = {}
do
	--{ battleCommander = object, side=coalition, decissionFrequency=seconds, decissionVariance=seconds, skipChance=percent}
	function BudgetCommander:new(obj)
		obj = obj or {}
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function BudgetCommander:update()
		local budget = self.battleCommander.accounts[self.side]
		local options = self.battleCommander.shops[self.side]
		local canAfford = {}
		for i,v in pairs(options) do
			if v.cost<=budget and (v.stock==-1 or v.stock>0) then
				table.insert(canAfford, i)
			end
		end
		
		local dice = math.random(1,100)
		if dice > self.skipChance then
			for i=1,10,1 do
				local choice = math.random(1, #canAfford)
				local err = self.battleCommander:buyShopItem(self.side, canAfford[choice])
				if not err then
					break
				else
					canAfford[choice]=nil
				end
			end
		end
	end
	
	function BudgetCommander:scheduleDecission()
		local variance = math.random(1, self.decissionVariance)
		SCHEDULER:New(nil,self.update,{self},variance,0)
	end
	
	function BudgetCommander:init()
		SCHEDULER:New(nil,self.scheduleDecission,{self},self.decissionFrequency,self.decissionFrequency)
	end
end

EventCommander = {}
do
	--{ decissionFrequency=seconds, decissionVariance=seconds, skipChance=percent}
	function EventCommander:new(obj)
		obj = obj or {}
		obj.events = {}
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function EventCommander:addEvent(event)--{id=string, action=function, canExecute=function}
		table.insert(self.events, event)
	end
	
	function EventCommander:triggerEvent(id)
		for _,v in ipairs(self.events) do
			if v.id == id and v:canExecute() then
				v:action()
				break
			end
		end
	end
	
	function EventCommander:chooseAndStart(time)
		local canRun = {}
		for i,v in ipairs(self.events) do
			if v:canExecute() then
				table.insert(canRun, v)
			end
		end
		
		if #canRun == 0 then return end
		
		local dice = math.random(1,100)
		if dice > self.skipChance then
			local choice = math.random(1, #canRun)
			local err = canRun[choice]:action()
		end
	end
	
	function EventCommander:scheduleDecission(time)
		local variance = math.random(1, self.decissionVariance)
		timer.scheduleFunction(self.chooseAndStart, self, time + variance)
		return time + self.decissionFrequency + variance
	end
	
	function EventCommander:init()
		timer.scheduleFunction(self.scheduleDecission, self, timer.getTime() + self.decissionFrequency)
	end
end

LogisticCommander = {}
do
	LogisticCommander.allowedTypes = {}
	LogisticCommander.allowedTypes['P-51D-30-NA'] = true
	LogisticCommander.allowedTypes['SpitfireLFMkIX'] = true
	LogisticCommander.allowedTypes['MosquitoFBMkVI'] = true
	LogisticCommander.allowedTypes['Bf-109K-4'] = true
	LogisticCommander.allowedTypes['FW-190A8'] = true
	LogisticCommander.allowedTypes['FW-190D9'] = true
	LogisticCommander.allowedTypes['F4U-1D'] = true
	LogisticCommander.allowedTypes['F4U-1D_CW'] = true
	LogisticCommander.allowedTypes['I-16'] = true
	LogisticCommander.allowedTypes['P-47D-30'] = true
	LogisticCommander.allowedTypes['P-47D-30bl1'] = true
	LogisticCommander.allowedTypes['P-47D-40'] = true
	LogisticCommander.allowedTypes['P-51D'] = true
	LogisticCommander.allowedTypes['SpitfireLFMkIXCW'] = true
	
	
	LogisticCommander.maxCarriedPilots = 4
	
	--{ battleCommander = object, supplyZones = { 'zone1', 'zone2'...}}
	function LogisticCommander:new(obj)
		obj = obj or {}
		obj.groupMenus = {} -- groupid = path
		obj.statsMenus = {}
		obj.carriedCargo = {} -- groupid = source
		obj.ejectedPilots = {}
		obj.carriedPilots = {} -- groupid = count
		obj.carriedPilotData = {}
		
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
end
	function LogisticCommander:loadSupplies(groupName)
	local gr = Group.getByName(groupName)
	if gr then
		local un = gr:getUnit(1)
		if un then
			if Utils.isInAir(un) then
				trigger.action.outTextForGroup(gr:getID(), 'Cannot load supplies while in air', 10)
				return
			end
			local zn = self.battleCommander:getZoneOfUnit(un:getName())
			if not zn then
				local carrierUnit
				if IsGroupActive("CVN-72") then
					carrierUnit = Unit.getByName("CVN-72")
				elseif IsGroupActive("CVN-73") then
					carrierUnit = Unit.getByName("CVN-73")
				end

				if carrierUnit then
					local carrierPos = carrierUnit:getPoint()
					local playerPos = un:getPoint()
					if COORDINATE:NewFromVec3(carrierPos):Get2DDistance(playerPos)<200 then
						self.carriedCargo[gr:getID()] = carrierUnit:getName()  -- Dynamically sets the carrier's name
						trigger.action.setUnitInternalCargo(un:getName(), 100)
						trigger.action.outTextForGroup(gr:getID(), 'Supplies loaded from the carrier', 20)
						return
					end
				else
					local gWrap = GROUP:FindByName(groupName)
					if gWrap then
						for _, zName in ipairs(self.supplyZones) do
							if string.find(zName, "CTLD FARP") then
								local zObj = ZONE:FindByName(zName)
								if zObj and gWrap:IsInZone(zObj) then
									self.carriedCargo[gr:getID()] = zName
									trigger.action.setUnitInternalCargo(un:getName(), 100)
									trigger.action.outTextForGroup(gr:getID(), 'Supplies loaded', 20)
									return
								end
							end
						end
					end
				end
				trigger.action.outTextForGroup(gr:getID(), 'Can only load supplies while within a friendly supply zone or on the carrier', 10)
				return
			end
			if zn.side ~= un:getCoalition() and not zn.wasBlue then
				trigger.action.outTextForGroup(gr:getID(), 'Can only load supplies while within a friendly supply zone', 10)
				return
			end
			if self.carriedCargo[gr:getID()] then
				if type(self.carriedCargo[gr:getID()]) == "string" and self.carriedCargo[gr:getID()] == "CVN-72" then
					trigger.action.outTextForGroup(gr:getID(), 'Supplies already loaded from the carrier', 10)
				else
					trigger.action.outTextForGroup(gr:getID(), 'Supplies already loaded', 10)
				end
				return
			end
			for i, v in ipairs(self.supplyZones) do
				if v == zn.zone then
					self.carriedCargo[gr:getID()] = zn.zone
					trigger.action.setUnitInternalCargo(un:getName(), 100)
					trigger.action.outTextForGroup(gr:getID(), 'Supplies loaded', 20)
					return
				end
			end
			trigger.action.outTextForGroup(gr:getID(), 'Can only load supplies while within a friendly supply zone', 10)
			return
		end
	end
end

	function LogisticCommander:unloadSupplies(groupName)
		local gr = Group.getByName(groupName)
		if gr then
			local un = gr:getUnit(1)
			if un then
				if Utils.isInAir(un) then
					trigger.action.outTextForGroup(gr:getID(), 'Can not unload supplies while in air', 10)
					return
				end
				
				local zn = self.battleCommander:getZoneOfUnit(un:getName())
				if not zn then
					local gWrap = GROUP:FindByName(groupName)
					if gWrap then
						for _, zName in ipairs(self.supplyZones) do
							if string.find(zName, "CTLD FARP") then
								local zObj = ZONE:FindByName(zName)
								if zObj and gWrap:IsInZone(zObj) then
									if not self.carriedCargo[gr:getID()] then
										trigger.action.outTextForGroup(gr:getID(), 'No supplies loaded', 10)
										return
									end
									self.carriedCargo[gr:getID()] = nil
									trigger.action.setUnitInternalCargo(un:getName(), 0)
									trigger.action.outTextForGroup(gr:getID(), 'Supplies unloaded', 10)
									return
								end
							end
						end
					end
					trigger.action.outTextForGroup(gr:getID(), 'Can only unload supplies while within a friendly or neutral zone', 10)
					return
				end
				
				if not(zn.side == un:getCoalition() or zn.side == 0)then
					trigger.action.outTextForGroup(gr:getID(), 'Can only unload supplies while within a friendly or neutral zone', 10)
					return
				end
				
				if not self.carriedCargo[gr:getID()] then
					trigger.action.outTextForGroup(gr:getID(), 'No supplies loaded', 10)
					return
				end
				
				trigger.action.outTextForGroup(gr:getID(), 'Supplies unloaded', 10)
				if self.carriedCargo[gr:getID()] ~= zn.zone then
					if zn.side == 0 and zn.active then 
						if self.battleCommander.playerRewardsOn then
							self.battleCommander:addFunds(un:getCoalition(), self.battleCommander.rewards.crate)
							trigger.action.outTextForCoalition(un:getCoalition(),'Capture +'..self.battleCommander.rewards.crate..' credits',10)
						end
							zn:capture(un:getCoalition())
						SCHEDULER:New(nil,function()
							if zn.wasBlue and un:isExist() then
							local landingEvent = {
								id = world.event.S_EVENT_LAND,
								time = timer.getAbsTime(),
								initiator = un,
								initiatorPilotName = un:getPlayerName(),
								initiator_unit_type = un:getTypeName(),
								initiator_coalition = un:getCoalition(),
							}
							
								world.onEvent(landingEvent)
							end
						end,{},5,0)
					elseif zn.side == un:getCoalition() then
						if self.battleCommander.playerRewardsOn then
							if zn:canRecieveSupply() then
								self.battleCommander:addFunds(un:getCoalition(), self.battleCommander.rewards.crate)
								trigger.action.outTextForCoalition(un:getCoalition(),'Resupply +'..self.battleCommander.rewards.crate..' credits',5)
							else
								local reward = self.battleCommander.rewards.crate * 0.25
								self.battleCommander:addFunds(un:getCoalition(), reward)
								trigger.action.outTextForCoalition(un:getCoalition(),'Resupply +'..reward..' credits (-75% due to no demand)',5)
							end
						end
						
						zn:upgrade()
					end
				end
				
				self.carriedCargo[gr:getID()] = nil
				trigger.action.setUnitInternalCargo(un:getName(), 0)
				return
			end
		end
	end
	

	
	function LogisticCommander:listSupplyZones(groupName)
		local gr = Group.getByName(groupName)
		if gr then
			local msg = 'Friendly supply zones:'
			for i,v in ipairs(self.supplyZones) do
				local z = self.battleCommander:getZoneByName(v)
				if z and z.side == gr:getCoalition() then
					msg = msg..'\n'..v
				end
			end
			
			trigger.action.outTextForGroup(gr:getID(), msg, 15)
		end
	end

	function LogisticCommander:loadPilot(groupname)
		local gr=Group.getByName(groupname)
		local groupid=gr:getID()
		if gr then
			local un=gr:getUnit(1)
			if Utils.getAGL(un)>50 then
				trigger.action.outTextForGroup(groupid,"You are too high",15)
				return
			end
			if UTILS.VecNorm(un:getVelocity()) > 5 then
				trigger.action.outTextForGroup(groupid,"You are moving too fast",15)
				return
			end
			if self.carriedPilots[groupid]>=LogisticCommander.maxCarriedPilots then
				trigger.action.outTextForGroup(groupid,"At max capacity",15)
				return
			end
			for i,v in ipairs(self.ejectedPilots)do
				local dist=UTILS.VecDist3D(un:getPoint(),v:getPoint())
				if dist<150 then
					self.carriedPilots[groupid]=self.carriedPilots[groupid]+1
					self.carriedPilotData=self.carriedPilotData or {}
					self.carriedPilotData[groupid]=self.carriedPilotData[groupid] or {}
					local pid=v:getObjectID()
					local pilotData=landedPilotOwners[pid]
					if pilotData then
						table.insert(self.carriedPilotData[groupid],pilotData)
						landedPilotOwners[pid]=nil
					end
					table.remove(self.ejectedPilots,i)
					v:destroy()
					trigger.action.outTextForGroup(groupid,"Pilot onboard ["..self.carriedPilots[groupid].."/"..LogisticCommander.maxCarriedPilots.."]",15)
					return
				end
			end
			trigger.action.outTextForGroup(groupid,"No ejected pilots nearby",15)
		end
	end
function LogisticCommander:unloadPilot(groupname)
		local gr=Group.getByName(groupname)
		local groupid=gr:getID()
		if gr then
			local un=gr:getUnit(1)
			if self.carriedPilots[groupid]==0 then
				trigger.action.outTextForGroup(groupid,"No one onboard",15)
				return
			end
			if Utils.isInAir(un) then
				trigger.action.outTextForGroup(groupid,"Can not drop off pilots while in air",15)
				return
			end

			local zn=self.battleCommander:getZoneOfUnit(un:getName())
			local friendly=false
			if zn and (zn.active and zn.side==gr:getCoalition() or zn.wasBlue) then
				friendly=true
			else
				for _,zName in ipairs(self.supplyZones) do
					if string.find(zName,"CTLD FARP") then
						local zObj=ZONE:FindByName(zName)
						if zObj and GROUP:FindByName(groupname):IsInZone(zObj) then
							friendly=true
							break
						end
					end
				end
			end

			if friendly then
				local count=self.carriedPilots[groupid]
				trigger.action.outTextForGroup(groupid,"Pilots dropped off",15)
				if self.battleCommander.playerRewardsOn then
					self.battleCommander:addFunds(un:getCoalition(),self.battleCommander.rewards.rescue*count)
					trigger.action.outTextForCoalition(un:getCoalition(),count.." pilots were rescued. +"..self.battleCommander.rewards.rescue*count.." credits",5)
					local rescuedPlayers=self.carriedPilotData[groupid] or {}
					for _,pilotData in ipairs(rescuedPlayers) do
						local pname=pilotData.player
						local restoreAmount=pilotData.lostCredits
						self.battleCommander:addFunds(un:getCoalition(),restoreAmount)
						self.battleCommander:addStat(pname,"Points",restoreAmount)
						trigger.action.outTextForCoalition(un:getCoalition(),"["..pname.."] recovered. +"..restoreAmount.." credits restored.",5)
					end
					self.carriedPilotData[groupid]=nil
				end
				self.carriedPilots[groupid]=0
				return
			end

			trigger.action.outTextForGroup(groupid,"Can only drop off pilots in a friendly zone",15)
		end
	end

	function LogisticCommander:markPilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			
			local maxdist = 300000
			local targetpilot = nil
			for i, v in ipairs(self.ejectedPilots) do
				local dist = UTILS.VecDist3D(un:getPoint(), v:getPoint())
				if dist < maxdist then
					maxdist = dist
					targetpilot = v
				end
			end
			
			if targetpilot then
				trigger.action.smoke(targetpilot:getPoint(), 4)
				trigger.action.outTextForGroup(gr:getID(), 'Ejected pilot has been marked with blue smoke', 15)
			else
				trigger.action.outTextForGroup(gr:getID(), 'No ejected pilots nearby', 15)
			end
		end
	end
	
	function LogisticCommander:flarePilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			
			local maxdist = 300000
			local targetpilot = nil
			for i,v in ipairs(self.ejectedPilots) do
				local dist = UTILS.VecDist3D(un:getPoint(), v:getPoint())
				if dist<maxdist then
					maxdist = dist
					targetpilot = v
				end
			end
			
			if targetpilot then
				trigger.action.signalFlare(targetpilot:getPoint(), 0, math.floor(math.random(0,359)))
			else
				trigger.action.outTextForGroup(gr:getID(), 'No ejected pilots nearby', 15)
			end
		end
	end
	
	function LogisticCommander:infoPilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			
			local maxdist = 300000
			local targetpilot = nil
			for i,v in ipairs(self.ejectedPilots) do
				local dist = UTILS.VecDist3D(un:getPoint(), v:getPoint())
				if dist<maxdist then
					maxdist = dist
					targetpilot = v
				end
			end
			
			if targetpilot then
				self:printPilotInfo(targetpilot, gr:getID(), un, 60)
			else
				trigger.action.outTextForGroup(gr:getID(), 'No ejected pilots nearby', 15)
			end
		end
	end
	
		function LogisticCommander:infoHumanPilot(groupname)
		local gr = Group.getByName(groupname)
		if not gr then return end
		local un = gr:getUnit(1)
		if not un or not un:isExist() then return end
		local maxdist = 300000
		local targetpilot = nil
		for i,ejectedObj in ipairs(self.ejectedPilots) do
			local pid = ejectedObj:getObjectID()
			local pilotData = landedPilotOwners[pid] or ejectedPilotOwners[pid]
			if pilotData and pilotData.player then
				local dist = UTILS.VecDist3D(un:getPoint(), ejectedObj:getPoint())
				if dist < maxdist then
					maxdist = dist
					targetpilot = ejectedObj
				end
			end
		end
		if targetpilot then
			self:printPilotInfo(targetpilot, gr:getID(), un, 60)
		else
			trigger.action.outTextForGroup(gr:getID(), 'No ejected friendly pilots nearby', 15)
		end
	end
	
	function LogisticCommander:printPilotInfo(pilotObj,groupid,referenceUnit,duration)
		local pnt=pilotObj:getPoint()
		local toprint='Pilot in need of extraction:'
		local objectID=pilotObj:getObjectID()
		local pilotData=landedPilotOwners[objectID]
		if (pilotData and pilotData.player) then		

			toprint = toprint .. '\n\n[' .. pilotData.player .. '] '
			toprint = toprint .. ' Lost: ' .. pilotData.lostCredits .. ' Credits'
			toprint = toprint .. '\n\nSave the pilot to retrive the lost credits'
		end
	local c=COORDINATE:NewFromVec3(pnt)
	local ddm=c:ToStringLLDDM():gsub("^LL DDM%s*","")
	local dms=c:ToStringLLDMS():gsub("^LL DMS%s*","")
	local mgrs=c:ToStringMGRS():gsub("^MGRS%s*","")
	local alt=c:GetLandHeight()
	toprint=toprint..'\n\nDDM:  '..ddm
	toprint=toprint..'\nDMS:  '..dms
	toprint=toprint..'\nMGRS: '..mgrs
	toprint=toprint..'\n\nAlt: '..math.floor(alt)..'m | '..math.floor(alt*3.280839895)..'ft'
	if referenceUnit then
		local dist=UTILS.VecDist3D(referenceUnit:getPoint(),pilotObj:getPoint())
		local dstkm=string.format('%.2f',dist/1000)
		local dstnm=string.format('%.2f',dist/1852)
		toprint=toprint..'\n\nDist: '..dstkm..'km | '..dstnm..'nm'
		local brg=COORDINATE:NewFromVec3(referenceUnit:getPoint()):HeadingTo(c)
		toprint=toprint..'\nBearing: '..math.floor(brg)
	end
	trigger.action.outTextForGroup(groupid,toprint,duration)
	end

	function LogisticCommander:update()
		local tocleanup = {}

		for i, v in ipairs(self.ejectedPilots) do
			if v and v:isExist() then
				for _, v2 in ipairs(self.battleCommander.zones) do
					if v2.active and v2.side ~= 0 and Utils.isInZone(v, v2.zone) then
						table.insert(tocleanup, i)
						break
					end
				end
			else
				table.insert(tocleanup, i)
			end
		end

		for i = #tocleanup, 1, -1 do
			local index = tocleanup[i]
			local pilot = self.ejectedPilots[index]

			if pilot and pilot:isExist() then
				pilot:destroy()
				landedPilotOwners[pilot:getName()]=nil
			end

			table.remove(self.ejectedPilots, index)
		end
	end


function LogisticCommander:init()
    local ev = {}
    ev.context = self
    function ev:onEvent(event)
        if event.id == 15 and event.initiator and event.initiator.getPlayerName then
            local player = event.initiator:getPlayerName()
            if player then
                local groupObj = event.initiator:getGroup()
                local groupid = groupObj:getID()
                local groupname = groupObj:getName()
                local unitType = event.initiator:getDesc()['typeName']
				self.context.battleCommander.playerNames = self.context.battleCommander.playerNames or {}
                self.context.battleCommander.playerNames[groupid] = player
				self.context.battleCommander:refreshShopMenuForGroup(groupid, groupObj)


                if self.context.statsMenus[groupid] then
                    missionCommands.removeItemForGroup(groupid, self.context.statsMenus[groupid])
                    self.context.statsMenus[groupid] = nil
                end

                local statsMenu = missionCommands.addSubMenuForGroup(groupid, 'Stats and Budget')
                local statsSubMenu = missionCommands.addSubMenuForGroup(groupid, 'Stats', statsMenu)
                missionCommands.addCommandForGroup(groupid, 'My Stats', statsSubMenu, self.context.battleCommander.printMyStats, self.context.battleCommander, event.initiator:getID(), player)
                missionCommands.addCommandForGroup(groupid, 'All Stats', statsSubMenu, self.context.battleCommander.printStats, self.context.battleCommander, event.initiator:getID())
                missionCommands.addCommandForGroup(groupid, 'Top 5 Players', statsSubMenu, self.context.battleCommander.printStats, self.context.battleCommander, event.initiator:getID(), 5)
                missionCommands.addCommandForGroup(groupid, 'Budget Overview', statsMenu, self.context.battleCommander.printShopStatus, self.context.battleCommander, 2)
                self.context.statsMenus[groupid] = statsMenu

                if self.context.allowedTypes[unitType] then
                    self.context.carriedCargo[groupid] = 0
                    self.context.carriedPilots[groupid] = 0

                    if self.context.groupMenus[groupid] then
                        missionCommands.removeItemForGroup(groupid, self.context.groupMenus[groupid])
                        self.context.groupMenus[groupid] = nil
                    end

                    local cargomenu = missionCommands.addSubMenuForGroup(groupid, 'Logistics')
                    missionCommands.addCommandForGroup(groupid, 'Load supplies', cargomenu, self.context.loadSupplies, self.context, groupname)
                    missionCommands.addCommandForGroup(groupid, 'Unload supplies', cargomenu, self.context.unloadSupplies, self.context, groupname)
                    missionCommands.addCommandForGroup(groupid, 'List supply zones', cargomenu, self.context.listSupplyZones, self.context, groupname)
                    missionCommands.addCommandForGroup(groupid, 'Supplies Status', cargomenu, self.context.checkSuppliesStatus, self.context, groupid)

                    local csar = missionCommands.addSubMenuForGroup(groupid, 'CSAR', cargomenu)
                    missionCommands.addCommandForGroup(groupid, 'Pick up pilot', csar, self.context.loadPilot, self.context, groupname)
                    missionCommands.addCommandForGroup(groupid, 'Drop off pilot', csar, self.context.unloadPilot, self.context, groupname)
                    missionCommands.addCommandForGroup(groupid, 'Info on closest pilot', csar, self.context.infoPilot, self.context, groupname)
                    missionCommands.addCommandForGroup(groupid, 'Info on closest pilot with credits', csar, self.context.infoHumanPilot, self.context, groupname)
                    missionCommands.addCommandForGroup(groupid, 'Deploy smoke at closest pilot', csar, self.context.markPilot, self.context, groupname)
                    missionCommands.addCommandForGroup(groupid, 'Deploy flare at closest pilot', csar, self.context.flarePilot, self.context, groupname)

                    local main = missionCommands.addSubMenuForGroup(groupid, 'Mark Zone', cargomenu)
                    local sub1
                    for i, v in ipairs(self.context.battleCommander.zones) do
                        if i < 10 then
                            missionCommands.addCommandForGroup(groupid, v.zone, main, v.markWithSmoke, v, event.initiator:getCoalition())
                        elseif i == 10 then
                            sub1 = missionCommands.addSubMenuForGroup(groupid, "More", main)
                            missionCommands.addCommandForGroup(groupid, v.zone, sub1, v.markWithSmoke, v, event.initiator:getCoalition())
                        elseif i % 9 == 1 then
                            sub1 = missionCommands.addSubMenuForGroup(groupid, "More", sub1)
                            missionCommands.addCommandForGroup(groupid, v.zone, sub1, v.markWithSmoke, v, event.initiator:getCoalition())
                        else
                            missionCommands.addCommandForGroup(groupid, v.zone, sub1, v.markWithSmoke, v, event.initiator:getCoalition())
                        end
                    end

                    self.context.groupMenus[groupid] = cargomenu
                end
                if self.context.carriedCargo[groupid] then
                    self.context.carriedCargo[groupid] = nil
                end
            end
        end

        if event.id == world.event.S_EVENT_TAKEOFF
           and event.initiator and event.initiator.getPlayerName -- ADDED: Checking for getPlayerName
        then
            local groupid = event.initiator:getGroup():getID()
            local unitType = event.initiator:getDesc()['typeName']
            local player = event.initiator:getPlayerName()
            local un = event.initiator
            local zn = self.context.battleCommander:getZoneOfUnit(un:getName())

            if zn and (zn.side == un:getCoalition() or (un:getCoalition() == 2 and zn.wasBlue)) then
                for _, v in ipairs(self.context.supplyZones) do
                    if v == zn.zone then
                        if self.context.allowedTypes[unitType] and not self.context.carriedCargo[groupid] then
                            trigger.action.outTextForGroup(groupid, 'Warning: Supplies not loaded', 30,true)
                            if trigger.misc.getUserFlag(180) == 0 then
                                trigger.action.outSoundForGroup(groupid, "micclick.ogg")
                            end
                        end
                        return
                    end
                end
            end
        end

		if event.id==world.event.S_EVENT_LANDING_AFTER_EJECTION then
			local aircraftID=event.place and event.place.id_
			local coalitionSide = event.initiator:getCoalition()
			local pilotObjectID=event.initiator and event.initiator:getObjectID()
			local pilotData=ejectedPilotOwners[aircraftID]
			

			if coalitionSide == coalition.side.RED then
				event.initiator:destroy()
				return
			end

			if pilotData then
				landedPilotOwners[pilotObjectID]=pilotData
				ejectedPilotOwners[aircraftID]=nil
			end

			table.insert(self.context.ejectedPilots,event.initiator)
			for i in pairs(self.context.groupMenus) do
				self.context:printPilotInfo(event.initiator,i,nil,15)
			end
		end
    end
    world.addEventHandler(ev)
    SCHEDULER:New(nil,self.update,{self},10,10)
end


function LogisticCommander:checkSuppliesStatus(groupid)
	if self.carriedCargo[groupid] then
		trigger.action.outTextForGroup(groupid, 'Supplies loaded', 10)
	else
		trigger.action.outTextForGroup(groupid, 'Supplies not loaded', 10)
	end
end

HercCargoDropSupply = {}
do
	HercCargoDropSupply.allowedCargo = {}
	HercCargoDropSupply.allowedCargo['weapons.bombs.Generic Crate [20000lb]'] = true
	HercCargoDropSupply.herculesRegistry = {} -- {takeoffzone = string, lastlanded = time}

	HercCargoDropSupply.battleCommander = nil
	function HercCargoDropSupply.init(bc)
		HercCargoDropSupply.battleCommander = bc
		
		cargodropev = {}
		function cargodropev:onEvent(event)
			if event.id == world.event.S_EVENT_SHOT then
				local name = event.weapon:getDesc().typeName
				if HercCargoDropSupply.allowedCargo[name] then
					local alt = Utils.getAGL(event.weapon)
					if alt < 5 then
						HercCargoDropSupply.ProcessCargo(event)
					else
						timer.scheduleFunction(HercCargoDropSupply.CheckCargo, event, timer.getTime() + 0.1)
					end
				end
			end
			
			if event.id == world.event.S_EVENT_TAKEOFF then
				if event.initiator and event.initiator.getDesc then
					local desc = event.initiator:getDesc()
					if desc and desc.typeName == 'Hercules' then
						local herc = HercCargoDropSupply.herculesRegistry[event.initiator:getName()]
						local zn = HercCargoDropSupply.battleCommander:getZoneOfUnit(event.initiator:getName())
						if zn then
							if not herc then
								HercCargoDropSupply.herculesRegistry[event.initiator:getName()] = {takeoffzone = zn.zone}
							elseif not herc.lastlanded or (herc.lastlanded + 30) < timer.getTime() then
								HercCargoDropSupply.herculesRegistry[event.initiator:getName()].takeoffzone = zn.zone
							end
						end
					end
				end
			end
			
			if event.id == world.event.S_EVENT_LAND then
				if event.initiator then
					local desc = event.initiator:getDesc()
					if desc and desc.typeName == 'Hercules' then
						local herc = HercCargoDropSupply.herculesRegistry[event.initiator:getName()]
						
						if not herc then
							HercCargoDropSupply.herculesRegistry[event.initiator:getName()] = {}
						end
						
						HercCargoDropSupply.herculesRegistry[event.initiator:getName()].lastlanded = timer.getTime()
					end
				end
			end
		end
		
		world.addEventHandler(cargodropev)
	end

	function HercCargoDropSupply.ProcessCargo(shotevent)
		local cargo = shotevent.weapon
		local zn = HercCargoDropSupply.battleCommander:getZoneOfWeapon(cargo)
		if zn and zn.active and shotevent.initiator and shotevent.initiator:isExist() then
			local herc = HercCargoDropSupply.herculesRegistry[shotevent.initiator:getName()]
			if not herc or herc.takeoffzone == zn.zone then
				cargo:destroy()
				return
			end
			
			local cargoSide = cargo:getCoalition()
			if zn.side == 0 then
				if HercCargoDropSupply.battleCommander.playerRewardsOn then
					HercCargoDropSupply.battleCommander:addFunds(cargoSide, HercCargoDropSupply.battleCommander.rewards.crate)
					trigger.action.outTextForCoalition(cargoSide,'Capture +'..HercCargoDropSupply.battleCommander.rewards.crate..' credits',5)
				end
				
				zn:capture(cargoSide)
			elseif zn.side == cargoSide then
				if HercCargoDropSupply.battleCommander.playerRewardsOn then
					if zn:canRecieveSupply() then
						HercCargoDropSupply.battleCommander:addFunds(cargoSide, HercCargoDropSupply.battleCommander.rewards.crate)
						trigger.action.outTextForCoalition(cargoSide,'Resupply +'..HercCargoDropSupply.battleCommander.rewards.crate..' credits',5)
					else
						local reward = HercCargoDropSupply.battleCommander.rewards.crate * 0.25
						HercCargoDropSupply.battleCommander:addFunds(cargoSide, reward)
						trigger.action.outTextForCoalition(cargoSide,'Resupply +'..reward..' credits (-75% due to no demand)',5)
					end
				end
				
				zn:upgrade()
			end
			
			cargo:destroy()
		end
	end
	
	function HercCargoDropSupply.CheckCargo(shotevent, time)
		local cargo = shotevent.weapon
		if not cargo:isExist() then
			return nil
		end
		
		local alt = Utils.getAGL(cargo)
		if alt < 5 then
			HercCargoDropSupply.ProcessCargo(shotevent)
			return nil
		end
		return time+0.1
	end
end
MissionCommander = {}
do
    function MissionCommander:new(obj)
        obj = obj or {}
        obj.missions = {}
        obj.missionsType = {}
        obj.missionFlags = {}
        if obj.checkFrequency then
            obj.checkFrequency = 30
        end
        setmetatable(obj, self)
        self.__index = self
        return obj
    end

	function MissionCommander:printMissions(groupId)
		local output = 'Active Missions'
		output = output .. '\n------------------------------------------------'

		for _, v in ipairs(self.missions) do
			if v.isRunning then
				output = output .. '\n[' .. self:decodeMessage(v.title) .. ']'
				output = output .. '\n' .. self:decodeMessage(v.description)
				output = output .. '\n------------------------------------------------'
			end
		end

		local hasAvailableEscortMissions = false
		for _, v in ipairs(self.missions) do
			if v.isEscortMission and not v.isRunning and not v.accept and v:isActive() and not v.denied then 
				hasAvailableEscortMissions = true
				break
			end
		end

		if self.escortMissionGenerated and hasAvailableEscortMissions then
			output = output .. '\nAvailable Missions'
			output = output .. '\n------------------------------------------------'
			for _, v in ipairs(self.missions) do
				if v.isEscortMission and not v.isRunning and not v.accept and v:isActive() then
					output = output .. '\n[' .. self:decodeMessage(v.MainTitle) .. ']'
					output = output .. '\n' .. self:decodeMessage(v.description)
					output = output .. '\n------------------------------------------------'
				end
			end
		end
	  if groupId then
		trigger.action.outTextForGroup(groupId, output, 30)
	  else
		trigger.action.outTextForCoalition(2, output, 10)
	  end
	end
	function MissionCommander:trackMission(params)

		if params.isEscortMission and params.zoneName then
			for _, existing in ipairs(self.missions) do
				if existing.isEscortMission and existing.zoneName == params.zoneName then
					return
				end
			end
		end
		params.isRunning = false
		params.accept = false
		params.notified = false
		table.insert(self.missions, params)
	end

	function MissionCommander:checkMissions(time)
		for i, v in ipairs(self.missions) do
			if v.isRunning then
				if v.missionFail and v:isActive() and v:missionFail() then
					v.isRunning = false
					table.remove(self.missions, i)
				if v.startOver then v:startOver() end
				elseif not v:isActive() then
					if v.messageEnd then trigger.action.outTextForCoalition(self.side, self:decodeMessage(v.messageEnd), 30) end
					if v.reward then self.battleCommander:addFunds(self.side, v.reward) end
					if v.endAction then v:endAction() end
					v.isRunning = false
					return time + 2
				end
			elseif v:isActive() and not v.isEscortMission then
				if v.canExecute and type(v.canExecute) == 'function' then
					if v:canExecute() then
						if v.messageStart then
							trigger.action.outTextForCoalition(self.side, self:decodeMessage(v.messageStart), 30) end
						if v.startAction then v:startAction() end
						v.isRunning = true
					end
				else
					if v.messageStart then
						trigger.action.outTextForCoalition(self.side, self:decodeMessage(v.messageStart), 30) end
					if v.startAction then v:startAction() end
					v.isRunning = true
					return time + 2
				end
			elseif v.isEscortMission and v:isActive() and not v.isRunning then
				if not v.notified then
					if v.titleBefore then
					v:titleBefore() end
					v.notified = true
				end
				if v:isActive() and v.notified and v:returnAccepted() and not v.isRunning then
					if v.startAction then v.startAction() end
					v.isRunning = true
					return time + 4
				end
			elseif v.isEscortMission and not v:isActive() and v.notified then
				v.notified = false
			end
		end

		return time + self.checkFrequency
	end

	function MissionCommander:acceptMission(mission)
		local targetMissionGroup = mission.missionGroup
		for _, v in ipairs(self.missions) do
			if v.isEscortMission and v.missionGroup == targetMissionGroup then
				v.accept = true
				v.isRunning = true
				return
			end
		end
	end



	function MissionCommander:init()
		--missionCommands.addCommandForCoalition(self.side, 'Missions', nil, self.printMissions, self)
		timer.scheduleFunction(self.checkMissions, self, timer.getTime() + 15)
	end
	printMissionMenus = printMissionMenus or {}
	function MissionCommander:createMissionsMenuForGroup(groupId)
		env.info("DEBUG: Creating menu for groupId="..tostring(groupId))
		
		if printMissionMenus[groupId] then
			missionCommands.removeItemForGroup(groupId, printMissionMenus[groupId])
		end
		
		printMissionMenus[groupId] = missionCommands.addCommandForGroup(groupId, "Missions", nil, function() self:printMissions(groupId) end)
	end

	function MissionCommander:decodeMessage(param)
		if type(param) == "function" then
			return param()
		elseif type(param) == "string" then
			return param
		end
	end
end

function isZoneUnderSEADMission(zoneName)
    for _, mission in ipairs(mc.missions) do
        if mission.zone == zoneName and mission.missionType == "SEAD" and mission:isActive() then
            return true
        end
    end
    return false
end

function isAnyOtherMissionActive(currentMissionZone)
    local missionData = missions[currentMissionZone]
    if missionData and IsGroupActive(missionData.missionGroup) then
        return true, missionData
    end
    return false, nil
end

function startNextMission(missionZone)
    local mission = missions[missionZone]
    if not mission then
        return
    end
    for trackedGroupName, _ in pairs(trackedGroups) do
        if IsGroupActive(trackedGroupName) then
            local trackedGroup = Group.getByName(trackedGroupName)
            if trackedGroup then
                local groupID = trackedGroup:getID()
                missionMenus[groupID] = missionMenus[groupID] or {}

                local isActive, activeMission = isAnyOtherMissionActive(missionZone)
                if isActive then
                    local activeMissionZone = activeMission.zone
                    local inProgressMenu = missionCommands.addSubMenuForGroup(groupID, "Current mission in progress. Continue?")
                    missionMenus[groupID].inProgressMenu = inProgressMenu

                    missionCommands.addCommandForGroup(groupID, "Yes", inProgressMenu, function()
                        removeMissionMenuForAll(activeMissionZone, nil, true)

                        if mission.missionGroup and type(mission.missionGroup) == "string" then
							local grpObj = GROUP:FindByName(mission.missionGroup)
							if grpObj then
								grpObj:Respawn()
							end
                            timer.scheduleFunction(function()
                                local groundUnitGroup = Group.getByName(mission.missionGroup)
                                if groundUnitGroup then
                                    trigger.action.groupStopMoving(groundUnitGroup)
                                end
                            end, {}, timer.getTime() + 2)

                            monitorFlagForMission(mission, trackedGroup, groupID)
                            createControlMenuForGroup(trackedGroup, mission, groupID)
                        else
                            trigger.action.outTextForGroup(groupID, "Error: Escort group not defined or invalid.", 10)
                        end
                    end)

                    missionCommands.addCommandForGroup(groupID, "No", inProgressMenu, function()
                        if missionMenus[groupID].inProgressMenu then
                            missionCommands.removeItemForGroup(groupID, missionMenus[groupID].inProgressMenu)
                            missionMenus[groupID].inProgressMenu = nil
                        end
                    end)

                    return
                end
            end
        end
    end
end

	function monitorFlagForMission(mission, group, groupID)
		if mission.MissionType ~= "Escort" then return end

		mission.lastFlagValue = nil
		mission.wasStopped = false

		local missionGroup = GROUP:FindByName(mission.missionGroup)
		if not missionGroup or not missionGroup:IsAlive() then return end

		local triggerZone = ZONE_GROUP:New(mission.missionGroup .. "_Zone", missionGroup, 2000)
		local groupSet = SET_GROUP:New():FilterCategoryGround():FilterAlive():FilterCoalitions("red"):FilterStart()

		triggerZone.OnAfterEnteredZone = function(self, From, Event, To, triggeringGroup)
			if missionGroup:IsAlive() then
				trigger.action.outTextForGroup(groupID, sendRandomMessage("halt"), 30)
				local snd = getRandomSound("halt")
				trigger.action.outSoundForGroup(groupID, snd)
				missionGroup:RouteStop()
			else
				for trackedGroupName,_ in pairs(trackedGroups) do
					local trackedGroup = GROUP:FindByName(trackedGroupName)
					if not trackedGroup or not trackedGroup:IsAlive() then
						trackedGroups[trackedGroupName] = nil
					end
				end
			end
			mission.wasStopped = true
		end

		triggerZone.OnAfterZoneEmpty = function(self, From, Event, To)
			if missionGroup:IsAlive() then
				trigger.action.outTextForGroup(groupID, sendRandomMessage("moving"), 30)
				local snd = getRandomSound("moving")
				trigger.action.outSoundForGroup(groupID, snd)
				missionGroup:RouteResume()
			else
				for trackedGroupName,_ in pairs(trackedGroups) do
					local trackedGroup = GROUP:FindByName(trackedGroupName)
					if not trackedGroup or not trackedGroup:IsAlive() then
						trackedGroups[trackedGroupName] = nil
					end
				end
			end
			mission.wasStopped = false
		end

		triggerZone:Trigger(groupSet)
	end

function canStartMission(mission)
    if not mission then return false end
    local targetZone = bc:getZoneByName(mission.TargetZone)
    if not targetZone or targetZone.side ~= 1 then return false end
    if not missions[mission.zone] then return false end
    return not IsGroupActive(mission.missionGroup)
end

function createControlMenuForGroup(group, mission, groupID)

    if mission.MissionType ~= "Escort" then return end
    missionMenus[groupID] = missionMenus[groupID] or {}

    for _, existingMission in pairs(missions) do
        if not trackedGroups[group:getName()] and mission.zone == existingMission.zone then
            trackedGroups[group:getName()] = true
        end
    end

    if not IsGroupActive(mission.missionGroup) then

		RespawnGroup(mission.missionGroup)

        timer.scheduleFunction(function()
            local missionGroup = Group.getByName(mission.missionGroup)
            if missionGroup then
                trigger.action.groupStopMoving(missionGroup)
                monitorFlagForMission(mission, group, groupID)
            end
        end, {}, timer.getTime() + 2)
    end

    local groupMenu = missionCommands.addSubMenuForGroup(groupID, mission.menuTitle)
    missionMenus[groupID].groupMenu = groupMenu

    missionCommands.addCommandForGroup(groupID, "Move", groupMenu, function()
        if IsGroupActive(mission.missionGroup) then
            local groundUnitGroup = Group.getByName(mission.missionGroup)
            trigger.action.groupContinueMoving(groundUnitGroup)
			local snd = getRandomSound("CommandMove")
			trigger.action.outSoundForGroup(groupID, snd)
            trigger.action.outTextForGroup(groupID, "missionGroup: Moving.", 10)
        else
            trigger.action.outTextForGroup(groupID, "Ground unit not found.", 10)
        end
    end)

    missionCommands.addCommandForGroup(groupID, "Hold position", groupMenu, function()
        if IsGroupActive(mission.missionGroup) then
            local groundUnitGroup = Group.getByName(mission.missionGroup)
            trigger.action.groupStopMoving(groundUnitGroup)
			local snd = getRandomSound("CommandStop")
			trigger.action.outSoundForGroup(groupID, snd)
            trigger.action.outTextForGroup(groupID, "missionGroup: holding position.", 10)
        else
            trigger.action.outTextForGroup(groupID, "Ground unit not found.", 10)
        end
    end)

    missionCommands.addCommandForGroup(groupID, "Deploy smoke near the convoy", groupMenu, function()
        if IsGroupActive(mission.missionGroup) then
            local groundUnitGroup = Group.getByName(mission.missionGroup)
            local lastAliveUnit = nil
            for _, unit in ipairs(groundUnitGroup:getUnits()) do
                if unit:isExist() and unit:getLife() > 0 then
                    lastAliveUnit = unit
                end
            end
            if lastAliveUnit then
                local position = lastAliveUnit:getPoint()
                trigger.action.smoke({x = position.x, y = position.y, z = position.z - 10}, trigger.smokeColor.Blue)
                trigger.action.outTextForGroup(groupID, "missionGroup: Blue smoke deployed", 10)
            else
                trigger.action.outTextForGroup(groupID, "No alive units found in the escort group.", 10)
            end
        else
            trigger.action.outTextForGroup(groupID, "Escort group not found.", 10)
        end
    end)

	missionCommands.addCommandForGroup(groupID,"Get Bearing to the Convoy",groupMenu,function()
		if IsGroupActive(mission.missionGroup) then
			local groundUnitGroup=Group.getByName(mission.missionGroup)
			local lastAliveUnit=nil
			for _,unit in ipairs(groundUnitGroup:getUnits()) do
				if unit:isExist() and unit:getLife()>0 then lastAliveUnit=unit end
			end
			if lastAliveUnit then
				local convoyPosition=lastAliveUnit:getPoint()
				local groupLeader=group:getUnit(1)
				if groupLeader then
					local groupLeaderPosition=groupLeader:getPoint()
					local dist=UTILS.VecDist3D(groupLeaderPosition,convoyPosition)
					local dstkm=string.format('%.2f',dist/1000)
					local bearing=Utils.getBearing(groupLeaderPosition,convoyPosition)
					trigger.action.outTextForGroup(groupID,"missionGroup: "..math.floor(bearing).."°\n\nDistance: "..dstkm.." km",20)
				else
					trigger.action.outTextForGroup(groupID,"Could not determine group leader's position.",10)
				end
			else
				trigger.action.outTextForGroup(groupID,"No alive units found in the escort group.",10)
			end
		else
			trigger.action.outTextForGroup(groupID,"Escort group not found.",10)
		end
	end)

    local restartMenu = missionCommands.addSubMenuForGroup(groupID, "Restart Mission", groupMenu)
    missionMenus[groupID].restartMenu = restartMenu

    missionCommands.addCommandForGroup(groupID, "Yes", restartMenu, function()
        if mission.missionGroup then
            destroyGroupIfActive(mission.missionGroup)
        end
        removeMissionMenuForAll(mission.zone)
		RespawnGroup(mission.missionGroup)
        timer.scheduleFunction(function()
            local missionGroup = Group.getByName(mission.missionGroup)
            if missionGroup then
                trigger.action.groupStopMoving(missionGroup)
            end
		trigger.action.outSoundForGroup(groupID, "YourCommand.ogg")
		trigger.action.outTextForGroup(groupID, "Escort group:\n\nWe are standing by and ready to move on your command.", 10)
        end, {}, timer.getTime() + 2)
        createControlMenuForGroup(group, mission, groupID)
		monitorFlagForMission(mission, group, groupID)
    end)

    missionCommands.addCommandForGroup(groupID, "No", restartMenu, function()
        missionCommands.removeItemForGroup(groupID, restartMenu)
        trigger.action.outTextForGroup(groupID, "Restart canceled.", 10)
    end)
    return missionMenus[groupID]
end


function handleMission(zoneName, groupName, groupID, group)
	if not missions then return end
    if not group or not group:isExist() then return end
    if not missions[zoneName] then return end
    local currentMission = missions[zoneName]

    for _, mission in pairs(missions) do
        if not trackedGroups[groupName] and zoneName == mission.zone then
            trackedGroups[groupName] = true
            missionMenus[groupID] = missionMenus[groupID] or {}

            if IsGroupActive(mission.missionGroup) then
                monitorFlagForMission(mission, group, groupID)
				generateEscortMission(zoneName, groupName, groupID, group, currentMission)
				missionGroupIDs[zoneName] = missionGroupIDs[zoneName] or {}
				missionGroupIDs[zoneName][groupID] = {
					groupID = groupID,	
					group = group
				}
                missionMenus[groupID] = createControlMenuForGroup(group, mission, groupID)
                return
            end

            if canStartMission(mission) then
				--[[
				for _, v in ipairs(mc.missions) do
					if v.zoneName == zoneName and v.isEscortMission then
						if v.denied == true then v.denied = false end
						break
					end
				end
				--]]
				generateEscortMission(zoneName, groupName, groupID, group)
				
                local acceptMenu = missionCommands.addSubMenuForGroup(group:getID(), mission.missionTitle)
                missionMenus[groupID].acceptMenu = acceptMenu
				
                missionCommands.addCommandForGroup(group:getID(), "Accept Mission", acceptMenu, function()
					mc:acceptMission(mission)
                    createControlMenuForGroup(group, mission, groupID)                
					
                    for trackedGroupName, _ in pairs(trackedGroups) do
                        local trackedGroup = Group.getByName(trackedGroupName)
                        if trackedGroup and trackedGroup:isExist() then
                            local trackedGroupID = trackedGroup:getID()
                            if missionMenus[trackedGroupID] and missionMenus[trackedGroupID].acceptMenu then
                                removeMissionMenuForAll(mission.zone)
                            end
                            timer.scheduleFunction(function()
                            createControlMenuForGroup(trackedGroup, mission, trackedGroupID)
							trigger.action.outTextForGroup(trackedGroupID, "Escort group:\n\nWe are standing by and ready to move on your command.", 15)
							trigger.action.outSoundForGroup(trackedGroupID, "YourCommand.ogg")
							end, nil, timer.getTime() + 5)
                        else
                            trackedGroups[trackedGroupName] = nil
                        end
                    end
                end)

                missionCommands.addCommandForGroup(group:getID(), "Deny Mission", acceptMenu, function()
                    trigger.action.outTextForGroup(group:getID(), "Mission denied.", 10)
					for _, v in ipairs(mc.missions) do
						if v.zoneName == zoneName and v.isEscortMission then
							v.denied = true
							break
						end
					end
                    if missionMenus[groupID] and missionMenus[groupID].acceptMenu then
                        missionCommands.removeItemForGroup(groupID, missionMenus[groupID].acceptMenu)
                        missionMenus[groupID].acceptMenu = nil
                    end
                end)
            end
        end
    end
end

function removeMissionMenuForAll(zoneName, groupID, destroyIfActive)
    local mission = missions[zoneName]
    if not mission then return end
    if not trackedGroups then return end

    if groupID then
		if missionMenus[groupID] then
			if missionMenus[groupID].restartMenu then
				missionCommands.removeItemForGroup(groupID, missionMenus[groupID].restartMenu)
				missionMenus[groupID].restartMenu = nil
			end
			if missionMenus[groupID].acceptMenu then
				missionCommands.removeItemForGroup(groupID, missionMenus[groupID].acceptMenu)
				missionMenus[groupID].acceptMenu = nil
			end
			if missionMenus[groupID].inProgressMenu then
				missionCommands.removeItemForGroup(groupID, missionMenus[groupID].inProgressMenu)
				missionMenus[groupID].inProgressMenu = nil
			end
			if missionMenus[groupID].groupMenu then
				missionCommands.removeItemForGroup(groupID, missionMenus[groupID].groupMenu)
				missionMenus[groupID].groupMenu = nil
			end
			missionMenus[groupID] = nil
		end
    else
        for trackedGroupName, _ in pairs(trackedGroups) do
            local trackedGroup = Group.getByName(trackedGroupName)
            if trackedGroup and trackedGroup:isExist() then
                local groupID = trackedGroup:getID()
                if missionMenus[groupID] then
                    if missionMenus[groupID].restartMenu then
                        missionCommands.removeItemForGroup(groupID, missionMenus[groupID].restartMenu)
                        missionMenus[groupID].restartMenu = nil
                    end
                    if missionMenus[groupID].acceptMenu then
                        missionCommands.removeItemForGroup(groupID, missionMenus[groupID].acceptMenu)
                        missionMenus[groupID].acceptMenu = nil
                    end
                    if missionMenus[groupID].inProgressMenu then
                        missionCommands.removeItemForGroup(groupID, missionMenus[groupID].inProgressMenu)
                        missionMenus[groupID].inProgressMenu = nil
                    end
                    if missionMenus[groupID].groupMenu then
                        missionCommands.removeItemForGroup(groupID, missionMenus[groupID].groupMenu)
                        missionMenus[groupID].groupMenu = nil
                    end
                    missionMenus[groupID] = nil
                end
            end
        end
    end

    if destroyIfActive then
            destroyGroupIfActive(mission.missionGroup)
        
    end
end

function removeMenusForGroupID(groupID)
    local trackedGroup = Group.getByID(groupID)
    if not trackedGroup then return end
    if missionMenus[groupID] then
        if missionMenus[groupID].restartMenu then
            missionCommands.removeItemForGroup(groupID, missionMenus[groupID].restartMenu)
            missionMenus[groupID].restartMenu = nil
        end
        if missionMenus[groupID].acceptMenu then
            missionCommands.removeItemForGroup(groupID, missionMenus[groupID].acceptMenu)
            missionMenus[groupID].acceptMenu = nil
        end
        if missionMenus[groupID].inProgressMenu then
            missionCommands.removeItemForGroup(groupID, missionMenus[groupID].inProgressMenu)
            missionMenus[groupID].inProgressMenu = nil
        end
        if missionMenus[groupID].groupMenu then
            missionCommands.removeItemForGroup(groupID, missionMenus[groupID].groupMenu)
            missionMenus[groupID].groupMenu = nil
        end
        missionMenus[groupID] = nil
    end
end
function sendRandomMessage(context)
    local messages = {
		halt = {
			"Recon confirms enemy activity ahead.\n\nConvoy holding position, awaiting clearance.",
			"Hostile movement detected nearby.\n\nConvoy halted. Secure the area before resuming.",
			"Enemy presence confirmed ahead.\n\nConvoy stopped, standing by for further orders.",
			"Potential threat identified.\n\nConvoy holding. Clear the area to proceed."
		},
		moving = {
			"Convoy rolling out.\n\nStay sharp and maintain visual.",
			"Convoy is Oscar Mike.\n\nKeep formation tight and eyes open for threats.",
			"Convoy underway.\n\nScan the route ahead for hostiles.",
			"Route clear. Convoy advancing toward destination."
		}
    }
    local selectedMessages = messages[context] or {"Unknown context provided. Please verify the convoy's status."}
    return selectedMessages[math.random(#selectedMessages)]
end
function getRandomSound(context)
    local sounds = {
		halt = {
			"ApprachingTheEnemy.ogg",
			"EnemyApproaching.ogg"
		},
		moving = {
			"AllrightLetsMoveIt.ogg",
			"AllClear.ogg",
			"LetsGo.ogg",
			"MoveOut.ogg"
		},
		CommandMove = {
			"RogerProceedMission.ogg",
			"OkRoggerThat.ogg",
			"CopyThat.ogg",
			"MoveOut.ogg"
		},
		CommandStop = {
			"TakingCover.ogg",
			"OkRoggerThat.ogg",
			"CopyThat.ogg",
			"TakingCoverNowSir.ogg"
		}
    }
    local selectedSounds = sounds[context] or {"Unknown context provided. Please verify the convoy's status."}
    return selectedSounds[math.random(#selectedSounds)]
end
missionMenus = {}
trackedGroups = trackedGroups or {}
missionGroupIDs = {}

capSpawnIndex = 1
capParentMenu = nil
capControlMenu = nil
capActive = false
capGroup = nil
capTemplate = (Era == 'Coldwar') and 'CAP_Template_CW' or 'CAP_Template'
capAltitude = 28000
capSpeed = 450
capHeadings = {
    ["Hot 360"] = 0,
    ["Hot 045"] = 45,
    ["Hot 090"] = 90,
    ["Hot 135"] = 135,
    ["Hot 180"] = 180,
    ["Hot 225"] = 225,
    ["Hot 270"] = 270,
    ["Hot 315"] = 315
}
capLegs = {["Orbit"] = 0,["10 NM Leg"] = 10, ["20 NM Leg"] = 20, ["30 NM Leg"] = 30, ["40 NM Leg"] = 40, ["50 NM Leg"] = 50}
function despawnCap()
    if capGroup then
        capGroup:Despawn()
    end
end
--[[ 
BASE:TraceOn()
BASE:TraceClass("FLIGHTGROUP")
BASE:TraceClass("AUFTRAG")
BASE:TraceClass("OPSGROUP") ]]

function setCapRacetrack(coord, heading, leg, zone)
    if not capGroup then return end
	local currentMission = capGroup:GetMissionCurrent()
    if currentMission then
        currentMission:__Cancel(5)
    end
	local formation = 196610
	if leg == 0 then
		local capSpeed = 330
		formation = 393217
		--CapMissionOrbit2 = AUFTRAG:NewORBIT_CIRCLE_EngageTargets(coord,capAltitude,capSpeed,8,formation,50)
		CapMissionOrbit2 = AUFTRAG:NewORBIT_CIRCLE(coord, capAltitude, capSpeed)
		CapMissionOrbit2:SetMissionAltitude(25000)
		CapMissionOrbit2.missionTask=ENUMS.MissionTask.CAP
		CapMissionOrbit2:SetEngageDetected(40, {"Air"})
		CapMissionOrbit2:SetROT(2)
		CapMissionOrbit2:SetROE(2)
		capGroup:AddMission(CapMissionOrbit2)
		function CapMissionOrbit2:OnAfterExecuting(From, Event, To)
			CapMissionOrbit2:SetMissionSpeed(330)
			if zone then
				trigger.action.outTextForCoalition(2, "CAP: Orbiting at " .. zone, 10)
			else
				trigger.action.outTextForCoalition(2, "CAP: Orbiting", 10)
			end
		end
	else
    	--CapMission2 = AUFTRAG:NewPATROLRACETRACK_EngageTargets(coord,capAltitude,capSpeed,heading,leg,327681,50)
		CapMission2 = AUFTRAG:NewORBIT(coord, capAltitude, capSpeed, heading, leg)
		capGroup:SetSpeed(600)
		CapMissionOrbit2:SetMissionAltitude(25000)
		CapMission2.missionAltitude = CapMission2.TrackAltitude
		CapMission2.missionTask=ENUMS.MissionTask.CAP
		CapMission2:SetEngageDetected(40, {"Air"})
		CapMission2:SetROT(2)
		CapMission2:SetROE(2)
		capGroup:AddMission(CapMission2)
		function CapMission2:OnAfterExecuting(From, Event, To)
		CapMission2:SetMissionSpeed(420)
			if zone then
				trigger.action.outTextForCoalition(2, "CAP: Racetrack at " .. zone .. " with heading " .. heading .. "° and leg distance " .. leg .. " NM", 10)
			else
				trigger.action.outTextForCoalition(2, "CAP: Racetrack with heading " .. heading .. "° and leg distance " .. leg .. " NM", 10)
			end
		end
	end
end

capPositionDirections = {["Reposition 360"] = 360, ["Reposition 045"] = 045, ["Reposition 090"] = 090, ["Reposition 125"] = 125, ["Reposition 180"] = 180, ["Reposition 225"] = 225, ["Reposition 270"] = 270, ["Reposition 315"] = 315}
capPositionDistances = {["0 NM"] = 0,["10 NM"] = 10, ["20 NM"] = 20, ["30 NM"] = 30, ["40 NM"] = 40, ["50 NM"] = 50, ["60 NM"] = 60, ["70 NM"] = 70, ["80 NM"] = 80, ["90 NM"] = 90, ["100 NM"] = 100}

destroyCasMenuItem = nil
destroySeadMenuItem = nil
destroyDecoyMenuItem = nil
destroyBomberMenuItem = nil
destroyNavyArtyMenuItem = nil
------------------------------------------------------ Dynamic Shop -----------------------------------------------------------

function isZoneSafeForSpawn(friendlyZoneName, minDistNM)
    for _, v in ipairs(bc.zones) do
        if v.side == 1 then -- enemy zone
            local dist_m = ZONE_DISTANCES[friendlyZoneName][v.zone]
            local dist = UTILS.MetersToNM(dist_m)
            if dist and dist < minDistNM then
                --env.info("Blue zone " .. friendlyZoneName .. " is not safe: enemy zone " .. v.zone .. " is only " .. string.format("%.1f", dist) .. " NM away.")
                return false
            end
        end
    end
    return true
end

function findClosestBlueZoneOutside(targetZoneName, minDistNM)
    for _, z in ipairs(bc.zones) do
        if z.side == 2 then
            local dist_m = ZONE_DISTANCES[z.zone][targetZoneName]
            local dist = UTILS.MetersToNM(dist_m)
            local safe = isZoneSafeForSpawn(z.zone, 20)
            --env.info(string.format("Zone %s: %.1f NM to target, safe: %s", z.zone, dist, tostring(safe)))
        end
    end
    local minDist = nil
    local selectedZone = nil
    for _, z in ipairs(bc.zones) do
        if z.side == 2 then
            local dist_m = ZONE_DISTANCES[z.zone][targetZoneName]
            local dist = UTILS.MetersToNM(dist_m)
            if dist and dist >= minDistNM then
                if isZoneSafeForSpawn(z.zone, 20) then
                    if not minDist or dist < minDist then
                        minDist = dist
                        selectedZone = z.zone
                    end
                end
            end
        end
    end
    return selectedZone
end
-- cap
function buildCapControlMenu()
    if capControlMenu then
        missionCommands.removeItemForCoalition(2, capControlMenu)
        capControlMenu = nil
    end
    capControlMenu = missionCommands.addSubMenuForCoalition(2, "Dynamic Control")

	if not (capActive or casActive or seadActive or decoyActive or bomberActive or navyArtyActive) then
		if capControlMenu then
			missionCommands.removeItemForCoalition(2, capControlMenu)
			capControlMenu = nil
		end
		return
	end

    if destroyCasMenuItem then
        missionCommands.removeItemForCoalition(2, destroyCasMenuItem)
        destroyCasMenuItem = nil
    end
    if casActive then
        destroyCasMenuItem = missionCommands.addCommandForCoalition(2, "CAS: Destroy", capControlMenu, despawnCas)
    end

	if destroyBomberMenuItem then
		missionCommands.removeItemForCoalition(2, destroyBomberMenuItem)
		destroyBomberMenuItem = nil
	end
	if bomberActive then
		destroyBomberMenuItem = missionCommands.addCommandForCoalition(2, "Bomber: Destroy", capControlMenu, despawnBomber)
	end

    if destroySeadMenuItem then
        missionCommands.removeItemForCoalition(2, destroySeadMenuItem)
        destroySeadMenuItem = nil
    end
    if seadActive then
        destroySeadMenuItem = missionCommands.addCommandForCoalition(2, "SEAD: Destroy", capControlMenu, despawnSead)
    end
	if destroyDecoyMenuItem then
        missionCommands.removeItemForCoalition(2, destroyDecoyMenuItem)
        destroyDecoyMenuItem = nil
    end
	    if decoyActive then
        destroyDecoyMenuItem = missionCommands.addCommandForCoalition(2, "DECOY: Destroy", capControlMenu, despawnDecoy)
    end
	
	if destroyNavyArtyMenuItem then
		missionCommands.removeItemForCoalition(2, destroyNavyArtyMenuItem)
		destroyNavyArtyMenuItem = nil
	end
	if navyArtyActive then
		destroyNavyArtyMenuItem = missionCommands.addCommandForCoalition(2, "Navy Artillery: Destroy", capControlMenu, despawnNavyArty)
	end
	
	if capActive then
		missionCommands.addCommandForCoalition(2, "CAP: Destroy", capControlMenu, despawnCap)
		missionCommands.addCommandForCoalition(2, "CAP: Hold Racetrack", capControlMenu, function()
			if capGroup then
				 capGroup:SwitchROE(2)
			end
			MESSAGE:New("CAP is set to (Engage If Engaged)", 15):ToAll()
		end)
		missionCommands.addCommandForCoalition(2, "CAP: Flightsweep", capControlMenu, function()
			if capGroup then
				capGroup:SwitchROE(1)
			end
			MESSAGE:New("CAP set to Engage All", 15):ToAll()
		end)
		local zoneMenu = missionCommands.addSubMenuForCoalition(2, "CAP: Reposition by Zone", capControlMenu)
		local zones = bc:getZones()
		local count = 0
		local sub1
		for _, v in ipairs(zones) do
			if v.active and (v.side == 2 or (v.side == 0 and (not v.NeutralAtStart or v.firstCaptureByRed))) and (not v.zone:lower():find("hidden")) then
				count = count + 1
				local zoneSubMenu
				if count < 10 then
					zoneSubMenu = missionCommands.addSubMenuForCoalition(2, v.zone, zoneMenu)
				elseif count == 10 then
					sub1 = missionCommands.addSubMenuForCoalition(2, "More", zoneMenu)
					zoneSubMenu = missionCommands.addSubMenuForCoalition(2, v.zone, sub1)
				elseif count % 9 == 1 then
					sub1 = missionCommands.addSubMenuForCoalition(2, "More", sub1)
					zoneSubMenu = missionCommands.addSubMenuForCoalition(2, v.zone, sub1)
				else
					zoneSubMenu = missionCommands.addSubMenuForCoalition(2, v.zone, sub1)
				end
				for _, headingName in ipairs({"Orbit","Hot 360","Hot 045","Hot 090","Hot 135","Hot 180","Hot 225","Hot 270","Hot 315"}) do
					if headingName == "Orbit" then
						missionCommands.addCommandForCoalition(2, headingName, zoneSubMenu, function()
							local zone = ZONE:FindByName(v.zone)
							if not zone then return end
							local coord = zone:GetCoordinate()
							setCapRacetrack(coord, 045, 0, v.zone)
							MESSAGE:New("CAP is onroute to " .. v.zone .. ".", 20):ToAll()
						end)
					else
						local headingVal = capHeadings[headingName]
						local headingMenu = missionCommands.addSubMenuForCoalition(2, headingName, zoneSubMenu)
						for _, legName in ipairs({"Orbit", "10 NM Leg", "20 NM Leg", "30 NM Leg", "40 NM Leg", "50 NM Leg"}) do
							local legVal = capLegs[legName]
							missionCommands.addCommandForCoalition(2, legName, headingMenu, function()
								local zone = ZONE:FindByName(v.zone)
								if not zone then return end
								local coord = zone:GetCoordinate()
								setCapRacetrack(coord, headingVal, legVal)
								MESSAGE:New("CAP is repositioning at " .. v.zone .. " with a new racetrack, heading " .. headingVal .. "°, " .. tostring(legVal) .. " miles leg.", 20):ToAll()
							end)
						end
					end
				end
			end
		end

		local posMenu = missionCommands.addSubMenuForCoalition(2, "CAP: Reposition by Position", capControlMenu)
		for _, dirName in ipairs({"Reposition 360", "Reposition 045", "Reposition 090", "Reposition 135", "Reposition 180", "Reposition 225", "Reposition 270", "Reposition 315"}) do
			local dirVal = capPositionDirections[dirName]
			local dirMenu = missionCommands.addSubMenuForCoalition(2, dirName, posMenu)
			for _, distName in ipairs({"0 NM", "10 NM", "20 NM", "30 NM", "40 NM", "50 NM", "60 NM", "70 NM", "80 NM", "90 NM", "100 NM"}) do
				local distVal = capPositionDistances[distName]
				local distMenu = missionCommands.addSubMenuForCoalition(2, distName, dirMenu)
				for _, headingName in ipairs({"Orbit","Hot 360","Hot 045","Hot 090","Hot 135","Hot 180","Hot 225","Hot 270","Hot 315"}) do
					if headingName == "Orbit" then
						missionCommands.addCommandForCoalition(2, headingName, distMenu, function()
							if capGroup then
								local offsetCoord = capGroup:GetCoordinate():Translate(UTILS.NMToMeters(distVal), dirVal, true)
								setCapRacetrack(offsetCoord, 045, 0)
								MESSAGE:New("CAP is about to " .. dirName .. " for " .. distName .. " and orbit.", 20):ToAll()
							end
						end)
					else
						local headingVal = capHeadings[headingName]
						local headingMenu = missionCommands.addSubMenuForCoalition(2, headingName, distMenu)
						for _, legName in ipairs({"Orbit", "10 NM Leg", "20 NM Leg", "30 NM Leg", "40 NM Leg", "50 NM Leg"}) do
							local legVal = capLegs[legName]
							missionCommands.addCommandForCoalition(2, legName, headingMenu, function()
								if capGroup then
									local offsetCoord = capGroup:GetCoordinate():Translate(UTILS.NMToMeters(distVal), dirVal, true)
									setCapRacetrack(offsetCoord, headingVal, legVal)
									MESSAGE:New("CAP is about to " .. dirName .. " " .. distName .. " with a new racetrack, heading " .. headingVal .. "°, " .. tostring(legVal) .. " miles leg.", 20):ToAll()
								end
							end)
						end
					end
				end
			end
		end
	end
end


function spawnCapAt(zoneName, heading, leg)
    if capActive then return end
    local zone = ZONE:FindByName(zoneName)
    if not zone then return end
    local coordVec3 = zone:GetCoordinate():GetVec3()
local SpawnCords = zone:GetCoordinate()
coordVec3.y = 7620
local coord = COORDINATE:NewFromVec3(coordVec3, heading)
local capSpawnName = capTemplate .. "_" .. tostring(capSpawnIndex)
local g = Respawn.SpawnAtPoint( capTemplate, coord, heading, 2 )
if not g then return end
timer.scheduleFunction(function(group, time)
local spawnedGroup = GROUP:FindByName(group:getName())
        capGroup = FLIGHTGROUP:New(spawnedGroup)
		capGroup:GetGroup():CommandSetUnlimitedFuel(false)
		capGroup:SetOutOfAAMRTB(true):SetSpeed(250)
		local homebase, distance = SpawnCords:GetClosestAirbase(0, 2)
		if homebase then
			capGroup:SetHomebase(homebase)
		end
		local formation = 196610
		if leg == 0 then
			capSpeed = 330
			formation = 393217
			-- CapMissionOrbit = AUFTRAG:NewORBIT_CIRCLE_EngageTargets(coord,capAltitude,capSpeed,8,formation,50)
			CapMissionOrbit = AUFTRAG:NewORBIT_CIRCLE(coord, capAltitude, capSpeed)
			CapMissionOrbit.missionTask=ENUMS.MissionTask.CAP
			CapMissionOrbit:SetEngageDetected(40, {"Air"})
			CapMissionOrbit:SetROT(2)
			CapMissionOrbit:SetROE(2)
			CapMissionOrbit:SetFormation(196610)
			capGroup:AddMission(CapMissionOrbit)
			capGroup:MissionStart(CapMissionOrbit)
		else
			local capSpeed = 400
			-- CapMissionPatrol = AUFTRAG:NewPATROLRACETRACK_EngageTargets(coord,capAltitude,capSpeed,heading,leg,formation,50)
			CapMissionPatrol = AUFTRAG:NewORBIT(coord, capAltitude, capSpeed, heading, leg)
			CapMissionPatrol.missionTask=ENUMS.MissionTask.CAP
			CapMissionPatrol:SetEngageDetected(40, {"Air"})
			CapMissionPatrol:SetROT(2)
			CapMissionPatrol:SetROE(2)
			CapMissionPatrol:SetMissionSpeed(450)
			CapMissionPatrol:SetFormation(196610)
			capGroup:AddMission(CapMissionPatrol)
			capGroup:MissionStart(CapMissionPatrol)
		end

		function capGroup:OnAfterLanded(From, Event, To)
    	self:ScheduleOnce(5, function() self:Destroy() end)
		end
		function capGroup:OnAfterOutOfMissilesAA(From, Event, To)
			capGroup:SwitchROE(2)
			trigger.action.outText("CAP is out of missiles, returning to base", 20)
		end
		
		function capGroup:OnAfterDead(From, Event, To)
			local landed = (From=="Landed") or (From=="Arrived")
			capGroup:__Stop(5)
			capGroup  = nil
			capActive = false
			buildCapControlMenu()
			if landed then
				trigger.action.outText("CAP group have landed", 20)
			else
				trigger.action.outText("CAP group have been killed", 20)
			end
		end

		local msg = (leg == 0)
            and ("CAP on station orbiting at " .. zoneName .. ".")
            or  ("CAP on station at " .. zoneName .. ", setting up racetrack " .. heading .. "°, " .. tostring(leg) .. " miles leg.")
		MESSAGE:New(msg, 20):ToAll()

		if capParentMenu then
		missionCommands.removeItemForCoalition(2, capParentMenu)
		capParentMenu = nil
		end
	end, g, timer.getTime() + 1)
    capActive = true
	buildCapControlMenu()


	capSpawnIndex = capSpawnIndex + 1
end



function buildCapMenu()
    if capParentMenu then
        missionCommands.removeItemForCoalition(2, capParentMenu)
        capParentMenu = nil
    end
    capParentMenu = missionCommands.addSubMenuForCoalition(2, "Request CAP from")
    local zones = bc:getZones()
    local count = 0
    local sub1
	local zoneMenu
    for _, v in ipairs(zones) do
        if v.side == 2 and (not v.zone:lower():find("hidden")) then
            count = count + 1
			local zoneName = v.zone
            if count < 10 then
                zoneMenu = missionCommands.addSubMenuForCoalition(2, v.zone, capParentMenu)
            elseif count == 10 then
                sub1 = missionCommands.addSubMenuForCoalition(2, "More", capParentMenu)
                zoneMenu = missionCommands.addSubMenuForCoalition(2, v.zone, sub1)
            elseif count % 9 == 1 then
                sub1 = missionCommands.addSubMenuForCoalition(2, "More", sub1)
                zoneMenu = missionCommands.addSubMenuForCoalition(2, v.zone, sub1)
            else
                zoneMenu = missionCommands.addSubMenuForCoalition(2, v.zone, sub1)
            end
            for _, headingName in ipairs({"Orbit","Hot 360","Hot 045","Hot 090","Hot 135","Hot 180","Hot 225","Hot 270","Hot 315"}) do
                if headingName == "Orbit" then
                    missionCommands.addCommandForCoalition(2, headingName, zoneMenu, function()
                        spawnCapAt(zoneName, 045, 0)
                    end)
                else
                    local headingVal = capHeadings[headingName]
                    local headingMenu = missionCommands.addSubMenuForCoalition(2, headingName, zoneMenu)
                    for _, legName in ipairs({"10 NM Leg", "20 NM Leg", "30 NM Leg", "40 NM Leg", "50 NM Leg"}) do
                        local legVal = capLegs[legName]
                        missionCommands.addCommandForCoalition(2, legName, headingMenu, function()
                            spawnCapAt(zoneName, headingVal, legVal)
                        end)
                    end
                end
            end
        end
    end
end	
-- Cas
casActive = false
casGroup = nil
casTemplate = (Era == 'Coldwar') and 'DynamicCas_Template_CW' or 'DynamicCas_Template'
casSpawnIndex = 7
CASTargetMenu = nil

function despawnCas()
  if casGroup then
    casGroup:Despawn()
  end
end


function spawnCasAt(zoneName, targetZoneName)
    if casActive then return end
    local zone = ZONE:FindByName(zoneName)
    local targetZone = ZONE:FindByName(targetZoneName)
    if not zone or not targetZone then return end
    local coord = zone:GetCoordinate()
	local SpawnCords = zone:GetCoordinate()
	coord:SetAltitude(7620)
    local targetCoord = targetZone:GetCoordinate()
    local heading = coord:GetAngleDegrees(coord:GetDirectionVec3(targetCoord))
    local casSpawnName = casTemplate .. tostring(casSpawnIndex)
    local tpl = UTILS.DeepCopy(_DATABASE.Templates.Groups[casTemplate].Template)
    local casSpawn = SPAWN:NewFromTemplate(tpl, casSpawnName, nil, true)
   casSpawn:InitHeading(heading):InitSkill("Excellent"):OnSpawnGroup(function(spawnedGroup)
	casGroup = FLIGHTGROUP:New(spawnedGroup)
	casGroup:GetGroup():CommandSetUnlimitedFuel(false)
	casGroup:SetOutOfAGMRTB(true):SetSpeed(250)
	local homebase, distance = SpawnCords:GetClosestAirbase(0, 2)
	if homebase then
		casGroup:SetHomebase(homebase)
	end
    local setGroup   = SET_GROUP:New()
    local setStatic = SET_STATIC:New()
    local zn = bc:getZoneByName(targetZoneName)
    if zn.built then
        for _, v in pairs(zn.built) do
            local grp = GROUP:FindByName(v)
            if grp then
                setGroup:AddGroup(grp)
            end
            local st = STATIC:FindByName(v,false)
            if st then
                setStatic:AddStatic(st)
            end
        end
    end

local CasMission = AUFTRAG:NewBAI(setGroup, 27000)
	CasMission.missionFraction=0.65
	CasMission:SetMissionAltitude(27000)
	CasMission:AddConditionSuccess(function() return bc:getZoneByName(targetZoneName).side == 0 end)
	CasMission:SetWeaponExpend(AI.Task.WeaponExpend.ONE)
	CasMission:SetEngageAsGroup(false)
	CasMission:SetMissionSpeed(700)
	casGroup:AddMission(CasMission)
	casGroup:MissionStart(CasMission)
	function CasMission:OnAfterExecuting(From, Event, To)
		casGroup:SwitchROE(2)
		CasMission:SetFormation(131075)
		CasMission:SetMissionSpeed(380)
	end
	function CasMission:OnAfterSuccess(From, Event, To)
		if setStatic:Count() < 0 then
			trigger.action.outTextForCoalition(2, "CAS group has successfully completed its mission", 15)
		end
	end
if setStatic:Count() > 0 then
    local auftragstatic = AUFTRAG:NewBAI(setStatic, 25000)
	auftragstatic:SetWeaponExpend(AI.Task.WeaponExpend.ONE)
	auftragstatic:SetEngageAsGroup(false)
	auftragstatic:SetMissionSpeed(600)
	casGroup:AddMission(auftragstatic)
	function auftragstatic:OnAfterExecuting(From, Event, To)
		casGroup:SwitchROE(1)
		auftragstatic:SetFormation(131075)
		auftragstatic:SetMissionSpeed(380)
	end
	function auftragstatic:OnAfterSuccess(From, Event, To)
		trigger.action.outTextForCoalition(2, "CAS group has successfully completed its mission", 15)
	end
end
	function casGroup:OnAfterLanded(From, Event, To)
		self:ScheduleOnce(5, function() self:Destroy() end)
	end
	function casGroup:OnAfterOutOfMissilesAG(From, Event, To)
		casGroup:SwitchROE(2)
		trigger.action.outTextForCoalition(2, "CAS group is Winchester, returning to base", 15)
	end
	function casGroup:OnAfterDead(From, Event, To)
		local landed = (From=="Landed") or (From=="Arrived")
		casGroup:__Stop(5)
		casGroup = nil
		casActive = false
		buildCapControlMenu()
		if landed then
			trigger.action.outText("CAS group have landed",20)
		else
			trigger.action.outText("CAS group have been killed",20)
		end
	end

    trigger.action.outTextForCoalition(2, "CAS flight launched from " .. zoneName .. " to attack " .. targetZoneName, 15)
	end)
    casGroup = nil
    casActive = true
    casSpawn:SpawnFromCoordinate(coord)
    casSpawnIndex = casSpawnIndex + 1
	buildCapControlMenu()
end
-- decoy
decoyActive = false
decoyGroup = nil
decoyTemplate = (Era == 'Coldwar') and "DynamicDecoy_Template_CW" or 'DynamicDecoy_Template'
decoySpawnIndex = 1
DECOYTargetMenu = nil
function despawnDecoy()
  if decoyGroup then
    decoyGroup:Despawn()
  end
end

function spawnDecoyAt(zoneName, targetZoneName)
    if decoyActive then return end
    local zone = ZONE:FindByName(zoneName)
    local targetZone = ZONE:FindByName(targetZoneName)
    if not zone or not targetZone then return end
    local coord = zone:GetCoordinate()
    local SpawnCords = zone:GetCoordinate()
    coord:SetAltitude(12000)
    local targetCoord = targetZone:GetCoordinate()
    local heading = coord:GetAngleDegrees(coord:GetDirectionVec3(targetCoord))
    local decoySpawnName = decoyTemplate .. tostring(decoySpawnIndex)
    local tpl = UTILS.DeepCopy(_DATABASE.Templates.Groups[decoyTemplate].Template)
    local decoySpawn = SPAWN:NewFromTemplate(tpl, decoySpawnName, nil, true):InitHeading(heading)
    decoySpawn:InitSkill("Excellent"):OnSpawnGroup(function(spawnedGroup)
    decoyGroup = FLIGHTGROUP:New(spawnedGroup)
    local homebase, distance = SpawnCords:GetClosestAirbase(0, 2)
    if homebase then
        decoyGroup:SetHomebase(homebase)
    end
    local decoyTargets = SET_GROUP:New()
    local zn = bc:getZoneByName(targetZoneName)
    if zn and zn.built then
        for _, v in pairs(zn.built) do
            local group = GROUP:FindByName(v)
            if group then
                decoyTargets:AddGroup(group)
            end
        end
    end
	local DecoyMission = AUFTRAG:NewBAI(decoyTargets, 33000)
	--local DecoyMission = AUFTRAG:NewSEADInZone(targetZone, 33000)
    DecoyMission.missionFraction = 0.3
	DecoyMission:SetWeaponExpend(AI.Task.WeaponExpend.ALL)
	DecoyMission:SetMissionSpeed(550)
	decoyGroup:SetSpeed(650)
	decoyGroup:AddMission(DecoyMission)
    function DecoyMission:OnAfterExecuting(From, Event, To)
    DecoyMission:SetROE(1)
    end
    function decoyGroup:OnAfterLanded(From, Event, To)
        self:ScheduleOnce(5, function() self:Destroy() end)
    end
	function DecoyMission:OnAfterSuccess(From, Event, To)
		trigger.action.outTextForCoalition(2, "Decoy Group has successfully completed its mission", 15)
	end
    function decoyGroup:OnAfterOutOfMissilesAG(From, Event, To)
		decoyGroup:SwitchROE(1)
        trigger.action.outTextForCoalition(2, "Decoy Group is now RTB", 15)
    end
    function decoyGroup:OnAfterDead(From, Event, To)
		local landed = (From=="Landed") or (From=="Arrived")
			decoyGroup:__Stop(5)
			decoyActive = false
			decoyGroup = nil
			buildCapControlMenu()
            if landed then
                trigger.action.outText("Decoy group have landed", 20)
            else
                trigger.action.outText("Decoy group have been killed", 20)
            end
        end
    trigger.action.outTextForCoalition(2, "Decoy flight launched from " .. zoneName .. " to attack " .. targetZoneName, 15)
    end)
    decoyActive = true
    decoySpawn:SpawnFromCoordinate(coord)
    buildCapControlMenu()
    decoySpawnIndex = decoySpawnIndex + 1
end


seadActive = false
seadGroup = nil
seadTemplate = (Era == 'Coldwar') and "DynamicSead_Template_CW" or 'DynamicSead_Template'
local seadSpawnIndex = 1
local SEADTargetMenu = nil


function despawnSead()
  if seadGroup then
    seadGroup:Despawn()
  end
end

function spawnSeadAt(zoneName, targetZoneName)
    if seadActive then return end
    local zone = ZONE:FindByName(zoneName)
    local targetZone = ZONE:FindByName(targetZoneName)
    if not zone or not targetZone then return end
    local coord = zone:GetCoordinate()
	local SpawnCords = zone:GetCoordinate()
	coord:SetAltitude(7620)
    local targetCoord = targetZone:GetCoordinate()
    local heading = coord:GetAngleDegrees(coord:GetDirectionVec3(targetCoord))
	local seadSpawnName = seadTemplate .. tostring(seadSpawnIndex)
	local g = Respawn.SpawnAtPoint( seadTemplate, coord, heading, 5 )
		if not g then return end
	timer.scheduleFunction(function(group, time)
		local SpawnGroup = GROUP:FindByName(group:getName())
		seadGroup = FLIGHTGROUP:New(SpawnGroup)
		seadGroup:GetGroup():CommandSetUnlimitedFuel(false)
		seadGroup:SetOutOfAGMRTB(true):SetSpeed(250)
		local homebase, distance = SpawnCords:GetClosestAirbase(0, 2)
		if homebase then
			seadGroup:SetHomebase(homebase)
		end	
		
		local fallbackUnits = {}
		local seadTargets = SET_UNIT:New()
		local zn = bc:getZoneByName(targetZoneName)
		for _, v in pairs(zn.built) do
			local group = GROUP:FindByName(v)
			if group then
				for _, unit in ipairs(group:GetUnits()) do
					if unit:HasAttribute("Air Defence") then
						seadTargets:AddUnit(unit)
					else
					 table.insert(fallbackUnits, unit)
					end
				end
			end	
		end
		seadTargets:ForEachUnit(function(unit)end)

local SeadMission
if seadTargets:Count() > 0 then
    SeadMission = AUFTRAG:NewBAI(seadTargets, 25000)
	
else
    for _, u in ipairs(fallbackUnits) do
        seadTargets:AddUnit(u)
    end
    SeadMission = AUFTRAG:NewBAI(seadTargets, 25000)
end

	fallbackUnits = nil
	SeadMission.missionFraction=0.4
	SeadMission:SetWeaponExpend(AI.Task.WeaponExpend.ALL)
	SeadMission:SetMissionSpeed(600)
	SeadMission:SetMissionAltitude(25000)
	seadGroup:AddMission(SeadMission)
	function SeadMission:OnAfterExecuting(From, Event, To)
	seadGroup:SwitchROE(1)
	--SeadMission:SetEngageDetected(15)
	seadGroup:SwitchROT(3)
	SeadMission:SetMissionSpeed(450)
	end
	function SeadMission:OnAfterSuccess(From, Event, To)
		trigger.action.outTextForCoalition(2, "SEAD Group has successfully completed its mission", 15)
	end
	function seadGroup:OnAfterLanded(From, Event, To)

		self:ScheduleOnce(5, function() self:Destroy() end)
	end
	function seadGroup:OnAfterOutOfMissilesAG(From, Event, To)
		seadGroup:SwitchROE(2)
		trigger.action.outTextForCoalition(2, "SEAD Group is now RTB", 15)
	end
	function seadGroup:OnAfterDead(From, Event, To)
		local landed = (From=="Landed") or (From=="Arrived")
		seadGroup:__Stop(5)
		seadGroup  = nil
		seadActive = false
		buildCapControlMenu()
		if landed then
			trigger.action.outTextForCoalition(2, "SEAD Group have landed", 15)
		else
			trigger.action.outTextForCoalition(2, "SEAD Group have been killed", 15)
		end
	end
	trigger.action.outTextForCoalition(2, "SEAD flight launched from " .. zoneName .. " to attack " .. targetZoneName, 15)
  end, g, timer.getTime() + 1)
	seadActive = true
	buildCapControlMenu()
    seadSpawnIndex = seadSpawnIndex + 1
end


----- Custom Missions -----
-- Debug logging flags - set to false to disable detailed logging
V1_DEBUG_LOGGING = false
NAVY_ARTY_DEBUG_LOGGING = false
BOMBER_DEBUG_LOGGING = false
BLUE_BOMBER_DEBUG_LOGGING = false
RED_INTERCEPTOR_DEBUG_LOGGING = false

-- Helper functions for debug logging
local function v1Log(message)
    if V1_DEBUG_LOGGING then
        env.info(message)
    end
end

local function navyArtyLog(message)
    if NAVY_ARTY_DEBUG_LOGGING then
        env.info(message)
    end
end

local function bomberLog(message)
    if BOMBER_DEBUG_LOGGING then
        env.info(message)
    end
end

local function blueBomberLog(message)
    if BLUE_BOMBER_DEBUG_LOGGING then
        env.info(message)
    end
end

local function redInterceptorLog(message)
    if RED_INTERCEPTOR_DEBUG_LOGGING then
        env.info(message)
    end
end



-- Navy Artillery
navyArtyActive = false
navyArtyGroup = nil
navyArtyTemplate = 'UK_NavyArty' -- Your navy group name from Navy_arty.lua
navyArtyStriker = 'AXE_NavyArty_Striker'
navyArtySpawnIndex = 1
NavyArtyTargetMenu = nil
destroyNavyArtyMenuItem = nil

function despawnNavyArty()
    if navyArtyGroup then
        -- Stop all schedulers before despawning (use pcall to avoid errors)
        pcall(function() navyArtyGroup:Stop() end)
        pcall(function() navyArtyGroup:Despawn() end)
        navyArtyActive = false
        navyArtyGroup = nil
        trigger.action.outTextForCoalition(2, "Naval Artillery Group despawned.", 10)
        buildCapControlMenu()
    end
end

function spawnNavyArtyAt(zoneName, targetZoneName, strikerZoneName)
    if navyArtyActive then 
        trigger.action.outTextForCoalition(2, "Naval Artillery already active!", 10)
        return 
    end
    
    local zone = ZONE:FindByName(zoneName)
    local targetZone = ZONE:FindByName(targetZoneName)
    local strikerZone = strikerZoneName and ZONE:FindByName(strikerZoneName) or nil
    
    if not zone or not targetZone then 
        trigger.action.outTextForCoalition(2, "Invalid zone selection for Naval Artillery!", 10)
        return 
    end
    
    local coord = zone:GetCoordinate()
    local targetCoord = targetZone:GetCoordinate()
    
    if not coord or not targetCoord then
        trigger.action.outTextForCoalition(2, "Invalid coordinates for Naval Artillery!", 10)
        return
    end
    
    -- Set altitude to sea level and validate water surface
    coord:SetAltitude(0)
    local surfaceType = coord:GetSurfaceType()
    if surfaceType ~= land.SurfaceType.WATER and surfaceType ~= land.SurfaceType.SHALLOW_WATER then
        trigger.action.outTextForCoalition(2, "Naval Artillery spawn zone must be over water!", 15)
        return
    end
    
    -- Use SPAWN for naval groups (not Respawn.SpawnAtPoint which is for aircraft)
    local navySpawn = SPAWN:New(navyArtyTemplate)
    
    -- Spawn at coordinate
    local spawnedGroup = navySpawn:SpawnFromCoordinate(coord)
    
    if not spawnedGroup then 
        trigger.action.outTextForCoalition(2, "Failed to spawn Naval Artillery!", 15)
        navyArtyActive = false
        return 
    end
    
    -- Schedule the setup after spawn to ensure group is fully initialized (increased to 5 seconds)
    timer.scheduleFunction(function()
        local group = GROUP:FindByName(spawnedGroup:GetName())
        if not group or not group:IsAlive() then
            trigger.action.outTextForCoalition(2, "Naval Artillery group not found after spawn!", 15)
            navyArtyActive = false
            return
        end
        
        -- Create NAVYGROUP using MOOSE
        navyArtyGroup = NAVYGROUP:New(group)
        
        if not navyArtyGroup then
            trigger.action.outTextForCoalition(2, "Failed to create Naval Artillery Group!", 15)
            navyArtyActive = false
            return
        end
        
        -- Configure navy group
        --navyArtyGroup:SetVerbosity(0)  -- Reduce verbosity to minimize logging errors
        navyArtyGroup:AddWeaponRange(1, 8, ENUMS.WeaponFlag.Auto)
        
        -- Get all groups in target zone for artillery missions (fixed coalition filter)
        local targetGroups = SET_GROUP:New():FilterZones({targetZone}):FilterCoalitions("red"):FilterActive():FilterOnce()
        
        if targetGroups:Count() == 0 then
            trigger.action.outTextForCoalition(2, "No targets found in " .. targetZoneName .. " for Naval Artillery!", 15)
            despawnNavyArty()
            return
        end
        
        -- Create artillery missions for each group in the target zone
        local missionCount = 0
        targetGroups:ForEachGroup(function(targetGroup)
            if targetGroup and targetGroup:IsAlive() then
                -- Create ARTY mission with 100m radius
                local artyMission = AUFTRAG:NewARTY(targetGroup, nil, 250)
                artyMission:SetWeaponType(ENUMS.WeaponFlag.Auto)
                
                -- Add mission to navy group
                navyArtyGroup:AddMission(artyMission)
                missionCount = missionCount + 1
            end
        end)
        
        trigger.action.outTextForCoalition(2, 
            string.format("Naval Artillery engaging %d targets at %s", 
            missionCount, targetZoneName), 20)
        
        -- Monitor mission completion
        function navyArtyGroup:OnAfterMissionDone(From, Event, To, Mission)
            trigger.action.outTextForCoalition(2, "Naval Artillery mission completed!", 15)
        end
        
        -- Handle group death
        function navyArtyGroup:OnAfterDead(From, Event, To)
            pcall(function() navyArtyGroup:Stop() end)
            navyArtyGroup = nil
            navyArtyActive = false
            buildCapControlMenu()
            trigger.action.outTextForCoalition(2, "Naval Artillery Group destroyed!", 15)
        end
        
        -- Spawn red striker bomber group if striker zone is provided
        if strikerZone then
            timer.scheduleFunction(function()
                navyArtyLog("[NAVY_STRIKER_LOG] ===== Starting Striker Spawn =====")
                local strikerCoord = strikerZone:GetCoordinate()
                strikerCoord:SetAltitude(7620)
                
                navyArtyLog(string.format("[NAVY_STRIKER_LOG] Striker spawn zone: %s", strikerZoneName))

                
                local strikerSpawn = SPAWN:New(navyArtyStriker)
                local strikerGroup = strikerSpawn:SpawnFromCoordinate(strikerCoord)
                
                if strikerGroup then
                    navyArtyLog(string.format("[NAVY_STRIKER_LOG] ✓ Striker group spawned: %s", strikerGroup:GetName()))
                    
                    timer.scheduleFunction(function()
                        navyArtyLog("[NAVY_STRIKER_LOG] ----- Assigning Mission to Striker -----")
                        
                        -- Get the actual spawned navy group object
                        local spawnedNavyGroup = GROUP:FindByName(spawnedGroup:GetName())
                        navyArtyLog(string.format("[NAVY_STRIKER_LOG] Looking for navy group: %s", spawnedGroup:GetName()))
                        
                        if not spawnedNavyGroup then
                            env.info("[NAVY_STRIKER_LOG] ✗ ERROR: Cannot find spawned navy group")
                            trigger.action.outTextForCoalition(1, "Striker mission failed: Navy target not found", 10)
                            return
                        end
                        
                        env.info(string.format("[NAVY_STRIKER_LOG] ✓ Found navy group: %s", spawnedNavyGroup:GetName()))
                        navyArtyLog(string.format("[NAVY_STRIKER_LOG]   Navy group size: %d units", spawnedNavyGroup:GetSize()))
                        navyArtyLog(string.format("[NAVY_STRIKER_LOG]   Navy group alive: %s", tostring(spawnedNavyGroup:IsAlive())))
                        
                        -- Log navy group units
                        -- for i, unit in ipairs(spawnedNavyGroup:GetUnits()) do
                        --     env.info(string.format("[NAVY_STRIKER_LOG]   Unit %d: %s (Type: %s)", 
                        --         i, unit:GetName(), unit:GetTypeName()))
                        -- end
                        
                        -- Create FLIGHTGROUP for striker
                        local strikerFG = FLIGHTGROUP:New(strikerGroup)
                        if not strikerFG then
                            env.info("[NAVY_STRIKER_LOG] ✗ ERROR: Failed to create FLIGHTGROUP")
                            return
                        end
                        env.info(string.format("[NAVY_STRIKER_LOG] ✓ Created FLIGHTGROUP: %s", strikerFG:GetName()))
                        
                        -- Create ANTISHIP mission - pass the GROUP directly, not a SET_GROUP
                        -- This matches the MOOSE demo pattern: AUFTRAG:NewANTISHIP(navygroup:GetGroup(), 1500)
                        local strikerMission = AUFTRAG:NewANTISHIP(spawnedNavyGroup, 1500)
                        strikerMission:SetMissionAltitude(3000)
                        strikerMission:SetWeaponExpend(AI.Task.WeaponExpend.HALF)
                        strikerMission:SetEngageAsGroup(false)
                        strikerMission:SetMissionSpeed(200)
                        
                        navyArtyLog("[NAVY_STRIKER_LOG] ✓ Created ANTISHIP mission targeting: " .. spawnedNavyGroup:GetName())
                        
                        strikerFG:AddMission(strikerMission)
                        --strikerFG:MissionStart(strikerMission)
                        
                        env.info("[NAVY_STRIKER_LOG] ✓ Mission assigned and started")
                        trigger.action.outTextForCoalition(1, 
                            string.format("Enemy bombers targeting %s launched from %s", 
                            spawnedNavyGroup:GetName(), strikerZoneName), 20)
                            
                            function strikerMission:OnAfterExecuting(From, Event, To)
                                strikerFG:SwitchROE(1)
                                strikerMission:SetMissionSpeed(200)
                            end
                            
                            function strikerFG:OnAfterLanded(From, Event, To)
                                self:ScheduleOnce(5, function() self:Destroy() end)
                            end
                            
                            function strikerFG:OnAfterDead(From, Event, To)
                                local landed = (From == "Landed") or (From == "Arrived")
                                strikerFG:__Stop(5)
                                if landed then
                                    trigger.action.outTextForCoalition(2, "Enemy striker group has landed", 15)
                                else
                                    trigger.action.outTextForCoalition(2, "Enemy striker group destroyed!", 15)
                                end
                            end
                            
                        trigger.action.outTextForCoalition(2, "Enemy bombers launched from " .. strikerZoneName .. " to attack Naval Artillery!", 20)
                    end, nil, timer.getTime() + 2)
                else
                    env.info("Failed to spawn striker group from " .. strikerZoneName)
                end
            end, nil, timer.getTime() + 30) -- Delay striker spawn by 30 seconds after navy group
        end
        
        -- Auto-despawn when all missions complete or group destroyed
        timer.scheduleFunction(function()
            if not navyArtyActive then
                return -- Stop checking
            end
            
            -- Check if group still exists and has alive units
            local groupObj = GROUP:FindByName(group:GetName())
            if not groupObj then
                -- Group completely destroyed
                if navyArtyGroup then
                    pcall(function() navyArtyGroup:Stop() end)
                end
                navyArtyActive = false
                navyArtyGroup = nil
                buildCapControlMenu()
                return
            end
            
            local aliveCount = groupObj:CountAliveUnits()
            if aliveCount == 0 then
                -- All units dead
                if navyArtyGroup then
                    pcall(function() navyArtyGroup:Stop() end)
                end
                navyArtyActive = false
                navyArtyGroup = nil
                buildCapControlMenu()
                return
            end
            
            -- Check if missions are complete
            if navyArtyGroup then
                local success, missions = pcall(function() return navyArtyGroup:GetMissions() end)
                if success and missions and #missions == 0 then
                    trigger.action.outTextForCoalition(2, "All Naval Artillery missions complete.", 15)
                    despawnNavyArty()
                    return
                end
            end
            
            -- Schedule next check
            return timer.getTime() + 15 -- Check every 15 seconds
        end, nil, timer.getTime() + 30) -- First check after 30 seconds
        
        end, nil, timer.getTime() + 5) -- Wait 5 seconds for group to fully initialize
    
    navyArtyActive = true
    buildCapControlMenu()
    navyArtySpawnIndex = navyArtySpawnIndex + 1
end

-- Bomber Striker Red
bomberActive = false
bomberGroup = nil
bomberEscortGroup = nil
bomberTemplate = (Era == 'Coldwar') and "DynamicBomber_Template_CW" or 'DynamicBomber_Template'
bomberEscortTemplate = (Era == 'Coldwar') and "DynamicBomberEscort_Template_CW" or 'DynamicBomberEscort_Template'
bomberSpawnIndex = 1
escortGroups = escortGroups or {}

function despawnBomber()
    if bomberGroup then
        bomberGroup:Despawn()
    end
end

function spawnBomberStrikerAt(spawnZoneName, targetZoneName)
    env.info("[BOMBER_LOG] ===== Starting Bomber Striker Mission =====")
    
    if bomberActive then 
        trigger.action.outTextForCoalition(1, "Bomber mission already active!", 10)
        env.info("[BOMBER_LOG] ✗ ABORT: Bomber mission already active")
        return 
    end
    
    local spawnZone = ZONE:FindByName(spawnZoneName)
    local targetZone = ZONE:FindByName(targetZoneName)
    
    bomberLog(string.format("[BOMBER_LOG] Spawn zone: %s", spawnZoneName))
    bomberLog(string.format("[BOMBER_LOG] Target zone: %s", targetZoneName))
    
    if not spawnZone or not targetZone then 
        trigger.action.outTextForCoalition(1, "Invalid zone selection for bomber mission!", 10)
        env.info("[BOMBER_LOG] ✗ ABORT: Invalid zone selection")
        return 
    end
    
    local coord = spawnZone:GetCoordinate()
    local SpawnCords = spawnZone:GetCoordinate()
    coord:SetAltitude(3048)
    local targetCoord = targetZone:GetCoordinate()
    
    bomberLog(string.format("[BOMBER_LOG] Spawn coordinate: X=%.1f, Z=%.1f, Alt=%.1f", 
        coord.x, coord.z, coord.y))
    bomberLog(string.format("[BOMBER_LOG] Target coordinate: X=%.1f, Z=%.1f", 
        targetCoord.x, targetCoord.z))
    bomberLog(string.format("[BOMBER_LOG] Bomber template: %s", bomberTemplate))
    
    local bomberSpawn = SPAWN:New(bomberTemplate)
    local spawnedGroup = bomberSpawn:SpawnFromCoordinate(coord)
    
    if not spawnedGroup then
        trigger.action.outTextForCoalition(1, "Failed to spawn bomber group!", 15)
        env.info("[BOMBER_LOG] ✗ ABORT: Failed to spawn bomber group")
        return
    end
    
    bomberLog(string.format("[BOMBER_LOG] ✓ Bomber group spawned: %s", spawnedGroup:GetName()))
    
    -- Schedule escort spawn after bomber is airborne
    timer.scheduleFunction(function()
        bomberLog("[BOMBER_LOG] ----- Checking for escort spawn (30s delay) -----")
        
        -- Spawn escort group at same location
        local escortCoord = spawnZone:GetCoordinate()
        escortCoord:SetAltitude(5000)
        
        bomberLog(string.format("[BOMBER_LOG] Escort template: %s", bomberEscortTemplate))
        
        local escortSpawn = SPAWN:New(bomberEscortTemplate)
        local escortSpawnedGroup = escortSpawn:SpawnFromCoordinate(escortCoord)
        
        if not escortSpawnedGroup then
            env.info("[BOMBER_LOG] ✗ WARNING: Failed to spawn escort group")
        else
           bomberLog(string.format("[BOMBER_LOG] ✓ Escort group spawned: %s", escortSpawnedGroup:GetName()))
            
            -- Initialize escort FLIGHTGROUP after a short delay
            timer.scheduleFunction(function()
                bomberLog("[BOMBER_LOG] ----- Initializing Escort Group (2s delay) -----")
                
                local escortGroup = GROUP:FindByName(escortSpawnedGroup:GetName())
                if not escortGroup or not escortGroup:IsAlive() then
                    env.info("[BOMBER_LOG] ✗ ERROR: Escort group not found or not alive")
                    return
                end
                
                bomberEscortGroup = FLIGHTGROUP:New(escortGroup)
                bomberEscortGroup:GetGroup():CommandSetUnlimitedFuel(false)
                bomberEscortGroup:SetSpeed(200)
                
                -- Set homebase using same method as bomber
                local homebase, distance = SpawnCords:GetClosestAirbase(0, 1)  -- Red coalition
                if homebase then
                    bomberEscortGroup:SetHomebase(homebase)
                    bomberLog(string.format("[BOMBER_LOG] ✓ Escort homebase set: %s", homebase:GetName()))
                end
                
                -- Create ESCORT mission to protect the bomber
                if bomberGroup and bomberGroup:IsAlive() then
                    -- Offset vector: 100m behind, same altitude, 200m to the right (standard escort formation)
                    local offsetVector = {x = -100, y = 0, z = 200}
                    local EscortMission = AUFTRAG:NewESCORT(bomberGroup:GetGroup(), offsetVector, 10, {"Air"})
                    EscortMission:SetMissionAltitude(10000)
                    EscortMission:SetMissionSpeed(200)
                    EscortMission:SetROE(ENUMS.ROE.WeaponFree)
                    
                    bomberEscortGroup:AddMission(EscortMission)
                    
                    env.info("[BOMBER_LOG] ✓ Escort mission configured and started")
                    trigger.action.outTextForCoalition(2, "Enemy fighter escort has launched to protect the bombers!", 15)
                    
                    -- Store escort reference for cleanup
                    if not escortGroups[bomberGroup:GetName()] then
                        escortGroups[bomberGroup:GetName()] = bomberEscortGroup
                    end
                    
                    function bomberEscortGroup:OnAfterLanded(From, Event, To)
                        self:ScheduleOnce(5, function() self:Destroy() end)
                    end
                    
                    function bomberEscortGroup:OnAfterDead(From, Event, To)
                        local landed = (From == "Landed") or (From == "Arrived")
                        bomberEscortGroup:__Stop(5)
                        bomberEscortGroup = nil
                        if landed then
                            trigger.action.outText("Enemy escort group has landed", 20)
                        else
                            trigger.action.outText("Enemy escort group has been destroyed", 20)
                        end
                    end
                else
                    env.info("[BOMBER_LOG] ✗ ERROR: Bomber group not alive for escort mission")
                end
            end, nil, timer.getTime() + 2)
        end
    end, nil, timer.getTime() + 30)
    
    timer.scheduleFunction(function()
        bomberLog("[BOMBER_LOG] ----- Initializing Bomber Group (2s delay) -----")
        
        local group = GROUP:FindByName(spawnedGroup:GetName())
        if not group or not group:IsAlive() then
            trigger.action.outTextForCoalition(1, "Bomber group not found after spawn!", 15)
            env.info("[BOMBER_LOG] ✗ ERROR: Bomber group not found or not alive")
            bomberActive = false
            return
        end
        
        env.info(string.format("[BOMBER_LOG] ✓ Found bomber group: %s", group:GetName()))
        bomberLog(string.format("[BOMBER_LOG]   Group size: %d units", group:GetSize()))
        
        -- Log bomber units
        -- for i, unit in ipairs(group:GetUnits()) do
        --     env.info(string.format("[BOMBER_LOG]   Unit %d: %s (Type: %s)", 
        --         i, unit:GetName(), unit:GetTypeName()))
        -- end
        
        bomberGroup = FLIGHTGROUP:New(group)
        bomberGroup:GetGroup():CommandSetUnlimitedFuel(false)
        bomberGroup:SetSpeed(200)
        
        env.info("[BOMBER_LOG] ✓ FLIGHTGROUP created and configured")
        
        local homebase, distance = SpawnCords:GetClosestAirbase(0, 1)  -- Red coalition
        if homebase then
            bomberGroup:SetHomebase(homebase)
            bomberLog(string.format("[BOMBER_LOG] ✓ Homebase set: %s (Distance: %.1f NM)", 
                homebase:GetName(), UTILS.MetersToNM(distance)))
        else
            env.info("[BOMBER_LOG] ✗ WARNING: No homebase found")
        end
        
        -- Find targets in the target zone using MOOSE SET filtering
        bomberLog("[BOMBER_LOG] ----- Scanning Target Zone -----")
        
        local targetSet = SET_GROUP:New()
        local targetZoneObj = bc:getZoneByName(targetZoneName)
        
        local targetCount = 0
        if targetZoneObj and targetZoneObj.built then
            bomberLog(string.format("[BOMBER_LOG] Target zone object found: %s", targetZoneName))
            bomberLog(string.format("[BOMBER_LOG] Built groups in zone: %d", 
                Utils.getTableSize(targetZoneObj.built)))
            
            for _, v in pairs(targetZoneObj.built) do
                local grp = GROUP:FindByName(v)
                if grp then
                    targetSet:AddGroup(grp)
                    targetCount = targetCount + 1
                    
                    -- Log each target group details
                    bomberLog(string.format("[BOMBER_LOG]   ✓ Target group %d: %s", targetCount, v))
                    bomberLog(string.format("[BOMBER_LOG]     Units: %d, Coalition: %s", 
                        grp:GetSize(), 
                        grp:GetCoalition() == 1 and "RED" or (grp:GetCoalition() == 2 and "BLUE" or "NEUTRAL")))
                    
                    -- Log unit types in group
                    -- for i, unit in ipairs(grp:GetUnits()) do
                    --     env.info(string.format("[BOMBER_LOG]       Unit %d: %s", i, unit:GetTypeName()))
                    -- end
                else
                    env.info(string.format("[BOMBER_LOG]   ✗ Target group not found: %s", v))
                end
            end
        else
            env.info("[BOMBER_LOG] ✗ WARNING: Target zone object not found or has no built groups")
        end
        
        bomberLog(string.format("[BOMBER_LOG] Total targets found: %d", targetCount))
        
        -- Create BAI (Battlefield Air Interdiction) mission targeting discovered groups
        bomberLog("[BOMBER_LOG] ----- Creating BAI Mission -----")
        
        if targetSet:Count() == 0 then
            trigger.action.outTextForCoalition(2, "No valid targets found for bomber strike!", 15)
            env.info("[BOMBER_LOG] ✗ ABORT: No valid targets in SET")
            bomberActive = false
            if bomberGroup then
                bomberGroup:Despawn()
            end
            return
        end
        
        bomberLog(string.format("[BOMBER_LOG] Creating BAI mission with %d target groups", targetSet:Count()))
--[[        
        local BomberMission = AUFTRAG:NewBAI(targetSet, 7000)
        BomberMission:SetWeaponExpend(AI.Task.WeaponExpend.ALL)
        BomberMission:SetMissionSpeed(200)
        BomberMission:SetMissionAltitude(7000)
        BomberMission:SetFormation(ENUMS.Formation.FixedWing.BomberElement)  -- WWII bomber formation
		BomberMission:SetEngageAsGroup(false)  -- Engage targets individually

		local BomberMission = AUFTRAG:NewBOMBCARPET(targetSet, 5000, 500)
        BomberMission:SetWeaponExpend(AI.Task.WeaponExpend.ALL)
        BomberMission:SetMissionSpeed(200)
        BomberMission:SetMissionAltitude(15000)
		BomberMission:SetFormation(ENUMS.Formation.FixedWing.BomberElement)
		BomberMission:SetEngageAsGroup(false)  -- Engage targets individually
--]]
local BomberMission = AUFTRAG:NewBOMBING(targetSet, 10000, ENUMS.WeaponFlag.Auto, false)
        BomberMission:SetWeaponExpend(AI.Task.WeaponExpend.ALL)
        BomberMission:SetMissionSpeed(200)
        BomberMission:SetMissionAltitude(10000)
		BomberMission:SetFormation(ENUMS.Formation.FixedWing.EchelonLeft)
		BomberMission:SetEngageAsGroup(true)  -- Engage targets individually


        env.info("[BOMBER_LOG] ✓ BAI mission created")
        
        bomberGroup:AddMission(BomberMission)
        
        function BomberMission:OnAfterExecuting(From, Event, To)
            bomberGroup:SwitchROE(2)
            BomberMission:SetMissionSpeed(200)
        end
        
        function BomberMission:OnAfterSuccess(From, Event, To)
            trigger.action.outTextForCoalition(2, "Enemy bomber mission completed", 15)
        end
        
        function bomberGroup:OnAfterLanded(From, Event, To)
            self:ScheduleOnce(5, function() self:Destroy() end)
        end
        
        function bomberGroup:OnAfterOutOfBombs(From, Event, To)
            bomberGroup:SwitchROE(2)
            trigger.action.outTextForCoalition(2, "Enemy bombers are Winchester, returning to base", 15)
        end
        
        function bomberGroup:OnAfterDead(From, Event, To)
            local landed = (From == "Landed") or (From == "Arrived")
            bomberGroup:__Stop(5)
            bomberGroup = nil
            bomberActive = false
            buildCapControlMenu()
            if landed then
                trigger.action.outText("Enemy bomber group has landed", 20)
            else
                trigger.action.outText("Enemy bomber group has been destroyed", 20)
            end
        end
        
        trigger.action.outTextForCoalition(2, 
            "Enemy bombers launched from " .. spawnZoneName .. " probable target " .. targetZoneName, 20)
    end, nil, timer.getTime() + 2)
    
    bomberActive = true
    buildCapControlMenu()
    bomberSpawnIndex = bomberSpawnIndex + 1
end

-- Blue Bomber Strike
bomberBlueActive = false
bomberBlueGroup = nil
bomberBlueEscortGroup = nil
bomberBlueTemplate = (Era == 'Coldwar') and "DynamicBomberBlue_Template_CW" or 'DynamicBomberBlue_Template'
bomberBlueEscortTemplate = (Era == 'Coldwar') and "DynamicBomberBlueEscort_Template_CW" or 'DynamicBomberBlueEscort_Template'
bomberBlueSpawnIndex = 1

-- RED Interceptor variables
redInterceptorActive = false
redInterceptorGroup = nil
redInterceptorTemplate = (Era == 'Coldwar') and 'RED_Interceptor_Template_CW' or 'RED_Interceptor_Template'
redInterceptorSpawnIndex = 1

function despawnBomberBlue()
    if bomberBlueGroup then
        bomberBlueGroup:Despawn()
    end
    if bomberBlueEscortGroup then
        bomberBlueEscortGroup:Despawn()
    end
end

function despawnRedInterceptor()
    if redInterceptorGroup then
        redInterceptorGroup:Despawn()
    end
end

function spawnBlueBomberStrikerAt(spawnZoneName, targetZoneName)
    env.info("[BLUE_BOMBER_LOG] ===== Starting Blue Bomber Striker Mission =====")
    
    if bomberBlueActive then 
        trigger.action.outTextForCoalition(2, "Blue bomber mission already active!", 10)
        env.info("[BLUE_BOMBER_LOG] ✗ ABORT: Blue bomber mission already active")
        return 
    end
    
    local spawnZone = ZONE:FindByName(spawnZoneName)
    local targetZone = ZONE:FindByName(targetZoneName)
    
    blueBomberLog(string.format("[BLUE_BOMBER_LOG] Spawn zone: %s", spawnZoneName))
    blueBomberLog(string.format("[BLUE_BOMBER_LOG] Target zone: %s", targetZoneName))
    
    if not spawnZone or not targetZone then 
        trigger.action.outTextForCoalition(2, "Invalid zone selection for Blue bomber mission!", 10)
        env.info("[BLUE_BOMBER_LOG] ✗ ABORT: Invalid zone selection")
        return 
    end
    
    local coord = spawnZone:GetCoordinate()
    local SpawnCords = spawnZone:GetCoordinate()
    coord:SetAltitude(6096)
    local targetCoord = targetZone:GetCoordinate()
    
    blueBomberLog(string.format("[BLUE_BOMBER_LOG] Spawn coordinate: X=%.1f, Z=%.1f, Alt=%.1f", 
        coord.x, coord.z, coord.y))
    blueBomberLog(string.format("[BLUE_BOMBER_LOG] Target coordinate: X=%.1f, Z=%.1f", 
        targetCoord.x, targetCoord.z))
    blueBomberLog(string.format("[BLUE_BOMBER_LOG] Blue bomber template: %s", bomberBlueTemplate))
    
    local bomberSpawn = SPAWN:New(bomberBlueTemplate)
    local spawnedGroup = bomberSpawn:SpawnFromCoordinate(coord)
    
    if not spawnedGroup then
        trigger.action.outTextForCoalition(2, "Failed to spawn Blue bomber group!", 15)
        env.info("[BLUE_BOMBER_LOG] ✗ ABORT: Failed to spawn Blue bomber group")
        return
    end
    
    env.info(string.format("[BLUE_BOMBER_LOG] ✓ Blue bomber group spawned: %s", spawnedGroup:GetName()))
    
    -- Schedule escort spawn after bomber is airborne
    timer.scheduleFunction(function()
        blueBomberLog("[BLUE_BOMBER_LOG] ----- Checking for escort spawn (30s delay) -----")
        
        -- Spawn escort group at same location
        local escortCoord = spawnZone:GetCoordinate()
        escortCoord:SetAltitude(6500)
        
        blueBomberLog(string.format("[BLUE_BOMBER_LOG] Escort template: %s", bomberBlueEscortTemplate))
        
        local escortSpawn = SPAWN:New(bomberBlueEscortTemplate)
        local escortSpawnedGroup = escortSpawn:SpawnFromCoordinate(escortCoord)
        
        if not escortSpawnedGroup then
            env.info("[BLUE_BOMBER_LOG] ✗ WARNING: Failed to spawn escort group")
        else
            blueBomberLog(string.format("[BLUE_BOMBER_LOG] ✓ Escort group spawned: %s", escortSpawnedGroup:GetName()))
            
            -- Initialize escort FLIGHTGROUP after a short delay
            timer.scheduleFunction(function()
                blueBomberLog("[BLUE_BOMBER_LOG] ----- Initializing Escort Group (2s delay) -----")
                
                local escortGroup = GROUP:FindByName(escortSpawnedGroup:GetName())
                if not escortGroup or not escortGroup:IsAlive() then
                    env.info("[BLUE_BOMBER_LOG] ✗ ERROR: Escort group not found or not alive")
                    return
                end
                
                bomberBlueEscortGroup = FLIGHTGROUP:New(escortGroup)
                bomberBlueEscortGroup:GetGroup():CommandSetUnlimitedFuel(false)
                bomberBlueEscortGroup:SetSpeed(200)
                
                -- Set homebase
                local homebase, distance = SpawnCords:GetClosestAirbase(0, 2)  -- Blue coalition
                if homebase then
                    bomberBlueEscortGroup:SetHomebase(homebase)
                blueBomberLog(string.format("[BLUE_BOMBER_LOG] ✓ Escort homebase set: %s", homebase:GetName()))
                end
                
                -- Create ESCORT mission to protect the bomber
                if bomberBlueGroup and bomberBlueGroup:IsAlive() then
                    local offsetVector = {x = -500, y = 0, z = -500}
                    local EscortMission = AUFTRAG:NewESCORT(bomberBlueGroup:GetGroup(), offsetVector, 10, {"Air"})
                    EscortMission:SetMissionAltitude(20000)
                    EscortMission:SetMissionSpeed(200)
                    EscortMission:SetROE(ENUMS.ROE.WeaponFree)
                    
                    bomberBlueEscortGroup:AddMission(EscortMission)
                    
                    env.info("[BLUE_BOMBER_LOG] ✓ Escort mission configured and started")
                    trigger.action.outTextForCoalition(2, "Friendly fighter escort launched to protect bombers!", 15)
                    
                    function bomberBlueEscortGroup:OnAfterLanded(From, Event, To)
                        self:ScheduleOnce(5, function() self:Destroy() end)
                    end
                    
                    function bomberBlueEscortGroup:OnAfterDead(From, Event, To)
                        local landed = (From == "Landed") or (From == "Arrived")
                        bomberBlueEscortGroup:__Stop(5)
                        bomberBlueEscortGroup = nil
                        if landed then
                            trigger.action.outText("Blue escort group has landed", 20)
                        else
                            trigger.action.outText("Blue escort group has been destroyed", 20)
                        end
                    end
                else
                    env.info("[BLUE_BOMBER_LOG] ✗ ERROR: Bomber group not alive for escort mission")
                end
            end, nil, timer.getTime() + 2)
        end
    end, nil, timer.getTime() + 30)
    
    timer.scheduleFunction(function()
        blueBomberLog("[BLUE_BOMBER_LOG] ----- Initializing Blue Bomber Group (2s delay) -----")
        
        local group = GROUP:FindByName(spawnedGroup:GetName())
        if not group or not group:IsAlive() then
            trigger.action.outTextForCoalition(2, "Blue bomber group not found after spawn!", 15)
            env.info("[BLUE_BOMBER_LOG] ✗ ERROR: Blue bomber group not found or not alive")
            bomberBlueActive = false
            return
        end
        
        blueBomberLog(string.format("[BLUE_BOMBER_LOG] ✓ Found Blue bomber group: %s", group:GetName()))
        blueBomberLog(string.format("[BLUE_BOMBER_LOG]   Group size: %d units", group:GetSize()))
        
        bomberBlueGroup = FLIGHTGROUP:New(group)
        bomberBlueGroup:GetGroup():CommandSetUnlimitedFuel(false)
        bomberBlueGroup:SetSpeed(200)
        
        env.info("[BLUE_BOMBER_LOG] ✓ FLIGHTGROUP created and configured")
        
        local homebase, distance = SpawnCords:GetClosestAirbase(0, 2)  -- Blue coalition
        if homebase then
            bomberBlueGroup:SetHomebase(homebase)
            blueBomberLog(string.format("[BLUE_BOMBER_LOG] ✓ Homebase set: %s (Distance: %.1f NM)", 
                homebase:GetName(), UTILS.MetersToNM(distance)))
        else
            env.info("[BLUE_BOMBER_LOG] ✗ WARNING: No homebase found")
        end
        
        -- Spawn RED interceptors
        spawnRedInterceptorFor(bomberBlueGroup, targetZoneName)
        
        -- Find targets in the target zone
        blueBomberLog("[BLUE_BOMBER_LOG] ----- Scanning Target Zone -----")
        
        local targetSet = SET_GROUP:New()
        local targetZoneObj = bc:getZoneByName(targetZoneName)
        
        local targetCount = 0
        if targetZoneObj and targetZoneObj.built then
            blueBomberLog(string.format("[BLUE_BOMBER_LOG] Target zone object found: %s", targetZoneName))
            
            for _, v in pairs(targetZoneObj.built) do
                local grp = GROUP:FindByName(v)
                if grp then
                    targetSet:AddGroup(grp)
                    targetCount = targetCount + 1
                    blueBomberLog(string.format("[BLUE_BOMBER_LOG]   ✓ Target group %d: %s", targetCount, v))
                end
            end
        end
        
        blueBomberLog(string.format("[BLUE_BOMBER_LOG] Total targets found: %d", targetCount))
        
        if targetSet:Count() == 0 then
            trigger.action.outTextForCoalition(2, "No valid targets found for Blue bomber strike!", 15)
            blueBomberLog("[BLUE_BOMBER_LOG] ✗ ABORT: No valid targets in SET")
            bomberBlueActive = false
            if bomberBlueGroup then
                bomberBlueGroup:Despawn()
            end
            return
        end
        
        local BomberMission = AUFTRAG:NewBOMBING(targetSet, 20000, ENUMS.WeaponFlag.Auto, false)
        BomberMission:SetWeaponExpend(AI.Task.WeaponExpend.ALL)
        BomberMission:SetMissionSpeed(200)
        BomberMission:SetMissionAltitude(20000)
        BomberMission:SetFormation(851968)
        BomberMission:SetEngageAsGroup(true)
        
        env.info("[BLUE_BOMBER_LOG] ✓ BOMBING mission created")
        
        bomberBlueGroup:AddMission(BomberMission)
        
        function BomberMission:OnAfterExecuting(From, Event, To)
            bomberBlueGroup:SwitchROE(2)
            BomberMission:SetMissionSpeed(200)
        end
        
        function BomberMission:OnAfterSuccess(From, Event, To)
            trigger.action.outTextForCoalition(2, "Blue bomber mission completed", 15)
        end
        
        function bomberBlueGroup:OnAfterLanded(From, Event, To)
            self:ScheduleOnce(5, function() self:Destroy() end)
        end
        
        function bomberBlueGroup:OnAfterOutOfBombs(From, Event, To)
            bomberBlueGroup:SwitchROE(2)
            trigger.action.outTextForCoalition(2, "Blue bombers are Winchester, returning to base", 15)
        end
        
        function bomberBlueGroup:OnAfterDead(From, Event, To)
            local landed = (From == "Landed") or (From == "Arrived")
            bomberBlueGroup:__Stop(5)
            bomberBlueGroup = nil
            bomberBlueActive = false
            buildCapControlMenu()
            if landed then
                trigger.action.outText("Blue bomber group has landed", 20)
            else
                trigger.action.outText("Blue bomber group has been destroyed", 20)
            end
        end
        
        trigger.action.outTextForCoalition(2, 
            "Friendly bombers launched from " .. spawnZoneName .. " targeting " .. targetZoneName, 20)
    end, nil, timer.getTime() + 2)
    
    bomberBlueActive = true
    buildCapControlMenu()
    bomberBlueSpawnIndex = bomberBlueSpawnIndex + 1
end

-- RED Interceptor function
function spawnRedInterceptorFor(blueBomberGroup, targetZoneName)
    env.info("[BLUE_BOMBER_LOG] ===== Starting RED Interceptor Mission =====")
    
    if redInterceptorActive then
        env.info("[BLUE_BOMBER_LOG] ✗ ABORT: RED interceptor already active")
        return
    end
    
    if not blueBomberGroup or not blueBomberGroup:IsAlive() then
        env.info("[BLUE_BOMBER_LOG] ✗ ABORT: Blue bomber group not valid")
        return
    end
    
    -- Find closest RED airbase to target zone
    local targetZone = ZONE:FindByName(targetZoneName)
    if not targetZone then
        env.info("[BLUE_BOMBER_LOG] ✗ ABORT: Target zone not found")
        return
    end
    
    local targetCoord = targetZone:GetCoordinate()
    local homebase, distance = targetCoord:GetClosestAirbase(0, 1)  -- RED coalition
    
    if not homebase then
        env.info("[BLUE_BOMBER_LOG] ✗ ABORT: No RED airbase found")
        return
    end
    
    blueBomberLog(string.format("[BLUE_BOMBER_LOG] ✓ Interceptor homebase: %s (Distance: %.1f NM)", 
        homebase:GetName(), UTILS.MetersToNM(distance)))
    
    -- Spawn interceptors hot at airbase
    local interceptorSpawn = SPAWN:New(redInterceptorTemplate)
    local spawnedGroup = interceptorSpawn:SpawnAtAirbase(homebase, SPAWN.Takeoff.Hot)
    
    if not spawnedGroup then
        env.info("[BLUE_BOMBER_LOG] ✗ ABORT: Failed to spawn interceptor group")
        return
    end
    
    blueBomberLog(string.format("[BLUE_BOMBER_LOG] ✓ RED interceptor group spawned: %s", spawnedGroup:GetName()))
    
    timer.scheduleFunction(function()
        local group = GROUP:FindByName(spawnedGroup:GetName())
        if not group or not group:IsAlive() then
            env.info("[BLUE_BOMBER_LOG] ✗ ERROR: Interceptor group not found after spawn")
            redInterceptorActive = false
            return
        end
        
        redInterceptorGroup = FLIGHTGROUP:New(group)
        redInterceptorGroup:SetHomebase(homebase)
        redInterceptorGroup:GetGroup():CommandSetUnlimitedFuel(false)
        
        -- Create INTERCEPT mission
        local InterceptMission = AUFTRAG:NewINTERCEPT(blueBomberGroup:GetGroup())
        InterceptMission:SetMissionAltitude(20000)
        InterceptMission:SetMissionSpeed(300)
        InterceptMission:SetROE(ENUMS.ROE.WeaponFree)
        
        redInterceptorGroup:AddMission(InterceptMission)
        
        env.info("[BLUE_BOMBER_LOG] ✓ INTERCEPT mission configured and started")
        trigger.action.outTextForCoalition(2, "Enemy interceptors scrambled to engage bombers!", 20)
        
        function redInterceptorGroup:OnAfterLanded(From, Event, To)
            self:ScheduleOnce(5, function() self:Destroy() end)
        end
        
        function redInterceptorGroup:OnAfterDead(From, Event, To)
            local landed = (From == "Landed") or (From == "Arrived")
            redInterceptorGroup:__Stop(5)
            redInterceptorGroup = nil
            redInterceptorActive = false
            if landed then
                trigger.action.outText("Enemy interceptors have landed", 20)
            else
                trigger.action.outText("Enemy interceptors have been destroyed", 20)
            end
        end
        
    end, nil, timer.getTime() + 2)
    
    redInterceptorActive = true
    redInterceptorSpawnIndex = redInterceptorSpawnIndex + 1
end

-- V1 Artillery
v1ArtyActive = {}  -- Changed to table to track multiple active sites
v1ArtyGroups = {}  -- Changed to table to store multiple groups
destroyV1ArtyMenuItem = nil



-- V1 Site configuration - maps V1 launch sites to their target zones
V1_SITE_CONFIG = {
    ["V1 Launch Site - Brecourt"] = {"Tangmere", "Ford", "Funtington", "Needs Oar Point"},
    ["V1 Launch Site - Herbouville"] = {"Farnborough", "Odiham"},
	["V1 Launch Site - Val Ygot"] = {"Friston", "Chailey"},
	["V1 Launch Site - Crecy Forest"] = {"BigginHill", "London"},
	["V1 Launch Site - Flixecourt"] = {"Lympne","Manston","Hawkinge", "Dover"},
	["V1 Launch Site - Wallon-Cappel"] = {"BigginHill", "London"},
	["V1 Launch Site - Neuville"] = {"BigginHill", "London", "Dover"}

	-- Add more sites and their target zones as needed
}



function despawnV1Arty()
    for siteName, group in pairs(v1ArtyGroups) do
        if group then
            pcall(function() group:Stop() end)
            v1ArtyGroups[siteName] = nil
            v1ArtyActive[siteName] = false
        end
    end
    trigger.action.outTextForCoalition(1, "All V1 Artillery stopped.", 10)
    buildCapControlMenu()
end

function spawnV1ArtyAt(v1ZoneName, targetZoneNames)
    -- Check if this specific site is already active
    if v1ArtyActive[v1ZoneName] then 
        trigger.action.outTextForCoalition(1, "V1 Artillery at " .. v1ZoneName .. " already active!", 10)
        return false
    end
    
    local v1Zone = ZONE:FindByName(v1ZoneName)
    if not v1Zone then 
        trigger.action.outTextForCoalition(1, "Invalid V1 zone: " .. v1ZoneName, 10)
        return false
    end
    
    -- Convert single zone to table if needed
    if type(targetZoneNames) == "string" then
        targetZoneNames = {targetZoneNames}
    end
    
    -- Validate all target zones exist
    local targetZones = {}
    env.info(string.format("[V1_LOG] ===== Starting V1 Artillery from %s =====", v1ZoneName))
    v1Log(string.format("[V1_LOG] Target zones requested: %s", table.concat(targetZoneNames, ", ")))
    
    for _, zoneName in ipairs(targetZoneNames) do
        local zone = ZONE:FindByName(zoneName)
        if zone then
            table.insert(targetZones, zone)
            v1Log(string.format("[V1_LOG] ✓ Target zone validated: %s", zoneName))
        else
            env.info(string.format("[V1_LOG] ✗ Target zone NOT FOUND: %s", zoneName))
        end
    end
    
    if #targetZones == 0 then
        trigger.action.outTextForCoalition(1, "No valid target zones for V1 Artillery!", 10)
        v1Log("[V1_LOG] ✗ ABORT: No valid target zones found")
        return false
    end
    
    -- Find V1 launcher group in the V1 zone (RED coalition)
    -- The V1 group name follows pattern: "V1 Launch Site - Brecourt # 1"
    local v1LauncherGroups = SET_GROUP:New():FilterZones({v1Zone}):FilterCoalitions("red"):FilterActive():FilterOnce()
    
    v1Log(string.format("[V1_LOG] Groups found in V1 zone: %d", v1LauncherGroups:Count()))
    
    if v1LauncherGroups:Count() == 0 then
        trigger.action.outTextForCoalition(1, "No V1 launcher found in " .. v1ZoneName, 15)
        v1Log(string.format("[V1_LOG] ✗ ABORT: No V1 launcher found in %s", v1ZoneName))
        return false
    end
    
    -- Find the correct V1 group by checking if it has a unit with type "V1x10"
    local v1Group = nil
    v1LauncherGroups:ForEachGroup(function(grp)
        local groupName = grp:GetName()
        v1Log(string.format("[V1_LOG] Checking group: %s", groupName))
        
        -- Check if group has at least one unit with type "V1x10"
        local hasV1Launcher = false
        for _, unit in ipairs(grp:GetUnits()) do
            local unitType = unit:GetTypeName()
            v1Log(string.format("[V1_LOG]   Unit type: %s", unitType))
            if unitType == "V1x10" then
                hasV1Launcher = true
                break
            end
        end
        
        if hasV1Launcher then
            v1Group = grp
            v1Log(string.format("[V1_LOG] ✓ Found V1 launcher group with V1x10 unit: %s", groupName))
        else
            env.info(string.format("[V1_LOG] ✗ Skipped group (no V1x10 unit): %s", groupName))
        end
    end)
    
    if not v1Group or not v1Group:IsAlive() then
        trigger.action.outTextForCoalition(1, "V1 launcher group not found or not active in " .. v1ZoneName, 15)
        v1Log(string.format("[V1_LOG] ✗ ABORT: V1 launcher not active in %s", v1ZoneName))
        return false
    end
    
    v1Log(string.format("[V1_LOG] ✓ V1 launcher found: %s", v1Group:GetName()))
    
    -- Create ARMYGROUP from existing group
    local artyGroup = ARMYGROUP:New(v1Group)
    artyGroup:SetDefaultFormation(ENUMS.Formation.Vehicle.OffRoad)
    artyGroup:AddWeaponRange(10, 250)
    artyGroup:SetVerbosity(0)
    
    -- Get all target groups from all target zones (BLUE coalition), excluding infantry
    local targetArray = {}
    local zoneNames = {}
    local totalScanned = 0
    local totalAdded = 0
    local totalExcluded = 0
    
    v1Log("[V1_LOG] ----- Scanning target zones for groups -----")
    
    for _, targetZone in ipairs(targetZones) do
        local zoneName = targetZone:GetName()
        v1Log(string.format("[V1_LOG] Scanning zone: %s", zoneName))
        
        local targetGroups = SET_GROUP:New():FilterZones({targetZone}):FilterCoalitions("blue"):FilterActive():FilterOnce()
        local zoneGroupCount = targetGroups:Count()
        
        v1Log(string.format("[V1_LOG]   Groups found in %s: %d", zoneName, zoneGroupCount))
        
        targetGroups:ForEachGroup(function(tgtGroup)
            totalScanned = totalScanned + 1
            
            if tgtGroup and tgtGroup:IsAlive() then
                local groupName = tgtGroup:GetName()
                
                -- Check if group has infantry attribute
                local hasInfantry = false
                local unitList = {}
                for _, unit in ipairs(tgtGroup:GetUnits()) do
                    table.insert(unitList, unit:GetTypeName())
                    if unit:HasAttribute("Infantry") then
                        hasInfantry = true
                    end
                end
                
                if hasInfantry then
                    totalExcluded = totalExcluded + 1
                    v1Log(string.format("[V1_LOG]   ✗ EXCLUDED (Infantry): %s [Units: %s]", 
                        groupName, table.concat(unitList, ", ")))
                else
                    totalAdded = totalAdded + 1
                    table.insert(targetArray, tgtGroup)
                    v1Log(string.format("[V1_LOG]   ✓ ADDED: %s [Units: %s]", 
                        groupName, table.concat(unitList, ", ")))
                end
            else
                totalExcluded = totalExcluded + 1
                v1Log(string.format("[V1_LOG]   ✗ EXCLUDED (Dead/Invalid): Group index %d", totalScanned))
            end
        end)
        
        table.insert(zoneNames, zoneName)
    end
    
    v1Log("[V1_LOG] ----- Target Scan Summary -----")
    v1Log(string.format("[V1_LOG] Total groups scanned: %d", totalScanned))
    v1Log(string.format("[V1_LOG] Total groups added: %d", totalAdded))
    v1Log(string.format("[V1_LOG] Total groups excluded: %d", totalExcluded))
    
    if #targetArray == 0 then
        trigger.action.outTextForCoalition(1, "No valid targets found in target zones", 15)
        return false
    end
    
    -- Store the group for this site
    v1ArtyGroups[v1ZoneName] = artyGroup
    v1ArtyActive[v1ZoneName] = true
    buildCapControlMenu()
    
    -- Launch 10 rockets cycling through targets
    local rocketsToLaunch = 10
    local currentTargetIndex = 1
    local rocketsLaunched = 0
    
    local targetZoneList = table.concat(zoneNames, ", ")
    trigger.action.outTextForCoalition(1, 
        string.format("V1 Artillery from %s engaging targets in: %s. Launching 10 rockets...", 
        v1ZoneName, targetZoneList), 20)
    
    -- Schedule rocket launches
    local function scheduleNextRocket()
        if rocketsLaunched >= rocketsToLaunch then
            trigger.action.outTextForCoalition(1, 
                "V1 Artillery barrage complete. " .. rocketsLaunched .. " rockets launched at " .. targetZoneList, 20)
            v1ArtyActive[v1ZoneName] = false
            v1ArtyGroups[v1ZoneName] = nil
            buildCapControlMenu()
            return
        end
        
        -- Refresh target array from all zones (in case some died), excluding infantry
        targetArray = {}
        for _, targetZone in ipairs(targetZones) do
            local refreshedTargets = SET_GROUP:New():FilterZones({targetZone}):FilterCoalitions("blue"):FilterActive():FilterOnce()
            refreshedTargets:ForEachGroup(function(tgtGroup)
                if tgtGroup and tgtGroup:IsAlive() then
                    -- Check if group has infantry attribute
                    local hasInfantry = false
                    for _, unit in ipairs(tgtGroup:GetUnits()) do
                        if unit:HasAttribute("Infantry") then
                            hasInfantry = true
                            break
                        end
                    end
                    -- Only add non-infantry groups
                    if not hasInfantry then
                        table.insert(targetArray, tgtGroup)
                    end
                end
            end)
        end
        
        if #targetArray == 0 then
            trigger.action.outTextForCoalition(1, "V1 Artillery: No targets remaining in " .. targetZoneList, 15)
            v1ArtyActive[v1ZoneName] = false
            v1ArtyGroups[v1ZoneName] = nil
            buildCapControlMenu()
            return
        end
        
        -- Ensure index is valid
        if currentTargetIndex > #targetArray then
            currentTargetIndex = 1
        end
        
        local targetGroup = targetArray[currentTargetIndex]
        
        if targetGroup and targetGroup:IsAlive() and artyGroup then
            local artyMission = AUFTRAG:NewARTY(targetGroup, 1, 100)
            artyMission:SetWeaponType(ENUMS.WeaponFlag.Auto)
            
            artyGroup:AddMission(artyMission)
            
            rocketsLaunched = rocketsLaunched + 1
            
            trigger.action.outTextForCoalition(1, 
                string.format("V1 Rocket %d/%d launched from %s", 
                rocketsLaunched, rocketsToLaunch, v1ZoneName), 10)
        end
        
        -- Move to next target (cycle)
        currentTargetIndex = currentTargetIndex + 1
        if currentTargetIndex > #targetArray then
            currentTargetIndex = 1
        end
        
        -- Determine next interval
        local nextInterval = 30  -- Default 30 seconds between rockets
        
        if rocketsLaunched == 5 then
            -- After 5th rocket, wait 10 minutes before 6th rocket
            nextInterval = 600  -- 10 minutes = 600 seconds
            trigger.action.outTextForCoalition(1, 
                "V1 Artillery: First salvo complete (5 rockets). Reloading... Next salvo in 10 minutes.", 20)
        end
        
        -- Schedule next rocket
        timer.scheduleFunction(scheduleNextRocket, nil, timer.getTime() + nextInterval)
    end
    
    -- Start first launch
    scheduleNextRocket()
    
    return true  -- Successfully started
end

-- Function to randomly select and launch V1 artillery
function launchRandomV1Artillery()
    -- Get list of available V1 sites
    local availableSites = {}
    for siteName, targetZones in pairs(V1_SITE_CONFIG) do
        if not v1ArtyActive[siteName] then
            table.insert(availableSites, siteName)
        end
    end
    
    if #availableSites == 0 then
        trigger.action.outTextForCoalition(1, "All V1 sites are currently active", 10)
        return false
    end
    
    -- Randomly select a site
    local selectedSite = availableSites[math.random(#availableSites)]
    local targetZones = V1_SITE_CONFIG[selectedSite]
    
    -- Launch from selected site
    return spawnV1ArtyAt(selectedSite, targetZones)
end
