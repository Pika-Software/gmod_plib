-- PLib Core by PrikolMen#3372
local resource_AddWorkshop = resource.AddWorkshop
local engine_GetAddons = engine.GetAddons
local game_MountGMA = game.MountGMA
local string_sub = string.sub
local file_Find = file.Find
local include = include
local ipairs = ipairs
local pairs = pairs
local Msg = Msg

util.AddNetworkString("PLib")

function PLib:FastDL_File(fl, name, compress)
    resource.AddSingleFile(fl, name or "PLib", compress)
end

function PLib:FastDL_Folder(folder, name, compress)
    local files, folders = file_Find(folder.."/*", "GAME")

    for i = 1, #files do
        self:FastDL_File(folder.."/"..files[i], name, compress)
    end

    for i = 1, #folders do
        self:FastDL_Folder(folder.."/"..folders[i], name, compress)
    end
end

function PLib:SteamWorkshop(addmaps)
    local addons = engine_GetAddons()
    local st = SysTime()

    if #addons > 0 then
        Msg("\n")
        self:Log(nil, "Making enabled addons available for client download...")
        local count = 0

        for _, addon in ipairs(addons) do
            if !addon["downloaded"] or !addon["mounted"] then continue end

            local wsid = addon["wsid"]
            if addon["tags"]:find(",map,") then
                if addmaps then
                    resource_AddWorkshop(wsid)
                    Msg("\t+ Map: "..addon["title"].." ("..wsid..")\n")
                    count = count + 1
                else
                    Msg("\t- Map (ignored): "..addon["title"].." ("..wsid..")\n")
                end
            else
                resource_AddWorkshop(wsid)
                Msg("\t+ Addon: "..addon["title"].." ("..wsid..")\n")
                count = count + 1
            end
        end

        self:Log(nil, "Total: "..count.." addons "..string.format("added to client download list in %.4f seconds.", SysTime() - st), "\n")
    end
end