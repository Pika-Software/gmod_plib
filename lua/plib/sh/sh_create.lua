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

function PLib:CreateWeapon(class, data)
	if validStr(class) and istable(data) then
		local SWEP = {}
		SWEP["PrintName"] = "PLib Weapon"
		SWEP["Primary"]     = {}
		SWEP["Secondary"]     = {}
		SWEP["WorldModel"]    = ""
		SWEP["ViewModel"]    = "models/weapons/c_arms.mdl"
		SWEP["Category"]    = "PLib"
		SWEP["HoldType"]    = "normal"
		SWEP["Spawnable"]    = true
		SWEP["UseHands"]    = true

		function SWEP:Initialize()
			self:SetWeaponHoldType(self["HoldType"])
		end

		weapons_Register(table_Merge(SWEP, data), class)
		self.dprint("SWEP", "Weapon Created -> ", class)

		if CLIENT then
			timer.Simple(0, function() self:SpawnMenuReload() end)
		end
	end
end

function PLib:CreateEntity(class, data, clear)
	if validStr(class) and istable(data) then
		local ENT = {}
		if not clear then
			ENT["Base"] = "base_anim"
			ENT["Model"] = "models/props_c17/oildrum001_explosive.mdl"
			ENT["PrintName"] = "PLib Entity"
			ENT["Spawnable"] = true
			ENT["DisableDuplicator"] = true

			function ENT:Initialize()
				if SERVER then
					self:SetModel(self["Model"])
					self:PhysicsInit(SOLID_VPHYSICS)
				end
			end
		end

		scripted_ents_Register(table_Merge(ENT, data), class)
		self.dprint("ENT", "Entity Created -> ", class)

		if CLIENT then
			timer.Simple(0, function() self:SpawnMenuReload() end)
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

function PLib:CreateInfoBanner(class, url, mins, maxs)
	self:CreateTriggerEntity(class, {
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
	}, false, true)
end

--[[-------------------------------------------------------------------------
	Library entities
---------------------------------------------------------------------------]]

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