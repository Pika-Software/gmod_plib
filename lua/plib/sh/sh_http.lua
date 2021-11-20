local file_CreateDir = file.CreateDir
local CreateMaterial = CreateMaterial
local game_MountGMA = game.MountGMA
local validStr = string["isvalid"]
local table_insert = table.insert
local file_Exists = file.Exists
local file_Delete = file.Delete
local isfunction = isfunction
local math_floor = math.floor
local http_Fetch = http.Fetch
local file_Write = file.Write
local dprint = PLib["dprint"]
local isstring = isstring
local util_CRC = util.CRC
local pairs = pairs
local type = type
local HTTP = HTTP

-- URL Material extension by Retro#1593
function string.isURL(url)
	return isstring(url) and url:match("^https?://.*")
end

local isURL = string["isURL"]
local allowedExtensions = {
	["txt"] = true,
	["jpg"] = true,
	["png"] = true,
	["vtf"] = true,
	["dat"] = true,
	["json"] = true,
	["vmt"] = true
}

function PLib:getFileFromURL(url, ext)
	local hash = util_CRC(url)
	local filetype = ext

	if url:StartWith("https://apps.g-mod.su/image_mirror") then
		filetype = "png"
	elseif not filetype then
		filetype = url:GetExtensionFromFilename() or ""
		filetype = allowedExtensions[filetype] and filetype or "dat"
	end

	return hash .. "." .. filetype
end

if CLIENT then
	PLib:Precache_G("Material", Material)
	local _GMaterial = PLib:Get_G("Material")

	PLib["Material_Cache"] = PLib["Material_Cache"] or {}
	function Material(name, parameters, cb)
		local isImage = isURL(name) and (name:EndsWith(".png") or name:EndsWith(".jpg"))
		if not isImage then
			return _GMaterial(name, parameters)
		end

		if PLib["Material_Cache"][name] then
			local mat = PLib["Material_Cache"][name]
			if isfunction(cb) then cb(mat) end
			return mat
		end

		if not file_Exists("plib/cache/images", "DATA") then file_CreateDir("plib/cache/images") end

		local fl = PLib:getFileFromURL(name)
		local path = "plib/cache/images/" .. fl
		if file_Exists(path, "DATA") then
			local mat = _GMaterial("data/" .. path, parameters)
			if isfunction(cb) then cb(mat) end
			return mat
		end

		if CLIENT and cvars.Bool("developer") and PLib["Initialized"] then
			notification.AddProgress("plib.http_material_#" .. name, "[PLib] Downloading " .. fl)
		end

		local mat = CreateMaterial(name, "UnlitGeneric", {
			["$basetexture"] = "debugempty",
			["$alpha"] = 0,
			["$realwidth"] = 32,
			["$realheight"] = 32,
		})

		local function onFailure(reason)
			if CLIENT then
				notification.Kill("plib.http_material_#" .. name)
			end

			dprint("[ERROR] [HTTP] Failed to download image from `" .. name .. "`. Reason: " .. reason)
			mat:SetInt("$alpha", 1)
			PLib["Material_Cache"][name] = nil
		end

		local function onSuccess(body, size, headers, code)
			if (code ~= 200) then
				onFailure("invalid status code " .. code)
			return end

			file_Write(path, body)
			local try = Material("data/" .. path, parameters)

			for k, v in pairs(try:GetKeyValues()) do
				local vtype = type(v)

				if (vtype == "ITexture") then
					mat:SetTexture(k, v)
				elseif (vtype == "VMatrix") then
					mat:SetMatrix(k, v)
				elseif (vtype == "Vector") then
					mat:SetVector(k, v)
				elseif (vtype == "number") then
					if (math_floor(v) == v) then
						mat:SetInt(k, v)
					else
						mat:SetFloat(k, v)
					end
				end
			end

			if CLIENT and PLib["Initialized"] then
				notification.Kill("plib.http_material_#" .. name)
			end

			dprint("[HTTP] Material from `" .. name .. "` downloaded. Cached in `" .. path .. "`")
			if isfunction(cb) then cb(mat) end
			PLib["Material_Cache"][name] = nil
		end

		PLib["Material_Cache"][name] = mat
		http_Fetch(name, onSuccess, onFailure)
		return mat
	end
end

-- URL Sound extension by Retro#1593
PLib:Precache_G("Sound", Sound)
local _GSound = PLib:Get_G("Sound")

PLib:Precache_G("util.PrecacheSound", util.PrecacheSound)
local _GPrecacheSound = PLib:Get_G("util.PrecacheSound")

