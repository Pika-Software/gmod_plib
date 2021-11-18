-- PLib Core by PrikolMen#3372
local string_EndsWith = string.EndsWith
local table_IsEmpty = table.IsEmpty
local AddCSLuaFile = AddCSLuaFile
local string_lower = string.lower
local string_Left = string.Left
local isfunction = isfunction
local file_Find = file.Find
local tostring = tostring
local isstring = isstring
local include = include
local ipairs = ipairs
local Color = Color
local MsgC = MsgC

PLib = PLib or {
    ["_G"] = {},
    ["Version"] = 3.34,
    ["Developers"] = {
        "KlΞn_list 🎀 ~ >,.,<#0710",
        "_ᐱℕᏩĒŁØҜҜ_#8486",
        "PrikolMen#3372",
        "DefaultOS#5913",
        "Retro#1593",
    },
    ["ModuleInitName"] = "_plib_module.lua",
}

function PLib:Precache_G(name, func)
    if (self["_G"][name] == nil) then
        self["_G"][name] = func

        if (self["dprint"] != nil) then
            self["dprint"]("_G", "_G Precached -> ", name)
        end
    end
end

function PLib:Get_G(name)
    return self["_G"][name]
end

PLib["_C"] = {
    ["cl"] = Color(255, 193, 7),
    ["sv"] = Color(40, 192, 252),
    ["text"] = Color(250, 238, 255),
    ["warn"] = Color(202, 50, 50),
    ["dy"] = Color(238, 225, 113),
    ["dg"] = Color(83, 138, 32),
    ["g"] = Color(93,174,117),
    ["print"] = Color(160, 236, 255),
    ["logo"] = Color(220, 220, 225, 250),
    ["gmod_white"] = Color(230, 230, 230),
    ["achievement"] = Color(255, 200, 0),
    ["module"] = Color(179, 138, 255),
    ["grey"] = Color(50, 50, 50),
    ["dgrey"] = Color(25, 25, 25),
}

PLib["GoodGuys"] = {
    ["76561198010188273"] = true, -- TheFizzyJuice
    ["76561198100459279"] = true, -- PrikolMen:-b
    ["76561198189022357"] = true, -- nullcalv1n
    ["76561198163261508"] = true, -- DefaultOS
    ["76561198032071176"] = true, -- Swanchick
    ["76561198049442792"] = true, -- Komi-sar
    ["76561198377497545"] = true, -- Kactus
    ["76561198256780625"] = true, -- Angel
    ["76561198884350315"] = true, -- Retro
    ["76561198068100168"] = true, -- Fer
    ["76561198233049188"] = true, -- Клён
    ["76561198323873998"] = true, -- Асыч
    ["76561198147878214"] = true, -- Карп
}   -- <3

-- SafeInclude by Retro#1593
function SafeInclude(fileName)
    assert(type(fileName) == "string", "bad argument #1 (string expected)")

    local errorHandler = debug.getregistry()[1]
    local lastError
    debug.getregistry()[1] = function(err)
        lastError = err
        return err
    end

    local args = { include(fileName) }
    debug.getregistry()[1] = errorHandler

    if lastError then
        return false, lastError
    else
        return true, unpack(args)
    end
end

function PLib:SideColor()
    return (CLIENT and self["_C"]["cl"] or self["_C"]["sv"])
end

PLib["Debug"] = cvars.Bool("developer") or false
cvars.AddChangeCallback("developer", function(cvar, old, new)
    PLib["Debug"] = tobool(new)
    hook.Run("PLib:Debug", PLib["Debug"])
end, "PLib")

function PLib:Log(tag, ...)
    MsgC(self:SideColor(), "["..(tag or "PLib").."] ", self["_C"]["text"], ...)
    Msg("\n")
end

function PLib:Path(dir, fl)
    if isstring(dir) then
        if isstring(fl) then
            if not string_EndsWith(dir, "/") then
                dir = dir .. "/"
            end
        else
            return false
        end
    elseif not isstring(fl) then
        return false
    end

    return (dir or "")..(fl or "")
end

function PLib:CL(dir, fl)
    local path = self:Path(dir, fl)
    assert(path, "Invalid path returned")

    if SERVER then
        AddCSLuaFile(path)
    else
        return SafeInclude(path)
    end
end

function PLib:SV(dir, fl)
    if CLIENT then return end

    local path = self:Path(dir, fl)
    assert(path, "Invalid path returned")

    return SafeInclude(path)
end

function PLib:SH(dir, fl)
    local path = self:Path(dir, fl)
    assert(path, "Invalid path returned")

    if SERVER then
        AddCSLuaFile(path)
    end

    return SafeInclude(path)
end

function PLib:Include(dir, fl, tag)
    local fileTag, ok, err = string_lower(string_Left(fl, 3))
    if (fileTag == "sv_") then
        ok, err = self:SV(dir, fl)
    elseif (fileTag == "cl_") then
        ok, err = self:CL(dir, fl)
    else
        if SERVER and (fileTag != "sh_") then
            self:Log(tag, "Attention, non sh or cl file has been sent to the client, this can be a significant hole in the server's security,\n if this is not the case, change the filename ", self["_C"]["warn"], fl, self["_C"]["text"]," to ", self["_C"]["dg"],"sh_"..fl, "\n")
        end

        ok, err = self:SH(dir, fl)
    end

    if (ok == true) then
        if self["Debug"] then
            self:Log(tag, fl, ": ", self["_C"]["g"], "OK")
        end
    elseif (ok == false) then
        self:Log(tag, fl, ": ", self["_C"]["warn"], err or "Initialization error!")
    end
end

function PLib:Load(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for _, fl in ipairs(files) do
        if string_EndsWith(fl, ".lua") and (fl != self["ModuleInitName"]) then
            self:Include(dir, fl, tag)
        end
    end

    for _, fol in ipairs(folders) do
        if (fol == "vgui") then continue end
        self:Load(dir .. fol, tag)
    end
end

PLib:SH("plib", "sh_loading_manager.lua")
PLib["Loaded"] = true
hook.Run("PLib:Loaded")
