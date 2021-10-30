local util_PrecacheModel = util.PrecacheModel
local ents_FindInSphere = ents.FindInSphere
local util_TableToJSON = util.TableToJSON
local util_JSONToTable = util.JSONToTable
local weapons_Register = weapons.Register
local scripted_ents_Register = scripted_ents.Register
local util_Decompress = util.Decompress
local util_QuickTrace = util.QuickTrace
local player_GetAll = player.GetAll
local util_Compress = util.Compress
local net_WriteUInt = net.WriteUInt
local net_WriteData = net.WriteData
local FindMetaTable = FindMetaTable
local validStr = string["isvalid"]
local net_ReadUInt = net.ReadUInt
local net_ReadData = net.ReadData
local table_insert = table.insert
local table_remove = table.remove
local string_lower = string.lower
local file_Exists = file.Exists
local math_random = math.random
local table_Merge = table.Merge
local dprint = PLib["dprint"]
local isfunction = isfunction
local math_Round = math.Round
local math_floor = math.floor
local math_abs = math.abs
local tostring = tostring
local tonumber = tonumber
local IsValid = IsValid
local CurTime = CurTime
local Vector = Vector
local ipairs = ipairs

function PLib.OneTeam(ply1, ply2)
	return ply1:Team() == ply2:Team()
end

function PLib.HasModel(path)
	return file_Exists(string_lower(path), "GAME")
end

