-- PLib Core by PrikolMen#3372
local resource_AddWorkshop = resource.AddWorkshop
local engine_GetAddons = engine.GetAddons
local game_MountGMA = game.MountGMA
local string_lower = string.lower
local string_sub = string.sub
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

local function IsMap(addon)
	return (addon["tags"]:find("map") or addon["title"]:find("ttt_")) and not string_lower(addon["title"]):find("nav file")
end

PLib["Workshop"] = PLib["Workshop"] or {}
function PLib:AddWorkshop(addon)
	local wsid = addon["wsid"]
	resource_AddWorkshop(wsid)
	Msg(string.format("\t+ %s: %s (%s)\n", (IsMap(addon) and "Map" or "Addon"), addon["title"], wsid))
	self["Workshop"][wsid] = addon
end

function PLib:SteamWorkshop()
	local addons = engine_GetAddons()
	local st = SysTime()

	if #addons > 0 then
		Msg("\n")
		self:Log(nil, "Making enabled addons available for client download...")

		local oldWorkshopCount = 0
		for _, _ in pairs(self["Workshop"]) do
			oldWorkshopCount = oldWorkshopCount + 1
		end

		local currentMap = game.GetMap()
		for _, addon in ipairs(addons) do
			if not addon["downloaded"] or not addon["mounted"] then continue end
			if IsMap(addon) then
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
					self:AddWorkshop(addon)
				else
					Msg("\t- Map (ignored): " .. addon["title"] .. " (" .. addon["wsid"] .. ")\n")
				end
			else
				self:AddWorkshop(addon)
			end
		end

		local newCount = 0
		for _, _ in pairs(self["Workshop"]) do
			newCount = newCount + 1
		end

		self:Log(nil, "Total: " .. (newCount - oldWorkshopCount) .. " addons " .. string.format("added to client download list in %.4f seconds.", SysTime() - st), "\n")
	end
end