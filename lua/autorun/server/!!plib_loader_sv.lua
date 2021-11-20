-- PLib Core by PrikolMen#3372
local resource_AddWorkshop = resource.AddWorkshop
local engine_GetAddons = engine.GetAddons
local file_Find = file.Find
local ipairs = ipairs
local Msg = Msg

function PLib:FastDL_File(fl, name, compress)
	resource.AddSingleFile(fl, name or "PLib", compress)
end

function PLib:FastDL_Folder(folder, name, compress)
	local files, folders = file_Find(folder .. "/*", "GAME")

	for i = 1, #files do
		self:FastDL_File(folder .. "/" .. files[i], name, compress)
	end

	for i = 1, #folders do
		self:FastDL_Folder(folder .. "/" .. folders[i], name, compress)
	end
end

local allMaps = CreateConVar("plib_workshop_all_maps", "0", {FCVAR_ARCHIVE, FCVAR_LUA_SERVER}, "Adds to client download list all maps from server collection. (0/1)", 0, 1):GetBool()
cvars.AddChangeCallback("plib_workshop_all_maps", function(name, old, new)
	allMaps = tobool(new)
end, "PLib")

local onlyActiveMap = CreateConVar("plib_workshop_active_map", "1", {FCVAR_ARCHIVE, FCVAR_LUA_SERVER}, "Adds to client download list only curret map from server collection. (0/1)", 0, 1):GetBool()
cvars.AddChangeCallback("plib_workshop_active_map", function(name, old, new)
	onlyActiveMap = tobool(new)
end, "PLib")

PLib["WorkshopCount"] = PLib["WorkshopCount"] or 0
function PLib:AddWorkshop(wsid, title, tag)
	resource_AddWorkshop(wsid)
	string.format("\t+ %s: %s (%s)\n", (tag or "Addon"), title, wsid)
	self["WorkshopCount"] = self["WorkshopCount"] + 1
end

function PLib:SteamWorkshop()
	local addons = engine_GetAddons()
	local st = SysTime()

	if #addons > 0 then
		Msg("\n")
		self:Log(nil, "Making enabled addons available for client download...")
		local oldWorkshopCount = self["WorkshopCount"]
		local currentMap = game.GetMap()

		for _, addon in ipairs(addons) do
			if not addon["downloaded"] or not addon["mounted"] then continue end

			local wsid = addon["wsid"]
			if addon["tags"]:find("map") then
				local shouldAdd = allMaps

				if onlyActiveMap and (allMaps == false) then
					local ok, files = game_MountGMA(addon["file"])
                    if not ok then continue end
                    
					for _, fl in ipairs(files) do
                        if (string_sub(fl, #fl - 3, #fl) == ".bsp") then
                            if (string_sub(fl, 6, #fl - 4) == currentMap) then
								shouldAdd = true
                                break;
                            end
                        end
                    end
				end

				if shouldAdd then
					self:AddWorkshop(wsid, addon["title"], "Map")
				else
					Msg("\t- Map (ignored): " .. addon["title"] .. " (" .. wsid .. ")\n")
				end
			else
				self:AddWorkshop(wsid, addon["title"])
			end
		end

		self:Log(nil, "Total: " .. (self["WorkshopCount"] - oldWorkshopCount) .. " addons " .. string.format("added to client download list in %.4f seconds.", SysTime() - st), "\n")
	end
end