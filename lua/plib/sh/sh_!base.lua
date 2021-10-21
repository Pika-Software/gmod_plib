hook.Add("InitPostEntity", "PLib:GameLoaded", function()
    hook.Remove("InitPostEntity", "PLib:GameLoaded")

    timer.Simple(5, function()
        hook.Run("PLib:GameLoaded")
    end)
end)

local cvars_Bool = cvars.Bool
local isstring = isstring
local print = print

function string.isvalid(str)
    return isstring(str) and str != ""
end

local validStr = string["isvalid"]

function PLib.dprint(tag, ...)
    if SERVER or (cvars_Bool('developer') == true) then
        PLib:Log("Debug"..((isstring(tag)) and ("/"..tag) or ""), ...)
    end
end

PLib["Achievements"] = {}
PLib["MatPresets"] = {
    ["Pic"] = "noclamp smooth",
}

PLib["SWAK"] = CreateConVar("plib_swak", "", {FCVAR_ARCHIVE, FCVAR_LUA_CLIENT, FCVAR_LUA_SERVER}, "PLib: Steam web api key - need to get user info"):GetString()
cvars.AddChangeCallback("plib_swak", function(name, old, new)
    PLib["SWAK"] = new
end, "PLib")

hook.Add("PLib:GameLoaded", "PLib:GlueLib", function()
    hook.Remove("PLib:GameLoaded", "PLib:GlueLib")

    if istable(glue) and (glue["Version"] != nil) then
        PLib["glue"] = glue
        PLib:Log(nil, "Hi Glue Library v"..glue["Version"].."!")
        PLib:Log("Glue", "Hello, PLib v"..PLib["Version"]..".")
    end
end)

PLib["DoorClasses"] = {
    ["func_door"] = true,
    ["func_door_rotating"] = true,
    ["prop_door_rotating"] = true,
    ["func_movelinear"] = true,
}

PLib["MapCleaning"] = false
hook.Add("PreCleanupMap", "PLib:PreCleanup", function() PLib["MapCleaning"] = true; end)
hook.Add("PostCleanupMap", "PLib:AfterCleanup", function() PLib["MapCleaning"] = false; end)

local concommand_GetTable = concommand.GetTable
local string_StartWith = string.StartWith
local table_insert = table.insert
local pairs = pairs

function PLib:Commands()
    local commands = {}
    for key, _ in pairs(concommand_GetTable()) do
        if (string_StartWith(key, "plib_") == true) then
            table_insert(commands, key)
        end
    end

    return commands
end

function PLib:NumTableToList(tbl)
    local str = ""
    for i = 1, #tbl do
        str = str..tbl[i]..((i < #tbl) and ", " or "")     
    end

    return str
end

concommand.Add("plib_info", function(ply)
    local cols = PLib["_C"]
    local sCol = PLib:SideColor()

    PLib:Log("Info", PLib:Translate("plib.title"), "\n",
    sCol, "["..PLib:Translate("plib.version").."] ", cols["print"], PLib["Version"], "\n",
    sCol, "["..PLib:Translate("plib.creators").."] ", cols["text"], "PrikolMen:-b, Rerto, Angel\n",
    sCol, "["..PLib:Translate("plib.ugg").."] ", cols["text"], (ply:IsGoodGuy() and "Yes" or "No"), "\n",
    sCol, "["..PLib:Translate("plib.commands").."] ", cols["text"], PLib:NumTableToList(PLib:Commands()))
end, nil, "Info command!", {FCVAR_LUA_CLIENT, FCVAR_LUA_SERVER})