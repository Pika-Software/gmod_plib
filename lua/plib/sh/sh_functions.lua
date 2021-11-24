local FindMetaTable = FindMetaTable
local table_concat = table.concat
local file_Exists = file.Exists
local string_lower = string.lower
local util_PrecacheModel = util.PrecacheModel
local string_GetPathFromFilename = string.GetPathFromFilename
local string_GetExtensionFromFilename = string.GetExtensionFromFilename
local isvector = isvector
local LerpVector = LerpVector
local isangle = isangle
local LerpAngle = LerpAngle
local isnumber = isnumber
local Lerp = Lerp
local IsColor = IsColor
local Color = Color
local table_insert = table.insert
local ipairs = ipairs
local file_Read = file.Read
local pcall = pcall
local math_Clamp = math.Clamp
local tonumber = tonumber
local PLib = PLib
local string_match = string.match
local string_format = string.format
local file_Find = file.Find
local string_EndsWith = string.EndsWith
local string_sub = string.sub
local GetGlobalString = GetGlobalString
local SetGlobalString = SetGlobalString
local isstring = isstring
local timer_Simple = timer.Simple
local achievements_Count = CLIENT and achievements.Count
local achievements_GetName = CLIENT and achievements.GetName
local Material = Material
local pairs = pairs
local table_remove = table.remove
local player_GetAll = player.GetAll
local ents_FindInSphere = ents.FindInSphere
local IsValid = IsValid
local isfunction = isfunction
local player_GetHumans = player.GetHumans
local math_random = math.random
local Vector = Vector
local table_insert = table_insert
local WorldToLocal = WorldToLocal
local Angle = Angle
local validStr = validStr
local util_QuickTrace = util.QuickTrace
local ents_FindInBox = ents.FindInBox
local math_max = math.max
local math_abs = math.abs
local math_Round = math.Round
local math_floor = math.floor
local string_Split = string.Split
local math_pow = math.pow
local math_ceil = math.ceil
local math_log = math.log
local select = select
local assert = assert
local string_byte = string.byte
local string_len = string.len
local math_fmod = math.fmod
local tostring = tostring
local surface_SetFont = CLIENT and surface.SetFont
local surface_GetTextSize = CLIENT and surface.GetTextSize
local string_find = string.find
local string_ToTable = string.ToTable
local game_GetAmmoName = game.GetAmmoName
local engine_GetAddons = engine.GetAddons
local ents_CreateClientside = CLIENT and ents.CreateClientside
local util_Compress = util.Compress
local util_TableToJSON = util.TableToJSON
local net_WriteUInt = net.WriteUInt
local net_WriteData = net.WriteData
local net_ReadUInt = net.ReadUInt
local util_JSONToTable = util.JSONToTable
local util_Decompress = util.Decompress
local net_ReadData = net.ReadData
local dprint = PLib["dprint"]
local module = module
local type = type

--[[-------------------------------------------------------------------------
	Used local variables
---------------------------------------------------------------------------]]

local PrechangedModels = {}
local BoneCache = {}

local ENTITY = FindMetaTable("Entity")
local VECTOR = FindMetaTable("Vector")
local ANGLE = FindMetaTable("Angle")
local COLOR = FindMetaTable("Color")
local IMATERIAL = FindMetaTable("IMaterial")
local VMATRIX = FindMetaTable("VMatrix")

--[[-------------------------------------------------------------------------
	Other
---------------------------------------------------------------------------]]

function PLib.string(...)
	return table_concat({...}, " ")
end

function PLib.OneTeam(ply1, ply2)
	return ply1:Team() == ply2:Team()
end

function PLib.HasModel(fpath)
	return file_Exists(string_lower(fpath), "GAME")
end

function PLib.Model(model)
	if (PrechangedModels[model] == nil) then
		util_PrecacheModel(model)
		PrechangedModels[model] = true
	end

	return model
end

function PLib:IsValidLuaFile(f)
	local fpath = string_GetPathFromFilename(f)
	return (string_GetExtensionFromFilename(f) == "lua") and ((fpath == "lua/autorun/") or (fpath == "lua/autorun/client/"))
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

