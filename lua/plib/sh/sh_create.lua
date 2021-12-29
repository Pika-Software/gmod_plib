local istable = istable
local weapons_Register = weapons.Register
local table_Merge = table.Merge
local scripted_ents_Register = scripted_ents.Register
local Vector = Vector
local OrderVectors = OrderVectors
local isnumber = isnumber
local table_Merge = table_Merge
local Angle = Angle
local IsValid = IsValid
local math_min = math.min
local ScrW = ScrW
local ScrH = ScrH
local isfunction = isfunction
local LocalPlayer = LocalPlayer
local input_IsButtonDown = CLIENT and input.IsButtonDown
local gui_HideGameUI = CLIENT and gui.HideGameUI
local vgui_Create = CLIENT and vgui.Create
local cam_Start3D2D = CLIENT and cam.Start3D2D
local cam_End3D2D = CLIENT and cam.End3D2D
local hook_Add = hook.Add
local CurTime = CurTime
local isstring = isstring
local validStr = string.isvalid

--[[-------------------------------------------------------------------------
	Creating
---------------------------------------------------------------------------]]

function PLib:CreateWeapon(class, data, clear)
	if validStr(class) then
		local weapon = {}
		if not clear then
			weapon["PrintName"] = "PLib Weapon"

			weapon["Primary"]     = {}
			weapon["Secondary"]     = {}

			weapon["WorldModel"]    = ""
			weapon["ViewModel"]    = "models/weapons/c_arms.mdl"

			weapon["UseHands"]    = true
			weapon["HoldType"]    = "normal"

			weapon["Spawnable"]    = true

			function weapon:Initialize()
				self:SetWeaponHoldType(self["HoldType"])
			end

			function weapon:PrimaryAttack()
			end

			function weapon:SecondaryAttack()
			end
		end

		if isfunction(data) then
			SWEP = {}

			local ret = data(weapon, class)
			if (ret == true) then
				return
			end

			if istable(ret) then
				weapon = ret
			else
				weapon = table_Merge(weapon, SWEP)
			end

			SWEP = nil
		elseif istable(data) then
			weapon = table_Merge(weapon, data)
		end

		weapons_Register(weapon, class)
		self.dprint("SWEP", "Weapon Created -> ", class)

		if CLIENT and (weapon["Spawnable"] == true) then
			timer.Simple(0, function()
				self:SpawnMenuReload()
			end)
		end
	end
end

function PLib:CreateEntity(class, data, clear)
	if validStr(class) then
		local entity = {}
		if not clear then
			entity["Base"] = "base_anim"
			entity["Type"] = "anim"

			entity["Model"] = "models/props_c17/oildrum001_explosive.mdl"
			entity["PrintName"] = "PLib Entity"

			entity["DisableDuplicator"] = true
			entity["Spawnable"] = true

			function entity:Initialize()
				if SERVER then
					self:SetModel(self["Model"])
					self:PhysicsInit(SOLID_VPHYSICS)
				end
			end
		end

		if isfunction(data) then
			ENT = {}

			local ret = data(entity, class)
			if (ret == true) then
				return
			end

			if istable(ret) then
				entity = ret
			else
				entity = table_Merge(entity, ENT)
			end

			ENT = nil
		elseif istable(data) then
			entity = table_Merge(entity, data)
		end

		scripted_ents_Register(entity, class)
		self.dprint("ENT", "Entity Created -> ", class)

		if CLIENT and (entity["Spawnable"] == true) then
			timer.Simple(0, function()
				self:SpawnMenuReload()
			end)
		end
	end
end

function PLib:LoadEntity(path)
	self:CreateEntity(path:match("([^/]+)$"):match("(.+)%..+"), function(ENT, class)
		local folder = path:match(".+/")

		ENT["Folder"] = folder

		for k, fl in ipairs(file.Find(folder, "LUA")) do
			local path = folder .. "/" .. fl
			if path:find("cl_init.lua") then
				if CLIENT then
					SafeInclude(path)
				else
					AddCSLuaFile(path)
				end

				continue
			end

			if path:find("init.lua") then
				if SERVER then
					SafeInclude(path)
				end

				continue
			end

			if SERVER then
				AddCSLuaFile(path)
			end

			include(path)
		end
	end, true)
