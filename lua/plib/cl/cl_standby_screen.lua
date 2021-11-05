local system_HasFocus = system.HasFocus
local cam_Start2D = cam.Start2D
local cam_End2D = cam.End2D

local waitTime = CreateClientConVar("plib_waittime", "300", true, false, "Need time to show standby screen", 0, 18000):GetInt()
cvars.AddChangeCallback("plib_waittime", function(_, _, new)
    waitTime = tonumber(new)
end, "PLib")

local function StartPlayerWaiting()
    if input.IsKeyTrapping() then return end
    input.StartKeyTrapping()

    hook.Add("Think", "PLib:StandbyScreen", function()
        if input.IsKeyTrapping() then
            if isnumber(input.CheckKeyTrapping()) then
                hook.Remove("Think", "PLib:StandbyScreen")
                LocalPlayer()["LastActivity"] = CurTime()
            end
        else
            hook.Remove("Think", "PLib:StandbyScreen")
        end
    end)
end

function PLib:AddStandbyScreen(ply)
    local screenFade = false
    hook.Add("RenderScene", "PLib:StandbyScreen", function()
        local waitTime = ((waitTime != 0) and (CurTime() - ply["LastActivity"]) > waitTime)
        if not system_HasFocus() or waitTime then         
            if (screenFade == false) then
                screenFade = true
            end
            
            if waitTime then
                StartPlayerWaiting()
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