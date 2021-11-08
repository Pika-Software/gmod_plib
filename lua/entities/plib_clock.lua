AddCSLuaFile()

ENT["Base"] = "base_anim"
ENT["PrintName"] = "Clock"
ENT["Spawnable"] = true

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_c17/clock01.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

        if (self["SetUnbreakable"] != nil) then
            self:SetUnbreakable(true)
        end
    else
        self["Sec"] = 0
        self["Mins"] = 0
        self["Hours"] = 0
    end
end

if CLIENT then
    local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_SetMaterial = surface.SetMaterial
    local cam_Start3D2D = cam.Start3D2D
    local cam_End3D2D = cam.End3D2D
    local tonumber = tonumber
    local os_date = os.date
    local Vector = Vector

    local hours = Material("https://i.imgur.com/BvfYi4f.png", PLib["MatPresets"]["Pic"])
    local mins = Material("https://i.imgur.com/yRMoWa5.png", PLib["MatPresets"]["Pic"])
    local secs = Material("https://i.imgur.com/OiHyZVq.png", PLib["MatPresets"]["Pic"])

    local color_white = color_white

    function ENT:Draw()
        self:DrawModel()

        cam_Start3D2D(self:LocalToWorld(Vector( -0.05, -0.05, 3.38)), Angle(0, 0, -90), 1)
            surface_SetDrawColor(color_white)

            surface_SetMaterial(hours)
            surface_DrawTexturedRectRotated(0, 0, 15, 15, self["Hours"])

            surface_SetMaterial(mins)
            surface_DrawTexturedRectRotated(0, 0, 15, 15, self["Mins"])

            surface_SetMaterial(secs)
            surface_DrawTexturedRectRotated(0, 0, 15, 15, self["Sec"])
        cam_End3D2D()
    end

    function ENT:Think()
        local h = tonumber(os_date("%I"))
        local min = tonumber(os_date("%M"))
        local secs = tonumber(os_date("%S"))

        local sz = 180
        self["Sec"] = sz - 6 * secs
        self["Mins"] = sz - (min / 60 * 360 + 6*secs / 60)
        self["Hours"] = sz - (h/12 * 360)+(6 * ( min / 60 )) + (0.1 * secs / 60)
    end
end