end

function PLib:CreateTrigger(class, data)
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
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_BBOX)
		self:DrawShadow(false)
		self:SetNoDraw(true)

		if SERVER then
			self:SetTrigger(true)
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

function PLib:CreateButton(class, data, usetype)
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
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_BBOX)
		self:DrawShadow(false)
		self:SetNoDraw(true)

		if SERVER then
			self:SetUseType(isnumber(usetype) and usetype or SIMPLE_USE)
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

function PLib:CreateInfoBanner(class, url, mins, maxs)
	self:CreateButton(class, {
		["URL"] = url or "http://pika-soft.ru/",
		["Mins"] = mins or Vector(-18, 0, -15),
		["Maxs"] = maxs or Vector(18, 2, 55),
		["UpdatePos"] = function(self)
			local mins, maxs = self:OBBMins(), self:OBBMaxs()
			self["pnlPos"] = Vector(maxs[1], 1, maxs[3]) + self:GetPos()
			self["pnlAng"] = Angle(0, 180, 90) + self:GetAngles()
			self["pnlSize"] = {(maxs[1] - mins[1]) * 10 + 18, (maxs[3] - mins[3]) * 10}

			local pnl = self["pnl"]
			if IsValid(pnl) then
				if (pnl["Opened"] == false) then
					pnl:SetSize(self["pnlSize"][1], self["pnlSize"][2])
					pnl:SetPos(0, 0)
				else
					pnl:SetSize(math_min(ScrW(), self["pnlSize"][1] * 1.5), math_min(ScrH(), self["pnlSize"][2] * 1.5))
					pnl:Center()
				end

				function pnl:Think()
				end
			end
		end,
		["Toggle"] = function(self, bool)
			local pnl = self["pnl"]
			if IsValid(pnl) then
				pnl["Opened"] = (bool == true) and true or false
				self:UpdatePos()

				if (bool == true) then
					pnl:SetPaintedManually(false)
					GAMEMODE:ShowMouse()

					local ent = self
					function pnl:Think()
						if IsValid(ent) then
							if (ent:GetPos():DistToSqr(LocalPlayer():EyePos()) > 10000) then
								ent:Toggle()
								return
							end

							if input_IsButtonDown(KEY_ESCAPE) then
								gui_HideGameUI()
								ent:Toggle()
							end
						end
					end
				else
					pnl:SetPaintedManually(true)
					GAMEMODE:HideMouse()
				end
			end
		end,
		["UpdateVGUI"] = function(self)
			local pnl = self["pnl"]
			if IsValid(pnl) then
				pnl:Remove()
			end

			self["pnl"] = vgui_Create("DHTML")
			if IsValid(self["pnl"]) then
				self["pnl"]:OpenURL(self["URL"])
				self:Toggle()
				self:UpdatePos()
			end
		end,
		["Draw"] = function(self)
			local pnl = self["pnl"]
			if IsValid(pnl) and (pnl["Opened"] == false) then
				cam_Start3D2D(self["pnlPos"], self["pnlAng"], 0.1)
					pnl:PaintManual()
				cam_End3D2D()
			end
		end,
		["Init"] = function(self)
			self:SetNoDraw(false)

			if CLIENT then
				self:UpdateVGUI()

				hook_Add("PLib:PlayerInitialized", self, function(self)
					if not IsValid(self) then return end
					self:Init()
				end)
			end
		end,
		["Timeout"] = 0,
		["Think"] = function(self)
			if CLIENT and (self["Timeout"] < CurTime()) then
				self["Timeout"] = CurTime() + 15 * 60

				self:UpdateVGUI()
			end
		end,
		["Use"] = function(self, ply)
			if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
				ply:SendLua("local ent = Entity(" .. self:EntIndex() .. ");if IsValid(ent) then ent:Toggle(true);end")
			end
		end,
	})
end

--[[-------------------------------------------------------------------------
	Library entities
---------------------------------------------------------------------------]]

PLib:CreateTrigger("plib_achievement_trigger", {
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
})

PLib:CreateButton("plib_achievement_button", {
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
})

PLib:CreateTrigger("prop_collide_box", {
	["Init"] = function(self)
		if SERVER then
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
			self:SetTrigger(false)
			self:SetNoDraw(false)
		end
    end
})