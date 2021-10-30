local util_KeyValuesToTablePreserveOrder = util.KeyValuesToTablePreserveOrder
local cvars_AddChangeCallback = cvars.AddChangeCallback
local net_SendToServer = CLIENT and net.SendToServer
local util_GetModelInfo = util.GetModelInfo
local util_TableToJSON = util.TableToJSON
local util_JSONToTable = util.JSONToTable
local net_WriteString = net.WriteString
local util_Decompress = util.Decompress
local file_CreateDir = file.CreateDir
local util_Compress = util.Compress
local string_format = string.format
local table_IsEmpty = table.IsEmpty
local net_WriteUInt = net.WriteUInt
local validStr = string["isvalid"]
local table_insert = table.insert
local string_lower = string.lower
local file_Exists = file.Exists
local math_random = math.random
local dprint = PLib["dprint"]
local math_Round = math.Round
local math_Clamp = math.Clamp
local file_Write = file.Write
local file_Read = file.Read
local net_Start = net.Start
local istable = istable
local IsValid = IsValid
local tobool = tobool
local Angle = Angle

local player_path = "plib/players"
local function ResetVars(path)
    if not file_Exists(player_path, "DATA") then
        file_CreateDir(player_path)
    end

    file_Write(path, util_Compress("[]"))
end

local function hasDataTable(ply)
    return ply["PLib"]["Data"] != nil
end

local function GetPlayerSavePath(ply)
    local uid
    if ply:IsBot() then
        uid = ply:Nick()
    else
        uid = ply:SteamID64()

        if (uid == nil) then
            if (ply["PLib"]["SteamID64"] != nil) then
                uid = ply["PLib"]["SteamID64"]
            end
        end
    end

    return player_path.."/"..(uid or "NULL")..".dat"
end

local PLAYER = FindMetaTable("Player")

PLAYER["PLib"] = {}

function PLAYER:GetAllData()
    local path = GetPlayerSavePath(self)
    if not file_Exists(path, "DATA") then
        return ResetVars(path)
    end

    return util_JSONToTable(util_Decompress(file_Read(path, "DATA"))), path
end

function PLAYER:GetSavedData(key)
    local data = self:GetAllData()
    return istable(data) and data[key] or nil
end

function PLAYER:ReplaceAllData(data)
    local path = GetPlayerSavePath(self)
    if not file_Exists(path, "DATA") then
        return ResetVars(path)
    end

    file_Write(path, util_Compress(util_TableToJSON(data)))
end

function PLAYER:SaveData(key, value)
    local data, path = self:GetAllData()
    if istable(data) then
        data[key] = value
        file_Write(path, util_Compress(util_TableToJSON(data)))
    else
        ResetVars(path)
    end
end

if SERVER then
    function PLAYER:SyncData()
        self["PLib"]["Data"] = self:GetAllData()
        self["PLib"]["SteamID"] = self:SteamID()
        self["PLib"]["SteamID64"] = self:SteamID64()
        self["PLib"]["Nick"] = self:Nick()
    end
end

function PLAYER:GetData(key)
    if SERVER then
        self["PLib"]["Data"] = self["PLib"]["Data"] or self:SyncData() or {}
        return self["PLib"]["Data"][key]
    else
        return self:GetSavedData(key)
    end
end

function PLAYER:SetData(key, value)
    if SERVER then
        self["PLib"]["Data"] = self["PLib"]["Data"] or self:SyncData() or {}
        self["PLib"]["Data"][key] = value
    else
        self:SaveData(key, value)
    end
end

if SERVER then
    hook.Add("PlayerDisconnected", "PLib:PlayerData_Sync", function(ply)
        if IsValid(ply) then
            local plibTbl = ply["PLib"]
            if (plibTbl != nil) then
                local data = plibTbl["Data"]
                if (data != nil) then
                    ply:ReplaceAllData(data)
                end
            end
        end
    end)
    
    hook.Add("PLib:PlayerInitialized", "PLib:PlayerData_Sync", function(ply)
        if IsValid(ply) then
            ply:SyncData()
        end
    end)
end

function PLAYER:HasAchievement(tag)
    if (PLib["Achievements"][tag] == nil) then return end
    local achi = self:GetData("Achievements")
    if not istable(achi) then
        return false
    end

    return (achi[id] == true)
end

function PLAYER:SaveAchievement(id)
    local achievements = self:GetData("Achievements")
    if not istable(achievements) then
        achievements = {}
    end

    if (achievements[id] != true) then
        achievements[id] = true

        self:SetData("Achievements", achievements)
        dprint("Saved achievement ", id, ", for ", (self:Nick() or self:Name()))
        
        return true
    end

    return false
end

function PLAYER:GiveAchievement(tag)
    local tbl = PLib["Achievements"][tag]
    if (tbl != nil) then
        if (self:SaveAchievement(tag) == false) and !(SERVER and self:IsListenServerHost()) then
            dprint(string_format("%s already have achievement, %s (Clientside: %s)", (self:Nick() or self:Name()), PLib:TranslateText(tbl[1]), tbl[3]))
            return false
        end
        
        if CLIENT then
            if (tbl[3] != true) then
                return false
            end

            net_Start("PLib")
                net_WriteUInt(0, 3)
                net_WriteString(tag)
            net_SendToServer()
        else
            net_Start("PLib")
                net.WriteUInt(1, 3)
                net.WriteEntity(self)
                net.WriteString(tag)
            net.Broadcast()
        end

        dprint(string_format("%s earned achievement, %s (Clientside: %s)", (self:Nick() or self:Name()), PLib:TranslateText(tbl[1]), tbl[3]))

        return true
    end

    return false
