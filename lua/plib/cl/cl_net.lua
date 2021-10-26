local net_ReadEntity = net.ReadEntity
local net_ReadString = net.ReadString
local net_ReadUInt = net.ReadUInt
local net_Receive = net.Receive
local tostring = tostring
local isnumber = isnumber
local IsValid = IsValid

PLib:Precache_G("net.Start", net.Start)
local net_Start = PLib:Get_G("net.Start")
local math_random = math.random
local SysTime = SysTime

local nets = {}
local function checkNetStart(name, timeout)
    if (timeout != nil) then
        local lastNet = nets[name]
        if (lastNet != nil) then
            if (nets[name] == false) then return false end
            if (lastNet[2] > math_random(22, 28)) then
                nets[name] = false
                return false
            end
        
            if (SysTime() - lastNet) < timeout then
                nets[name] = {SysTime(), lastNet[2] + 1}
                return false
            end
        end

        lastNet = {SysTime(), 0}
	end

    return true
end

function net.Start(name, unreliable, timeout, tag)
    if (checkNetStart(tag or name, timeout) == false) then
        Error("Too frequent requests to server!") 
    end

    net_Start(name, unreliable)
end

local matOptions = PLib["MatPresets"]["Pic"]
local acts = {
    [0] = function()
        PLib["Achievements"] = {}
        for tag, tbl in pairs(net.ReadCompressTable() or {}) do
            if (tbl != nil) then
                local mat = tbl[2]
                if (mat != nil) then
                    tbl[2] = (isnumber(mat) and PLib:GetStandardAchievementIcon(id) or Material(mat, matOptions))
                end

                PLib["Achievements"][tostring(tag)] = tbl
            end
        end
    end,
    [1] = function()
        local ply = net_ReadEntity()
        if IsValid(ply) then
            local id = net_ReadString()
            ply:GotAchievement(id)
            if (ply == LocalPlayer()) then
                PLib.AchievementVGUI(id)
            end
        end
    end,
    [2] = function()
        LocalPlayer():Notify(net.ReadString(), net.ReadString())
    end,
    [3] = function()
        local url = net.ReadString()
        PLib["ServerLogo"] = Material(url, matOptions)
        RunConsoleCommand("plib_logo_update")
    end,
    [4] = function()
        local NETCALL = PLib["NetCallback"]
        NETCALL:Run(net.ReadString(), net.ReadCompressTable())
    end,
}

net_Receive("PLib", function(len)
    local act = acts[net_ReadUInt(3)]
    if (act != nil) then
        act();
    end
end)