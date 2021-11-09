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
                if self["Debug"] then
                    self:Log(tag, "VGUI Include: ", self["_C"]["cl"], string.sub(fl, 0, #fl - 4))
                end

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
local descriptionNames = {"description", "info", "desc"}
local needNames = {"dependencies", "need", "required"}
local titleNames = {"title", "text", "name"}
local versionNames = {"version", "ver", "v"}
local sourceNames = {"source", "github"}

local pairs = pairs

function PLib:GetModuleInfo(info, folder)
    local tbl = {
        ["name"] = folder,
        ["version"] = 0,
        ["source"] = {},
        ["required"] = {},
        ["description"] = {},
    }

    -- Value Seacher 3000 :>
    for key, value in pairs(info) do
        for _, tag in ipairs(titleNames) do
            if isstring(key) and (key:lower() == tag) and isstring(value) then
                tbl["name"] = value
            end
        end

        for _, tag in ipairs(versionNames) do
            if isstring(key) and (key:lower() == tag) and isnumber(value) then
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
                tbl["postInit"] = value
            end
        end

        for _, tag in ipairs(descriptionNames) do
            if isstring(key) and (key:lower() == tag) and istable(value) then
                tbl["description"] = value
            end
        end

        for _, tag in ipairs(needNames) do
            if isstring(key) and (key:lower() == tag) and istable(value) then
                tbl["required"] = value
            end
        end

        for _, tag in ipairs(sourceNames) do
            if isstring(key) and (key:lower() == tag) and istable(value) then
                tbl["source"] = value
            end
        end
    end

    return tbl
end

local relationalOperators = {">=", "<=", ">", "<"}
local function BuildRequiredCheck(str)
    local name, operator1, ver1, operator2, ver2

    for _, op in ipairs(relationalOperators) do
        local start = string.find(str, op)
        if (start != nil) then
            name = string.sub(str, 0, start - 1)

            for num, char in ipairs(string.ToTable(name)) do
                if (char == " ") or (char == "  ") then
                    continue
                end

                name = string.sub(name, num, #name)

                break;
            end

            for i = -#name, 0 do
                local num = math.abs(i)
                local char = name[num]
                if (char == " ") or (char == "  ") then
                    continue
                end

                name = string.sub(name, 0, num)

                break;
            end

            operator1 = op

            local opStart = start + #op
            local start2 = string.find(str, ",", opStart)
            if (start2 != nil) then
                ver1 = tonumber(string.Replace(string.sub(str, opStart, start2 - 1), " ", ""))

                for _, op in ipairs(relationalOperators) do
                    local start3 = string.find(str, op, start2 + 1)
                    if (start3 != nil) then
                        local opStart2 = start3 + #op
                        operator2 = string.Replace(string.sub(str, start3, opStart2), " ", "")
                        ver2 = tonumber(string.Replace(string.sub(str, opStart2, #str), " ", ""))
                        break;
                    end
                end
            else
                ver1 = tonumber(string.Replace(string.sub(str, opStart, #str), " ", ""))
            end

            break;
        end
    end

    return CompileString(
        [[
        local args = {...}
        local version = args[1]
        return (version ]]..operator1.." "..ver1.." "..((operator2 != nil) and (" and version "..operator2.." "..ver2) or "")..")",
    "CompileRequiredCheck"), name, str
end

function PLib:ModuleData(dir, folder, isLoad)
    local moduleConfig = (dir .. folder) .. "/" .. self["ModuleInitName"]

    if file_Exists(moduleConfig, "LUA") then
        if SERVER and (isLoad == true) then
            AddCSLuaFile(moduleConfig)
        end

        local ok, info = SafeInclude(moduleConfig)
        if ok and istable(info) then
            if not istable(info) then
                self:Log(nil, "Module ", self["_C"]["warn"], folder, self["_C"]["text"], " lost the load table, please report this to the creator of the module or try restart game.")
                return false
            end

            return self:GetModuleInfo(info, folder)
        else
            self:Log(folder, "Error in ", self["_C"]["warn"], moduleConfig, self["_C"]["text"], "!\n", self["_C"]["warn"], info)
            return false
        end
    end

    return true
end

function PLib:GetModuleLoadTable(path, data)
    local loadTable = {
        ["name"] = data["name"],
        ["path"] = path,
        ["required"] = data["required"] or {
            ["PLib_Core"] = (">= 1.0, <="..self["Version"]),
        },
        ["version"] = data["version"],
        ["description"] = data["description"] or {
            ["summary"] = "",
            ["detailed"] = "",
            ["homepage"] = "",
            ["license"] = "",
        },
        ["source"] = data["source"] or {
            ["url"] = "",
            ["tag"] = "",
        },
    }
    
    local init = data["init"]
    if isfunction(init) then
        loadTable["init"] = init
        loadTable["useloader"] = (data["useloader"] == true)
    else
        loadTable["useloader"] = (data["useloader"] != false)
    end

    local postInit = data["postInit"]
    if isfunction(postInit) then
        loadTable["postInit"] = postInit
    end

    return loadTable
end

function PLib:RequiredModluesAnalize(tbl, func)
    for _, str in ipairs(tbl) do
        func(BuildRequiredCheck(str))
    end
end

function PLib:LoadModules(path)
    local modulesDir = path .. "/"
    local _, modules = file_Find(modulesDir.."*", "LUA")

    self["Modules"] = {}

    for id, folder in ipairs(modules) do
        local data = self:ModuleData(modulesDir, folder, true)
        if istable(data) then
            local name = data["name"]
            local version = data["version"]
            local required = data["required"]

            if (#required != 0) then
                local haveRequired = {}
                for num, folder in ipairs(modules) do
                    if (num == id) then continue end
                    local data = self:ModuleData(modulesDir, folder)
                    if !istable(data) then continue end

                    self:RequiredModluesAnalize(required, function(name, func, str)
                        if (name == data["name"]) and func(data["version"]) then
                            table.insert(haveRequired, str)
                        end
                    end)
                end

                if (#haveRequired < #required) then
                    self:Log(name .. " v" .. version, "Module loading canceled, reason: ", self["_C"]["warn"], "Required modules is missing.")
                    for _, str in ipairs(required) do
                        local have = false
                        for _, str2 in ipairs(haveRequired) do
                            if (str == str2) then
                                have = true
                            end
                        end

                        if not have then
                            self:Log(name .. " v" .. version, "Required: ", self["_C"]["module"], str)
                        end
                    end
                end

                return
            end

            local loadList = {}
            for num, folder in ipairs(modules) do
                if (num == id) then continue end
                local data = self:ModuleData(modulesDir, folder)
                if !istable(data) then continue end

                if (data["name"] == name) and (data["version"] > version) then
                    self:Log(name .. " v" .. version, "Module loading canceled, reason: ", self["_C"]["warn"], "New version detected!")
                    return
                end
                
                self:RequiredModluesAnalize(required, function(reqName, func)
                    if (reqName == name) and func(version) then
                        table.insert(loadList, self:GetModuleLoadTable(modulesDir .. folder, data))
                    end
                end)
            end

            table.insert(self["Modules"], self:GetModuleLoadTable(modulesDir .. folder, data))

            for _, tbl in ipairs(loadList) do
                table.insert(self["Modules"], tbl)
            end

        elseif (data == true) then
            table.insert(self["Modules"], {
                ["name"] = folder,
                ["path"] = path,
                ["version"] = 0,
                ["useloader"] = true,
            })
        end
    end

    for id, tbl in ipairs(self["Modules"]) do
        local name = tbl["name"]
        local version = tbl["version"]

        local init = tbl["init"]
        if (init != nil) then
            init(self, tbl, modules)
        end

        local path = tbl["path"]
        if (tbl["useloader"] == true) then
            self:Load(path, name)
        end

        self:VGUILoad(path .. "/vgui", name)

        local postInit = tbl["postInit"]
        if (postInit != nil) then
            postInit(self, tbl, modules)
        end

        self:Log(nil, "Module Loaded: ", self["_C"]["module"], name)
    end
end

PLib:SharedLoad("plib/sh")
PLib:ServerLoad("plib/sv")
PLib:ClientLoad("plib/cl")
PLib:VGUILoad("plib/cl/vgui")
PLib:LoadModules("plib/modules")