function PLib.Lerp(frac, a, b)
	if isvector(a) then
		return LerpVector(frac, a, b)
	elseif isangle(a) then
		return LerpAngle(frac, a, b)
	elseif isnumber(a) then
		return Lerp(frac, a, b)
	elseif IsColor(a) then
		local col = Color(0, 0, 0, 0)
		col["r"] = Lerp(frac, a["r"], b["r"])
		col["g"] = Lerp(frac, a["g"], b["g"])
		col["b"] = Lerp(frac, a["b"], b["b"])
		col["a"] = Lerp(frac, a["a"] or 255, b["a"] or 255)

		return col
	end
end

function PLib.EyeAngles(ply)
	local attach_id, ang = ply:LookupAttachment("eyes")

	if attach_id then
		local attach = ply:GetAttachment(attach_id)
		if attach then
			ang = attach["Ang"]
		end
	end

	return ang or ENTITY.EyeAngles(ply)
end

function PLib.EyePos(ply)
	local attach_id, attach, pos = ply:LookupAttachment("eyes"), false

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

	if (pos ~= nil) then
		return pos
	end

	return ENTITY.EyePos(ply)
end

PLib:Precache_G("player_manager.AddValidHands", player_manager.AddValidHands)
PLib:Precache_G("player_manager.AddValidModel", player_manager.AddValidModel)

-- PlayerModel export by Retro#1593
function PLib:ExportPM(files)
	local mdls, hands = {}, {}
	function player_manager.AddValidHands(name, model, skin, bodygroups)
		table_insert(hands, {name = name, model = model, skin = skin, bodygroups = bodygroups})
	end

	function player_manager.AddValidModel(name, model)
		table_insert(mdls, {name = name, model = model})
	end

	for _, fl in ipairs(files) do
		if not self:IsValidLuaFile(fl) then continue end

		local path = fl:sub(5)
		local lua = file_Read(path, "LUA")
		if not lua then continue end

		local ok, err = pcall(RunString, lua, path)
		if (ok == true) then
			PLib:Log("Error", err)
		end
	end

	player_manager.AddValidHands = self:Get_G("player_manager.AddValidHands")
	player_manager.AddValidModel = self:Get_G("player_manager.AddValidModel")

	return mdls, hands
end

--[[-------------------------------------------------------------------------
	Convert operations
---------------------------------------------------------------------------]]

-- arguments can be only 0-255
function PLib.Vec4ToInt(a, b, c, d)
	local int = 0
	int = int + pbit.lshift(math_Clamp(tonumber(a), 0, 255), 24)
	int = int + pbit.lshift(math_Clamp(tonumber(b), 0, 255), 16)
	int = int + pbit.lshift(math_Clamp(tonumber(c), 0, 255), 8)
	int = int + math_Clamp(tonumber(d), 0, 255)
	return int
end

function PLib.Vec4FromInt(i)
	return pbit.rshift(pbit.band(i, 0xFF000000), 24),
	pbit.rshift(pbit.band(i, 0x00FF0000), 16),
	pbit.rshift(pbit.band(i, 0x0000FF00), 8),
	pbit.band(i, 0x000000FF)
end

function PLib.IPAddressToInt(ip)
	return PLib.Vec4ToInt(string_match(ip, "(%d+)%.(%d+)%.(%d+)%.(%d+)"))
end

function PLib.IPAddressFromInt(i)
	return string_format("%d.%d.%d.%d", PLib.Vec4FromInt(i))
end

--[[-------------------------------------------------------------------------
	Server info
---------------------------------------------------------------------------]]

PLib["GetMap"] = game["GetMap"]

