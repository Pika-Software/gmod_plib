local system_HasFocus = system.HasFocus
local cam_Start2D = cam.Start2D
local cam_End2D = cam.End2D

local waitTime = CreateClientConVar("plib_waittime", "300", true, false, "Need time to show standby screen", 0, 18000):GetInt()
cvars.AddChangeCallback("plib_waittime", function(_, _, new)
    waitTime = tonumber(new)
end, "PLib")

function PLib:AddStandbyScreen(ply)
    local screenFade = false
    hook.Add("RenderScene", "PLib:StandbyScreen", function()
        if not system_HasFocus() or ((waitTime != 0) and (CurTime() - ply["LastActivity"]) > waitTime) then         
            if (screenFade == false) then
                screenFade = true
            end

            if (self["StandbyScreen"] != nil) then
                cam_Start2D()
                    self:StandbyScreen()
                cam_End2D()
            end

            return true
        elseif (screenFade == true) then
            ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 3, 0)
            screenFade = false
        end
    end)
end

hook.Add("PLib:PlayerInitialized", "PLib:StandbyScreen", function(ply)
    hook.Remove("PLib:PlayerInitialized", "PLib:StandbyScreen")
    PLib:AddStandbyScreen(ply)
end)

if (PLib["Loaded"] == true) then
    PLib:AddStandbyScreen(LocalPlayer())
end