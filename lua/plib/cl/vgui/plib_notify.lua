PLib["Notifications"] = PLib["Notifications"] or {}

local function ScreenInit()

end

hook.Add("OnScreenSizeChanged", "PLib:Notify", ScreenInit)
ScreenInit()

local PANEL = {}
function PANEL:Setup(title, text, color, time)

end

function PANEL:Init()
    self:Setup()
end

function PANEL:PerformLayout()

end

function PANEL:Paint(w, h)

end

vgui.Register("plib_notify", PANEL)

function PLib:AddNotify(title, text)
    local notify = vgui.Create("plib_notify")
    notify:Setup(title, text)
end

-- PLib:AddNotify(title, text)