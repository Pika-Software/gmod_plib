local net_dbg = CreateConVar("plib_" .. (SERVER and "svdbg" or "cldbg") .. "_receive", "0", "Enable/disable output for incoming messages")

local messages_logtime = {}
local nextlogtime = 0.3

-- Function for handling messages from the network
function net.Incoming(len, client)
    local id = net.ReadHeader()
    local poolstr = util.NetworkIDToString(id)

    if not poolstr then return end
    poolstr = poolstr:lower()

    local func = net.Receivers[poolstr]
    if not func then return end

    -- Removes 2 bytes of ReadHeader from length
    len = len - 16

    if net_dbg:GetBool() and (SERVER or PLib:DebugAllowed()) and CurTime() > (messages_logtime[poolstr] or 0) then
        messages_logtime[poolstr] = CurTime() + nextlogtime
        if IsValid(client) then
            PLib:Log("Debug/NetIncoming", string.format("%s(%s)<I%i:P%i> send `%s`, length %i bits (%i bytes)", client:Nick(), client:SteamID(), client:EntIndex(), client:UserID(), poolstr, len, len * 0.125))
        else
            PLib:Log("Debug/NetIncoming", string.format("Received `%s`, length %i bits (%i bytes)", poolstr, len, len * 0.125))
        end
    end

    func(len, client)
end

concommand.Add("plib_" .. (SERVER and "sv" or "cl") .. "find_netpool", function(ply, cmd, args)
    if CLIENT and not PLib:DebugAllowed() then return end
    local findpatt = args[1]
    if not findpatt or findpatt == "" then return end
    findpatt = findpatt:lower()
    PLib:Log("Debug/NetPoolSearch", "Results:")
    for id = 1, 4096 do
        local strpool = util.NetworkIDToString(id)
        if strpool and strpool:lower():find(findpatt) then
            local func = net.Receivers[strpool] or net.Receivers[strpool:lower()]
            local info = "[NOT IN RECEIVERS]:-1"
            if func then
                info = debug.getinfo(func)
                info = info.source .. ":" .. info.linedefined
            end
            PLib:Log(id, string.format("%s    %s", strpool, info))
        end
    end
end)