PLib["GetMap"] = game["GetMap"]
function PLib:GetMapList()
    local tbl = {}
    local maps = file.Find("maps/*", "GAME")
    for i = 1, #maps do
        local map = maps[i]
        if string.EndsWith(map, ".bsp") then
            table_insert(tbl, string.sub(map, 0, #map - 4))
        end
    end

    return tbl
end

local table_concat = table.concat
function PLib.string(...)
    return table_concat({...}, " ")
end

function PLib.GetBonePos(ent, bone)
	local pos = ent:GetBonePosition(bone)
	if pos == ent:GetPos() then
		local matrix = ent:GetBoneMatrix(bone)
		if matrix then
			pos = matrix:GetTranslation()
		end
	end

	return pos
end

function PLib:GetAchievement(tag)
    return self["Achievements"][tag]
end

function PLib:GetAchievementName(tag)
    local achi = self:GetAchievement(tag)
	if (achi != nil) then
		return PLib:TranslateText(achi[1])
	elseif CLIENT and (isnumber(tag) and tag <= achievements.Count()) then
		return PLib:TranslateText(achievements.GetName(tag))
	else
		return PLib:TranslateText(tag or "")
	end
end

function PLib:EditAchievement(tag, title, icon)
    local tbl = self:GetAchievement(tag)
	if (tbl != nil) then
	    tbl[1] = title and PLib:TranslateText(title) or tbl[1]
    	tbl[2] = icon and Material(icon, PLib["MatPresets"]["Pic"]) or tbl[2]
	    self["Achievements"][tag] = tbl
	end
end

function PLib:RemoveAchievement(tag)
	local num = 1
	for id, tbl in pairs(self["Achievements"]) do
		if (id == tag) then
			return table_remove(self["Achievements"], num)
		end

		num = num + 1
	end

	return false
end

PLib:Precache_G("Color", Color)
local _GColor = PLib:Get_G("Color")

function Color(hex, g, b, a)
    if validStr(hex) and (g == nil) and (b == nil) and (a == nil) then
		local hex = hex:gsub("#", "")
		if (hex:len() == 3) then
			return _GColor((tonumber("0x"..hex:sub(1, 1)) * 17), (tonumber("0x"..hex:sub(2, 2)) * 17), (tonumber("0x"..hex:sub(3, 3)) * 17))
		else
			return _GColor(tonumber("0x"..hex:sub(1, 2)), tonumber("0x"..hex:sub(3, 4)), tonumber("0x"..hex:sub(5, 6)))
		end
	end

	return _GColor(hex, g, b, a)
end

local PrechangedModels = {}
function PLib.Model(model)
	if (PrechangedModels[model] == nil) then
		util_PrecacheModel(model)
		PrechangedModels[model] = true		
	end

	return model
end

function player.inRange(pos, range)
	range = range ^ 2

	local output = {}
	for i, ply in ipairs(player_GetAll()) do
		if ply:GetPos():DistToSqr(pos) <= range then
			table_insert(output, ply)
		end
	end

	return output
end

function player.findNearest(pos, radius, filter)
	local plys = {}
	for num, ply in ipairs((radius == nil) and player_GetAll() or ents_FindInSphere(pos, radius)) do
		if IsValid(ply) and ply:IsPlayer() and (!filter or !isfunction(filter) or filter(ply)) then
			table_insert(plys, {pos:Distance(ply:GetPos()), ply})
		end
	end
	
	local output = {}
	for _, tbl in ipairs(plys) do
		if !output or (tbl[1] < output[1]) then
			output = tbl
		end
	end

	return output
end

local player_GetHumans = player.GetHumans
local player_GetAll = player.GetAll

function player.Random(no_bots)
    local players = no_bots and player_GetHumans() or player_GetAll()
    return players[math_random(1, #players)]
end

local game_GetAmmoName = game.GetAmmoName
function game.AmmoList()
	local last = game_GetAmmoName(1)
	local output = {last}
  
	while (last != nil) do
		last = game_GetAmmoName(table_insert(output, last))
	end
  
	return output
end

local Lerp = Lerp
function PLib.Lerp(frac, a, b)
    if isvector(a) then
        return LerpVector(frac, a, b)
    elseif isangle(a) then
        return LerpAngle(frac, a, b)
    elseif isnumber(a) then
        return Lerp(frac, a, b)
	elseif IsColor(a) then
		local col = Color(0,0,0,0)
		col["r"] = Lerp(frac, a["r"], b["r"])
		col["g"] = Lerp(frac, a["g"], b["g"])
		col["b"] = Lerp(frac, a["b"], b["b"])
		col["a"] = Lerp(frac, a["a"] or 255, b["a"] or 255)

		return col
    end
end

function engine.GetAddon(id)
	local addons = engine.GetAddons()
    for i = 1, #addons do
        local addon = addons[i]
        if (addon["wsid"] == id) then
            return addon
        end
    end
    
    return false
end

local ENTITY = FindMetaTable("Entity")
function PLib.EyeAngles(ply)
	local attach_id, ang = ply:LookupAttachment('eyes')

	if attach_id then
		local attach = ply:GetAttachment(attach_id)
		if attach then
			ang = attach["Ang"]
		end
	end

	return (ang or ENTITY.EyeAngles(ply))
end

function PLib.EyePos(ply)
	local attach_id, attach, pos = ply:LookupAttachment('eyes'), false

	if attach_id then
		attach = ply:GetAttachment(attach_id)
		if attach then
			pos = attach["Pos"]
		end
	end

	if (attach == nil) then
		local bone = ply:GetBoneByTag("head")
		if bone then
			pos = ply:GetBonePosition(bone)
			if pos == ply:GetPos() then
				local matrix = ply:GetBoneMatrix(bone)
				if matrix then
					pos = matrix:GetTranslation()
				end
			end
		end
	end

	if ply:GetNWBool("CustomPM") then
		local id = ply:GetNWString("CustomPM_ID")
		if cfg["pmd_eyesOffsets"][id] then
			pos = pos + cfg["pmd_eyesOffsets"][id]
		end
	end

	if (pos != nil) then
		return pos
	end

	return ENTITY.EyePos(ply)
end

function ENTITY:GetDownTrace(filter)
	return util_QuickTrace(self:EyePos(), Vector(0, 0, -1)*50000, filter or {self})
end

function ENTITY:StandingOnGround()
	local tr = self:GetDownTrace()
	if tr["Hit"] then
		if self:IsOnGround() or (self:GetPos():DistToSqr(tr["HitPos"]) < 500) then
			return true
		end
	end

	return false
end

function ENTITY:InBox(mins, maxs)
	local ent_list = ents.FindInBox(mins, maxs)
	for i = 1, #ent_list do
		if (self == ent_list[i]) then
			return true
		end
	end

	return false
end

function ENTITY:GetHorizontalSpeed()
	local vel = self:GetVelocity()

	return Vector(vel[1], vel[2], 0):Length() or 0
end

function ENTITY:GetVerticalSpeed()
	return self:GetVelocity()[3]
end

local math_max = math.max
function ENTITY:GetWight()
	local mins, maxs = self:GetCollisionBounds()
	return math_max(maxs[1] - mins[1], maxs[2] - mins[2])
end

function ENTITY:GetHight()
	local mins, maxs = self:GetCollisionBounds()
	return maxs[3] - mins[3]
end

function ENTITY:TeamObject(ply)
	if IsValid(ply) and IsValid(self) then
		local owner = self:CPPIGetOwner() or self:GetCreator() or self:GetOwner()
		if IsValid(owner) then
			if (owner == ply) then return true end
			return PLib.OneTeam(ply, owner)
		end
	end

	return false
end

function ENTITY:IsDoor()
	local class = self:GetClass()
	if validStr(class) and class:match("door") then
		return true
	end

	return IsValid(self:GetNWEntity("OriginalDoor", nil)) or false
end

function ENTITY:GetSize()
	if (self["PLib.Size"] == nil) then
		-- 1 pika unit == 10 unit
		local mins, maxs = self:GetCollisionBounds()
		local facets = (maxs - mins)*0.1 -- Units to pika units
		self["PLib.Size"] = (facets[1] * facets[2] * facets[3])
	end
	
	return self["PLib.Size"]
end

function ENTITY:CubicDistance()
	if (self["PLib.CubicDistance"] == nil) then
		local mins, maxs = self:GetCollisionBounds()
		self["PLib.CubicDistance"] = mins:Distance(maxs)
	end
	
	return self["PLib.CubicDistance"]
end

function ENTITY:GetSpeed()
	local vel = self:GetVelocity()
	if (vel != nil) then
		return math_abs(vel:Length()), vel
	end

	return 0
end

function ENTITY:Speed()
	return self:GetVelocity():Length()
end

function ENTITY:IsDoor()
	local class = self:GetClass()
	return ((class != nil) and class:match("door") or false)
end

local BoneCache = {}
function ENTITY:GetBoneByTag(tag)
	local model = self:GetModel()
	if not BoneCache[model] then
		self:SetupBones()

		for id = 0, self:GetBoneCount() do
			local name = self:GetBoneName(id)
			if !name or name == "" then continue end
			if string_lower(name):match(string_lower(tag)) then
				BoneCache[model] = id;
				break;
			end
		end
	end

	return BoneCache[model] or false
end

local VECTOR = FindMetaTable("Vector")
function VECTOR:Round(dec)
    return Vector(math_Round(self[1], dec or 0), math_Round(self[2], dec or 0), math_Round(self[3], dec or 0))
end

function VECTOR:Floor()
	self[1] = math_floor(self[1])
	self[2] = math_floor(self[2])
	self[3] = math_floor(self[3])
    return self
end

function VECTOR:Middle()
	return (self[1] + self[2] + self[3])/3
end

function VECTOR:Lerp(frac, b)
	return LerpVector(frac, self, b)
end
	
local ANGLE = FindMetaTable("Angle")
function ANGLE:Lerp(frac, b)
	return LerpAngle(frac, self, b)
end

function ANGLE:Floor()
	self[1] = math_floor(self[1])
	self[2] = math_floor(self[2])
	self[3] = math_floor(self[3])
    return self
end

local COLOR = FindMetaTable("Color")
function COLOR:Lerp(frac, b)
	self["r"] = Lerp(frac, b["r"], self["r"])
	self["g"] = Lerp(frac, b["g"], self["g"])
	self["b"] = Lerp(frac, b["b"], self["b"])
	self["a"] = Lerp(frac, b["a"] or 255, self["a"] or 255)

	return self
end

function COLOR:SetAlpha(alpha)
	self["a"] = alpha
	return self
end

local IMaterial = FindMetaTable("IMaterial")
function IMaterial:GetSize()
	return self:GetInt("$realwidth"), self:GetInt("$realheight")
end

function PLib:MaterialSize(mat)
    return mat:GetInt("$realwidth"), mat:GetInt("$realheight")
end

function math.striving_for(value, valueTo, delay)
    return value + (valueTo-value)/delay
end

function math.average(...)
	local amount = select('#', ...)
	assert(amount > 1, 'At least two numbers are required!')
	local total = 0

	for i = 1, amount do
		total = total + select(i, ...)
	end

	return total / amount
end

function ents.FindInBoxRotated(pos, ang, mins, maxs, size, ent)
	local result = {}

	if (pos == nil) then
		if IsValid(ent) then
			pos = ent:GetPos()
		else
			return result
		end
	end

	if (size == nil) then
		if IsValid(ent) then
			size = ent:CubicDistance()
		else
			return result
		end
	end

	if IsValid(ent) then
		for _, tEnt in ipairs(ents.FindInSphere(pos, size)) do
			if IsValid(tEnt) and tEnt != ent then
				local mn, mx = tEnt:GetCollisionBounds()
				if (ent:WorldToLocal(tEnt:LocalToWorld(tEnt:OBBCenter())):WithinAABox(mins, maxs) or ent:WorldToLocal(tEnt:LocalToWorld(mn)):WithinAABox(mins, maxs) 
				or ent:WorldToLocal(tEnt:LocalToWorld(mx)):WithinAABox(mins, maxs) or ent:WorldToLocal(tEnt:LocalToWorld(Vector(mn[1],mn[2],mx[3]))):WithinAABox(mins, maxs)
				or ent:WorldToLocal(tEnt:LocalToWorld(Vector(mx[1],mx[2],mn[3]))):WithinAABox(mins, maxs) or ent:WorldToLocal(tEnt:GetPos()):WithinAABox(mins, maxs)) then
					table_insert(result, tEnt)
				end
			end
		end
	else
		for _, eTarget in ipairs(ents.FindInSphere(pos, size))do
			if WorldToLocal(eTarget:GetPos(), eTarget:GetAngles(), pos, ang):WithinAABox(mins, maxs) then
				table_insert(result, eTarget)
			elseif WorldToLocal(eTarget:GetPos(), eTarget:GetAngles() - Angle(0,180,0), pos, ang):WithinAABox(mins, maxs) then
				table_insert(result, eTarget)
			elseif WorldToLocal(eTarget:GetPos(), eTarget:GetAngles()*(-1), pos, ang):WithinAABox(mins, maxs) then
				table_insert(result, eTarget)
			end
			
		end
	end

  	return result
end

function table.shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math_random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end

    return tbl
end

function string.charCount(str, chr)
	if !str or !chr then return end
	local count = 0
	for _, char in ipairs(string.ToTable(str)) do
		if char == chr then
			count = count + 1
		end
	end

	return count 
end

function PLib:CreateWeapon(class, data)
	if validStr(class) and istable(data) then
		local SWEP = {}
		SWEP["PrintName"] = "PLib Weapon"
		SWEP["Primary"] 	= {}
		SWEP["Secondary"] 	= {}
		SWEP["WorldModel"]	= ""
		SWEP["ViewModel"]	= "models/weapons/c_arms.mdl"
		SWEP["Category"]	= "PLib"
		SWEP["HoldType"]	= "normal"
		SWEP["Spawnable"]	= true
		SWEP["UseHands"]	= true

		function SWEP:Initialize()
			self:SetWeaponHoldType(self["HoldType"])
		end

		weapons_Register(table_Merge(SWEP, data), class)
		dprint("SWEP", "Weapon Created -> ", class)

		if CLIENT then
			self:SpawnMenuReload()
		end
	end
end

function PLib:CreateEntity(class, data)
	if validStr(class) and istable(data) then
		local ENT 			= {}
		ENT["Base"] 		= "base_anim"
		ENT["Model"]		= "models/props_c17/oildrum001_explosive.mdl"
		ENT["Category"]		= "PLib"
		ENT["PrintName"] 	= "PLib Entity"
		ENT["Spawnable"]	= true

		function ENT:Initialize()
			if SERVER then
				self:SetModel(self["Model"])
				self:PhysicsInit(SOLID_VPHYSICS)
			end
		end

		scripted_ents_Register(table_Merge(ENT, data), class)
		dprint("ENT", "Entity Created -> ", class)

		if CLIENT then
			self:SpawnMenuReload()
		end
	end
end

-- Net Compressed tables by DefaultOS#5913
function net.WriteCompressTable(tbl)
	if (tbl == nil) then return end
    local data = util_Compress(util_TableToJSON(tbl))
    net_WriteUInt(#data,16)
    net_WriteData(data,#data)
end

function net.ReadCompressTable()
    local len = net_ReadUInt(16)
	return util_JSONToTable(util_Decompress(net_ReadData(len)))
end

function PLib:ObfuscateLua(code)
	-- not yet
end