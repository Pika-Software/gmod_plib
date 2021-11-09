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

function PLib:SteamWorkshop(map) -- game.GetMap()
    local addons = engine_GetAddons()
    local st = SysTime()

    if #addons > 0 then
        Msg("\n")
        self:Log(nil, "Started adding addons on Steam Workshop...")
        local count = 0

        for _, addon in ipairs(addons) do
            if !addon["downloaded"] or !addon["mounted"] then continue end

            local wsid = addon["wsid"]
            if addon["tags"]:match("map") then
                if (map == nil) then
                    resource_AddWorkshop(wsid)
                    Msg("   + Map: "..addon["title"].." ("..wsid..")\n")
                    count = count + 1
                else
                    local ok, files = game_MountGMA(addon["file"])
                    if not ok then continue end
                    for _, fl in ipairs(files) do
                        if (string_sub(fl, #fl-3, #fl) == ".bsp") then
                            if (string_sub(fl, 6, #fl - 4) == map) then
                                resource_AddWorkshop(wsid)
                                Msg("   + Map: "..addon["title"].." ("..wsid..")\n")
                                count = count + 1
                                break;
                            end
                        end
                    end
                end
            else
                resource_AddWorkshop(wsid)
                Msg("   + Addon: "..addon["title"].." ("..wsid..")\n")
                count = count + 1
            end
        end

        self:Log(nil, "Total: "..count.." addons. "..string.format("Adding on Steam Workshop completed in %.4f seconds.", SysTime() - st), "\n")
    end
end