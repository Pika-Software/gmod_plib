local hook_Run = hook.Run
local hook_Add = hook.Add
local assert = assert
local type = type

-- Player Buttons by PrikolMen#3372
local PLAYER = FindMetaTable("Player")

PLAYER["PLib.Buttons"] = {}
function PLAYER:GetButton(key)
    assert(type(key) == "number", "bad argument #1 (number expected)")
    return self["PLib.Buttons"][key] or false
end

function PLAYER:SetButton(key, bool)
    assert(type(key) == "number", "bad argument #1 (number expected)")
    assert(type(bool) == "boolean", "bad argument #2 (boolean expected)")

    self["PLib.Buttons"][key] = bool
    hook_Run("PlayerButtonToggle", self, key, bool)
end

hook_Add("PlayerButtonDown", "PLib.Buttons", function(ply, key)
    ply:SetButton(key, true)
end)

hook_Add("PlayerButtonUp", "PLib.Buttons", function(ply, key)
    ply:SetButton(key, false)
end)

--[[-------------------------------------------------------------------------
	Example
-----------------------------------------------------------------------------

if CLIENT then
    hook.Add("PlayerButtonToggle", "sadasd", function(ply, key, bool)
        print(ply, input.GetKeyName(key), bool)
    end)
end

---------------------------------------------------------------------------]]