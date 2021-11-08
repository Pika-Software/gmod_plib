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
    "CompileRequiredCheck"), name
end

function PLib:LoadModules(path)
    local modulesDir = path .. "/"
    local _, modules = file_Find(modulesDir.."*", "LUA")

    self["Modules"] = {}

    for id, folder in ipairs(modules) do
        local path = modulesDir .. folder
        local moduleConfig = path .. "/" .. self["ModuleInitName"]

        if file_Exists(moduleConfig, "LUA") then
            if SERVER then
                AddCSLuaFile(moduleConfig)
            end

            local ok, info = SafeInclude(moduleConfig)
            if ok then
                if not istable(info) then
                    self:Log(nil, "Module ", self["_C"]["warn"], folder, self["_C"]["text"], " lost the load table, please report this to the creator of the module or try restart game.")
                    return
                end

                local priority = #self["Modules"]
                local moduleData = self:GetModuleInfo(info, folder)

                local name = moduleData["name"]
                local version = moduleData["version"]
                local required = moduleData["required"]

                local required_list, required_count = {}, 0
                for num, str in ipairs(required) do
                    local func, name = BuildRequiredCheck(str)
                    required_list[name] = func
                    required_count = required_count + 1
                end

                for num, folder in ipairs(modules) do
                    if (num == id) then continue end

                    local path = modulesDir .. folder
                    local moduleConfig = path .. "/" .. self["ModuleInitName"]

                    if file_Exists(moduleConfig, "LUA") then
                        local ok, info = SafeInclude(moduleConfig)
                        if ok and istable(info) then
                            local tbl = self:GetModuleInfo(info, folder)
                            local mName, mVer = tbl["name"], tbl["version"]
                            if (mName == name) and (mVer > version) then
                                self:Log(name .. " v" .. version, "Module loading canceled, reason: ", self["_C"]["warn"], "New version detected.")
                                return
                            end

                            for rName, func in pairs(required_list) do
                                if (rName == mName) and func(mVer) then
                                    required_count = required_count - 1
                                end
                            end
                        end
                    end
                end

                if (required_count > 0) then
                    self:Log(name .. " v" .. version, "Module loading canceled, reason: ", self["_C"]["warn"], "Required modules missing.")
                    self:Log(name .. " v" .. version, "Required: ", table.ToString(required, nil, true))
                    return
                end

                local loadTable = {
                    ["name"] = name,
                    ["path"] = path,
                    ["required"] = required or {
                        ["PLib_Core"] = (">= 1.0, <="..self["Version"]),
                    },
                    ["version"] = version,
                    ["description"] = moduleData["description"] or {
                        ["summary"] = "",
                        ["detailed"] = "",
                        ["homepage"] = "",
                        ["license"] = "",
                    },
                    ["source"] = moduleData["source"] or {
                        ["url"] = "",
                        ["tag"] = "",
                    },
                }

                local init = moduleData["init"]
                local useloader = moduleData["useloader"]

                if isfunction(init) then
                    loadTable["init"] = init
                    loadTable["useloader"] = (useloader == true)
                else
                    loadTable["useloader"] = (useloader != false)
                end

                local postInit = moduleData["postInit"]
                if isfunction(postInit) then
                    loadTable["postInit"] = postInit
                end

                table.insert(self["Modules"], loadTable)
            else
                self:Log(folder, "Error in ", self["_C"]["warn"], moduleConfig, self["_C"]["text"], "!\n", self["_C"]["warn"], info)
            end
        else
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