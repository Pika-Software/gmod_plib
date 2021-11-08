-- PLib Achievement by PrikolMen#3372
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_GetTextSize = surface.GetTextSize
local draw_LinearGradient = draw.LinearGradient
local surface_PlaySound = surface.PlaySound
local surface_DrawRect = surface.DrawRect
local surface_SetFont = surface.SetFont
local draw_DrawText = draw.DrawText
local table_remove = table.remove
local ScreenScale = ScreenScale
local cam_Start2D = cam.Start2D
local math_floor = math.floor
local math_Clamp = math.Clamp
local FrameTime = FrameTime
local cam_End2D = cam.End2D
local math_max = math.max
local hook_Add = hook.Add
local IsValid = IsValid
local CurTime = CurTime
local ipairs = ipairs
local Color = Color
local ScrH = ScrH

-- w 240 - ss 80
-- h 96     - ss 32
local aw, ah, maxOnScreen = 240, 93
local function ScreenInit()
    maxOnScreen = math_floor(ScrH()/ah)
end

hook_Add("OnScreenSizeChanged", "PLib:Achievement", ScreenInit)
ScreenInit()

local font = "Main1"
local sound1 = Sound("ui/buttonrollover.wav")

local achievementsCreated = {}
local PANEL = {}

function PANEL:TextChanged()
    surface_SetFont(font)
    local x1, y1 = surface_GetTextSize("#plib.achievement")
    local x2, y2 = surface_GetTextSize(self["Title"])
    self["TextW"] = math_max(x1, x2)
    self["TextH"] = y1
end

local table_insert = table.insert
function PANEL:Init()
    self["Offset"] = 0
    self["Direction"] = 1
    self["Speed"] = 3
    self["Title"] = "Title"
    self["TextW"] = 32
    self["Slot"] = 0

    self:SetPaintedManually(false)
    self:NoClipping(true)
    self:TextChanged()

    for num, pnl in ipairs(achievementsCreated) do
        if not IsValid(pnl) then
            self["Slot"] = num
            achievementsCreated[num] = self
            return
        end
    end

    table_insert(achievementsCreated, self)
    self["Slot"] = #achievementsCreated
end

local defaultIcon = Material("https://i.imgur.com/Rlcq2Nm.png", PLib["MatPresets"]["Pic"])
function PANEL:SetAchievement(tag)
    local tbl = PLib["Achievements"][tag]
    if (tbl != nil) then
        self["Title"] = PLib:TranslateText(tbl[1])
        self["Image"] = tbl[2] or defaultIcon

        self:TextChanged()
    else
        self:Remove()
    end
end

function PANEL:Think()
    if (self["Slot"] > maxOnScreen) then
        for num, pnl in ipairs(achievementsCreated) do
            if not IsValid(pnl) then
                self["Slot"] = num
                achievementsCreated[num] = self
                return
            end
        end
    end

    self["Offset"] = math_Clamp(self["Offset"] + (self["Direction"] * FrameTime() * self["Speed"]), 0, 1)
    self:InvalidateLayout()

    if (self["Direction"] == 1) and (self["Offset"] == 1) then
        self["Direction"] = 0
        self["Down"] = CurTime() + 5
    end

    if (self["Down"] != nil) and (CurTime() > self["Down"]) then
        self["Direction"] = -1
        self["Down"] = nil
    end

    if (self["Offset"] == 0) then
        self:Remove()
    end

    if (self["Sound"] == nil) and (self["Slot"] <= maxOnScreen) then
        surface_PlaySound(sound1)
        self["Sound"] = true
    end
end

function PANEL:PerformLayout()
    if (self["Slot"] > maxOnScreen) then return end
    PLib:Draw2D(function(w, h)
        self:SetSize(aw + self["TextW"]/2, ah)
        self:SetPos(w - aw - self["TextW"]/2, h - (ah * self["Offset"] * self["Slot"]))
    end)
end

local col0 = Color(42, 46, 51)
local col1 = Color(18, 26, 42)
local col2 = Color(42, 71, 94)

local preset1 = {
    {offset = 0, color = col1},
    {offset = 1, color = col2},
}

local preset2 = {
    {offset = 0, color = col0},
    {offset = 1, color = col1},
}

local color_white = color_white
local color_white2 = Color(221, 221, 221)
local color_white3 = Color(198, 206, 218)
function PANEL:Paint(w, h)
    if (self["Slot"] > maxOnScreen) then return end
    local x, y = self:GetPos()

    local alpha = (255 * self["Offset"])
    col0:SetAlpha(alpha)
    col1:SetAlpha(alpha)
    col2:SetAlpha(alpha)
    self:SetAlpha(alpha)

    local w2 = w/2
    surface_SetDrawColor(col1)
    surface_DrawRect(0, 0, w2 + 1, h)

    draw_LinearGradient(x + w2, y, w2 + 1, h, preset1)
    draw_LinearGradient(x + 1, y + 1, w - 2, h - 1, preset2)

    surface_SetDrawColor(color_white)
    surface_SetMaterial(self["Image"] or defaultIcon)
    surface_DrawTexturedRect(14, 15, 64, 64)

    draw_DrawText("#plib.achievement", font, 87, 23, color_white2, TEXT_ALIGN_LEFT)
    draw_DrawText(self["Title"], font, 87, 50, color_white3, TEXT_ALIGN_LEFT)
end

vgui.Register("plib_achievement", PANEL)

local table_IsEmpty = table.IsEmpty
hook_Add("PostRender", "PLib:Achievements", function()
    cam_Start2D()
        for i = 1, #achievementsCreated do
            local pnl = achievementsCreated[i]
            if IsValid(pnl) then
                pnl:PaintManual()
            end
        end
    cam_End2D()
end)