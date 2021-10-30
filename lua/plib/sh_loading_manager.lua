-- Loading Manager by PrikolMen#3372
local string_EndsWith = string.EndsWith
local string_lower = string.lower
local string_Left = string.Left
local file_Find = file.Find
local ipairs = ipairs

function PLib:VGUILoad(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for _, fl in ipairs(files) do
        if string_EndsWith(fl, ".lua") then
            local path = self:Path(dir, fl)
            if (path != false) then
                self:Log(tag, "VGUI Include: ", self["_C"]["cl"], string.sub(fl, 0, #fl - 4))

                if SERVER then 
                    AddCSLuaFile(path)
                else
                    include(path)
                end
            end
        end
    end

    for _, fol in ipairs(folders) do
        self:VGUILoad(dir .. fol, tag)
    end 
end

function PLib:ClientLoad(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for _, fl in ipairs(files) do
        if string_EndsWith(fl, ".lua") then
            self:CL(dir, fl, tag)
        end
    end

    for _, fol in ipairs(folders) do
        if (fol == "vgui") then return end
        self:ClientLoad(dir..fol, tag)
    end
end

function PLib:SharedLoad(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for _, fl in ipairs(files) do
        if string_EndsWith(fl, ".lua") then
            self:SH(dir, fl, tag)
        end
    end

    for _, fol in ipairs(folders) do
        self:SharedLoad(dir .. fol, tag)
    end 
end

function PLib:ServerLoad(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for _, fl in ipairs(files) do
        if string_EndsWith(fl, ".lua") then
            self:SV(dir, fl, tag)
        end
    end

    for _, fol in ipairs(folders) do
        self:ServerLoad(dir .. fol, tag)
    end 
end

local moduleConfig = "/_plib_module.lua"
local file_Exists = file.Exists
function PLib:LoadModules(dir, moduleName)
    local files, folders = file_Find(dir.."/*", "LUA")

    local moduleFile, moduleTbl = dir.."/"..self["ModulesConfigName"]
    if file_Exists(moduleFile, "LUA") then
        if SERVER then
            AddCSLuaFile(moduleFile)
        end

        moduleTbl = include(moduleFile)
        if (moduleTbl == nil) then
            MsgC(self["_C"]["module"], "[Pika Software] ", self["_C"]["warn"], "Сritical error", self["_C"]["text"], ", your ", self["_C"]["sv"], "Garry's mod", self["_C"]["text"]," does not load files correctly, try restarting the game.\n")
            return
        end

        local init = moduleTbl["Init"]
        if (init != nil) then
            init(self, dir)
        end

        if (moduleTbl["DisableAutoload"] == true) then
            return 
        end
    end

    dir = dir .. "/"

    for _, fl in ipairs(files) do
        if string_EndsWith(fl, ".lua") and (fl != self["ModulesConfigName"]) then
            self:Include(dir, fl, moduleName)
        end
    end

    for _, fol in ipairs(folders) do
        self:LoadModules(dir..fol, ((moduleName != nil) and moduleName or fol))
        if (moduleName == nil) and not file_Exists(dir..fol.."/"..self["ModulesConfigName"], "LUA") then
            self:Log(nil, "Module Loaded: ", self["_C"]["module"], fol)
        end
    end

    if (moduleTbl != nil) then
        local name = moduleTbl["Name"]
        if (name != nil) then
            self:Log(nil, "Module Loaded: ", self["_C"]["module"], name)
        end

        local postload = moduleTbl["PostLoad"]
        if (postload != nil) then
            postload(self, dir)
        end
    end
end

PLib:SharedLoad("plib/sh")
PLib:ServerLoad("plib/sv")
PLib:ClientLoad("plib/cl")
PLib:VGUILoad("plib/cl/vgui")
PLib:LoadModules("plib/modules")