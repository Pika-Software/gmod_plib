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

-- local function loadLuaFolder(path)
-- 	local files, folder = file.Find(path .. "/*", "LUA")
-- 	for _, fol in ipairs(folders) do
-- 		print(fol)
-- 		loadLuaFolder(path .. "/" .. fol)
-- 	end

-- 	for _, fl in ipairs(files) do
		
-- 	end
-- end

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

-- PLib:WorkshopEnable("2663863847")

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