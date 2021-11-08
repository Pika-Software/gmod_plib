AddCSLuaFile()

local tostring = tostring
local IsValid = IsValid

ENT["Base"] = "base_anim"
ENT["PrintName"] = "Online Radio"
ENT["Spawnable"] = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Enabled")
    self:NetworkVar("String", 0, "URL")
end

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_lab/citizenradio.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        self:SetUseType(SIMPLE_USE)

        if (self["SetUnbreakable"] != nil) then
            self:SetUnbreakable(true)
        end
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
    local render_SetStencilCompareFunction = render.SetStencilCompareFunction
    local render_SetStencilZFailOperation = render.SetStencilZFailOperation
    local render_SetStencilReferenceValue = render.SetStencilReferenceValue
    local render_SetStencilPassOperation = render.SetStencilPassOperation
    local render_SetStencilFailOperation = render.SetStencilFailOperation
    local render_SetStencilWriteMask = render.SetStencilWriteMask
    local render_SetStencilTestMask = render.SetStencilTestMask
    local render_SetStencilEnable = render.SetStencilEnable
    local surface_SetDrawColor = surface.SetDrawColor
    local render_ClearStencil = render.ClearStencil
    local surface_DrawPoly = surface.DrawPoly
    local surface_DrawRect = surface.DrawRect
    local draw_NoTexture = draw.NoTexture
    local net_ReadEntity = net.ReadEntity
    local net_ReadString = net.ReadString
    local cam_Start3D2D = cam.Start3D2D
    local cam_End3D2D = cam.End3D2D
    local net_Receive = net.Receive
    local HSVToColor = HSVToColor
    local FrameTime = FrameTime
    local math_cos = math.cos
    local math_sin = math.sin
    local math_max = math.max
    local Vector = Vector
    local Angle = Angle

    net_Receive("PLib.Radio", function()
        local ent = net_ReadEntity()
        if IsValid(ent) and (ent:GetClass() == "plib_radio") then
            PLib:PlayURL(net_ReadString(), net_ReadString(), ent)
        end
    end)

    ENT["polys"] = {
        [1] = {x = -380, y = 230},
        [2] = {x = -380, y = 7},
        [23] = {x = 482.99639374367, y = 230},
    }

    for i = 3, 22 do
        local t = math.pi * 2 / 20 * (i-2)
        local cos = 200 / 2 + math_cos(4.5 + t / 3.5) * 200 / 4
        local sin = 200 / 2 + math_sin(4.5 + t / 3.5) * 200 / 4

        ENT["polys"][i] = {x = 785 - 380 + cos - 72, y = sin - 18 - 25}
    end

    ENT["fftV"] = {}

    function ENT:Draw(flags)
        self:DrawModel(flags)

        local fft, bass = {}, 0
        local channel = self[self["FM_Tag"]]
        if IsValid(channel) then
            fft, bass = PLib:SoundAnalyze(channel)
        end

        render_SetStencilWriteMask( 0xFF )
        render_SetStencilTestMask( 0xFF )
        render_SetStencilReferenceValue( 0 )
        render_SetStencilCompareFunction( STENCIL_ALWAYS )
        render_SetStencilPassOperation( STENCIL_KEEP )
        render_SetStencilFailOperation( STENCIL_KEEP )
        render_SetStencilZFailOperation( STENCIL_KEEP )
        render_ClearStencil()

        render_SetStencilEnable( true )
        render_SetStencilReferenceValue( 1 )
        render_SetStencilCompareFunction( STENCIL_NEVER )
        render_SetStencilFailOperation( STENCIL_REPLACE )

        cam_Start3D2D(self:GetPos() + Vector(-8.7, 0, 16), self:GetAngles() + Angle(0, 90, 90), 0.0215)
            surface_SetDrawColor(255, 255, 255, 255)
            draw_NoTexture()
            surface_DrawPoly(self["polys"])
        cam_End3D2D()

        render_SetStencilCompareFunction( STENCIL_EQUAL )
        render_SetStencilFailOperation( STENCIL_KEEP )

        cam_Start3D2D(self:GetPos() + Vector(-8.7, 0, 16), self:GetAngles() + Angle(0, 90, 90), 0.0215)
            surface_SetDrawColor(5, 5, 8, 255)
            surface_DrawRect(-380, 0, 870, 230, 0)

            if (bass != 0) then
                for i = 1, 84 do
                    self["fftV"][i] = math_max(fft[i], (self["fftV"][i] or 0) - FrameTime() / 10)

                    surface_SetDrawColor(HSVToColor((180 + (self["fftV"][i] - fft[i]) * 800)%360, 1, 1))
                    surface_DrawRect(-380 + i * 10, 200 - fft[i] * 1400 , 10, 2+fft[i]*1400)
                    surface_SetDrawColor(255, 255, 255,55)
                    surface_DrawRect(-380 + i * 10, 200 - self["fftV"][i]*1400 , 10, 2+self["fftV"][i] * 1400)
                end
            end
        cam_End3D2D()

        render_SetStencilEnable( false )

        render_SetStencilEnable( true )
        render_SetStencilReferenceValue( 1 )
        render_SetStencilCompareFunction( STENCIL_NEVER )
        render_SetStencilFailOperation( STENCIL_REPLACE )

        cam_Start3D2D(self:GetPos() + Vector(-8.7,0,16), self:GetAngles() + Angle(0, 90, 90), 0.0215)
            surface_SetDrawColor(5, 5, 8, 255)
            surface_DrawRect( -596, 32, 156, 109 )
        cam_End3D2D()

        render_SetStencilCompareFunction( STENCIL_EQUAL )
        render_SetStencilFailOperation( STENCIL_KEEP )

        cam_Start3D2D(self:GetPos() + Vector(-6.6,11,12), self:GetAngles() + Angle(-28 + bass, 90, 90), 0.0215)
            surface_SetDrawColor(5, 5, 8, 255)
            surface_DrawRect(-5 / 2, -100, 5, 100)
        cam_End3D2D()

        render_SetStencilEnable( false )
    end
end