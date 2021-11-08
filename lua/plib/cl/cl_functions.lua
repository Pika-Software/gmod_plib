local string_format = string.format
local sound_PlayURL = sound.PlayURL
local validStr = string["isvalid"]
local dprint = PLib["dprint"]
local math_Round = math.Round
local math_max = math.max
local isstring = isstring
local CurTime = CurTime
local IsValid = IsValid

-- Sound Analyze by _ᐱℕᏩĒŁØҜҜ_#8486
PLib["URL_Sound_List"] = PLib["URL_Sound_List"] or {}
PLib["DefaultSoundURL"] = "https://radio.pika-soft.ru/stream"
PLib["MaxURLSoundDist"] = 200
PLib["MaxURLSoundDist^"] = math.pow(PLib["MaxURLSoundDist"], 2) * 20
function PLib:PlayURL(tag, url, target, flags, callback)
    if (tag == nil) then
        tag = "PLib"
        dprint("PlayURL", "No TAG, installed by default: PLib")
    end

    if (url == "Stop") then
        self:RemoveURLSound(tag)
        return
    end

    if (validStr(url) == false) then
        url = self["DefaultSoundURL"]
        dprint("PlayURL", "No URL, installed by default: ", self["DefaultSoundURL"])
    end

    local tbl = self["URL_Sound_List"][tag]
    if (tbl != nil) then
        local soundChannel = tbl[1]
        if IsValid(soundChannel) then
            soundChannel:Stop()
            dprint("PlayURL", "SoundChannel already created! Recreating...")
        end
    end

    sound_PlayURL(url, (IsValid(target) and "3d " or "")..((isstring(flags)) and flags or ""), function(channel, errorID, errorName)
        if IsValid(channel) then
            if (callback != nil) then
                callback(channel, errorID, errorName)
            end

            if IsValid(target) then
                local pos = target:GetPos()
                if (target["OBBCenter"] != nil) then
                    pos = pos + target:OBBCenter()
                end

                channel:Set3DFadeDistance(self["MaxURLSoundDist"] / 2, 0)
                channel:SetPos(pos)

                target[tag] = channel
            end

            channel:Play()
            timer.Simple(0, function()
                self["URL_Sound_List"][tag] = {channel, IsValid(target) and target or false}
                dprint("PlayURL", string_format("SoundChannel, %s created!", tag))
            end)
        else
            dprint("PlayURL", string_format("Error, %s! [%s]", errorID, errorName))
        end
    end)
end

function PLib:URLSoundThink()
    for tag, tbl in pairs(self["URL_Sound_List"]) do
        if (tbl != nil) then
            local channel = tbl[1]
            if IsValid(channel) then
                local target = tbl[2]
                if (target != false) then
                    if IsValid(target) then
                        local pos = target:GetPos()
                        if (target["OBBCenter"] != nil) then
                            pos = pos + target:OBBCenter()
                        end

                        if (LocalPlayer():GetPos():DistToSqr(pos) < self["MaxURLSoundDist^"]) then
                            if (channel:GetState() == 2) then
                                channel:Play()
                            end
                        elseif (channel:GetState() == 1) then
                            channel:Pause()
                        end

                        channel:SetPos(pos)
                    else
                        channel:Stop()
                        self["URL_Sound_List"][tag] = nil
                    end
                end
            else
                self["URL_Sound_List"][tag] = nil
            end
        end
    end
end

hook.Add("Think", "PLib:URLSound", function()
    PLib:URLSoundThink()
end)

function PLib:GetURLSound(tag)
    if (tag == nil) then
        tag = "PLib"
        dprint("PlayURL", "No TAG, installed by default: PLib")
    end

    local tbl = self["URL_Sound_List"][tag]
    if (tbl != nil) and IsValid(tbl[1]) then
        return tbl[1], tbl[2]
    end

    return false
end

function PLib:RemoveURLSound(tag)
    if (tag == nil) then
        tag = "PLib"
        dprint("PlayURL", "No TAG, installed by default: PLib")
    end

    local tbl = self["URL_Sound_List"][tag]
    if (tbl != nil) and IsValid(tbl[1]) then
        tbl[1]:Stop()
        self["URL_Sound_List"][tag] = nil
        return true
    end

    return false
end

function PLib:SoundAnalyze(channel)
    local bass, fft = 0, {}
    if IsValid(channel) then
    channel:FFT(fft, 6)

    for i = 1, 255 do
        if (fft[i] == nil) then continue end
        bass = math_max(0, bass, fft[i]*170)
    end
end
    return fft, bass
end

function PLib:GetBass(channel)
    local bass, fft = 0, {}
    channel:FFT(fft, 6)

    for i = 1, 255 do
        if (fft[i] == nil) then continue end
        bass = math_max(0, bass, fft[i]*170)
    end

    return math_Round(bass)
