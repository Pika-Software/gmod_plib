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

local file_Exists = file.Exists
local isstring = isstring

local initNames = {"init", "initialize", "autorun", "load", "preload", "start"}
local postinitNames = {"post", "postinit", "afterinit", "after", "postload", "afterload", "end"}
local userloaderNames = {"useloader", "autoload", "loader"}
local titleNames = {"title", "text", "name"}
local versionNames = {"version", "ver", "v"}

local pairs = pairs

function PLib:GetModuleInfo(info, folder)
    local tbl = {
        ["name"] = folder,
        ["version"] = 0,
    }

    -- Value Seacher 3000 :>
    for key, value in pairs(info) do
        for _, tag in ipairs(titleNames) do
            if isstring(key) and (key:lower() == tag) then
                tbl["name"] = value
            end
        end

        for _, tag in ipairs(versionNames) do
            if isstring(key) and (key:lower() == tag) then
                tbl["version"] = value
            end
        end

        for _, tag in ipairs(userloaderNames) do
            if isstring(key) and (key:lower() == tag) then
                tbl["useloader"] = value
            end
        end

        for _, tag in ipairs(initNames) do
            if isstring(key) and (key:lower() == tag) then
                tbl["init"] = value
            end
        end

        for _, tag in ipairs(postinitNames) do
            if isstring(key) and (key:lower() == tag) then
                tbl["postinit"] = value
            end
        end
    end

    return tbl
end

function PLib:LoadModule(modulesDir, folder, modules, id)
    local path = modulesDir .. folder
    local moduleConfig = path .. "/" .. self["ModulesConfigName"]
    if file_Exists(moduleConfig, "LUA") then
        AddCSLuaFile(moduleConfig)
        local ok, info = SafeInclude(moduleConfig)
        if ok then
            if not istable(info) then
                self:Log(nil, "Module ", self["_C"]["warn"], folder, self["_C"]["text"], " lost the load table, please report this to the creator of the module or try restart game.")
                return
            end

            local moduleData = self:GetModuleInfo(info, folder)

            -- Too many call's
            local name = moduleData["name"]
            local version = moduleData["version"]

            for num, folder in ipairs(modules) do
                if (num == id) then continue end

                local path = modulesDir .. folder
                local moduleConfig = path .. "/" .. self["ModulesConfigName"]

                if file_Exists(moduleConfig, "LUA") then
                    local ok, info = SafeInclude(moduleConfig)
                    if ok and istable(info) then
                        local tbl = self:GetModuleInfo(info, folder)
                        if (tbl["name"] == name) and (tbl["version"] > version) then
                            self:Log(name .. " v" .. version, "Module loading canceled, reason: ", self["_C"]["warn"], "new version module detected.")
                            return
                        end
                    end
                end
            end

            local init, useloader = moduleData["init"], moduleData["useloader"]
            if isfunction(init) then
                init(self, info, modules)

                if (useloader == true) then
                    self:Load(path, name)
                end
            elseif (useloader != false) then
                self:Load(path, name)
            end

            local postinit = moduleData["postinit"]
            if isfunction(postinit) then
                postinit(self, info, modules)
            end

            self:Log(nil, "Module Loaded: ", self["_C"]["module"], name)
        else
            self:Log(folder, "Error in ", self["_C"]["warn"], moduleConfig, self["_C"]["text"], "!\n", self["_C"]["warn"], info)
        end
    else
        self:Load(path, folder)
    end
end

function PLib:LoadModules(path)
    local modulesDir = path.."/"
    local _, modules = file_Find(modulesDir.."*", "LUA")

    for num, folder in ipairs(modules) do
        self:LoadModule(modulesDir, folder, modules, num)
    end
end

-- function PLib:LoadModules(dir, moduleName)
--     local files, folders = file_Find(dir.."/*", "LUA")

--     local moduleFile, moduleTbl = dir.."/"..self["ModulesConfigName"]
--     if file_Exists(moduleFile, "LUA") then
--         if SERVER then
--             AddCSLuaFile(moduleFile)
--         end

--         moduleTbl = include(moduleFile)
--         if (moduleTbl == nil) then
--             MsgC(self["_C"]["module"], "[Pika Software] ", self["_C"]["warn"], "Сritical error", self["_C"]["text"], ", your ", self["_C"]["sv"], "Garry's mod", self["_C"]["text"]," does not load files correctly, try restarting the game.\n")
--             return
--         end

--         local init = moduleTbl["Init"]
--         if (init != nil) then
--             init(self, dir)
--         end

--         if (moduleTbl["DisableAutoload"] == true) then
--             return 
--         end
--     end

--     dir = dir .. "/"

--     for _, fl in ipairs(files) do
--         if string_EndsWith(fl, ".lua") and (fl != self["ModulesConfigName"]) then
--             self:Include(dir, fl, moduleName)
--         end
--     end

--     for _, fol in ipairs(folders) do
--         self:LoadModules(dir..fol, ((moduleName != nil) and moduleName or fol))
--         if (moduleName == nil) and not file_Exists(dir..fol.."/"..self["ModulesConfigName"], "LUA") then
--             self:Log(nil, "Module Loaded: ", self["_C"]["module"], fol)
--         end
--     end

--     if (moduleTbl != nil) then
--         local name = moduleTbl["Name"]
--         if (name != nil) then
--             self:Log(nil, "Module Loaded: ", self["_C"]["module"], name)
--         end

--         local postload = moduleTbl["PostLoad"]
--         if (postload != nil) then
--             postload(self, dir)
--         end
--     end
-- end

PLib:SharedLoad("plib/sh")
PLib:ServerLoad("plib/sv")
PLib:ClientLoad("plib/cl")
PLib:VGUILoad("plib/cl/vgui")
PLib:LoadModules("plib/modules")