function PLib:GetMapList()
	local tbl, maps = {}, file_Find("maps/*", "GAME")

	for i = 1, #maps do
		local map = maps[i]
		if string_EndsWith(map, ".bsp") then
			table_insert(tbl, string_sub(map, 0, #map - 4))
		end
	end

	return tbl
end

function PLib:GetServerName()
	return GetGlobalString("ServerName", SERVER and self:GetHostName() or "Garry's Mod")
end

function PLib:SetServerName(str)
	local old = self:GetServerName()
	SetGlobalString("ServerName", isstring(str) and str or old)
	timer_Simple(0, function()
		dprint(nil, string_format("Server name changed from '%s' to '%s'!", old, self:GetServerName()))
	end)
end

--[[-------------------------------------------------------------------------
	Achievements
---------------------------------------------------------------------------]]

function PLib:GetAchievement(tag)
	return self["Achievements"][tag]
end

function PLib:GetAchievementName(tag)
	local achi = self:GetAchievement(tag)
	if (achi ~= nil) then
		return PLib:TranslateText(achi[1])
	elseif CLIENT and (isnumber(tag) and tag <= achievements_Count()) then
		return PLib:TranslateText(achievements_GetName(tag))
	else
		return PLib:TranslateText(tag or "")
	end
end

function PLib:EditAchievement(tag, title, icon)
	local tbl = self:GetAchievement(tag)
	if (tbl ~= nil) then
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

--[[-------------------------------------------------------------------------
	Find / Get
---------------------------------------------------------------------------]]

function player.FindInRange(pos, range)
	range = range ^ 2

	local output = {}
	for i, ply in ipairs(player_GetAll()) do
		if ply:GetPos():DistToSqr(pos) <= range then
			table_insert(output, ply)
		end
	end

	return output
end

function player.FindNearest(pos, radius, filter)
	local plys = {}
	for num, ply in ipairs((radius == nil) and player_GetAll() or ents_FindInSphere(pos, radius)) do
		if IsValid(ply) and ply:IsPlayer() and (not filter or not isfunction(filter) or filter(ply)) then
			table_insert(plys, {pos:Distance(ply:GetPos()), ply})
		end
	end

	local output = nil
	for _, tbl in ipairs(plys) do
		if not output or (tbl[1] < output[1]) then
			output = tbl
		end
	end

	return output or {}
end

function player.Random(no_bots)
	local players = no_bots and player_GetHumans() or player_GetAll()
	return players[math_random(1, #players)]
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
		for _, tEnt in ipairs(ents_FindInSphere(pos, size)) do
			if IsValid(tEnt) and tEnt ~= ent then
				local mn, mx = tEnt:GetCollisionBounds()
				if (ent:WorldToLocal(tEnt:LocalToWorld(tEnt:OBBCenter())):WithinAABox(mins, maxs) or ent:WorldToLocal(tEnt:LocalToWorld(mn)):WithinAABox(mins, maxs)
				or ent:WorldToLocal(tEnt:LocalToWorld(mx)):WithinAABox(mins, maxs) or ent:WorldToLocal(tEnt:LocalToWorld(Vector(mn[1],mn[2],mx[3]))):WithinAABox(mins, maxs)
				or ent:WorldToLocal(tEnt:LocalToWorld(Vector(mx[1],mx[2],mn[3]))):WithinAABox(mins, maxs) or ent:WorldToLocal(tEnt:GetPos()):WithinAABox(mins, maxs)) then
					table_insert(result, tEnt)
				end
			end
		end
	else
		for _, eTarget in ipairs(ents_FindInSphere(pos, size)) do
			if WorldToLocal(eTarget:GetPos(), eTarget:GetAngles(), pos, ang):WithinAABox(mins, maxs) then
				table_insert(result, eTarget)
			elseif WorldToLocal(eTarget:GetPos(), eTarget:GetAngles() - Angle(0,180,0), pos, ang):WithinAABox(mins, maxs) then
				table_insert(result, eTarget)
			elseif WorldToLocal(eTarget:GetPos(), eTarget:GetAngles() * (-1), pos, ang):WithinAABox(mins, maxs) then
				table_insert(result, eTarget)
			end

		end
	end

	return result
end

--[[-------------------------------------------------------------------------
	Color improvements
---------------------------------------------------------------------------]]

PLib:Precache_G("Color", Color)
local _GColor = PLib:Get_G("Color")

function Color(hex, g, b, a)
	if (g == nil) and (b == nil) and (a == nil) then
		if validStr(hex) then
			hex = hex:gsub("#", "")
			if (hex:len() == 3) then
				return _GColor(tonumber("0x" .. hex:sub(1, 1)) * 17, tonumber("0x" .. hex:sub(2, 2)) * 17, tonumber("0x" .. hex:sub(3, 3)) * 17)
			else
				return _GColor(tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)))
			end
		elseif isnumber(hex) then
			return _GColor(PLib.Vec4FromInt(hex))
		end
	end

	return _GColor(hex, g, b, a)
end

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

function COLOR:ToInt()
	return PLib.Vec4ToInt(self["r"], self["g"], self["b"], self["a"])
end

function COLOR:FromInt(i)
	self["r"], self["g"], self["b"], self["a"] = PLib.Vec4FromInt(i)
end

--[[-------------------------------------------------------------------------
	Matrix improvements
---------------------------------------------------------------------------]]

local vec_zero = Vector()
local ang_zero = Angle()
local def_scale = Vector(1, 1)

function VMATRIX:Reset()
	self:Zero()
	self:SetScale(def_scale)
	self:SetAngles(ang_zero)
	self:SetTranslation(vec_zero)
	self:SetField(1, 1, 1)
	self:SetField(2, 2, 1)
	self:SetField(3, 3, 1)
	self:SetField(4, 4, 1)
end

--[[-------------------------------------------------------------------------
	IMaterial improvements
---------------------------------------------------------------------------]]

function ismaterial(mat)
	return debug.getmetatable(mat) == IMATERIAL
end

function IMATERIAL:GetSize()
	return self:GetInt("$realwidth"), self:GetInt("$realheight")
end

--[[-------------------------------------------------------------------------
	Small module for material transformation operations
---------------------------------------------------------------------------]]

do
	module("pmat_transform", package.seeall)

	local matrix = Matrix()
	local vec_origin = Vector()
	local vec_scale = Vector(1, 1)
	local ang_rotation = Angle()

	function Reset()
		matrix:Reset()
	end

	function SetRotationOrigin(rot_x, rot_y)
		vec_origin.x, vec_origin.y = rot_x, rot_y
	end

	function SetScale(scale_x, scale_y)
		vec_scale.x, vec_scale.y = scale_x, scale_y
		matrix:SetScale(vec_scale)
	end

	function SetRotation(rot)
		ang_rotation.y = rot
		matrix:Translate(vec_origin)
		matrix:SetAngles(ang_rotation)
		matrix:Translate(-vec_origin)
	end

	function Rotate(rot)
		ang_rotation.y = rot
		matrix:Translate(vec_origin)
		matrix:Rotate(ang_rotation)
		matrix:Translate(-vec_origin)
	end

	function Apply(mat)
		assert(ismaterial(mat), "bad argument #1 to 'Apply' (IMaterial expected, got " .. type(mat) .. ")")
		mat:SetMatrix("$basetexturetransform", matrix)
	end

	function Copy(obj)
		if ismatrix(obj) then
			matrix:Set(obj)
		elseif ismaterial(obj) then
			local mtx = obj:GetMatrix("$basetexturetransform")
			if mtx then
				matrix:Set(mtx)
			end
		end
	end
end

--[[-------------------------------------------------------------------------
	Entity improvements
---------------------------------------------------------------------------]]

PLib:Precache_G("ENTITY:GetOwner", ENTITY["GetOwner"])
local ownerCheckFunctions = {
	PLib:Get_G("ENTITY:GetOwner")
}

timer.Simple(0, function()
	if CPPI then
		table.insert(ownerCheckFunctions, ENTITY["CPPIGetOwner"])
	end
end)

if SERVER then
	table.insert(ownerCheckFunctions, ENTITY["GetCreator"])
end

function ENTITY:GetOwner()
	if SERVER and self:CreatedByMap() then
		return NULL
	end

	for _, func in ipairs(ownerCheckFunctions) do
		local ply = func(self)
		if IsValid(ply) then
			return ply
		end
	end

	return NULL
end

function ENTITY:GetDownTrace(filter)
	return util_QuickTrace(self:EyePos(), Vector(0, 0, -1) * 50000, filter or { self })
end

function ENTITY:StandingOnGround()
	local tr = self:GetDownTrace()
	if tr["Hit"] and (self:IsOnGround() or (self:GetPos():DistToSqr(tr["HitPos"]) < 500)) then
		return true
	end

	return false
end

function ENTITY:InBox(mins, maxs)
	local ent_list = ents_FindInBox(mins, maxs)
	for i = 1, #ent_list do
		if (self == ent_list[i]) then
			return true
		end
	end

	return false
end

function ENTITY:GetHorizontalSpeed()
	local vel = self:GetVelocity()

	return Vector(vel["x"], vel["y"], 0):Length() or 0
end

function ENTITY:GetVerticalSpeed()
	return self:GetVelocity()["z"]
end

function ENTITY:GetWight()
	local mins, maxs = self:GetCollisionBounds()
	return math_max(maxs["x"] - mins["x"], maxs["y"] - mins["y"])
end

function ENTITY:GetHight()
	local mins, maxs = self:GetCollisionBounds()
	return maxs["z"] - mins["z"]
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
	return (class == "prop_door_rotating") or (class == "func_door_rotating") or IsValid(self:GetNWEntity("PLib.DoorEntity", false))
end

local prop_Classes = {
	["prop_detail"] = true,
	["prop_static"] = true,
	["prop_physics"] = true,
	["prop_ragdoll"] = true,
	["prop_dynamic"] = true,
	["prop_physics_override"] = true,
	["prop_dynamic_override"] = true,
	["prop_physics_multiplayer"] = true
}

function ENTITY:IsProp()
	return prop_Classes[self:GetClass()] or false
end

function ENTITY:GetSize()
	if (self["PLib.Size"] == nil) then
		-- 1 pika unit == 10 unit
		local mins, maxs = self:GetCollisionBounds()
		local facets = (maxs - mins) * 0.1 -- Units to pika units
		self["PLib.Size"] = (facets["x"] * facets["y"] * facets["z"])
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
	if (vel ~= nil) then
		return math_abs(vel:Length()), vel
	end

	return 0
end

function ENTITY:GetRawSpeed()
	return self:GetVelocity():Length()
end

function ENTITY:GetBoneByTag(tag)
	local model = self:GetModel()
	if not BoneCache[model] then
		self:SetupBones()

		for id = 0, self:GetBoneCount() do
			local name = self:GetBoneName(id)
			if not name or name == "" then continue end
			if string_lower(name):match(string_lower(tag)) then
				BoneCache[model] = id
				break
			end
		end
	end

	return BoneCache[model] or false
end

--[[-------------------------------------------------------------------------
	Vector improvements
---------------------------------------------------------------------------]]

function VECTOR:Round(dec)
	return Vector(math_Round(self["x"], dec or 0), math_Round(self["y"], dec or 0), math_Round(self["z"], dec or 0))
end

function VECTOR:InBox(vec1, vec2)
	return self["x"] >= vec1["x"] and self["x"] <= vec2["x"] and self["y"] >= vec1["y"] and self["y"] <= vec2["y"] and self["z"] >= vec1["z"] and self["z"] <= vec2["z"]
end

function VECTOR:Floor()
	self["x"] = math_floor(self["x"])
	self["y"] = math_floor(self["y"])
	self["z"] = math_floor(self["z"])
	return self
end

function VECTOR:Abs()
	self["x"] = math_abs(self["x"])
	self["y"] = math_abs(self["y"])
	self["z"] = math_abs(self["z"])
	return self
end

function VECTOR:NormalizeZero()
	self["x"] = (self["x"] == 0) and 0 or self["x"]
	self["y"] = (self["y"] == 0) and 0 or self["y"]
	self["z"] = (self["z"] == 0) and 0 or self["z"]
	return self
end

function VECTOR:Middle()
	return (self["x"] + self["y"] + self["z"]) / 3
end

function VECTOR:Lerp(frac, b)
	return LerpVector(frac, self, b)
end

--[[-------------------------------------------------------------------------
	Angle improvements
---------------------------------------------------------------------------]]

function ANGLE:Lerp(frac, b)
	return LerpAngle(frac, self, b)
end

function ANGLE:Floor()
	self["p"] = math_floor(self["p"])
	self["y"] = math_floor(self["y"])
	self["r"] = math_floor(self["r"])
	return self
end

function ANGLE:abs()
	self["p"] = math_abs(self["p"])
	self["y"] = math_abs(self["y"])
	self["r"] = math_abs(self["r"])
	return self
end

function ANGLE:NormalizeZero()
	self["p"] = (self["p"] == 0) and 0 or self["p"]
	self["y"] = (self["y"] == 0) and 0 or self["y"]
	self["r"] = (self["r"] == 0) and 0 or self["r"]
	return self
end

--[[-------------------------------------------------------------------------
	table module improvements
---------------------------------------------------------------------------]]

function table.Sub(tbl, offset, len)
	local newTbl = {}
	for i = 1, len do
		newTbl[i] = tbl[i + offset]
	end

	return newTbl
end

function table.Sum(arr)
	local sum = 0
	for i = 1, #arr do
		sum = sum + arr[i]
	end

	return sum
end

function table.Min(tbl)
	local min = nil
	for key, value in ipairs(tbl) do
		if (min == nil) or (value < min) then
			min = value
		end
	end

	return min
end

function table.Max(tbl)
	local max = nil
	for key, value in ipairs(tbl) do
		if (max == nil) or (value > max) then
			max = value
		end
	end

	return max
end

function table.shuffle(tbl)
	local size = #tbl
	for i = size, 1, -1 do
		local rand = math.random(size)
		tbl[i], tbl[rand] = tbl[rand], tbl[i]
	end

	return tbl
end

function table.Lookup(tbl, key, default)
	local fragments = string_Split(key, ".")
	local value = tbl

	for _, fragment in ipairs(fragments) do
		value = value[fragment]

		if not value then
			return default
		end
	end

	return value
end

--[[-------------------------------------------------------------------------
	math module improvements
---------------------------------------------------------------------------]]

function math.power2(n)
	return math_pow(2, math_ceil(math_log(n) / math_log(2)))
end

math["Map"] = math["Remap"]

function math.striving_for(value, valueTo, delay)
	return value + (valueTo - value) / delay
end

function math.average(...)
	local amount = select("#", ...)
	assert(amount > 1, "At least two numbers are required!")
	local total = 0

	for i = 1, amount do
		total = total + select(i, ...)
	end

	return total / amount
end

function math.Clamp(inval, minval, maxval)
	if inval < minval then return minval end
	if inval > maxval then return maxval end
	return inval
end

--[[-------------------------------------------------------------------------
	string module improvements
---------------------------------------------------------------------------]]

function string.Hash(str)
	local bytes = {string_byte(str, 0, string_len(str))}
	local hash = 0

	for _, v in ipairs(bytes) do
		hash = math_fmod(v + ((hash * 32) - hash), 0x07FFFFFF)
	end

	return hash
end

function string.FormatSeconds(sec)
	local hours = math_floor(sec / 3600)
	local minutes = math_floor((sec % 3600) / 60)
	local seconds = sec % 60

	if minutes < 10 then
		minutes = "0" .. tostring(minutes)
	end

	if seconds < 10 then
		seconds = "0" .. tostring(seconds)
	end

	if hours > 0 then
		return string_format("%s:%s:%s", hours, minutes, seconds)
	else
		return string_format("%s:%s", minutes, seconds)
	end
end

function string.Reduce(str, font, width)
	surface_SetFont( font )

	local tw = surface_GetTextSize(str)
	while tw > width do
		str = string_sub(str, 1, string_len(str) - 1)
		tw, th = surface_GetTextSize(str)
	end

	return str
end

function string.FindFromTable(str, tbl)
	for _, v in ipairs(tbl) do
		if string_find(str, v) then
			return true
		end
	end

	return false
end

function string.СharCount(str, chr)
	if not str or not chr then return end
	local count = 0
	for _, char in ipairs(string_ToTable(str)) do
		if char == chr then
			count = count + 1
		end
	end

	return count
end

--[[-------------------------------------------------------------------------
	game module improvements
---------------------------------------------------------------------------]]

function game.AmmoList()
	local last = game_GetAmmoName(1)
	local output = {last}

	while (last ~= nil) do
		last = game_GetAmmoName(table_insert(output, last))
	end

	return output
end

PLib:Precache_G("game.CleanUpMap", game.CleanUpMap)
local game_CleanUpMap = PLib:Get_G("game.CleanUpMap")

function game.CleanUpMap(dontSendToClients, extraFilters, cleanupClientside)
	if CLIENT and cleanupClientside then
		PLib:CleanUpClientSideEnts(extraFilters)
	end

	return game_CleanUpMap(dontSendToClients, extraFilters)
end

--[[-------------------------------------------------------------------------
	engine module improvements
---------------------------------------------------------------------------]]

function engine.GetAddon(id)
	local addons = engine_GetAddons()
	for i = 1, #addons do
		local addon = addons[i]
		if (addon["wsid"] == id) then
			return addon
		end
	end

	return false
end

--[[-------------------------------------------------------------------------
	ents module improvements
---------------------------------------------------------------------------]]

PLib:Precache_G("ents.Create", ents.Create)
local ents_Create = PLib:Get_G("ents.Create")

function ents.Create(class)
	if SERVER then
		return ents_Create(class)
	else
		return ents_CreateClientside(class)
	end
end

--[[-------------------------------------------------------------------------
	net module improvements
---------------------------------------------------------------------------]]

-- net compressed tables by DefaultOS#5913
function net.WriteCompressTable(tbl)
	if (tbl == nil) then return end
	local data = util_Compress(util_TableToJSON(tbl))
	net_WriteUInt(#data, 16)
	net_WriteData(data, #data)
end

function net.ReadCompressTable()
	local len = net_ReadUInt(16)
	return util_JSONToTable(util_Decompress(net_ReadData(len)))
end

--[[-------------------------------------------------------------------------
	Normal bitwise library without overflowing
	By kaeza (https://gist.github.com/kaeza/8ee7e921c98951b4686d)
---------------------------------------------------------------------------]]

do
	module("pbit", package.seeall)

	local function tobittable_r(x, ...)
		if (x or 0) == 0 then return ... end
		return tobittable_r(math_floor(x / 2), x % 2, ...)
	end

	local function tobittable(x)
		assert(isnumber(x), "bad argument #1 to 'tobittable' (number expected, got " .. type(x) .. ")")
		if x == 0 then return { 0 } end
		return { tobittable_r(x) }
	end

	local function makeop(cond)
		local function oper(x, y, ...)
			if not y then return x end
			x, y = tobittable(x), tobittable(y)
			local xl, yl = #x, #y
			local t, tl = {}, math_max(xl, yl)
			for i = 0, tl - 1 do
				local b1, b2 = x[xl - i], y[yl - i]
				if not (b1 or b2) then break end
				t[tl - i] = (cond((b1 or 0) ~= 0, (b2 or 0) ~= 0) and 1 or 0)
			end
			return oper(tonumber(table_concat(t), 2), ...)
		end
		return oper
	end

	band = makeop(function(a, b) return a and b end)
	bor = makeop(function(a, b) return a or b end)
	bxor = makeop(function(a, b) return a ~= b end)

	function bnot(x, bits)
		return bxor(x, (2 ^ (bits or math_floor(math_log(x, 2)))) - 1)
	end

	function lshift(x, bits)
		return math_floor(x) * (2 ^ bits)
	end

	function rshift(x, bits)
		return math_floor(math_floor(x) / (2 ^ bits))
	end

	function tobin(x, bits)
		local r = table_concat(tobittable(x))
		return ("0"):rep((bits or 1) + 1 - #r) .. r
	end

	function frombin(x)
		return tonumber(x:match("^0*(.*)"), 2)
	end

	function bset(x, bitn)
		return bor(x, 2 ^ bitn)
	end

	function bunset(x, bitn)
		return band(x, bnot(2 ^ bitn, math_ceil(math_log(x, 2))))
	end

	function bisset(x, bitn, ...)
		if not bitn then return end
		return rshift(x, bitn) % 2 == 1, bisset(x, ...)
	end
end

--[[-------------------------------------------------------------------------
	Game Difficulties (HL2)
---------------------------------------------------------------------------]]

PLib["Difficulties"] = {"plib.difficulty.easy", "plib.difficulty.normal", "plib.difficulty.hard"}
function PLib:AddGameDifficulty(difficulty)
	assert(type(difficulty) == "string", "bad argument #1 (string expected)")

	for num, name in ipairs(self["Difficulties"]) do
		if (name == difficulty) then
			self:Log(nil, string.format("Game difficulty already exist -> %s (%s)", difficulty, num))
			return
		end
	end

	local id = table.insert(self["Difficulties"], difficulty)
	self:Log(nil, string.format("Game difficulty created -> %s (%s)", difficulty, id))
	return id, difficulty
end

function PLib:GameDifficulty()
	local difficulty, id = "Normal", game.GetSkillLevel() or cvars.Number("skill", 2)

	for num, name in ipairs(self["Difficulties"]) do
		if (num == id) then
			difficulty = name
			break
		end
	end

	return id, difficulty
end

--[[-------------------------------------------------------------------------
	not yet
---------------------------------------------------------------------------]]

function PLib:ObfuscateLua(code)
	return code
end
