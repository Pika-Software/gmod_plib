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

function PLib:GetServerName()
	return GetGlobalString("ServerName", SERVER and self:GetHostName() or "Garry's Mod")
end

function PLib:SetServerName(str)
	local old = self:GetServerName()
	SetGlobalString("ServerName", isstring(str) and str or old)
	timer.Simple(0, function()
		self:Log(nil, string.format("Server name changed from '%s' to '%s'!", old, self:GetServerName()))
	end)
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

function VECTOR:InBox(vec1, vec2)
	return self[1] >= vec1[1] and self[1] <= vec2[1] and self[2] >= vec1[2] and self[2] <= vec2[2] and self[3] >= vec1[3] and self[3] <= vec2[3]
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

function math.power2(n)
	return math.pow(2, math.ceil(math.log(n) / math.log(2)))
end

function math.Map(int, from1, to1, from2, to2)
    return (int - from1) / (to1 - from1) * (to2 - from2) + from2;
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

function table.Lookup(tbl, key, default)
	local fragments = string.Split(key, '.')
	local value = tbl

	for _, fragment in ipairs(fragments) do
		value = value[fragment]

		if not value then
			return default
		end
	end

	return value
end

function string.hash( str )
	local bytes = {string.byte(str, 0, string.len(str))}
	local hash = 0

	for _, v in ipairs( bytes ) do
		hash = math.fmod( v + ((hash*32) - hash ), 0x07FFFFFF )
	end
	
	return hash
end

function string.FormatSeconds(sec)
	local hours = math.floor(sec / 3600)
	local minutes = math.floor((sec % 3600) / 60)
	local seconds = sec % 60

	if minutes < 10 then
		minutes = "0" .. tostring(minutes)
	end

	if seconds < 10 then
		seconds = "0" .. tostring(seconds)
	end

	if hours > 0 then
		return string.format("%s:%s:%s", hours, minutes, seconds)
	else
		return string.format("%s:%s", minutes, seconds)
	end
end

function string.reduce(str, font, width)
	surface.SetFont( font )

	local tw, th = surface.GetTextSize(str)
	while tw > width do
		str = string.sub(str, 1, string.len(str) - 1)
		tw, th = surface.GetTextSize(str)
	end

	return str
end

function string.findFromTable(str, tbl)
	for _, v in ipairs(tbl) do
		if string.find(str, v) then
			return true
		end
	end

	return false
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

if CLIENT then
	hook.Add("PostGamemodeLoaded", "PLib:IsSandbox_Check", function()
		if GAMEMODE["IsSandboxDerived"] then
			PLib["isSandbox"] = true
			hook.Run("PLib:IsSandbox")
		else
			PLib["isSandbox"] = false
		end
	end)

	function PLib:SpawnMenuReload()
		if not self["isSandbox"] or not hook.Run("SpawnMenuEnabled") then return end
	
		-- If we have an old spawn menu remove it.
		if IsValid(g_SpawnMenu) then
			g_SpawnMenu:Remove()
			g_SpawnMenu = nil
		end
	
		hook.Run("PreReloadToolsMenu")
	
		-- Start Fresh
		spawnmenu.ClearToolMenus()
	
		-- Add defaults for the gamemode. In sandbox these defaults
		-- are the Main/Postprocessing/Options tabs.
		-- They're added first in sandbox so they're always first
		hook.Run("AddGamemodeToolMenuTabs")
	
		-- Use this hook to add your custom tools
		-- This ensures that the default tabs are always
		-- first.
		hook.Run("AddToolMenuTabs")
	
		-- Use this hook to add your custom tools
		-- We add the gamemode tool menu categories first
		-- to ensure they're always at the top.
		hook.Run("AddGamemodeToolMenuCategories")
		hook.Run("AddToolMenuCategories")
	
		-- Add the tabs to the tool menu before trying
		-- to populate them with tools.
		hook.Run("PopulateToolMenu")
	
		g_SpawnMenu = vgui.Create("SpawnMenu")
	
		if IsValid(g_SpawnMenu) then
			g_SpawnMenu:SetVisible( false )
			hook.Run("SpawnMenuCreated", g_SpawnMenu)
		end
	
		CreateContextMenu()
	
		hook.Run("PostReloadToolsMenu")
	end
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

function PLib:CreateEntity(class, data, clear)
	if validStr(class) and istable(data) then
		local ENT = {}
		if not clear then
			ENT["Base"] = "base_anim"
			ENT["Model"] = "models/props_c17/oildrum001_explosive.mdl"
			ENT["Category"]	= "PLib"
			ENT["PrintName"] = "PLib Entity"
			ENT["Spawnable"] = true

			function ENT:Initialize()
				if SERVER then
					self:SetModel(self["Model"])
					self:PhysicsInit(SOLID_VPHYSICS)
				end
			end
		end

		scripted_ents_Register(table_Merge(ENT, data), class)
		dprint("ENT", "Entity Created -> ", class)

		if CLIENT then
			self:SpawnMenuReload()
		end
	end
end

