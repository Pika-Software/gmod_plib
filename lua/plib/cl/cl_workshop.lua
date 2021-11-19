local notification_AddProgress = notification.AddProgress
local steamworks_DownloadUGC = steamworks.DownloadUGC
local string_format = string.format
local notification_Kill = notification.Kill
local isfunction = isfunction
local game_MountGMA = game.MountGMA
local timer_Simple = timer.Simple

PLib["WorkshopDownloaded"] = PLib["WorkshopDownloaded"] or {}
PLib["WorkshopInstalled"] = PLib["WorkshopInstalled"] or {}

function PLib:WorkshopDownload(id, cb)
	self.dprint("Workshop", "Trying download addon, id: ", id)

	local saved = PLib["WorkshopDownloaded"][id]
	if (saved == nil) then
		if CLIENT then
			notification_AddProgress("plib.workshop_download_#" .. id, "[PLib] Downloading: " .. id)
		end

		steamworks_DownloadUGC(id, function(path)
			self.dprint("Workshop", string_format("Addon downloaded, id: %s (%s)", id, path))

			if CLIENT then
				notification_Kill("plib.workshop_download_#" .. id)
			end

			PLib["WorkshopDownloaded"][id] = path
			if isfunction(cb) then
				cb(path)
			end
		end)
	else
		self.dprint("Workshop", "Addon already downloaded, id: ", id)

		if isfunction(cb) then
			cb(saved)
		end

		return saved
	end
end

function PLib:WorkshopInstall(id, cb)
	self.dprint("Workshop", "Trying install addon, id: ", id)

	local saved = PLib["WorkshopInstalled"][id]
	if (saved == nil) then
		self:WorkshopDownload(id, function(path)
			local ok, files = game_MountGMA(path)

			local outputTbl = {path, files}
			if ok then
				PLib["WorkshopInstalled"][id] = outputTbl
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