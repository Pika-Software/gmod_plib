-- Loading Manager by PrikolMen#3372
local string_EndsWith = string.EndsWith
local string_lower = string.lower
local string_Left = string.Left
local file_Find = file.Find
local ipairs = ipairs

function PLib:VGUILoad(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for i = 1, #files do
        local fl = files[i]
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

    for i = 1, #folders do
        self:VGUILoad(dir..folders[i], tag)
    end 
end

function PLib:ClientLoad(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for i = 1, #files do
        local fl = files[i]
        if string_EndsWith(fl, ".lua") then
            self:CL(dir, fl, tag)
        end
    end

    for i = 1, #folders do
        local fol = folders[i]
        if (fol == "vgui") then return end
        self:ClientLoad(dir..fol, tag)
    end
end

function PLib:SharedLoad(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for i = 1, #files do
        local fl = files[i]
        if string_EndsWith(fl, ".lua") then
            self:SH(dir, fl, tag)
        end
    end

    for i = 1, #folders do
        self:SharedLoad(dir..folders[i], tag)
    end
end

function PLib:ServerLoad(dir, tag)
    dir = dir .. "/"
    local files, folders = file_Find(dir.."*", "LUA")

    for i = 1, #files do
        local fl = files[i]
        if string_EndsWith(fl, ".lua") then
            self:SV(dir, fl, tag)
        end
    end

    for i = 1, #folders do
        self:ServerLoad(dir..folders[i], tag)
    end
end

function PLib:IncludeModule(dir, fl, moduleName)
    local fileTag = string_lower(string_Left(fl, 3))

    local ok, err = pcall(function()
        if SERVER and (fileTag == "sv_") then
            self:SV(dir, fl, tag)
        elseif (fileTag == "cl_") then
            self:CL(dir, fl, tag)
        else
            if SERVER and (fileTag != "sh_") and (fl != "_plib_module.lua") then
                self:Log(tag, "Attention, non sh or cl file has been sent to the client, this can be a significant hole in the server's security,\n if this is not the case, change the filename ", self["_C"]["warn"], fl, self["_C"]["text"]," to ", self["_C"]["dg"],"sh_"..fl, "\n")
            end

            self:SH(dir, fl, tag)
        end
    end)

    if (ok == true) then
        -- self:Log(moduleName, fl, ": ", self["_C"]["g"], "OK")

        return true
    else
        self:Log(moduleName, fl, ": ", self["_C"]["warn"], "Error! ("..err..")")

        return false
    end
end

local moduleConfig = "/_plib_module.lua"
local file_Exists = file.Exists
function PLib:LoadModules(dir, moduleName)
    local files, folders = file_Find(dir.."/*", "LUA")

    local module
    local moduleFile = dir..moduleConfig
    if file_Exists(moduleFile, "LUA") then
        if SERVER then
            AddCSLuaFile(moduleFile)
        end

        module = include(moduleFile)

        local init = module["Init"]
        if (init != nil) then
            init(self, dir)
        end

        if (module["DisableAutoload"] == true) then
            return 
        end
    end
    
    dir = dir .. "/"

    local hasError = false
    for i = 1, #files do
        local fl = files[i]
        if string_EndsWith(fl, ".lua") then
            if (self:IncludeModule(dir, fl, moduleName) == false) then
                hasError = true
            end
        end
    end

    local hasErrors = false
    for i = 1, #folders do
        local fol = folders[i]
        hasErrors = self:LoadModules(dir..fol, ((moduleName != nil) and moduleName or fol))
        if (moduleName == nil) and not file_Exists(dir..fol..moduleConfig, "LUA") then
            self:Log(nil, "Module Loaded: ", ((hasErrors == false) and self["_C"]["module"] or self["_C"]["warn"]), fol)
        end
    end

    if (module != nil) then
        local name = module["Name"]
        if (name != nil) then
            self:Log(nil, "Module Loaded: ", ((hasErrors == false) and self["_C"]["module"] or self["_C"]["warn"]), name)
        end

        local postload = module["PostLoad"]
        if (postload != nil) then
            postload(self, dir)
        end
    end

    return hasError
end

PLib:SharedLoad("plib/sh")
PLib:ServerLoad("plib/sv")
PLib:ClientLoad("plib/cl")
PLib:VGUILoad("plib/cl/vgui")
PLib:LoadModules("plib/modules")