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
    ["Version"] = 1.93,
    ["Developers"] = {
        "_ᐱℕᏩĒŁØҜҜ_#8486",
        "PrikolMen#3372",
        "Retro#1593",
    },
}

function PLib:Precache_G(func)
    if isfunction(func) then
        local name = tostring(func)
        if (self["_G"][name] == nil) then
            self["_G"][name] = func
        end
    end
end

function PLib:Get_G(func)
    return self["_G"][tostring(func)]
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
    ["grey"] = Color(25, 25, 25),
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
    ["76561198199724378"] = true, -- DrDos
    ["76561198884350315"] = true, -- Retro
    ["76561198068100168"] = true, -- Fer
    ["76561198233049188"] = true, -- Клён
    ["76561198323873998"] = true, -- Асыч
    ["76561198147878214"] = true, -- Карп
    ["76561198287965045"] = true, -- лёлик
}   -- <3

function PLib:SideColor()
    return (CLIENT and self["_C"]["cl"] or self["_C"]["sv"])
end

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
            return fl
        end
    elseif not isstring(fl) then
        return false
    end

    return (dir or "")..(fl or "")
end

function PLib:SH(dir, fl, tag)
    local path = self:Path(dir, fl)
    if (path != false) then
        if SERVER then
            include(path)
            AddCSLuaFile(path)
        else
            include(path)
        end
    end
end

function PLib:CL(dir, fl, tag)
    local path = self:Path(dir, fl)
    if (path != false) then
        if SERVER then 
            AddCSLuaFile(path)
        else
            include(path)
        end
    end
end

function PLib:SV(dir, fl, tag)
    if SERVER then
        local path = self:Path(dir, fl)
        if (path != false) then
            include(path)
        end
    end
end

function PLib:Include(dir, fl, tag)
    local fileTag = string_lower(string_Left(fl, 3))

    if SERVER and (fileTag == "sv_") then
        self:SV(dir, fl, tag)
    elseif (fileTag == "cl_") then
        self:CL(dir, fl, tag)
    else
        if SERVER and (fileTag != "sh_") then
            self:Log(tag, "Attention, non sh or cl file has been sent to the client, this can be a significant hole in the server's security,\n if this is not the case, change the filename ", self["_C"]["warn"], fl, self["_C"]["text"]," to ", self["_C"]["dg"],"sh_"..fl, "\n")
        end

        self:SH(dir, fl, tag)
    end

    self:Log(tag, fl, ": ", self["_C"]["g"], "OK")
end

function PLib:Load(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for k, fl in ipairs(files) do
        if string_EndsWith(fl, ".lua") then
            self:Include(dir, fl, tag)
        end
    end

    for k, fol in ipairs(folders) do
        self:Load(dir..fol, tag)
    end
end

function PLib:ListReload()
    local loadList = self["LoadList"] or {}
    if not table_IsEmpty(loadList) then
        for num, tbl in ipairs(loadList) do
            print("\n")
            local dir, tag = tbl[1], tbl[2]
            local preLoad, afterLoad = tbl[3], tbl[4]
            self:Log(tag, "Start loading...")
            if isfunction(preLoad) then
                preLoad(dir, tag)
            end

            if isstring(dir) then
                self:Load(dir, tag)
            end

            if isfunction(afterLoad) then
                afterLoad(dir, tag)
            end

            self:Log(tag, "Loaded!")
        end
    end
end

PLib:SH("plib", "sh_loading_manager.lua")
PLib["Loaded"] = true