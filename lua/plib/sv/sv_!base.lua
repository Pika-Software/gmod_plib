local ents_FindByClass = ents.FindByClass
local isURL = string["isURL"]
local IsValid = IsValid

CreateConVar("plib_debug_allow", "1", {FCVAR_LUA_SERVER, FCVAR_ARCHIVE}, "Allow the display of debugging information and the use of debugging commands for clients")

function PLib:AreaPortalFix(ent)
    if (self["MapCleaning"] == false) and IsValid(ent) and self["DoorClasses"][ent:GetClass()] then
        local name = ent:GetName()
        if (name != "") then
            local portals = ents_FindByClass("func_areaportal")
            for i = 1, #portals do
                local portal = portals[i]
                if (portal:GetInternalVariable("target") == name) then
                    portal:SetSaveValue("target", "")
                    portal:Fire("Open")
                end
            end
        end
    end
end

hook.Add("EntityRemoved", "PLib.AreaPortalFix", function(ent)
    PLib:AreaPortalFix(ent)
end)

function PLib:ServerLogoUpdate(url)
    if isURL(url) then
        hook.Add("PLib:PlayerInitialized", "PLib:Logo", function(ply)
            net.Start("PLib")
                net.WriteUInt(3, 3)
                net.WriteString(url)
            net.Send(ply)
        end)
    else
        hook.Remove("PLib:PlayerInitialized", "PLib:Logo")
        self:Log(nil, "#plib.invalid_logo_url")
    end
end

PLib:ServerLogoUpdate(CreateConVar("plib_server_logo", "", {FCVAR_LUA_SERVER, FCVAR_ARCHIVE}, "Server logo url, replaces player logos"):GetString())
cvars.AddChangeCallback("plib_server_logo", function(name, old, new)
    PLib:ServerLogoUpdate(new)
end, "PLib")

-- Getting SWAK
hook.Add("PLib:GameLoaded", "PLib:GlueLib", function()
    hook.Remove("PLib:GameLoaded", "PLib:GlueLib")
    if (PLib["SWAK"] == "") then
        http.Fetch("https://apps.g-mod.su/swak", function(body)
            PLib["SWAK"] = util.Decompress(body)
        end)
    end
end)

concommand.Add("plib_modules_reload", function()
    PLib:LoadModules("plib/modules")
    PLib:Log(nil, "Modules reloaded!")
end)