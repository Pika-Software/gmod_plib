local validStr = string["isvalid"]
local string_sub = string.sub
local string_find = string.find
local acts = {
	-- Achievements
	[0] = function(ply)
			if IsValid(ply) then
				local id = net.ReadString()
				if (id != "") then
					local tbl = PLib["Achievements"][id]
					if (tbl != nil) then
						if (tbl[3] != true) then
							return false
						end

						ply:GiveAchievement(id)
					end
				end
			end
		end,
	[1] = {
		function(ply)
			local tag = net.ReadString()
			if validStr(tag) then
				local ts = string_find(tag, "_")
				if (ts != nil) then
					local steamid64 = net.ReadString()
					if validStr(steamid64) then
						PLib[string_sub(tag, 0, ts - 1)](PLib, steamid64, function(tbl)
							if IsValid(ply) then
								net.Start("PLib")
									net.WriteUInt(4, 3)
									net.WriteString(tag)
									net.WriteCompressTable(tbl)
								net.Send(ply)
							end
						end)
					end
				end
			end
		end,
		0.3,
	},
}

local math_random = math.random
local CurTime = CurTime
local maxWarns = 100

local function NetCheck(ply, id, timeout)
	if (ply["PLibNetSecure"] == nil) then
		ply["PLibNetSecure"] = {
			["Nets"] = {},
			["Warns"] = 0,
		}
	end

	if (ply["PLibNetSecure"]["Warns"] > maxWarns + math_random(1, 10)) then
		ply["NET::BLOCK"] = true
	end

	local curTime = CurTime()
	ply["PLibNetSecure"]["Nets"][id] = curTime

	local warns = ply["PLibNetSecure"]["Warns"]
	if (curTime - ply["PLibNetSecure"]["Nets"][id]) > (timeout - ply:Ping()/1000) then
		ply["PLibNetSecure"]["Warns"] = warns + 1
		return false
	end

	if (warns > 0) then
		ply["PLibNetSecure"]["Warns"] = warns - 0.5
	end

	return true
end

net.Receive("PLib", function(len, ply)
	if IsValid(ply) then
		if (ply["NET::BLOCK"] == true) then return end
		local id = net.ReadUInt(3)
		local act = acts[id]
		if isfunction(act) then
			act(ply)
		elseif istable(act) then
			if NetCheck(ply, id, act[2]) then
				act[1](ply)
			end
		end
	end
end)