function PLib:CreateTriggerEntity(class, data, trigger, use)
	local ENT = {}
	ENT["Type"] = "anim"
	ENT["PrintName"] = "PLib Trigger"
	ENT["Mins"] = Vector(-25, -25, -25)
	ENT["Maxs"] = Vector(25, 25, 25)

	function ENT:Init()
	end

	function ENT:SetSize(mins, maxs)
		self["Mins"], self["Maxs"] = mins, maxs
	end

	function ENT:SetupBox(mins, maxs)
		OrderVectors(mins, maxs)
		self:SetCollisionBounds(mins, maxs)
		self["Mins"], self["Maxs"] = mins, maxs
	end

	function ENT:Initialize()
		self:SetCollisionGroup((use != nil) and COLLISION_GROUP_DEBRIS or COLLISION_GROUP_IN_VEHICLE)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_BBOX)
		self:DrawShadow(false)
		self:SetNoDraw(true)

		if SERVER then
			self:SetTrigger((trigger == true) and trigger or false)
			if (use != nil) then
				self:SetUseType(isnumber(use) and use or SIMPLE_USE)
			end
		end

		self:SetupBox(self["Mins"], self["Maxs"])
		self:Init()
	end

	if CLIENT then
		local plib = self
		function ENT:Draw()
			plib:DebugEntityDraw(self)
		end
	end

	self:CreateEntity(class, table_Merge(ENT, data or {}), true)
end

PLib:CreateTriggerEntity("plib_achievement_trigger", {
	["Init"] = function(self)
		self:SetNoDraw(false)
	end,
	["SetAchievement"] = function(self, tag)
		self["Achievement"] = tag
	end,
	["StartTouch"] = function(self, ply)
		local tag = self["Achievement"]
        if isstring(tag) and IsValid(ply) and ply:IsPlayer() and (ply[tag] == nil) then
            ply:GiveAchievement(tag)
            ply[tag] = true
        end
    end,
}, true)

PLib:CreateTriggerEntity("plib_achievement_button", {
	["SetAchievement"] = function(self, tag)
		self["Achievement"] = tag
	end,
	["Init"] = function(self)
		self:SetNoDraw(false)
	end,
	["Use"] = function(self, ply)
		local tag = self["Achievement"]
        if isstring(tag) and IsValid(ply) and ply:IsPlayer() and (ply[tag] == nil) then
            ply:GiveAchievement(tag)
            ply[tag] = true
        end
    end,
}, false, true)

local steamworks_DownloadUGC = steamworks and steamworks.DownloadUGC
PLib["WorkshopDownloaded"] = PLib["WorkshopDownloaded"] or {}

function PLib:WorkshopDownload(id, cb)
	local saved = PLib["WorkshopDownloaded"][id]
	if (saved == nil) then
		if CLIENT then
			notification.AddProgress("plib.workshop_download_#" .. id, "[PLib] Downloading: " .. id)
		end

		steamworks_DownloadUGC(id, function(path)
			if CLIENT then
				notification.Kill("plib.workshop_download_#" .. id)
			end

			PLib["WorkshopDownloaded"][id] = path
			if isfunction(cb) then
				cb(path)
			end

			dprint("Workshop", "Install try download workshop addon, id: ", id)
		end)
	else
		if isfunction(cb) then
			cb(saved)
		end

		return saved
	end

	dprint("Workshop", "Install try download workshop addon, id: ", id)
end

PLib["WorkshopInstalled"] = PLib["WorkshopInstalled"] or {}
local game_MountGMA = game.MountGMA

function PLib:WorkshopInstall(id, cb)
	local saved = PLib["WorkshopDownloaded"][id]
	if (saved == nil) then
		self:WorkshopDownload(id, function(path)
			local ok, files = game_MountGMA(path)

			local outputTbl = {path, files}
			if (ok == true) then
				PLib["WorkshopInstalled"][id] = outputTbl
			end

			if isfunction(cb) then
				cb(ok, path, files)
			end

			return (ok == true) and outputTbl or false
		end)
	else
		if isfunction(cb) then
			cb(true, saved[1], saved[2])
		end	

		return saved
	end
end

function PLib:TryInstallWorkshop(id, cb, num)
	self:WorkshopInstall(id, function(ok, path, files)
		if (ok == false) then
			local num = num + 1
			timer.Simple(10, function()
				self:TryInstallWorkshop(id, cb, num)
			end)

			dprint("Workshop", "Install try #", num)
		elseif isfunction(cb) then
			cb(path, files)
		end
	end)
end

PLib:Precache_G("ents.Create", ents.Create)
local ents_Create = PLib:Get_G("ents.Create")

function ents.Create(class)
	if SERVER then
		return ents_Create(class)
	else
		return ents.CreateClientside(class)
	end
end

PLib:Precache_G("game.CleanUpMap", game.CleanUpMap)
local game_CleanUpMap = PLib:Get_G("game.CleanUpMap")

function game.CleanUpMap(dontSendToClients, extraFilters, cleanupClientside)
	if CLIENT and cleanupClientside then
		PLib:CleanUpClientSideEnts(extraFilters)
	end

	return game_CleanUpMap(dontSendToClients, extraFilters)
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