end

function PLAYER:IsGoodGuy()
    return PLib["GoodGuys"][self:SteamID64()] or false
end

if (PLAYER["Nickname"] == nil) then
	PLAYER["Nickname"] = PLAYER["Nick"]

	function PLAYER:Nick()
		return self:GetNWString("Nickname", self:Nickname())
	end
	
	PLAYER["Name"] = PLAYER["Nick"]
end

local LocalPlayer = LocalPlayer
hook.Add("StartCommand", "PLib:LastActivity", function(ply, cmd)
    if CLIENT and ply != LocalPlayer() then return end
    local lr, fb, ud = cmd:GetSideMove(), cmd:GetForwardMove(), cmd:GetUpMove()
    if (lr + fb + ud) != 0 then
        ply["LastActivity"]= CurTime()
        return
    end

    local mx, my, mw = cmd:GetMouseX(), cmd:GetMouseY(), cmd:GetMouseWheel()
    if (mx + my + mw) != 0 then
        ply["LastActivity"] = CurTime()
        return
    end
end)

hook.Add("PlayerNoClip", "PLib:NoclipFix", function(ply)
    return ply:IsSuperAdmin()
end)

local ModelFlexes = {}
local ModelNoFlexes = {}

CreateClientConVar("plib_voice_vibration", "0", true, false, "Talking players without flexes will 'vibrate'", 0, 1)
function PLAYER:MouthMoveAnimation()
    if self:IsSpeaking() then
		local model = self:GetModel()
        if (validStr(model) == true) then
            local flCount = self:GetFlexNum()
            if (flCount > 0) then
                if (ModelFlexes[model] == nil) then
                    ModelFlexes[model] = {}
                    local animeEmotions = {
                        "Ah",
                        "A13",
                        "E",
                        "U",
                        "Wa",
                    }
                    
                    local flexes = {
                        "jaw_drop",
                        "left_part",
                        "right_part",
                        "left_mouth_drop",
                        "right_mouth_drop",
                        -- "cheek",
                        -- "blink",
                        "open",
                        "mouth",
                    }
                
                    local blacklist = {
                        "sideways"
                    }

                    local mdl = util_GetModelInfo(model)
                    local tbl = util_KeyValuesToTablePreserveOrder(mdl["KeyValues"])

                    local mult = math_Round(tbl[1]["Value"][8]["Value"], 2)/500

                    for id = 0, flCount do
                        local name = self:GetFlexName(id)
                        for i = 1, #animeEmotions do
                            if (name == animeEmotions[i]) then
                                local min, max = self:GetFlexBounds(id)
                                table_insert(ModelFlexes[model], {id, min, max, mult})
                            end
                        end

                        for i = 1, #flexes do
                            local flex = flexes[i]
                            if ((name == flex) or string_lower(name):match(flex)) then
                                local blocked = false
                                for i = 1, #blacklist do
                                    if string_lower(name):match(blacklist[i]) then
                                        blocked = true
                                    end
                                end

                                if (blocked == false) then
                                    local min, max = self:GetFlexBounds(id)
                                    table_insert(ModelFlexes[model], {id, min, max, mult})
                                end
                            end
                        end
                    end
                end

                local volume = math_Round(math.striving_for((self["OldVoiceVolume"] or 0), self:VoiceVolume(), 10), 4)

                self["OldVoiceVolume"] = volume

                local flexes = ModelFlexes[model]
                for i = 1, #flexes do
                    local tbl = flexes[i]
                    self:SetFlexWeight(tbl[1], math_Clamp(volume*tbl[4], tbl[2], tbl[3]))
                end
            elseif CLIENT then
                if (ModelNoFlexes[model] == nil) then
                    local bones = {
                        "ValveBiped.Bip01_Head",
                        "ValveBiped.Bip01_Neck1",
                        "ValveBiped.Bip01_Spine4",
                        "ValveBiped.Bip01_Spine3",
                        "ValveBiped.Bip01_Spine2",
                        "ValveBiped.Bip01_Spine1",
                        "ValveBiped.Bip01_Spine",
                        "ValveBiped.Bip01_Pelvis",
                    }

                    for i = 1, #bones do
                        local bone = self:LookupBone(bones[i])
                        if (bone != nil) and (bone > -1) then
                            ModelNoFlexes[model] = bone
                            break;
                        end
                    end
                end

                local mult = 5
                local bone = ModelNoFlexes[model]

                if (GetConVar("plib_voice_vibration"):GetBool() == true) then
                    bone = 0
                    mult = 10
                end

                local rnd = math_random(-1, 1)
                local rnd2 = math_random(-1, 1)

                local volume = math_Round(math.striving_for((self["OldVoiceVolume"] or 0), self:VoiceVolume(), 10), 4)
                
                self["OldVoiceVolume"] = volume

                self:ManipulateBoneAngles(bone, Angle(0, volume*rnd*mult, volume*rnd2*mult))
            end
        end
	elseif (self["OldVoiceVolume"] != nil) then
        local flexes = ModelFlexes[self:GetModel()]
		if (flexes != nil) then
			for i = 1, #flexes do
				self:SetFlexWeight(flexes[i][1], 0)
			end
		end

		self["OldVoiceVolume"] = nil
	end
end