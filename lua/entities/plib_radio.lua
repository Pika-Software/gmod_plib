AddCSLuaFile()

local tostring = tostring
local IsValid = IsValid

ENT["Base"] = "base_anim"
ENT["PrintName"] = "Online Radio"
ENT["Spawnable"] = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enabled")
	self:NetworkVar("String", 0, "URL")
	self:NetworkVar("Int", 0, "FDist")
	self:NetworkVar("Int", 1, "SDist")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_lab/citizenradio.mdl")
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		hook.Add("PLib:Loaded", self, function()
			if IsValid(self) and self["SetUnbreakable"] ~= nil then
				self:SetUnbreakable(true)
			end
		end)

		self:SetFDist(400)
		self:SetSDist(500)
	end

	self:AddEFlags(EFL_NO_THINK_FUNCTION)

	self["FM_Tag"] = tostring(self) .. "_radio"
end

if SERVER then
	util.AddNetworkString("PLib.Radio")

	local net_WriteEntity = net.WriteEntity
	local net_WriteString = net.WriteString
	local net_Broadcast = net.Broadcast
	local table_Random = table.Random
	local net_Start = net.Start
	local net_Send = net.Send
	local isstring = isstring
	local CurTime = CurTime
	local istable = istable

	function ENT:Play(ply)
		net_Start("PLib.Radio")
			net_WriteEntity(self)
			net_WriteString(self["FM_Tag"])
			net_WriteString(self:GetURL())
		if (ply == nil) then
			net_Broadcast()
		else
			net_Send(ply)
		end
	end

	function ENT:Use()
		local time = CurTime()
		if ((self["UseTimeout"] or 0) < time) then
			self:SetEnabled(not self:GetEnabled())
			self:EmitSound("buttons/lightswitch2.wav")

			self:SetURL(self:GetEnabled() and table_Random(self["URLs"] or {"https://radio.pika-soft.ru/stream"}) or "Stop")
			timer.Simple(0, function()
				self:Play()
			end)

			self["UseTimeout"] = time + 1
		end
	end

	net.Receive("PLib.Radio", function(len, ply)
		local time = CurTime()
		if not IsValid(ply) or (ply["PLib.Radio"] or 0) > time then return end
		ply["PLib.Radio"] = time + 10

		local ent = net.ReadEntity()
		if IsValid(ent) and (ent:GetClass() == "plib_radio") and ((ent["PLib.Radio"] or 0) < time) then
			ent["PLib.Radio"] = time + 5

			ent:SetURL(ent:GetEnabled() and istable(ent["URLs"]) and table_Random(ent["URLs"]) or "Stop")
			timer.Simple(0, function()
				ent:Play()
			end)
		end
	end)

	function ENT:OnRemove()
	end

	function ENT:SetURLs(url)
		if istable(url) then
			self["URLs"] = url
		elseif isstring(url) then
			self["URLs"] = {url}
		end
	end

	hook.Add("PLib:PlayerInitialized", "PLib.Radio", function(ply)
		timer.Simple(0, function()
			for num, ent in ipairs(ents.FindByClass("plib_radio")) do
				if IsValid(ent) and ent:GetEnabled() then
					ent:Play(ply)
				end
			end
		end)
	end)
else
	local surface_SetDrawColor = surface.SetDrawColor
	local surface_DrawRect = surface.DrawRect
	local net_ReadEntity = net.ReadEntity
	local net_ReadString = net.ReadString
	local cam_Start3D2D = cam.Start3D2D
	local cam_End3D2D = cam.End3D2D
	local net_Receive = net.Receive
	local HSVToColor = HSVToColor
	local FrameTime = FrameTime
	local math_max = math.max
	local math_min = math.min
	local Vector = Vector

	net_Receive("PLib.Radio", function()
		local ent = net_ReadEntity()
		if IsValid(ent) and (ent:GetClass() == "plib_radio") then
			PLib:PlayURL(net_ReadString(), net_ReadString(), ent, ent:GetFDist(), ent:GetSDist())
		end
	end)

	function ENT:AudioEnded(channel, tag)
		PLib:RemoveURLSound(tag)

		net.Start("PLib.Radio")
			net.WriteEntity(self)
		net.SendToServer()
	end

	ENT["FFT"] = {}
	ENT["FFT2"] = {}
	ENT["Bass"] = 0
	function ENT:Draw(flags)
		self:DrawModel(flags)

		local channel = self[self["FM_Tag"]]
		if IsValid(channel) then
			local fft, bass = PLib:SoundAnalyze(channel)
			self["FFT"] = fft
			self["Bass"] = math.striving_for(self["Bass"], bass, 100)
		end

		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		cam_Start3D2D(self:LocalToWorld(Vector(8.45, 1.8, 16)), ang, 0.0215)
			surface_SetDrawColor(5, 5, 8, 255)
			surface_DrawRect(-355, 15, 820, 200, 0)

			for i = 1, 80 do
				local FFT = self["FFT"][i] or 0
				local FFT2 = self["FFT2"][i] or 0

				self["FFT2"][i] = math_max(FFT, FFT2 - FrameTime() / 10)

			if self["Bass"] == 0 or !IsValid(channel)  then
				self["FFT"][i] = math_max(0, FFT - FrameTime() / 10)
				self["Bass"] = math_max(0, self["Bass"] - FrameTime() / 10)
			end

				local simple = math_min(180, FFT * 1200)
				surface_SetDrawColor(HSVToColor((180 + (FFT2 - FFT) * 800) % 360, 1, 1))
				surface_DrawRect(-360 + i * 10, 200 - simple, 10, simple)

				local simple2 = math_min(180, FFT2 * 1200)
				surface_SetDrawColor(255, 255, 255, 55)
				surface_DrawRect(-360 + i * 10, 200 - simple2, 10, simple2)
			end
		cam_End3D2D()

		ang:RotateAroundAxis(ang:Up(), 28 - math_min(58, self["Bass"] * 1.5))

		cam_Start3D2D(self:LocalToWorld(Vector(8.45, -9.7, 12)), ang, 0.0215)
			surface_SetDrawColor(5, 5, 8, 255)
			surface_DrawRect(0, -100, 5, 60)
		cam_End3D2D()
	end
end