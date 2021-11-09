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
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        self:SetUseType(SIMPLE_USE)

        hook.Add("PLib:Loaded", self, function()
            if IsValid(self) then
                if (self["SetUnbreakable"] != nil) then
                    self:SetUnbreakable(true)
                end  
            end
        end)

        self:SetFDist(400)
        self:SetSDist(500)
    end

    self["FM_Tag"] = tostring(self).."_radio"
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
    local pairs = pairs

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

            self:SetURL(self:GetEnabled() and table_Random(self["URLs"]) or "Stop")
            timer.Simple(0, function()
                self:Play()
            end)

            self["UseTimeout"] = time + 1
        end
    end

    net.Receive("PLib.Radio", function(len, ply)
        local time = CurTime()
        if !IsValid(ply) or (ply["PLib.Radio"] or 0) > time then return end
        ply["PLib.Radio"] = time + 10

        local ent = net.ReadEntity()
        if IsValid(ent) and (ent:GetClass() == "plib_radio") and ((ent["PLib.Radio"] or 0) < time) then
            ent["PLib.Radio"] = time + 5

            ent:SetURL(ent:GetEnabled() and table_Random(ent["URLs"]) or "Stop")
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
    local Angle = Angle

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

        cam_Start3D2D(self:LocalToWorld(Vector(8.45, 1.8, 16)), self:GetAngles() + Angle(0, 90, 90), 0.0215)
            surface_SetDrawColor(5, 5, 8, 255)
            surface_DrawRect(-355, 15, 820, 200, 0)

            for i = 1, 80 do
                local FFT = self["FFT"][i] or 0
                local FFT2 = self["FFT2"][i] or 0

                self["FFT2"][i] = math_max(FFT, FFT2 - FrameTime() / 10)

                local simple = math_min(180, FFT * 1200)
                surface_SetDrawColor(HSVToColor((180 + (FFT2 - FFT) * 800) % 360, 1, 1))
                surface_DrawRect(-360 + i * 10, 200 - simple, 10, simple)

                local simple2 = math_min(180, FFT2 * 1200)
                surface_SetDrawColor(255, 255, 255, 55)
                surface_DrawRect(-360 + i * 10, 200 - simple2, 10, simple2)
            end
        cam_End3D2D()
    
        cam_Start3D2D(self:LocalToWorld(Vector(8.45, -9.7, 12)), self:GetAngles() + Angle(-28 + math_min(60, self["Bass"]), 90, 90), 0.0215)
            surface_SetDrawColor(5, 5, 8, 255)
            surface_DrawRect(0, -100, 5, 60)
        cam_End3D2D()
    end
end