end

local HSVToColor = HSVToColor
function PLib:BassColor(bass, frequency, saturation, value)
    return HSVToColor(bass * frequency  % 360, saturation or 1, value or 1)
end

local StandardAchievementIcons = {
    [0] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/b8ce64f366e8a8a1c2aef231cca8ec82f3115d63.jpg",
    [1] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/d6b5b7ac882b0865415218642cb21bfb5a5fca77.jpg",
    [2] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/f4bc0f96a846eeaa63a9ea92d11757b342376374.jpg",
    [3] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/f331d3e21b7fc96c8f117787fe3e2d5e26b9952e.jpg",
    [4] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/9d99453c08ea180230b5ad24f904c0749e6ce139.jpg",
    [5] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/7cb317f7a953204e79a3fc2923aad8eb77df74bd.jpg",
    [6] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/c1421b7d9609b03bca96bae9abde44da628d20a1.jpg",
    [7] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/88f7f6f51232d0792f70683599a55974b14086d1.jpg",
    [8] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/14f07b40867ab5ceb305fa99fc1b112fc96abb14.jpg",
    [9] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/725230a05dc1cc0fbba9be46233d77b34ca9f685.jpg",
    [10] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/82ee06b6fb3a0aed698dfa33303526d58340f2c1.jpg",
    [11] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/a200f9a8cc7327f9885218ff2e1a9317ce711459.jpg",
    [12] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/9d608f3ad483370e261da7991aece5c135432098.jpg",
    [13] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/812c6a24eb1997d7784e7bc6ab381899ae6b0753.jpg",
    [14] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/814409f41a371a1029d4dda336f3d6958c558548.jpg",
    [15] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/33309ff1fc671bd3bf7f74dfd29df688429d2943.jpg",
    [16] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/040ae0e4fef44e23609b2cd2b545d3f41c782dd0.jpg",
    [17] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/0352bbe5511ea372e24108680a70929e559c3dcc.jpg",
    [18] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/c45ed5c18d9b92d68ea034d13fe0ee537110753f.jpg",
    [19] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/1ce84afb8118aafc4e2aa5c007b97f8d7330bbf8.jpg",
    [20] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/8fbefdee3a3f2ac51a51aa7cd2d5f7116165aad8.jpg",
    [21] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/5dd0d4a1bcd15561860a06ea76969dfce4ff6b76.jpg",
    [22] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/ab6158930869f33717e4aa55122973ffd8d3d364.jpg",
    [23] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/e2e840130db8efd5e34f12087a0ccddb7b04f40e.jpg",
    [24] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/de22904018d342008bb6d94087190a0c2493689f.jpg",
    [25] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/1c5bef9615a260ae3177c26ad8ac86f5dc192ead.jpg",
    [26] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/0afc0d332af9c5e779302bb7a70d29b15fdec263.jpg",
    [27] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/f0b8f66a9f445a80fcf7897d8b07c634ae26a469.jpg",
    [28] = "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/4000/75b1b16c2b67b893d35d3b8c79de90dcb14dfd4b.jpg",
}

local matOptions = PLib["MatPresets"]["Pic"]
function PLib:GetStandardAchievementIcon(id)
    if isnumber(id) and (id < 29) then
        return Material(StandardAchievementIcons[id], matOptions)
    end
end

local ents_GetAll = ents.GetAll
function PLib:CleanUpClientSideEnts(filters)
    local filterFunc = filters
    if not isfunction(filterFunc) then
        local funcStr = [[
            local args = {...}
            local ent, filter = args[1], args[2]
        ]]

        if IsEntity(filters) then
            funcStr = funcStr .. [[
                return (ent == filter)
            ]]
        elseif isstring(filters) then
            funcStr = funcStr .. [[
                return (ent:GetClass() == filter)
            ]]
        elseif istable(filters) and not table.IsEmpty(filters) then
            funcStr = funcStr .. [[
                local class = ent:GetClass()
                for num, value in ipairs(filter) do
                    if (ent == value) or (class == value) then
                        return true
                    end
                end

                return false
            ]]
        else
            funcStr = "return true"
        end

        filterFunc = CompileString(funcStr, "CleanUpClientSideEnts")
    end

    for _, ent in ipairs(ents_GetAll()) do
        if IsValid(ent) and (ent:EntIndex() == -1) and filterFunc(ent, filters) then
            ent:Remove()
        end
    end

    hook.Run("PLib:PostClientCleanup")
end

function PLib.LightLevel(pos)
    local col = render.GetLightColor(pos):ToColor()
    return (col["r"] / 255 + col["g"] / 255 + col["b"] / 255) / 3
end