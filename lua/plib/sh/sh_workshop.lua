local string_format = string.format
local game_MountGMA = game.MountGMA
local timer_Simple = timer.Simple
local isfunction = isfunction

PLib["WorkshopDownloaded"] = PLib["WorkshopDownloaded"] or {}
PLib["WorkshopInstalled"] = PLib["WorkshopInstalled"] or {}

function PLib:WorkshopDownload(id, cb)
	if !isstring(id) then id = tostring(id) end
	self.dprint("Workshop", "Trying download addon, id: ", id)

	local saved = self["WorkshopDownloaded"][id]
	if (saved == nil) then
		if CLIENT then
			notification.AddProgress("plib.workshop_download_#" .. id, "[PLib] Downloading: " .. id)
		end

		steamworks.DownloadUGC(id, function(path)
			self.dprint("Workshop", string_format("Addon downloaded, id: %s (%s)", id, path))

			if CLIENT then
				notification.Kill("plib.workshop_download_#" .. id)
			end

			self["WorkshopDownloaded"][id] = path
			if isfunction(cb) then
				cb(path)
			end
		end)

		if CLIENT then
			timer.Simple(30, function()
				notification.Kill("plib.workshop_download_#" .. id)
			end)
		end
	else
		self.dprint("Workshop", "Addon already downloaded, id: ", id)

		if isfunction(cb) then
			cb(saved)
		end

		return saved
	end
end

function PLib:WorkshopInstall(id, cb)
	if !isstring(id) then id = tostring(id) end
	self.dprint("Workshop", "Trying install addon, id: ", id)

	local saved = self["WorkshopInstalled"][id]
	if (saved == nil) then
		self:WorkshopDownload(id, function(path)
			if !isstring(path) then
				if isfunction(cb) then
					cb(false)
				end

				return false
			end
			local ok, files = game_MountGMA(path)

			local outputTbl = {path, files}
			if ok then
				self["WorkshopInstalled"][id] = outputTbl
				self.dprint("Workshop", "Addon installed successfully, id: ", id)
			else
				self.dprint("Workshop", "Addon installation failed, id: ", id)
			end

			if isfunction(cb) then
				cb(ok, path, files)
			end

			return ok and outputTbl or false
		end)
	else
		self.dprint("Workshop", "Addon already installed, id: ", id)

		if isfunction(cb) then
			cb(true, saved[1], saved[2])
		end

		return saved
	end
end

function PLib:WorkshopEnable(id)
	if !isstring(id) then id = tostring(id) end
	self.dprint("Workshop", "Trying enable addon, id: ", id)

	local saved = self["WorkshopInstalled"][id]
	if (saved == nil) then
		self.dprint("Workshop", "Addon not installed, id: ", id)
		return
	end

	for _, fl in ipairs(saved[2]) do
		if fl:StartWith("lua/") then
			local fol = fl:sub(5, #fl)
			if fol:StartWith("autorun") then
				local fol2 = fol:sub(5, #fl)

			elseif fol:StartWith("entities") then
				if file.IsDir(fol, "LUA") then
					-- print(fol)

				elseif fol:EndsWith(".lua") then
					local path = fol:sub(1, fol:find(".lua") - 1)
					local ent_class = path:sub(path:find("/") + 1, #path)

					ENT = {
						["Base"] = "base_anim",
						["Folder"] = "entities/" .. ent_class
					}

					SafeInclude(fol)

					scripted_ents.Register(istable(ENT) and ENT or {}, ent_class)

					ENT = nil
				end
			elseif fol:StartWith("weapons") then
				if file.IsDir(fol, "LUA") then
					-- print(fol)

				elseif fol:EndsWith(".lua") then
					local path = fol:sub(1, fol:find(".lua") - 1)
					local wep_class = path:sub(path:find("/") + 1, #path)

					SWEP = {
						["Folder"] = "weapons/" .. wep_class
					}

					SafeInclude(fol)
					weapons.Register(istable(SWEP) and SWEP or {}, wep_class)

					SWEP = nil
				end
			end
		end

		-- print(fl)
	end

	self.dprint("Workshop", "Addon successfully enabled, id: ", id)
end

function PLib:WorkshopUpdate(id, cb)
	if !isstring(id) then id = tostring(id) end
	self.dprint("Workshop", "Trying update addon, id: ", id)

	local saved = self["WorkshopInstalled"][id]
	if (saved == nil) then
		self.dprint("Workshop", "Addon not installed, id: ", id)

		if isfunction(cb) then
			cb(false)
		end

		return saved
	else
		self:WorkshopDownload(id, function(path)
			local ok, files = game_MountGMA(path)

			local outputTbl = {path, files}
			if ok then
				self["WorkshopInstalled"][id] = outputTbl
				self.dprint("Workshop", "Addon update successfully, id: ", id)
			else
				self.dprint("Workshop", "Addon update failed, id: ", id)
			end

			if isfunction(cb) then
				cb(ok, path, files)
			end

			return (ok and outputTbl or false)
		end)
	end
end

function PLib:TryInstallWorkshop(id, cb, num)
	self:WorkshopInstall(id, function(ok, path, files)
		if (ok == false) then
			num = num + 1
			timer_Simple(10, function()
				self:TryInstallWorkshop(id, cb, num)
			end)

			self.dprint("Workshop", "Install try #", num)
		elseif isfunction(cb) then
			cb(path, files)
		end
	end)
end

-- PLib:TryInstallWorkshop("2663863847", function()
-- 	-- PLib:WorkshopEnable("2663863847")
-- end)

if SERVER then
	hook.Add("PLib:PlayerInitialized", "PLib:CheckSelfHosted", function(ply)
		hook.Remove("PLib:PlayerInitialized", "PLib:CheckSelfHosted")
		local host = player.GetListenServerHost()
		if IsValid(host) and (steamworks == nil) then
			util.AddNetworkString("PLib.steamworks")
			steamworks = {}

			local funcs = {}
			function steamworks.DownloadUGC(id, func)
				if !isstring(id) or !isfunction(func) then return end
				net.Start("PLib.steamworks")
					net.WriteUInt(table.insert(funcs, func), 7)
					net.WriteString(id)
				net.Send(host)
			end

			net.Receive("PLib.steamworks", function(len, ply)
				if (ply != host) then
					ply:Kick("PLib - Don't touch my net functions!")
					return
				end

				local id = net.ReadUInt(7)
				local func = funcs[id]
				if (func != nil) then
					func(net.ReadString())
					table.remove(funcs, id)
				end
			end)
		end
	end)
else
	net.Receive("PLib.steamworks", function()
		local num = net.ReadUInt()
		steamworks.DownloadUGC(net.ReadString(), function(path)
			net.Start("PLib.steamworks")
				net.WriteUInt(num, 7)
				net.WriteString(path)
			net.SendToServer()
		end)
	end)
end