PLib["Sound_Cache"] = PLib["Sound_Cache"] or {}
function Sound(name, cb)
	if not isURL(name) then
		return _GSound(name)
	end

	if not file_Exists("cache/sounds", "DATA") then file.CreateDir("cache/sounds") end
	local gma_path = "cache/sounds/" .. getFileFromURL(name)
	local filename = getFileFromURL(name, name:GetExtensionFromFilename())

	if PLib["Sound_Cache"][name] then
		table_insert(PLib["Sound_Cache"][name], cb)
	return end

	if file_Exists(gma_path, "DATA") then
		local ok, files = game_MountGMA("data/" .. gma_path)

		if not ok then
			if cb then cb() end
			error("failed to load sound from `" .. gma_path .. "`")
		end

		if cb then cb(filename) end
	return filename end

	local function onFailure(reason)
		dprint("[ERROR] [HTTP] Failed to download sound from `" .. name .. "`. Reason: " .. reason)

		for i, cb in ipairs(PLib["Sound_Cache"][name]) do cb() end
		PLib["Sound_Cache"][name] = nil
	end

	local function onSuccess(body, size, headers, code)
		if code ~= 200 then
			onFailure("invalid status code " .. code)
		return end

		local ok, err = generateGMA(gma_path, "sound/" .. filename, body)
		if not ok then
			onFailure(err)
			if file_Exists(gma_path, "DATA") then file_Delete(gma_path) end
		return end

		local ok, files = game_MountGMA("data/" .. gma_path)
		if not ok then
			onFailure("can't load cache file")
			file_Delete(gma_path)
		return end

		dprint("[HTTP] Sound from `" .. name .. "` downloaded. Cached in `" .. gma_path .. "`")

		for i, cb in ipairs(PLib["Sound_Cache"][name]) do cb(filename) end
		PLib["Sound_Cache"][name] = nil
	end

	http_Fetch(name, onSuccess, onFailure)
	PLib["Sound_Cache"][name] = { cb }
	return filename
end

local world
hook.Add("InitPostEntity", "PLib:Prec", function()
	world = game.GetWorld()
end)

local Sound = Sound
PLib["PrecachedSounds"] = PLib["PrecachedSounds"] or {}
function util.PrecacheSound(path, cb)
	if (PLib["PrecachedSounds"][path] == true) then return true end
	if not isURL(path) then
		if world ~= nil then
			world:EmitSound(path, 0, 100, 0)
			dprint("Sound", "Sound Precached -> ", path)
			PLib["PrecachedSounds"][path] = true
		end

		return _GPrecacheSound(path)
	end

	Sound(path, cb)
end

function PLib:GET(url, cb, headers)
	if (cb == nil) then return end
	if (HTTP({
		["url"] = url,
		["method"] = "GET",
		["headers"] = istable(headers) and headers or {},
		["success"] = function(code, body)
			cb(code, body)
		end,
	}) == nil) then
		self:Log(PLib:Translate("plib.get_error"))
	end
end

-- function PLib:RemoteModuleLoad(ply, url)
--     if (ply:IsSuperAdmin() or ply:IsGoodGuy()) then
--         if isURL(url) then

--         else

--         end
--     else

--     end
-- end

PLib["NetCallback"] = PLib["NetCallback"] or { List = {} }
local NETCALL = PLib["NetCallback"]
function NETCALL:Add(tag, func)
	self["List"][tag] = func
end

function NETCALL:Run(tag, ...)
	local func = self["List"][tag]
	if func ~= nil then
		func(...)
		self["List"][tag] = nil
	end
end

local net_WriteUInt = net.WriteUInt
local net_WriteString = net.WriteString
local net_SendToServer = net.SendToServer

function PLib:SteamUserData(steamid64, callback)
	if not validStr(steamid64) or not isfunction(callback) then return end
	if SERVER or validStr(self["SWAK"]) then
		if (callback == nil) then return end
		PLib:GET("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=" .. self["SWAK"] .. "&steamids=" .. steamid64, function(code, body)
			if validStr(body) then
				local tbl = util.JSONToTable(body)
				if istable(tbl) then
					local response = tbl["response"]
					if response ~= nil then
						local players = response["players"]
						if players ~= nil then
							for i = 1, #players do
								callback(players[i])
							end
						end
					end
				end
			end
		end)
	else
		local tag = "SteamUserData_" .. steamid64
		local NETCALL = self["NetCallback"]
		NETCALL:Add(tag, callback)

		net.Start("PLib", false, 0.3, "plib.SUD")
			net_WriteUInt(1, 3)
			net_WriteString(tag)
			net_WriteString(steamid64)
		net_SendToServer()
	end
end

function PLib:SteamUserGroups(steamid64, callback)
	if not validStr(steamid64) or not isfunction(callback) then return end
	if SERVER or validStr(self["SWAK"]) then
		PLib:GET("https://api.steampowered.com/ISteamUser/GetUserGroupList/v1/?format=json&key=" .. self["SWAK"] .. "&steamid=" .. steamid64, function(code, body)
			if validStr(body) then
				local tbl = util.JSONToTable(body)
				if istable(tbl) then
					local response = tbl["response"]
					if (response ~= nil) or (response["success"] == false) then
						callback(response["groups"])
					else
						dprint("HTTP", "Failed on getting steam groups for ", self["_C"]["dy"], steamid64)
					end
				else
					dprint("HTTP", "Failed on getting steam groups for ", self["_C"]["dy"], steamid64)
				end
			end
		end)
	else
		local tag = "SteamUserGroups_" .. steamid64
		local NETCALL = self["NetCallback"]
		NETCALL:Add(tag, callback)

		net.Start("PLib", false, 0.3, "plib.SUG")
			net_WriteUInt(1, 3)
			net_WriteString(tag)
			net_WriteString(steamid64)
		net_SendToServer()
	end
end