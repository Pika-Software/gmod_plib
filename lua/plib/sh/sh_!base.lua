-- string_meta by KlΞn_list 🎀 ~ >,.,<#0710
local tostring = tostring
local isstring = isstring

local string_meta = debug.getmetatable("String")
string_meta["__add"] = function(left, right)
    if (left == nil) then error("attempt to concatenate nil value (left)") end
    if (right == nil) then error("attempt to concatenate nil value (right)") end
    return tostring(left) .. tostring(right)
end

string_meta["__mul"] = function(left, right)
    if isnumber(left) then return right:rep(left) end
    if isnumber(right) then return left:rep(right) end
    error("can't multiply string by non-number (" .. type(left) .. " * " .. type(right) .. ")")
end

string_meta["__sub"] = function(left, right)
    if isnumber(left) then return right:sub(1 + left) end
    if isnumber(right) then return left:sub(1, left:len() - right) end
    error("can't subtraction string by non-number (" .. type(left) .. " - " .. type(right) .. ")")
end

hook.Add("InitPostEntity", "PLib:GameLoaded", function()
    hook.Remove("InitPostEntity", "PLib:GameLoaded")

    timer.Simple(5, function()
        hook.Run("PLib:GameLoaded")
    end)
end)

local cvars_Bool = cvars.Bool
local print = print

function string.isvalid(str)
    return isstring(str) and str != ""
end

local validStr = string["isvalid"]

function PLib.dprint(tag, ...)
    if SERVER or PLib["Debug"] then
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
hook.Add("PreCleanupMap", "PLib:PreCleanup", function() PLib["MapCleaning"] = true end)
hook.Add("PostCleanupMap", "PLib:AfterCleanup", function() PLib["MapCleaning"] = false end)

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

-- GMA Builder by Retro#1593
local function WriteLongLong(f, x)
    f:WriteLong(x)
    f:WriteLong(0)
end

local function WriteULongLong(f, x)
    f:WriteULong(x)
    f:WriteULong(0)
end

local function WriteString(f, str)
    f:Write(str)
    f:WriteByte(0)
end

local util_Buffer = util.Buffer
function PLib:buildGMA(f, path, data)
    local size = #data
    local buffer = util_Buffer()

    buffer:Write('GMAD')
    buffer:WriteByte(3)
    buffer:WriteULongLong(0)
    buffer:WriteULongLong(os.time())
    buffer:WriteByte(0)
    buffer:WriteString('File Packer')
    buffer:WriteString('By Retro')
    buffer:WriteString('Author Name')
    buffer:WriteLong(1)

    -- Writing list
    buffer:WriteULong(1)
    buffer:WriteString(path)
    buffer:WriteLongLong(size)
    buffer:WriteULong(0)
    buffer:WriteULong(0) -- end of list

    -- Writing file
    buffer:Write(data)
    buffer:WriteULong(0)
    return buffer
end

local file_Write = file.Write
function PLib:generateGMA(name, path, data)
    if not validStr(name) or not validStr(path) or not validStr(data) then return end

    ok, err = pcall(self:buildGMA(), f, path, data)

    if ok then
        err:Start()
        file_Write(name, err:Read(err:GetSize()))
    end

    return ok, err
end

function PLib:Info(ply)
    local txtCol = self["_C"]["text"]
    local sCol = self:SideColor()

    self:Log(self:Translate("plib.name"), self:Translate("plib.title"), "\n",
    sCol, "["..self:Translate("plib.version").."] ", self["_C"]["print"], self["Version"], "\n",
    sCol, "["..self:Translate("plib.creators").."] ", txtCol, table.concat(self["Developers"], ", ") .. "\n",
    sCol, "["..self:Translate("plib.commands").."] ", txtCol, self:NumTableToList(self:Commands()), "\n",
    sCol, "["..self:Translate("plib.difficulty").."] ", txtCol, self:Translate(select(2, self:GameDifficulty())), "\n",
    sCol, "["..self:Translate("plib.ugg").."] ", txtCol, self:Translate(ply:IsGoodGuy() and "plib.yes" or "plib.no"))
end

concommand.Add("plib_info", function(ply)
    PLib:Info(ply)
end, nil, "Info command!", {FCVAR_LUA_CLIENT, FCVAR_LUA_SERVER})

concommand.Add("plib_modules", function()
    PLib:Log(nil, "Modules: ", table.ToString(PLib["Modules"], nil, true))
end)