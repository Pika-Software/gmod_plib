local input_IsButtonDown = CLIENT and input.IsButtonDown
local input_IsMouseDown = CLIENT and input.IsMouseDown
local hook_Run = hook.Run
local hook_Add = hook.Add
local assert = assert
local type = type

-- Player Buttons by PrikolMen#3372
local PLAYER = FindMetaTable("Player")
function PLAYER:GetButton(key)
    assert(type(key) == "number", "bad argument #1 (number expected)")
    if CLIENT then
        return (key > 106) and input_IsMouseDown(key) or input_IsButtonDown(key)
    end

    return self["PLib.Buttons"][key] or false
end

if SERVER then
    PLAYER["PLib.Buttons"] = {}
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
end

--[[-------------------------------------------------------------------------
	Example
-----------------------------------------------------------------------------

if CLIENT then
    hook.Add("PlayerButtonToggle", "Example", function(ply, key, bool)
        print(ply, input.GetKeyName(key), bool)
    end)
end

---------------------------------------------------------------------------]]